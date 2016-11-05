require 'will_paginate/array'

class ApplicationController < ActionController::Base

  include ApplicationHelper
  include IconHelper
  include FeatureFlagHelper
  protect_from_forgery
  layout 'application'

  before_filter :check_http_auth,
    :check_auth_token,
    :fetch_logged_in_user,
    :save_current_host_with_port,
    :generate_event_id,
    :set_homepage_path,
    :report_queue_size,
    :maintenance_warning,
    :cannot_access_if_banned

  # This updates translation files from WTI on every page load. Only useful in translation test servers.
  before_filter :fetch_translations if APP_CONFIG.update_translations_on_every_page_load == "true"

  #this shuold be last
  before_filter :push_reported_analytics_event_to_js
  before_filter :push_reported_gtm_data_to_js

  rescue_from RestClient::Unauthorized, :with => :session_unauthorized

  attr_reader :current_user

  def set_homepage_path
    @homepage_path = search_path
  end

  def fetch_logged_in_user
    if person_signed_in?
      @current_user = current_person
      setup_logger!(user_id: @current_user.id, username: @current_user.username)
    end
  end

  # A before filter for views that only users that are logged in can access
  def ensure_logged_in(warning_message)
    return if logged_in?
    session[:return_to] = request.fullpath
    flash[:warning] = warning_message
    redirect_to login_path and return
  end

  def logged_in?
    @current_user.present?
  end

  def current_user?(person)
    @current_user && @current_user.id.eql?(person.id)
  end

  # Saves current path so that the user can be
  # redirected back to that path when needed.
  def save_current_path
    session[:return_to_content] = request.fullpath
  end

  def save_current_host_with_port
    # store the host of the current request (as sometimes needed in views)
    @current_host_with_port = request.host_with_port
  end

  def request_hash
    @request_hash ||= {
      host: request.host,
      protocol: request.protocol,
      fullpath: request.fullpath,
      port_string: request.port_string,
      headers: request.headers
    }
  end

  def cannot_access_if_banned
    # Not logged in
    return unless @current_user

    # Admin can access
    return if @current_user.is_admin?

    # Check if banned
    if @current_user.banned?
      flash.keep
      redirect_to access_denied_path
    end
  end

  def fetch_community_admin_status
    @is_current_community_admin = @current_user && @current_user.has_admin_rights?
  end

  def report_queue_size
    MonitoringService::Monitoring.report_queue_size
  end

  def maintenance_warning
    now = Time.now
    @show_maintenance_warning = NextMaintenance.show_warning?(15.minutes, now)
    @minutes_to_maintenance = NextMaintenance.minutes_to(now)
  end

  private

  # Override basic instrumentation and provide additional info for
  # lograge to consume. These are pulled and logged in environment
  # configs.
  def append_info_to_payload(payload)
    super
    payload[:host] = request.host
    payload[:community_id] = Maybe(@current_community).id.or_else("")
    payload[:current_user_id] = Maybe(@current_user).id.or_else("")
    payload[:request_uuid] = request.uuid
  end

  def date_equals?(date, comp)
    date && date.to_date.eql?(comp)
  end

  def session_unauthorized
    # For some reason, ASI session is no longer valid => log the user out
    clear_user_session
    flash[:error] = t("layouts.notifications.error_with_session")
    ApplicationHelper.send_error_notification("ASI session was unauthorized. This may be normal, if session just expired, but if this occurs frequently something is wrong.", "ASI session error", params)
    redirect_to search_path and return
  end

  def clear_user_session
    @current_user = session[:person_id] = nil
  end

  # this generates the event_id that will be used in
  # requests to cos during this Sharetribe-page view only
  def generate_event_id
    RestHelper.event_id = "#{EventIdHelper.generate_event_id(params)}_#{Time.now.to_f}"
    # The event id is generated here and stored for the duration of this request.
    # The option above stores it to thread which should work fine on mongrel
  end

  def ensure_is_admin
    unless @is_current_community_admin
      flash[:error] = t("layouts.notifications.only_kassi_administrators_can_access_this_area")
      redirect_to search_path and return
    end
  end

  def ensure_is_superadmin
    unless Maybe(@current_user).is_admin?.or_else(false)
      flash[:error] = t("layouts.notifications.only_kassi_administrators_can_access_this_area")
      redirect_to search_path and return
    end
  end

  # Does a push to Google Analytics on next page load
  # the reason to go via session is that the actions that cause events
  # often do a redirect.
  # This is still not fool proof as multiple redirects would lose
  def report_analytics_event(category, action, opt_label)
    session[:analytics_event] = [category, action, opt_label]
  end

  # Does a push to Google Tag Manager on next page load
  # same disclaimers as before apply
  def report_to_gtm(map)
    session[:gtm_datalayer] = map
  end

  # if session has analytics event
  # report that and clean session
  def push_reported_analytics_event_to_js
    if session[:analytics_event]
      @analytics_event = session[:analytics_event]
      session.delete(:analytics_event)
    end
  end

  def push_reported_gtm_data_to_js
    if session[:gtm_datalayer]
      @gtm_datalayer = session[:gtm_datalayer]
      session.delete(:gtm_datalayer)
    end
  end

  def fetch_translations
    WebTranslateIt.fetch_translations
  end

  def check_http_auth
    return true unless APP_CONFIG.use_http_auth.to_s.downcase == 'true'
    if authenticate_with_http_basic { |u, p| u == APP_CONFIG.http_auth_username && p == APP_CONFIG.http_auth_password }
      true
    else
      request_http_basic_authentication
    end
  end

  def check_auth_token
    user_to_log_in = UserService::API::AuthTokens::use_token_for_login(params[:auth])
    person = Person.find(user_to_log_in[:id]) if user_to_log_in

    if person
      sign_in(person)
      @current_user = person

      # Clean the URL from the used token
      path_without_auth_token = URLUtils.remove_query_param(request.fullpath, "auth")
      redirect_to path_without_auth_token
    end

  end

  def logger
    if @logger.nil?
      metadata = [:marketplace_id, :marketplace_ident, :user_id, :username, :request_uuid]
      @logger = SharetribeLogger.new(:controller, metadata)
      @logger.add_metadata(request_uuid: request.uuid)
    end

    @logger
  end

  def setup_logger!(metadata)
    logger.add_metadata(metadata)
  end

  def display_branding_info?
    !params[:controller].starts_with?("admin") && !@current_plan[:features][:whitelabel]
  end
  helper_method :display_branding_info?

  def display_onboarding_topbar?
    # Don't show if user is not logged in
    return false unless @current_user

    # Show for super admins
    return true if @current_user.is_admin?

    # Show for admins if their status is accepted
    @current_user.is_marketplace_admin? &&
      @current_user.community_membership.accepted?
  end

  helper_method :display_onboarding_topbar?

  def topbar_props
    TopbarHelper.topbar_props(
      path_after_locale_change: @return_to,
      user: @current_user,
      search_placeholder: @community_customization&.search_placeholder,
      locale_param: params[:locale])
  end

  helper_method :topbar_props

  def header_props
    user = Maybe(@current_user).map { |u|
      {
        unread_count: MarketplaceService::Inbox::Query.notification_count(u.id).try(:to_i),
        avatar_url: u.image.present? ? u.image.url(:thumb) : view_context.image_path("profile_image/thumb/missing.png"),
        current_user_name: u.given_name,
        inbox_path: person_inbox_path(u),
        profile_path: person_path(u),
        manage_listings_path: person_path(u, show_closed: true),
        settings_path: person_settings_path(u),
        logout_path: logout_path
      }
    }.or_else({})

    common = {
      logged_in: @current_user.present?,
      homepage_path: @homepage_path,
      return_after_locale_change: @return_to,
      sign_up_path: sign_up_path,
      login_path: login_path,
      new_listing_path: new_listing_path,
      icons: pick_icons(
        APP_CONFIG.icon_pack,
        [
          "dropdown",
          "mail",
          "user",
          "list",
          "settings",
          "logout",
          "rows",
          "home",
          "new_listing",
          "information",
          "feedback",
          "invite",
          "redirect",
          "admin"
        ])
    }

    common.merge(user)
  end

  helper_method :header_props

  def render_not_found!(msg = "Not found")
    raise ActionController::RoutingError.new(msg)
  end
end

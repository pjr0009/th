class PaypalAccountsController < ApplicationController
  before_filter do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_view_your_settings")
  end

  DataTypePermissions = PaypalService::DataTypes::Permissions

  def index
    m_account = accounts_api.get(
      person_id: @current_user.id
    ).maybe

    @selected_left_navi_link = "payments"


    payment_settings = payment_settings_api.get_active.maybe

    render(locals: {
      next_action: next_action(m_account[:state].or_else("")),
      left_hand_navigation_links: settings_links_for(@current_user),
      order_permission_action: ask_order_permission_person_paypal_account_path(@current_user),
      paypal_account_email: m_account[:email].or_else(""),
      commission_from_seller: t("paypal_accounts.commission", commission: payment_settings[:commission_from_seller]),
      minimum_commission: Money.new(payment_settings[:minimum_transaction_fee_cents], "USD"),
      commission_type: payment_settings[:commission_type],
      paypal_fees_url: PaypalCountryHelper.fee_link("EN"),
      create_url: PaypalCountryHelper.create_paypal_account_url,
      receive_funds_info_label_tr_key: PaypalCountryHelper.receive_funds_info_label_tr_key("EN"),
      upgrade_url: "https://www.paypal.com/US/upgrade"
    })
  end

  def ask_order_permission
    response = accounts_api.request(
      body: PaypalService::API::DataTypes.create_create_account_request(
      {
        person_id: @current_user.id,
        callback_url: permissions_verified_person_paypal_account_url,
        country: "US"
      }),
      flow: :old)

    raise response.to_json
    permissions_url = response.data[:redirect_url]

    if permissions_url.blank?
      flash[:error] = t("paypal_accounts.new.could_not_fetch_redirect_url")
      return redirect_to action: :index
    else
      render json: {redirect_url: permissions_url}
    end
  end

  def ask_billing_agreement
  end

  def permissions_verified

    unless params[:verification_code].present?
      return flash_error_and_redirect_to_settings(error_msg: t("paypal_accounts.new.permissions_not_granted"))
    end

    response = accounts_api.create(
      person_id: @current_user.id,
      order_permission_request_token: params[:request_token],
      body: PaypalService::API::DataTypes.create_account_permission_verification_request(
        {
          order_permission_verification_code: params[:verification_code]
        }
      ),
      flow: :old)

    if response[:success]
      redirect_to paypal_account_settings_payment_path(@current_user.username)
    else
      flash_error_and_redirect_to_settings(error_response: response) unless response[:success]
    end
  end

  def billing_agreement_success
    # response = accounts_api.billing_agreement_create(
    #   community_id: @current_community.id,
    #   person_id: @current_user.id,
    #   billing_agreement_request_token: params[:token]
    # )

    # if response[:success]
    #   redirect_to paypal_account_settings_payment_path(@current_user.username)
    # else
    #   case response.error_msg
    #   when :billing_agreement_not_accepted
    #     flash_error_and_redirect_to_settings(error_msg: t("paypal_accounts.new.billing_agreement_not_accepted"))
    #   when :wrong_account
    #     flash_error_and_redirect_to_settings(error_msg: t("paypal_accounts.new.billing_agreement_wrong_account"))
    #   else
    #     flash_error_and_redirect_to_settings(error_response: response)
    #   end
    # end
  end

  def billing_agreement_cancel
    # accounts_api.delete_billing_agreement(
    #   community_id: @current_community.id,
    #   person_id: @current_user.id
    # )

    # flash[:error] = t("paypal_accounts.new.billing_agreement_canceled")
    # redirect_to paypal_account_settings_payment_path(@current_user.username)
  end


  private

  def next_action(paypal_account_state)
    if paypal_account_state == :verified
      :none
    else
      :ask_order_permission
    end
  end

  def flash_error_and_redirect_to_settings(error_response: nil, error_msg: nil)
    error_msg =
      if (error_msg)
        error_msg
      elsif (error_response && error_response[:error_code] == "570058")
        t("paypal_accounts.new.account_not_verified")
      elsif (error_response && error_response[:error_code] == "520009")
        t("paypal_accounts.new.account_restricted")
      else
        t("paypal_accounts.new.something_went_wrong")
      end

    flash[:error] = error_msg
    redirect_to action: error_redirect_action
  end

  def error_redirect_action
    :index
  end

  def payment_gateway_commission
    p_set =
      Maybe(payment_settings_api.get_active)
      .map {|res| res[:success] ? res[:data] : nil}
      .select {|set| set[:payment_gateway] == :paypal }
      .or_else(nil)

    raise ArgumentError.new("No active paypal gateway for community.") if p_set.nil?

    p_set[:commission_from_seller]
  end

  def paypal_minimum_commissions_api
    PaypalService::API::Api.minimum_commissions
  end

  def payment_settings_api
    TransactionService::API::Api.settings
  end

  def accounts_api
    PaypalService::API::Api.accounts_api
  end

end

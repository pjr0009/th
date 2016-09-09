module PathHelpers

  module_function

  def search_url(community_id:, opts: {})
    case [CustomLandingPage::LandingPageStore.enabled?(community_id),
          opts[:locale].present?]
    when matches([true, true])
      paths.search_with_locale_url(opts)
    when matches([true, false])
      paths.search_without_locale_url(opts.merge(locale: nil))
    when matches([false, true])
      paths.homepage_with_locale_url(opts)
    when matches([false, false])
      paths.homepage_without_locale_url(opts.merge(locale: nil))
    end
  end

  def landing_page_path(community_id:, logged_in:, locale_param:, default_locale:)
    non_default_locale = ->(locale) { locale && locale != default_locale.to_s}

    case [CustomLandingPage::LandingPageStore.enabled?(community_id), logged_in, locale_param]
    when matches([true, false, non_default_locale])
      paths.landing_page_with_locale_path(locale: locale_param)
    when matches([true, __, __])
      paths.landing_page_without_locale_path(locale: nil)
    when matches([false, false, non_default_locale])
      paths.homepage_with_locale_path(locale: locale_param)
    else
      paths.homepage_without_locale_path(locale: nil)
    end
  end

  def paths
    @_url_helpers ||= Rails.application.routes.url_helpers
  end

end

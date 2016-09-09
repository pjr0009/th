module PaypalService
  module MerchantInjector
    def paypal_merchant
      @paypal_merchant ||= build_paypal_merchant
    end

    module_function

    def build_paypal_merchant
      config = DataTypes.create_config(
        {
          api_credentials: build_api_credentials(APP_CONFIG),
          ipn_hook: build_ipn_hook(APP_CONFIG)
        }
      )

      PaypalService::Merchant.new(config, PaypalService::Logger.new)
    end


    def build_ipn_hook(app_config)
      if (app_config.paypal_ipn_domain)
        hook_url = Rails.application.routes.url_helpers.paypal_ipn_hook_url(
          host: app_config.paypal_ipn_domain,
          protocol: app_config.paypal_ipn_protocol)

        DataTypes.create_ipn_hook({ url: hook_url })
      else
        PaypalService::Logger.new.warn("Paypal IPN host not defined. You will not receive IPN notifications!")
        nil
      end
    end

    def build_api_credentials(config)
      PaypalService::DataTypes.create_api_credentials({
        username: config.paypal_username,
        password: config.paypal_password,
        signature: config.paypal_signature,
        app_id: config.paypal_app_id,
        mode: config.paypal_mode})
    end
  end
end

module PaypalService
  module PermissionsInjector
    def paypal_permissions
      @paypal_permissions ||= build_paypal_permissions
    end

    module_function

    def build_paypal_permissions
      config = DataTypes.create_config(
        {
          api_credentials: build_api_credentials(APP_CONFIG)
        }
      )

      PaypalService::Permissions.new(config, PaypalService::Logger.new)
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

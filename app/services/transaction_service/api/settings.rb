module TransactionService::API
  class Settings

    PaymentSettingsStore = TransactionService::Store::PaymentSettings

    def get(payment_gateway:, payment_process:)
      Result::Success.new(PaymentSettingsStore.get(
                           payment_gateway: payment_gateway,
                           payment_process: payment_process))
    end

    # Update settings but don't change gateway, process or active state
    def update(settings)
      Result::Success.new(PaymentSettingsStore.update(settings))
    end

    def get_active
      Result::Success.new(PaymentSettingsStore.get_active)
    end

    # Update the given gateway and process to be the active one, disable others
    def activate( payment_gateway:, payment_process:)
      Result::Success.new(PaymentSettingsStore.activate(
                           payment_gateway: payment_gateway,
                           payment_process: payment_process))
    end

    def disable(payment_gateway:, payment_process:)
      Result::Success.new(PaymentSettingsStore.disable(
                           payment_gateway: payment_gateway,
                           payment_process: payment_process))
    end

  end
end

module TransactionService::Process
  Gateway = TransactionService::Gateway

  class Preauthorize

    TxStore = TransactionService::Store::Transaction

    def create(tx:, gateway_fields:, gateway_adapter:, prefer_async:)
      Transition.transition_to(tx[:id], :initiated)

      Gateway.unwrap_completion(
        gateway_adapter.create_payment(
          tx: tx,
          gateway_fields: gateway_fields,
          prefer_async: prefer_async))
    end

    def reject(tx:, message:, sender_id:, gateway_adapter:)
      res = Gateway.unwrap_completion(
        gateway_adapter.reject_payment(tx: tx, reason: "")) do

        Transition.transition_to(tx[:id], :rejected)
      end

      if res[:success] && message.present?
        send_message(tx, message, sender_id)
      end

      res
    end

    def complete_preauthorization(tx:, message:, sender_id:, gateway_adapter:)
      res = Gateway.unwrap_completion(
        gateway_adapter.complete_preauthorization(tx: tx)) do

        Transition.transition_to(tx[:id], :paid)
      end

      if res[:success] && message.present?
        send_message(tx, message, sender_id)
      end

      res
    end

    def complete(tx:, gateway_adapter:)
      Transition.transition_to(tx[:id], :confirmed)
      TxStore.mark_as_unseen_by_other(community_id: tx[:community_id],
                                      transaction_id: tx[:id],
                                      person_id: tx[:listing_author_id])
      Result::Success.new({result: true})
    end

    def cancel(tx:, message:, sender_id:, gateway_adapter:)
      Transition.transition_to(tx[:id], :canceled)
      TxStore.mark_as_unseen_by_other(community_id: tx[:community_id],
                                      transaction_id: tx[:id],
                                      person_id: tx[:listing_author_id])

      if message.present?
        send_message(tx, message, sender_id)
      end

      Result::Success.new({result: true})
    end

    def request_refund(tx:, message:, sender_id:, gateway_adapter:)
      Transition.transition_to(tx[:id], :refund_requested)
      TxStore.mark_as_unseen_by_other(community_id: tx[:community_id],
                                      transaction_id: tx[:id],
                                      person_id: tx[:listing_author_id])
      if message.present?
        send_message(tx, message, sender_id)
      end

      Result::Success.new({result: true})
    end


    def refund(tx:, message:, gateway_adapter:, prefer_async: false)
      Gateway.unwrap_completion(
        gateway_adapter.refund(
          tx: tx,
          prefer_async: prefer_async))
    end

    def add_tracking_info(tx: tx, shipping_tracking_number:, shipping_provider:)
      if TxStore.add_tracking_info(tx[:id], {shipping_tracking_number: shipping_tracking_number, shipping_provider: shipping_provider})
        Transition.transition_to(tx[:id], :shipped)
        TxStore.mark_as_unseen_by_other(community_id: tx[:community_id],
                                        transaction_id: tx[:id],
                                        person_id: tx[:listing_author_id])
      end
    end

    private

    def send_message(tx, message, sender_id)
      TxStore.add_message(community_id: tx[:community_id],
                          transaction_id: tx[:id],
                          message: message,
                          sender_id: sender_id)
    end

  end
end

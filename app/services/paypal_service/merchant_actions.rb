module PaypalService
  module MerchantActions

    module_function

    # Convert between a Money instance and corresponding Paypal API presentation
    # pp API present amounts as hash-like objects, e.g. : { value: "17.12", currencyID: "EUR" }

    def from_money(m)
      { value: MoneyUtil.to_dot_separated_str(m), currencyID: m.currency.iso_code }
    end

    def to_money(pp_amount)
      pp_amount.value.to_money(pp_amount.currency_id) unless (pp_amount.nil? || pp_amount.value.nil?)
    end


    def hook_url(ipn_hook)
      ipn_hook[:url] unless ipn_hook.nil?
    end

    def append_useraction_commit(url_str)
      URLUtils.append_query_param(url_str, "useraction", "commit")
    end


    # Use either the default old checkout UI or the new paypal checkout experience
    NEW_CHECKOUT_UI = false

    # URLs for the new paypal checkout UI
    SANDBOX_EC_URL = "https://www.sandbox.paypal.com/checkoutnow"
    LIVE_EC_URL = "https://www.paypal.com/checkoutnow"
    TOKEN_PARAM = "token"

    def express_checkout_url(api, token)
      if NEW_CHECKOUT_UI
        endpoint = api.config.mode.to_sym
        if (endpoint == :sandbox)
          URLUtils.append_query_param(SANDBOX_EC_URL, TOKEN_PARAM, token)
        else
          URLUtils.append_query_param(LIVE_EC_URL, TOKEN_PARAM, token)
        end
      else
        api.express_checkout_url(token)
      end
    end


    MERCHANT_ACTIONS = {

      do_reference_transaction: PaypalAction.def_action(
        input_transformer: -> (req, config) {
          {
            DoReferenceTransactionRequestDetails: {
              ReferenceID: req[:billing_agreement_id],
              PaymentAction: PAYMENT_ACTIONS[:sale],
              PaymentType: "InstantOnly",
              PaymentDetails: {
                ButtonSource: config[:button_source],
                NotifyURL: hook_url(config[:ipn_hook]),
                OrderTotal: from_money(req[:payment_total]),
                InvoiceID: req[:invnum],
                PaymentDetailsItem: [{
                    ItemCategory: "Digital", #Commissions are always digital goods, enables also micropayments
                    Name: req[:name],
                    Description: req[:desc],
                    Number: 0,
                    Quantity: 1,
                    Amount: from_money(req[:payment_total])
                }]
              },
              MsgSubID: req[:msg_sub_id]
            }
          }
        },
        wrapper_method_name: :build_do_reference_transaction,
        action_method_name: :do_reference_transaction,
        output_transformer: -> (res, api) {
          details = res.do_reference_transaction_response_details
          DataTypes::Merchant.create_do_reference_transaction_response({
            billing_agreement_id: details.billing_agreement_id,
            payment_id: details.payment_info.transaction_id,
            payment_total: to_money(details.payment_info.gross_amount),
            payment_date: details.payment_info.payment_date.to_s,
            fee: to_money(details.payment_info.fee_amount),
            payment_status: details.payment_info.payment_status,
            pending_reason: details.payment_info.pending_reason,
            username_to: api.config.subject || api.config.username
          })
        }
      ),

      get_chained_payment_details: PaypalAction.def_action(
        input_transformer: -> (req, _) { { payKey: req[:token] } },
        wrapper_method_name: :build_payment_details,
        action_method_name: :payment_details,
        output_transformer: -> (res, api) {
          DataTypes::Merchant.create_get_chained_payment_details_response(
            {
              token: res.payKey,
              payment_status: res.status,
              payer_id: res.paymentInfoList.paymentInfo[0].receiver.accountId,
              receiver_id: res.sender.accountId,
              ext_transaction_id: res.paymentInfoList.paymentInfo[0].transactionId,
              payment_total: res.paymentInfoList.paymentInfo[0].receiver.amount.to_money(res.currencyCode),
              currency_code: res.currencyCode
            }
          )
        }
      ),

      create_chained_payment: PaypalAction.def_action(
        input_transformer: -> (req, config) {

          commission_fee = req[:payment_total] * 0.03
          tackHunterPayerId = Rails.env.production? ? ENV["PP_PAYER_ID"] : "WCWU2NEN8YMAN"

          req_details = {
            actionType: "CREATE",
            cancelUrl: req[:cancel],
            currencyCode: "USD",
            memo: req[:memo],
            returnUrl: req[:success],
            receiverList: {
              :receiver => [
                {
                  accountId: req[:payer_id], 
                  amount: req[:payment_total],
                  paymentType: "GOODS",
                  primary: true
                },
                {
                  accountId: tackHunterPayerId, 
                  amount: commission_fee,
                  paymentType: "SERVICE",
                  primary: false
                }
              ]
            }

          }

          req_details
        },
        wrapper_method_name: :build_pay,
        action_method_name: :pay,
        output_transformer: -> (res, api) {
          DataTypes::Merchant.create_chained_payment_response({
            token: res.payKey,
            redirect_url: api.payment_url(res),
            receiver_username: api.config.subject || api.config.username
          })
        }
      ),

      set_shipping_payment_options: PaypalAction.def_action(
        input_transformer: -> (req, config) {
          req_details = {
            :payKey => req[:token],
            :senderOptions => {
              :shippingAddress => {
                :addresseeName => req[:shipping_address_name],
                :city => req[:shipping_address_city],
                :country => "US",
                :street1 => req[:shipping_address_street1],
                :street2 => req[:shipping_address_street2],
                :zip => req[:shipping_address_postal_code]
              }
            },
            :receiverOptions => [{
              :receiver => {
                :accountId => req[:payer_id]
              },
              :invoiceData => {
                :totalShipping => req[:shipping_total],
                :item => [{
                  :name => req[:item_name],
                  :price => req[:item_price]
                }] 
              } 
            }],
            :displayOptions => {
                :headerImageUrl => "https://s3.amazonaws.com/tackhunter/www/logo-black.png",
                :businessName => "Tack Hunter LLC"
              }
          }

          req_details
        },
        wrapper_method_name: :build_set_payment_options,
        action_method_name: :set_payment_options,
        output_transformer: -> (res, api) {
          DataTypes::Merchant.set_payment_options_response({success: true})
        }
      ),

      set_pickup_payment_options: PaypalAction.def_action(
        input_transformer: -> (req, config) {
          req_details = {
            :payKey => req[:token],
            :receiverOptions => [{
              :receiver => {
                :accountId => req[:payer_id]
              },
              :invoiceData => {
                :item => [{
                  :name => req[:item_name],
                  :price => req[:item_price]
                }] 
              } 
            }],
            :displayOptions => {
                :emailHeaderImageUrl => "https://s3.amazonaws.com/tackhunter/www/logo-black.png", 
                :headerImageUrl => "https://s3.amazonaws.com/tackhunter/www/logo-black.png",
                :businessName => "Tack Hunter LLC"
              }
          }

          req_details
        },
        wrapper_method_name: :build_set_payment_options,
        action_method_name: :set_payment_options,
        output_transformer: -> (res, api) {
          DataTypes::Merchant.set_payment_options_response({success: true})
        }
      ),

      refund_paypal_payment: PaypalAction.def_action(
        input_transformer: -> (req, _) {
          {
            payKey: req[:token],
            transactionId: req[:ext_transaction_id],
          }
        },
        wrapper_method_name: :build_refund,
        action_method_name: :refund,
        output_transformer: -> (res, api) {
          output = {
            status: res.refundInfoList.refundInfo[0].refundStatus.try(:downcase)
          }
          if res.refundInfoList.refundInfo[0].encryptedRefundTransactionId
            output.merge!(ext_refund_transaction_id: res.refundInfoList.refundInfo[0].encryptedRefundTransactionId)
          end
          if res.refundInfoList.refundInfo[0].totalOfAllRefunds
            output.merge!(actual_refund_total: res.refundInfoList.refundInfo[0].totalOfAllRefunds.to_money(res.currencyCode))
          end
          DataTypes::Merchant.create_refund_paypal_payment_response(output)
        }
      ),

      get_transaction_details: PaypalAction.def_action(
        input_transformer: -> (req, _) {
          {
            TransactionID: req[:transaction_id],
          }
        },
        wrapper_method_name: :build_get_transaction_details,
        action_method_name: :get_transaction_details,
        output_transformer: -> (res, api) {
          payment_info = res.payment_transaction_details.payment_info
          DataTypes::Merchant.create_get_transaction_details_response(
            {
              transaction_id: payment_info.transaction_id,
              payment_status: payment_info.payment_status,
              pending_reason: payment_info.pending_reason,
              transaction_total: to_money(payment_info.gross_amount)
            }
          )
        }
      )
    }

  end
end

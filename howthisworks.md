

- Listing Shape - specifies the format of the listing. Importantly it specifies the process by which a transaction for the item is done, i.e. transaction_id

- Payment Settings - specifies global commisions, as well as payment_process (preauthorize) and payment_gateway (paypal)


When you click the buy button:
  - Ensure the listing is open and active
  - fetch_data: get community, get the transaction process to use for the listing (i.e. preauthorize), get the payment gateway to use from the payment settings
  - initiate_order_path(transaction_params) "/listings/:listing_id/initiate" if payment gateway is paypal
  - initiated path is the action that is called when "proceed to payment is clicked"
  - preauth tran controller -> initiated -> create_preauth_transaction
  - trnasaction service create
  IMPORTANT
    inside transaction service create:
      - payment settings adapter is set based on pament_gateway param (i.e. paypalsettingadapter)
      - a tx is created via the transaction store
      - the tx process #create is called which is usually preauthorize, it then calls upon the process adapter to create the payment
      - then we're in the paypal adapter #create_payment



- Listing Shape - specifies the format of the listing. Importantly it specifies the process by which a transaction for the item is done, i.e. transaction_id

- Payment Settings - specifies global commisions, as well as payment_process (preauthorize) and payment_gateway (paypal)


When you click the buy button:
  - Ensure the listing is open and active
  - fetch_data: get community, get the transaction process to use for the listing (i.e. preauthorize), get the payment gateway to use from the payment settings
  - initiate_order_path(transaction_params) "/listings/:listing_id/initiate" if payment gateway is paypal
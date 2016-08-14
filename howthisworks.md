

- Listing Shape - specifies the format of the listing. Importantly it specifies the process by which a transaction for the item is done, i.e. transaction_id

- Payment Settings - specifies global commisions, as well as payment_process (preauthorize) and payment_gateway (paypal)


When you click the buy button:
  - Ensure the listing is open and active
  - fetch_data: get community, get the transaction process to use for the listing (i.e. preauthorize), get the payment gateway to use from the payment settings
  - initiate_order_path(transaction_params) "/listings/:listing_id/initiate" if payment gateway is paypal
  - initiated path is the action that is called when "proceed to payment is clicked"
  - preauth tran controller -> initiated -> create_preauth_transaction
  - trnasaction service create transaction with status initiated
  IMPORTANT
    inside transaction service create:
      - payment settings adapter is set based on pament_gateway param (i.e. paypalsettingadapter)
      - a tx is created via the transaction store
      - the tx process #create is called which is usually preauthorize, it then calls upon the process adapter to create the payment
      - then we're in the paypal adapter #create_payment
      - see various places such as merchant actions. basically the chained payment is first created, then it is initiated with paypal to get a paykey, then user is redirected to paypal to complete

  - checkout orders controller #success is called
    - PaypalService::API::Api.payments.get_request_token find  paypal token
    - lookup trans by token
    - PaypalService::API::Api.payments.create
    - if existing payment is nil?
      - use token to create payment
      - else ensure payment authorized
    - ANOTHER BIGGIE
      - Paypas service  api::payment#create_payment called by create -> do_create (async)




flow of events
1) create paypal token and transaction
2) redirect user to complete checkout
3) upon success of checkout, create payment


Changing paypal account in the account settings:

- attach a click event onto ask_paypal_permissions id tag in paypal_account_connected.haml
- initializeNewPaypalAccountHandler is then called paypalAccountSettings.js
- specify the controller action paypal account create in paypal_preferences_controller
- accounts_create action creates a preliminary response which includes a redirect URL
- upon following the redirect URL, the user is returned to permissions_verified action where the actual paypal account is created
- note that the pending paypal account is found / created for admins leveraging the fact that person id is null. this is how its known to be a community payment account
- lastly before using this new account, all other accounts are set to false
- if unchanged, the new account is deleted




Answered questions

- the reason paypal accounts dont transfer over correctly is because there is no order permissions or billing agreements created 


CREATING PAYPAL ACCOUNT

- in paypal service / accounts # create
- upon creating a paypal accoutn correctly, basic info is requested





actions to take when deploying

- import sql
- reset my password
- paypal settings are already created



- Listing Shape - specifies the format of the listing. Importantly it specifies the process by which a transaction for the item is done, i.e. transaction_id

- Payment Settings - specifies global commisions, as well as payment_process (preauthorize) and payment_gateway (paypal)


When you click the buy button:
  - initiate.haml is an involved template
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
      - events emmitted into paypal_events, this is where state transitions for transaction and payment occurs
        1) augment_transaction_details_with_paypal_info
          - right now it'll just send shipping info if necessary


flow of events
1) create paypal token and transaction
2) redirect user to complete checkout
3) upon success of checkout, create payment

user gets payment
there should be a call to action to refund the order if necessary


Changing paypal account in the account settings:

- attach a click event onto ask_paypal_permissions id tag in paypal_account_connected.haml
- initializeNewPaypalAccountHandler is then called paypalAccountSettings.js
- specify the controller action paypal account create in paypal_preferences_controller
- accounts_create action creates a preliminary response which includes a redirect URL
- upon following the redirect URL, the user is returned to permissions_verified action where the actual paypal account is created
- note that the pending paypal account is found / created for admins leveraging the fact that person id is null. this is how its known to be a community payment account
- lastly before using this new account, all other accounts are set to false
- if unchanged, the new account is deleted




Refunds

- go up through paypal adapter 
- hit paypal payments #refund #do_refund
- actually process the refund


Answered questions

- the reason paypal accounts dont transfer over correctly is because there is no order permissions or billing agreements created 


CREATING PAYPAL ACCOUNT

- in paypal service / accounts # create
- upon creating a paypal accoutn correctly, basic info is requested






Community 
  has_many :listings
  has_many :transactions
  

Transaction
  belongs_to :community
  belongs_to :listing
  has_many :transaction_transitions, dependent: :destroy, foreign_key: :transaction_id
  has_one :payment, foreign_key: :transaction_id
  has_one :booking, :dependent => :destroy
  has_one :shipping_address, dependent: :destroy
  belongs_to :starter, :class_name => "Person", :foreign_key => "starter_id"
  belongs_to :conversation
  has_many :testimonials




actions to take when deploying

- import sql
- run migrations
- update tranaction transition states where to_state => 'paid' to 'confirmed'
- update transaction current states where 'canceled', or 'paid', to be 'confirmed' / 'refunded'
- reset my password
- paypal settings are already created
- remove custom head script from community object

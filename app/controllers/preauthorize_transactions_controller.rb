class PreauthorizeTransactionsController < ApplicationController

  before_filter do |controller|
   controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_do_a_transaction")
  end

  before_filter :fetch_listing_from_params
  before_filter :ensure_listing_is_open
  before_filter :ensure_listing_author_is_not_current_user
  before_filter :ensure_authorized_to_reply
  before_filter :ensure_can_receive_payment

  ContactForm = FormUtils.define_form("ListingConversation", :content, :sender_id, :listing_id, :community_id)
    .with_validations { validates_presence_of :content, :listing_id }

  BraintreeForm = Form::Braintree

  PreauthorizeMessageForm = FormUtils.define_form("ListingConversation",
    :content,
    :sender_id,
    :delivery_method,
    :quantity,
    :listing_id,
    :name,
    :street1,
    :street2,
    :city,
    :postal_code,
    :state_or_province,
    :phone
   ).with_validations {
    validates_presence_of :listing_id
    validates_presence_of :name, :street1, :city, :phone, :postal_code, :state_or_province , if: -> {self.delivery_method == "shipping"}
    validates :delivery_method, inclusion: { in: %w(shipping pickup), message: "%{value} is not shipping or pickup." }, allow_nil: true
  }


  ListingQuery = MarketplaceService::Listing::Query
  BraintreePaymentQuery = BraintreeService::Payments::Query

  def initiate
    delivery_method = valid_delivery_method(delivery_method_str: params[:delivery],
                                            shipping: @listing.require_shipping_address,
                                            pickup: @listing.pickup_enabled)
    if(delivery_method == :errored)
      return redirect_to error_not_found_path
    end

    quantity = TransactionViewUtils.parse_quantity(params[:quantity])

    vprms = view_params(listing_id: params[:listing_id],
                        quantity: quantity,
                        shipping_enabled: delivery_method == :shipping)

    price_break_down_locals = TransactionViewUtils.price_break_down_locals({
      booking:  false,
      quantity: quantity,
      listing_price: vprms[:listing][:price],
      localized_unit_type: translate_unit_from_listing(vprms[:listing]),
      localized_selector_label: translate_selector_label_from_listing(vprms[:listing]),
      subtotal: (quantity > 1 || vprms[:listing][:shipping_price].present?) ? vprms[:subtotal] : nil,
      shipping_price: delivery_method == :shipping ? vprms[:shipping_price] : nil,
      total: vprms[:total_price]
    })

    community_country_code = LocalizationUtils.valid_country_code(@current_community.country)

    render "listing_conversations/initiate", locals: {
      preauthorize_form: PreauthorizeMessageForm.new,
      listing: vprms[:listing],
      delivery_method: delivery_method,
      quantity: quantity,
      author: query_person_entity(vprms[:listing][:author_id]),
      action_button_label: vprms[:action_button_label],
      expiration_period: MarketplaceService::Transaction::Entity.authorization_expiration_period(vprms[:payment_type]),
      form_action: initiated_order_path(person_id: @current_user.id, listing_id: vprms[:listing][:id]),
      price_break_down_locals: price_break_down_locals,
      country_code: community_country_code
    }
  end

  def initiated
    conversation_params = params[:listing_conversation]

    preauthorize_form = PreauthorizeMessageForm.new(conversation_params.merge({
      listing_id: @listing.id
    }))
    unless preauthorize_form.valid?
      return render_error_response(request.xhr?, preauthorize_form.errors.full_messages.join(", "), action: :initiate)
    end
    delivery_method = valid_delivery_method(delivery_method_str: preauthorize_form.delivery_method,
                                            shipping: @listing.require_shipping_address,
                                            pickup: @listing.pickup_enabled)
    if(delivery_method == :errored)
      return render_error_response(request.xhr?, "Delivery method is invalid.", action: :initiate)
    end
    


    quantity = TransactionViewUtils.parse_quantity(preauthorize_form.quantity)
    shipping_price = shipping_price_total(@listing.shipping_price, @listing.shipping_price_additional, quantity)

    transaction_params = {
      payment_type: :paypal,
      community: @current_community,
      listing: @listing,
      listing_quantity: quantity,
      user: @current_user,
      content: preauthorize_form.content,
      use_async: request.xhr?,
      delivery_method: delivery_method,
      shipping_price: shipping_price
    }
    if delivery_method == :shipping
      transaction_params.merge!(
        {
          :shipping_address_attributes => {
            :name    => preauthorize_form.name,
            :street1 => preauthorize_form.street1,
            :street2 => preauthorize_form.street2,
            :city    => preauthorize_form.city,
            :state_or_province   => preauthorize_form.state_or_province,
            :postal_code => preauthorize_form.postal_code,
            :phone => preauthorize_form.phone
          }
        }
      )
    end

    transaction_response = create_preauth_transaction(transaction_params)

    unless transaction_response[:success]
      return render_error_response(request.xhr?, t("error_messages.paypal.generic_error"), action: :initiate) unless transaction_response[:success]
    end

    transaction_id = transaction_response[:data][:transaction][:id]
    if (transaction_response[:data][:gateway_fields][:redirect_url])
      redirect_to transaction_response[:data][:gateway_fields][:redirect_url]
    else
      render json: {
        op_status_url: transaction_op_status_path(transaction_response[:data][:gateway_fields][:process_token]),
        op_error_msg: t("error_messages.paypal.generic_error")
      }
    end
  end

  def preauthorize
    quantity = TransactionViewUtils.parse_quantity(params[:quantity])
    vprms = view_params(listing_id: params[:listing_id], quantity: quantity)
    braintree_settings = BraintreePaymentQuery.braintree_settings(@current_community.id)

    price_break_down_locals = TransactionViewUtils.price_break_down_locals({
      booking:  false,
      quantity: quantity,
      listing_price: vprms[:listing][:price],
      localized_unit_type: translate_unit_from_listing(vprms[:listing]),
      localized_selector_label: translate_selector_label_from_listing(vprms[:listing]),
      subtotal: (quantity > 1) ? vprms[:subtotal] : nil,
      total: vprms[:total_price]
    })

    render "listing_conversations/preauthorize", locals: {
      preauthorize_form: PreauthorizeMessageForm.new,
      braintree_client_side_encryption_key: braintree_settings[:braintree_client_side_encryption_key],
      braintree_form: BraintreeForm.new,
      listing: vprms[:listing],
      quantity: quantity,
      author: query_person_entity(vprms[:listing][:author_id]),
      action_button_label: vprms[:action_button_label],
      expiration_period: MarketplaceService::Transaction::Entity.authorization_expiration_period(vprms[:payment_type]),
      form_action: preauthorized_payment_path(person_id: @current_user.id, listing_id: vprms[:listing][:id]),
      price_break_down_locals: price_break_down_locals
    }
  end

  def preauthorized
    conversation_params = params[:listing_conversation]

    if @current_community.transaction_agreement_in_use? && conversation_params[:contract_agreed] != "1"
      flash[:error] = t("error_messages.transaction_agreement.required_error")
      return redirect_to action: :preauthorize
    end

    preauthorize_form = PreauthorizeMessageForm.new(conversation_params.merge({
      listing_id: @listing.id
    }))

    if preauthorize_form.valid?
      braintree_form = BraintreeForm.new(params[:braintree_payment])
      quantity = TransactionViewUtils.parse_quantity(preauthorize_form.quantity)

      transaction_response = TransactionService::Transaction.create({
          transaction: {
            community_id: @current_community.id,
            listing_id: @listing.id,
            listing_title: @listing.title,
            starter_id: @current_user.id,
            listing_author_id: @listing.author.id,
            unit_type: @listing.unit_type,
            unit_price: @listing.price,
            unit_tr_key: @listing.unit_tr_key,
            listing_quantity: quantity,
            content: preauthorize_form.content,
            payment_gateway: :braintree,
            payment_process: :preauthorize,
          },
          gateway_fields: braintree_form.to_hash
        })

      unless transaction_response[:success]
        flash[:error] = "An error occured while trying to create a new transaction: #{transaction_response[:error_msg]}"
        return redirect_to action: :preauthorize
      end

      transaction_id = transaction_response[:data][:transaction][:id]

      redirect_to person_transaction_path(:person_id => @current_user.id, :id => transaction_id)
    else
      flash[:error] = preauthorize_form.errors.full_messages.join(", ")
      return redirect_to action: :preauthorize
    end
  end

  private

  def translate_unit_from_listing(listing)
    Maybe(listing).select { |l|
      l[:unit_type].present?
    }.map { |l|
      ListingViewUtils.translate_unit(l[:unit_type], l[:unit_tr_key])
    }.or_else(nil)
  end

  def translate_selector_label_from_listing(listing)
    Maybe(listing).select { |l|
      l[:unit_type].present?
    }.map { |l|
      ListingViewUtils.translate_quantity(l[:unit_type], l[:unit_selector_tr_key])
    }.or_else(nil)
  end

  def view_params(listing_id:, quantity: 1, shipping_enabled: false)
    listing = ListingQuery.listing(listing_id)
    payment_type = MarketplaceService::Community::Query.payment_type(@current_community.id)

    action_button_label = translate(listing[:action_button_tr_key])

    subtotal = listing[:price] * quantity
    shipping_price = shipping_price_total(listing[:shipping_price], listing[:shipping_price_additional], quantity)
    total_price = shipping_enabled ? subtotal + shipping_price : subtotal

    { listing: listing,
      payment_type: payment_type,
      action_button_label: action_button_label,
      subtotal: subtotal,
      shipping_price: shipping_price,
      total_price: total_price }
  end

  def render_error_response(is_xhr, error_msg, redirect_params)
    if is_xhr
      render json: { error_msg: error_msg }
    else
      flash[:error] = error_msg
      redirect_to(redirect_params)
    end
  end

  def ensure_listing_author_is_not_current_user
    if @listing.author == @current_user
      flash[:error] = t("layouts.notifications.you_cannot_send_message_to_yourself")
      redirect_to(session[:return_to_content] || search_path)
    end
  end

  # Ensure that only users with appropriate visibility settings can reply to the listing
  def ensure_authorized_to_reply
    unless @listing.visible_to?(@current_user, @current_community)
      flash[:error] = t("layouts.notifications.you_are_not_authorized_to_view_this_content")
      redirect_to search_path and return
    end
  end

  def ensure_listing_is_open
    if @listing.closed?
      flash[:error] = t("layouts.notifications.you_cannot_reply_to_a_closed_offer")
      redirect_to(session[:return_to_content] || search_path)
    end
  end

  def fetch_listing_from_params
    @listing = Listing.find(params[:listing_id] || params[:id])
  end

  def new_contact_form(conversation_params = {})
    ContactForm.new(conversation_params.merge({sender_id: @current_user.id, listing_id: @listing.id, community_id: @current_community.id}))
  end

  def ensure_can_receive_payment
    payment_type = MarketplaceService::Community::Query.payment_type(@current_community.id) || :none

    ready = TransactionService::Transaction.can_start_transaction(transaction: {
        payment_gateway: payment_type,
        community_id: @current_community.id,
        listing_author_id: @listing.author.id
      })

    unless ready[:data][:result]
      flash[:error] = t("layouts.notifications.listing_author_payment_details_missing")
      return redirect_to listing_path(@listing)
    end
  end

  def valid_delivery_method(delivery_method_str:, shipping:, pickup:)
    case [delivery_method_str, shipping, pickup]
    when matches([nil, true, false]), matches(["shipping", true, __])
      :shipping
    when matches([nil, false, true]), matches(["pickup", __, true])
      :pickup
    when matches([nil, false, false])
      nil
    else
      :errored
    end
  end

  def braintree_gateway_locals(community_id)
    braintree_settings = BraintreePaymentQuery.braintree_settings(community_id)

    {
      braintree_client_side_encryption_key: braintree_settings[:braintree_client_side_encryption_key],
      braintree_form: BraintreeForm.new
    }
  end

  def create_preauth_transaction(opts)
    gateway_fields =
      if (opts[:payment_type] == :paypal)
        # PayPal doesn't like images with cache buster in the URL
        logo_url = Maybe(opts[:community])
          .wide_logo
          .select { |wl| wl.present? }
          .url(:paypal, timestamp: false)
          .or_else(nil)

        {
          merchant_brand_logo_url: logo_url,
          success_url: success_paypal_service_checkout_orders_url + "?token=${payKey}", #paypal does not automatically append, important to include this
          cancel_url: cancel_paypal_service_checkout_orders_url(listing_id: opts[:listing].id)
        }
      else
        BraintreeForm.new(opts[:bt_payment_params]).to_hash
      end

    transaction = {
          community_id: opts[:community].id,
          listing_id: opts[:listing].id,
          listing_title: opts[:listing].title,
          starter_id: opts[:user].id,
          listing_author_id: opts[:listing].author.id,
          listing_quantity: opts[:listing_quantity],
          unit_type: opts[:listing].unit_type,
          unit_price: opts[:listing].price,
          unit_tr_key: opts[:listing].unit_tr_key,
          unit_selector_tr_key: opts[:listing].unit_selector_tr_key,
          content: opts[:content],
          payment_gateway: opts[:payment_type],
          payment_process: :preauthorize,
          delivery_method: opts[:delivery_method],
          shipping_address_attributes: opts[:shipping_address_attributes]
    }

    if(opts[:delivery_method] == :shipping)
      transaction[:shipping_price] = opts[:shipping_price]
    end

    TransactionService::Transaction.create({
        transaction: transaction,
        gateway_fields: gateway_fields
      },
      paypal_async: opts[:use_async])
  end

  def query_person_entity(id)
    person_entity = MarketplaceService::Person::Query.person(id, @current_community.id)
    person_display_entity = person_entity.merge(
      display_name: PersonViewUtils.person_entity_display_name(person_entity, @current_community.name_display_type)
    )
  end

  def shipping_price_total(shipping_price, shipping_price_additional, quantity)
    Maybe(shipping_price)
      .map { |price|
        if shipping_price_additional.present? && quantity.present? && quantity > 1
          price + (shipping_price_additional * (quantity - 1))
        else
          price
        end
      }
      .or_else(nil)
  end

end

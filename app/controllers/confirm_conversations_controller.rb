class ConfirmConversationsController < ApplicationController

  before_filter do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_confirm_or_cancel")
  end

  before_filter :fetch_conversation
  before_filter :fetch_listing

  before_filter :ensure_is_starter

  MessageForm = Form::Message

  def confirm
    unless @listing_transaction.can_be_confirmed?
      flash[:error] = "You're transaction is not currently in a state that allows confirmation. Please contact support and we'll be happy to help out."
      return redirect_to person_transaction_path(person_id: @current_user.id, message_id: @listing_transaction.id)
    end

    conversation =      MarketplaceService::Conversation::Query.conversation_for_person(@listing_transaction.conversation.id, @current_user.id, @current_community.id)
    can_be_confirmed =  MarketplaceService::Transaction::Query.can_transition_to?(@listing_transaction, :confirmed)
    other_person =      query_person_entity(@listing_transaction.other_party(@current_user).id)

    render(locals: {
      action_type: "confirm",
      message_form: MessageForm.new,
      listing_transaction: @listing_transaction,
      can_be_confirmed: can_be_confirmed,
      other_person: other_person,
      status: @listing_transaction.status,
      form: @listing_transaction
    })
  end


  def dispute
    unless in_valid_pre_state(@listing_transaction)
      return redirect_to person_transaction_path(person_id: @current_user.id, message_id: @listing_transaction.id)
    end

    conversation =      MarketplaceService::Conversation::Query.conversation_for_person(@listing_transaction.conversation.id, @current_user.id, @current_community.id)
    can_be_confirmed =  MarketplaceService::Transaction::Query.can_transition_to?(@listing_transaction.id, :confirmed)
    other_person =      query_person_entity(@listing_transaction.other_party(@current_user).id)

    render(:confirm, locals: {
      action_type: "cancel",
      message_form: MessageForm.new,
      listing_transaction: @listing_transaction,
      can_be_confirmed: can_be_confirmed,
      other_person: other_person,
      status: @listing_transaction.status,
      form: @listing_transaction # TODO fix me, don't pass objects
    })
  end

  def request_refund
    if @listing_transaction.can_be_requested_to_be_refunded?
      TransactionService::Transaction.request_refund(community_id: @current_community.id, transaction_id: @listing_transaction.id, message: nil, sender_id: @current_user.id)
    end
    return redirect_to person_transaction_path(person_id: @current_user.id, message_id: @listing_transaction.id)
  end


  # Handles confirm and cancel forms
  def confirmation
    if @listing_transaction.current_state == "confirmed"
      flash[:error] = "You've already confirmed this order."
      return redirect_to person_transaction_path(person_id: @current_user.id, message_id: @listing_transaction.id)
    end

    if !MarketplaceService::Transaction::Query.can_transition_to?(@listing_transaction.id, :confirmed)
      flash[:error] = t("layouts.notifications.something_went_wrong")
      return redirect_to person_transaction_path(person_id: @current_user.id, message_id: @listing_transaction.id)
    end
    transaction = TransactionService::Transaction.confirm(community_id: @current_community.id, transaction_id: @listing_transaction.id)

    confirmation = ConfirmConversation.new(@listing_transaction, @current_user, @current_community)
    confirmation.update_participation(true)

    flash[:notice] = "Confirmed! We'll let the seller know."

    redirect_to new_person_message_feedback_path(:person_id => @current_user.id, :message_id => @listing_transaction.id)
  end

  private


  def parse_message_param
    if(params[:message])
      message = MessageForm.new(params.require(:message).permit(:content).merge({ conversation_id: @listing_transaction.conversation.id }))
      if(message.valid?)
        message.content
      end
    end
  end

  def ensure_is_starter
    unless @listing_transaction.starter == @current_user
      flash[:error] = "Only listing starter can perform the requested action"
      redirect_to (session[:return_to_content] || root)
    end
  end

  def fetch_listing
    @listing = @listing_transaction.listing
  end

  def fetch_conversation
    @listing_transaction = @current_community.transactions.find(params[:id])
  end

  def in_valid_pre_state(transaction)
    transaction.can_be_confirmed? || transaction.can_be_disputed?
  end

  def query_person_entity(id)
    person_entity = MarketplaceService::Person::Query.person(id, @current_community.id)
    person_display_entity = person_entity.merge(
      display_name: PersonViewUtils.person_entity_display_name(person_entity, @current_community.name_display_type)
    )
  end
end

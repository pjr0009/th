class TransactionProcessStateMachine
  include Statesman::Machine

  state :not_started, initial: true
  state :free
  state :initiated
  state :awaiting_shipment
  state :awaiting_pickup
  state :shipped
  state :refund_requested
  state :disputed
  state :confirmed
  state :refunded
  state :errored

  transition from: :not_started,               to: [:free, :initiated]
  transition from: :initiated,                 to: [:awaiting_pickup, :awaiting_shipment]
  transition from: :awaiting_shipment,         to: [:refund_requested, :refunded, :shipped]
  transition from: :awaiting_pickup,           to: [:refund_requested, :refunded, :confirmed]
  transition from: :shipped,                   to: [:refund_requested, :confirmed]
  transition from: :refund_requested,          to: [:refunded, :confirmed, :disputed]

  # after_transition(to: :paid) do |transaction|
  #   accepter = transaction.listing.author
  #   current_community = transaction.community

  #   Delayed::Job.enqueue(TransactionStatusChangedJob.new(transaction.id, accepter.id, current_community.id))

  #   [3, 10].each do |send_interval|
  #     Delayed::Job.enqueue(PaymentReminderJob.new(transaction.id, transaction.payment.payer.id, current_community.id), :priority => 9, :run_at => send_interval.days.from_now)
  #   end
  # end

  after_transition(to: [:awaiting_shipment, :awaiting_pickup]) do |transaction|
    payer = transaction.starter
    current_community = transaction.community

    ConfirmConversation.new(transaction, payer, current_community).activate_automatic_confirmation!

    Delayed::Job.enqueue(SendPaymentReceipts.new(transaction.id))
  end

  # after_transition(to: :rejected) do |transaction|
  #   rejecter = transaction.listing.author
  #   current_community = transaction.community

  #   Delayed::Job.enqueue(TransactionStatusChangedJob.new(transaction.id, rejecter.id, current_community.id))
  # end

  # after_transition(to: :confirmed) do |conversation|
  #   confirmation = ConfirmConversation.new(conversation, conversation.starter, conversation.community)
  #   confirmation.confirm!
  # end

  # after_transition(from: :accepted, to: :canceled) do |conversation|
  #   confirmation = ConfirmConversation.new(conversation, conversation.starter, conversation.community)
  #   confirmation.cancel!
  # end

  # after_transition(from: :paid, to: :canceled) do |conversation|
  #   confirmation = ConfirmConversation.new(conversation, conversation.starter, conversation.community)
  #   confirmation.cancel!
  #   confirmation.cancel_escrow!
  # end

end

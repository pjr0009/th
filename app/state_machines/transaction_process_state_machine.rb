class TransactionProcessStateMachine
  include Statesman::Machine

  state :not_started, initial: true
  state :free
  state :initiated
  state :pending_ext
  state :paid
  state :accepted
  state :shipped
  state :confirmed
  state :errored
  state :refunded

  transition from: :not_started,               to: [:free, :initiated]
  transition from: :initiated,                 to: [:paid]
  transition from: :pending_ext,               to: [:paid]
  transition from: :paid,                      to: [:shipped, :refunded, :confirmed]
  transition from: :confirmed,                 to: [:shipped, :refunded]

  # after_transition(to: :paid) do |transaction|
  #   accepter = transaction.listing.author
  #   current_community = transaction.community

  #   Delayed::Job.enqueue(TransactionStatusChangedJob.new(transaction.id, accepter.id, current_community.id))

  #   [3, 10].each do |send_interval|
  #     Delayed::Job.enqueue(PaymentReminderJob.new(transaction.id, transaction.payment.payer.id, current_community.id), :priority => 9, :run_at => send_interval.days.from_now)
  #   end
  # end

  after_transition(to: :paid) do |transaction|
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

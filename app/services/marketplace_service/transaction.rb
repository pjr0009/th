module MarketplaceService
  module Transaction
    TransactionModel = ::Transaction
    ParticipationModel = ::Participation

    module Entity
      Transaction = EntityUtils.define_entity(
        :id,
        :community_id,
        :last_transition,
        :last_transition_at,
        :listing,
        :listing_title,
        :status,
        :author_skipped_feedback,
        :starter_skipped_feedback,
        :starter_id,
        :testimonials,
        :transitions,
        :payment_total,
        :payment_gateway,
        :commission_from_seller,
        :delivery_method,
        :conversation,
        :booking,
        :created_at,
        :__model
      )

      Transition = EntityUtils.define_entity(
        :to_state,
        :created_at,
        :metadata
      )

      Testimonial = EntityUtils.define_entity(
        :author_id,
        :receiver_id,
        :grade
      )

      ConversationEntity = MarketplaceService::Conversation::Entity
      Conversation = ConversationEntity::Conversation
      ListingEntity = MarketplaceService::Listing::Entity

      module_function

      def waiting_testimonial_from?(transaction, person_id)
        if transaction[:starter_id] == person_id && transaction[:starter_skipped_feedback]
          false
        elsif transaction[:author_id] == person_id && transaction[:author_skipped_feedback]
          false
        else
          testimonial_from(transaction, person_id).nil?
        end
      end

      # Params:
      # - gateway_expires_at (how long the payment authorization is valid)
      # - max_date_at (max date, e.g. booking ending)
      def preauth_expires_at(gateway_expires_at, max_date_at=nil)
        [gateway_expires_at,
         Maybe(max_date_at).map {|d| (d + 2.day).to_time(:utc)}.or_else(nil)
        ].compact.min
      end

      def authorization_expiration_period(payment_type)
        # TODO These configs should be moved to Paypal/Braintree services
        case payment_type
        when :braintree
          APP_CONFIG.braintree_expiration_period.to_i
        when :paypal
          APP_CONFIG.paypal_expiration_period.to_i
        end
      end

      def testimonial_from(transaction, person_id)
        transaction[:testimonials].find { |testimonial| testimonial[:author_id] == person_id }
      end

      def transaction(transaction_model)
        listing_model = transaction_model.listing
        listing = ListingEntity.listing(listing_model) if listing_model

        payment_gateway = transaction_model.payment_gateway.to_sym

        Transaction[EntityUtils.model_to_hash(transaction_model).merge({
          status: transaction_model.current_state,
          last_transition_at: Maybe(transaction_model.transaction_transitions.last).created_at.or_else(nil),
          listing: listing,
          testimonials: transaction_model.testimonials.map { |testimonial|
            Testimonial[EntityUtils.model_to_hash(testimonial)]
          },
          starter_id: transaction_model.starter_id,
          transitions: transaction_model.transaction_transitions.map { |transition|
            Transition[EntityUtils.model_to_hash(transition)]
          },
          payment_total: calculate_total(transaction_model),
          booking: transaction_model.booking,
          __model: transaction_model
        })]
      end

      def transaction_with_conversation(transaction_model, community_id)
        transaction = Entity.transaction(transaction_model)
        transaction[:conversation] = if transaction_model.conversation
          ConversationEntity.conversation(transaction_model.conversation, community_id)
        else
          # placeholder for deleted conversation to keep transaction list working
          ConversationEntity.deleted_conversation_placeholder
        end
        transaction
      end

      def transition(transition_model)
        transition = Entity::Transition[EntityUtils.model_to_hash(transition_model)]
        transition[:metadata] = HashUtils.symbolize_keys(transition[:metadata]) if transition[:metadata].present?
        transition
      end

      def calculate_total(transaction_model)
        m_transaction = Maybe(transaction_model)

        unit_price       = m_transaction.unit_price.or_else(0)
        quantity         = m_transaction.listing_quantity.or_else(1)
        shipping_price   = m_transaction.shipping_price.or_else(0)

        (unit_price * quantity) + shipping_price
      end
    end

    module Command

      NewTransactionOptions = EntityUtils.define_builder(
        [:community_id, :fixnum, :mandatory],
        [:listing_id, :fixnum, :mandatory],
        [:starter_id, :string, :mandatory],
        [:author_id, :string, :mandatory],
        [:content, :string, :optional],
        [:commission_from_seller, :fixnum, :optional]
      )

      module_function

      def create(transaction_opts)
        opts = NewTransactionOptions[transaction_opts]

        transaction = TransactionModel.new({
            community_id: opts[:community_id],
            listing_id: opts[:listing_id],
            starter_id: opts[:starter_id],
            commission_from_seller: opts[:commission_from_seller]})

        conversation = transaction.build_conversation(
          community_id: opts[:community_id],
          listing_id: opts[:listing_id])

        conversation.participations.build({
            person_id: opts[:author_id],
            is_starter: false,
            is_read: false})

        conversation.participations.build({
            person_id: opts[:starter_id],
            is_starter: true,
            is_read: true})

        if opts[:content].present?
          conversation.messages.build({
              content: opts[:content],
              sender_id: opts[:starter_id]})
        end

        transaction.save!

        # TODO
        # We should return Entity, without expanding all the relations
        transaction.id
      end

      # Mark transasction as unseen, i.e. something new (e.g. transition) has happened
      #
      # Under the hood, this is stored to conversation, which is not optimal since that ties transaction and
      # conversation tightly together
      #
      # Deprecated! No need to call from outside tx service in the new process model.
      def mark_as_unseen_by_other(transaction_id, person_id)
        TransactionModel.find(transaction_id)
          .conversation
          .participations
          .where("person_id != '#{person_id}'")
          .update_all(is_read: false)
      end

      def mark_as_seen_by_current(transaction_id, person_id)
        TransactionModel.find(transaction_id)
          .conversation
          .participations
          .where("person_id = '#{person_id}'")
          .update_all(is_read: true)
      end

      def transition_to(transaction_id, new_status, metadata = nil)
        new_status = new_status.to_sym

        if Query.can_transition_to?(transaction_id, new_status)
          transaction = TransactionModel.where(id: transaction_id, deleted: false).first
          old_status = transaction.current_state.to_sym if transaction.current_state.present?

          transaction_entity = Entity.transaction(transaction)
          payment_type = transaction.payment_gateway.to_sym

          Entity.transaction(save_transition(transaction, new_status, metadata))
        end
      end

      def save_transition(transaction, new_status, metadata = nil)
        transaction.current_state = new_status
        transaction.save!

        metadata_hash = Maybe(metadata)
          .map { |data| TransactionService::DataTypes::TransitionMetadata.create_metadata(data) }
          .map { |data| HashUtils.compact(data) }
          .or_else(nil)

        state_machine = TransactionProcessStateMachine.new(transaction, transition_class: TransactionTransition)
        state_machine.transition_to!(new_status, metadata_hash)

        transaction.touch(:last_transition_at)

        transaction.reload
      end

    end

    module Query

      module_function

      def transaction(transaction_id)
        Maybe(TransactionModel.where(id: transaction_id, deleted: false).first)
          .map { |m| Entity.transaction(m) }
          .or_else(nil)
      end

      def transaction_with_conversation(transaction_id:, person_id: nil, community_id:)
        rel = TransactionModel.joins(:listing)
          .where(id: transaction_id, deleted: false)
          .where(community_id: community_id)

        with_person = Maybe(person_id)
          .map { |p_id|
            [rel.where("starter_id = ? OR listings.author_id = ?", p_id, p_id)]
          }
          .or_else { [rel] }
          .first

        Maybe(with_person.first)
          .map { |tx_model|
            Entity.transaction_with_conversation(tx_model, community_id)
          }
          .or_else(nil)
      end

      def transactions_for_community_sorted_by_column(community_id, sort_column, sort_direction, limit, offset)
        transactions = TransactionModel
          .where(community_id: community_id, deleted: false)
          .includes(:listing)
          .limit(limit)
          .offset(offset)
          .order("#{sort_column} #{sort_direction}")

        transactions = transactions.map { |txn|
          Entity.transaction_with_conversation(txn, community_id)
        }
      end

      def transactions_for_community_sorted_by_activity(community_id, sort_direction, limit, offset)
        sql = sql_for_transactions_for_community_sorted_by_activity(community_id, sort_direction, limit, offset)
        transactions = TransactionModel.find_by_sql(sql)

        transactions = transactions.map { |txn|
          Entity.transaction_with_conversation(txn, community_id)
        }
      end

      def transactions_count_for_community(community_id)
        TransactionModel.where(community_id: community_id, deleted: false).count
      end

      def can_transition_to?(transaction_id, new_status)
        transaction = TransactionModel.where(id: transaction_id, deleted: false).first
        if transaction
          state_machine = TransactionProcessStateMachine.new(transaction, transition_class: TransactionTransition)
          state_machine.can_transition_to?(new_status)
        end
      end

      # TODO Consider removing to inbox service, since this is more like inbox than transaction stuff.
      def sql_for_transactions_for_community_sorted_by_activity(community_id, sort_direction, limit, offset)
        # Get 'last_transition_at'
        # (this is done by joining the transitions table to itself where created_at < created_at OR sort_key < sort_key, if created_at equals)
        "
          SELECT transactions.* FROM transactions
          LEFT JOIN conversations ON transactions.conversation_id = conversations.id
          WHERE transactions.community_id = #{community_id} AND transactions.deleted = false
          ORDER BY
            GREATEST(COALESCE(transactions.last_transition_at, '0001-01-01'),
              COALESCE(conversations.last_message_at, '0001-01-01')) #{sort_direction}
          LIMIT #{limit} OFFSET #{offset}
        "
      end

      @construct_last_transition_to_sql = ->(params){
      "
        SELECT id, transaction_id, to_state, created_at FROM transaction_transitions WHERE transaction_id in (#{params[:transaction_ids].join(',')})
      "
      }
    end
  end
end

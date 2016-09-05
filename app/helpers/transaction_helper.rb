module TransactionHelper

  def icon_for(status)
    case status
    when "awaiting_shipment"
      "icon-time"
    when "awaiting_pickup"
      "icon-time"
    when "shipped"
      "icon-truck"
    when "refund_requested"
      "icon-warning-sign"
    when "dispute"
      "ss-delete"
    when "resolved"
      "ss-check"
    when "preauthorized"
      "ss-check"
    when "pending_ext"
      "ss-alert"
    when "accept_preauthorized"
      "ss-check"
    when "reject_preauthorized"
      "ss-delete"
    when "errored"
      "ss-delete"
    end
  end

  # Give `status`, `is_author` and `other_party` and get back icon and text for current status
  # rubocop:disable all
  def conversation_icon_and_status(status, is_author, other_party_name, waiting_feedback, status_meta)
    icon_waiting_you = icon_tag("alert", ["icon-fix-rel", "waiting-you"])
    icon_waiting_other = icon_tag("clock", ["icon-fix-rel", "waiting-other"])

    # Split "confirmed" status into "waiting_feedback" and "completed"
    status = if waiting_feedback
      "waiting_feedback"
    else
      "completed"
    end if status == "confirmed"

    status_hash = {
      pending: ->() { {
        author: {
          icon: icon_waiting_you,
          text: t("conversations.status.waiting_for_you_to_accept_request")
        },
        starter: {
          icon: icon_waiting_other,
          text: t("conversations.status.waiting_for_listing_author_to_accept_request", listing_author_name: other_party_name)
        }
      } },

      pending_ext: ->() {
        case status_meta[:paypal_pending_reason]
        when "multicurrency"
          {
            author: {
              icon: icon_waiting_you,
              # Make this aware of the reason
              text: t("conversations.status.pending_external_inbox.paypal.multicurrency")
            },
            starter: {
              icon: icon_waiting_other,
              text: t("conversations.status.waiting_for_listing_author_to_accept_request", listing_author_name: other_party_name)
            }
          }
        when "intl"
          {
            author: {
              icon: icon_waiting_you,
              # Make this aware of the reason
              text: t("conversations.status.pending_external_inbox.paypal.intl")
            },
            starter: {
              icon: icon_waiting_other,
              text: t("conversations.status.waiting_for_listing_author_to_accept_request", listing_author_name: other_party_name)
            }
          }
        when "verify"
          {
            author: {
              icon: icon_waiting_you,
              # Make this aware of the reason
              text: t("conversations.status.pending_external_inbox.paypal.verify")
            },
            starter: {
              icon: icon_waiting_other,
              text: t("conversations.status.waiting_for_listing_author_to_accept_request", listing_author_name: other_party_name)
            }
          }
        else # some pending_ext reason we don't have special message for
          {
            author: {
              icon: icon_waiting_you,
              text: t("conversations.status.pending_external_inbox.paypal.unknown_reason")
            },
            starter: {
              icon: icon_waiting_other,
              text: t("conversations.status.waiting_for_listing_author_to_accept_request", listing_author_name: other_party_name)
            }
          }
        end
      },

      awaiting_shipment: ->() { {
        author: {
          icon: icon_waiting_other,
          text: "Waiting for you to ship."
        },
        starter: {
          icon: icon_waiting_you,
          text: "Waiting for #{other_party_name} to ship."
        }
      } },

      awaiting_pickup: ->() { {
        author: {
          icon: icon_waiting_other,
          text: "Waiting for #{other_party_name} to pickup"
        },
        starter: {
          icon: icon_waiting_you,
          text: "Waiting for you to pickup"
        }
      } },


      shipped: ->() { {
        author: {
          icon: icon_waiting_other,
          text: "Waiting for #{other_party_name} to confirm"
        },
        starter: {
          icon: icon_waiting_you,
          text: "Item shipped"
        }
      } },

      refund_requested: ->() { {
        author: {
          icon: icon_waiting_other,
          text: "Waiting for you to issue refund."
        },
        starter: {
          icon: icon_waiting_you,
          text: "Waiting for #{other_party_name} to issue refund."
        }
      } },

      refunded: ->() { {
        author: {
          icon: icon_waiting_other,
          text: "Refunded."
        },
        starter: {
          icon: icon_waiting_you,
          text: "Refunded."
        }
      } },

      waiting_feedback: ->() { {
        both: {
          icon: icon_waiting_you,
          text: t("conversations.status.waiting_feedback_from_you")
        }
      } },

      confirmed: ->() { {
        both: {
          icon: icon_tag("check", ["icon-fix-rel", "confirmed"]),
          text: t("conversations.status.request_confirmed")
        }
      } },

      canceled: ->() { {
        both: {
          icon: icon_tag("cross", ["icon-fix-rel", "canceled"]),
          text: t("conversations.status.request_canceled")
        }
      } },

      errored: ->() { {
        both: {
          icon: icon_tag("cross", ["icon-fix-rel", "canceled"]),
          text: t("conversations.status.payment_errored")
         }
      } },
    }

    Maybe(status_hash)[status.to_sym]
      .map { |s| s.call }
      .map { |s| Maybe(is_author ? s[:author] : s[:starter]).or_else { s[:both] } }
      .values
      .get
  end

  def contextual_transaction_actions(conversation, is_author)
    statuses = if conversation.listing && !conversation.status.eql?("free")
      status_hash = {
        awaiting_shipment: ->() { {
          author: [
            awaiting_shipment_seller_links(conversation)
          ],
          starter: [
            awaiting_shipment_buyer_links(conversation)
          ]
        } },
        awaiting_pickup: ->() { {
          author: [
            awaiting_pickup_links(conversation)
          ],
         starter: [
            awaiting_pickup_links(conversation)
          ]
        } },
        shipped: ->() { {
          author: [
          ],
         starter: [
            awaiting_pickup_links(conversation)
          ]
        } },
        refund_requested: ->() { {
          author: [
            refund_requested_seller_links(conversation)

          ],
          starter: [
            refund_requested_buyer_links(conversation)
          ]
        } },
        refunded: ->() { {
          author: [
          ],
          starter: [
          ]
        } },
        confirmed: ->() { {
          both: [
          ]
        } },
        canceled: ->() { {
          both: [
            feedback_status(conversation)
          ]
        } },
        errored: ->() { {
          author: [
            status_info(t("conversations.status.payment_errored_author", starter_name: conversation.starter.name(conversation.community)), icon_classes: icon_for("errored"))
          ],
          starter: [
            status_info(t("conversations.status.payment_errored_starter"), icon_classes: icon_for("errored"))
          ]
        } }
      }

      Maybe(status_hash)[conversation.status.to_sym]
        .map { |s| s.call }
        .map { |s| Maybe(is_author ? s[:author] : s[:starter]).or_else { s[:both] } }
        .or_else([])
    else
      []
    end

    statuses.flatten.compact
  end
  
  def contextual_transaction_status(conversation, is_author)
    statuses = if conversation.listing && !conversation.status.eql?("free")
      status_hash = {
        awaiting_shipment: ->() { {
          author: [
            status_info("Ready to ship.", icon_classes: "icon-check")
          ],
          starter: [
            status_info(
              t("conversations.status.waiting_for_listing_author_to_ship_listing",
                :listing_title => link_to(conversation.listing.title, conversation.listing),
                :listing_author_name => link_to(PersonViewUtils.person_display_name(conversation.author, conversation.community))
              ).html_safe,
              icon_classes: icon_for("awaiting_shipment")
            )
          ]
        } },
        awaiting_pickup: ->() { {
          author: [
            status_info("Waiting for #{conversation.starter.name(conversation.community)} to pick up their item.", icon_classes: icon_for("awaiting_pickup"))
          ],
         starter: [
            status_info("Waiting for pickup, please mark the item as confirmed once you pick it up.", icon_classes: icon_for("awaiting_pickup"))
          ]
        } },
        shipped: ->() { {
          author: [
            status_info("Shipped. Waiting for #{conversation.starter.name(conversation.community)} to mark the order as completed.", icon_classes: icon_for("shipped")),
          ],
         starter: [
            status_info("Shipped. Please mark this order as completed once it arrives.", icon_classes: icon_for("shipped"))
          ]
        } },
        refund_requested: ->() { {
          author: [
            status_info("#{conversation.starter.name(conversation.community)} requested a refund. If this item was shipped to a customer, please wait until they've shipped it back before issuing any refunds.", icon_classes: icon_for("awaiting_pickup"))
          ],
          starter: [
            status_info("you requested a refund, waiting for seller to respond", icon_classes: icon_for("refund_requested"))
          ]
        } },
        refunded: ->() { {
          author: [
            status_info("#{conversation.starter.name(conversation.community)} was refunded")
          ],
          starter: [
            status_info("refund issued")
          ]
        } },
        pending_ext: ->() {
          ## This is so wrong place to call services...
          #TODO Deprecated call, update to use PaypalService::API:Api.payments.get_payment
          paypal_payment = PaypalService::Store::PaypalPayment.for_transaction(conversation.id)

          reason = Maybe(conversation).transaction_transitions.last.metadata["paypal_pending_reason"]

          case reason
          when Some("multicurrency")
            {
              author: [
                status_info(t("conversations.status.pending_external.paypal.multicurrency", currency: paypal_payment[:payment_total].currency, paypal_url: link_to("https://www.paypal.com", "https://www.paypal.com")).html_safe, icon_classes: icon_for("pending_ext"))
              ],
              starter: [
                status_info(t("conversations.status.request_preauthorized"), icon_classes: icon_for("preauthorized")),
              ]
            }
          when Some("intl")
            {
              author: [
                status_info(t("conversations.status.pending_external.paypal.intl", paypal_url: link_to("https://www.paypal.com", "https://www.paypal.com")).html_safe, icon_classes: icon_for("pending_ext"))
              ],
              starter: [
                status_info(t("conversations.status.request_preauthorized"), icon_classes: icon_for("preauthorized")),
              ]
            }
          when Some("verify")
            {
              author: [
                status_info(t("conversations.status.pending_external.paypal.verify", paypal_url: link_to("https://www.paypal.com", "https://www.paypal.com")).html_safe, icon_classes: icon_for("pending_ext"))
              ],
              starter: [
                status_info(t("conversations.status.request_preauthorized"), icon_classes: icon_for("preauthorized")),
              ]
            }
          end
        },
        confirmed: ->() { {
          both: [
            status_info(t("conversations.status.request_confirmed"), icon_classes: icon_for("confirmed")),
            feedback_status(conversation)
            
          ]
        } },
        canceled: ->() { {
          both: [
            status_info(t("conversations.status.request_canceled"), icon_classes: icon_for("canceled")),
          ]
        } },
        rejected: ->() { {
          both: [
            status_info(t("conversations.status.request_rejected"), icon_classes: icon_for(conversation.status))
          ]
        } },
        errored: ->() { {
          author: [
            status_info(t("conversations.status.payment_errored_author", starter_name: conversation.starter.name(conversation.community)), icon_classes: icon_for("errored"))
          ],
          starter: [
            status_info(t("conversations.status.payment_errored_starter"), icon_classes: icon_for("errored"))
          ]
        } }
      }

      Maybe(status_hash)[conversation.status.to_sym]
        .map { |s| s.call }
        .map { |s| Maybe(is_author ? s[:author] : s[:starter]).or_else { s[:both] } }
        .or_else([])
    else
      []
    end

    statuses.flatten.compact
  end

  private

  def waiting_for_confirmation_links(conversation)
    if conversation.seller == @current_user
      waiting_for_buyer_to_confirm(conversation)
    else
      waiting_for_current_user_to_confirm(conversation)
    end
  end
  
  def awaiting_shipment_links(conversation)
    if conversation.seller == @current_user
      awaiting_shipment_seller_links(conversation)
    else
      awaiting_shipment_buyer_links(conversation)
    end
  end

  def awaiting_pickup_links(conversation)
    if conversation.seller == @current_user
      awaiting_pickup_seller_links(conversation)
    else
      awaiting_pickup_buyer_links(conversation)
    end
  end


  def feedback_status(conversation)
    if conversation.has_feedback_from?(@current_user)
      feedback_given_status
    elsif conversation.feedback_skipped_by?(@current_user)
      feedback_skipped_status
    else
      feedback_pending_status(conversation)
    end
  end

  def waiting_for_current_user_to_confirm(conversation)
    status_links([
      {
        link_href: confirm_person_message_path(@current_user, :id => conversation.id),
        link_classes: "confirm",
        link_icon_with_text_classes: icon_for("confirmed"),
        link_text_with_icon: "Mark as Completed"
      },
      {
        link_href: request_refund_person_message_path(@current_user, :id => conversation.id),
        link_classes: "cancel",
        link_icon_with_text_classes: icon_for("canceled"),
        link_text_with_icon: "Request Refund"
      }
    ])
  end

  def awaiting_shipment_seller_links(conversation)
    status_links([
      {
        link_href: confirm_person_message_path(@current_user, :id => conversation.id),
        link_classes: "confirm",
        link_icon_with_text_classes: icon_for("confirmed"),
        link_text_with_icon: "Add Tracking Info"
      },
      {
        link_href: refund_person_transaction_path(@current_user, :id => conversation.id),
        link_classes: "cancel",
        link_icon_with_text_classes: icon_for("canceled"),
        link_text_with_icon: "Issue Refund"
      }
    ])
  end

  def awaiting_shipment_buyer_links(conversation)
    status_links([{
        link_href: request_refund_person_message_path(@current_user, :id => conversation.id),
        link_classes: "cancel",
        link_icon_with_text_classes: icon_for("canceled"),
        link_text_with_icon: "Request Refund"
      }
    ])
  end


  def awaiting_pickup_seller_links(conversation)
    status_links([
      {
        link_href: refund_person_transaction_path(@current_user, :id => conversation.id),
        link_classes: "cancel",
        link_icon_with_text_classes: icon_for("canceled"),
        link_text_with_icon: "Issue Refund"
      }
    ])
  end
  
  def awaiting_pickup_buyer_links(conversation)
    status_links([
      {
        link_href: confirm_person_message_path(@current_user, :id => conversation.id),
        link_classes: "confirm",
        link_icon_with_text_classes: icon_for("confirmed"),
        link_text_with_icon: "Confirm"
      },
      {
        link_href: request_refund_person_message_path(@current_user, :id => conversation.id),
        link_classes: "cancel",
        link_icon_with_text_classes: icon_for("canceled"),
        link_text_with_icon: "Request Refund"
      }
    ])
  end

  def refund_requested_seller_links(conversation)
    status_links([
      {
        link_href: refund_person_transaction_path(@current_user, :id => conversation.id),
        link_classes: "confirm",
        link_icon_with_text_classes: icon_for("confirmed"),
        link_text_with_icon: "Issue refund"
      },
      {
        link_href: cancel_person_message_path(@current_user, :id => conversation.id),
        link_classes: "cancel",
        link_icon_with_text_classes: icon_for("dispute"),
        link_text_with_icon: "Dispute"
      }
    ])
  end

  def refund_requested_buyer_links(conversation)
    status_links([
      {
        link_href: confirm_person_message_path(@current_user, :id => conversation.id),
        link_classes: "confirm",
        link_icon_with_text_classes: icon_for("confirmed"),
        link_text_with_icon: "Resolved"
      },
      {
        link_href: cancel_person_message_path(@current_user, :id => conversation.id),
        link_classes: "cancel",
        link_icon_with_text_classes: icon_for("dispute"),
        link_text_with_icon: "Dispute"
      }
    ])
  end


  def awaiting_shipment_buyer_links(conversation)
    status_links([{
        link_href: request_refund_person_message_path(@current_user, :id => conversation.id),
        link_classes: "cancel",
        link_icon_with_text_classes: icon_for("canceled"),
        link_text_with_icon: "Request Refund"
      }
    ])
  end

  def feedback_pending_status(conversation)
    status_links([
      {
        link_href: new_person_message_feedback_path(@current_user, :message_id => conversation.id),
        link_icon_with_tag: icon_tag("testimonial", ["icon-with-text"]),
        link_text_with_icon: t("conversations.status.give_feedback")
      },
      {
        link_href: skip_person_message_feedbacks_path(@current_user, :message_id => conversation.id),
        link_classes: "cancel",
        link_icon_with_text_classes: "ss-skipforward",
        link_text_with_icon: t("conversations.status.skip_feedback"),
        link_data: { :method => "put", :remote => "true"}
      }
    ])
  end

  def status_links(content)
    {
      type: :status_links,
      content: content
    }
  end


  def waiting_for_buyer_to_confirm(conversation)
    link = t("conversations.status.waiting_confirmation_from_requester",
      :requester_name => link_to(
        conversation.other_party(@current_user).given_name_or_username,
        conversation.other_party(@current_user)
      )
    ).html_safe

    status_info(link, icon_classes: 'ss-clock')
  end

  def feedback_given_status
    status_info(t("conversations.status.feedback_given"), icon_tag: icon_tag("testimonial", ["icon-part"]))
  end

  def feedback_skipped_status
    status_info(t("conversations.status.feedback_skipped"), icon_classes: "ss-skipforward")
  end

  def status_info(text, icon_tag: nil, icon_classes: nil)
    hash = {
      type: :status_info,
      content: {
        info_text_part: text
      }
    }

    if icon_tag
      hash.deep_merge(content: {info_icon_tag: icon_tag})
    elsif icon_classes
      hash.deep_merge(content: {info_icon_part_classes: icon_classes})
    else
      hash
    end
  end

  def shipping_providers
    Transaction::VALID_SHIPPING_PROVIDERS
  end

  def us_states
      [
        ['Alabama', 'AL'],
        ['Alaska', 'AK'],
        ['Arizona', 'AZ'],
        ['Arkansas', 'AR'],
        ['California', 'CA'],
        ['Colorado', 'CO'],
        ['Connecticut', 'CT'],
        ['Delaware', 'DE'],
        ['District of Columbia', 'DC'],
        ['Florida', 'FL'],
        ['Georgia', 'GA'],
        ['Hawaii', 'HI'],
        ['Idaho', 'ID'],
        ['Illinois', 'IL'],
        ['Indiana', 'IN'],
        ['Iowa', 'IA'],
        ['Kansas', 'KS'],
        ['Kentucky', 'KY'],
        ['Louisiana', 'LA'],
        ['Maine', 'ME'],
        ['Maryland', 'MD'],
        ['Massachusetts', 'MA'],
        ['Michigan', 'MI'],
        ['Minnesota', 'MN'],
        ['Mississippi', 'MS'],
        ['Missouri', 'MO'],
        ['Montana', 'MT'],
        ['Nebraska', 'NE'],
        ['Nevada', 'NV'],
        ['New Hampshire', 'NH'],
        ['New Jersey', 'NJ'],
        ['New Mexico', 'NM'],
        ['New York', 'NY'],
        ['North Carolina', 'NC'],
        ['North Dakota', 'ND'],
        ['Ohio', 'OH'],
        ['Oklahoma', 'OK'],
        ['Oregon', 'OR'],
        ['Pennsylvania', 'PA'],
        ['Puerto Rico', 'PR'],
        ['Rhode Island', 'RI'],
        ['South Carolina', 'SC'],
        ['South Dakota', 'SD'],
        ['Tennessee', 'TN'],
        ['Texas', 'TX'],
        ['Utah', 'UT'],
        ['Vermont', 'VT'],
        ['Virginia', 'VA'],
        ['Washington', 'WA'],
        ['West Virginia', 'WV'],
        ['Wisconsin', 'WI'],
        ['Wyoming', 'WY']
      ]
  end
end

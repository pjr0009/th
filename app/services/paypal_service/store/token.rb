module PaypalService::Store::Token
  PaypalTokenModel = ::PaypalToken

  module Entity
    Token = EntityUtils.define_builder(
      [:token, :string, :mandatory],
      [:transaction_id, :fixnum, :mandatory],
      [:merchant_id, :string, :mandatory],
      [:receiver_id, :string, :mandatory],
      [:item_name, :string],
      [:item_quantity, :fixnum],
      [:item_price, :money],
      [:shipping_total, :money],
      [:paypal_redirect_url, :string, :mandatory]
    )

    module_function

    def from_model(model)
      Token.call(
        EntityUtils.model_to_hash(model).merge({
            item_price: model.item_price,
            shipping_total: model.shipping_total
        }))
    end
  end


  module_function

  def create(opts)
    pt_opts = {
      token: opts[:token],
      transaction_id: opts[:transaction_id],
      merchant_id: opts[:merchant_id],
      receiver_id: opts[:receiver_id],
      item_name: opts[:item_name],
      item_quantity: opts[:item_quantity],
      item_price: opts[:item_price],
      paypal_redirect_url: opts[:paypal_redirect_url]
    }

    pt_opts[:shipping_total] = opts[:shipping_total] if opts[:shipping_total]

    PaypalTokenModel.create!(pt_opts)
  end

  def delete(transaction_id)
    PaypalTokenModel.where(transaction_id: transaction_id).destroy_all
  end

  def get(token)
    Maybe(PaypalTokenModel.where(token: token)
      .map { |model| Entity.from_model(model) }
      .or_else(nil)
  end

  def get_for_transaction(transaction_id)
    Maybe(PaypalTokenModel.where(transaction_id: transaction_id).first)
      .map { |model| Entity.from_model(model) }
      .or_else(nil)
  end

  def get_all
    PaypalToken.all
  end
end

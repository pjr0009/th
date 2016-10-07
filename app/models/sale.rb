# == Schema Information
#
# Table name: sales
#
#  id                    :integer          not null, primary key
#  brand_id              :integer
#  product_id            :integer
#  transactions_id       :integer
#  external_source       :string(255)
#  external_location     :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  asking_price_cents    :integer          default(0)
#  asking_price_currency :string(255)
#  sold_price_cents      :integer          default(0)
#  sold_price_currency   :string(255)
#
# Indexes
#
#  index_sales_on_brand_id                                       (brand_id)
#  index_sales_on_brand_id_and_product_id_and_external_location  (brand_id,product_id,external_location) UNIQUE
#  index_sales_on_product_id                                     (product_id)
#  index_sales_on_transactions_id                                (transactions_id)
#

#the primary purpose of this model is for historical pricing data and record keeping
class Sale < ActiveRecord::Base
  belongs_to :brand
  belongs_to :product
  belongs_to :tx, class_name: "Transaction", foreign_key: "transaction_id"
  monetize :sold_price_cents, allow_nil: false
  monetize :asking_price_cents, allow_nil: false

end

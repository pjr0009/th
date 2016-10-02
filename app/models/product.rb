# == Schema Information
#
# Table name: products
#
#  id                 :integer          not null, primary key
#  model              :string(255)      not null
#  brand_id           :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  image_file_name    :string(255)
#  image_content_type :string(255)
#  image_file_size    :integer
#  image_updated_at   :datetime
#
# Indexes
#
#  index_products_on_brand_id  (brand_id)
#

class Product < ActiveRecord::Base
end

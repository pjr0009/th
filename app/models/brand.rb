# == Schema Information
#
# Table name: brands
#
#  id                        :integer          not null, primary key
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  summary                   :string(255)
#  logo_file_name            :string(255)
#  logo_content_type         :string(255)
#  logo_file_size            :integer
#  logo_updated_at           :datetime
#  illustration_file_name    :string(255)
#  illustration_content_type :string(255)
#  illustration_file_size    :integer
#  illustration_updated_at   :datetime
#

class Brand < ActiveRecord::Base
  has_many :listings
  has_and_belongs_to_many :disciplines
  has_many :products
end

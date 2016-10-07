# == Schema Information
#
# Table name: brands
#
#  id                :integer          not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  name              :string(255)
#  slug              :string(255)
#  summary           :string(255)
#  logo_file_name    :string(255)
#  logo_content_type :string(255)
#  logo_file_size    :integer
#  logo_updated_at   :datetime
#

class Brand < ActiveRecord::Base
  extend FriendlyId
  
  has_many :listings
  has_and_belongs_to_many :disciplines
  has_many :products
  has_many :sales
  before_create :ensure_capitalized
  validates :name, uniqueness: { case_sensitive: false }
  friendly_id :name, use: [:slugged, :finders]


  def ensure_capitalized
    self.name = self.name.titleize unless (self.name.upcase == self.name)
  end
end

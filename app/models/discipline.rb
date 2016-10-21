# == Schema Information
#
# Table name: disciplines
#
#  id                        :integer          not null, primary key
#  summary                   :text(65535)
#  name                      :string(255)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  illustration_file_name    :string(255)
#  illustration_content_type :string(255)
#  illustration_file_size    :integer
#  illustration_updated_at   :datetime
#  slug                      :string(255)
#

class Discipline < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  has_and_belongs_to_many :brands
  has_many :discipline_categories
  has_many :categories, :through => :discipline_categories
  has_attached_file :image, :styles => {
        :small_3x2 => "240x160#",
        :medium => "360x270#",
        :thumb => "120x120#",
        :email => "150x100#"
      }
  
end

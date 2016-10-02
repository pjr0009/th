# == Schema Information
#
# Table name: disciplines
#
#  id         :integer          not null, primary key
#  summary    :text(65535)
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Discipline < ActiveRecord::Base
  has_and_belongs_to_many :brands
  has_attached_file :image, :styles => {
        :small_3x2 => "240x160#",
        :medium => "360x270#",
        :thumb => "120x120#",
        :email => "150x100#"
      }
  
end

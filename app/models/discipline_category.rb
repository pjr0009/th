# == Schema Information
#
# Table name: discipline_categories
#
#  id            :integer          not null, primary key
#  discipline_id :integer
#  category_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class DisciplineCategory < ActiveRecord::Base
  belongs_to :discipline
  belongs_to :category
end

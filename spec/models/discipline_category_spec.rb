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

require 'rails_helper'

RSpec.describe DisciplineCategory, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

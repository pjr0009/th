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

require 'rails_helper'

RSpec.describe Discipline, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

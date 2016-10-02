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

require 'rails_helper'

RSpec.describe Brand, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

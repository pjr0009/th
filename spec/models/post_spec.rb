# == Schema Information
#
# Table name: posts
#
#  id                       :integer          not null, primary key
#  title                    :string(255)
#  partial                  :string(255)
#  author                   :string(255)
#  slug                     :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  feature_image_large      :string(255)      not null
#  external_attribution_url :string(255)
#  summary                  :text(65535)      not null
#

require 'rails_helper'

RSpec.describe Post, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

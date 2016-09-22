# == Schema Information
#
# Table name: posts
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  partial    :string(255)
#  author     :string(255)
#  slug       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Post < ActiveRecord::Base
  extend FriendlyId
  friendly_id :title, use: [:slugged, :finders]
  after_create :set_partial_name

  private
  def set_partial_name
    self.partial = self.slug.underscore
    self.save
  end
end

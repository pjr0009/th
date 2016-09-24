# == Schema Information
#
# Table name: news_posts
#
#  id                 :integer          not null, primary key
#  title              :string(255)
#  partial            :string(255)
#  person_id          :integer
#  slug               :string(255)
#  summary            :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  image_file_name    :string(255)
#  image_content_type :string(255)
#  image_file_size    :integer
#  image_updated_at   :datetime
#

class NewsPost < ActiveRecord::Base
  extend FriendlyId
  friendly_id :title, use: [:slugged, :finders]
  has_attached_file :image, :styles => {
        :small_3x2 => "240x160#",
        :medium => "360x270#",
        :thumb => "120x120#",
        :feature => "1400x380#",
        :email => "150x100#"}
  after_create :set_partial_name

  validates_attachment_size :image, :less_than => APP_CONFIG.max_image_filesize.to_i, :unless => Proc.new {|model| model.image.nil? }
  validates_attachment_content_type :image,
                                    :content_type => ["image/jpeg", "image/png", "image/gif", "image/pjpeg", "image/x-png"], # the two last types are sent by IE.
                                    :unless => Proc.new {|model| model.image.nil? }

  private
  def set_partial_name
    self.partial = self.slug.underscore
    self.save
  end
end

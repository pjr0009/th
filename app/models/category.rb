# == Schema Information
#
# Table name: categories
#
#  id            :integer          not null, primary key
#  parent_id     :integer
#  icon          :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  community_id  :integer
#  sort_priority :integer
#  url           :string(255)
#  name          :string(255)      not null
#  slug          :string(255)
#
# Indexes
#
#  index_categories_on_community_id  (community_id)
#  index_categories_on_parent_id     (parent_id)
#  index_categories_on_url           (url)
#

class Category < ActiveRecord::Base
  extend FriendlyId
  
  attr_accessible(
    :community_id,
    :parent_id,
    :name,
    :translations,
    :translation_attributes,
    :sort_priority,
    :url,
    :basename,
    :discipline_ids
  )

  attr_accessor :basename

  friendly_id :slug_candidates, use: [:slugged, :finders]


  has_many :subcategories, -> { order("sort_priority") }, :class_name => "Category", :foreign_key => "parent_id", :dependent => :destroy
  # children is a more generic alias for sub categories, used in classification.rb
  has_many :children, -> { order("sort_priority") }, :class_name => "Category", :foreign_key => "parent_id"
  belongs_to :parent, :class_name => "Category"
  has_many :listings
  has_many :translations, :class_name => "CategoryTranslation", :dependent => :destroy

  has_many :discipline_categories
  has_many :disciplines, :through => :discipline_categories

  has_and_belongs_to_many :listing_shapes, -> { order("sort_priority") }, join_table: "category_listing_shapes"

  has_many :category_custom_fields, :dependent => :destroy
  has_many :custom_fields, -> { order("sort_priority") }, :through => :category_custom_fields

  belongs_to :community

  before_destroy :can_destroy?

  def slug_candidates
    [
      :name,
      ["western", :name],
    ]
  end

  def should_generate_new_friendly_id? #will change the slug if the name changed
    name_changed? || discipline_categories.all.any?(&:changed?)
  end

  def name_with_disciplines
    unless disciplines.blank?
      "#{disciplines.map(&:name).join(',')} > #{self.name}"
    else
      self.name
    end
  end

  def has_own_or_subcategory_listings?
    listings.count > 0 || subcategories.any? { |subcategory| !subcategory.listings.empty? }
  end

  def has_subcategories?
    subcategories.count > 0
  end

  def has_own_or_subcategory_custom_fields?
    custom_fields.count > 0 || subcategories.any? { |subcategory| !subcategory.custom_fields.empty? }
  end

  def subcategory_ids
    subcategories.collect(&:id)
  end

  def own_and_subcategory_ids
    [id].concat(subcategory_ids)
  end

  def is_subcategory?
    !parent_id.nil?
  end

  def can_destroy?
    is_subcategory? || community.top_level_categories.count > 1
  end

  def remove_needs_caution?
    has_own_or_subcategory_listings? or has_subcategories?
  end

  def own_and_subcategory_listings
    Listing.find_by_category_and_subcategory(self)
  end

  def own_and_subcategory_custom_fields
    CategoryCustomField.find_by_category_and_subcategory(self).includes(:custom_field).collect(&:custom_field)
  end

  def with_all_children
    # first add self
    child_array = [self]

    # Then add children with their children too
    children.each do |child|
      child_array << child.with_all_children
    end

    return child_array.flatten
  end

  def icon_name
    return icon if ApplicationHelper.icon_specified?(icon)
    return parent.icon_name if parent
    return "other"
  end

  def self.find_by_url_or_id(url_or_id)
    self.find_by_url(url_or_id) || self.find_by_id(url_or_id)
  end
end

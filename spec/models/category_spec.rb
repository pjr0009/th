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

require 'spec_helper'

describe Category, type: :model do

  before(:each) do
    @discipline = FactoryGirl.create(:discipline, name: "English")
    @discipline_2 = FactoryGirl.create(:discipline, name: "Western")
    @category = FactoryGirl.create(:category, name: "Saddles")
    @category2 = FactoryGirl.create(:category, name: "Breeches")
    @subcategory = FactoryGirl.create(:category, name: "Dressage Saddles")
    @subcategory.update_attribute(:parent_id, @category.id)
    @category.reload
    @subcategory.reload
    @discipline.reload
    @discipline_2.reload
  end

  context "Top level categories are unique" do 
    describe "slug_candidates" do
      it "should not prefix category with discipline" do
        expect(@category.slug).to eq("saddles")
        expect(@category2.slug).to eq("breeches")
      end
    end
    describe "should_generate_new_friendly_id?" do
      it "should update the slug if the category name changes" do
        expect(@category.slug).to eq("saddles")
        expect(@category2.slug).to eq("breeches")
        @category.name = "Boots"
        @category.save
        expect(@category.slug).to eq("boots")
      end
      it "should not change the slug if the parent disciplines change" do
        expect(@category.slug).to eq("saddles")
        expect(@category2.slug).to eq("breeches")
        @category.disciplines << @discipline
        @category2.disciplines << @discipline_2
        
        #verify discpline assignment went through so that the test is accurate
        expect(@category.disciplines).to include(@discipline)
        expect(@category.disciplines).to_not include(@discipline_2)
        expect(@category2.disciplines).to include(@discipline_2)
        expect(@category2.disciplines).to_not include(@discipline)

        #now test that it didnt change slugs
        expect(@category.slug).to eq("saddles")
        expect(@category2.slug).to eq("breeches")
      end
    end
  end
  context "Top level categories are NOT unique" do 
    describe "slug_candidates" do
      it "should prefix category with discipline if you try to create another category by the same name" do
        category_3 = FactoryGirl.build(:category, name: "Saddles")
        category_3.disciplines << @discipline_2
        category_3.save
        category_3.reload
        expect(category_3.slug).to eq("western-saddles")
        expect(@category.slug).to eq("saddles")
      end
      it "should unprefix category slug if you fix collision manually" do
        category_3 = FactoryGirl.build(:category, name: "Saddles")
        category_3.disciplines << @discipline_2
        category_3.save
        category_3.reload
        expect(category_3.slug).to eq("western-saddles")
        expect(@category.slug).to eq("saddles")
        category_3.name = "Show Attire"
        category_3.save
        category_3.reload
        expect(category_3.slug).to eq("show-attire")
      end
    end
  end
end

# it "has listings?" do
#   expect(@category.has_own_or_subcategory_listings?).to be_falsey

#   @listing = FactoryGirl.create(:listing, {category: @category})
#   @category.reload

#   expect(@category.has_own_or_subcategory_listings?).to be_truthy
# end

# it "can not be deleted if it's the only top level category" do
#   expect(Category.find_by_id(@category.id)).not_to be_nil

#   @category.destroy

#   expect(Category.find_by_id(@category.id)).not_to be_nil
# end

# it "removes subcategories if parent is removed" do
#   @category2 = FactoryGirl.create(:category, :community => @community)

#   expect(Category.find_by_id(@category.id)).not_to be_nil
#   expect(Category.find_by_id(@subcategory.id)).not_to be_nil

#   @category.destroy

#   expect(Category.find_by_id(@category.id)).to be_nil
#   expect(Category.find_by_id(@subcategory.id)).to be_nil
# end

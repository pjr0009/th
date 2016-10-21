 module Searchable
  extend ActiveSupport::Concern

  def set_categories
    @categories = @discipline.categories.all.includes(:children)
    @main_categories = @categories.select { |c| c.parent_id == nil }
  end

  def find_listings(query="", category_url=nil, discipline_id=nil, page=1)
    categories = []
    Category.where(:url => category_url).each do |category|
      categories = category.own_and_subcategory_ids
      @selected_category = category
    end
    search = {
      # Add listing_id
      categories: categories,
      discipline_id: discipline_id,
      keywords: query,
      per_page: 25,
      page: page,
      include_closed: false
    }

    raise_errors = Rails.env.development?
    ListingIndexService::API::Api.listings.search(
      search: search,
      includes: [:author, :listing_images],
      engine: :sphinx,
      raise_errors: raise_errors
      ).and_then { |res|
      Result::Success.new(
        ListingIndexViewUtils.to_struct(
        result: res,
        includes: [:author, :listing_images],
        page: search[:page],
        per_page: search[:per_page]
      ))
    }

  end
end
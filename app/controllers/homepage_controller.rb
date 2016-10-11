# encoding: utf-8
class HomepageController < ApplicationController
  include Searchable
  before_filter :save_current_path, :except => :sign_in

  APP_DEFAULT_VIEW_TYPE = "grid"
  VIEW_TYPES = ["grid", "list", "map"]
  APP_MINIMUM_DISTANCE_MAX = 5


  def index
    @homepage = true

    set_categories
    params[:page] ||= 1

    search_result = find_listings(params[:q], params[:category], nil, params[:page])

    if request.xhr? # checks if AJAX request
      search_result.on_success { |listings|
        @listings = listings # TODO Remove
        render partial: "list_item", collection: @listings, as: :listing
      }.on_error {
        render nothing: true, status: 500
      }
    else
      search_result.on_success { |listings|
        @listings = listings
        render and return
      }.on_error { |e|
        flash[:error] = t("homepage.errors.search_engine_not_responding")
        @listings = Listing.none.paginate(:per_page => 1, :page => 1)
        render status: 500 and return
      }
    end
  end

  # def self.selected_view_type(view_param, community_default, app_default, all_types)
  #   if view_param.present? and all_types.include?(view_param)
  #     view_param
  #   elsif community_default.present? and all_types.include?(community_default)
  #     community_default
  #   else
  #     app_default
  #   end
  # end

  # private

  # def filter_range(price_min, price_max)
  #   if (price_min && price_max)
  #     min = MoneyUtil.parse_str_to_money(price_min, @current_community.default_currency).cents
  #     max = MoneyUtil.parse_str_to_money(price_max, @current_community.default_currency).cents

  #     if ((@current_community.price_filter_min..@current_community.price_filter_max) != (min..max))
  #       (min..max)
  #     else
  #       nil
  #     end
  #   end
  # end

  # # Return all params starting with `numeric_filter_`
  # def self.numeric_filter_params(all_params)
  #   all_params.select { |key, value| key.start_with?("nf_") }
  # end

  # def self.parse_numeric_filter_params(numeric_params)
  #   numeric_params.inject([]) do |memo, numeric_param|
  #     key, value = numeric_param
  #     _, boundary, id = key.split("_")

  #     hash = {id: id.to_i}
  #     hash[boundary.to_sym] = value
  #     memo << hash
  #   end
  # end

  # def self.group_to_ranges(parsed_params)
  #   parsed_params
  #     .group_by { |param| param[:id] }
  #     .map do |key, values|
  #       boundaries = values.inject(:merge)

  #       {
  #         id: key,
  #         value: (boundaries[:min].to_f..boundaries[:max].to_f)
  #       }
  #     end
  # end

  # # Filter search params if their values equal min/max
  # def self.filter_unnecessary(search_params, numeric_fields)
  #   search_params.reject do |search_param|
  #     numeric_field = numeric_fields.find(search_param[:id])
  #     search_param == { id: numeric_field.id, value: (numeric_field.min..numeric_field.max) }
  #   end
  # end

  # def self.options_from_params(params, regexp)
  #   option_ids = HashUtils.select_by_key_regexp(params, regexp).values

  #   array_for_search = CustomFieldOption.find(option_ids)
  #     .group_by { |option| option.custom_field_id }
  #     .map { |key, selected_options| {id: key, value: selected_options.collect(&:id) } }
  # end

  # def self.dropdown_field_options_for_search(params)
  #   options_from_params(params, /^filter_option/)
  # end

  # def self.checkbox_field_options_for_search(params)
  #   options_from_params(params, /^checkbox_filter_option/)
  # end

  # def shapes
  #   ListingService::API::Api.shapes
  # end

  # def search_coordinates(latlng)
  #   lat, lng = latlng.split(',')
  #   if(lat.present? && lng.present?)
  #     return { latitude: lat, longitude: lng }
  #   else
  #     ArgumentError.new("Format of latlng coordinate pair \"#{latlng}\" wasn't \"lat,lng\" ")
  #   end
  # end

  # def location_search_params(latlng, distance_unit, distance_max, minimum_distance_max)
  #   # Current map doesn't react to zoom & panning, so we fetch all the results as before.
  #   if @view_type != 'map'
  #     Maybe(latlng)
  #       .map {
  #         search_coordinates(latlng).merge({
  #           distance_unit: distance_unit,
  #           distance_max: [minimum_distance_max, distance_max.to_f].max,
  #           sort: :distance
  #         })
  #       }
  #       .or_else({})
  #   else
  #     {}
  #   end
  # end

  # def no_current_user_in_private_clp_enabled_marketplace?
  #   CustomLandingPage::LandingPageStore.enabled?(@current_community.id) &&
  #     @current_community.private &&
  #     !@current_user
  # end

end

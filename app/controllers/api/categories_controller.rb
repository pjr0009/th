class Api::CategoriesController < ApplicationController
  before_action :set_category, only: [:custom_fields]

  def index
    if params[:discipline_id]
      Category.where(discipline_id: params[:discipline_id], parent_id: nil)
    else
      Category.where(:parent_id => nil).limit(10)
    end
  end

  def custom_fields
    render json: @category.custom_fields.includes(:options).map{|c| {name: c.names.first, custom_field: c, type: c.type}}
  end


  private
  
  def set_category
    @category = Category.find(params[:id])
  end
end

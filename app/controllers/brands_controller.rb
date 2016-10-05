class BrandsController < ApplicationController
  before_action :set_brand, only: [:show, :edit, :update, :destroy]

  # GET /brands
  def index
    if params[:q]
      params[:q] = params[:q].capitalize
      @brands = Brand.limit(10).where("name LIKE ?", "#{params[:q]}%")
    else
      @brands = Brand.limit(10)
    end
    render json: @brands
  end

  # GET /brands/1
  def show
    unless @brand.verified
      redirect_to root_path
    end
  end

  # GET /brands/new
  def new
    @brand = Brand.new
  end

  # GET /brands/1/edit
  def edit
  end

  # POST /brands
  def create
    @brand = Brand.new(brand_params)

    if @brand.save
      render json: @brand, status: :created, location: @brand
    else
      render json: @brand, status: :ok
    end
  end

  # PATCH/PUT /brands/1
  def update
    if @brand.update(brand_params)
      redirect_to @brand, notice: 'Brand was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /brands/1
  def destroy
    @brand.destroy
    redirect_to brands_url, notice: 'Brand was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_brand
      @brand = Brand.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def brand_params
      params.require(:brand).permit(:name)
    end
end

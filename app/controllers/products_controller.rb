class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  # GET /products
  def index
    if params[:q]
      params[:q] = params[:q].capitalize
      if params[:brand_id]
        @products = Product.limit(10).where("brand_id = ? AND model LIKE ?", params[:brand_id], "#{params[:q]}%")
      else
        render json: [] and return
      end
    else
      @products = Product.limit(10)
    end
    render json: @products
  end

  # GET /products/1
  def show
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products
  def create
    @product = Product.find_or_initialize_by(product_params)

    if @product.save && @product.new_record?
      render json: @product, status: :created, location: @product
    else
      render json: @product, status: :ok
    end
  end

  # PATCH/PUT /products/1
  def update
    if @product.update(product_params)
      redirect_to @product, notice: 'Product was successfully updated.'
    else
      render :edit
    end
  end



  # DELETE /products/1
  def destroy
    @product.destroy
    redirect_to products_url, notice: 'Product was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def product_params
      params.require(:product).permit(:model, :brand_id)
    end
end

class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  # GET /products
  def index
    if params[:q]
      params[:q] = params[:q].capitalize
      if params[:brand_id]
        @products = Product.limit(10).where("brand_id = ? AND model LIKE ?", params[:brand_id], "#{params[:q]}%")
      else
        @products = Product.limit(10).where("model LIKE ?", "#{params[:q]}%")
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
    @product = Product.new(product_params)

    if @product.save
      render json: @product, status: :created, location: @product
    else
      render json: @brand, status: :ok
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

  def get_estimate
    keywords = "#{params[:brand]}"
    keywords += " #{params[:model]}" if params[:model]
    keywords += " Saddle"
    RestClient.get("http://svcs.ebay.com/services/search/FindingService/v1",
      {
        params: {
          "SECURITY-APPNAME": "PhilliRo-TackHunt-PRD-12f5817e2-c6b274bd", 
          "OPERATION-NAME": "findCompletedItems", 
          "SERVICE-VERSION": "1.0.0", 
          "RESPONSE-DATA-FORMAT": "json", 
          "keywords": keywords, 
          "itemFilter(0).name": "Condition", 
          "itemFilter(0).value": "3000"
        }, 
        headers: {
          "X-EBAY-SOA-SECURITY-APPNAME": "PhilliRo-TackHunt-PRD-12f5817e2-c6b274bd"
        }
      }
    ) {|response| 
        body = JSON.parse(response.body)["findCompletedItemsResponse"].first["searchResult"].first
        render json: quantify_estimate_results(body) and return
      }

  end

  def quantify_estimate_results(body)
    totalSaleValue = 0
    totalSales = 0
    totalOveralSaleValue = 0
    totalOveralSaleValueCount = 0

    formattedResponse = {}

    formattedResponse["sampleSize"] = 0
    formattedResponse["sellability"] = 0
    formattedResponse["averageSellingPrice"] = 0
    formattedResponse["averageAskingPrice"] = 0
    formattedResponse["supply"] = 0
    if body && body["item"]
      body["item"].each do |item|
        if item["sellingStatus"].first["currentPrice"].first["@currencyId"] == "USD"
 
          unless item["sellingStatus"].first["sellingState"].first == "EndedWithoutSales"
            totalSaleValue += item["sellingStatus"].first["currentPrice"].first["__value__"].to_i
            totalSales += 1
          end
          totalOveralSaleValue += item["sellingStatus"].first["currentPrice"].first["__value__"].to_i
          totalOveralSaleValueCount += 1
          formattedResponse["sampleSize"] += 1
        end
      end
      if totalSales > 0 && totalSaleValue > 0
        formattedResponse["averageSellingPrice"] = totalSaleValue/totalSales
      end
      if totalOveralSaleValue > 0 && totalOveralSaleValueCount > 0
        formattedResponse["averageAskingPrice"] = totalOveralSaleValue/totalOveralSaleValueCount
      end
    end
    return formattedResponse
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

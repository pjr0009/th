class Api::SalesController < ApplicationController
  before_action :set_brand, only: [:index]
  before_action :set_product, only: [:index]

  def index
    unless params[:product_id] && params[:brand_id]
      render json: {} and return
    end
    if params[:sync_external]
      sync_external
    end
    formattedResponse = {}
    askingAverageNumerator = 0
    askingAverageDivisor = 0
    soldAverageNumerator = 0
    soldAverageDivisor = 0

    formattedResponse["sampleSize"] = 0
    formattedResponse["sellability"] = 0
    formattedResponse["averageSellingPrice"] = 0
    formattedResponse["averageAskingPrice"] = 0
    formattedResponse["supply"] = 0
    sales = Sale.where(product_id: @product.id, brand_id: @brand.id)
    sales.each do |sale|
      formattedResponse["sampleSize"] += 1
      askingAverageNumerator += sale.asking_price
      soldAverageNumerator += sale.sold_price
      askingAverageDivisor += 1 if sale.asking_price > 0
      soldAverageDivisor += 1 if sale.sold_price > 0
    end
    if soldAverageDivisor > 0
      formattedResponse["averageSellingPrice"] = (soldAverageNumerator / soldAverageDivisor).format
    end
    if askingAverageDivisor > 0
      formattedResponse["averageAskingPrice"] = (askingAverageNumerator / askingAverageDivisor).format
    end
    render json: formattedResponse and return
  end
  private
  def sync_external
    keywords = @brand.name
    keywords += " #{@product.model}"
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
        persist_results(body)
        return true
      }

  end

  def persist_results(body)
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
          sale = Sale.new
          sale.external_source = "eBay"
          sale.external_location = item["itemId"]

          unless item["sellingStatus"].first["sellingState"].first == "EndedWithoutSales"
            saleValue = item["sellingStatus"].first["currentPrice"].first["__value__"].to_i
            sale.sold_price = saleValue
            totalSaleValue += item["sellingStatus"].first["currentPrice"].first["__value__"].to_i
            totalSales += 1

          end
          overalSaleValue = item["sellingStatus"].first["currentPrice"].first["__value__"].to_i
          sale.asking_price = overalSaleValue
          totalOveralSaleValue += item["sellingStatus"].first["currentPrice"].first["__value__"].to_i
          totalOveralSaleValueCount += 1
          formattedResponse["sampleSize"] += 1

          sale.brand = @brand
          sale.product = @product
          begin
            sale.save!
          rescue ActiveRecord::RecordNotUnique => e
            puts e
          end
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

  def set_brand
    @brand = Brand.find(params[:brand_id]) if params[:brand_id]
  end
  
  def set_product
    @product = Product.find(params[:product_id]) if params[:product_id]
  end
end

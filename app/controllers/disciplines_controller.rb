class DisciplinesController < ApplicationController
  include Searchable
  before_action :set_discipline, only: [:show, :edit, :update, :destroy, :categories]

  # GET /disciplines
  def index
    @disciplines = Discipline.all
    render json: @disciplines
  end

  # GET /disciplines/1
  def show
    set_categories
    params[:page] ||= 1
    search_result = find_listings(params[:q], params[:category], @discipline.id, params[:page])
    search_result.on_success { |listings|
        @listings = listings
        render "homepage/index", locals: {
          show_price_filter: false
        }
      }.on_error { |e|
        flash[:error] = t("homepage.errors.search_engine_not_responding")
        @listings = Listing.none.paginate(:per_page => 1, :page => 1)
        render "homepage/index", status: 500, locals: {
          show_price_filter: false
        }
      }


  end

  def categories
    categories = @discipline.categories.where(:parent_id => nil).includes(:translations)
    render json: categories.to_json(:include => :translations)
  end

  # GET /disciplines/new
  def new
    @discipline = Discipline.new
  end

  # GET /disciplines/1/edit
  def edit
  end

  # POST /disciplines
  def create
    @discipline = Discipline.new(discipline_params)

    if @discipline.save
      redirect_to @discipline, notice: 'Discipline was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /disciplines/1
  def update
    if @discipline.update(discipline_params)
      redirect_to @discipline, notice: 'Discipline was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /disciplines/1
  def destroy
    @discipline.destroy
    redirect_to disciplines_url, notice: 'Discipline was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_discipline
      @discipline = Discipline.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def discipline_params
      params[:discipline]
    end
end

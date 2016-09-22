class NewsController < ApplicationController
  before_action :set_post, only: [:show]

  # GET /blogs
  def index
    @posts = Post.all
    @featured_post = Post.first
  end

  # GET /blogs/1
  def show
  end

  # # PATCH/PUT /blogs/1
  # def update
  #   if @blog.update(blog_params)
  #     redirect_to @blog, notice: 'Blog was successfully updated.'
  #   else
  #     render :edit
  #   end
  # end

  # # DELETE /blogs/1
  # def destroy
  #   @blog.destroy
  #   redirect_to blogs_url, notice: 'Blog was successfully destroyed.'
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    # def blog_params
    #   params.require(:post).permit(:title, :partial, :author)
    # end
end

class Admin::TagsController < Admin::BaseController
  before_action :get_tag, except: [:index]

  def index
    @tags = Content::SearchTags[tag_value: "%#{params[:value]}%"].limit(100) if params[:value].present?
  end

  def edit
  end

  def update
    @tag.update_attributes(name: params[:tags][:name],
                           description: params[:tags][:description])
    flash[:notice] = 'The tag has been updated.'
    redirect_to admin_tags_path(value: @tag.value)
  end

  private
  def get_tag
    @tag = Content::Models::Tag.find(params[:id])
  end
end

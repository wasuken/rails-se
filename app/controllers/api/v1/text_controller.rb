class Api::V1::TextController < ApplicationController
  def index
    @texts = Text.all
    render json: {staus: 200,data: @texts}
  end
  def create
    p params[:url]
    Text.create_url_contents(params[:url]) if params[:url]
  end
end

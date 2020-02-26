class Api::V1::TextController < ApplicationController
  def index
    @texts = Text.all
    render json: {staus: 200,data: @texts}
  end
  def store
  end
end

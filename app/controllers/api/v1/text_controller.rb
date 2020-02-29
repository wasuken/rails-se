# coding: utf-8
require "natto"
require "nokogiri"
require "open-uri"

class Proc
  def self_curry
    self.curry.call(self)
  end
end

class Api::V1::TextController < ApplicationController
  def index
    @texts = Text.all.take(30)
    if params[:q]
      @texts = Text.search_query(params[:q])
    end
    render json: { staus: 200, data: @texts }
  end
  def create
    if params[:url] && params[:t] == "deep"
      TextMorpheme.input_deep_contents(params[:url])
    elsif params[:file] && params[:t] == "zip"
      TextMorpheme.input_zip_contents(params[:file], request.env["HTTP_REFERER"])
    elsif params[:url]
      TextMorpheme.input_single_url_contents(params[:url])
    end
  end
end

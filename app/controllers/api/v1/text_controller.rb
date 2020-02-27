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
    @texts = Text.all
    if params[:q]
      nm = Natto::MeCab.new
      nodes = nm.enum_parse(params[:q])
                .select{|n| n.feature.include?('名詞')}
                .select{|n| n.surface.size > 2 }
                .map(&:surface)
      @t_ms = Morpheme
                .joins(:text_morphemes)
                .select("morphemes.value as value", "text_morphemes.count as cnt", "text_morphemes.*")
                .where("value like ?", nodes.map{|x| "%#{x}%"})
                .order(cnt: :desc)
                .take(10)
                .map(&:text_id)
      @texts = Text.where(id: @t_ms).sort_by{|o| @t_ms.index(o.id)}
    end
    render json: {staus: 200,data: @texts}
  end
  def create
    p params
    if params[:url] && params[:t] == "deep"
      uri = URI.parse(params[:url])
      base = "#{uri.scheme}://#{uri.host}"
      watched_list = Text.all.map(&:url)
      f = lambda {|f, u|
        begin
          doc = Nokogiri::HTML(open(URI.encode(u)))
          doc.css("a").each do |a|
            if a.attr("href").match(/^http/) && !watched_list.include?(a.attr("href")) &&
               !watched_list.include?(base + a.attr("href")) &&
               a.attr("href").match(base)
              watched_list << a.attr("href")
              p "in"
              sleep(5)
              Text.create_url_contents(a.attr("href"))
              f.call(f, a.attr("href"))
            elsif a.attr("href").match(/^\//) && !watched_list.include?(a.attr("href")) &&
                  !watched_list.include?(base + a.attr("href"))
              watched_list << (base + a.attr("href"))
              p "in"
              sleep(5)
              Text.create_url_contents(base + a.attr("href"))
              f.call(f, base + a.attr("href"))
            end
          end
        rescue => er
          p er
        end
      }.self_curry.call(base)
    elsif params[:url]
      Text.create_url_contents(params[:url])
    end
  end
end

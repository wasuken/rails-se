# coding: utf-8
require "nokogiri"
require "natto"
require "open-uri"

class Text < ApplicationRecord
  has_many :text_morphemes
  def self.search_query(query)
    nm = Natto::MeCab.new
    nodes = nm.enum_parse(query)
              .select{|n| n.feature.include?('名詞')}
              .select{|n| n.surface.size > 2 }
              .map(&:surface)
    t_ms = Morpheme
              .joins(:text_morphemes)
              .select("morphemes.value as value", "text_morphemes.count as cnt", "text_morphemes.*")
    texts_map = {}
    nodes.map{|x| "%#{x}%"}.each do |v|
      t_ms.where("value like ?", v).all.each do |rec|
        if texts_map[rec.text_id] != nil
          newcnt = texts_map[rec.text_id][:cnt] + rec.count
          texts_map[rec.text_id] = {rec: texts_map[rec.text_id][:rec], cnt: newcnt}
        else
          texts_map[rec.text_id] = {rec: rec, cnt: rec.cnt}
        end
      end
    end
    t_id_lst = texts_map.keys.sort{|a, b| texts_map[b][:cnt] <=> texts_map[a][:cnt]}
    Text.where(id: t_id_lst).sort_by{|o| t_id_lst.index(o.id)}
    # @t_ms = Morpheme
    #           .joins(:text_morphemes)
    #           .select("morphemes.value as value", "text_morphemes.count as cnt", "text_morphemes.*")
    #           .where("value like ?", nodes.map{|x| "%#{x}%"})
    #           .order(cnt: :desc)
    #           .take(10)
    #           .map(&:text_id)
    # Text.where(id: @t_ms).sort_by{|o| @t_ms.index(o.id)}
  end
end

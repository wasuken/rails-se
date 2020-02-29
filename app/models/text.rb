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

    nodes_morp_id_lst = nodes.drop(1)
        .inject(Morpheme.where("value like ?", nodes.first)){|result, item|
      result + Morpheme.where("value like ?", item)
    }.map(&:id).uniq

    p nodes_morp_id_lst
    text_in_including_query_size =
      Text
        .joins(:text_morphemes)
        .where("morpheme_id in (?)", nodes_morp_id_lst)
        .group(:text_id)
        .count
        .keys
        .size

    p text_in_including_query_size

    idf = Math.log(Text.all.size / text_in_including_query_size)
    nodes.map{|x| "%#{x}%"}.each do |v|
      t_ms.where("value like ?", v).all.each do |rec|
        tf = (rec.count * rec.value.size).to_f / Text.find(rec.text_id).contents.size.to_f
        tf_idf = tf * idf
        p "tf = " + tf.to_s
        p "idf = " + idf.to_s
        p "tf_idf = " + tf_idf.to_s
        if texts_map[rec.text_id]
          new_point = texts_map[rec.text_id][:point] + tf_idf
          texts_map[rec.text_id] = {rec: texts_map[rec.text_id][:rec], point: new_point}
        else
          texts_map[rec.text_id] = {rec: rec, point: tf_idf}
        end
      end
    end
    t_id_lst = texts_map.keys.sort{|a, b| texts_map[b][:point] <=> texts_map[a][:point]}
    Text.where(id: t_id_lst).sort_by{|o| t_id_lst.index(o.id)}.take(30)
  end
end

# coding: utf-8
require "nokogiri"
require "natto"
require "open-uri"
require 'digest/sha1'

class Text < ApplicationRecord
  has_many :text_morphemes
  def self.search_query(query)
    nm = Natto::MeCab.new
    nodes = nm.enum_parse(query)
              .map(&:surface)
              .select{|x| !x.size.zero?}
    nodes.push(query)
    p nodes
    t_ms = Morpheme
              .joins(:text_morphemes)
              .select("morphemes.value as value", "text_morphemes.*", "text_morphemes.*")
    texts_map = {}

    nodes_morp_id_lst = nodes.drop(1)
        .inject(Morpheme.where("value like ?", nodes.first)){|result, item|
      result + Morpheme.where("value like ?", item)
    }.map(&:id).uniq

    text_in_including_query_size =
      Text
        .joins(:text_morphemes)
        .where("morpheme_id in (?)", nodes_morp_id_lst)
        .group(:text_id)
        .count
        .keys
        .size
    if text_in_including_query_size.zero?
      p "text_in_including_query_size is zero"
      return
    end
    idf = Math.log(Text.all.size / text_in_including_query_size)
    nodes.map{|x| "%#{x}%"}.each do |v|
      t_ms.where("value like ?", v).all.each do |rec|
        if texts_map[rec.text_id]
          new_point = texts_map[rec.text_id][:point] + rec.score
          texts_map[rec.text_id] = {rec: texts_map[rec.text_id][:rec], point: new_point}
        else
          texts_map[rec.text_id] = {rec: rec, point: rec.score}
        end
      end
    end
    t_id_lst = texts_map.keys.sort{|a, b| texts_map[b][:point] <=> texts_map[a][:point]}
    Text.where(id: t_id_lst).sort_by{|o| t_id_lst.index(o.id)}.take(30)
  end
  def self.create_auto_hash(url, title, contents)
    dg = Digest::SHA1.hexdigest(title + contents)
    Text.create(url: url, contents: contents, title: title, contents_hash: dg)
  end
end

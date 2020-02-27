# coding: utf-8
require "nokogiri"
require "natto"
require "open-uri"

class Text < ApplicationRecord
  def self.create_url_contents(url)
    doc = Nokogiri::HTML(open(url))
    title = doc.title
    contents = doc.text
    text = Text.create(url: url, contents: contents, title: title)
    nm = Natto::MeCab.new
    morp_grp = nm.enum_parse(contents.gsub(/<.*?>/, ''))
                 .select{|n| n.feature.include?('名詞')}
                 .select{|n| n.surface.size > 2 }
                 .map(&:surface)
                 .group_by{|n| n }
                 .sort{|a, b| b[1].size <=> a[1].size}
    morp_grp.each do |m|
      mp = Morpeme.find_or_create_by(value: m[0])
      TextMorpheme.create(morpheme_id: mp.id, text_id: text.id, count: m[1].size)
    end
  end
end

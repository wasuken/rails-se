# coding: utf-8
require "nokogiri"
require "natto"
require "open-uri"

class Text < ApplicationRecord
  has_many :text_morphemes
  def self.create_url_contents(url)
    doc = Nokogiri::HTML(open(URI.encode(url)))
    title = doc.title
    contents = doc.css("body").first.text.gsub(/\n|\t/, ' ')
    text = Text.create(url: url, contents: contents, title: title)
    nm = Natto::MeCab.new
    morp_grp = nm.enum_parse(contents.gsub(/<.*?>/, ''))
                 .select{|n| n.feature.include?('名詞')}
                 .select{|n| n.surface.size > 2 }
                 .map(&:surface)
                 .group_by{|n| n }
    morp_grp.each do |m|
      mp = Morpheme.find_or_create_by(value: m[0])
      p mp
      TextMorpheme.create(morpheme_id: mp.id, text_id: text.id, count: m[1].size)
    end
  end
end

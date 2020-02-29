# coding: utf-8
require "nokogiri"
require "natto"
require "open-uri"
require "zip"

class TextMorpheme < ApplicationRecord
  belongs_to :morpheme
  def self.create_url_contents(url, contents, title)
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
  def self.input_single_url_contents(url)
    doc = Nokogiri::HTML(open(URI.encode(url)))
    title = doc.title
    contents = doc.css("body").first.text.gsub(/\n|\t/, ' ')
    create_url_contents(url, contents, title)
  end
  def self.input_deep_contents(url)
    uri = URI.parse(url)
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
            sleep(5)
            TextMorpheme.input_single_contents_url(a.attr("href"))
            f.call(f, a.attr("href"))
          elsif a.attr("href").match(/^\//) && !watched_list.include?(a.attr("href")) &&
                !watched_list.include?(base + a.attr("href"))
            watched_list << (base + a.attr("href"))
            sleep(5)
            TextMorpheme.input_single_contents_url(base + a.attr("href"))
            f.call(f, base + a.attr("href"))
          end
        end
      rescue => er
        p er
      end
    }.self_curry.call(base)
  end
  def self.input_zip_contents(f, root_url)
    base_uri = root_url + "zip/" + File.basename(f.path) + "/"
    Zip::File.open(f.path) do |zip|
      zip.each do |entry|
        ext = File.extname(entry.name)
        next if ext.blank? || File.basename(entry.name).count(".") > 1
        Tempfile.open([File.basename(entry.to_s), ext]) do |file|
          begin
            entry.extract(file.path) { true }
            path = file.path.sub(/^\.\/|\//, '')
            url = "#{base_uri}#{path}"
            contents = file.read
            create_url_contents(url, contents, File.basename(path))
          ensure
            file.close!
          end
        end
      end
    end
  end
end

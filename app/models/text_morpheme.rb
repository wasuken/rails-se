# coding: utf-8
require "nokogiri"
require "natto"
require "open-uri"
require "zip"

class Proc
  def self_curry
    self.curry.call(self)
  end
end

class TextMorpheme < ApplicationRecord
  belongs_to :morpheme
  def self.create_url_contents(url, contents, title)
    ActiveRecord::Base.transaction do
      begin
        text = Text.create_auto_hash(url, title, contents)
        nm = Natto::MeCab.new
        morps = nm.enum_parse(contents)
        # .select{|n| n.feature.include?('名詞')}
        # .select{|n| n.surface.size > 2 }
        morp_grp = morps
                     .map(&:surface)
                     .group_by{|n| n }
        morp_grp.each do |m|
          # 現時点での結果。最後にidfとtf-idfを更新する。
          mp = Morpheme.find_or_create_by(value: m[0])
          text_in_including_query_size =
            Text
              .joins(:text_morphemes)
              .where("morpheme_id = ?", mp.id)
              .group(:text_id)
              .count
              .keys
              .size
          idf = Math.log(Text.count.to_f / text_in_including_query_size.to_f)
          tf = m[1].size.to_f / nm.enum_parse(contents).size.to_f
          tf_idf = tf * idf
          TextMorpheme.create(morpheme_id: mp.id, text_id: text.id, tf: tf, idf: idf, score: tf_idf)
        end
      rescue => er
        p er
        raise ActiveRecord::Rollback
      end
    end
  end
  def self.update_tf_idf()
    Morpheme.all.each do |m|
      text_in_including_query_size =
        Text
          .joins(:text_morphemes)
          .where("morpheme_id = ", m.id)
          .group(:text_id)
          .count
          .keys
          .size
      idf = Math.log(Text.count.to_f / text_in_including_query_size.to_f)
      TextMorpheme.all.each do |t|
        TextMorpheme
          .where("text_id = ?", t.id)
          .where("morpheme_id = ?", m.id).each do |tm|
          tm.idf = idf
          tm.score = tm.tf * idf
          tm.save
        end
      end
    end
  end
  def self.input_single_url_contents(url)
    doc = Nokogiri::HTML(open(URI.encode(url)))
    title = doc.title
    contents = doc.css("body").first.text.gsub(/\n|\t/, ' ')
    create_url_contents(url, contents.gsub(/<.*?>/, ''), title)
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
            path = File.basename(file.path)
            url = "#{base_uri}#{path}"
            contents = file.read
            create_url_contents(url,
                                contents.force_encoding("UTF-8"),
                                path.split(".").first.force_encoding("UTF-8"))
          ensure
            file.close!
          end
        end
      end
    end
  end
end

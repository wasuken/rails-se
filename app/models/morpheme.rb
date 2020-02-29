# coding: utf-8
require "natto"
require "nokogiri"
require "open-uri"

class Morpheme < ApplicationRecord
  has_many :text_morphemes
end

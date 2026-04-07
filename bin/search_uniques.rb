#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'json'

DATA_PATH = File.expand_path('../data/uniques.json', __dir__)

def usage
  warn 'Usage: ruby bin/search_uniques.rb "search text"'
  warn '   or: ruby bin/search_uniques.rb word1 word2 word3'
end

queries = ARGV.map(&:strip).reject(&:empty?)
if queries.empty?
  usage
  exit 1
end

normalized_queries = queries.map(&:downcase)

unless File.exist?(DATA_PATH)
  warn "Data file not found: #{DATA_PATH}"
  warn 'Run `ruby bin/fetch_uniques.rb` first.'
  exit 1
end

items = JSON.parse(File.read(DATA_PATH))

csv = CSV.generate do |out|
  out << %w[name item_type effect_text url]

  items.each do |item|
    effect_text = item.fetch('effect_text', '')
    normalized_effect_text = effect_text.downcase
    next unless normalized_queries.any? { |query| normalized_effect_text.include?(query) }

    out << [item['name'], item['item_type'], effect_text, item['url']]
  end
end

$stdout.write(csv)

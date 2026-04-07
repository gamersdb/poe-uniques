#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'json'

DATA_PATH = File.expand_path('../data/uniques.json', __dir__)

def usage
  warn 'Usage: ruby bin/search_uniques.rb "search text"'
end

query = ARGV[0]
if query.nil? || query.empty?
  usage
  exit 1
end

normalized_query = query.downcase

unless File.exist?(DATA_PATH)
  warn "Data file not found: #{DATA_PATH}"
  warn 'Run `ruby bin/fetch_uniques.rb` first.'
  exit 1
end

items = JSON.parse(File.read(DATA_PATH))

csv = CSV.generate do |out|
  out << %w[name effect_text url]

  items.each do |item|
    effect_text = item.fetch('effect_text', '')
    next unless effect_text.downcase.include?(normalized_query)

    out << [item['name'], effect_text, item['url']]
  end
end

$stdout.write(csv)

#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'time'
require 'uri'

SOURCE_PAGE = 'https://poedb.tw/us/Unique_item'
OUTPUT_PATH = File.expand_path('../data/uniques.json', __dir__)

def normalize_text(text)
  text.to_s.gsub("\u00A0", ' ').gsub(/[[:space:]]+/, ' ').strip
end

def category_name(tab_pane)
  header = normalize_text(tab_pane.at_css('h5.card-header')&.text)
  header.sub(%r{\s*/\d+\z}, '')
end

def item_cards(tab_pane)
  tab_pane.css('div.d-flex.border-top.rounded')
end

def item_link(card)
  card.css('a.uniqueitem').find { |node| node.at_css('.uniqueName') }
end

def extract_effects(card)
  card.css('.implicitMod, .explicitMod').map { |node| normalize_text(node.text) }.reject(&:empty?)
end

def extract_item(card, category, fetched_at)
  link = item_link(card)
  return nil unless link

  name = normalize_text(link.at_css('.uniqueName')&.text)
  return nil if name.empty?

  effects = extract_effects(card)
  {
    name: name,
    base_type: normalize_text(link.at_css('.uniqueTypeLine')&.text).yield_self { |value| value.empty? ? nil : value },
    category: category,
    url: URI.join(SOURCE_PAGE, link['href']).to_s,
    effects: effects,
    effect_text: effects.join("\n"),
    source_page: SOURCE_PAGE,
    fetched_at: fetched_at
  }
end

def fetch_html
  URI.open(
    SOURCE_PAGE,
    'User-Agent' => 'poe-uniques-fetcher/1.0',
    read_timeout: 30,
    open_timeout: 30
  ).read
end

html = fetch_html
document = Nokogiri::HTML(html)
fetched_at = Time.now.iso8601

items = document.css('.tab-content > .tab-pane').flat_map do |tab_pane|
  category = category_name(tab_pane)
  next [] if category.empty?

  item_cards(tab_pane).map do |card|
    extract_item(card, category, fetched_at)
  end.compact
end

abort('Failed to extract any unique items from PoEDB.') if items.empty?

FileUtils.mkdir_p(File.dirname(OUTPUT_PATH))
File.write(OUTPUT_PATH, JSON.pretty_generate(items))

warn "Wrote #{items.size} items to #{OUTPUT_PATH}"

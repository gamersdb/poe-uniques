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

IMAGE_PATH_TYPE_RULES = [
  [%r{/Weapons/.*/Wands/}i, 'wand'],
  [%r{/Weapons/.*/Daggers/}i, 'dagger'],
  [%r{/Weapons/.*/Claws/}i, 'claw'],
  [%r{/Weapons/.*/Sceptres/}i, 'sceptre'],
  [%r{/Weapons/.*/RuneDaggers/}i, 'rune_dagger'],
  [%r{/Weapons/.*/OneHandAxes/}i, 'axe'],
  [%r{/Weapons/.*/TwoHandAxes/}i, 'axe'],
  [%r{/Weapons/.*/OneHandMaces/}i, 'mace'],
  [%r{/Weapons/.*/TwoHandMaces/}i, 'mace'],
  [%r{/Weapons/.*/OneHandSwords/}i, 'sword'],
  [%r{/Weapons/.*/TwoHandSwords/}i, 'sword'],
  [%r{/Weapons/.*/Bows/}i, 'bow'],
  [%r{/Weapons/.*/Staves/}i, 'staff'],
  [%r{/Weapons/.*/FishingRods/}i, 'fishing_rod'],
  [%r{/Weapons/.*/Warstaves/}i, 'warstaff'],
  [%r{/Armours/Helmets/}i, 'helmet'],
  [%r{/Armours/Boots/}i, 'boots'],
  [%r{/Armours/Gloves/}i, 'gloves'],
  [%r{/Armours/BodyArmours/}i, 'body_armour'],
  [%r{/Armours/Shields/}i, 'shield'],
  [%r{/Belts/}i, 'belt'],
  [%r{/Rings/}i, 'ring'],
  [%r{/Amulets/}i, 'amulet'],
  [%r{/Quivers/}i, 'quiver'],
  [%r{/Flasks/}i, 'flask'],
  [%r{/Jewels/}i, 'jewel']
].freeze

BASE_TYPE_SUFFIX_RULES = [
  [%r{\bwand\z}i, 'wand'],
  [%r{\bdagger\z}i, 'dagger'],
  [%r{\bclaw\z}i, 'claw'],
  [%r{\bsceptre\z}i, 'sceptre'],
  [%r{\brune dagger\z}i, 'rune_dagger'],
  [%r{\baxe\z}i, 'axe'],
  [%r{\bmace\z}i, 'mace'],
  [%r{\bsword\z}i, 'sword'],
  [%r{\bbow\z}i, 'bow'],
  [%r{\bstaff\z}i, 'staff'],
  [%r{\bwarstaff\z}i, 'warstaff'],
  [%r{\bhelmet\z}i, 'helmet'],
  [%r{\bhelm\z}i, 'helmet'],
  [%r{\bboots\z}i, 'boots'],
  [%r{\bslippers\z}i, 'boots'],
  [%r{\bgreaves\z}i, 'boots'],
  [%r{\bshoes\z}i, 'boots'],
  [%r{\bgloves\z}i, 'gloves'],
  [%r{\bmitts\z}i, 'gloves'],
  [%r{\bgauntlets\z}i, 'gloves'],
  [%r{\bvambraces\z}i, 'gloves'],
  [%r{\bshield\z}i, 'shield'],
  [%r{\bring\z}i, 'ring'],
  [%r{\bamulet\z}i, 'amulet'],
  [%r{\bbelt\z}i, 'belt'],
  [%r{\bquiver\z}i, 'quiver'],
  [%r{\bflask\z}i, 'flask'],
  [%r{\bjewel\z}i, 'jewel']
].freeze

BASE_TYPE_KEYWORD_RULES = [
  [%r{\bcuirass\b|\bdoublet\b|\bvest\b|\brobe\b|\btunic\b|\bcoat\b|\barmour\b|\bbrigandine\b|\bmail\b|\bjack\b|\bplate\b}i, 'body_armour']
].freeze

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

def image_src(card)
  card.at_css('img')&.[]('src')
end

def item_type_from_image_path(src)
  return nil if src.nil? || src.empty?

  IMAGE_PATH_TYPE_RULES.each do |pattern, item_type|
    return item_type if src.match?(pattern)
  end

  nil
end

def item_type_from_base_type(base_type)
  return nil if base_type.nil? || base_type.empty?

  BASE_TYPE_SUFFIX_RULES.each do |pattern, item_type|
    return item_type if base_type.match?(pattern)
  end

  BASE_TYPE_KEYWORD_RULES.each do |pattern, item_type|
    return item_type if base_type.match?(pattern)
  end

  nil
end

def derive_item_type(card, base_type)
  item_type_from_image_path(image_src(card)) || item_type_from_base_type(base_type)
end

def extract_item(card, category, fetched_at)
  link = item_link(card)
  return nil unless link

  name = normalize_text(link.at_css('.uniqueName')&.text)
  return nil if name.empty?

  base_type = normalize_text(link.at_css('.uniqueTypeLine')&.text).yield_self { |value| value.empty? ? nil : value }
  effects = extract_effects(card)
  {
    name: name,
    base_type: base_type,
    item_type: derive_item_type(card, base_type),
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

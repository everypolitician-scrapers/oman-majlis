#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  html = open(url).read.sub(/(Abdullah bin Hamoud Al Nadabi and).*(Hamid bin Mohammed Al Rawahi)/ms, '\1 \2')
  Nokogiri::HTML(html)
end

def scrape_list(url)
  noko = noko_for(url)
  start = noko.xpath('//p[span[contains(.,"WINNERS LIST")]]')
  box = start.xpath('following-sibling::ul | following-sibling::p | following-sibling::div').slice_before { |e| e.name == 'div' }.first
  region = "Governorate of Muscat"

  box.each do |node|
    if node.name == 'p'
      region = node.text
    elsif node.name == 'ul'
      node.css('li').each do |li|
        wilayah, who = li.text.split(/:,?\s*/, 2).map(&:tidy)
        area_id = "ocd-division/country:om/region:%s/wilayah:%s" % [region, wilayah].map { |str| str.downcase.gsub(/[[:space:]]/, '_') }

        who.split(/ and /).each do |name|
          data = { 
            name: name.sub(/\.$/,''),
            region: region,
            area: wilayah,
            area_id: area_id,
            party: 'None',
            term: 7,
            source: url,
          }
          ScraperWiki.save_sqlite([:name, :area_id, :term], data)
        end
      end
    end
  end
end

term = { 
  id: 7,
  name: '7th Period',
  start_date: 2011,
}
ScraperWiki.save_sqlite([:id], term, 'terms')


scrape_list('http://www.khaleejtimes.com/article/20111017/ARTICLE/310179889/1016')

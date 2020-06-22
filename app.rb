require 'open-uri'
require 'nokogiri'
require 'json'
require 'active_support/core_ext/hash'
require 'sinatra'
require 'pp'

feeds = []

xml_sources = [
  {
    'id' => 'hackernews',
    'url' => 'https://hnrss.org/frontpage'
  },
  {
    'id' => 'slashdot',
    'url' => 'http://rss.slashdot.org/Slashdot/slashdotDevelopers'
  },
  {
    'id' => 'reddit',
    'url' => 'https://www.reddit.com/r/programming.rss'
  },
  {
    'id' => 'lobsters',
    'url' => 'https://lobste.rs/rss'
  }
]

def build_json_from_xml_url(xml_url)
  xml = Nokogiri::XML(URI.open(xml_url, 'User-Agent' => 'Mozilla/5.0 feed parser')).to_xml
  json = Hash.from_xml(xml).to_json
end

def build_feed_from_json(json, xml_source_id)
  feed = []
  parsed_json = JSON.parse(json)
end

def build_feed_item(title, link, date, host)
  return {
    'title' => title,
    'link' => link,
    'date' => date,
    'host' => host
  }
end

def build_feed(xml_sources)
  feeds = []

  xml_sources.each do |xml_source|
    feed = []
    xml_source_url = xml_source['url']
    xml_source_id = xml_source['id']

    json = JSON.parse(build_json_from_xml_url(xml_source_url))
    
    case xml_source_id
    when 'hackernews'
      json['rss']['channel']['item'].each do |item|
        begin
          title = item['title']
          link = item['link']
          date = item['pubDate'] 
          host = URI.parse(link).host.sub('www.', '')
          feed_item = build_feed_item(title, link, date, host)
          feed << feed_item
        rescue URI::InvalidURIError => e
          # do nothing
        end
      end
    when 'reddit'
      json['feed']['entry'].each do |item|
        begin
          title = item['title']
          link = item['link']['href']
          date = item['updated']
          host = URI.parse(link.sub(',','')).host.sub('www.', '')
          feed_item = build_feed_item(title, link, date, host)
          feed << feed_item
        rescue URI::InvalidURIError
          # do nothing
        end
      end
    when 'slashdot'
      json['RDF']['item'].each do |item|
        begin
          title = item['title']
          link = item['origLink']
          date = item['date']
          host = URI.parse(link).host.sub('www.', '')
          feed_item = build_feed_item(title, link, date, host)
          feed << feed_item
        rescue URI::InvalidURIError
          # do nothing
        end
      end
    when 'lobsters'
      json['rss']['channel']['item'].each do |item|
        begin
          title = item['title']
          link = item['link']
          date = item['pubDate']
          host = URI.parse(link).host.sub('www.', '')
          feed_item = build_feed_item(title, link, date, host)
          feed << feed_item
        rescue URI::InvalidURIError
          # do nothing
        end
      end
    else
    end
    feeds << feed
  end

  feeds.flatten!.shuffle
end

def export_feed(feed)
  File.open('feed.json', 'w') do |file|
    if (file.write(feed.to_json))
      puts "Written feed to JSON"
    end
  end
end

def export_stats
  stats = {
    'updated_at' => Time.now
  }

  File.open('stats.json', 'w') do |file|
    if (file.write(stats.to_json))
      puts "Written stats to JSON"
    end
  end
end

def build_and_export_feed(xml_sources)
  feed = build_feed(xml_sources)
  export_feed(feed)
  export_stats
end

build_and_export_feed(xml_sources)

Thread.new do
  while true do
    sleep 60 * 15
    build_and_export_feed(xml_sources)
  end
end

get '/' do
  html = File.open('index.html').read
end

get '/feed' do
  File.open('feed.json').read
end

get '/stats' do
  File.open('stats.json').read
end

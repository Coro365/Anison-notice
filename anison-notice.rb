require "pp"
require "json"
require "open-uri"
require "rss"
require "Date"
require "nokogiri"
Dir[File.dirname(__FILE__) + "/anison-notice/*.rb"].each {|file| require file}

VERSION = "0.9.0"
PATH = File.dirname(__FILE__)+"/anison-notice"

init_check

@goods = Array.new
animetick_tids(ANIMETICK_ID).each_with_index do |tid, idx|
  next if MAXI_ANIMES <= idx
  syobo_goods(tid)
end
anime_goods_save

renge_days
today_release_goods = Array.new
released_soon_goods =  Array.new

@goods.each do |item|
  next unless item[:genre] == "music"
  if @renge_days.include?(item[:date])
    released_soon_goods.push(item)
  end

  if @today == item[:date]
    today_release_goods.push(item)
  end
end

soon_goods_pb_message(released_soon_goods)
today_goods_pb_message(today_release_goods)

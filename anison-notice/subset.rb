
def init_check
  if ANIMETICK_ID.empty? || TOKEN.empty?
    puts("ERROR: Please edit ANIMETICK_ID and TOKEN in config.rb")
    exit
  end
end

def animetick_tids(userid)
  url = "http://animetick.net/users/#{userid}"
  animetick_subscribes = Array.new
  begin
    atick = Nokogiri::HTML.parse(open(url),nil,"utf-8")
  rescue Exception => e
    puts "#{e.message} #{url}" 
  end

  atick.xpath("//li[@class='animation']").each do |i|
    imgurl = i.xpath("div[@class='icon']/img").attribute("src").value
    title = i.xpath("div[@class='detail']").attribute("title").value
    tid = imgurl.slice(6..9)
    title.slice!(/\(第[0-9]*?クール\)/)
    animetick_subscribes.push(tid)
  end
  return animetick_subscribes.uniq
end

def re_genre(genre)
  genre = "music" if genre.match(/音楽/)
  genre = "dvd" if genre.match(/DVD/)
  genre = "book" if genre.match(/本|Ebook|eBooks/)
  genre = "game" if genre.match(/ゲーム/)
  genre = "hobby" if genre.match(/Hobby/)
  return genre
end

def syobo_goods(tid)
  syobo_url = "http://cal.syoboi.jp/tid/#{tid}/goods"
  begin
    syobo_html = Nokogiri::HTML.parse(open(syobo_url),nil,"utf-8")
  rescue Exception => e
    puts "#{e.message} #{syobo_url}" 
  end

  anime_name = syobo_html.title
  anime_name.slice!(": グッズ - しょぼいカレンダー")

  syobo_html.xpath("//div[@id='tid_goods']/table").each do |genre_teble|

    genre = genre_teble.xpath(".//tr/th").text
    if genre.match(/音楽|DVD|本|Ebook|eBooks|ゲーム|Hobby/)
      genre = re_genre(genre)
    end

    genre_teble.xpath(".//tr/td/table/tr/td[2]").each do |goods_node|
      title = goods_node.xpath(".//div[@class='title']").text    
      url = goods_node.xpath(".//div[@class='title']/a").attr("href").value
      asin = url.match(/ASIN\/(.*?)\//)[1]
      date = goods_node.text.split("発売日: ")[1]
      @goods.push({:asin => asin, :title => title, :url => url, :date => date, :genre => genre, :anime_name => anime_name})
    end

  end
end

def anime_goods_save
  json_data = JSON.pretty_generate(@goods)
  open(PATH+"/anime_goods.json", 'w') {|f|f.print json_data}
end

def renge_days
  today = Date.today
  @today = today.strftime("%Y-%m-%d")
  #@today = "2017-07-26"
  @renge_days = Array.new
  DAY_RANGE.times do |i|
    @renge_days.push(today.next_day(i+1).strftime("%Y-%m-%d"))
  end
end

def today_goods_pb_message(today_goods)
  return if today_goods.empty?
  title = message = ""
  if today_goods.size == 1
    #title = "#{today_goods[0][:anime_name]} のAnisonが今日リリースされます"
    title = "Today #{today_goods[0][:anime_name]} anison released!"
    message = today_goods[0][:title]  
  elsif today_goods.size >= 2
    anime_names = anime_names_to_string(today_goods)
    #title = "#{anime_names} など#{today_goods.size}個ののAnisonが今日リリースされます"
    title = "Today #{today_goods.size} anisons such as #{anime_names} released!"
  
    today_goods.each do |item|
      message = message + item[:anime_name] + " " + item[:date] + "\n"
      message = message + item[:title] + "\n"
      message = message + "\n"
    end
  end
  puts title
  print message
  sent_push(title, message)
end

def soon_goods_pb_message(soon_goods)
  return if soon_goods.empty?
  title = message = ""
  if soon_goods.size == 1
    #title = "#{soon_goods[0][:anime_name]} のAnisonが#{DAY_RANGE}日中にリリースされます"
    title = "#{soon_goods[0][:anime_name]} anison released in #{DAY_RANGE} days"

    message = soon_goods[0][:title]  
  elsif soon_goods.size >= 2
    anime_names = anime_names_to_string(soon_goods)
    #title = "#{anime_names} など#{soon_goods.size}個ののAnisonが#{DAY_RANGE}日中にリリースされます"
    title = "#{soon_goods.size} anisons such as #{anime_names} released in #{DAY_RANGE} days"
    
    soon_goods.each do |item|
      message = message + item[:anime_name] + " " + item[:date] + "\n"
      message = message + item[:title] + "\n"
      message = message + "\n"
    end
  end
  puts title
  print message
  sent_push(title, message)
end

def anime_names_to_string(goods)
  anime_names = Array.new
  goods.each do |item|
    anime_names.push(item[:anime_name])
  end
  anime_names = anime_names.uniq
  anime_names = anime_names[0..3] if anime_names.size >= 4
  return anime_names.join(", ")
end

require 'washbullet'

PB_PATH = File.dirname(__FILE__)

def get_uid
  begin
    api_response = `curl -s -u #{TOKEN}: https://api.pushbullet.com/v2/users/me`  
  rescue Exception => e
    error("Pushbullet API(uid) error.")
    return
  end
  userId = JSON.parse(api_response)
  return userId["iden"]
end

def get_did
  begin
    api_response = `curl -s -u #{TOKEN}: https://api.pushbullet.com/v2/devices`
  rescue Exception => e
    error("Pushbullet API(did) error.")
    return
  end
  raw_d_infos = JSON.parse(api_response)

  d_ids = Hash.new
  raw_d_infos["devices"].size.times do |i|
    d_name = raw_d_infos["devices"][i]["nickname"]
    d_id = raw_d_infos["devices"][i]["iden"]
    d_ids[d_name] = d_id
  end
  return d_ids
end

def sent_push(title, message)
  client = Washbullet::Client.new(TOKEN)

  @push_info["dids"].each do |d_name, d_id|
    next if d_name.nil? || d_name.empty?
    DEVICES.each do |device|
      if device == d_name || device == "*"
        client.push_note(
          receiver:   :device, 
          identifier:  d_id, 
          params: {title: title, body:  message})
      end
    end
  end
  puts "Pushbullet done."
end

def create_pb_cache
  uid = get_uid
  dids = get_did
  push_info = {
    "update" => Time.now, 
    "uid" => uid, 
    "dids" => dids}

  json_save(push_info, "/pb_cache.json")
  puts "Pushbullet cache done."
  return push_info
end

def read_pb_cache
  json_read("/pb_cache.json")
end

def get_push_info
  return create_pb_cache if read_pb_cache.empty?
  return read_pb_cache
end

def json_save(json_data, file_name)
  json_data = JSON.pretty_generate(json_data)
  open(PB_PATH+file_name, 'w') {|f|f.print json_data}
end

def json_read(file_name)
  begin
    json_data = open(PB_PATH+file_name) { |io| JSON.load(io)}
  rescue
    puts("read error #{PB_PATH+file_name}") 
    return []
  end
  return json_data
end

def push_test
  print("Pushbullet test\n")
  sent_push("Pushbullet test", "(/ﾟｰﾟ)ﾟｰﾟ)ﾉ Taad\n#{Time.now}")
end

@push_info = get_push_info
#push_test
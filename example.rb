require_relative 'ct' #example.rb must in the same path with ct.rb

$ws = Manager.new

def $ws.onMessage(room, user, message) 
    puts "#{room.name}: <#{user.name}> #{message.body}"
    if message.body == "halo" 
        room.message "halo juga " + user.name
    end
    if message.body == "leave" 
        $ws.leaveRoom("monosekai")
        room.message "leave room monosekai"
    end
    if message.body == "join" 
        $ws.joinRoom("monosekai")
        room.message "join room monosekai"
    end
end

$ws.start ["nico-nico", "ws4py"]

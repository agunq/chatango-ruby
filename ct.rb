#!/usr/bin/ruby
#author agunq 
#contact: <agunq.e@gmail.com>
#file ct.rb
#Require Ruby 2.0

require 'socket'
require 'uri'
require 'net/http'

def getServer(group)
    
    tsweights = [['5', 75], ['6', 75], ['7', 75], ['8', 75], ['16', 75], ['17', 75], ['18', 75], ['9', 95], ['11', 95], ['12', 95], ['13', 95], ['14', 95], ['15', 95], ['19', 110], ['23', 110], ['24', 110], ['25', 110], ['26', 110], ['28', 104], ['29', 104], ['30', 104], ['31', 104], ['32', 104], ['33', 104], ['35', 101], ['36', 101], ['37', 101], ['38', 101], ['39', 101], ['40', 101], ['41', 101], ['42', 101], ['43', 101], ['44', 101], ['45', 101], ['46', 101], ['47', 101], ['48', 101], ['49', 101], ['50', 101], ['52', 110], ['53', 110], ['55', 110], ['57', 110], ['58', 110], ['59', 110], ['60', 110], ['61', 110], ['62', 110], ['63', 110], ['64', 110], ['65', 110], ['66', 110], ['68', 95], ['71', 116], ['72', 116], ['73', 116], ['74', 116], ['75', 116], ['76', 116], ['77', 116], ['78', 116], ['79', 116], ['80', 116], ['81', 116], ['82', 116], ['83', 116], ['84', 116]]
    
    group = group.gsub("_", "q")
    group = group.gsub("-", "q")
    fnv = group[0, [5, group.length].min].to_i(base=36).to_f
    lnv = group[6, [3, (group.length - 5)].min]
    
    if lnv
      lnv = lnv.to_i(base=36).to_f
      lnv = [lnv, 1000].max
    else
      lnv = 1000
    end
      
    num = (fnv % lnv) / lnv
    maxnum = tsweights.map{|x| x[1]}.inject { |sum, x| sum + x }
    cumfreq = 0
    sn = 0
    for wgt in tsweights
        
        cumfreq += (wgt[1].to_f / maxnum)
        if(num <= cumfreq)
            sn = wgt[0].to_i
            break
        end
    end

    return "s" + sn.to_s + ".chatango.com"
end

def genUid
    return rand(10 ** 15 .. 10 ** 16).to_s
end

def getAnonId(n, id) 
    if n == nil
        n = "5504"
    end
    j = n.split("").map{|x| x.to_i}
    k = id[4,id.length].split("").map{|x| x.to_i}
    l = j.zip(k)
    m = l.map{|x| (x[0] + x[1]).to_s[-1]}
    return m.join("")
end

def strip_html(msg)
    msg = msg.gsub(/<\/?[^>]*>/, "")
    return msg
end

def clean_message(text)
    c = text.match("<n(.*?)\/>")
    f = text.match("<f(.*?)>")
    if c
        c = c.captures[0]
    end
    if f 
        f = f.captures[0]
    end
    text = text.sub("<n.*?/>", "")
    text = text.sub("<f.*?>", "")
    text = strip_html(text)
    text = text.gsub("&lt;", "<")
    text = text.gsub("&gt;", ">")
    text = text.gsub("&quot;", "\"")
    text = text.gsub("&apos;", "'")
    text = text.gsub("&amp;", "&")
    return text, c, f
end

def parseFont(f)
    if f != nil
        sizecolor, fontface = f.split("=", 1)
        sizecolor = sizecolor.strip()
        size = sizecolor[1,3].to_i
        col = sizecolor[3,3]
        if col == ""
            col = nil
        end
        face = f.split("\"", 2)[1].split("\"", 2)[0]
        return col, face, size
    else
        return nil, nil, nil
    end
end 

class Task_

    attr_accessor :mgr, :target, :evt, :isInterval, :args, :timeout

    def initialize(mgr, timeout, isInterval, evt, args)
        @mgr = mgr
        @target = Time.now.to_f + timeout
        @evt = evt
        @isInterval = isInterval
        @args = args
        @timeout = timeout
    end
    
    def newtarget
        @target = Time.now.to_f + timeout
    end
 
    def inspect
        return "<Task: #{target}>"
    end
end


$users = {}
def User(name)
    if not $users.include?(name)
        user = User_.new name
        $users[name] = user
    else
        user = $users[name]
    end
    return user
end

class User_

    attr_accessor :name, :rawname, :nameColor, :fontSize, :fontFace, :fontColor

    def initialize(name)
        @name = name
        @rawname = name
        @nameColor = "000"
        @fontSize = 12
        @fontFace = "0"
        @fontColor = "000"
    end
    
    def setNameColor n
        @nameColor = n
    end

    def setFontColor n
        @fontColor = n
    end

    def setFontFace n
        @fontFace = n
    end

    def setFontSize n
        @fontSize = n
    end

    def inspect
        return "<User: #{rawname}>"
    end

    def to_s
        return "<User: #{rawname}>"
    end
end


class Message
    
    attr_accessor :user, :body, :msgid, :room

    def initialize(room, user, body, msgid)
        @user = user
        @body = body
        @msgid = msgid
        @room = room
    end
    
    def attach(room, msgid)
        @msgid = msgid
        @room = room
    end
    
    def detach(room, msgid)
        @msgid = msgid
        @room = room
    end
    
    def inspect
        return "<Message: #{user}>"
    end
end

class Pm
   
    def initialize(mgr)
        @auid = nil
        @server = "c1.chatango.com"
        @connected = false
        @mgr = mgr
    end
    
    def socket
        return @socket
    end
    
    def connected
        return @connected 
    end
   
    def auth
        if @mgr.username !=nil and @mgr.password !=nil
            uri = URI('http://chatango.com/login')
            params = {
                "user_id" => @mgr.username,
                "password" => @mgr.password,
                "storecookie" => "on",
                "checkerrors" => "yes"
                }
            uri.query = URI.encode_www_form(params)
            res = Net::HTTP.get_response(uri)
            cookie = res['set-cookie'].match("auth\.chatango\.com ?= ?([^;]*)").captures
            if cookie
                @auid = cookie[0]
            end
            @socket.write("tlogin:#{@auid}:2\x00")
        end
    end
   
    def ping h
        #puts h
        @socket.write("\r\n\x00")
    end
   
    def connect
        @socket = TCPSocket.new @server, 443 #5222
        auth
        @connected = true
        setInterval(20, :ping, "Ping! at <PM>")
    end
   
    def message user, msg
        @socket.write("msg:#{user}:#{msg}\r\n\x00")
    end
   
    def disconnect
        if @connected == true
            if @socket.closed? == false 
                @socket.close   
            end
            @connected = false
        end
    end
   
    def process(data)
        data = data.split("\x00")
        for d in data
            food = d.split(":")
            if food.length > 0
                cmd = "rcmd_" + food[0]
                if self.respond_to?(cmd)
                    self.send(cmd, food) 
                end
            end
        end
    end
   
    def rcmd_msg args
        user = User args[1]
        body = strip_html args[6, args.length].join ":"
        body = body[0, body.length-2]
        onPMMessage(self, user, body)
    end
   
    def setInterval timeout, evt, *args
        task = Task_.new(self, timeout, true, evt, *args)
        @mgr.add_task task
    end
   
    def setTimeout timeout, evt, *args
        task = Task_.new(self, timeout, false, evt, *args)
        @mgr.add_task task
    end
   
    def callEvent evt, *args
        if @mgr.respond_to?(evt)
            @mgr.send(evt, *args)
        end
    end
   
    def onPMMessage(pm, user, message)
        callEvent(:onPMMessage, pm, user, message)
    end
    
    def inspect
        return "<Pm: #{@mgr.user}>"
    end
end 

class Room
    
    def initialize(mgr, name)
        @name = name
        @uid = genUid
        @server = getServer(name)
        @connected = false
        @mgr = mgr
        @mqueue = nil
        @socket = nil
        @status = {}
    end
    
    def name 
        return @name 
    end
    
    def socket
        return @socket
    end
    
    def connected
        return @connected 
    end
    
    def auth
        if @mgr.username !=nil and @mgr.password !=nil
            @socket.write("bauth:#@name:#@uid:#{@mgr.username}:#{@mgr.password}\x00")
        # login as anon
        else
            @socket.write("bauth:#@name:#@uid\x00")
        end
    end
    
    def ping h
        #puts h
        @socket.write("\r\n\x00")
    end
    
    def connect
        @socket = TCPSocket.new @server, 443
        auth
        @connected = true
        setInterval(20, :ping, "Ping! at #{@name}")
    end
    
    def message msg, html = false
        if html == false
            msg = msg.gsub( "<", "&lt;")
            msg = msg.gsub( ">", "&gt;")
        end
        msgs = msg.chars.each_slice(2000).map(&:join)
        s, c, f = @mgr.user.fontSize, @mgr.user.fontColor, @mgr.user.fontFace
        for msg in msgs
            msg = "<n#{@mgr.user.nameColor}/><f x#{s}#{c}=\"#{f}\">#{msg}</f>"
            @socket.write("bmsg:t12r:#{msg}\r\n\x00")
        end
    end
    
    def disconnect
        if @connected == true
            if @socket.closed? == false 
                @socket.close   
            end
            @connected = false
            onDisconnect(self)
        end
    end

    def userlist
        return @status.values
    end
    
    def setBgMode mode
        @socket.write("msgbg:" + mode.to_s + "\r\n\x00")
    end
    
    def setRecordingMode mode
        @socket.write("msgmedia:" + mode.to_s + "\r\n\x00")
    end
    
    def process(data)
        data = data.split("\x00")
        for d in data
            food = d.split(":")
            if food.length > 0
                cmd = "rcmd_" + food[0]
                if self.respond_to?(cmd)
                    self.send(cmd, food)
                end
            end
        end
    end 
    
    def rcmd_ok args
        if args[3] == "C" and @mgr.username == nil and @mgr.password == nil
            n = args[5].split('.')[0]
            n = n[-4, n.length]
            aid = args[2][0, 8]
            pid = "!anon" + getAnonId(n, aid)
            @mgr.user.setNameColor n
        elsif args[3] == "C" and @mgr.password == nil
            @socket.write("blogin:#{@mgr.username}\r\n\x00")
        end
    end
    
    def rcmd_inited args
        @socket.write("g_participants:start\r\n\x00")
        @socket.write("getpremium:1\r\n\x00")
        onConnect(self)
    end

    def rcmd_g_participants args
        args = args[1, args.length - 1].join(":")
        args = args.split(";")
        for data in args
            data = data.split(":")
            sid = data[0]
            puid = data[2]
            name = data[3]
            if name == "None"
                n = args[1].to_i.to_s[-4, 4]
                if data[4] == "None"
                    name = "!anon" + getAnonId(n, puid)
                end
            end
            user = User name
            @status[sid] = user
        end
    end
    
    def rcmd_participant args
        args = args[1, args.length - 1]
        sid = args[1]
        puid = args[2]
        name = args[3]
        if name == "None"
            n = args[6].to_i.to_s[-4, 4]
            if args[4] == "None"
                name = "!anon" + getAnonId(n, puid)
            end
        end

        user = User name
        
        #leave
        if args[0] == "0" 
            if @status.has_key?(sid)
                @status.delete(sid)
            end
        end

        #join/rejoin
        if args[0] == "1" or args[0] == "2"
            @status[sid] = user
        end
    end

    def rcmd_b args 
        name = args[2]
        msg = args[10, args.length].join(":")
        msg, n, f = clean_message(msg)
        if name == ""
            nameColor = nil
            name = "#" + args[3]
            if name == "#"
                name = "!anon" + getAnonId(n, args[4])
            end
        else
            if n
                nameColor = n
            else 
                nameColor = nil
            end
        end 
        user = User name
        fontColor, fontFace, fontSize = parseFont(f)
        msg = Message.new(self, user, msg, args[4])
        @mqueue  = msg
    end
    
    def rcmd_u args 
        if @mqueue
            msg = @mqueue 
            if msg.msgid == args[1]
                msg.attach(self, args[2])
            end
            onMessage(self, msg.user, msg)
        end
    end
    
    def setInterval timeout, evt, *args
        task = Task_.new(self, timeout, true, evt, *args)
        @mgr.add_task task
    end
    
    def setTimeout timeout, evt, *args
        task = Task_.new(self, timeout, false, evt, *args)
        @mgr.add_task task
    end
    
    def callEvent evt, *args
        if @mgr.respond_to?(evt)
            @mgr.send(evt, *args)
        end
    end
    
    def onMessage(room, user, message)
        callEvent(:onMessage, room, user, message)
    end
    def onConnect(room)
        callEvent(:onConnect, room)
    end
    def onDisconnect(room)
        callEvent(:onDisconnect, room)
    end
    def inspect
        return "<Room: #{name}>"
    end
end 

class Chatango
    def initialize
        @rooms = {}
        @user = nil
        @username = nil
        @password = nil
        @tasks = []
        @running = false
        @pm = nil
    end
    def pm
        return @pm
    end
    
    def user
        @user = User username
        return @user
    end
    
    def rooms
        rl = []
        ro = @rooms.values.collect{|k| k}
        for r in ro
            if r.connected == true
                rl << r
            end
        end
        return rl
    end
    
    def username
        return @username
    end

    def password
        return @password
    end

    def add_task newtask
        @tasks << newtask
    end

    def del_task task
        if @tasks.include?(task)
            @tasks.delete task
        end
    end
    
    def tasks
        tk = []
        for t in @tasks
            if t.mgr.connected == true
                tk << t
            end
        end
        return tk
    end
    
    def enableBg
        for room in rooms
            room.setBgMode(1)
        end
    end
    
    def disableBg
        for room in rooms
            room.setBgMode(0)
        end
    end
    
    def start(rooms=[], username=nil, password=nil)
        @username = username
        @password = password
        @running = true
        if rooms.length == 0
            print "Room names separated by semicolons: "
            room = gets.chomp
            rooms = room.split(";")
        end
        if username == nil or username == ""
            print "User Name: "
            @username = gets.chomp
        end
        if @username == "" 
            @username = nil
        end
        if password == nil or password == ""
            print "Password: "
            @password = gets.chomp
        end
        if @password == ""
            @password = nil
        end
        for r in rooms
            joinRoom(r)
        end
        if @username != nil and @password != nil
            @pm = Pm.new(self)
            @pm.connect
        end
        
        callEvent(:onInitialize)
        
        while @running == true
            sockets = @rooms.values.collect{|k| k.socket}
            connections = @rooms.values.collect{|k| k}
            if @pm != nil
                sockets << @pm.socket
                connections << @pm
            end
            sockets = sockets.reject{|k| k.closed?}
            w, r, e = select(sockets, nil, nil, 0)
            for c in connections
                if c.socket.closed? == true
                    c.disconnect
                elsif w != nil
                    for socket in w
                        if c != nil and c.socket == socket
                            begin
                                partial_data = socket.recv(1024)
                                c.process(partial_data)
                            rescue
                                c.disconnect
                            end
                        end
                    end
                end
            end
            ticking
        end
    end
    
    def ticking
        now = Time.now.to_f
        if tasks.length > 0
            for task in tasks
                if task.target <= now
                    if task.mgr.respond_to?(task.evt)
                        task.mgr.send(task.evt, task.args)
                        if task.isInterval
                            new = task.timeout + now
                            task.newtarget
                        else
                            @tasks.delete(task)
                            task = nil
                        end
                    end
                end
            end
        end
    end
    
    def finish
        @tasks.clear
        for name in @rooms.keys 
            leaveRoom(name)
        end
        if @pm != nil
            @pm.disconnect
        end
        @running = false
    end
    
    def joinRoom(name)
        if @rooms.key?(name) == false
            @rooms[name] = Room.new(self, name)
            @rooms[name].connect
        elsif @rooms.key?(name) == true
            if @rooms[name].connected == false
                @rooms[name].connect
            end
        end
    end
    
    def leaveRoom(name)
        if @rooms.key?(name) == true
            @rooms[name].disconnect
            @rooms.delete(name)
        end
    end
    
    def callEvent evt, *args
        if self.respond_to?(evt)
            self.send(evt, *args)
        end
    end
    
    def inspect
        return "<Chatango: #{username}>"
    end
end

#!/usr/bin/ruby
#author agunq 
#contact: <agunq.e@gmail.com>
#file ct.rb

require 'socket'

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
    def initialize(mgr, timeout, isInterval, evt, args) 
        @mgr = mgr
	    @target = Time.now.to_f + timeout
	    @evt = evt
	    @isInterval = isInterval
	    @args = args
	    @timeout = timeout
	end
	def mgr
	    return @mgr end
	def newtarget
	    @target = Time.now.to_f + timeout
	end
	def target
	    return @target end
	def evt 
	    return @evt end
	def isInterval
	    return @isInterval end
	def args 
	    return @args end
	def timeout 
	    return @timeout end
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
    def initialize(name)
        @name=name
    end
    def name 
        return @name end
end


class Message
    def initialize(room, user, body, msgid)
        @user=user
        @body=body
        @msgid=msgid
        @room=room
    end
    
    def attach(room, msgid)
        @msgid=msgid
        @room=room
    end
    
    def detach(room, msgid)
        @msgid=msgid
        @room=room
    end
    
    def body 
        return @body end
    def msgid 
        return @msgid end
    def user 
        return @user end  
    def room 
        return @room end
end

class Room
    
    def initialize(mgr, name)
        @name=name
        @uid=genUid
        @server = getServer(name)
        @connected = false
        @mgr = mgr
        @mqueue = nil
        @tasks = []
    end
    
    def name 
        return @name 
    end
    def add_task task
        @tasks << task
    end
    def tasks
        return @tasks
    end
    
    def auth
        if @mgr.user !=nil and @mgr.password !=nil
            @sock.write("bauth:#@name:#@uid:#{@mgr.user}:#{@mgr.password}\x00")
        # login as anon
        else
            @sock.write("bauth:#@name:#@uid\x00")
        end
    end
    
    def ping h
        #puts h
        @sock.write("\r\n\x00")
    end

	def connect
	    @sock = TCPSocket.new @server, 443
	    auth
	    @connected = true
	    setInterval(5, :ping, "Ping! at #{@name}")
	    while @connected
	        begin
	            partial_data = @sock.recv_nonblock(1024)
	            process(partial_data)
                ticking
            rescue
                ticking
            end
	    end
	    @sock.close
	end

	def message args
	    @sock.write("bmsg:t12r:#{args}\r\n\x00")
	end
	
	def disconnect
	    @sock.close   
	    @connected = false 
	end
	
	def process(data)
	    data = data.split("\x00")
	    for d in data
	        food = d.split(":")
	        cmd = "rcmd_" + food[0]
	        if self.respond_to?(cmd)
	            self.send(cmd, food) 
	        end
	    end
	end 
	
	def rcmd_inited args
	    @sock.write("g_participants:start\r\n\x00")
	    @sock.write("getpremium:1\r\n\x00")
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
	                        tasks.delete(task)
	                        task = nil
	                    end
	                end
	            end
	        end
	    end
	end
	
	def setInterval timeout, evt, *args
	    task = Task_.new(self, timeout, true, evt, *args)
	    add_task task
    end
    
    def setTimeout timeout, evt, *args
	    task = Task_.new(self, timeout, false, evt, *args)
	    add_task task
    end
	
	def callEvent evt, *args
	    if @mgr.respond_to?(evt)
	        @mgr.send(evt, *args)
	    end
	end
	
	def onMessage(room, user, message)
	    callEvent(:onMessage, room, user, message)
	end
end 

class Manager
    def initialize
        @threads = {}
        @rooms = {}
        @user = nil
        @password = nil
    end
    
    def user
        return @user
    end
    
    def password
        return @password
    end
    
    def start(rooms, user=nil, password=nil)
        @user = user
        @password = password
        for r in rooms
            joinRoom(r)
        end
        @threads[rooms[0]].join
    end
    
    def finish
        for name in @rooms.keys 
            leaveRoom(name)
        end
    end
    
    def joinRoom(name)
        if @threads.key?(name) == false
            @threads[name] = Thread.new do
                if @rooms.key?(name) == false
                    @rooms[name] = Room.new(self, name)
                    @rooms[name].connect
                end
            end
        end
    end
    
    def leaveRoom(name)
        if @threads.key?(name) == true
            if @rooms.key?(name) == true
                @rooms[name].disconnect
                @rooms.delete(name)
            end
            @threads[name].exit
            @threads.delete(name)
        end
    end
    
end

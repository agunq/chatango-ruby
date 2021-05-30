#!/usr/bin/ruby
#author agunq
#contact: <agunq.e@gmail.com>
#file ct.rb
#Require Ruby 2.0
#Require Websocket [gem install webscoket]

require 'socket'
require 'uri'
require 'cgi'
require 'net/http'
require 'websocket'

class WebSocketC

	def connect(url, options={})
		return if @socket
		@url = url
		uri = URI.parse url
		@socket = TCPSocket.new(uri.host, uri.port)
		@handshake = ::WebSocket::Handshake::Client.new :url => url, :headers => options[:headers]
		@handshaked = false
		@pipe_broken = false
		@rframe = ::WebSocket::Frame::Incoming::Client.new(version: @handshake.version)
		@closed = false
		@socket.write @handshake.to_s
		while !@handshaked do
			begin
				unless @recv_data = @socket.getc
					next
				end
				unless @handshaked
					@handshake << @recv_data
					if @handshake.finished?
						@handshaked = true
					end
				end
			rescue Exception => e
				puts "handshake fail - #{e.message}"
				@handshaked = true
				self.close
			end
		end
	end

	def socket
		return @socket
	end

	def send(data, options={:type => :text})
		return if !@handshaked or @closed
		type = options[:type]
		@wframe = ::WebSocket::Frame::Outgoing::Client.new(:data => data, :type => type, :version => @handshake.version)
		begin
			@socket.write @wframe.to_s
		rescue Exception => e
			@pipe_broken = true
			puts "pipe broken - #{e.message}"
			self.close
		end
	end

	def read
		begin
			@recv_data = @socket.recv(1024)
			@rframe << @recv_data.to_s
			return @rframe
		rescue Exception => e
			puts "frame error - #{e.message}"
			self.close
		end
	end

	def close
		return if @closed
		if !@pipe_broken
			send nil, :type => :close
		end
		@closed = true
		@socket.close if @socket
		@socket = nil
	end

	def open?
		!@closed
	end

end

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
		sizecolor, fontface = f.split("=", 2)
		sizecolor = sizecolor.strip()
		size = sizecolor[1,2].to_i
		col = sizecolor[3,6]
		if col == ""
			col = nil
		end
		face = f.split("\"", 3)[1]
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
	if name == nil
		name = ""
	end
	if not $users.include?(name.downcase)
		user = User_.new name
		$users[name.downcase] = user
	else
		user = $users[name.downcase]
	end
	return user
end

class User_

	attr_accessor :name, :puid, :sid, :nameColor, :fontSize, :fontFace, :fontColor, :mbg, :mrec

	def initialize(name)
		@name = name
		@puid = nil
		@sid = nil
		@nameColor = "000"
		@fontSize = 12
		@fontFace = "0"
		@fontColor = "000"
		@mbg = false
		@mrec = false
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
		return "<User: #{name}>"
	end

	def to_s
		return "<User: #{name}>"
	end
end

class Message

	attr_accessor :user, :body, :msgid, :sid, :unid, :room, :ip, :badge, :time, :nameColor, :fontColor, :fontFace, :fontSize

	def initialize(room, user, body, msgunid, sid, ip, badge, mtime, mnameColor, mfontColor, mfontFace, mfontSize)
		@user = user
		@body = body
		@msgid = ""
		@unid = msgunid
		@sid = sid
		@room = room
		@ip = ip
		@badge = badge
		@time = mtime
		@nameColor = mnameColor
		@fontColor = mfontColor
		@fontFace = mfontFace
		@fontSize = mfontSize
	end

	def attach(room, msgid)
		@msgid = msgid
		@room = room
	end

	def detach
		@msgid = nil
	end

	def inspect
		return "<Message: #{user}>"
	end
end


class Pm

	attr_accessor :wbyte, :blocklist, :contacts, :status

	def initialize(mgr)
		@auid = nil
		@server = "c1.chatango.com"
		@connected = false
		@mgr = mgr
		@wbyte = ""
		@wlockbyte = ""
		@wlock = false
		@firstCommand = true
		@socket = WebSocketC.new
		@status = {}
		@blocklist = []
		@contacts = []
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
			sendCommand("tlogin", @auid, "2")
			setWriteLock(true)
		end
	end

	def ping h
		#puts h
		sendCommand("")
	end

	def connect
		headers = { "Origin" => "http://st.chatango.com", "Pragma" => "no-cache", "Cache-Control" => "no-cache" }
		@socket.connect "ws://#{@server}:8080", options = {:headers => headers}
		auth
		@mgr.setInterval(self, 20, :ping, "Ping! at <PM>")
		@connected = true
	end

	def message username, msg
		if msg != nil
			msg = "<n#{@mgr.user.nameColor.downcase}/><m v=\"1\"><g x#{@mgr.user.fontSize}s#{@mgr.user.fontColor.downcase}=\"#{@mgr.user.fontFace}\">#{msg}</g></m>"
			sendCommand("msg", username, msg)
		end
	end

	def disconnect
		if @connected == true
			if @socket.open? == true
				@socket.close
			end
			@connected = false
		end
	end

	def addContact(user)
		user = User user
		unless user.include?(@contacts)
			sendCommand("wlaad", user.name.downcase)
			@contacts << user
			callEvent(:onPMContactAdd, self, user)
		end
	end

	def removeContact(user)
		user = User user
		if user.include?(@contacts)
			sendCommand("wldelete", user.name.downcase)
			@contacts.delete(user)
			callEvent(:onPMContactRemove, self, user)
		end
	end

	def block(user)
		user = User user
		unless @blocklist.include?(user)
			sendCommand("block", user.name.downcase, user.name.downcase, "S")
			@blocklist << user
			callEvent(:onPMBlock, self, user)
		end
	end

	def unblock(user)
		user = User user
		if @blocklist.include?(user)
			sendCommand("unblock", user.name.downcase)
		end
	end

	def setBgMode mode
		sendCommand("msgbg", mode.to_s)
	end

	def setRecordingMode mode
		sendCommand("msgmedia", mode.to_s)
	end

	def process(data)
		if data
			data = data.split("\x00")
			for d in data
				food = d.split(":")
				if food.length > 0
					cmd = "rcmd_" + food[0].rstrip
					if self.respond_to?(cmd)
						self.send(cmd, food)
					end
				end
			end
		end
	end

	def rcmd_OK args
		setWriteLock(false)
		sendCommand("wl")
		sendCommand("getblock")
		sendCommand("getpremium", "1")
		callEvent(:onPMConnect, self)
	end

	def rcmd_wl args
		data = args[1, args.size-1]
		for i in (0..(data.size/4)-1)
			name, last_on, is_on, idle = data[i * 4, i * 4 + 4]
			user = User(name)
			if last_on == "None"
				nil
			elsif not is_on == "on"
				@status[user] = [last_on.to_i, false, 0]
			elsif idle == "0"
				@status[user] = [last_on.to_i, true, 0]
			else
				@status[user] = [last_on.to_i, true, Time.now.to_f - idle.to_i * 60]
			end
			@contacts << user
		end
		callEvent(:onPMContactlistReceive, self)
	end

	def rcmd_block_list(args)
		@blocklist = []
		for name in args
			if name != ""
				user = User name
				@blocklist << user
			end
		end
	end

	def rcmd_DENIED(args)
		disconnect
		callEvent(:onLoginFail, self)
	end

	def rcmd_mhs(args)
		@connected = true
		setWriteLock(false)
	end

	def rcmd_msg args
		user = User args[1]
		body = strip_html args[6, args.length].join ":"
		body = body[0, body.length-2]
		callEvent(:onPMMessage, self, user, body)
	end

	def rcmd_msgoff(args)
		user = User(args[1])
		body = strip_html args[6, args.length].join ":"
		body = body[0, body.length-2]
		callEvent(:onPMOfflineMessage, self, user, body)
	end

	def rcmd_wlonline(args)
		user = User(args[1])
		last_on = args[2].to_f
		@status[user] = [last_on,true,last_on]
		callEvent(:onPMContactOnline, user)
	end

	def rcmd_wloffline(args)
		user = User(args[1])
		last_on = args[2].to_f
		@status[user] = [last_on,false,0]
		callEvent(:onPMContactOffline, user)
	end

	def rcmd_premium args
		if args[2].to_i > Time.now.to_i
			@premium = true
			if @mgr.user.mbg
				self.setBgMode(1)
			end
			if @mgr.user.mrec
				self.setRecordingMode(1)
			end
		else
			@premium = false
		end
	end

	def rcmd_kickingoff(args)
		disconnect
	end

	def rcmd_toofast(args)
		disconnect
	end

	def rcmd_unblocked(user)
		user = User user
		if user.include?(@blocklist)
			@blocklist.delete(user)
			callEvent(:onPMUnblock, self, user)
		end
	end

	def callEvent evt, *args
		if @mgr.respond_to?(evt)
			@mgr.send(evt, *args)
		end
	end

	def write args
		if @wlock == true
			@wlockbyte += args
		else
			@wbyte += args
		end
	end

	def setWriteLock args
		@wlock = args
		if @wlock == false
			write(@wlockbyte)
			@wlockbyte = ""
		end
	end

	def sendCommand(*args)
		if @firstCommand == true
			terminator = "\x00"
			@firstCommand = false
		else
			terminator = "\r\n\x00"
		end
		write args.join(":") + terminator
	end

	def inspect
		return "<Pm: #{@mgr.user}>"
	end
end

class Room

	attr_accessor :wbyte, :owner, :mods, :banlist, :unbanlist, :bannedwords, :usercount, :channel

	def initialize(mgr, name)
		@name = name
		@uid = genUid
		@server = getServer(name)
		@connected = false
		@mgr = mgr
		@wbyte = ""
		@wlockbyte = ""
		@wlock = false
		@firstCommand = true
		@mqueue = {}
		@umqueue = {}
		@socket = WebSocketC.new
		@status = {}
		@owner = ""
		@mods = {}
		@history = []
		@log_i = []
		@banlist = {}
		@unbanlist = {}
		@bannedwords = []
		@usercount = 0
		@channel = "0"
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
			sendCommand("bauth", @name, @uid, @mgr.username, @mgr.password)
			# login as anon
		else
			sendCommand("bauth", @name, @uid)
		end
		setWriteLock(true)
	end

	def ping h
		#puts h
		sendCommand("")
	end

	def connect
		headers = { "Origin" => "http://st.chatango.com", "Pragma" => "no-cache", "Cache-Control" => "no-cache" }
		@socket.connect "ws://#{@server}:8080", options = {:headers => headers}
		auth
		@status.clear
		@mgr.setInterval(self, 20, :ping, "Ping! at #{@name}")
		@connected = true
	end

	def reconnect
		if @connected
			@mgr.leaveRoom @name
		end
		@mgr.joinRoom @name
	end

	def message msg, html = false, msgc = @channel
		if html == false
			msg = msg.gsub( "<", "&lt;")
			msg = msg.gsub( ">", "&gt;")
		end
		msgs = msg.chars.each_slice(2000).map(&:join)
		s, c, f = @mgr.user.fontSize, @mgr.user.fontColor, @mgr.user.fontFace
		for msg in msgs
			msg = "<n#{@mgr.user.nameColor}/><f x#{s}#{c}=\"#{f}\">#{msg}</f>"
			sendCommand("bm", "t12r", msgc, msg)
		end
	end

	def disconnect
		if @connected == true
			if @socket.open? == true
				@socket.close
			end
			@connected = false
			callEvent(:onDisconnect, self)
		end
	end

	def userlist
		return @status.values
	end

	def setBgMode mode
		sendCommand("msgbg", mode.to_s)
	end

	def setRecordingMode mode
		sendCommand("msgmedia", mode.to_s)
	end

	def login(name, pass=nil)
		if pass != nil
			sendCommand("blogin", name.to_s, pass.to_s)
		else
			sendCommand("blogin", name.to_s)
		end
	end

	def logout
		sendCommand("blogout")
	end

	def addBadWord(word, type="part")
		part_words, exact_words = @bannedwords
		if !part_words.include?(word) and type=="part"
			part_words << word
		elsif !exact_words.include?(word) and type=="exact"
			exact_words << word
		end
		sendCommand("setbannedwords", part_words.join(","), exact_words.join(","))
	end

	def removeBadWord(word, type="part")
		part_words, exact_words = @bannedwords
		if part_words.include?(word) and type=="part"
			part_words.delete(word)
		elsif exact_words.include?(word) and type=="exact"
			exact_words.delete(word)
		end
		sendCommand("setbannedwords", part_words.join(","), exact_words.join(","))
	end

	def addMod(user)
		sendCommand("addmod", user.to_s.downcase)
	end

	def removeMod(user)
		sendCommand("removemod", user.to_s.downcase)
	end

	def clearall
		sendCommand("clearall")
		sendCommand("getannouncement")
	end

	def rawBan(name, ip, unid)
		sendCommand("block", unid.to_s, ip.to_s, name.to_s.downcase)
	end

	def ban(user)
		msg = getLastMessage user
		rawBan(msg.user.name, msg.ip, msg.unid)
	end

	def getBanRecord user
		user = User user
		if @banlist.keys.include?(user)
			return @banlist[user]
		end
	end

	def rawUnban name, ip, unid
		sendCommand("removeblock", unid, ip, name)
	end

	def unban user
		rec = getBanRecord(user)
		if rec
			rawUnban(rec["target"].name, rec["ip"], rec["unid"])
		end
	end

	def requestBanList
		sendCommand("blocklist", "block", "", "next", "500")
	end

	def requestUnBanList
		sendCommand("blocklist", "unblock", "", "next", "500")
	end

	def flag message
		sendCommand("g_flag", message.msgid)
	end

	def flagUser user
		msg = getLastMessage(user)
		if msg
			flag(msg)
		end
	end

	def deleteMessage message
		sendCommand("delmsg", message.msgid)
	end

	def deleteUser user
		msg = getLastMessage(user)
		if msg
			sendCommand("delmsg", msg.msgid)
		end
	end

	def delete message
		deleteMessage(message)
	end

	def rawClearUser unid, ip, user
		sendCommand("delallmsg", unid, ip, user)
	end

	def clearUser  user
		msg = getLastMessage(user)
		if msg
			if ["!","#"].include?(msg.user.name[0])
				rawClearUser(msg.unid, msg.ip, "")
			else
				rawClearUser(msg.unid, msg.ip, msg.user.name.downcase)
			end
		end
	end

	def process(data)
		if data
			data = data.split("\x00")
			for d in data
				food = d.split(":")
				if food.length > 0
					cmd = "rcmd_" + food[0].rstrip
					if self.respond_to?(cmd)
						self.send(cmd, food)
					end
				end
			end
		end
	end

	def rcmd_denied(args)
		disconnect
		callEvent(:onLoginFail, self)
	end

	def rcmd_ok args
		setWriteLock(false)
		if args[3] == "C" and @mgr.username == nil and @mgr.password == nil
			n = args[5].split('.')[0]
			n = n[-4, n.length]
			aid = args[2][0, 8]
			pid = "!anon" + getAnonId(n, aid)
			@mgr.user.setNameColor n
		elsif args[3] == "C" and @mgr.password == nil
			sendCommand("blogin", @mgr.username)
		elsif args[3] != "M"
			callEvent(:onLoginFail, self)
			disconnect
		end
		@owner = User args[1]
		mods = args[7].split(";").collect{|x| [User(x.split(",")[0]), x.split(",")[1]] }
		for mod, v in mods
			@mods[mod] = v
		end
	end

	def rcmd_inited args
		sendCommand("getpremium", "1")
		sendCommand("g_participants", "start")
		sendCommand("getbannedwords")
		callEvent(:onConnect, self)
		for msg in @log_i.reverse
			user = msg.user
			callEvent(:onHistoryMessage, self, user, msg)
			addHistory msg
		end
		@log_i = []
	end

	def rcmd_bw(args)
		if args[1]
			part_words = CGI.unescape(args[1]).split(",")
		else
			part_words = []
		end
		if args[2]
			exact_words = CGI.unescape(args[2]).split(",")
		else
			exact_words = []
		end
		@bannedwords = [part_words, exact_words]
		callEvent(:onBannedWordsUpdated, self, @bannedwords)
	end

	def rcmd_ubw(args)
		sendCommand("getbannedwords")
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
				n = data[1].to_i.to_s[-4, 4]
				if data[4] == "None"
					name = "!anon" + getAnonId(n, puid)
				else
					name = "#" + data[4]
				end
			end
			user = User name
			user.puid = puid
			user.sid = sid
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
			else
				name = "#" + args[4]
			end
		end

		user = User name
		user.puid = puid
		user.sid = sid

		#leave
		if args[0] == "0"
			if @status.key?(sid)
				@status.delete(sid)
				callEvent(:onLeave, self, user)
			end
		end

		#join/rejoin
		if args[0] == "1" or args[0] == "2"
			@status[sid] = user
			callEvent(:onJoin, self, user)
		end
	end

	def rcmd_mods args
		new = args[1..-1].collect{|x| [User(x.split(",")[0]), x.split(",")[1]] }
		old = @mods
		
		@mods = {}
		newmods = []
		upmods = []
		delmods = []
		for mod, v in new
			@mods[mod] = v
			if old.include? mod
				if old[mod] != v
					upmods << [mod, v, old[mod]]
				end
			else
				newmods <<  [mod, v]
			end
		end
		
		for mod, v in old
			if !new.collect{|k,v|k }.include? mod
				delmods << [mod, v]
			end
		end
		if newmods.size > 0
			callEvent(:onModAdd, newmods)
		end
		if upmods.size > 0
			callEvent(:onModChange, upmods)
		end
		if delmods.size > 0
			callEvent(:onModRemove, delmods)
		end
		
	end
	
	def rcmd_b args
		name = args[2]
		rawmsg = args[10, args.size-10]
		if rawmsg
			msg, n, f = clean_message(rawmsg.join(":"))
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
			mtime = args[1].to_f
			msg = Message.new(self, user, msg, args[5], args[4], args[7], args[8], mtime, nameColor, fontColor, fontFace, fontSize)
		
			if msg.user != @mgr.user
				msg.user.fontColor = msg.fontColor
				msg.user.fontFace = msg.fontFace
				msg.user.fontSize = msg.fontSize
				msg.user.nameColor = msg.nameColor
			end
			addHistory msg
			@channel = msg.badge
			callEvent(:onMessage, self, msg.user, msg)
			@mqueue[args[6]]  = msg
			if @umqueue
				if @umqueue.keys.include?(args[6])
					umsgid = @umqueue[args[6]]
					msg.attach(self, umsgid)
					@umqueue.delete args[6]
				end
			end
			checkSecret args[6]
		end
	end
			


	def rcmd_u args
		@umqueue[args[1]]  = args[2]
		if @mqueue
			if @mqueue.keys.include?(args[1])
				msg = @mqueue[args[1]]
				msg.attach(self, args[2])
				@mqueue.delete args[1]
			end
		end
		checkSecret args[1]
	end
	
	def checkSecret check
		
		@umqueue.each{|k, v|
			if k != check 
				@umqueue.delete(k)
				@umqueue.each{|ks, vs| puts "some secret #{ks} #{vs} #{self.name}"}
			end
		}
		
	end

	def rcmd_i args
		name = args[2]
		rawmsg = args[10, args.size-10]
		if rawmsg
			msg, n, f = clean_message(rawmsg.join(":"))
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
			mtime = args[1].to_f
			msg = Message.new(self, user, msg, args[5], args[4], args[7], args[8], mtime, nameColor, fontColor, fontFace, fontSize)
			msg.attach self, args[6]
			@log_i << msg
		end
	end

	def rcmd_premium args
		if args[2].to_i > Time.now.to_i
			@premium = true
			if @mgr.user.mbg
				self.setBgMode(1)
			end
			if @mgr.user.mrec
				self.setRecordingMode(1)
			end
		else
			@premium = false
		end
	end

	def rcmd_delete args
		msg = getMessageById args[1]
		if @history.include? msg
			@history.delete msg
			callEvent(:onMessageDelete, self, msg.user, msg)
		end
	end

	def rcmd_deleteall args
		for msgid in args
			rcmd_delete(["delete", msgid])
		end
	end

	def rcmd_n args
		@usercount = args[1].to_i(16)
		callEvent(:onUserCountChange, self)
	end

	def rcmd_blocklist args
		data = args[1, args.size-1]
		@banlist = {}
		sections = data.join(":").split(";")
		for section in sections
			params = section.split(":")
			next if params.size != 5
			next if params[2] == ""
			user = User(params[2])
			@banlist[user] = {
				"unid" => params[0],
				"ip" => params[1],
				"target" => user,
				"time" => params[3].to_f,
				"src" => User(params[4])
			}
		end
		callEvent(:onBanlistUpdate, self)
	end

	def rcmd_unblocklist args
		data = args[1, args.size-1]
		@unbanlist = {}
		sections = data.join(":").split(";")
		for section in sections
			params = section.split(":")
			next if params.size != 5
			next if params[2] == ""
			user = User(params[2])
			@unbanlist[user] = {
				"unid" => params[0],
				"ip" => params[1],
				"target" => user,
				"time" => params[3].to_f,
				"src" => User(params[4])
			}
		end
		callEvent(:onUnbanlistUpdate, self)
	end

	def rcmd_blocked args
		return if args[3] == ""
		target = User(args[3])
		user = User(args[4])
		@banlist[target] = {"unid" => args[1], "ip" => args[2], "target" => target, "time" => args[5].to_f, "src" => user}
		callEvent(:onBan, self, user, target)
	end

	def rcmd_unblocked args
		return if args[3] == ""
		target = User(args[3])
		user = User(args[4])
		@unbanlist[target] = {"unid" => args[1], "ip" => args[2], "target" => target, "time" => args[5].to_f, "src" => user}
		callEvent(:onUnban, self, user, target)
	end

	def rcmd_updateprofile(args)
		user = User(args[1])
		callEvent(:onUpdateProfile, self, user)
	end

	def rcmd_show_fw(args)
		callEvent(:onFloodWarning, self)
	end

	def rcmd_show_tb(args)
		callEvent(:onFloodBan, self)
	end

	def rcmd_tb(args)
		callEvent(:onFloodBanRepeat, self)
	end

	def addHistory msg
		@history << msg
		lastmsg = @history[0]
		if @history.size > 100
			if @history.include?(lastmsg)
				@history.delete lastmsg
			end
		end
	end

	def getLastMessage user
		user = User user
		for msg in @history.reverse
			if msg.user == user
				return msg
			end
		end
	end

	def getMessageById msgid
		for msg in @history.reverse
			if msg.msgid == msgid
				return msg
			end
		end
	end

	def callEvent evt, *args
		if @mgr.respond_to?(evt)
			@mgr.send(evt, *args)
		end
	end

	def write args
		if @wlock == true
			@wlockbyte += args
		else
			@wbyte += args
		end
	end

	def setWriteLock args
		@wlock = args
		if @wlock == false
			write(@wlockbyte)
			@wlockbyte = ""
		end
	end

	def sendCommand(*args)
		if @firstCommand == true
			terminator = "\x00"
			@firstCommand = false
		else
			terminator = "\r\n\x00"
		end
		write args.join(":") + terminator
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
		ro = @rooms.values
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
		if not @tasks.include?(newtask)
			@tasks << newtask
		end
	end

	def del_task task
		if @tasks.include?(task)
			@tasks.delete task
			task = nil
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
		self.user.mbg = true
		for room in rooms
			room.setBgMode(1)
		end
	end

	def disableBg
		self.user.mbg = false
		for room in rooms
			room.setBgMode(0)
		end
	end

	def enableRecording
		self.user.mrec = true
		for room in rooms
			room.setRecordingMode(1)
		end
	end

	def disableRecording
		self.user.mrec = false
		for room in rooms
			room.setRecordingMode(0)
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
			begin
				connections = @rooms.values
				if @pm != nil
					connections << @pm
				end
				sockets = connections.collect{|c| c.socket.socket}.reject{|x| x == nil}
				wsockets = connections.collect{|c| c.socket.socket if c.wbyte != "" }.reject{|x| x == nil}
				rd, wr, e = select(sockets, wsockets, nil, 0.2)
				for c in connections
					if c.socket.open? == false
						c.disconnect
					end
					if rd != nil
						for socket in rd
							if c.socket.socket == socket
								frame = c.socket.read
								while partial_data = frame.next
									partial_data = partial_data.to_s.force_encoding("utf-8").encode
									c.process(partial_data)
								end
							end
						end
					end
					if wr != nil
						for socket in wr
							if c.socket.socket == socket
								c.socket.send(c.wbyte)
								c.wbyte = ""
							end
						end
					end
				end
			rescue Exception => e
				puts e.message
				puts e.backtrace
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
							del_task task
						end
					end
				end
			end
		end
	end

	def setInterval mgr, timeout, evt, *args
		task = Task_.new(mgr, timeout, true, evt, *args)
		add_task task
	end

	def setTimeout mgr, timeout, evt, *args
		task = Task_.new(mgr, timeout, false, evt, *args)
		add_task task
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

	def getRoom(name)
		name = name.downcase
		if @rooms.key?(name) == true
			return @rooms[name]
		end
	end

	def joinRoom(name)
		rawname = name
		name = name.downcase
		if @rooms.key?(name) == false
			@rooms[name] = Room.new(self, rawname)
			@rooms[name].connect
		elsif @rooms.key?(name) == true
			if @rooms[name].connected == false
				@rooms[name].connect
			end
		end
	end

	def leaveRoom(name)
		name = name.downcase
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

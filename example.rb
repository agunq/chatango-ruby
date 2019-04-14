require_relative 'ct'

class Bot < Chatango	

	def onInitialize
		self.user.setFontColor "3333ff"
		self.user.setNameColor "00f"
		self.enableBg
	end

	def onPMMessage(pm, user, message)
		puts "<PM>: <#{user.name}> #{message}"
		text = "ya ?"
		pm.message user.name, "#{text}"
	end

	def onConnect(room)
		puts "Connected to #{room.name}"
	end

	def onDisconnect(room)
		puts "Disconnected from #{room.name}"
	end

	def onMessage(room, user, message)
		puts "#{room.name}: <#{user.name}> #{message.body}"
		if message.body == "halo"
			room.message "halo juga " + user.name
		end
	end
end

#another example to start your bot
#Bot.new.start(["GroupName1", "GroupName2"], "UserName", "Password")

Bot.new.start

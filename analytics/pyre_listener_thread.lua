--[[The Analytics app launches Pyre on the player's behalf in a separate
thread. This is the code for that thread.]]

love.thread.getChannel("RITECLUB"):push({"PYRE_ANALYTICS", "PYRE_OPENED"})

local stream = io.popen(%s, "r")

while stream and io.type(stream) ~= "closed file" do
	local line = stream:read("*l")
	if line then
		if string.match(line, "^RITECLUB") then
			local array = {}
			for op in string.gmatch(line, "([^|]+)|?") do
				table.insert(array, op)
			end
			love.thread.getChannel("RITECLUB"):push(array)
		end
	else
		stream:close()
	end
end

love.thread.getChannel("RITECLUB"):push({"PYRE_ANALYTICS", "PYRE_CLOSED"})

--[[This thread sends messages to the FFmpeg "server", and waits for the
video recording to end.]]

local socket = require("socket")

HOST = "127.0.0.1"
PORT = 9876

function send_msg(msg)
	local client = socket.connect(HOST, PORT)
	client:send(msg)
	client:close()
end

send_msg("START")

--[[OK now we can sit in a loop and wait for the video recording to stop.]]
local done_recording = false
local msg

while not done_recording do
	while love.thread.getChannel("TOVIDEORECORDER"):peek() do
		msg = love.thread.getChannel("TOVIDEORECORDER"):pop()
		if msg and msg[1] == "KILL_RECORDING" then
			send_msg("STOP")
			done_recording = true
		end
	end
end

--[[Signal to the main app that we're done recording the video.]]
love.thread.getChannel("FROMVIDEORECORDER"):push({"PYRE_RECORDING", "RECORDING_FINISHED"})

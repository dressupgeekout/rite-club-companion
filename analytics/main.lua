--[[Pyre Analytics App! Requires a pre-patched copy of Pyre.]]

local json = require("json")
local serpent = require("serpent")

require("exiles")
require("triumvirates")
require("arenas")
require("talismans")
require("masteries")

io.stdout:setvbuf("line")
io.stderr:setvbuf("line")

---------- ---------- ----------

SECTION_NONE = "NONE"
SECTION_CHRONO = "CHRONO"
SECTION_EXILES = "EXILES"

TEAM_A_NUMBER = 12
TEAM_B_NUMBER = 13

DEFAULT_FONT = love.graphics.newFont()
ARENA_NAME_FONT = love.graphics.newFont("fonts/Alegreya-Regular.otf", 28)
EVENT_FONT = love.graphics.newFont("fonts/Alegreya-Regular.otf", 24)

if love.system.getOS() == "Windows" then
	PYRE_PATH = "launch_pyre.bat"
else
	PYRE_PATH = "launch_pyre.sh"
end

CONFIG_FILE = "RiteClubConfig.lua"
DEFAULT_CONFIG_RECORD_VIDEO = true
DEFAULT_CONFIG_DATABASE_URL = "http://noxalas.net:9292/api/v1"

function ReadConfigFile()
	CONFIG_RECORD_VIDEO = DEFAULT_CONFIG_RECORD_VIDEO
	CONFIG_DATABASE_URL = DEFAULT_CONFIG_DATABASE_URL

	if love.filesystem.getInfo(CONFIG_FILE) then
		dofile(CONFIG_FILE)
	end

	print(string.format("CONFIG_RECORD_VIDEO = %s", CONFIG_RECORD_VIDEO))
	print(string.format("CONFIG_DATABASE_URL = %s", CONFIG_DATABASE_URL))
end

function SecondsToPrettyTime(sec)
	local mins = math.floor(sec / 60)
	sec = sec - (60 * mins)
	return string.format("%d:%02d", mins, sec)
end
CurrentlyRecording = false

function SecondsToPrettyTimeFrac(sec)
	local mins = math.floor(sec / 60)
	local sec = sec - (60 * mins)
	local leftover = (sec - math.floor(sec)) * 100
	return string.format("%02d:%02d.%02d", mins, sec, leftover)
end

function LaunchPyre()
	if PyreEngaged then
		print("WARNING: Pyre is already engaged!")
		return
	end

	local realpath

	if OurOS == "OS X" then
		realpath = string.format("%q", string.format("%s/Contents/MacOS/Pyre", PYRE_PATH)) -- XXX
	elseif OurOS == "Windows" then
		realpath = string.format("%q", PYRE_PATH)
	elseif OurOS == "Linux" then
		realpath = string.format("%q", PYRE_PATH) -- XXX ??
	end

	local code = string.format(love.filesystem.read("pyre_listener_thread.lua"), realpath)
	PyreThread = love.thread.newThread(code)
	PyreThread:start()

	local recordercode = love.filesystem.read("pyre_recorder_thread.lua")
	PyreRecorderThread = love.thread.newThread(recordercode)
	PyreRecorderPID = -1
end

function PostMortem()
	local team_a_throw_damage = 0
	local team_b_throw_damage = 0

	for _, event in ipairs(RiteInfo.A.Scores) do
		if event.Thrown then team_a_throw_damage = team_a_throw_damage + event.Value end
	end
	for _, event in ipairs(RiteInfo.B.Scores) do
		if event.Thrown then team_b_throw_damage = team_b_throw_damage + event.Value end
	end

	print(string.format("TEAM A THROW DAMAGE: %d", team_a_throw_damage))
	print(string.format("TEAM B THROW DAMAGE: %d", team_b_throw_damage))

	--[[Digest of everything that happened, we'll post it to the website if
	desired.]]
	RiteFinalSummary = {
		A = {
			Triumvirate = RiteInfo.A.Triumvirate.Name,
			Exiles = {},
		},
		B = {
			Triumvirate = RiteInfo.B.Triumvirate.Name,
			Exiles = {},
		},
		Common = {
			Arena = RiteInfo.Common.Arena.Name,
			RiteTime = RiteTime,
		},
		Chrono = {},
	}

	for _, team in ipairs({"A", "B"}) do
		for _, exile in ipairs(RiteInfo[team].Exiles) do
			local x = {
				Name = exile.Name,
			}
			if exile.Talisman then x.Talisman = exile.Talisman.Name end
			table.insert(RiteFinalSummary[team].Exiles, x)
		end
	end

	for _, event in ipairs(RiteInfo.Chrono) do
		local e = {
			Type = event.Type,
			Time = event.Time,
		}
		if event.Type == "SCORE" then
			e.Exile = event.Exile.Name
			e.Value = event.Value
			e.Thrown = event.Thrown
		end
		if event.Type == "BANISHMENT" then
			e.Banisher = event.Banisher.Name
			e.BanisherTeam = event.BanisherTeam
			e.Banishee = event.Banishee.Name
			e.BanisheeTeam = event.BanisheeTeam
		end
		table.insert(RiteFinalSummary.Chrono, e)
	end

	print("")
	print(json.encode(RiteFinalSummary))
	print("")
end

function AnalyzeMessage(msg)
	--[[LOVE-level things]]
	if msg[1] == "PYRE_ANALYTICS" and msg[2] == "PYRE_OPENED" then
		PyreEngaged = true
	end
	if msg[1] == "PYRE_ANALYTICS" and msg[2] == "PYRE_CLOSED" then
		PyreEngaged = false
	end

	--[[Basic events]]
	local key = msg[2]
	local value = msg[3]

	if key == "RITECOMMENCED" then
		RiteTime = 0
		RiteEngaged = true
		RiteInfo = NewRiteInfo()
		if CurrentSection == SECTION_NONE then
			CurrentSection = SECTION_CHRONO
		end
		if CONFIG_RECORD_VIDEO then
			PyreRecorderThread:start()
			CurrentlyRecording = true
			print(">> VIDEO RECORDING HAS STARTED")
		end
	end
	if key == "RITECONCLUDED" then
		RiteEngaged = false
		if CONFIG_RECORD_VIDEO then
			love.thread.getChannel("TOVIDEORECORDER"):push({"KILL_RECORDING", PyreRecorderPID})
			CurrentlyRecording = false
			print(">> VIDEO RECORDING HAS ENDED")
		end
		PostMortem()
	end
	if key == "TEAM1TRIUMVIRATE" or key == "TEAM2TRIUMVIRATE" then
		local n, _ = string.gsub(value, "TeamName", "")
		if key == "TEAM1TRIUMVIRATE" then
			RiteInfo.A.Triumvirate = TRIUMVIRATE_MAP[tonumber(n)]
		else
			RiteInfo.B.Triumvirate = TRIUMVIRATE_MAP[tonumber(n)]
		end
	end

	local team_n, exile_n = string.match(key, "^TEAM(%d)EXILE(%d)$")
	if team_n and exile_n then
		local exiles_table
		if tonumber(team_n) == 1 then
			exiles_table = RiteInfo.A.Exiles
		else
			exiles_table = RiteInfo.B.Exiles
		end
		exiles_table[tonumber(exile_n)] = CHARACTER_MAP[tonumber(value)]
	end

	local team_n, exile_n = string.match(key, "^TEAM(%d)EXILE(%d)TALISMAN$")
	if team_n and exile_n then
		local exiles_table
		if tonumber(team_n) == 1 then
			exiles_table = RiteInfo.A.Exiles
		else
			exiles_table = RiteInfo.B.Exiles
		end
		if value ~= "nil" then
			exiles_table[tonumber(exile_n)].Talisman = TALISMAN_MAP[value]
		end
	end

	if key == "STAGE" then
		local x, _ = string.gsub(value, "MatchSite", "")
		RiteInfo.Common.Arena = ARENA_MAP[x]
	end

	--[[Score events]]
	if key == "STARTSCORE" then
		NextEvent = {}
		NextEvent.Type = "SCORE"
		NextEvent.Time = RiteTime
	end
	if key == "STOPSCORE" then
		table.insert(RiteInfo[NextEvent.Team].Scores, NextEvent)
		table.insert(RiteInfo.Chrono, NextEvent)
	end
	if key == "SCORETEAM" then
		local team = tonumber(value)
		if team == TEAM_A_NUMBER then
			NextEvent.Team = "A"
		elseif team == TEAM_B_NUMBER then
			NextEvent.Team = "B"
		end
	end
	if key == "SCORER" then
		NextEvent.Exile = CHARACTER_MAP[tonumber(value)]
	end
	if key == "SCOREVALUE" then
		NextEvent.Value = tonumber(value)
	end
	if key == "SCORETHROWN" then
		NextEvent.Thrown = (value == "true")
	end

	--[[Banishment events]]
	if key == "BANISHSTART" then
		NextEvent = {}
		NextEvent.Type = "BANISHMENT"
		NextEvent.Time = RiteTime
	end
	if key == "BANISHSTOP" then
		--[[XXX different event for each team? based on who's dead vs who's killer?]]
		table.insert(RiteInfo.Chrono, NextEvent)
	end
	if key == "BANISHER" then
		NextEvent.Banisher = CHARACTER_MAP[tonumber(value)]
	end
	if key == "BANISHERTEAM" then
		if tonumber(value) == TEAM_A_NUMBER then
			NextEvent.BanisherTeam = "A"
		else
			NextEvent.BanisherTeam = "B"
		end
	end
	if key == "BANISHEE" then
		NextEvent.Banishee = CHARACTER_MAP[tonumber(value)]
	end
	if key == "BANISHEETEAM" then
		if tonumber(value) == TEAM_A_NUMBER then
			NextEvent.BanisheeTeam = "A"
		else
			NextEvent.BanisheeTeam = "B"
		end
	end
end

function NewRiteInfo()
	return {
		Common={},
		A={Triumvirate=nil, Exiles={}, Scores={},},
		B={Triumvirate=nil, Exiles={}, Scores={},},
		Chrono={}
	}
end

function ToggleSection()
	if CurrentSection == SECTION_CHRONO then
		CurrentSection = SECTION_EXILES
	else
		CurrentSection = SECTION_CHRONO
	end
end

---------- ---------- ----------

function love.load(argv, unfilteredArgv)
	print("*** Rite Club Companion ***")

	love.window.setTitle("Pyre Analytics")
	love.window.setMode(1280, 720)
	love.graphics.setBackgroundColor(0, 0, 0, 1)

	ReadConfigFile()

	OurOS = love.system.getOS()

	PyreEngaged = false
	PyreTime = 0

	RiteEngaged = false
	RiteTime = 0
	RiteInfo = NewRiteInfo()

	PyreStarImg = love.graphics.newImage("ui/pyre.png")

	CurrentSection = SECTION_NONE
	CurrentlyRecording = false

	local recordercode = love.filesystem.read("pyre_recorder_thread.lua")
	PyreRecorderThread = love.thread.newThread(recordercode)
	PyreRecorderPID = -1
end

function love.threaderror(thread, errorstr)
	print("** THREAD ERROR", tostring(thread), tostring(errorstr))
end

function love.update(dt)
	if PyreEngaged then
		PyreTime = PyreTime + dt
	end

	if RiteEngaged then
		RiteTime = RiteTime + dt
	end

	local msg

	if PyreThread and PyreThread:isRunning() then
		while love.thread.getChannel("RITECLUB"):peek() do
			msg = love.thread.getChannel("RITECLUB"):pop()
			print(string.format("(Pyre) %s", serpent.line(msg)))
			AnalyzeMessage(msg)
		end
	end
end

function love.keypressed(key, scancode, isrepeat)
	if CurrentSection == SECTION_NONE then
		if key == "return" then
			LaunchPyre()
		end
	else
		if key == "return" then
			ToggleSection()
		end
	end
end

function love.draw()
	if CurrentSection == SECTION_NONE then
		local star_x = love.graphics.getWidth()/2 - PyreStarImg:getWidth()/2
		local star_y = love.graphics.getHeight()/2 - PyreStarImg:getHeight()/2

		love.graphics.draw(PyreStarImg, star_x, star_y)

		love.graphics.printf("Press RETURN", 0, star_y + PyreStarImg:getHeight() + 10, love.graphics.getWidth(), "center")
	end

	love.graphics.setFont(DEFAULT_FONT)
	love.graphics.print(string.format("PYRE TIME = %s", SecondsToPrettyTime(PyreTime)), 10, 10)
	love.graphics.print(string.format("CURRENT_SECTION = %s", CurrentSection), 10, 24)

	local team_a_basex = 250
	local team_b_basex = 750
	local exilescale = 0.35

	if RiteInfo.Common.Arena then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(RiteInfo.Common.Arena.Preview, 10, 100)
		love.graphics.setFont(ARENA_NAME_FONT)
		love.graphics.print(RiteInfo.Common.Arena.Name, 10, 100+RiteInfo.Common.Arena.Preview:getHeight()+4)

		local timecode_y = 100+RiteInfo.Common.Arena.Preview:getHeight()+50

		if CurrentlyRecording then
			love.graphics.setColor(1, 0, 0, 1)
			love.graphics.circle("fill", 40, timecode_y + ARENA_NAME_FONT:getHeight()/2, ARENA_NAME_FONT:getHeight()/4)
			love.graphics.setColor(1, 1, 1, 1)
		end

		love.graphics.print(SecondsToPrettyTimeFrac(RiteTime), 60, timecode_y)
	end


	if CurrentSection == SECTION_CHRONO then
		if RiteInfo.A.Triumvirate and RiteInfo.B.Triumvirate then
			local sigil_a = RiteInfo.A.Triumvirate.Sigil
			local sigil_b = RiteInfo.B.Triumvirate.Sigil
			love.graphics.draw(sigil_a, team_a_basex + 200, 10, 0, 0.5)
			love.graphics.draw(sigil_b, team_b_basex + 200, 10, 0, 0.5)
			love.graphics.setFont(ARENA_NAME_FONT)
			love.graphics.print(RiteInfo.A.Triumvirate.Name, team_a_basex + 200 + (sigil_a:getWidth()*0.5), 15)
			love.graphics.print(RiteInfo.B.Triumvirate.Name, team_b_basex + 200 + (sigil_a:getWidth()*0.5), 15)
		end

		local display_i = 0

		for i = math.max(1, #RiteInfo.Chrono-8), #RiteInfo.Chrono, 1 do
			display_i = display_i + 1
			local event = RiteInfo.Chrono[i]
			local x
			local y
			local thrown

			if event.Type == "SCORE" then
				if event.Thrown then thrown = "T" else thrown = "-" end
				if event.Team == "A" then x = team_a_basex else x = team_b_basex end
			elseif event.Type == "BANISHMENT" then
				if event.BanisherTeam == "A" then
					x = team_a_basex
				else
					x = team_b_basex
				end
			end

			local portrait

			if event.Type == "SCORE" then
				portrait = event.Exile.Portrait
			else
				portrait = event.Banisher.Portrait
			end

			y = (display_i*20) + display_i*(portrait:getHeight()*exilescale) + 8

			if display_i % 2 == 0 then
				love.graphics.setColor(0.4, 0.4, 0.4, 1.0)
			else
				love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
			end
			love.graphics.rectangle("fill", team_a_basex, y, (team_b_basex - team_a_basex)*2, portrait:getHeight()*exilescale + 8)

			love.graphics.setColor(1, 1, 1, 1)

			if event.Type == "SCORE" then
				love.graphics.draw(event.Exile.Portrait, x, y, 0, exilescale)

				love.graphics.setFont(EVENT_FONT)
				love.graphics.print(
					string.format("%s [%s] %s (%d)", SecondsToPrettyTimeFrac(event.Time), thrown, event.Exile.Name, event.Value),
					x + event.Exile.Portrait:getWidth()*exilescale + 8, y
				)
			end

			if event.Type == "BANISHMENT" then
				love.graphics.setFont(EVENT_FONT)
				love.graphics.draw(event.Banisher.Portrait, x, y, 0, exilescale) 
				love.graphics.draw(event.Banishee.Portrait, x + event.Banisher.Portrait:getWidth()*exilescale, y, 0, exilescale)
				love.graphics.print(SecondsToPrettyTimeFrac(event.Time), x + event.Banisher.Portrait:getWidth()*exilescale*2+ 8, y)
			end
		end
	end

	if CurrentSection == SECTION_EXILES then
		local y
		for i, exile in ipairs(RiteInfo.A.Exiles) do
			y = (display_i-1)*100 + 20
			love.graphics.draw(exile.Portrait, 250, y, 0, 0.5)
			if exile.Talisman then
				love.graphics.draw(exile.Talisman.Image, 250 + (exile.Portrait:getWidth()*0.5) + 8, y, 0, 0.85)
			end
		end

		for i, exile in ipairs(RiteInfo.B.Exiles) do
			y = (display_i+3)*100 + 29
			love.graphics.draw(exile.Portrait, 250, y, 0, 0.5)
			if exile.Talisman then
				love.graphics.draw(exile.Talisman.Image, 250 + (exile.Portrait:getWidth()*0.5) + 8, y, 0, 0.85)
			end
		end
	end
end

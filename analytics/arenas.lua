function Arena(name, letter)
	local previewfile = string.format("arenas/LocalePreview_MatchSite%s.png", letter)

	return {
		Name = name,
		Letter = letter,
		Preview = love.graphics.newImage(previewfile),
	}
end

ARENA_BOOKOFRITES = Arena("Book of Rites", "A")
ARENA_CAIRNOFHAUB = Arena("Cairn of Ha'ub", "D")
ARENA_FALLOFSOLIAM = Arena("Fall of Soliam", "I")
ARENA_GLADEOFLU = Arena("Glade of Lu", "H")
ARENA_HULKOFORES = Arena("Hulk of Ores", "F")
ARENA_ISLEOFKHAYLMER = Arena("Isle of Khaylmer", "J")
ARENA_NESTOFTRIESTA = Arena("Nest of Triesta", "G")
ARENA_PITOFMILITHE = Arena("Pit of Milithe", "E")
ARENA_RIDGEOFGOL = Arena("Ridge of Gol", "B")
ARENA_SPRINGOFJOMUER = Arena("Spring of Jomuer", "C")

--[[This is the official mapping within the game.]]
ARENA_MAP = {
	A = ARENA_BOOKOFRITES,
	B = ARENA_RIDGEOFGOL,
	C = ARENA_SPRINGOFJOMUER,
	D = ARENA_CAIRNOFHAUB,
	E = ARENA_PITOFMILITHE,
	F = ARENA_HULKOFORES,
	G = ARENA_NESTOFTRIESTA,
	H = ARENA_GLADEOFLU,
	I = ARENA_FALLOFSOLIAM,
	J = ARENA_ISLEOFKHAYLMER,
}

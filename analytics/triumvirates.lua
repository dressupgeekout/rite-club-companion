function Triumvirate(name, ...)
	local sigilname
	if ... then sigilname = ... else sigilname = name end
	return {
		Name = name,
		Sigil = love.graphics.newImage("sigils/"..sigilname..".png")
	}
end

TRIUMVIRATE_ACCUSERS = Triumvirate("Accusers")
TRIUMVIRATE_BEYONDERS = Triumvirate("Beyonders")
TRIUMVIRATE_CHASTITY = Triumvirate("Chastity")
TRIUMVIRATE_DISSIDENTS = Triumvirate("Dissidents")
TRIUMVIRATE_ESSENCE = Triumvirate("Essence")
TRIUMVIRATE_FATE = Triumvirate("Fate")
TRIUMVIRATE_NIGHTWINGS = Triumvirate("Nightwings")
TRIUMVIRATE_PYREHEARTS = Triumvirate("Pyrehearts")
TRIUMVIRATE_TEMPERS = Triumvirate("Tempers")
TRIUMVIRATE_TRUENIGHTWINGS = Triumvirate("True Nightwings", "TrueNightwings")
TRIUMVIRATE_WITHDRAWN = Triumvirate("Withdrawn")

TRIUMVIRATE_MAP = {
	[1]  = TRIUMVIRATE_NIGHTWINGS,
	[2]  = TRIUMVIRATE_ACCUSERS,
	[3]  = TRIUMVIRATE_FATE,
	[4]  = TRIUMVIRATE_DISSIDENTS,
	[5]  = TRIUMVIRATE_WITHDRAWN,
	[6]  = TRIUMVIRATE_PYREHEARTS,
	[7]  = TRIUMVIRATE_ESSENCE,
	[8]  = TRIUMVIRATE_CHASTITY,
	[9]  = TRIUMVIRATE_TEMPERS,
	[10] = TRIUMVIRATE_BEYONDERS,
	[11] = TRIUMVIRATE_TRUENIGHTWINGS,
}

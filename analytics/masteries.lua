function Mastery(name)
	return {
		Name = name,
		Image = love.graphics.newImage(string.format("masteries/skill_icon_%s.png", string.lower(name))),
	}
end

MASTERY_AURA = Mastery("Aura")
MASTERY_BALL = Mastery("Ball")
MASTERY_BANISHMENT = Mastery("Banishment")
MASTERY_CAST = Mastery("Cast")
MASTERY_EVADE = Mastery("Evade")
MASTERY_PYREDAMAGE = Mastery("Pyredamage")
MASTERY_PYREHEALTH = Mastery("Pyrehealth")
MASTERY_RESPAWN = Mastery("Respawn")
MASTERY_SPECIAL = Mastery("Special")
MASTERY_SPEED = Mastery("Speed")
MASTERY_SPRINT = Mastery("Sprint")
MASTERY_STAMINA = Mastery("Stamina")
MASTERY_TAUNT = Mastery("Taunt")

MASTERY_MAP = {
	Aura = MASTERY_AURA,
	Ball = MASTERY_BALL,
	Banishment = MASTERY_BANISHMENT,
	Cast = MASTERY_CAST,
	Evade = MASTERY_EVADE,
	Pyredamage = MASTERY_PYREDAMAGE,
	Pyrehealth = MASTERY_PYREHEALTH,
	Respawn = MASTERY_RESPAWN,
	Special = MASTERY_SPECIAL,
	Speed = MASTERY_SPEED,
	Sprint = MASTERY_SPRINT,
	Stamina = MASTERY_STAMINA,
	Taunt = MASTERY_TAUNT,
}

function Talisman(name, ...)
	local imagename

	if ... then
		imagename = ...
	else
		imagename, _ = string.gsub(name, "%s+", "_")
		imagename = string.gsub(imagename, "[^%w_]+", "")
		imagename = string.lower(imagename)
	end

	return {
		Name = name,
		Image = love.graphics.newImage(string.format("talismans/%s_01.png", imagename)),
	}
end

TALISMAN_ASHEN_COAL       = Talisman("Ashen Coal")
TALISMAN_ASTRAL_EYE       = Talisman("Astral Eye")
TALISMAN_BLACK_CLAW       = Talisman("Black Claw")
TALISMAN_BLACK_HEART      = Talisman("Black Heart")
TALISMAN_BLACK_HOOF       = Talisman("Black Hoof")
TALISMAN_BOTTLED_VOID     = Talisman("Bottled Void")
TALISMAN_BRIGHT_WISP      = Talisman("Bright Wisp")
TALISMAN_CUR_FANG         = Talisman("Cur Fang")
TALISMAN_DYING_FLAME      = Talisman("Dying Flame")
TALISMAN_FAERIE_DUST      = Talisman("Faerie Dust")
TALISMAN_FAITH_STONE      = Talisman("Faith Stone")
TALISMAN_FLAME_LEECH      = Talisman("Flame Leech")
TALISMAN_FROZEN_SOUL      = Talisman("Frozen Soul")
TALISMAN_GOLS_BRACER      = Talisman("Gol's Bracer")
TALISMAN_HAUBS_WING       = Talisman("Haub's Wing")
TALISMAN_INFERNAL_BLOOM   = Talisman("Infernal Bloom")
TALISMAN_JEWELED_BAND     = Talisman("Jeweled Band")
TALISMAN_JOMUERS_FANG     = Talisman("Jomuer's Fang")
TALISMAN_KHAYLMERS_ANKLET = Talisman("Khaylmer's Anklet")
TALISMAN_LIVING_FLAME     = Talisman("Living Flame")
TALISMAN_LUMINOUS_IDOL    = Talisman("Luminous Idol")
TALISMAN_LUNAR_GLASS      = Talisman("Lunar Glass")
TALISMAN_LUS_REED         = Talisman("Lu's Bough", "lus_reed")
TALISMAN_MILITHES_SKIN    = Talisman("Milithe's Skin")
TALISMAN_MOON_CREST       = Talisman("Moon Crest")
TALISMAN_MOTTLED_FLASK    = Talisman("Mottled Flask")
TALISMAN_NIHILAND_LEECH   = Talisman("Nihiland Leech")
TALISMAN_ORES_SCALE       = Talisman("Ores' Scale")
TALISMAN_PRAYER_BEADS     = Talisman("Prayer Beads")
TALISMAN_RIGHTEOUS_FLAME  = Talisman("Righteous Flame")
TALISMAN_RITE_LITE        = Talisman("Rite Lite")
TALISMAN_RUNED_BAND       = Talisman("Runed Band")
TALISMAN_SHOOTING_STAR    = Talisman("Shooting Star")
TALISMAN_SLING_BULLET     = Talisman("Sling Bullet")
TALISMAN_SOLIAMS_HORN     = Talisman("Soliam's Horn")
TALISMAN_STAR_SPLINTER    = Talisman("Star Splinter")
TALISMAN_SUNKEN_SHADOW    = Talisman("Sunken Shadow")
TALISMAN_TAILWIND_CREST   = Talisman("Tailwind Crest")
TALISMAN_THORNED_KNOT     = Talisman("Thorned Knot")
TALISMAN_TITAN_TOOTH      = Talisman("Titan Tooth")
TALISMAN_TRIESTAS_PLUME   = Talisman("Triesta's Plume", "_triestas_plume")
TALISMAN_TYPHOON_BOTTLE   = Talisman("Typhoon Bottle")
TALISMAN_VENGEFUL_VOW     = Talisman("Vengeful Vow")
TALISMAN_WEBBED_LANTHORN  = Talisman("Webbed Lanthorn")

TALISMAN_MAP = {
	AuraCastRangeItem          = TALISMAN_THORNED_KNOT,
	AuraSpikeKillItem          = TALISMAN_SHOOTING_STAR,
	AuraSpikeStunItem          = TALISMAN_BLINDING_STAR,
	CarrySpeedItem             = TALISMAN_LUNAR_GLASS,
	CursedItem01               = TALISMAN_BLACK_HOOF,
	CursedItem02               = TALISMAN_BLACK_HEART,
	EnemyRespawnIncreaseItem   = TALISMAN_SUNKEN_SHADOW,
	GoalHealItem               = TALISMAN_RIGHTEOUS_FLAME,
	GoalLifeStealItem          = TALISMAN_FLAME_LEECH,
	JumpBashItem               = TALISMAN_TITAN_TOOTH,
	KillDetonateItem           = TALISMAN_INFERNAL_BLOOM,
	KillsRegenerateStaminaItem = TALISMAN_NIHILAND_LEECH,
	KillsRespawnFriendsItem    = TALISMAN_WEBBED_LANTHORN,
	LosingScoreItem            = TALISMAN_DYING_FLAME,
	OnDeathExplosionItem       = TALISMAN_VENGEFUL_VOW,
	PassOnDeathItem            = TALISMAN_BRIGHT_WISP,
	PlusAuraItem               = TALISMAN_SCRIBE_ROCK,
	PlusRespawnItem            = TALISMAN_FAITH_STONE,
	PlusSpeedItem              = TALISMAN_TAILWIND_CREST,
	PowerUpDropOnKillItem      = TALISMAN_FAERIE_SPIRIT,
	PyreDamageItem             = TALISMAN_ASTRAL_EYE,
	PyreHealthItem             = TALISMAN_ASHEN_COAL,
	PyreLastHitShieldItem      = TALISMAN_RITE_LITE,
	PyrePreDamageItem          = TALISMAN_FROZEN_SOUL,
	QuickRespawnItem           = TALISMAN_MOON_CREST,
	RandomScoreItem            = TALISMAN_CHAOS_FLAME,
	RespawnWeaponItem          = TALISMAN_BOTTLED_VOID,
	SacrificeDamageItem        = TALISMAN_CUR_FANG,
	SacrificeScoreRespawnItem  = TALISMAN_PRAYER_BEADS,
	SetItem01                  = TALISMAN_JEWELED_BAND,
	SetItem02                  = TALISMAN_RUNED_BAND,
	StaminaOnBallPickupItem    = TALISMAN_LUMINOUS_IDOL,
	TauntScoreItem             = TALISMAN_LEERING_MASK,
	TeamHeadwindsItem          = TALISMAN_TYPHOON_BOTTLE,
	TeamStaminaRechargeItem    = TALISMAN_MOTTLED_FLASK,
	ThrowDamageItem            = TALISMAN_TWILIGHT_SHARD,
	TossChargeTimeItem         = TALISMAN_STAR_SPLINTER,
	TossDistanceItem           = TALISMAN_SLING_BULLET,
	UniqueFlyingItem01         = TALISMAN_TRIESTAS_PLUME,
	UniqueImpItem01            = TALISMAN_HAUBS_WING,
	UniqueLargeItem01          = TALISMAN_SOLIAMS_HORN,
	UniqueMediumAltItem01      = TALISMAN_KHAYLMERS_ANKLET,
	UniqueMediumItem01         = TALISMAN_GOLS_BRACER,
	UniqueMonsterItem01        = TALISMAN_MILITHES_TAIL,
	UniqueSmallItem01          = TALISMAN_JOMUERS_FANG,
	UniqueTrailItem01          = TALISMAN_ORES_SCALE,
	UniqueTreeItem01           = TALISMAN_LUS_BOUGH,
	WinningScoreItem           = TALISMAN_LIVING_FLAME,
}

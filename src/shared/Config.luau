-- Tunables for the whole game. Pure data; no behaviour lives here.

local Config = {}

-- ground is a 760x760 slab centred on the origin (see default.project.json)
Config.WorldHalf = 380

-- player movement
Config.BaseWalkSpeed = 17
Config.CarrySpeedFactor = 0.6
Config.JumpPower = 50

-- bases on a ring around the plaza
Config.BaseCount = 6
Config.BaseRingRadius = 175
Config.BaseRadius = 34
Config.PedestalsPerBase = 8
Config.PedestalRingRadius = 20

-- the plaza lane where wild brainrot drift past (west -> east along +X)
Config.Lane = {
	Z = 8,
	HalfLength = 78,
	Speed = 9,
	SpawnEvery = 3.2,
	MaxWild = 14,
	Width = 16,
}

-- konbini (safe zone, spawn, shop counter) sits north of the lane
Config.Konbini = {
	Center = Vector3.new(0, 0, -52),
	HalfX = 34,
	HalfZ = 18,
	SpawnPad = Vector3.new(0, 0.6, -28),
}

-- interactions
Config.CatchHold = 1.1
Config.StealHold = 0.8
Config.StealCooldown = 4
Config.PlaceHold = 0
Config.CollectHold = 0
Config.LockCost = 200
Config.LockSeconds = 60

-- income meter cap on a pedestal, seconds' worth
Config.MeterCap = 900

-- neon tide wave
Config.Tide = {
	FirstDelay = 40,
	MinGap = 60,
	MaxGap = 90,
	Warning = 8,
	Travel = 14,
	HalfSpan = 330,
	Thickness = 10,
	Height = 34,
	Knockback = 70,
}

-- patrol robots
Config.Patrol = {
	Count = 2,
	Walk = 12,
	Chase = 21,
	Sight = 42,
	StunSeconds = 4,
	Orbit = 84,
}

-- persistence
Config.AutosaveSeconds = 60
Config.StoreName = "KonbiniBrainrot_v2"

-- guidance tuning (client)
Config.Guide = {
	ChevronSpacing = 5,
	ChevronCount = 7,
	NearGoal = 9,
}

return Config

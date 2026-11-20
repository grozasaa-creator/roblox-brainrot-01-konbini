-- Builds a character Model out of primitive parts. Used by the server for wild, carried and placed
-- characters. Parts are welded to an invisible Root so the whole thing can be anchored or carried.

local CollectionService = game:GetService("CollectionService")

local Characters = require(script.Parent.Characters)
local Mutations = require(script.Parent.Mutations)
local Rarity = require(script.Parent.Rarity)
local Economy = require(script.Parent.Economy)

local CharacterModel = {}

local function styleFor(part, spec, mutation, flickerIndex)
	local color = spec.color
	local material = (spec.extra and spec.extra.mat) or Enum.Material.SmoothPlastic
	local mdef = Mutations.Defs[mutation]
	if mdef then
		material = mdef.material
		if mutation == "Glitch" then
			-- alternate two hot colours so it reads as "broken"
			color = (flickerIndex % 2 == 0) and mdef.tint or Color3.fromRGB(120, 255, 90)
		else
			color = color:Lerp(mdef.tint, 0.75)
		end
	end
	part.Color = color
	part.Material = material
	part.Transparency = (spec.extra and spec.extra.transparency) or 0
end

local function makePart(spec, rootCFrame, mutation, i, k)
	local p = Instance.new("Part")
	p.Name = "P" .. i
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.Anchored = false
	local local_cf = CFrame.new(spec.off * k)
	local size = spec.size * k
	if spec.shape == "Ball" then
		p.Shape = Enum.PartType.Ball
		p.Size = size
	elseif spec.shape == "Cyl" then
		p.Shape = Enum.PartType.Cylinder
		-- Roblox cylinders run along X; swap axes and lay it upright
		p.Size = Vector3.new(size.Y, size.X, size.Z)
		local_cf = local_cf * CFrame.Angles(0, 0, math.rad(90))
	else
		p.Size = size
	end
	styleFor(p, spec, mutation, i)
	p.CFrame = rootCFrame * local_cf
	return p
end

local function addEyes(model, root, def, k)
	local fd = def.face
	if not fd then
		return
	end
	local f = { y = fd.y * k, z = fd.z * k, gap = fd.gap * k, size = fd.size * k }
	for _, side in ipairs({ -1, 1 }) do
		local white = Instance.new("Part")
		white.Name = "Eye"
		white.Shape = Enum.PartType.Ball
		white.Size = Vector3.new(f.size, f.size * 1.15, f.size * 0.6)
		white.Color = Color3.fromRGB(255, 255, 255)
		white.Material = Enum.Material.SmoothPlastic
		white.CanCollide = false
		white.CanTouch = false
		white.CanQuery = false
		white.Massless = true
		white.CFrame = root.CFrame * CFrame.new(side * f.gap, f.y, f.z)
		white.Parent = model
		local pupil = Instance.new("Part")
		pupil.Name = "Pupil"
		pupil.Shape = Enum.PartType.Ball
		pupil.Size = Vector3.new(f.size * 0.45, f.size * 0.55, f.size * 0.3)
		pupil.Color = Color3.fromRGB(15, 15, 25)
		pupil.Material = Enum.Material.SmoothPlastic
		pupil.CanCollide = false
		pupil.CanTouch = false
		pupil.CanQuery = false
		pupil.Massless = true
		pupil.CFrame = root.CFrame * CFrame.new(side * f.gap, f.y, f.z - f.size * 0.22)
		pupil.Parent = model
	end
end

local function weldAll(model, root)
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") and d ~= root then
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = d
			w.Parent = d
		end
	end
end

-- Returns a Model positioned with its feet at `at` (a CFrame). `anchored` decides whether Root is fixed;
-- `k` uniformly scales the geometry (1 = natural size).
function CharacterModel.build(charId, mutation, at, anchored, k)
	local def = Characters.get(charId)
	assert(def, "unknown character " .. tostring(charId))
	mutation = mutation or Mutations.None
	k = k or 1

	local model = Instance.new("Model")
	model.Name = def.name

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 0.4, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Anchored = anchored and true or false
	root.CFrame = at or CFrame.new()
	root.Parent = model
	model.PrimaryPart = root

	for i, spec in ipairs(def.parts) do
		makePart(spec, root.CFrame, mutation, i, k).Parent = model
	end
	addEyes(model, root, def, k)
	weldAll(model, root)

	model:SetAttribute("CharId", charId)
	model:SetAttribute("Mutation", mutation)
	model:SetAttribute("Rarity", def.rarity)
	model:SetAttribute("Height", def.height * k)
	model:SetAttribute("Income", Economy.income(charId, mutation, 0))
	CollectionService:AddTag(model, "Brainrot")
	return model
end

function CharacterModel.rarityColor(charId)
	local def = Characters.get(charId)
	return Rarity.get(Rarity.indexOf(def and def.rarity or "Common")).color
end

return CharacterModel

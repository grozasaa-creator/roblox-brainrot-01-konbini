-- キャラ定義から 3D モデル（Part の組み合わせ）を組み立てる。サーバーが呼び、タグと属性で見た目を伝える。
local Characters = require(script.Parent.Characters)
local Mutations = require(script.Parent.Mutations)
local Rarity = require(script.Parent.Rarity)

local CharacterModel = {}

local SHAPES = {
	Block = Enum.PartType.Block,
	Ball = Enum.PartType.Ball,
	Cylinder = Enum.PartType.Cylinder,
}

local function makePart(model: Model, spec, scale: number, mutation, isBody: boolean)
	local part
	if spec.s == "Wedge" then
		part = Instance.new("WedgePart")
	else
		part = Instance.new("Part")
		part.Shape = SHAPES[spec.s]
	end
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = spec.size * scale
	local rot = spec.rot or Vector3.zero
	part.CFrame = CFrame.new(spec.pos * scale) * CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
	part.Color = spec.c
	part.Material = spec.m or Enum.Material.SmoothPlastic
	part.Transparency = spec.t or 0
	if mutation and not spec.rainbow then
		part.Color = mutation.color
		part.Material = mutation.material
	end
	part.Name = isBody and "Body" or "Piece"
	if spec.rainbow then
		part:AddTag("Rainbow")
	end
	if mutation and mutation.id == "Glitch" then
		part:AddTag("Glitch")
	end
	part.Parent = model
	return part
end

local function makeEyes(model: Model, face, scale: number)
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Shape = Enum.PartType.Ball
		eye.Name = "Eye"
		eye.Anchored = true
		eye.CanCollide = false
		eye.Size = Vector3.one * face.eye * scale
		eye.Color = Color3.new(1, 1, 1)
		eye.Material = Enum.Material.SmoothPlastic
		eye.CFrame = CFrame.new((face.pos + Vector3.new(side * face.eye * 0.75, 0, 0)) * scale)
		eye.Parent = model
		local pupil = Instance.new("Part")
		pupil.Shape = Enum.PartType.Ball
		pupil.Name = "Pupil"
		pupil.Anchored = true
		pupil.CanCollide = false
		pupil.Size = Vector3.one * face.eye * 0.45 * scale
		pupil.Color = Color3.new(0, 0, 0)
		pupil.CFrame = CFrame.new((face.pos + Vector3.new(side * face.eye * 0.75 + side * -0.05, -0.05, face.eye * 0.35)) * scale)
		pupil.Parent = model
	end
end

-- 足元が原点、+Z が正面。WorldPivot を原点に置くので PivotTo/ScaleTo は足元基準で効く（PrimaryPart は使わない）。
function CharacterModel.build(charId: string, mutationId: string?): Model
	local def = Characters.byId[charId]
	local mutation = mutationId and Mutations.byId[mutationId] or nil
	local scale = def.scale or 1

	local model = Instance.new("Model")
	model.Name = def.name
	local topY = 0
	for i, spec in ipairs(def.parts) do
		makePart(model, spec, scale, mutation, i == 1)
		topY = math.max(topY, (spec.pos.Y + spec.size.Y / 2) * scale)
	end
	makeEyes(model, def.face, scale)

	-- レア度の台座リング（色でレア度が分かる）
	local ring = Instance.new("Part")
	ring.Name = "RarityRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.Size = Vector3.new(0.3, 5 * scale, 5 * scale)
	ring.CFrame = CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90))
	local rarity = Rarity.byName[def.rarity]
	ring.Color = rarity.color
	ring.Material = Enum.Material.Neon
	if rarity.name == "Mythic" then
		ring:AddTag("Rainbow")
	end
	ring.Parent = model

	model.WorldPivot = CFrame.new()
	model:SetAttribute("CharId", charId)
	model:SetAttribute("Mutation", mutationId or "")
	model:SetAttribute("Rarity", def.rarity)
	model:SetAttribute("Height", topY)
	model:AddTag("Brainrot")
	return model
end

return CharacterModel

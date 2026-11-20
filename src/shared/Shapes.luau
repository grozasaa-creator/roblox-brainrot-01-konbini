-- Small geometry helpers shared by the server (static signage) and the client (live guide arrows).

local Shapes = {}

local function bar(parent, cf, size, color, material, transparency)
	local p = Instance.new("Part")
	p.Name = "Bar"
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Transparency = transparency
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- A ">" shape: the apex sits half a `reach` ahead of `cf` (forward = LookVector), the arms sweep back and out.
-- Returns the two bars so callers can tint or fade them.
function Shapes.chevron(parent, cf, reach, thickness, color, material, transparency)
	material = material or Enum.Material.Neon
	transparency = transparency or 0
	local arm = reach * 1.4142
	local half = reach * 0.5
	local size = Vector3.new(thickness, thickness * 0.5, arm)
	local right = bar(parent, cf * CFrame.new(half, 0, -half) * CFrame.Angles(0, math.rad(45), 0), size, color, material, transparency)
	local left = bar(parent, cf * CFrame.new(-half, 0, -half) * CFrame.Angles(0, math.rad(-45), 0), size, color, material, transparency)
	return right, left
end

-- moves a chevron made by Shapes.chevron to a new frame without rebuilding it
function Shapes.placeChevron(right, left, cf, reach)
	local half = reach * 0.5
	right.CFrame = cf * CFrame.new(half, 0, -half) * CFrame.Angles(0, math.rad(45), 0)
	left.CFrame = cf * CFrame.new(-half, 0, -half) * CFrame.Angles(0, math.rad(-45), 0)
end

-- A flat disc (cylinder lying down) of the given diameter.
function Shapes.disc(parent, pos, diameter, height, color, material, transparency)
	local p = Instance.new("Part")
	p.Name = "Disc"
	p.Shape = Enum.PartType.Cylinder
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Size = Vector3.new(height, diameter, diameter)
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	p.Color = color
	p.Material = material or Enum.Material.Neon
	p.Transparency = transparency or 0
	p.Parent = parent
	return p
end

return Shapes

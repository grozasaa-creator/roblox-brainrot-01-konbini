-- Every piece of GUI text in the game is made here, so it is always TextScaled, wrapped and clamped
-- inside its own frame. Sizes are given as scale; a UISizeConstraint keeps frames sane on huge/tiny screens.

local UiKit = {}

UiKit.Colors = {
	Panel = Color3.fromRGB(32, 26, 72),
	PanelLight = Color3.fromRGB(58, 48, 118),
	Text = Color3.fromRGB(255, 255, 255),
	Gold = Color3.fromRGB(255, 226, 90),
	Mint = Color3.fromRGB(110, 255, 200),
	Pink = Color3.fromRGB(255, 120, 225),
	Red = Color3.fromRGB(255, 85, 100),
	Dim = Color3.fromRGB(150, 145, 190),
}

function UiKit.corner(inst, scale)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale or 0.2, 0)
	c.Parent = inst
	return c
end

function UiKit.stroke(inst, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

function UiKit.limitSize(inst, minW, minH, maxW, maxH)
	local c = Instance.new("UISizeConstraint")
	c.MinSize = Vector2.new(minW or 0, minH or 0)
	c.MaxSize = Vector2.new(maxW or math.huge, maxH or math.huge)
	c.Parent = inst
	return c
end

local function apply(inst, props)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
end

function UiKit.frame(parent, props)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = UiKit.Colors.Panel
	f.BorderSizePixel = 0
	apply(f, props)
	f.Parent = parent
	return f
end

-- opts: MaxText / MinText bound the scaled text; pad is the inner padding as a fraction of the label
function UiKit.label(parent, text, props, opts)
	opts = opts or {}
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = UiKit.Colors.Text
	l.Text = text
	l.TextScaled = true
	l.TextWrapped = true
	l.TextTruncate = Enum.TextTruncate.None
	apply(l, props)
	l.Parent = parent

	local pad = Instance.new("UIPadding")
	local p = opts.pad or 0.08
	pad.PaddingTop = UDim.new(p, 0)
	pad.PaddingBottom = UDim.new(p, 0)
	pad.PaddingLeft = UDim.new(p * 0.8, 0)
	pad.PaddingRight = UDim.new(p * 0.8, 0)
	pad.Parent = l

	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = opts.MinText or 6
	limit.MaxTextSize = opts.MaxText or 34
	limit.Parent = l
	return l
end

function UiKit.button(parent, text, props, opts)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.BackgroundColor3 = UiKit.Colors.PanelLight
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBlack
	b.TextColor3 = UiKit.Colors.Text
	b.Text = text
	b.TextScaled = true
	b.TextWrapped = true
	apply(b, props)
	b.Parent = parent

	local pad = Instance.new("UIPadding")
	local p = (opts and opts.pad) or 0.12
	pad.PaddingTop = UDim.new(p, 0)
	pad.PaddingBottom = UDim.new(p, 0)
	pad.PaddingLeft = UDim.new(p * 0.8, 0)
	pad.PaddingRight = UDim.new(p * 0.8, 0)
	pad.Parent = b

	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = (opts and opts.MinText) or 6
	limit.MaxTextSize = (opts and opts.MaxText) or 30
	limit.Parent = b
	UiKit.corner(b, 0.2)
	return b
end

function UiKit.screenGui(name, order)
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = false
	g.DisplayOrder = order or 1
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	return g
end

return UiKit

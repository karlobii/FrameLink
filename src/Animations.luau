--!strict
local Animations = {}

export type Defaults = {
	Size: UDim2,
	Position: UDim2,
	Rotation: number
}

-- Each animation defines its timing, where it starts, and where it goes
Animations.Pop = {
	InfoIn = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	InfoOut = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
	StartState = function(defaults: Defaults) return { Size = UDim2.new(0, 0, 0, 0) } end,
	InGoals = function(defaults: Defaults) return { Size = defaults.Size } end,
	OutGoals = function(defaults: Defaults) return { Size = UDim2.new(0, 0, 0, 0) } end,
}

Animations.PopSpin = {
	InfoIn = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	InfoOut = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
	StartState = function(defaults: Defaults) return { Size = UDim2.new(0, 0, 0, 0), Rotation = -60 } end,
	InGoals = function(defaults: Defaults) return { Size = defaults.Size, Rotation = defaults.Rotation } end,
	OutGoals = function(defaults: Defaults) return { Size = UDim2.new(0, 0, 0, 0), Rotation = -60 } end,
}

Animations.SlideBottom = {
	InfoIn = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	InfoOut = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
	StartState = function(defaults: Defaults) return { Position = UDim2.new(defaults.Position.X.Scale, defaults.Position.X.Offset, 1.5, 0) } end,
	InGoals = function(defaults: Defaults) return { Position = defaults.Position } end,
	OutGoals = function(defaults: Defaults) return { Position = UDim2.new(defaults.Position.X.Scale, defaults.Position.X.Offset, 1.5, 0) } end,
}

Animations.Top = {
	InfoIn = TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
	InfoOut = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
	StartState = function(defaults: Defaults) return { Position = UDim2.new(defaults.Position.X.Scale, defaults.Position.X.Offset, -0.5, 0) } end,
	InGoals = function(defaults: Defaults) return { Position = defaults.Position } end,
	OutGoals = function(defaults: Defaults) return { Position = UDim2.new(defaults.Position.X.Scale, defaults.Position.X.Offset, -0.5, 0) } end,
}

Animations.SlideRight = {
	InfoIn = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	InfoOut = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
	StartState = function(defaults: Defaults) return { Position = UDim2.new(1.5, 0, defaults.Position.Y.Scale, defaults.Position.Y.Offset) } end,
	InGoals = function(defaults: Defaults) return { Position = defaults.Position } end,
	OutGoals = function(defaults: Defaults) return { Position = UDim2.new(1.5, 0, defaults.Position.Y.Scale, defaults.Position.Y.Offset) } end,
}

Animations.SlideLeft = {
	InfoIn = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	InfoOut = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
	StartState = function(defaults: Defaults) return { Position = UDim2.new(-0.5, 0, defaults.Position.Y.Scale, defaults.Position.Y.Offset) } end,
	InGoals = function(defaults: Defaults) return { Position = defaults.Position } end,
	OutGoals = function(defaults: Defaults) return { Position = UDim2.new(-0.5, 0, defaults.Position.Y.Scale, defaults.Position.Y.Offset) } end,
}

return Animations
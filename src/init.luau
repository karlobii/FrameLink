--[[
-- FrameLink - UI Animation & State Management Framework
-- Copyright (C) 2026 karlobii (GITHUB)
-- This program is free software: you can redistribute it under the terms of the GNU General Public License v3.0.
-- See <https://www.gnu.org/licenses/> for details.
--]]

--!strict

local TweenService = game:GetService("TweenService")
local AnimationsModule = script:WaitForChild("Animations")
local Animations = require(AnimationsModule) :: { [string]: AnimationDefinition }

export type Defaults = {
	Size: UDim2,
	Position: UDim2,
	Rotation: number,
	[string]: any,
}

export type Goals = {
	Size: UDim2?,
	Position: UDim2?,
	Rotation: number?,
	[string]: any,
}

export type AnimationDefinition = {
	InfoIn: TweenInfo?,
	InfoOut: TweenInfo?,
	InGoals: (Defaults) -> Goals,
	OutGoals: (Defaults) -> Goals,
	StartState: (Defaults) -> { [string]: any },
}

export type Props = {
	In: (string | AnimationDefinition)?, 
	Out: (string | AnimationDefinition)?,
	Anim: (string | AnimationDefinition)?,
	CloseButton: GuiButton?,
	Background: GuiButton?,
	SoundIn: Sound?,
	SoundOut: Sound?, 
	OnOpened: ((FrameLinkObj) -> ())?,
	OnClosed: ((FrameLinkObj) -> ())?,
	tweenInfoIn: TweenInfo?,
	tweenInfoOut: TweenInfo?,
}

export type MultiProps = {
	In: (string | AnimationDefinition)?, 
	Out: (string | AnimationDefinition)?,
	Anim: (string | AnimationDefinition)?,
	CloseButtonName: string?, 
	BackgroundName: string?,
	SoundIn: Sound?,
	SoundOut: Sound?,
	OnOpened: ((FrameLinkObj) -> ())?,
	OnClosed: ((FrameLinkObj) -> ())?,
	tweenInfoIn: TweenInfo?,
	tweenInfoOut: TweenInfo?,
}

type FrameLinkState = {
	props: Props,
	tweens: { In: Tween?, Out: Tween? },
	open: boolean,
	isAnimating: boolean,
	defaultSize: UDim2,
	defaultPosition: UDim2,
	defaultRotation: number,
	startState: { [string]: any },
	frame: GuiObject,
	connections: { RBXScriptConnection },
}

export type FrameLinkObj = typeof(setmetatable({} :: FrameLinkState, {} :: FrameLinkClass))

type FrameLinkClass = {
	__index: FrameLinkClass,
	registerAnimation: (name: string, animDef: AnimationDefinition) -> (),
	_playOpen: (self: FrameLinkObj) -> (),
	setOpen: (self: FrameLinkObj) -> (),
	setClosed: (self: FrameLinkObj) -> (),
	toggle: (self: FrameLinkObj) -> (),
	check: (self: FrameLinkObj, frame: GuiObject?) -> boolean,
	createTweens: (self: FrameLinkObj) -> (),
	init: (self: FrameLinkObj, button: GuiButton?) -> (),
	destroyTweens: (self: FrameLinkObj) -> (),
	destroy: (self: FrameLinkObj) -> (),
	link: (button: GuiButton?, frame: GuiObject, props: Props?) -> FrameLinkObj?,
	multiLink: (buttonFolder: Folder, frameFolder: Folder, multiProps: MultiProps?) -> (),
}

local FrameLink = {} :: FrameLinkClass
FrameLink.__index = FrameLink

local currentFrame: FrameLinkObj? = nil

function FrameLink.registerAnimation(name: string, animDef: AnimationDefinition)
	Animations[name] = animDef
end

function FrameLink._playOpen(self: FrameLinkObj)
	self.open = true

	for property, value in pairs(self.startState) do
		(self.frame :: any)[property] = value
	end

	self.frame.Visible = true

	if self.props.SoundIn then
		self.props.SoundIn:Play()
	end

	if self.props.Background then
		self.props.Background.Visible = true
	end

	local onOpened = self.props.OnOpened
	if onOpened then
		onOpened(self)
	end

	if self.tweens.In then
		self.isAnimating = true
		self.tweens.In:Play()

		self.tweens.In.Completed:Once(function()
			self.isAnimating = false
		end)
	else
		self.isAnimating = false
	end
end

function FrameLink.setOpen(self: FrameLinkObj)
	if self.open == true or self.isAnimating then return end

	if currentFrame and currentFrame ~= self then
		if currentFrame.isAnimating then return end 

		local prevFrame = currentFrame
		currentFrame = self

		if prevFrame.tweens.Out then
			prevFrame.tweens.Out.Completed:Once(function()
				self:_playOpen()
			end)
		else
			self:_playOpen()
		end
		prevFrame:setClosed()
	else
		currentFrame = self
		self:_playOpen()
	end
end

function FrameLink.setClosed(self: FrameLinkObj)
	if self.open == false or self.isAnimating then return end

	if currentFrame == self then
		currentFrame = nil
	end 

	self.open = false

	if self.props.SoundOut then
		self.props.SoundOut:Play()
	end

	if self.props.Background then
		self.props.Background.Visible = false
	end

	if self.tweens.Out then
		self.isAnimating = true
		self.tweens.Out:Play()

		self.tweens.Out.Completed:Once(function()
			self.frame.Visible = false
			self.isAnimating = false

			local onClosed = self.props.OnClosed
			if onClosed then
				onClosed(self)
			end
		end)
	else
		self.frame.Visible = false
		self.isAnimating = false

		local onClosed = self.props.OnClosed
		if onClosed then
			onClosed(self)
		end
	end
end

function FrameLink.toggle(self: FrameLinkObj)
	if self.open == true then
		self:setClosed()
	else
		self:setOpen()
	end
end

function FrameLink.check(self: FrameLinkObj, frame: GuiObject?): boolean
	if not frame then return false end
	if not frame:IsA("GuiObject") then return false end
	return true
end

function FrameLink.createTweens(self: FrameLinkObj)
	self.tweens = {}

	self.startState = {
		Size = self.defaultSize,
		Position = self.defaultPosition,
		Rotation = self.defaultRotation,
	}

	local defaults: Defaults = table.clone(self.startState) :: Defaults

	local inAnimProp = self.props.Anim or self.props.In
	local outAnimProp = self.props.Anim or self.props.Out

	local function getAnimDef(animProp: (string | AnimationDefinition)?): AnimationDefinition?
		if type(animProp) == "table" then
			return animProp
		elseif type(animProp) == "string" then
			return Animations[animProp]
		end
		return nil
	end

	local inGoals: Goals = {}
	local outGoals: Goals = {}
	local inInfo: TweenInfo? = nil
	local outInfo: TweenInfo? = nil

	local inDef = getAnimDef(inAnimProp)
	if inDef then
		inInfo = self.props.tweenInfoIn or inDef.InfoIn
		inGoals = inDef.InGoals(defaults)

		local startStateGoals = inDef.StartState(defaults)
		for prop, val in pairs(startStateGoals) do
			self.startState[prop] = val
		end
	elseif inAnimProp then
		warn("FrameLink: Unknown IN animation")
	end

	local outDef = getAnimDef(outAnimProp)
	if outDef then
		outInfo = self.props.tweenInfoOut or outDef.InfoOut
		outGoals = outDef.OutGoals(defaults)
	elseif outAnimProp then
		warn("FrameLink: Unknown OUT animation")
	end

	if next(inGoals) and inInfo then
		self.tweens.In = TweenService:Create(self.frame, inInfo, inGoals :: { [string]: any })
	end

	if next(outGoals) and outInfo then
		self.tweens.Out = TweenService:Create(self.frame, outInfo, outGoals :: { [string]: any })
	end
end

function FrameLink.init(self: FrameLinkObj, button: GuiButton?)
	if button then
		local connection = button.MouseButton1Click:Connect(function()
			self:toggle()
		end)
		table.insert(self.connections, connection)
	end

	if self.props.CloseButton then
		local connection = self.props.CloseButton.MouseButton1Click:Connect(function()
			self:setClosed()
		end)
		table.insert(self.connections, connection)
	end

	if self.props.Background then
		local connection = self.props.Background.MouseButton1Click:Connect(function()
			self:setClosed()
		end)
		table.insert(self.connections, connection)
	end
end

function FrameLink.destroyTweens(self: FrameLinkObj)
	if self.tweens.In then
		self.tweens.In:Cancel()
		self.tweens.In:Destroy()
		self.tweens.In = nil
	end

	if self.tweens.Out then
		self.tweens.Out:Cancel()
		self.tweens.Out:Destroy()
		self.tweens.Out = nil
	end
end

function FrameLink.destroy(self: FrameLinkObj)
	if currentFrame == self then
		currentFrame = nil
	end

	self:destroyTweens()

	for _, conn in ipairs(self.connections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(self.connections)

	self.open = false
	self.isAnimating = false
end

function FrameLink.link(button: GuiButton?, frame: GuiObject, props: Props?): FrameLinkObj?
	local self = setmetatable({
		open = false,
		isAnimating = false,
		defaultSize = frame.Size,
		defaultPosition = frame.Position,
		defaultRotation = frame.Rotation,
		startState = {},
		tweens = {},
		frame = frame,
		props = props or {},
		connections = {},
	}, FrameLink) :: FrameLinkObj

	if not self:check(frame) then
		warn("FrameLink: Attempted to link an invalid frame.")
		return nil
	end

	self:createTweens()

	for property, value in pairs(self.startState) do
		(self.frame :: any)[property] = value
	end

	self.frame.Visible = false
	if self.props.Background then 
		self.props.Background.Visible = false 
	end

	self:init(button)

	return self
end

function FrameLink.multiLink(buttonFolder: Folder, frameFolder: Folder, multiProps: MultiProps?)
	local safeProps = multiProps or {} :: MultiProps

	for _, button in ipairs(buttonFolder:GetChildren()) do
		local frame = frameFolder:FindFirstChild(button.Name)

		if frame and button:IsA("GuiButton") and frame:IsA("GuiObject") then
			local closeButton: GuiButton? = nil
			if safeProps.CloseButtonName then
				local foundX = frame:FindFirstChild(safeProps.CloseButtonName)
				if foundX and foundX:IsA("GuiButton") then
					closeButton = foundX
				end
			end

			local background: GuiButton? = nil
			if safeProps.BackgroundName and frame.Parent then
				local foundBg = frame.Parent:FindFirstChild(safeProps.BackgroundName)
				if foundBg and foundBg:IsA("GuiButton") then
					background = foundBg
				end
			end

			local props: Props = {
				In = safeProps.In,
				Out = safeProps.Out,
				Anim = safeProps.Anim,
				CloseButton = closeButton,
				Background = background,
				SoundIn = safeProps.SoundIn,
				SoundOut = safeProps.SoundOut,
				OnOpened = safeProps.OnOpened,
				OnClosed = safeProps.OnClosed,
				tweenInfoIn = safeProps.tweenInfoIn,
				tweenInfoOut = safeProps.tweenInfoOut,
			}

			FrameLink.link(button, frame, props)
		else
			warn("FrameLink: Invalid button or frame setup for: ", button.Name)
		end
	end
end

return FrameLink

-- FrameLink - UI Animation & State Management Framework
-- Copyright (C) 2026 karlobii (GITHUB)
-- This program is free software: you can redistribute it under the terms of the GNU General Public License v3.0.
-- See <https://www.gnu.org/licenses/> for details.--]]


local TweenService = game:GetService("TweenService")
local Animations = require(script.Animations)

local frameLink = {}
frameLink.__index = frameLink
export type frameLink = typeof(frameLink) & {
	props: props?,
	tweens: { In: Tween?, Out: Tween? },
	open: boolean,
	isAnimating: boolean,
	defaultSize: UDim2,
	defaultPosition: UDim2,
	defaultRotation: number,
	startState: { [string]: any },
	frame: Frame,
	connections: { RBXScriptConnection }
}

export type props = {
	In: string?, 
	Out: string?,
	Anim: string?,
	CloseButton: GuiButton?,
	Background: GuiButton?,
	SoundIn: Sound?,
	SoundOut: Sound?, 
	OnOpened: (() -> ())?,
	OnClosed: (() -> ())?,
	tweenInfoIn: TweenInfo?,
	tweenInfoOut: TweenInfo?
}

export type multiProps = {
	In: string?, 
	Out: string?,
	Anim: string?,
	CloseButtonName: string?, 
	BackgroundName: string?,
	SoundIn: Sound?,
	SoundOut: Sound?,
	OnOpened: (() -> ())?,
	OnClosed: (() -> ())?,
	tweenInfoIn: TweenInfo?,
	tweenInfoOut: TweenInfo?,
}

local currentFrame : frameLink? = nil

function frameLink._playOpen(self: frameLink)
	self.open = true

	for property, value in self.startState do
		(self.frame :: any)[property] = value
	end

	self.frame.Visible = true

	if self.props and self.props.SoundIn then
		self.props.SoundIn:Play()
	end

	if self.props and self.props.Background then
		self.props.Background.Visible = true
	end

	if self.tweens.In then
		self.isAnimating = true
		self.tweens.In:Play()
		self.tweens.In.Completed:Once(function()
			self.isAnimating = false
			if self.props and self.props.OnOpened then
				self.props.OnOpened()
			end
		end)
	else
		self.isAnimating = false
		if self.props and self.props.OnOpened then
			self.props.OnOpened()
		end
	end
end

function frameLink.setOpen(self: frameLink)
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

function frameLink.setClosed(self: frameLink)
	if self.open == false or self.isAnimating then return end

	if currentFrame == self then
		currentFrame = nil
	end	

	self.open = false

	if self.props and self.props.SoundOut then
		self.props.SoundOut:Play()
	end

	if self.props and self.props.Background then
		self.props.Background.Visible = false
	end

	if self.tweens.Out then
		self.isAnimating = true
		self.tweens.Out:Play()
		self.tweens.Out.Completed:Once(function()
			self.frame.Visible = false
			self.isAnimating = false
			if self.props and self.props.OnClosed then
				self.props.OnClosed()
			end
		end)
	else
		self.frame.Visible = false
		self.isAnimating = false
		if self.props and self.props.OnClosed then
			self.props.OnClosed()
		end
	end
end

function frameLink.toggle(self: frameLink)
	if self.open == true then
		self:setClosed()
	else
		self:setOpen()
	end
end

function frameLink.check(self: frameLink, button:GuiButton): boolean
	if not button or not self.frame then return false end
	if not button:IsA("GuiButton") then return false end
	if not self.frame:IsA("Frame") then return false end
	return true
end

function frameLink.createTweens(self: frameLink) : ()
	self.tweens = {}
		
	self.startState = {
		Size = self.defaultSize,
		Position = self.defaultPosition,
		Rotation = self.defaultRotation
	}
	
	local props = self.props or {}
	local defaults = table.clone(self.startState)
	local inAnimName = props.Anim or props.In
	local outAnimName = props.Anim or props.Out

	local inGoals, outGoals = {}, {}
	local inInfo, outInfo = nil, nil

	if inAnimName and Animations[inAnimName] then
		local animDef = Animations[inAnimName]
		inInfo = props.tweenInfoIn or animDef.InfoIn
		inGoals = animDef.InGoals(defaults)

		for prop, val in animDef.StartState(defaults) do
			self.startState[prop] = val
		end
	elseif inAnimName then
		warn("FrameLink: Unknown IN animation '" .. inAnimName .. "'")
	end

	if outAnimName and Animations[outAnimName] then
		local animDef = Animations[outAnimName]
		outInfo = props.tweenInfoOut or animDef.InfoOut
		outGoals = animDef.OutGoals(defaults)
	elseif outAnimName then
		warn("FrameLink: Unknown OUT animation '" .. outAnimName .. "'")
	end

	if next(inGoals) ~= nil and inInfo then
		self.tweens.In = TweenService:Create(self.frame, inInfo, inGoals)
	end

	if next(outGoals) ~= nil and outInfo then
		self.tweens.Out = TweenService:Create(self.frame, outInfo, outGoals)
	end
end

function frameLink.init(self: frameLink, button: GuiButton)
	button.MouseButton1Click:Connect(function()
		self:toggle()
	end)

	if self.props.CloseButton then
		self.props.CloseButton.MouseButton1Click:Connect(function()
			self:setClosed()
		end)
	end

	if self.props.Background then
		self.props.Background.MouseButton1Click:Connect(function()
			self:setClosed()
		end)
	end
end

function frameLink.link(button: GuiButton, frame: Frame, props: props) : frameLink
	local self = setmetatable({
		open = false,
		isAnimating = false,
		defaultSize = frame.Size,
		defaultPosition = frame.Position,
		defaultRotation = frame.Rotation,
		startState = {},
		tweens = {},
		frame = frame,
		props = props,
		connections = {},
	}, frameLink) :: frameLink
	
	if self.props == nil then self.props = {} end 
	
	if self:check(button) then
		self:createTweens() 

		for property, value in (self.startState) do
			(self.frame :: any)[property] = value
		end
		self.frame.Visible = false
		if self.props.Background then self.props.Background.Visible = false end

		self:init(button) 
	end

	return self
end

function frameLink.multiLink(buttonFolder: Folder, frameFolder: Folder, multiProps: multiProps)
	for _,button in buttonFolder:GetChildren() do
		local frame = frameFolder:FindFirstChild(button.Name)
		if frame and button:IsA("GuiButton") and frame:IsA("Frame") then

			if multiProps == nil then multiProps = {} end

			local CloseButton = nil
			if multiProps.CloseButtonName then
				local foundX = frame:FindFirstChild(multiProps.CloseButtonName)
				if foundX and foundX:IsA("GuiButton") then
					CloseButton = foundX
				end
			end

			local Background = nil
			if multiProps.BackgroundName then
				local foundBg = frame.Parent:FindFirstChild(multiProps.BackgroundName)
				if foundBg and foundBg:IsA("GuiButton") then
					Background = foundBg
				end
			end

			local props : props = {
				In = multiProps.In,
				Out = multiProps.Out,
				Anim = multiProps.Anim,
				CloseButton = CloseButton,
				Background = Background,
				SoundIn = multiProps.SoundIn,
				SoundOut = multiProps.SoundOut,
				OnOpened = multiProps.OnOpened,
				OnClosed = multiProps.OnClosed,
				tweenInfoIn = multiProps.tweenInfoIn,
				tweenInfoOut = multiProps.tweenInfoOut,
			}

			frameLink.link(button, frame, props)
		else
			warn("Invalid button or frame setup for: ", button.Name)
		end
	end
end

return frameLink
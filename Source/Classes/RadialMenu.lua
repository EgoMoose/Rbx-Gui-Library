--[[
Classes.RadialMenu

This class creates a radial menu. It is by far the most "raw" module in this library as so much of how you interact with it is developer defined.

Constructors:
	new(subN [integer], tPercent [float], rotation [float])
		> Creates a radial menu divided into subN sections where the ring is tPercent width of the frame radius
		> and the ring is rotationally offset by rotation radians

Properties:
	Frame [instance]
		> The container frame for the radial menu. Can be used for positioning and resizing.
		> Note that this frame should always be square, by default it's set to YY size constraining
	Rotation [float]
 		> The rotation offset that the developer entered as an argument when creating the radial menu.
	SubN [integer]
		> The number of subsections that the developer entered as an argument when creating the radial menu.
	Enabled [boolean]
		> Whether or not the radial menu is actively tracking input.
		> Defaults to true
	DeadZoneIn [float]
		> Number represents a percentage from the radius that will be ignored in regards to input
		> By default this is 0.5 meaning the center 50% of the radial frame ignores input
	DeadZoneOut [float]
		> Number represents a percentage from the radius that once passed will be ignored in regards to input.
		> By default this is math.huge meaning that as long as your outside of DeadZoneIn your input will not be ignored.

Methods:
	:SetRadialProps(props [dictionary]) [void]
		> Sets the properties of all the radial background UI
	:SetDialProps(props [dictionary]) [void]
		> Sets the properties of the radial dial UI
	:GetTheta(userInputType [Enum.UserInputType]) [float]
		> Depending on if MouseMovement, Touch, or a Gamepad returns the directional angle that the user is inputting on their device
		> If input is not in deadzone range then this method returns nil
		> Returns the angle in radians
	:PickIndex(theta) [integer]
		> Given a directional angle returns the closest element on the radial wheel as an index.
	:GetRadial(index) [instance]
		> Returns the radial background UI for that index.
	:GetAttachment(index) [instance]
		> Returns the radial attachment UI for that index.
		> This frame is useful for putting text or images in.
	:IsVisible() [boolean]
		> Returns whether or not the radial menu is visible to the user or not.
	:Destroy() [void]
		> Destroys the RadioButtonGroup and all the events, etc that were running it.

Events:
	.Clicked:Connect(function(index [integer])
		> Fired when the user selects an element on the radial menu.
	.Hover:Connect(function(oldIndex [integer], newIndex [integer])
		> Fired when the user hovers in the direction of a new element on the radial menu
--]]


-- CONSTANTS

local GuiLib = script.Parent.Parent
local Lazy = require(GuiLib:WaitForChild("LazyLoader"))
local Defaults = GuiLib:WaitForChild("Defaults")

local UIS = game:GetService("UserInputService")
local RUNSERVICE = game:GetService("RunService")
local CONSTANTS = Lazy.Classes.Children.RadialMenu.CONSTANTS

local PI = math.pi
local TAU = CONSTANTS.TAU
local EX_OFFSET = CONSTANTS.EX_OFFSET

local GAMEPAD_CLICK = {
	[Enum.KeyCode.ButtonA] = true
}

local MOUSE_GROUP = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.MouseMovement] = true,
	[Enum.UserInputType.Touch] = true
}

local GAMEPAD_GROUP = {
	[Enum.UserInputType.Gamepad1] = true,
	[Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true,
	[Enum.UserInputType.Gamepad4] = true,
	[Enum.UserInputType.Gamepad5] = true,
	[Enum.UserInputType.Gamepad6] = true,
	[Enum.UserInputType.Gamepad7] = true,
	[Enum.UserInputType.Gamepad8] = true
}

local CreateRadial = Lazy.Classes.Children.RadialMenu.CreateRadial

-- Class

local RadialMenuClass = {}
RadialMenuClass.__index = RadialMenuClass
RadialMenuClass.__type = "RadialMenu"

function RadialMenuClass:__tostring()
	return RadialMenuClass.__type
end

-- Public Constructors

function RadialMenuClass.new(subN, tPercent, rotation)
	local self = setmetatable({}, RadialMenuClass)
	
	self._Maid = Lazy.Utilities.Maid.new()
	self._ClickedBind = Instance.new("BindableEvent")
	self._HoverBind = Instance.new("BindableEvent")
	self._LastHoverIndex = nil
	
	self.Frame = CreateRadial(subN, tPercent, rotation)
	self.Rotation = rotation
	self.SubN = subN
	
	self.Enabled = true
	self.DeadZoneIn = 0.5
	self.DeadZoneOut = math.huge
	
	self.Clicked = self._ClickedBind.Event
	self.Hover = self._HoverBind.Event
	
	init(self)
	
	self:SetDialProps{ImageColor3 = Color3.new(0, 0, 0)}
	self:SetRadialProps{
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.7
	}
	
	return self
end

-- Private Methods
	
local function shortestDist(start, stop)
	local modDiff = (stop - start) % TAU
	local sDist = PI - math.abs(math.abs(modDiff) - PI)
	if ((modDiff + TAU) % TAU < PI) then
		return sDist
	else
		return -sDist
	end
end

function init(self)
	local subN = self.SubN
	local dial = self.Frame.RadialDial
	
	local inputType = Enum.UserInputType.MouseMovement
	
	self._Maid:Mark(self._ClickedBind)
	self._Maid:Mark(self._HoverBind)
	
	self._Maid:Mark(UIS.LastInputTypeChanged:Connect(function(iType)
		if (MOUSE_GROUP[iType] or GAMEPAD_GROUP[iType]) then
			inputType = iType
		end
	end))
	
	local lTheta = 0
	
	self._Maid:Mark(UIS.InputBegan:Connect(function(input)
		if (not self.Enabled) then
			return
		end
		
		
		if (GAMEPAD_GROUP[input.UserInputType]) then
			if (not GAMEPAD_CLICK[input.KeyCode]) then
				return
			else
				self._ClickedBind:Fire(self:PickIndex(lTheta))
			end
		end
		
		local theta = self:GetTheta(input.UserInputType)
		if (theta) then
			self._ClickedBind:Fire(self:PickIndex(theta))
		end
	end))

	self._Maid:Mark(RUNSERVICE.RenderStepped:Connect(function(dt)
		if (not self.Enabled) then
			return
		end
		
		local theta = self:GetTheta(inputType)
		if (theta and self:IsVisible()) then
			lTheta = theta
			
			local frameRot = math.rad(self.Frame.Rotation)
			local toDeg = math.deg(theta - self.Rotation + frameRot + EX_OFFSET + 2*TAU) % 360
			local closest = toDeg / (360 / self.SubN) + 0.5
			
			dial.Rotation = math.deg(self:GetRotation(closest))
			
			local index = self:PickIndex(theta)
			if (index ~= self._LastHoverIndex) then
				self._HoverBind:Fire(self._LastHoverIndex, index)
				self._LastHoverIndex = index
			end
		end
	end))
end

-- Public Methods

function RadialMenuClass:SetRadialProps(props)
	for _, child in next, self.Frame.Radial:GetChildren() do
		for prop, value in next, props do
			child[prop] = value
		end
	end
end

function RadialMenuClass:SetDialProps(props)
	local dial = self.Frame.RadialDial
	for prop, value in next, props do
		dial[prop] = value
	end
end

function RadialMenuClass:GetTheta(userInputType)
	local delta = nil
	
	if (MOUSE_GROUP[userInputType]) then
		local frame = self.Frame
		local radius = frame.AbsoluteSize.y/2
		local center = frame.AbsolutePosition + frame.AbsoluteSize/2
		local mousePos = UIS:GetMouseLocation() + Vector2.new(0, -36)
		delta = (mousePos - center) / radius
	elseif (GAMEPAD_GROUP[userInputType]) then
		local states = UIS:GetGamepadState(userInputType)
		for _, state in next, states do
			states[state.KeyCode] = state
		end
		delta = states[Enum.KeyCode.Thumbstick2].Position * Vector3.new(1, -1, 1)
	end
	
	if (delta) then
		local m = delta.Magnitude
		if (m >= self.DeadZoneIn and m <= self.DeadZoneOut) then
			return math.atan2(delta.y, -delta.x)
		end
	end
end

function RadialMenuClass:PickIndex(theta)
	local frameRot = math.rad(self.Frame.Rotation)
	local toDeg = math.deg(theta - self.Rotation + frameRot + EX_OFFSET + 2*TAU) % 360
	local closest = math.floor(toDeg / (360 / self.SubN))
	return closest + 1
end

function RadialMenuClass:GetRotation(index)
	return -TAU * ((index - 1) / self.SubN)
end

function RadialMenuClass:GetRadial(index)
	return self.Frame.Radial[index]
end

function RadialMenuClass:GetAttachment(index)
	return self.Frame.Attach[index]
end

function RadialMenuClass:IsVisible()
	local frame = self.Frame
	while (frame and frame:IsA("GuiObject") and frame.Visible) do
		frame = frame.Parent
		if (frame and frame:IsA("ScreenGui") and frame.Enabled) then
			return true
		end
	end
	return false
end

function RadialMenuClass:Destroy()
	self._Maid:Sweep()
	self.Frame:Destroy()
	self.Clicked = nil
	self.Hover = nil
	self.Frame = nil
end

--

return RadialMenuClass
--[[
Classes.Slider

This class creates a slider object which can be dragged for different values.

Constructors:
	new(frame [instance], axis [string])
		> Slider frames must have the following format:
			>> SliderFrame
				>>> Dragger
				>>> Background
		> axis defines if the slider is horizontal "x" or vertical "y"
	Create(axis [string])
		> Creates a slider frame from the default, simply define whether it's horizontal "x" or vertical "y".

Properties:
	Frame [instance]
		> The container frame for the slider. Can be used for positioning and resizing.
	Interval [number] [0, 1]
 		> Set this to force an interval step on the slider. For example if you only wanted steps of 1/10th then you'd write
		> Slider.Interval = 0.1
	IsActive [boolean]
		> When true the slider can be interacted with by the user, when false its values can only be set by the developer.
	TweenClick [boolean]
		> If true then when the user clicks on the slider the dragger will tween to that target. If not it will be instant.
	Inverted [boolean]
		> If true then the value of the slider will be inverted (e.g. when horizontal the right-most position will be zero and left-most 1)
		> This is useful for when you have a vertical slider as typically users envision the down-most position to be zero.

Methods:
	:Get() [number]
		> Returns the slider position from 0 to 1
	:Set(value [number], doTween [boolean]) [void]
		> Sets the slider to a specific position or closest possible if interval > 0. If doTween is true then the slider will tween to that position.
	:Destroy() [void]
		> Destroys the slider frame and all the events, etc that were running it

Events:
	.Changed:Connect(function(value [number])
		> When the slider's position changes this fires the slider's current position
	.Clicked:Connect(function(value [number])
		> When the user clicks somewhere on the slider this fires the clicked position
	.DragStart:Connect(function()
		> Fires when the user starts dragging the slider
	.DragStop:Connect(function()
		> Fires when the user stops dragging the slider
--]]

-- CONSTANTS

local GuiLib = script.Parent.Parent
local Lazy = require(GuiLib:WaitForChild("LazyLoader"))
local Defaults = GuiLib:WaitForChild("Defaults")

local UIS = game:GetService("UserInputService")
local RUNSERVICE = game:GetService("RunService")

local SLIDER_FRAMEX = Defaults:WaitForChild("SliderFrameX")
local SLIDER_FRAMEY = Defaults:WaitForChild("SliderFrameY")

local XBOX_STEP = 0.01
local DEBOUNCE_TICK = 0.1
local XBOX_DEADZONE = 0.35
local THUMBSTICK = Enum.KeyCode.Thumbstick2

-- Class

local SliderClass = {}
SliderClass.__index = SliderClass
SliderClass.__type = "Slider"

function SliderClass:__tostring()
	return SliderClass.__type
end

-- Public Constructors

function SliderClass.new(sliderFrame, axis)
	local self = setmetatable({}, SliderClass)
	
	self._Maid = Lazy.Utilities.Maid.new()
	self._Spring = Lazy.Utilities.Spring.new(1, 0.1, 1, 0)
	self._Axis = axis or "x"
	self._ChangedBind = Instance.new("BindableEvent")
	self._ClickedBind = Instance.new("BindableEvent")
	
	self.Interval = 0
	self.IsActive = true
	self.TweenClick = true
	self.Inverted = false
	
	self.Frame = sliderFrame
	self.Changed = self._ChangedBind.Event
	self.Clicked = self._ClickedBind.Event
	self.DragStart = nil
	self.DragStop = nil
	
	init(self)
	self:Set(0.5)
	
	return self
end

function SliderClass.Create(axis)
	local slider = nil
	
	if (not axis or axis == "x") then
		slider = SliderClass.new(SLIDER_FRAMEX:Clone(), axis)
	else
		slider = SliderClass.new(SLIDER_FRAMEY:Clone(), axis)
		slider.Inverted = true
	end
	
	return slider
end

-- Private Methods

function init(self)
	local frame = self.Frame
	local dragger = frame.Dragger
	local background = frame.Background
	
	local axis = self._Axis
	local maid = self._Maid
	local spring = self._Spring
	local dragTracker = Lazy.Classes.Dragger.new(dragger)
	
	self.DragStart = dragTracker.DragStart
	self.DragStop = dragTracker.DragStop
	
	maid:Mark(frame)
	maid:Mark(self._ChangedBind)
	maid:Mark(self._ClickedBind)
	maid:Mark(function() dragTracker:Destroy() end)
	
	-- Get bounds and background size scaled accordingly for calculations
	local function setUdim2(a, b)
		if (axis == "y") then a, b = b, a end
		return UDim2.new(a, 0, b, 0)
	end
	
	local last = -1
	local bPos, bSize
	local function updateBounds()
		bPos, bSize = getBounds(self)
		background.Size = setUdim2(bSize / frame.AbsoluteSize[axis], 1)
		last = -1
	end
	
	updateBounds()
	maid:Mark(frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateBounds))
	maid:Mark(frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateBounds))
	maid:Mark(frame:GetPropertyChangedSignal("Parent"):Connect(updateBounds))
	
	-- Move the slider when the xbox moves it
	local xboxDir = 0
	local xboxTick = 0
	local xboxSelected = false
	
	maid:Mark(dragger.SelectionGained:Connect(function()
		xboxSelected = true
	end))
	
	maid:Mark(dragger.SelectionLost:Connect(function()
		xboxSelected = false
	end))
	
	maid:Mark(UIS.InputChanged:Connect(function(input, process)
		if (process and input.KeyCode == THUMBSTICK) then
			local pos = input.Position
			xboxDir = math.abs(pos[axis]) > XBOX_DEADZONE and math.sign(pos[axis]) or 0
		end
	end))
	
	-- Move the slider when we drag it
	maid:Mark(dragTracker.DragChanged:Connect(function(element, input, delta)
		if (self.IsActive) then
			self:Set((input.Position[axis] - bPos) / bSize, false)
		end
	end))
	
	-- Move the slider when we click somewhere on the bar
	maid:Mark(frame.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			local t = (input.Position[axis] - bPos) / bSize
			self._ClickedBind:Fire(math.clamp(t, 0, 1))
			if (self.IsActive) then
				self:Set(t, self.TweenClick)
			end
		end
	end))
	
	-- position the slider
	maid:Mark(RUNSERVICE.RenderStepped:Connect(function(dt)
		if (xboxSelected) then
			local t = tick()
			if (self.Interval <= 0) then
				self:Set(self:Get() + xboxDir*XBOX_STEP*dt*60)
			elseif (t - xboxTick > DEBOUNCE_TICK) then
				xboxTick = t
				self:Set(self:Get() + self.Interval*xboxDir)
			end
		end
		
		spring:Update(dt)
		local x = spring.x
		if (x ~= last) then
			local scalePos = (bPos + (x * bSize) - frame.AbsolutePosition[axis]) / frame.AbsoluteSize[axis]
			dragger.Position = setUdim2(scalePos, 0.5)
			self._ChangedBind:Fire(self:Get())
			last = x
		end
	end))
end

function getBounds(self)
	local frame = self.Frame
	local dragger = frame.Dragger
	local axis = self._Axis
	
	local pos = frame.AbsolutePosition[axis] + dragger.AbsoluteSize[axis]/2
	local size = frame.AbsoluteSize[axis] - dragger.AbsoluteSize[axis]
	
	return pos, size
end

-- Public Methods

function SliderClass:Get()
	local t = self._Spring.x
	if (self.Inverted) then t = 1 - t end
	return t
end

function SliderClass:Set(value, doTween)
	local spring = self._Spring
	local newT = math.clamp(value, 0, 1)
	
	if (self.Interval > 0) then
		newT = math.floor((newT / self.Interval) + 0.5) * self.Interval
	end
	
	spring.t = newT
	spring.instant = not doTween
end

function SliderClass:Destroy()
	self._Maid:Sweep()
	self.Frame:Destroy()
	self.Changed = nil
	self.Clicked = nil
	self.StartDrag = nil
	self.StopDrag = nil
	self.Frame = nil
end

--

return SliderClass
-- Meant for internal use, no documentation given

-- CONSTANTS

local GuiLib = script.Parent.Parent
local Lazy = require(GuiLib:WaitForChild("LazyLoader"))

local UIS = game:GetService("UserInputService")
local RUNSERVICE = game:GetService("RunService")

local DEADZONE2 = 0.15^2
local FLIP_THUMB = Vector3.new(1, -1, 1)

local VALID_PRESS = {
	[Enum.UserInputType.MouseButton1] = true;
	[Enum.UserInputType.Touch] = true;
}

local VALID_MOVEMENT = {
	[Enum.UserInputType.MouseMovement] = true;
	[Enum.UserInputType.Touch] = true;
}

-- Class

local DraggerClass = {}
DraggerClass.__index = DraggerClass
DraggerClass.__type = "Dragger"

function DraggerClass:__tostring()
	return DraggerClass.__type
end

-- Public Constructors

function DraggerClass.new(element)
	local self = setmetatable({}, DraggerClass)
	
	self._Maid = Lazy.Utilities.Maid.new()
	self._DragBind = Instance.new("BindableEvent")
	self._StartBind = Instance.new("BindableEvent")
	self._StopBind = Instance.new("BindableEvent")
	
	self.Element = element
	self.IsDragging = false
	self.DragChanged = self._DragBind.Event
	self.DragStart = self._StartBind.Event
	self.DragStop = self._StopBind.Event
	
	init(self)
	
	return self
end

-- Private Methods

function init(self)
	local element = self.Element
	local maid = self._Maid
	local dragBind = self._DragBind
	local lastMousePosition = Vector3.new()
	
	maid:Mark(self._DragBind)
	maid:Mark(self._StartBind)
	maid:Mark(self._StopBind)
	
	maid:Mark(element.InputBegan:Connect(function(input)
		if (VALID_PRESS[input.UserInputType]) then
			lastMousePosition = input.Position
			self.IsDragging = true
			self._StartBind:Fire()
		end
	end))
	
	maid:Mark(UIS.InputEnded:Connect(function(input)
		if (VALID_PRESS[input.UserInputType]) then
			self.IsDragging = false
			self._StopBind:Fire()
		end
	end))
	
	maid:Mark(UIS.InputChanged:Connect(function(input, process)
		if (self.IsDragging) then
			if (VALID_MOVEMENT[input.UserInputType]) then
				local delta = input.Position - lastMousePosition
				lastMousePosition = input.Position
				dragBind:Fire(element, input, delta)
			end
		end
	end))
end

-- Public Methods

function DraggerClass:Destroy()
	self._Maid:Sweep()
	self.DragChanged = nil
	self.DragStart = nil
	self.DragStop = nil
	self.Element = nil
end

--

return DraggerClass
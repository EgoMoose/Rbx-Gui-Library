--[[
Classes.Dropdown

This class creates a dropdown that the user can select a list of options from.

Constructors:
	new(frame [instance], listFrame [instance])
		>
	Create(list[] [string], max [integer])
		> Creates a dropdown from the list with a max scrolling number.

Properties:
	Frame [instance]
		> The container frame for the dropdown. Can be used for positioning and resizing.
	ListFrame [instance]
 		> The contaienr frame for the dropdown list. Parented underneath the main container frame.

Methods:
	:Set(option [instance]) [void]
		> option is a child of the ListFrame and you can set it as the selected option of the dropdown with this method
	:Get() [instance]
		> Returns the selected option frame (which is again, a child of the ListFrame)
	:Show(bool [boolean])
		> Set whether the dropdown list is visible or not.
	:Destroy() [void]
		> Destroys the RadioButtonGroup and all the events, etc that were running it.

Events:
	.Changed:Connect(function(option [instance])
		> Fired when the user selects a new option from the dropdown list.
--]]


-- CONSTANTS

local GuiLib = script.Parent.Parent
local Lazy = require(GuiLib:WaitForChild("LazyLoader"))
local Defaults = GuiLib:WaitForChild("Defaults")

local UIS = game:GetService("UserInputService")

local VALID_PRESS = {
	[Enum.UserInputType.MouseButton1] = true;
	[Enum.UserInputType.Touch] = true;
}

local ARROW_UP = "rbxassetid://5154078925"
local ARROW_DOWN = "rbxassetid://5143165549"

local DROP_BUTTON = Defaults:WaitForChild("DropdownButton")

-- Class

local DropdownClass = {}
DropdownClass.__index = DropdownClass
DropdownClass.__type = "Dropdown"

function DropdownClass:__tostring()
	return DropdownClass.__type
end

-- Public Constructors

function DropdownClass.new(button, listFrame)
	local self = setmetatable({}, DropdownClass)
	
	self._Maid = Lazy.Utilities.Maid.new()
	self._ChangedBind = Instance.new("BindableEvent")
	self._Options = {}
	self._Selected = nil
	
	self.Button = button
	self.ListFrame = listFrame
	self.Changed = self._ChangedBind.Event
	
	init(self)
	self:Set(self._Options[1])
	
	return self
end

function DropdownClass.Create(list, max)
	max = max or #list
	
	local button = DROP_BUTTON:Clone()
	local listFrame = Lazy.Constructors.List.Create(list, max)
	
	listFrame.Position = UDim2.new(0, 0, 1, 0)
	listFrame.Size = UDim2.new(1, 0, max, 0)
	listFrame.Visible = false
	listFrame.Parent = button
	
	return DropdownClass.new(button, listFrame)
end

-- Private Methods

function init(self)
	local button = self.Button
	local listFrame = self.ListFrame
	
	local function contentSizeUpdate()
		local absSize = button.AbsoluteSize
		local ratio = absSize.y / absSize.x
		
		button.Arrow.Size = UDim2.new(ratio, 0, 1, 0)
		button.Option.Size = UDim2.new(1 - ratio, -12, 1, 0)
	end
	
	contentSizeUpdate()
	self._Maid:Mark(button:GetPropertyChangedSignal("AbsoluteSize"):Connect(contentSizeUpdate))
	
	for i, optionButton in next, listFrame.ScrollFrame:GetChildren() do
		self._Options[i] = optionButton
		optionButton.Activated:Connect(function()
			self:Set(optionButton)
		end)
	end

	self._Maid:Mark(button.Activated:Connect(function()
		self:Show(not listFrame.Visible)
	end))
	
	self._Maid:Mark(UIS.InputBegan:Connect(function(input)
		if (VALID_PRESS[input.UserInputType]) then
			local p = input.Position
			local p2 = Vector2.new(p.x, p.y)
			
			if (listFrame.Visible and not (isInFrame(listFrame, p2) or isInFrame(button, p2))) then
				self:Show(false)
			end
		end
	end))
end

function isInFrame(frame, pos)
	local fPos = frame.AbsolutePosition
	local fSize = frame.AbsoluteSize
	local d = pos - fPos
	return (d.x >= 0 and d.x <= fSize.x and d.y >= 0 and d.y <= fSize.y)
end

-- Public Methods

function DropdownClass:Set(option)
	if (self._Selected ~= option) then
		self._Selected = option
		self._ChangedBind:Fire(option)
		self.Button.Option.Text = option.Label.Text
	end
	self:Show(false)
end

function DropdownClass:Get()
	return self._Selected
end

function DropdownClass:Show(bool)
	self.Button.Arrow.Image = bool and ARROW_UP or ARROW_DOWN
	self.ListFrame.Visible = bool
end

function DropdownClass:Destroy()
	self._Maid:Sweep()
	self._Changed = nil
	self._Options = nil
	self._Selected = nil
	self.Button:Destroy()
end

--

return DropdownClass
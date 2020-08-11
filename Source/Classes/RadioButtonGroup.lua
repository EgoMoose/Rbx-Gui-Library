--[[
Classes.RadioButtonGroup

This class creates a list of radio buttons that the user can select from.

Constructors:
	new(frame [instance], buttons[] [RadioButtonLabel])
	Create(list[] [string], max [integer])
		> Creates a RadioButtonGroup from the list with a max scrolling number.

Properties:
	Frame [instance]
		> The container frame for the RadioButtonGroup. Can be used for positioning and resizing.
	RadioButtons[] [RadioButtonLabel]
 		> An array of the RadioButtonLabels that are used in the RadioButtonGroup.

Methods:
	:GetActiveRadio() [RadioButtonLabel]
		> Returns the currently selected RadioButtonLabel
	:Destroy() [void]
		> Destroys the RadioButtonGroup and all the events, etc that were running it.

Events:
	.Changed:Connect(function(old [RadioButtonLabel], new [RadioButtonLabel])
		> When the selected radio button is changed in the radio button group this event fires
--]]

-- CONSTANTS

local GuiLib = script.Parent.Parent
local Lazy = require(GuiLib:WaitForChild("LazyLoader"))

-- Class

local RadioButtonGroupClass = {}
RadioButtonGroupClass.__index = RadioButtonGroupClass
RadioButtonGroupClass.__type = "RadioButtonLabel"

function RadioButtonGroupClass:__tostring()
	return RadioButtonGroupClass.__type
end

-- Public Constructors

function RadioButtonGroupClass.new(frame, radioButtons)
	local self = setmetatable({}, RadioButtonGroupClass)
	
	self._Maid = Lazy.Utilities.Maid.new()
	self._ChangedBind = Instance.new("BindableEvent")
	self._ActiveRadio = radioButtons[1]
	
	self.Frame = frame
	self.RadioButtons = radioButtons
	self.Changed = self._ChangedBind.Event
	
	init(self)
	
	return self
end

function RadioButtonGroupClass.Create(list, max)
	local radios = {}
	
	local function instanceFunc(index, option)
		local radio = Lazy.Classes.RadioButtonLabel.Create(option)
		radio.Frame.LayoutOrder = index
		radios[index] = radio
		return radio.Frame
	end
	
	local frame = Lazy.Constructors.List.Create(list, max or #list, Enum.FillDirection.Vertical, UDim.new(0, 5), instanceFunc)
	
	return RadioButtonGroupClass.new(frame, radios)
end

-- Private Methods

function init(self)
	for _, radio in next, self.RadioButtons do
		radio:SetValue(false)
		self._Maid:Mark(radio.Button.Activated:Connect(function()
			local old = self._ActiveRadio
			
			self._ActiveRadio:SetValue(false)
			self._ActiveRadio = radio
			self._ActiveRadio:SetValue(true)
			
			self._ChangedBind:Fire(old, radio)
		end))
	end
	
	self._ActiveRadio:SetValue(true)
end

-- Public Methods

function RadioButtonGroupClass:GetActiveRadio()
	return self._ActiveRadio
end

function RadioButtonGroupClass:Destroy()
	self._Maid:Sweep()
	self.Frame:Destroy()
end

--

return RadioButtonGroupClass
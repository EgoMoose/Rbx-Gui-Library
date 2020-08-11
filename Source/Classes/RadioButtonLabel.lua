--[[
Classes.RadioButtonLabel

This class creates a single radio button label.

Constructors:
	new(frame [instance])
		>
	Create(text)
		> Creates a RadioButtonLabel from the text provided.

Properties:
	Frame [instance]
		> The container frame for the RadioButtonLabel. Can be used for positioning and resizing.
	Button [instance]
 		> The button used to track when the user clicks on the radio button or not

Methods:
	:GetValue() [boolean]
		> Returns whether the button is selected or not.
	:SetValue(bool [boolean]) [void]
		> Sets if the button is selected or not
	:Destroy() [void]
		> Destroys the RadioButtonLabel and all the events, etc that were running it.
--]]

-- CONSTANTS

local GuiLib = script.Parent.Parent
local Lazy = require(GuiLib:WaitForChild("LazyLoader"))
local Defaults = GuiLib:WaitForChild("Defaults")

local RADIOBUTTON_LABEL = Defaults:WaitForChild("RadioButtonLabel")

-- Class

local RadioButtonLabelClass = {}
RadioButtonLabelClass.__index = RadioButtonLabelClass
RadioButtonLabelClass.__type = "RadioButtonLabel"

function RadioButtonLabelClass:__tostring()
	return RadioButtonLabelClass.__type
end

-- Public Constructors

function RadioButtonLabelClass.new(frame)
	local self = setmetatable({}, RadioButtonLabelClass)
	
	self._Maid = Lazy.Utilities.Maid.new()
	
	self.Frame = frame
	self.Button = frame.RadioContainer.RadioButton
	
	init(self)
	self:SetValue(false)
	
	return self
end

function RadioButtonLabelClass.Create(text)
	local cbLabel = RADIOBUTTON_LABEL:Clone()
	cbLabel.Label.Text = text
	return RadioButtonLabelClass.new(cbLabel)
end

-- Private Methods

function init(self)
	local label = self.Frame.Label
	local container = self.Frame.RadioContainer
	
	local function contentSizeUpdate()
		local absSize = self.Frame.AbsoluteSize
		local ratio = absSize.y / absSize.x
		container.Size = UDim2.new(ratio, 0, 1, 0)
		label.Size = UDim2.new(1 - ratio, -10, 1, 0)
		label.Position = UDim2.new(ratio, 10, 0, 0)
	end
	
	contentSizeUpdate()
	self._Maid:Mark(self.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(contentSizeUpdate))
end

-- Public Methods

function RadioButtonLabelClass:GetValue()
	return self.Button.Circle.Visible
end

function RadioButtonLabelClass:SetValue(bool)
	bool = not not bool
	
	local container = self.Frame.RadioContainer
	local colorA = container.BorderColor3
	local colorB = container.BackgroundColor3
	
	container.Outline.ImageColor3 = bool and colorA or colorB
	container.RadioButton.Circle.Visible = bool
end

function RadioButtonLabelClass:Destroy()
	self._Maid:Sweep()
	self.Frame:Destroy()
end

--

return RadioButtonLabelClass
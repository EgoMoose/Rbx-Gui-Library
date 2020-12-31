--[[
Classes.CheckboxLabel

This class creates a single checkbox label

Constructors:
	new(frame [instance])
		>
	Create(text)
		> Creates a CheckboxLabel from the text provided.

Properties:
	Frame [instance]
		> The container frame for the CheckboxLabel. Can be used for positioning and resizing.
	Button [instance]
 		> The button used to track when the user clicks on the checkbox button or not

Methods:
	:GetValue() [boolean]
		> Returns whether the checkbox is selected or not.
	:SetValue(bool [boolean]) [void]
		> Sets if the checkbox is selected or not.
	:Destroy() [void]
		> Destroys the RadioButtonLabel and all the events, etc that were running it.

Events:
	.Changed:Connect(function(bool [boolean])
		> Fired when the user clicks the checkbox.
--]]


-- CONSTANTS

local GuiLib = script.Parent.Parent
local Lazy = require(GuiLib:WaitForChild("LazyLoader"))
local Defaults = GuiLib:WaitForChild("Defaults")

local CHECKBOX_LABEL = Defaults:WaitForChild("CheckboxLabel")

-- Class

local CheckboxLabelClass = {}
CheckboxLabelClass.__index = CheckboxLabelClass
CheckboxLabelClass.__type = "CheckboxLabel"

function CheckboxLabelClass:__tostring()
	return CheckboxLabelClass.__type
end

-- Public Constructors

function CheckboxLabelClass.new(frame)
	local self = setmetatable({}, CheckboxLabelClass)
	
	self._Maid = Lazy.Utilities.Maid.new()
	self._ChangedBind = Instance.new("BindableEvent")
	
	self.Frame = frame
	self.Button = frame.CheckContainer.CheckButton
	self.Changed = self._ChangedBind.Event
	
	init(self)
	self:SetValue(false)
	
	return self
end

function CheckboxLabelClass.Create(text)
	local cbLabel = CHECKBOX_LABEL:Clone()
	cbLabel.Label.Text = text
	return CheckboxLabelClass.new(cbLabel)
end

-- Private Methods

function init(self)
	local label = self.Frame.Label
	local container = self.Frame.CheckContainer
	local checkmark = self.Button.Checkmark
	
	local function contentSizeUpdate()
		local absSize = self.Frame.AbsoluteSize
		local ratio = absSize.y / absSize.x
		container.Size = UDim2.new(ratio, 0, 1, 0)
		label.Size = UDim2.new(1 - ratio, -10, 1, 0)
		label.Position = UDim2.new(ratio, 10, 0, 0)
	end
	
	contentSizeUpdate()
	self._Maid:Mark(self.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(contentSizeUpdate))
	
	self._Maid:Mark(self.Button.Activated:Connect(function()
		self:SetValue(not checkmark.Visible)
	end))
end

-- Public Methods

function CheckboxLabelClass:GetValue()
	return self.Button.Checkmark.Visible
end

function CheckboxLabelClass:SetValue(bool)
	bool = not not bool
	
	local container = self.Frame.CheckContainer
	local colorA = container.BackgroundColor3
	local colorB = container.BorderColor3
	local colorC = container.Outline.BackgroundColor3
	
	local outlineColor = bool and colorB or colorC
	if (bool and container.CheckButton.BackgroundTransparency == 1) then
		outlineColor = colorC
	end
	
	for _, child in next, container.Outline:GetChildren() do
		child.BackgroundColor3 = outlineColor
	end
	
	container.CheckButton.BackgroundColor3 = bool and colorB or colorA
	container.CheckButton.Checkmark.Visible = bool
	
	self._ChangedBind:Fire(bool)
end

function CheckboxLabelClass:Destroy()
	self._Maid:Sweep()
	self.Frame:Destroy()
	self.Changed = nil
end

--

return CheckboxLabelClass
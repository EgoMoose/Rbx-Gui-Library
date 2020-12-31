--[[
Classes.TextMask

This class creates a text mask object which can be used to limit user input into a text gui element

Constructors:
	new(textFrame [instance])
		> Creates a text mask object for the given text frame.

Properties:
	Frame [instance]
		> The text frame that you put as an argument when creating the text mask object.

Methods:
	:GetValue() [variant]
		> Returns the text frame's value converted to the mask type.
		> For instance if you used a vector3 mask then this would return the value inputted as a vector3
	:GetMaskType() [string]
		> Returns the name of the mask type you are using
	:SetMaxLength(len [integer]) [void]
		> Sets the maximum number of characters the user can input into the text field
		> By default the max length is 230,000 characters
	:SetMaskType(name [string]) [void]
		> Sets mask type of the mask object. This name should coincide with a child of this module
		> By default the mask type is always set to "String"
	:Destroy() [void]
		> Destroys the mask object and any events, etc used in the purpose of running it.

--]]

-- CONSTANTS

local GuiLib = script.Parent.Parent
local Lazy = require(GuiLib:WaitForChild("LazyLoader"))
local Defaults = GuiLib:WaitForChild("Defaults")

local INCREMENT_BUTTON = Defaults:WaitForChild("IncrementButton")
local DECREMENT_BUTTON = Defaults:WaitForChild("DecrementButton")

local WARN_MSG = "%s is not a valid mask. Defaulting to 'String' mask."

local MASKS = {}
for _, module in pairs(script:GetChildren()) do
	MASKS[module.Name] = require(module)
end

-- Class

local TextMaskClass = {}
TextMaskClass.__index = TextMaskClass
TextMaskClass.__type = "TextMask"

function TextMaskClass:__tostring()
	return TextMaskClass.__type
end

-- Public Constructors

function TextMaskClass.new(textFrame)
	local self = setmetatable({}, TextMaskClass)
	
	self._Maid = Lazy.Utilities.Maid.new()
	self._MaskType = MASKS.String
	self._MaxLength = 230000
	
	self.Frame = textFrame
	
	init(self)
	
	return self
end

-- Private Methods

function init(self)
	local frame = self.Frame
	local maid = self._Maid

	maid:Mark(frame:GetPropertyChangedSignal("Text"):Connect(function()
		local mask = self._MaskType
		local result = mask:Process(frame.Text):sub(1, self._MaxLength)
		frame.Text = result
	end))
	
	maid:Mark(frame.FocusLost:Connect(function()
		local mask = self._MaskType
		if (not mask:Verify(frame.Text)) then
			frame.Text = mask.Default
		end
	end))
end

-- Public Methods

function TextMaskClass:GetValue()
	return self._MaskType:ToType(self.Frame.Text)
end

function TextMaskClass:GetMaskType()
	return self._MaskType.Name
end

function TextMaskClass:SetMaxLength(len)
	self._MaxLength = len
end

function TextMaskClass:SetMaskType(name)
	local mask = MASKS[name]
	if (not mask) then
		mask = MASKS.String
		warn(WARN_MSG:format(name))
	end
	self._MaskType = mask
	self.Frame.Text = mask:Process(self.Frame.Text):sub(1, self._MaxLength)
	
	-- Add increment/decrement buttons for numeric inputs
	if name == "Number" then
		-- Initialize text to 0, consumer can override
		self.Frame.Text = 0

		self.IncrementButton = INCREMENT_BUTTON:Clone()
		self.IncrementButton.AnchorPoint = Vector2.new(1, 0)
		self.IncrementButton.Position = UDim2.new(1, 0, 0, 0)
		self._Maid:Mark(self.IncrementButton.Activated:Connect(function()
			self.Frame.Text = tonumber(self.Frame.Text) + 1
		end))
		self.IncrementButton.Parent = self.Frame
		self._Maid:Mark(self.IncrementButton)
		
		self.DecrementButton = DECREMENT_BUTTON:Clone()
		self.DecrementButton.AnchorPoint = Vector2.new(1, 1)
		self.DecrementButton.Position = UDim2.new(1, 0, 1, 0)
		self._Maid:Mark(self.DecrementButton.Activated:Connect(function()
			self.Frame.Text = tonumber(self.Frame.Text) - 1
		end))
		self.DecrementButton.Parent = self.Frame
		self._Maid:Mark(self.DecrementButton)
	end
end

function TextMaskClass:Destroy()
	self._Maid:Sweep()
end

--

return TextMaskClass

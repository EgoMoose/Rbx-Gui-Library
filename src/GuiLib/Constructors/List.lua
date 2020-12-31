--[[
Constructors.List

This module provides a set of functions useful for generating lists that can be scrolled through.

This module only has one function:

List.Create(
	string[] list, -- an array of strings used to generate instances for the list
	integer scrollMax, -- the maximum number of elements visible in the scroll frame at any given time. Defaults to math.huge
	enum fillDirection, -- Enum.FillDirection lets you decide if the list is vertical or horizontal. Defaults to verical
	udim padding, -- scale and offset for padding between instances. Defaults to no padding
	function instanceFunc -- must return a UI object such as a frame. Defaults to creating a textbutton with a child textlabel
)

--]]

-- CONSTANTS

local GuiLib = script.Parent.Parent
local Lazy = require(GuiLib:WaitForChild("LazyLoader"))
local Defaults = GuiLib:WaitForChild("Defaults")

local LIST_BUTTON = Defaults:WaitForChild("ListButton")

local DEFAULT_LAYOUT = {
	SortOrder = Enum.SortOrder.LayoutOrder
}

-- Private Functions

local function defaultButton(index, option)
	local button = LIST_BUTTON:Clone()
	button.Name = option .. "_button"
	button.Label.Text = option
	return button
end

-- Library

local List = {}

function List.Create(list, max, fillDirection, padding, instanceFunc)
	max = max or math.huge
	padding = padding or UDim.new(0, 0)
	fillDirection = fillDirection or Enum.FillDirection.Vertical
	instanceFunc = instanceFunc or defaultButton

	local nList = #list
	local dList = 1 / nList
	
	local isVertical = (fillDirection == Enum.FillDirection.Vertical)
	
	local listFrame = Instance.new("Frame")
	listFrame.Name = "ListFrame"
	listFrame.BorderSizePixel = 0 
	
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollFrame"
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	
	local canvasSize = nil	
	local elementSize = nil
	local extraPosition = nil
	
	local adj = (nList - 1) / nList
	local scale = padding.Scale * adj
	local offset = padding.Offset * adj
	
	if (isVertical) then
		canvasSize = UDim2.new(0, 0, nList / max, 0) 
		elementSize = UDim2.new(1, 0, dList - scale, -offset)
	else
		canvasSize = UDim2.new(nList / max , 0, 0, 0)
		elementSize = UDim2.new(dList - scale, -offset, 1, 0)
	end
	
	scrollFrame.CanvasSize = canvasSize
	
	local items = {}
	for i, option in ipairs(list) do
		local item = instanceFunc(i, option)
		item.LayoutOrder = i
		item.Size = elementSize
		item.Position = UDim2.new(0, 0, (i-1)*dList, 0)
		
		if (isVertical) then
			item.Position = item.Position + UDim2.new(0, 0, padding.Scale/nList*(i-1), padding.Offset/nList*(i-1))
		else
			item.Position = item.Position + UDim2.new(padding.Scale/nList*(i-1), padding.Offset/nList*(i-1), 0, 0)
		end
		
		items[i] = item
		item.Parent = scrollFrame
	end
	
	listFrame.BackgroundTransparency = items[1].BackgroundTransparency
	listFrame.BackgroundColor3 = items[1].BackgroundColor3
	scrollFrame.Parent = listFrame
	
	return listFrame	
end

--

return List
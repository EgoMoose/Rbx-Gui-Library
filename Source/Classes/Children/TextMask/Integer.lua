local NumberMask = require(script.Parent:WaitForChild("Number"))

local Mask = {}

Mask.Name = "Integer"
Mask.Default = "0"

function Mask:Process(text)
	local new = NumberMask:Process(text)
	local find = new:find("%.") or #new + 1

	return new:sub(1, find - 1)
end

function Mask:Verify(text)
	local valid = NumberMask:Verify(text)
	return (valid and not text:find("%."))
end

function Mask:ToType(text)
	text = self:Verify(text) and text or self.Default
	return tonumber(text)
end

return Mask
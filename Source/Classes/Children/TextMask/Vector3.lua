local NumberMask = require(script.Parent:WaitForChild("Number"))

local function matchArray(str, pattern)
	local arr = {}
	for sub in string.gmatch(str, pattern) do
		arr[#arr + 1] = sub
	end
	return arr
end

local Mask = {}

Mask.Name = "Vector3"
Mask.Default = "0, 0, 0"

function Mask:Process(text)
	return text
end

function Mask:Verify(text)
	local find = text:find("[^%d., -]") -- find any non number, decimal, comma, space or negative
	if (not find) then
		local nCommas = #string.split(text, ",")
		if (nCommas == 3) then
			local nums = matchArray(text, "%-*%d[%d.]*")
			if (#nums == 3) then
				for i, num in next, nums do
					if (not NumberMask:Verify(num)) then
						return false
					end
				end
				return true
			end
		end
	end
	return false
end

function Mask:ToType(text)
	text = self:Verify(text) and text or self.Default
	
	local components = string.split(text, ", ")
	for i, c in next, components do
		components[i] = tonumber(c)
	end
	
	return Vector3.new(unpack(components))
end

return Mask
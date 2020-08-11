local Mask = {}

Mask.Name = "Number"
Mask.Default = "0"

function Mask:Process(text)
	local new = text:gsub("[^%d.-]", "")
	
	local neg = new:sub(1, 1)
	new = neg .. new:sub(2):gsub("%-", "")
	
	local found = new:find("%.")
	if (found) then
		local a = new:sub(1, found)
		local b = new:sub(found + 1, #new):gsub("[%.]", "")
		return a .. b
	end
	
	return new
end

function Mask:Verify(text)
	local find = text:find("[^%d.-]") -- find any non number, decimal, negative
	if (not find) then
		if (text:sub(1, 1) == "-") then
			find = text:sub(2):find("%-")
			if (find or #text == 1) then
				return false
			end
		end
		
		find = text:find("%.")
		if (find) then
			local new = text:sub(find + 1, #text):find("%.") -- check for second decimal
			return not new
		end
		
		return true
	end
	return false
end

function Mask:ToType(text)
	text = self:Verify(text) and text or self.Default
	return tonumber(text)
end

return Mask
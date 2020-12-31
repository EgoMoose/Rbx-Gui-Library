local GuiLib = script.Parent
local FORMAT_STR = "\"%s\" is not an existing class/folder."

local VALID = {
	["Folder"] = true;
	["ModuleScript"] = true;
}

local function getLoaderOf(child)
	local Library = {}
	local Meta = {}
	
	function Meta:__index(key)
		if (Library[key]) then
			return Library[key]
		end
		
		local object = child:FindFirstChild(key)
		if (object and object ~= script and VALID[object.ClassName]) then
			Library[key] = object:IsA("ModuleScript") and require(object) or getLoaderOf(object)
			return Library[key]
		end
		
		error(FORMAT_STR:format(key), 2)
	end
	
	return setmetatable({}, Meta)
end

return getLoaderOf(GuiLib)
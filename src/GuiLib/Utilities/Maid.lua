-- CONSTANTS

local FORMAT_STR = "Maid does not support type \"%s\""

local DESTRUCTORS = {
	["function"] = function(item)
		item()
	end;
	["RBXScriptConnection"] = function(item)
		item:Disconnect()
	end;
	["Instance"] = function(item)
		item:Destroy()
	end;
}

-- Class

local MaidClass = {}
MaidClass.__index = MaidClass
MaidClass.__type = "Maid"

function MaidClass:__tostring()
	return MaidClass.__type
end

-- Public Constructors

function MaidClass.new()
	local self = setmetatable({}, MaidClass)
	
	self.Trash = {}
	
	return self
end

-- Public Methods

function MaidClass:Mark(item)
	local tof = typeof(item)
	
	if (DESTRUCTORS[tof]) then
		self.Trash[item] = tof
	else
		error(FORMAT_STR:format(tof), 2)
	end
end

function MaidClass:Unmark(item)
	if (item) then
		self.Trash[item] = nil
	else
		self.Trash = {}
	end
end

function MaidClass:Sweep()
	for item, tof in next, self.Trash do
		DESTRUCTORS[tof](item)
	end
	self.Trash = {}
end

--

return MaidClass
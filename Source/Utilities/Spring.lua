-- CONSTANTS

-- Private Functions

local function getAbsDist(a, b)
	local d = b - a
	if (type(d) == "number") then
		return math.abs(d)
	end
	return d.Magnitude
end

-- Class

local SpringClass = {}
SpringClass.__index = SpringClass
SpringClass.__type = "Spring"

function SpringClass:__tostring()
	return SpringClass.__type
end

-- Public Constructors

function SpringClass.new(stiffness, dampingCoeff, dampingRatio, initialPos)
	local self = setmetatable({}, SpringClass)
	
	self.instant = false
	self.marginOfError = 1E-6

	dampingRatio = dampingRatio or 1
	local m = dampingCoeff*dampingCoeff/(4*stiffness*dampingRatio*dampingRatio)
	self.k = stiffness/m
	self.d = -dampingCoeff/m
	self.x = initialPos
	self.t = initialPos
	self.v = initialPos*0

	return self
end

-- Public Methods

function SpringClass:Update(dt)
	if (not self.instant) then
		local t, k, d, x0, v0 = self.t, self.k, self.d, self.x, self.v
		local a0 = k*(t - x0) + v0*d
		local v1 = v0 + a0*(dt/2)
		local a1 = k*(t - (x0 + v0*(dt/2))) + v1*d
		local v2 = v0 + a1*(dt/2)
		local a2 = k*(t - (x0 + v1*(dt/2))) + v2*d
		local v3 = v0 + a2*dt
		local x4 = x0 + (v0 + 2*(v1 + v2) + v3)*(dt/6)
		self.x, self.v = x4, v0 + (a0 + 2*(a1 + a2) + k*(t - (x0 + v2*dt)) + v3*d)*(dt/6)
		
		if (getAbsDist(x4, self.t) > self.marginOfError) then
			return x4
		end
	end
	
	self.x, self.v = self.t, self.v*0
	return self.x
end

--

return SpringClass
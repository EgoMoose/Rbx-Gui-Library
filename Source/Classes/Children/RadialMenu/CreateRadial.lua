-- CONSTANTS

local CONSTANTS = require(script.Parent:WaitForChild("CONSTANTS"))
local Triangle = require(script.Parent:WaitForChild("Triangle"))

local PI2 = math.pi/2
local TAU = CONSTANTS.TAU

local GAP = CONSTANTS.GAP
local PART_PER_UNIT = CONSTANTS.PART_PER_UNIT

local CENTER = CONSTANTS.CENTER
local EXTERIOR_RADIUS = CONSTANTS.EXTERIOR_RADIUS
local EX_OFFSET = CONSTANTS.EX_OFFSET
local G_OFFSET = CONSTANTS.G_OFFSET

local VPF = Instance.new("ViewportFrame")
VPF.Ambient = Color3.new(1, 1, 1)
VPF.LightColor = Color3.new(1, 1, 1)
VPF.LightDirection = Vector3.new(0, 0, -1)
VPF.BackgroundTransparency = 1
VPF.Size = UDim2.new(1, 0, 1, 0)

local CAMERA = Instance.new("Camera")
CAMERA.CameraType = Enum.CameraType.Scriptable
CAMERA.CFrame = CFrame.new()
CAMERA.FieldOfView = CONSTANTS.FOV

--

local function pivotAround(model, pivotCF, newCF)
	local invPivotCF = pivotCF:Inverse()
	for _, part in next, model:GetDescendants() do
		part.CFrame = newCF * (invPivotCF * part.CFrame)
	end
end

local function createSection(subN, interior_radius, exterior_radius, ppu)
	local subModel = Instance.new("Model")
	
	local exCircum = (TAU*exterior_radius)/subN - GAP
	local inCircum = (TAU*interior_radius)/subN - GAP

	local exTheta = exCircum / (exterior_radius)
	local inTheta = inCircum / (interior_radius)
	local diffTheta = exTheta - inTheta
	
	local exPoints = {}
	local inPoints = {}
	
	local nParts = math.ceil(exCircum/ppu)
	
	for i = 0, nParts do
		exPoints[i + 1] = CENTER * CFrame.fromEulerAnglesXYZ(0, 0, (i/nParts)*exTheta) * Vector3.new(exterior_radius, 0, 0)
		inPoints[i + 1] = CENTER * CFrame.fromEulerAnglesXYZ(0, 0, diffTheta/2 + (i/nParts)*inTheta) * Vector3.new(interior_radius, 0, 0)
	end
	
	for i = 1, nParts do
		local a = exPoints[i]
		local b = inPoints[i]
		local c = exPoints[i + 1]
		local d = inPoints[i + 1]
		
		Triangle(subModel, a, b, c)
		Triangle(subModel, b, c, d)
	end
	
	return subModel
end

local function createRadial(subN, tPercent, rotation)
	rotation = rotation or 0
	
	local dialEx = (1 - tPercent)*EXTERIOR_RADIUS - 1
	local dialIn = dialEx - 2
	
	local section = createSection(subN, (1 - tPercent)*EXTERIOR_RADIUS, EXTERIOR_RADIUS, PART_PER_UNIT)
	local innerSection = createSection(subN, dialIn, dialEx, PART_PER_UNIT/2)
	
	local frame = Instance.new("Frame")
	local radialFrame = Instance.new("Frame")
	local attachFrame = Instance.new("Frame")
	radialFrame.BackgroundTransparency = 1
	attachFrame.BackgroundTransparency = 1
	radialFrame.Size = UDim2.new(1, 0, 1, 0)
	attachFrame.Size = UDim2.new(1, 0, 1, 0)
	radialFrame.Name = "Radial"
	attachFrame.Name = "Attach"
	radialFrame.Parent = frame
	attachFrame.Parent = frame
	
	local thickness = tPercent * EXTERIOR_RADIUS
	local interior_radius = EXTERIOR_RADIUS - thickness
	local inv_tPercent = 1 - tPercent/2
	
	local exCircum = (TAU*EXTERIOR_RADIUS)/subN
	local exTheta = exCircum / EXTERIOR_RADIUS
	local inCircum = (TAU*interior_radius)/subN - GAP
	local inTheta = inCircum / (interior_radius)
	
	local edge = Vector2.new(math.cos(inTheta), math.sin(inTheta))*interior_radius - Vector2.new(interior_radius, 0)
	local edgeLen = math.min(edge.Magnitude / (EXTERIOR_RADIUS*2), 0.18)
	
	for i = 0, subN - 1 do
		local vpf = VPF:Clone()
		local cam = CAMERA:Clone()
		vpf.CurrentCamera = cam
		vpf.Name = i + 1
		
		local theta = (i/subN)*TAU + rotation
		
		local sub = section:Clone()
		pivotAround(sub, CENTER, CENTER * CFrame.fromEulerAnglesXYZ(0, 0, theta + EX_OFFSET))
		sub.Parent = vpf
		
		local t = theta - EX_OFFSET + exTheta/2 + G_OFFSET
		local c = -math.cos(t)/2 * inv_tPercent
		local s = math.sin(t)/2 * inv_tPercent
		
		local attach = Instance.new("Frame")
		attach.Name = i + 1
		attach.BackgroundTransparency = 1
		attach.BackgroundColor3 = Color3.new()
		attach.BorderSizePixel = 0
		attach.AnchorPoint = Vector2.new(0.5, 0.5)
		attach.Position = UDim2.new(0.5 + c, 0, 0.5 + s, 0)
		attach.Size = UDim2.new(edgeLen, 0, edgeLen, 0)
		attach.Parent = attachFrame
		
		cam.Parent = vpf
		vpf.Parent = radialFrame
	end
	
	section:Destroy()
	
	local vpf = VPF:Clone()
	local cam = CAMERA:Clone()
	vpf.CurrentCamera = cam
	vpf.Name = "RadialDial"
	
	local g = GAP / (2*dialEx)
	local off = -TAU/4 + g
	
	pivotAround(innerSection, CENTER, CENTER * CFrame.fromEulerAnglesXYZ(0, 0, rotation + off))
	innerSection.Parent = vpf
	vpf.Parent = frame
	
	frame.BackgroundTransparency = 1
	frame.SizeConstraint = Enum.SizeConstraint.RelativeYY
	frame.Size = UDim2.new(1, 0, 1, 0)
	return frame
end

--

return createRadial
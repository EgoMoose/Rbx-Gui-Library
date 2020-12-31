TAU = math.pi*2

GAP = 2
FOV = 70
VIEW_DIST = 50
PART_PER_UNIT = 6

CENTER = CFrame.new(0, 0, -VIEW_DIST)
EXTERIOR_RADIUS = VIEW_DIST * math.tan(math.rad(FOV/2))
G_OFFSET = GAP / (2*EXTERIOR_RADIUS)
EX_OFFSET = -TAU/4 + G_OFFSET

local module = getfenv()
module.script = nil
return module
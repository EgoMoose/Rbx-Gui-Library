local WEDGE = Instance.new("WedgePart")
WEDGE.Material = Enum.Material.SmoothPlastic
WEDGE.Anchored = true
WEDGE.CanCollide = false
WEDGE.Color = Color3.new(1, 1, 1)

return function(parent, a, b, c)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	
	if (abd > acd and abd > bcd) then
		c, a = a, c
	elseif (acd > bcd and acd > abd) then
		a, b = b, a
	end
	
	ab, ac, bc = b - a, c - a, c - b
	
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	
	local height = math.abs(ab:Dot(up))
	local width1 = math.abs(ab:Dot(back))
	local width2 = math.abs(ac:Dot(back))
	
	local w1 = WEDGE:Clone()
	w1.Size = Vector3.new(0, height, width1)
	w1.CFrame = CFrame.fromMatrix((a + b)/2, right, up, back)
	w1.Parent = parent
	
	local w2 = WEDGE:Clone()
	w2.Size = Vector3.new(0, height, width2)
	w2.CFrame = CFrame.fromMatrix((a + c)/2, -right, up, -back)
	w2.Parent = parent
	
	return w1, w2
end
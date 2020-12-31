local Mask = {}

Mask.Name = "String"
Mask.Default = ""

function Mask:Process(text)
	return text
end

function Mask:Verify(text)
	return true
end

function Mask:ToType(text)
	return text
end

return Mask
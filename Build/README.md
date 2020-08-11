# Building the project

The project can be downloaded and built using the following code in the Roblox Studio command bar.

```Lua
local URL = "https://api.github.com/repos/EgoMoose/Rbx-Gui-Library/contents"
local HTTP = game:GetService("HttpService")

-- build functions

local function isLua(item)
	local doesMatch = item.name:lower():match(".lua")
	return (item.type == "file" and doesMatch)
end

local function isFolder(item)
	return (item.type == "dir")
end

local function build(path, parent)
	local data = HTTP:JSONDecode(HTTP:GetAsync(URL .. path))
	
	for i, item in next, data do
		local name = item.name
		if (isLua(item)) then
			name = name:sub(1, #item-5)
			
			local module = Instance.new("ModuleScript")
			module.Name = name
			module.Source = HTTP:GetAsync(item.download_url)
			module.Parent = parent
		elseif (isFolder(item)) then
			local folder = Instance.new("Folder")
			folder.Name = name
			folder.Parent = parent
			
			build(item.path, folder)
		end
	end
end

--

local GuiLib = Instance.new("Folder")
GuiLib.Name = "GuiLib"

build("/Source", GuiLib)

GuiLib.Parent = workspace
```

Beyond that the `Defaults.rbxm` file will have to be manually dragged into studio and placed in the `GuiLib` folder.
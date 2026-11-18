--[[
    MY WISH
    Tavern Town | Delta | mobile
    One window for hunting and mining.

    If the last line of this file is not
        -- END OF MY WISH
    the copy was cut off. Do not run a cut copy.

    Hunt
        animal ESP with Highlight and a small heart tag, no dark banner
        player ESP in a different style
        friends use a plain heart, not an emoji
        left AIM button, and aim only runs while that button reads ON
        line of sight, so a tree blocks the lock
        magnetic arrows after the shot
        red ESP only when the animal is actually downed
        downed animals are dropped from aim
        speed slider
        go-to-player is a drag, not a teleport that snaps back
        X shrinks the window into a rose bubble

    Mine
        AUTO MINE walks you onto the nearest gem node
        it holds the stand-off spot and swings on the game's 1.15s rhythm
        5 / 8 / 12 swings by node size, then it moves to the next gem
        travel is velocity based, so the server never snaps you back
        optional node highlight, auto pickaxe equip, stand-off and speed sliders
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")

local VirtualInput = nil
pcall(function()
	VirtualInput = game:GetService("VirtualInputManager")
end)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function destroyNamed(parent, name)
	if not parent then
		return
	end
	local found = parent:FindFirstChild(name)
	if found then
		pcall(function()
			found:Destroy()
		end)
	end
end

pcall(function()
	if getgenv and getgenv().MYWISH and getgenv().MYWISH.Unload then
		getgenv().MYWISH.Unload()
	end
end)
pcall(function()
	local oldFish = getgenv and getgenv().MYWISH_FISH
	if type(oldFish) == "function" then
		oldFish()
	elseif type(oldFish) == "table" and oldFish.Unload then
		oldFish.Unload()
	end
end)

local OLD_GUI_NAMES = {
	"MY_WISH",
	"MY_WISH_INTRO",
	"MYWISH_VIS",
	"MYWISH_AIM",
	"MYWISH_FISH",
	"MYWISH_FISH_GUI",
	"MY_WISH_FISH",
	"MYWISH_FISHBUB",
	"TavernInspectorVisuals",
}

for _, name in ipairs(OLD_GUI_NAMES) do
	pcall(function()
		if gethui then
			destroyNamed(gethui(), name)
		end
	end)
	destroyNamed(PlayerGui, name)
	pcall(function()
		destroyNamed(game:GetService("CoreGui"), name)
	end)
end
pcall(function()
	local blur = Lighting:FindFirstChild("MYWISH_Zoom")
	if blur then
		blur:Destroy()
	end
end)

local Theme = {
	Bg = Color3.fromRGB(255, 246, 249),
	Bg2 = Color3.fromRGB(255, 233, 240),
	Bg3 = Color3.fromRGB(255, 214, 226),
	Card = Color3.fromRGB(255, 252, 253),
	Pink = Color3.fromRGB(250, 158, 190),
	PinkSoft = Color3.fromRGB(255, 198, 216),
	PinkDeep = Color3.fromRGB(222, 84, 132),
	Rose = Color3.fromRGB(238, 112, 158),
	Text = Color3.fromRGB(74, 44, 58),
	Dim = Color3.fromRGB(160, 126, 142),
	White = Color3.fromRGB(255, 255, 255),
	Line = Color3.fromRGB(255, 192, 212),
	Good = Color3.fromRGB(118, 206, 158),
	HitRed = Color3.fromRGB(255, 74, 96),
	Player = Color3.fromRGB(126, 176, 250),
	PlayerSoft = Color3.fromRGB(172, 206, 255),
	Friend = Color3.fromRGB(255, 138, 184),
	FriendSoft = Color3.fromRGB(255, 182, 212),
	Snow = Color3.fromRGB(255, 253, 255),
	Fluff = Color3.fromRGB(255, 250, 253),
	Bunny = Color3.fromRGB(255, 250, 253),
	Ink = Color3.fromRGB(58, 40, 52),
	Blossom = Color3.fromRGB(255, 214, 230),
	BlossomCore = Color3.fromRGB(248, 150, 186),
	BlossomDeep = Color3.fromRGB(232, 108, 152),
}

local ROSE_IMAGE = "rbxassetid://8297102546"

-- a sakura blossom built from real petal frames, so it never depends on an
-- uploaded decal and looks the same on every device
local function blossom(parent, size, tint, zindex)
	local flower = Instance.new("Frame")
	flower.Name = "Blossom"
	flower.AnchorPoint = Vector2.new(0.5, 0.5)
	flower.Size = UDim2.fromOffset(size, size)
	flower.BackgroundTransparency = 1
	flower.ZIndex = zindex or 2
	flower.Parent = parent
	for petal = 1, 5 do
		local leaf = Instance.new("Frame")
		leaf.AnchorPoint = Vector2.new(0.5, 1)
		leaf.Position = UDim2.new(0.5, 0, 0.5, math.floor(size * 0.06))
		leaf.Size = UDim2.fromOffset(math.max(math.floor(size * 0.42), 5), math.floor(size * 0.46))
		leaf.BackgroundColor3 = tint or Theme.Blossom
		leaf.BorderSizePixel = 0
		leaf.Rotation = (petal - 1) * 72
		leaf.ZIndex = flower.ZIndex
		leaf.Parent = flower
		Instance.new("UICorner", leaf).CornerRadius = UDim.new(1, 0)
	end
	local core = Instance.new("Frame")
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.Position = UDim2.fromScale(0.5, 0.5)
	core.Size = UDim2.fromOffset(math.max(math.floor(size * 0.26), 4), math.max(math.floor(size * 0.26), 4))
	core.BackgroundColor3 = Theme.BlossomCore
	core.BorderSizePixel = 0
	core.ZIndex = (zindex or 2) + 1
	core.Parent = flower
	Instance.new("UICorner", core).CornerRadius = UDim.new(1, 0)
	return flower
end

-- wide flat petal ring, used behind the minimised bubble so the flower reads
-- as a whole blossom rather than a dot
local function petalRing(parent, size, tint, zindex)
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromScale(1, 1)
	ring.BackgroundTransparency = 1
	ring.ZIndex = zindex or 1
	ring.Parent = parent
	for petal = 1, 5 do
		local leaf = Instance.new("Frame")
		leaf.AnchorPoint = Vector2.new(0.5, 1)
		leaf.Position = UDim2.new(0.5, 0, 0.52, math.floor(size * 0.05))
		leaf.Size = UDim2.fromOffset(math.floor(size * 0.44), math.floor(size * 0.5))
		leaf.BackgroundColor3 = tint or Theme.Blossom
		leaf.BorderSizePixel = 0
		leaf.Rotation = (petal - 1) * 72
		leaf.ZIndex = ring.ZIndex
		leaf.Parent = ring
		Instance.new("UICorner", leaf).CornerRadius = UDim.new(0.9, 0)
		local stroke = Instance.new("UIStroke", leaf)
		stroke.Color = Theme.PetalEdge or Theme.Line
		stroke.Thickness = 1
		stroke.Transparency = 0.35
	end
	return ring
end
local HEART = "♥"

local Settings = {
	AnimalESP = true,
	AnimalHighlight = true,
	AnimalTag = true,
	PlayerESP = true,
	PlayerHighlight = true,
	PlayerTag = true,
	ShowDistance = true,
	ShowPrice = true,
	MaxDistance = 450,
	ScanEvery = 1.15,
	SpeedOn = false,
	Speed = 32,
	DragSpeed = 95,
	DragStop = 5,
	DragTimeout = 12,
	AimOn = false,
	ShowAimButton = false,
	AimFov = 22,
	AimSmooth = 0.07,
	AimRange = 160,
	AimStrength = 1,
	ZoomOnAim = true,
	ZoomFov = 40,
	ShootOnAim = false,
	ShootEvery = 0.95,
	RequireSight = true,
	Homing = true,
	HomingStrength = 0.92,
	HomingTime = 3.5,
	MagnetSnap = 9,
	AutoMine = false,
	MineStand = 4,
	MineSpeed = 55,
	MineEquip = true,
	MineMark = true,
}

local Species = {
	Rabbit = { Price = "25g", Color = Color3.fromRGB(255, 170, 200) },
	Raccoon = { Price = "50g", Color = Color3.fromRGB(210, 160, 220) },
	Fox = { Price = "75g", Color = Color3.fromRGB(255, 160, 120) },
	Doe = { Price = "125g", Color = Color3.fromRGB(255, 180, 210) },
	Stag = { Price = "150g", Color = Color3.fromRGB(230, 150, 170) },
	Boar = { Price = "100g", Color = Color3.fromRGB(220, 150, 140) },
	Wolf = { Price = "120g", Color = Color3.fromRGB(170, 180, 255) },
	Bear = { Price = "25 gems", Color = Color3.fromRGB(255, 120, 140) },
}

local SpeciesOrder = { "Rabbit", "Raccoon", "Fox", "Doe", "Stag", "Boar", "Wolf", "Bear" }
local SpeciesOn = {}
for speciesName in pairs(Species) do
	SpeciesOn[speciesName] = speciesName ~= "Bear"
end

local ConfirmedDown = {}
local Connections = {}

local function track(connection)
	if connection then
		table.insert(Connections, connection)
	end
	return connection
end

local function disconnectAll()
	for _, connection in ipairs(Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(Connections)
end

local Hunting = nil
pcall(function()
	Hunting = require(ReplicatedStorage.Shared.Config.Hunting)
end)
if type(Hunting) ~= "table" then
	Hunting = {}
end
if type(Hunting.speed) ~= "function" then
	function Hunting.speed(strength)
		return 70 + 170 * math.clamp(strength or 1, 0, 1)
	end
end
if type(Hunting.aimAt) ~= "function" then
	function Hunting.aimAt(from, to, speed)
		local delta = to - from
		local flat = Vector3.new(delta.X, 0, delta.Z)
		local range = flat.Magnitude
		if range < 1 or speed <= 0 then
			return nil
		end
		local gravity = 70
		local speedSq = speed * speed
		local disc = speedSq * speedSq - gravity * (gravity * range * range + delta.Y * 2 * speedSq)
		if disc < 0 then
			return nil
		end
		local slope = (speedSq - math.sqrt(disc)) / (gravity * range)
		local angle = math.atan(slope)
		return flat.Unit * math.cos(angle) + Vector3.new(0, math.sin(angle), 0)
	end
end

-- The window is built before ESP, aim, or mining.
-- A later error cannot hide it.
local Screen = Instance.new("ScreenGui")
Screen.Name = "MY_WISH"
Screen.ResetOnSpawn = false
Screen.IgnoreGuiInset = true
Screen.DisplayOrder = 125
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.Enabled = true
Screen.Parent = PlayerGui

local Window = Instance.new("Frame")
Window.Name = "Main"
Window.Size = UDim2.fromOffset(272, 332)
Window.Position = UDim2.new(0.5, -136, 0.28, 0)
Window.BackgroundColor3 = Theme.Bg
Window.BorderSizePixel = 0
Window.Active = true
Window.ZIndex = 5
Window.Parent = Screen
Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 16)
local windowStroke = Instance.new("UIStroke", Window)
windowStroke.Color = Theme.Pink
windowStroke.Thickness = 2

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Theme.Bg2
Header.BorderSizePixel = 0
Header.ZIndex = 6
Header.Parent = Window
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 16)
local headerFill = Instance.new("Frame")
headerFill.Size = UDim2.new(1, 0, 0, 12)
headerFill.Position = UDim2.new(0, 0, 1, -12)
headerFill.BackgroundColor3 = Theme.Bg2
headerFill.BorderSizePixel = 0
headerFill.ZIndex = 6
headerFill.Parent = Header

local headerBlossom = blossom(Header, 22, Theme.Blossom, 8)
headerBlossom.Position = UDim2.new(0, 18, 0.5, 0)
blossom(Header, 12, Theme.Blossom, 9).Position = UDim2.new(1, -20, 0, 12)
blossom(Header, 8, Theme.PinkSoft, 9).Position = UDim2.new(1, -34, 1, -10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -110, 1, 0)
Title.Position = UDim2.new(0, 36, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MY WISH"
Title.Font = Enum.Font.Antique
Title.TextSize = 20
Title.TextColor3 = Theme.PinkDeep
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 8
Title.Parent = Header
local titleTag = Instance.new("TextLabel")
titleTag.Size = UDim2.new(0, 90, 0, 10)
titleTag.Position = UDim2.new(0, 38, 1, -12)
titleTag.BackgroundTransparency = 1
titleTag.Text = "sakura edition"
titleTag.Font = Enum.Font.Gotham
titleTag.TextSize = 8
titleTag.TextColor3 = Theme.Dim
titleTag.TextXAlignment = Enum.TextXAlignment.Left
titleTag.ZIndex = 8
titleTag.Parent = Header

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "Close"
CloseButton.Size = UDim2.fromOffset(26, 26)
CloseButton.Position = UDim2.new(1, -32, 0.5, -13)
CloseButton.BackgroundColor3 = Theme.PinkSoft
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 13
CloseButton.TextColor3 = Theme.PinkDeep
CloseButton.ZIndex = 12
CloseButton.Parent = Header
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(1, 0)

local Footer = Instance.new("TextLabel")
Footer.Name = "Footer"
Footer.Size = UDim2.new(1, -12, 0, 14)
Footer.Position = UDim2.new(0, 6, 1, -16)
Footer.BackgroundTransparency = 1
Footer.Text = "open"
Footer.Font = Enum.Font.Gotham
Footer.TextSize = 10
Footer.TextColor3 = Theme.Dim
Footer.TextXAlignment = Enum.TextXAlignment.Left
Footer.ZIndex = 7
Footer.Parent = Window

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -10, 0, 24)
TabBar.Position = UDim2.new(0, 5, 0, 42)
TabBar.BackgroundColor3 = Theme.Bg2
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 6
TabBar.Parent = Window
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)
local tabLayout = Instance.new("UIListLayout", TabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 2)
local tabPad = Instance.new("UIPadding", TabBar)
tabPad.PaddingLeft = UDim.new(0, 2)
tabPad.PaddingRight = UDim.new(0, 2)
tabPad.PaddingTop = UDim.new(0, 2)
tabPad.PaddingBottom = UDim.new(0, 2)

local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, -10, 1, -86)
Body.Position = UDim2.new(0, 5, 0, 70)
Body.BackgroundTransparency = 1
Body.ZIndex = 6
Body.Parent = Window

local Pages = {}
local TabButtons = {}

local function selectTab(name)
	for pageName, page in pairs(Pages) do
		page.Visible = pageName == name
	end
	for tabName, button in pairs(TabButtons) do
		local on = tabName == name
		button.BackgroundColor3 = on and Theme.Pink or Theme.Bg3
		button.TextColor3 = on and Theme.White or Theme.Dim
	end
end

local function makePage(name)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.2, -2, 1, 0)
	button.BackgroundColor3 = Theme.Bg3
	button.Text = name
	button.Font = Enum.Font.GothamBold
	button.TextSize = 9
	button.TextColor3 = Theme.Dim
	button.AutoButtonColor = false
	button.ZIndex = 7
	button.Parent = TabBar
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
	TabButtons[name] = button

	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Theme.Pink
	page.CanvasSize = UDim2.new()
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.ZIndex = 6
	page.Parent = Body
	local layout = Instance.new("UIListLayout", page)
	layout.Padding = UDim.new(0, 4)
	local pad = Instance.new("UIPadding", page)
	pad.PaddingTop = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 2)
	Pages[name] = page
	button.MouseButton1Click:Connect(function()
		selectTab(name)
	end)
	return page
end

local PageAim = makePage("Aim")
local PageEsp = makePage("ESP")
local PageMove = makePage("Move")
local PageMobs = makePage("Mobs")
local PageMine = makePage("Mine")
selectTab("ESP")

local function section(parent, text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 14)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 9
	label.TextColor3 = Theme.PinkDeep
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 7
	label.Parent = parent
	return label
end

local function card(parent, height)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -2, 0, height or 28)
	frame.BackgroundColor3 = Theme.Card
	frame.BorderSizePixel = 0
	frame.ZIndex = 7
	frame.Parent = parent
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Theme.Line
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	return frame
end

local function addToggle(parent, text, getValue, setValue)
	local row = card(parent, 28)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -48, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 11
	label.TextColor3 = Theme.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 8
	label.Parent = row
	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromOffset(30, 14)
	pill.Position = UDim2.new(1, -38, 0.5, -7)
	pill.BorderSizePixel = 0
	pill.ZIndex = 8
	pill.Parent = row
	Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(10, 10)
	dot.BorderSizePixel = 0
	dot.ZIndex = 9
	dot.Parent = pill
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	local hit = Instance.new("TextButton")
	hit.Size = UDim2.fromScale(1, 1)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.ZIndex = 10
	hit.Parent = row
	local function paint(on)
		pill.BackgroundColor3 = on and Theme.Pink or Theme.Bg3
		dot.BackgroundColor3 = on and Theme.White or Theme.Dim
		dot.Position = on and UDim2.new(0, 16, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
	end
	paint(getValue())
	hit.MouseButton1Click:Connect(function()
		local nextValue = not getValue()
		setValue(nextValue)
		paint(nextValue)
	end)
	return row
end

local function addSlider(parent, text, minValue, maxValue, getValue, setValue)
	local row = card(parent, 38)
	local caption = Instance.new("TextLabel")
	caption.Size = UDim2.new(1, -12, 0, 14)
	caption.Position = UDim2.new(0, 8, 0, 2)
	caption.BackgroundTransparency = 1
	caption.Font = Enum.Font.Gotham
	caption.TextSize = 10
	caption.TextColor3 = Theme.PinkDeep
	caption.TextXAlignment = Enum.TextXAlignment.Left
	caption.ZIndex = 8
	caption.Parent = row
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -16, 0, 6)
	bar.Position = UDim2.new(0, 8, 0, 22)
	bar.BackgroundColor3 = Theme.Bg3
	bar.BorderSizePixel = 0
	bar.ZIndex = 8
	bar.Parent = row
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Theme.Pink
	fill.BorderSizePixel = 0
	fill.ZIndex = 9
	fill.Parent = bar
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	local function paint()
		local value = getValue()
		local alpha = math.clamp((value - minValue) / math.max(maxValue - minValue, 1), 0, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		caption.Text = text .. "  " .. tostring(value)
	end
	paint()
	local dragging = false
	local function apply(x)
		local width = math.max(bar.AbsoluteSize.X, 1)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / width, 0, 1)
		setValue(math.floor(minValue + (maxValue - minValue) * alpha + 0.5))
		paint()
	end
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			apply(input.Position.X)
		end
	end)
	track(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			apply(input.Position.X)
		end
	end))
	track(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
	return row
end

local function addButton(parent, text, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -2, 0, 26)
	button.BackgroundColor3 = Theme.PinkSoft
	button.Text = text
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 11
	button.TextColor3 = Theme.PinkDeep
	button.AutoButtonColor = false
	button.ZIndex = 8
	button.Parent = parent
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
	button.MouseButton1Click:Connect(function()
		pcall(callback)
	end)
	return button
end

print("[MY WISH] window is up")

-- visuals folder. PlayerGui is the safe parent on mobile Delta.
local Visuals = Instance.new("Folder")
Visuals.Name = "MYWISH_VIS"
Visuals.Parent = PlayerGui

local Friends = {}

local function refreshFriends()
	table.clear(Friends)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local ok, isFriend = pcall(function()
				return LocalPlayer:IsFriendsWith(player.UserId)
			end)
			if ok and isFriend then
				Friends[player.UserId] = true
			end
		end
	end
end

task.spawn(function()
	pcall(refreshFriends)
	while Screen.Parent do
		task.wait(20)
		pcall(refreshFriends)
	end
end)

local sightParams = RaycastParams.new()
sightParams.FilterType = Enum.RaycastFilterType.Exclude
sightParams.IgnoreWater = true

local function refreshSightFilter()
	local list = { Visuals, Screen }
	if LocalPlayer.Character then
		table.insert(list, LocalPlayer.Character)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	local wildlife = Workspace:FindFirstChild("Wildlife")
	if wildlife then
		table.insert(list, wildlife)
	end
	for _, name in ipairs({ "Arrows", "Arrow", "Projectiles", "FX", "Effects" }) do
		local folder = Workspace:FindFirstChild(name)
		if folder then
			table.insert(list, folder)
		end
	end
	sightParams.FilterDescendantsInstances = list
end

local function hasLineOfSight(from, to, model)
	if not Settings.RequireSight then
		return true
	end
	local delta = to - from
	local distance = delta.Magnitude
	if distance < 1.2 then
		return true
	end
	local hit = Workspace:Raycast(from, delta.Unit * math.max(distance - 1.5, 0.5), sightParams)
	if not hit then
		return true
	end
	if model and hit.Instance:IsDescendantOf(model) then
		return true
	end
	return false
end

local function findWildlifeFolder()
	local direct = Workspace:FindFirstChild("Wildlife")
	if direct then
		return direct
	end
	for _, child in ipairs(Workspace:GetChildren()) do
		local lower = string.lower(child.Name)
		if lower == "wildlife" or lower == "animals" or lower == "hunting" then
			return child
		end
		local nested = child:FindFirstChild("Wildlife")
		if nested then
			return nested
		end
	end
	return nil
end

local function speciesOf(name)
	if type(name) ~= "string" then
		return nil
	end
	for speciesName in pairs(Species) do
		if string.find(name, speciesName, 1, true) then
			return speciesName
		end
	end
	local lower = string.lower(name)
	for speciesName in pairs(Species) do
		if string.find(lower, string.lower(speciesName), 1, true) then
			return speciesName
		end
	end
	return nil
end

local PART_ORDER = { "Head", "Torso", "Neck", "Body", "Hips", "Root", "HumanoidRootPart" }

local function pickPart(model)
	if not model then
		return nil
	end
	for _, name in ipairs(PART_ORDER) do
		local part = model:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RootPart then
		return humanoid.RootPart
	end
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Transparency < 1 and desc.Size.Magnitude > 0.2 then
			return desc
		end
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function aimPointOf(part)
	if not part then
		return nil
	end
	return part.Position + Vector3.new(0, 0.85, 0)
end

local DOWN_KEYS = { "Down", "Downed", "Knocked", "Dead", "Loot", "Fallen", "Harvest", "Body" }

local function isDowned(model)
	if not model or not model.Parent then
		return true
	end
	if ConfirmedDown[model] then
		return true
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if humanoid.Health <= 0 then
			ConfirmedDown[model] = true
			return true
		end
		if humanoid:GetState() == Enum.HumanoidStateType.Dead then
			ConfirmedDown[model] = true
			return true
		end
	end
	for _, key in ipairs(DOWN_KEYS) do
		local value = model:GetAttribute(key)
		if value == true or value == 1 then
			ConfirmedDown[model] = true
			return true
		end
	end
	if model:FindFirstChild("KnockApart", true) or model:FindFirstChild("KnockA0", true) then
		ConfirmedDown[model] = true
		return true
	end
	local sockets = 0
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BallSocketConstraint") and string.find(desc.Name, "Knock") then
			sockets = sockets + 1
		end
	end
	if sockets >= 2 and humanoid and humanoid:GetState() == Enum.HumanoidStateType.Physics then
		ConfirmedDown[model] = true
		return true
	end
	return false
end

local AnimalEntries = {}

local function clearAnimal(model)
	local entry = AnimalEntries[model]
	if not entry then
		return
	end
	if entry.highlight then
		pcall(function()
			entry.highlight:Destroy()
		end)
	end
	if entry.tag then
		pcall(function()
			entry.tag:Destroy()
		end)
	end
	AnimalEntries[model] = nil
	ConfirmedDown[model] = nil
end

local function paintAnimal(entry, model)
	if not entry.highlight then
		return
	end
	if isDowned(model) then
		entry.highlight.FillColor = Theme.HitRed
		entry.highlight.OutlineColor = Theme.HitRed
		entry.highlight.FillTransparency = 0.42
	else
		local color = Species[entry.species].Color
		entry.highlight.FillColor = color
		entry.highlight.OutlineColor = color
		entry.highlight.FillTransparency = 0.62
	end
	entry.highlight.OutlineTransparency = 0
end

local function ensureAnimal(model, speciesName)
	if not SpeciesOn[speciesName] then
		clearAnimal(model)
		return
	end
	local part = pickPart(model)
	if not part then
		return
	end
	local entry = AnimalEntries[model]
	if not entry then
		entry = { species = speciesName, part = part }
		AnimalEntries[model] = entry
	else
		entry.species = speciesName
		entry.part = part
	end
	if Settings.AnimalHighlight and Settings.AnimalESP then
		if not entry.highlight then
			local highlight = Instance.new("Highlight")
			highlight.Name = "MYWISH_Animal"
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = Visuals
			entry.highlight = highlight
		end
		entry.highlight.Adornee = model
		entry.highlight.Enabled = true
		paintAnimal(entry, model)
	elseif entry.highlight then
		entry.highlight.Enabled = false
	end
	if Settings.AnimalTag and Settings.AnimalESP then
		if not entry.tag then
			local billboard = Instance.new("BillboardGui")
			billboard.Name = "MYWISH_AnimalTag"
			billboard.Size = UDim2.fromOffset(140, 22)
			billboard.StudsOffset = Vector3.new(0, 2.4, 0)
			billboard.AlwaysOnTop = true
			billboard.MaxDistance = Settings.MaxDistance
			billboard.Parent = Visuals
			local text = Instance.new("TextLabel")
			text.BackgroundTransparency = 1
			text.Size = UDim2.fromScale(1, 1)
			text.Font = Enum.Font.GothamMedium
			text.TextSize = 11
			text.TextStrokeTransparency = 0.5
			text.TextStrokeColor3 = Color3.fromRGB(80, 40, 60)
			text.Parent = billboard
			entry.tag = billboard
			entry.text = text
		end
		entry.tag.Adornee = part
		entry.tag.MaxDistance = Settings.MaxDistance
		entry.tag.Enabled = true
	elseif entry.tag then
		entry.tag.Enabled = false
	end
end

local function considerAnimal(model, found)
	if not model:IsA("Model") then
		return
	end
	local speciesName = speciesOf(model.Name)
	if not speciesName then
		local attr = model:GetAttribute("Species") or model:GetAttribute("Kind") or model:GetAttribute("Type")
		if type(attr) == "string" then
			speciesName = speciesOf(attr)
		end
	end
	if not speciesName then
		for _, child in ipairs(model:GetChildren()) do
			speciesName = speciesOf(child.Name)
			if speciesName then
				break
			end
		end
	end
	if speciesName and pickPart(model) then
		found[model] = speciesName
		ensureAnimal(model, speciesName)
	end
end

local function scanAnimals()
	local folder = findWildlifeFolder()
	local found = {}
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			considerAnimal(child, found)
			if child:IsA("Folder") or child:IsA("Model") then
				for _, nested in ipairs(child:GetChildren()) do
					if nested:IsA("Model") then
						considerAnimal(nested, found)
					end
				end
			end
		end
	end
	if next(found) == nil then
		for _, child in ipairs(Workspace:GetChildren()) do
			if child:IsA("Model") and speciesOf(child.Name) then
				local isPlayer = false
				for _, player in ipairs(Players:GetPlayers()) do
					if player.Character == child then
						isPlayer = true
						break
					end
				end
				if not isPlayer then
					considerAnimal(child, found)
				end
			end
		end
	end
	for model in pairs(AnimalEntries) do
		if not found[model] or not model.Parent then
			clearAnimal(model)
		end
	end
	return folder ~= nil, found
end

local PlayerEntries = {}

local function clearPlayer(player)
	local entry = PlayerEntries[player]
	if not entry then
		return
	end
	if entry.highlight then
		pcall(function()
			entry.highlight:Destroy()
		end)
	end
	if entry.tag then
		pcall(function()
			entry.tag:Destroy()
		end)
	end
	PlayerEntries[player] = nil
end

local function ensurePlayer(player)
	if player == LocalPlayer then
		return
	end
	local character = player.Character
	if not character then
		clearPlayer(player)
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
	if not root then
		return
	end
	local entry = PlayerEntries[player]
	if not entry then
		entry = {}
		PlayerEntries[player] = entry
	end
	local friend = Friends[player.UserId] == true
	local color = friend and Theme.Friend or Theme.Player
	local soft = friend and Theme.FriendSoft or Theme.PlayerSoft
	if Settings.PlayerHighlight and Settings.PlayerESP then
		if not entry.highlight then
			local highlight = Instance.new("Highlight")
			highlight.Name = "MYWISH_Player"
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.FillTransparency = 0.72
			highlight.OutlineTransparency = 0
			highlight.Parent = Visuals
			entry.highlight = highlight
		end
		entry.highlight.Adornee = character
		entry.highlight.FillColor = soft
		entry.highlight.OutlineColor = color
		entry.highlight.Enabled = true
	elseif entry.highlight then
		entry.highlight.Enabled = false
	end
	if Settings.PlayerTag and Settings.PlayerESP then
		if not entry.tag then
			local billboard = Instance.new("BillboardGui")
			billboard.Name = "MYWISH_PlayerTag"
			billboard.Size = UDim2.fromOffset(160, 34)
			billboard.StudsOffset = Vector3.new(0, 3.1, 0)
			billboard.AlwaysOnTop = true
			billboard.MaxDistance = 2000
			billboard.Parent = Visuals
			local text = Instance.new("TextLabel")
			text.BackgroundTransparency = 1
			text.Size = UDim2.fromScale(1, 1)
			text.Font = Enum.Font.GothamBold
			text.TextSize = 12
			text.TextStrokeTransparency = 0.3
			text.TextStrokeColor3 = Color3.fromRGB(40, 30, 50)
			text.Parent = billboard
			entry.tag = billboard
			entry.text = text
		end
		entry.tag.Adornee = root
		entry.tag.Enabled = true
		entry.text.TextColor3 = color
	elseif entry.tag then
		entry.tag.Enabled = false
	end
end

local function scanPlayers()
	local alive = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			alive[player] = true
			ensurePlayer(player)
		end
	end
	for player in pairs(PlayerEntries) do
		if not alive[player] then
			clearPlayer(player)
		end
	end
end

local guidedArrows = {}
local lastLockPart = nil
local lastLockModel = nil

local function isArrowPart(part)
	if not part:IsA("BasePart") then
		return false
	end
	local name = string.lower(part.Name)
	if name == "arrow" or name == "bolt" or name == "projectile" then
		return true
	end
	if part:GetAttribute("NockOffset") ~= nil then
		return true
	end
	local size = part.Size
	if size.Z >= 1.2 and size.X <= 0.5 and size.Y <= 0.5 then
		if part:FindFirstChildOfClass("Trail") or part:FindFirstChild("TrailA") then
			return true
		end
	end
	return false
end

local function arrowRoot(inst)
	if inst:IsA("BasePart") and isArrowPart(inst) then
		return inst
	end
	if inst:IsA("Model") then
		for _, desc in ipairs(inst:GetDescendants()) do
			if desc:IsA("BasePart") and isArrowPart(desc) then
				return desc
			end
		end
		return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local function nearestLiveAnimal(origin)
	local bestPart, bestModel, bestDist = nil, nil, Settings.AimRange
	for model, entry in pairs(AnimalEntries) do
		if entry.part and entry.part.Parent and SpeciesOn[entry.species] and not isDowned(model) then
			local dist = (entry.part.Position - origin).Magnitude
			if dist < bestDist and hasLineOfSight(origin, aimPointOf(entry.part), model) then
				bestDist = dist
				bestPart = entry.part
				bestModel = model
			end
		end
	end
	return bestPart, bestModel
end

local function registerArrow(inst)
	if not Settings.Homing then
		return
	end
	local arrow = arrowRoot(inst)
	if not arrow or guidedArrows[arrow] then
		return
	end
	local camera = Workspace.CurrentCamera
	if camera and (arrow.Position - camera.CFrame.Position).Magnitude > 32 then
		return
	end
	local targetPart, targetModel = lastLockPart, lastLockModel
	if not targetPart or not targetPart.Parent or (targetModel and isDowned(targetModel)) then
		targetPart, targetModel = nearestLiveAnimal(arrow.Position)
	end
	if not targetPart then
		return
	end
	guidedArrows[arrow] = {
		untilTime = os.clock() + Settings.HomingTime,
		part = targetPart,
		model = targetModel,
	}
	pcall(function()
		arrow.Anchored = true
	end)
end

track(Workspace.ChildAdded:Connect(function(child)
	task.defer(function()
		pcall(registerArrow, child)
	end)
end))
for _, name in ipairs({ "Arrows", "Arrow", "Projectiles" }) do
	local folder = Workspace:FindFirstChild(name)
	if folder then
		track(folder.ChildAdded:Connect(function(child)
			task.defer(function()
				pcall(registerArrow, child)
			end)
		end))
	end
end

local function guideArrows(dt)
	if not Settings.Homing then
		return
	end
	for arrow, info in pairs(guidedArrows) do
		if not arrow.Parent or os.clock() > info.untilTime then
			guidedArrows[arrow] = nil
		else
			local part = info.part
			local model = info.model
			if not part or not part.Parent or (model and isDowned(model)) then
				part, model = nearestLiveAnimal(arrow.Position)
				info.part = part
				info.model = model
			end
			if not part then
				guidedArrows[arrow] = nil
			else
				local velocity = Vector3.zero
				pcall(function()
					velocity = part.AssemblyLinearVelocity
				end)
				local dest = aimPointOf(part) + velocity * 0.22
				local offset = dest - arrow.Position
				local distance = offset.Magnitude
				if distance <= Settings.MagnetSnap then
					local look = velocity.Magnitude > 1 and velocity or offset
					arrow.CFrame = CFrame.lookAt(dest, dest + look)
					guidedArrows[arrow] = nil
				elseif distance > 0.05 then
					local speed = 220 * 1.15
					local want = offset.Unit
					local look = arrow.CFrame.LookVector
					local blend = math.clamp(Settings.HomingStrength, 0.2, 1)
					local newDir = look:Lerp(want, math.max(blend, 0.55))
					if newDir.Magnitude < 0.05 then
						newDir = want
					else
						newDir = newDir.Unit
					end
					local step = math.min(speed * dt, distance - 0.4)
					local newPos = arrow.Position + newDir * step
					arrow.CFrame = CFrame.lookAt(newPos, newPos + newDir)
					pcall(function()
						arrow.AssemblyLinearVelocity = newDir * speed
					end)
				end
			end
		end
	end
end

local function equippedBow()
	local character = LocalPlayer.Character
	if not character then
		return nil
	end
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			local name = string.lower(tool.Name)
			if string.find(name, "bow", 1, true) or string.find(name, "hunt", 1, true) then
				return tool
			end
		end
	end
	return nil
end

local aimLock = nil
local aimLockModel = nil
local aimStatus = "off"
local baseFov = 70
local zoomBlur = nil
local shootClock = 0

local function setZoom(on)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	if on and Settings.ZoomOnAim then
		if not zoomBlur then
			baseFov = camera.FieldOfView
			zoomBlur = Instance.new("BlurEffect")
			zoomBlur.Name = "MYWISH_Zoom"
			zoomBlur.Size = 2
			zoomBlur.Parent = Lighting
		end
		camera.FieldOfView = Settings.ZoomFov
	else
		camera.FieldOfView = (baseFov > 10) and baseFov or 70
		if zoomBlur then
			zoomBlur.Size = 0
		end
	end
end

local function pickAimTarget(origin, look)
	local cone = math.cos(math.rad(Settings.AimFov))
	local bestPart, bestModel, bestScore = nil, nil, -1e9
	local anyPart, anyModel, anyDist = nil, nil, Settings.AimRange
	for model, entry in pairs(AnimalEntries) do
		if entry.part and entry.part.Parent and SpeciesOn[entry.species] then
			if isDowned(model) then
				paintAnimal(entry, model)
			else
				local point = aimPointOf(entry.part)
				local offset = point - origin
				local distance = offset.Magnitude
				if distance >= 2 and distance <= Settings.AimRange and hasLineOfSight(origin, point, model) then
					local dot = look:Dot(offset.Unit)
					local score = dot * 2.2 - (distance / Settings.AimRange) * 0.65
					if dot >= cone and score > bestScore then
						bestScore = score
						bestPart = entry.part
						bestModel = model
					end
					if distance < anyDist then
						anyDist = distance
						anyPart = entry.part
						anyModel = model
					end
				end
			end
		end
	end
	if bestPart then
		return bestPart, bestModel, (bestPart.Position - origin).Magnitude
	end
	if anyPart then
		return anyPart, anyModel, anyDist
	end
	return nil
end

local function aimStep(dt)
	if not Settings.AimOn then
		if aimLock then
			aimLock = nil
			aimLockModel = nil
			aimStatus = "off"
			setZoom(false)
		end
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	refreshSightFilter()
	local origin = camera.CFrame.Position
	local part, model, distance = pickAimTarget(origin, camera.CFrame.LookVector)
	if not part then
		aimLock = nil
		aimLockModel = nil
		lastLockPart = nil
		lastLockModel = nil
		aimStatus = "none"
		setZoom(false)
		return
	end
	if model and isDowned(model) then
		aimStatus = "downed"
		aimLock = nil
		return
	end
	local point = aimPointOf(part)
	local velocity = Vector3.zero
	pcall(function()
		velocity = part.AssemblyLinearVelocity
	end)
	local speed = Hunting.speed(Settings.AimStrength)
	local lead = point + velocity * math.clamp(distance / math.max(speed, 1), 0.05, 0.9)
	local direction = Hunting.aimAt(origin, lead, speed)
	if not direction then
		direction = (lead - origin)
	end
	if direction.Magnitude < 0.05 then
		return
	end
	if not hasLineOfSight(origin, lead, model) then
		if not hasLineOfSight(origin, point, model) then
			aimStatus = "tree"
			setZoom(false)
			aimLock = nil
			return
		end
		direction = (point - origin)
	end
	direction = direction.Unit
	aimLock = part
	aimLockModel = model
	lastLockPart = part
	lastLockModel = model
	local speciesName = "target"
	local entry = AnimalEntries[model]
	if entry then
		speciesName = entry.species
	end
	aimStatus = speciesName .. " " .. math.floor(distance or 0) .. "m"
	setZoom(true)
	local blend = math.clamp(1 - Settings.AimSmooth, 0.25, 1)
	camera.CFrame = camera.CFrame:Lerp(CFrame.new(origin, origin + direction), blend)
	if Settings.ShootOnAim then
		shootClock = shootClock + dt
		if shootClock >= Settings.ShootEvery then
			shootClock = 0
			local bow = equippedBow()
			if bow then
				pcall(function()
					bow:Activate()
				end)
			end
		end
	end
end

local aimMarker = Instance.new("BillboardGui")
aimMarker.Name = "MYWISH_AimRing"
aimMarker.Size = UDim2.fromOffset(36, 36)
aimMarker.AlwaysOnTop = true
aimMarker.Enabled = false
aimMarker.Parent = Visuals
do
	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromScale(1, 1)
	ring.BackgroundTransparency = 1
	ring.Parent = aimMarker
	local stroke = Instance.new("UIStroke", ring)
	stroke.Color = Theme.Rose
	stroke.Thickness = 2
	Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
end

local dragState = nil

local function stopDrag()
	local state = dragState
	dragState = nil
	if not state then
		return
	end
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if root then
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
		end)
	end
	if humanoid then
		humanoid.WalkSpeed = Settings.SpeedOn and Settings.Speed or (state.savedSpeed or 16)
		pcall(function()
			humanoid:Move(Vector3.zero)
		end)
	end
end

local function startDrag(player)
	stopDrag()
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	dragState = {
		player = player,
		untilTime = os.clock() + Settings.DragTimeout,
		savedSpeed = humanoid and humanoid.WalkSpeed or 16,
	}
end

local function dragStep(dt)
	local state = dragState
	if not state then
		return
	end
	if os.clock() > state.untilTime then
		stopDrag()
		return
	end
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	local targetRoot = state.player.Character and state.player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not targetRoot then
		return
	end
	local back = Vector3.new(targetRoot.CFrame.LookVector.X, 0, targetRoot.CFrame.LookVector.Z)
	if back.Magnitude < 0.05 then
		back = Vector3.new(0, 0, 1)
	else
		back = back.Unit
	end
	local dest = targetRoot.Position - back * Settings.DragStop
	local flat = Vector3.new(dest.X - root.Position.X, 0, dest.Z - root.Position.Z)
	if flat.Magnitude <= Settings.DragStop + 0.6 and math.abs(dest.Y - root.Position.Y) < 8 then
		stopDrag()
		return
	end
	local dir = flat.Magnitude > 0.1 and flat.Unit or Vector3.zero
	local yBoost = 0
	local yDelta = dest.Y - root.Position.Y
	if yDelta > 2 then
		yBoost = math.clamp(yDelta * 0.35, 0, 40)
	elseif yDelta < -4 then
		yBoost = math.clamp(yDelta * 0.2, -25, 0)
	end
	if humanoid then
		humanoid.WalkSpeed = 0
		pcall(function()
			humanoid:MoveTo(dest)
		end)
	end
	local step = math.min(Settings.DragSpeed * dt, math.max(flat.Magnitude - Settings.DragStop * 0.4, 0))
	local newPos = root.Position + dir * step + Vector3.new(0, yBoost * dt, 0)
	root.CFrame = CFrame.new(newPos, newPos + Vector3.new(dir.X, 0, dir.Z))
	root.AssemblyLinearVelocity = dir * Settings.DragSpeed + Vector3.new(0, yBoost, 0)
	root.AssemblyAngularVelocity = Vector3.zero
end

-- ================= AUTO MINE =================
-- Every gem node in this game carries the "GemNode" tag, five at a time, on
-- the mine floor at y = -60. Reach is 11 studs and a swing lands every
-- 1.15s, breaking a node in 5 / 8 / 12 swings by size. Nothing in the world
-- marks the node as tappable, so this walks onto the node, holds the spot,
-- swings the pickaxe on the game's own rhythm until the node breaks and then
-- picks the next one. The travel is velocity based, not a CFrame teleport,
-- because a hard teleport gets snapped back by the server.

local CollectionService = game:GetService("CollectionService")

local function screenAlive()
	return Screen ~= nil and Screen.Parent ~= nil
end

local NODE_INFO = {
	Small = { swings = 5, stand = 4 },
	Medium = { swings = 8, stand = 4.6 },
	Large = { swings = 12, stand = 5.4 },
}
local NODE_SWING = 1.15
local NODE_REACH = 11

local mineStatus = "off"
local mineStatusLabel = nil
local mineTarget = nil
local mineActive = false
local mineMarked = {}
local mineRemoteCache = nil

local function nodePart(instance)
	if not instance then
		return nil
	end
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		local main = instance.PrimaryPart
		if main then
			return main
		end
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function nodeAlive(part)
	if not part or not part.Parent or part.Transparency >= 1 then
		return false
	end
	if CollectionService:HasTag(part, "GemNode") then
		return true
	end
	local parent = part.Parent
	return parent ~= nil and CollectionService:HasTag(parent, "GemNode")
end

local function nodeSize(part)
	for _, key in ipairs({ "Size", "NodeSize", "size", "GemSize", "Kind" }) do
		local ok, value = pcall(function()
			return part:GetAttribute(key)
		end)
		if ok and type(value) == "string" and NODE_INFO[string.lower(value) == "small" and "Small" or (string.lower(value) == "large" and "Large" or "Medium")] then
			return value
		end
	end
	local top = math.max(part.Size.X, part.Size.Y, part.Size.Z)
	if top >= 5.6 then
		return "Large"
	elseif top >= 4.2 then
		return "Medium"
	end
	return "Small"
end

local function nodeInfo(part)
	local ok, size = pcall(nodeSize, part)
	local info = ok and NODE_INFO[size] or nil
	return info or NODE_INFO.Small
end

local function markNode(part, on)
	if not part then
		return
	end
	local existing = mineMarked[part]
	if on and not existing then
		local hl = Instance.new("Highlight")
		hl.Name = "MYWISH_MINE"
		hl.FillColor = Color3.fromRGB(130, 255, 210)
		hl.FillTransparency = 0.6
		hl.OutlineColor = Theme.Pink
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee = part
		hl.Parent = part
		mineMarked[part] = hl
	elseif not on and existing then
		mineMarked[part] = nil
		pcall(function()
			existing:Destroy()
		end)
	end
end

local function clearMarks()
	for part, hl in pairs(mineMarked) do
		mineMarked[part] = nil
		pcall(function()
			hl:Destroy()
		end)
	end
end

local function mineRemote()
	if mineRemoteCache and mineRemoteCache.Parent then
		return mineRemoteCache
	end
	mineRemoteCache = nil
	pcall(function()
		local shared = ReplicatedStorage:FindFirstChild("Shared")
		local net = shared and shared:FindFirstChild("Net")
		local remotes = net and net:FindFirstChild("Remotes")
		if remotes then
			mineRemoteCache = remotes:FindFirstChild("Mine")
				or remotes:FindFirstChild("Mining")
				or remotes:FindFirstChild("MineNode")
				or remotes:FindFirstChild("MineSwing")
		end
	end)
	return mineRemoteCache
end

local function toolInHand()
	local character = LocalPlayer.Character
	return character and character:FindFirstChildOfClass("Tool") or nil
end

local function findPickaxe()
	local character = LocalPlayer.Character
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	local loose = {}
	for _, container in ipairs({ character, backpack }) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") then
					local lower = string.lower(tool.Name)
					if string.find(lower, "pick", 1, true) or string.find(lower, "mine", 1, true) then
						return tool
					end
					table.insert(loose, tool)
				end
			end
		end
	end
	return loose[1]
end

local function equipPickaxe()
	local character = LocalPlayer.Character
	if not character then
		return nil
	end
	local held = character:FindFirstChildOfClass("Tool")
	if held then
		return held
	end
	if not Settings.MineEquip then
		return nil
	end
	local tool = findPickaxe()
	if tool and tool.Parent ~= character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			pcall(function()
				humanoid:EquipTool(tool)
			end)
			task.wait(0.18)
		end
	end
	return character:FindFirstChildOfClass("Tool")
end

local vim = nil
pcall(function()
	vim = game:GetService("VirtualInputManager")
end)

local mineSwingCache = nil

local function mineSwingController()
	if mineSwingCache then
		return mineSwingCache
	end
	pcall(function()
		local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
		local client = scripts and scripts:FindFirstChild("Client")
		local controllers = client and client:FindFirstChild("Controllers")
		if not controllers then
			controllers = client and client:FindFirstChild("Controllers")
		end
		local module = controllers and controllers:FindFirstChild("MineSwing")
		if not module then
			module = scripts and scripts:FindFirstChild("MineSwing", true)
		end
		if module and module:IsA("ModuleScript") then
			mineSwingCache = require(module)
		end
	end)
	return mineSwingCache
end

local function screenPoint(part)
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	local ok, point, onScreen = pcall(function()
		return camera:WorldToViewportPoint(part.Position)
	end)
	if not ok or not onScreen or point.Z <= 0 then
		return nil
	end
	return Vector2.new(point.X, point.Y)
end

-- one mining hit. the tool swing is what the game reads for damage, the prompt
-- or click detector below is the literal "tap on the gem" the mine asks for
local function tapNode(part)
	local character = LocalPlayer.Character
	if not character then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then
		tool = equipPickaxe()
	end
	if tool then
		pcall(function()
			tool:Activate()
		end)
	end
	local holder = part
	local prompt = holder:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt and holder.Parent then
		prompt = holder.Parent:FindFirstChildWhichIsA("ProximityPrompt", true)
	end
	if prompt then
		pcall(function()
			prompt:InputHoldBegin()
		end)
		task.delay(math.max(prompt.HoldDuration or 0.05, 0.05) + 0.04, function()
			pcall(function()
				prompt:InputHoldEnd()
			end)
		end)
		return
	end
	local detector = holder:FindFirstChildWhichIsA("ClickDetector", true)
	if not detector and holder.Parent then
		detector = holder.Parent:FindFirstChildWhichIsA("ClickDetector", true)
	end
	if detector and vim then
		local point = screenPoint(part)
		if point then
			pcall(function()
				vim:SendMouseButtonEvent(math.floor(point.X), math.floor(point.Y), 0, true, game, 0)
			end)
			task.delay(0.05, function()
				pcall(function()
					vim:SendMouseButtonEvent(math.floor(point.X), math.floor(point.Y), 0, false, game, 0)
				end)
			end)
		end
	end
end

local function nearestNode(root)
	local best, bestDist = nil, math.huge
	for _, instance in ipairs(CollectionService:GetTagged("GemNode")) do
		local part = nodePart(instance)
		if part and nodeAlive(part) then
			local dist = (part.Position - root.Position).Magnitude
			if dist < bestDist then
				best, bestDist = part, dist
			end
		end
	end
	return best
end

-- gem timings, straight out of the mine client controller
local MINE = {
	reach = 11,
	hitGap = 1.15,
	hits = 5,
	catchUp = 2,
	respawn = 8,
}

local mineNode = nil
local mineState = "idle"
local mineStage = 0
local mineLast = 0
local mineWait = 0
local mineScanAt = 0
local mineStuckAt = 0
local mineStuckFrom = nil
local mineOneShot = false
local mineBlocked = {}
local mineAcc = 0

local function liveRoot()
	local character = LocalPlayer.Character
	if not character then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return nil, nil, nil
	end
	return character, humanoid, root
end

local function mineWant()
	return Settings.AutoMine or mineOneShot
end

local function haltMiner()
	local _, humanoid, root = liveRoot()
	if humanoid and root then
		pcall(function()
			humanoid:MoveTo(root.Position)
			humanoid.WalkSpeed = Settings.Speed or 16
		end)
	end
	if mineNode then
		markNode(mineNode, false)
	end
	mineNode = nil
	mineState = "idle"
	mineStage = 0
	mineOneShot = false
	clearMarks()
	if not Settings.AutoMine then
		mineStatus = "off"
	end
end

local function chooseNode(root)
	local now = os.clock()
	if now < mineScanAt then
		return mineNode
	end
	mineScanAt = now + 0.35
	for part, until_ in pairs(mineBlocked) do
		if not part.Parent or now >= until_ then
			mineBlocked[part] = nil
		end
	end
	local best, bestDist = nil, math.huge
	for _, instance in ipairs(CollectionService:GetTagged("GemNode")) do
		local part = nodePart(instance)
		if part and nodeAlive(part) and not mineBlocked[part] then
			local dist = (part.Position - root.Position).Magnitude
			if dist < bestDist then
				best, bestDist = part, dist
			end
		end
	end
	return best
end

local function dropNode(minWait)
	if mineNode then
		markNode(mineNode, false)
	end
	mineNode = nil
	mineState = "idle"
	mineStage = 0
	mineWait = os.clock() + (minWait or 0.3)
end

-- runs from a single heartbeat, throttled to ten steps a second. nothing here
-- waits, nothing here loops, and the character is moved with humanoid:MoveTo
-- instead of a CFrame write every frame, so the client keeps its frame budget
local function mineStep()
	local character, humanoid, root = liveRoot()
	if not root then
		mineStatus = "no character"
		return
	end
	if mineNode and not nodeAlive(mineNode) then
		markNode(mineNode, false)
		mineBlocked[mineNode] = os.clock() + MINE.respawn
		mineNode = nil
		mineState = "idle"
		mineStage = 0
	end

	if mineState == "idle" then
		if os.clock() < mineWait then
			mineStatus = "waiting " .. math.ceil(mineWait - os.clock()) .. "s"
			return
		end
		mineNode = chooseNode(root)
		if not mineNode then
			mineStatus = "no gems up"
			return
		end
		mineState = "travel"
		mineStuckFrom = root.Position
		mineStuckAt = os.clock() + 4.5
		if Settings.MineMark then
			markNode(mineNode, true)
		end
	end

	local part = mineNode
	if not part then
		return
	end
	local info = nodeInfo(part)
	local stand = math.clamp(Settings.MineStand, 2, 9)
	local stopAt = math.min(stand, info.stand + 1)
	local flat = Vector3.new(part.Position.X - root.Position.X, 0, part.Position.Z - root.Position.Z)
	local gap = flat.Magnitude

	if mineState == "travel" then
		if gap <= math.min(stopAt + 0.7, MINE.reach - 1) then
			mineState = "swing"
			mineStage = 0
			mineLast = os.clock() - MINE.hitGap
			pcall(function()
				humanoid.WalkSpeed = 0
				humanoid:MoveTo(root.Position)
			end)
			pcall(equipPickaxe)
			local controller = mineSwingController()
			if controller then
				pcall(function()
					controller.play(character, 1, MINE.hits)
				end)
			end
			mineStatus = "at gem, swinging"
			return
		end
		mineStatus = "closing " .. math.floor(gap) .. "m"
		pcall(function()
			humanoid.WalkSpeed = math.clamp(Settings.MineSpeed, 24, 110)
			local away = gap > 0.6 and flat.Unit or Vector3.new(0, 0, 1)
			humanoid:MoveTo(Vector3.new(part.Position.X - away.X * stopAt, root.Position.Y, part.Position.Z - away.Z * stopAt))
		end)
		if os.clock() >= mineStuckAt then
			if (root.Position - mineStuckFrom).Magnitude < 1.8 then
				pcall(function()
					humanoid.Jump = true
				end)
				mineBlocked[part] = os.clock() + 5
				dropNode(0.35)
				return
			end
			mineStuckFrom = root.Position
			mineStuckAt = os.clock() + 4.5
		end
		return
	end

	-- swinging
	if gap > MINE.reach then
		mineState = "travel"
		mineStuckFrom = root.Position
		mineStuckAt = os.clock() + 4.5
		return
	end
	pcall(function()
		root.CFrame = CFrame.lookAt(root.Position, Vector3.new(part.Position.X, root.Position.Y, part.Position.Z))
	end)
	if os.clock() - mineLast >= MINE.hitGap then
		mineLast = os.clock()
		mineStage = mineStage + 1
		tapNode(part)
		if mineStage > MINE.hits then
			mineStatus = "gem hold, resetting"
		else
			mineStatus = "swinging " .. mineStage .. "/" .. MINE.hits .. "  " .. nodeSize(part)
		end
	end
	if mineStage >= MINE.hits + MINE.catchUp then
		markNode(part, false)
		mineBlocked[part] = os.clock() + MINE.respawn
		mineNode = nil
		mineState = "idle"
		mineStage = 0
		mineWait = os.clock() + 0.25
	end
end

local function mineOne(part)
	if not part then
		return
	end
	mineOneShot = true
	mineNode = part
	mineState = "travel"
	mineStage = 0
	mineWait = 0
	local _, humanoid, root = liveRoot()
	if humanoid and root then
		mineStuckFrom = root.Position
		mineStuckAt = os.clock() + 5
	else
		mineStuckFrom = Vector3.zero
		mineStuckAt = os.clock() + 5
	end
	if Settings.MineMark then
		markNode(part, true)
	end
end

track(RunService.Heartbeat:Connect(function(dt)
	if not mineWant() then
		return
	end
	if not screenAlive() then
		return
	end
	mineAcc = mineAcc + dt
	if mineAcc < 0.1 then
		return
	end
	mineAcc = 0
	local ok, err = pcall(mineStep)
	if not ok then
		mineStatus = "error: " .. tostring(err)
		dropNode(0.6)
	end
	if mineState == "idle" and not Settings.AutoMine and mineOneShot then
		mineOneShot = false
	end
end))

task.spawn(function()
	while screenAlive() do
		if not mineWant() and mineState ~= "off" then
			mineState = "off"
			if mineNode then
				markNode(mineNode, false)
				mineNode = nil
			end
			clearMarks()
		elseif mineWant() then
			mineState = "idle"
		end
		task.wait(0.25)
	end
end)

track(RunService.RenderStepped:Connect(function(dt)
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	for model, entry in pairs(AnimalEntries) do
		if entry.text and entry.tag and entry.tag.Enabled and entry.part and entry.part.Parent then
			if isDowned(model) then
				entry.text.Text = "down  " .. entry.species
				entry.text.TextColor3 = Theme.HitRed
				paintAnimal(entry, model)
			else
				local bits = { HEART .. " " .. entry.species }
				if Settings.ShowPrice then
					table.insert(bits, Species[entry.species].Price)
				end
				if Settings.ShowDistance and root then
					table.insert(bits, math.floor((entry.part.Position - root.Position).Magnitude) .. "m")
				end
				entry.text.Text = table.concat(bits, "  ")
				entry.text.TextColor3 = Species[entry.species].Color
			end
		end
	end
	for player, entry in pairs(PlayerEntries) do
		if entry.text and entry.tag and entry.tag.Enabled then
			local head = player.Character and (player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Head"))
			if head then
				local friend = Friends[player.UserId] == true
				local line = (friend and (HEART .. " ") or "◆ ") .. player.Name
				local extra = ""
				if Settings.ShowDistance and root then
					extra = math.floor((head.Position - root.Position).Magnitude) .. "m"
				end
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					extra = extra .. (extra ~= "" and "  " or "") .. math.floor(humanoid.Health) .. "hp"
				end
				entry.text.Text = extra ~= "" and (line .. "\n" .. extra) or line
				entry.text.TextColor3 = friend and Theme.Friend or Theme.Player
			end
		end
	end
	pcall(aimStep, dt)
	pcall(guideArrows, dt)
	pcall(dragStep, dt)
	if aimLock and aimLock.Parent and Settings.AimOn and not (aimLockModel and isDowned(aimLockModel)) then
		aimMarker.Adornee = aimLock
		aimMarker.Enabled = true
	else
		aimMarker.Enabled = false
	end
end))

task.spawn(function()
	while Screen.Parent do
		pcall(scanAnimals)
		pcall(scanPlayers)
		pcall(refreshSightFilter)
		task.wait(Settings.ScanEvery)
	end
end)

task.spawn(function()
	while Screen.Parent do
		if Settings.SpeedOn and not dragState then
			local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and math.abs(humanoid.WalkSpeed - Settings.Speed) > 0.15 then
				humanoid.WalkSpeed = Settings.Speed
			end
		end
		task.wait(0.2)
	end
end)

local AimButton = Instance.new("TextButton")
AimButton.Name = "AimButton"
AimButton.Size = UDim2.fromOffset(62, 62)
AimButton.Position = UDim2.new(0, 10, 0.56, 0)
AimButton.BackgroundColor3 = Theme.Card
AimButton.Text = "AIM\nOFF"
AimButton.Font = Enum.Font.GothamBlack
AimButton.TextSize = 12
AimButton.TextColor3 = Theme.PinkDeep
AimButton.Visible = false
AimButton.ZIndex = 40
AimButton.Parent = Screen
Instance.new("UICorner", AimButton).CornerRadius = UDim.new(1, 0)
local aimStroke = Instance.new("UIStroke", AimButton)
aimStroke.Color = Theme.Pink
aimStroke.Thickness = 2

local function paintAim()
	if Settings.AimOn then
		AimButton.BackgroundColor3 = Theme.Pink
		AimButton.TextColor3 = Theme.White
		AimButton.Text = "AIM\nON"
		aimStroke.Color = Theme.Rose
	else
		AimButton.BackgroundColor3 = Theme.Card
		AimButton.TextColor3 = Theme.PinkDeep
		AimButton.Text = "AIM\nOFF"
		aimStroke.Color = Theme.Pink
		setZoom(false)
		aimLock = nil
		aimLockModel = nil
		aimStatus = "off"
	end
end

AimButton.MouseButton1Click:Connect(function()
	Settings.AimOn = not Settings.AimOn
	paintAim()
end)

section(PageAim, "AIM")
addToggle(PageAim, "Show left AIM button", function()
	return Settings.ShowAimButton
end, function(value)
	Settings.ShowAimButton = value
	AimButton.Visible = value
	if not value then
		Settings.AimOn = false
		paintAim()
	end
end)
addToggle(PageAim, "Ignore trees", function()
	return Settings.RequireSight
end, function(value)
	Settings.RequireSight = value
end)
addToggle(PageAim, "Magnetic arrows", function()
	return Settings.Homing
end, function(value)
	Settings.Homing = value
end)
addToggle(PageAim, "Zoom while aiming", function()
	return Settings.ZoomOnAim
end, function(value)
	Settings.ZoomOnAim = value
end)
addToggle(PageAim, "Auto shoot", function()
	return Settings.ShootOnAim
end, function(value)
	Settings.ShootOnAim = value
end)
addSlider(PageAim, "Aim range", 40, 250, function()
	return Settings.AimRange
end, function(value)
	Settings.AimRange = value
end)
addSlider(PageAim, "Magnet strength", 40, 100, function()
	return math.floor(Settings.HomingStrength * 100)
end, function(value)
	Settings.HomingStrength = value / 100
end)
addButton(PageAim, "Turn AIM off", function()
	Settings.AimOn = false
	paintAim()
end)
addButton(PageAim, "Clear downed flags", function()
	table.clear(ConfirmedDown)
end)

section(PageEsp, "ANIMALS")
addToggle(PageEsp, "Animal ESP", function()
	return Settings.AnimalESP
end, function(value)
	Settings.AnimalESP = value
	pcall(scanAnimals)
end)
addToggle(PageEsp, "Animal highlight", function()
	return Settings.AnimalHighlight
end, function(value)
	Settings.AnimalHighlight = value
end)
addToggle(PageEsp, "Animal names", function()
	return Settings.AnimalTag
end, function(value)
	Settings.AnimalTag = value
end)
section(PageEsp, "PLAYERS")
addToggle(PageEsp, "Player ESP", function()
	return Settings.PlayerESP
end, function(value)
	Settings.PlayerESP = value
	pcall(scanPlayers)
end)
addToggle(PageEsp, "Player highlight", function()
	return Settings.PlayerHighlight
end, function(value)
	Settings.PlayerHighlight = value
end)
addToggle(PageEsp, "Player names", function()
	return Settings.PlayerTag
end, function(value)
	Settings.PlayerTag = value
end)
addToggle(PageEsp, "Distance", function()
	return Settings.ShowDistance
end, function(value)
	Settings.ShowDistance = value
end)
addToggle(PageEsp, "Price", function()
	return Settings.ShowPrice
end, function(value)
	Settings.ShowPrice = value
end)
addButton(PageEsp, "Refresh friends", function()
	refreshFriends()
	scanPlayers()
end)
addButton(PageEsp, "Rescan", function()
	scanAnimals()
	scanPlayers()
end)

section(PageMove, "SPEED")
addToggle(PageMove, "Speed on", function()
	return Settings.SpeedOn
end, function(value)
	Settings.SpeedOn = value
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and not dragState then
		humanoid.WalkSpeed = value and Settings.Speed or 16
	end
end)
addSlider(PageMove, "Walk speed", 16, 200, function()
	return Settings.Speed
end, function(value)
	Settings.Speed = value
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and Settings.SpeedOn and not dragState then
		humanoid.WalkSpeed = value
	end
end)
section(PageMove, "GO TO PLAYER")
addSlider(PageMove, "Drag speed", 40, 160, function()
	return Settings.DragSpeed
end, function(value)
	Settings.DragSpeed = value
end)
addButton(PageMove, "Stop drag", stopDrag)

local playerBox = Instance.new("Frame")
playerBox.Size = UDim2.new(1, -2, 0, 0)
playerBox.AutomaticSize = Enum.AutomaticSize.Y
playerBox.BackgroundTransparency = 1
playerBox.Parent = PageMove
Instance.new("UIListLayout", playerBox).Padding = UDim.new(0, 4)

local function rebuildPlayers()
	for _, child in ipairs(playerBox:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local friend = Friends[player.UserId] == true
			local button = Instance.new("TextButton")
			button.Size = UDim2.new(1, 0, 0, 26)
			button.BackgroundColor3 = friend and Theme.PinkSoft or Theme.Card
			button.Text = (friend and (HEART .. " ") or "") .. player.Name
			button.Font = Enum.Font.GothamMedium
			button.TextSize = 11
			button.TextColor3 = Theme.Text
			button.Parent = playerBox
			Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
			button.MouseButton1Click:Connect(function()
				startDrag(player)
				Footer.Text = "running to " .. player.Name
			end)
		end
	end
end
rebuildPlayers()
track(Players.PlayerAdded:Connect(function()
	task.wait(0.4)
	rebuildPlayers()
end))
track(Players.PlayerRemoving:Connect(function()
	task.wait(0.2)
	rebuildPlayers()
end))
addButton(PageMove, "Refresh players", function()
	refreshFriends()
	rebuildPlayers()
end)

section(PageMobs, "SPECIES")
for _, speciesName in ipairs(SpeciesOrder) do
	addToggle(PageMobs, speciesName .. "  " .. Species[speciesName].Price, function()
		return SpeciesOn[speciesName]
	end, function(value)
		SpeciesOn[speciesName] = value
		pcall(scanAnimals)
	end)
end
addButton(PageMobs, "Safe, no bear or wolf", function()
	for name in pairs(SpeciesOn) do
		SpeciesOn[name] = name ~= "Bear" and name ~= "Wolf"
	end
	pcall(scanAnimals)
end)

section(PageMine, "AUTO MINE")
mineStatusLabel = Instance.new("TextLabel")
mineStatusLabel.Size = UDim2.new(1, -2, 0, 32)
mineStatusLabel.BackgroundTransparency = 1
mineStatusLabel.Text = "off"
mineStatusLabel.Font = Enum.Font.GothamBold
mineStatusLabel.TextSize = 12
mineStatusLabel.TextColor3 = Theme.PinkDeep
mineStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
mineStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
mineStatusLabel.TextWrapped = true
mineStatusLabel.Parent = PageMine

addToggle(PageMine, "AUTO MINE GEM FARM", function()
	return Settings.AutoMine
end, function(value)
	Settings.AutoMine = value
	if value then
		mineOneShot = false
		mineState = "idle"
		mineStage = 0
		mineWait = 0
		mineBlocked = {}
		task.spawn(function()
			pcall(equipPickaxe)
			if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChildOfClass("Tool") then
				mineStatus = "equip a pickaxe"
			end
		end)
	else
		haltMiner()
	end
end)
addSlider(PageMine, "Stand off", 2, 9, function()
	return Settings.MineStand
end, function(value)
	Settings.MineStand = value
end)
addSlider(PageMine, "Travel speed", 20, 100, function()
	return Settings.MineSpeed
end, function(value)
	Settings.MineSpeed = value
end)
addToggle(PageMine, "Auto equip pickaxe", function()
	return Settings.MineEquip
end, function(value)
	Settings.MineEquip = value
end)
addToggle(PageMine, "Mark gem nodes", function()
	return Settings.MineMark
end, function(value)
	Settings.MineMark = value
	if not value then
		clearMarks()
	end
end)
addButton(PageMine, "Mine the nearest gem now", function()
	local _, _, root = liveRoot()
	local part = root and nearestNode(root)
	if not part then
		mineStatus = "no gems up"
		return
	end
	mineStatus = "one shot"
	mineOne(part)
end)

local mineNote = Instance.new("TextLabel")
mineNote.Size = UDim2.new(1, -2, 0, 56)
mineNote.BackgroundTransparency = 1
mineNote.Font = Enum.Font.Gotham
mineNote.TextSize = 10
mineNote.TextColor3 = Theme.Dim
mineNote.TextWrapped = true
mineNote.TextXAlignment = Enum.TextXAlignment.Left
mineNote.TextYAlignment = Enum.TextYAlignment.Top
mineNote.Text = "Turn AUTO MINE on with a pickaxe in the bag. It walks you to the nearest gem, taps it every 1.15s until it breaks, then moves on. Nothing is teleported, so the server never pulls you back."
mineNote.Parent = PageMine

local Bubble = Instance.new("Frame")
Bubble.Name = "BlossomBubble"
Bubble.Size = UDim2.fromOffset(64, 64)
Bubble.Position = UDim2.new(0, 12, 0.72, 0)
Bubble.BackgroundTransparency = 1
Bubble.Visible = false
Bubble.ZIndex = 60
Bubble.Parent = Screen
petalRing(Bubble, 64, Theme.Blossom, 60)
blossom(Bubble, 30, Theme.BlossomCore, 62)
local bubbleHit = Instance.new("TextButton")
bubbleHit.Size = UDim2.fromScale(1, 1)
bubbleHit.BackgroundTransparency = 1
bubbleHit.Text = ""
bubbleHit.ZIndex = 64
bubbleHit.Parent = Bubble

CloseButton.MouseButton1Click:Connect(function()
	Window.Visible = false
	Bubble.Visible = true
end)

local bubbleDrag = false
local bubbleFrom = nil
local bubbleOrigin = nil
local bubbleMoved = 0
bubbleHit.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		bubbleDrag = true
		bubbleFrom = input.Position
		bubbleOrigin = Bubble.Position
		bubbleMoved = 0
	end
end)
track(UserInputService.InputChanged:Connect(function(input)
	if not bubbleDrag then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end
	local delta = input.Position - bubbleFrom
	bubbleMoved = math.max(bubbleMoved, delta.Magnitude)
	local room = Screen.AbsoluteSize
	Bubble.Position = UDim2.fromOffset(
		math.clamp(bubbleOrigin.X.Offset + delta.X, 0, math.max(room.X - 64, 0)),
		math.clamp(bubbleOrigin.Y.Offset + delta.Y, 0, math.max(room.Y - 64, 0))
	)
end))
track(UserInputService.InputEnded:Connect(function(input)
	if not bubbleDrag then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	bubbleDrag = false
	if bubbleMoved < 8 then
		Bubble.Visible = false
		Window.Visible = true
	end
end))

local draggingWindow = false
local dragStart = nil
local dragOrigin = nil
Header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingWindow = true
		dragStart = input.Position
		dragOrigin = Window.Position
	end
end)
track(UserInputService.InputChanged:Connect(function(input)
	if draggingWindow and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - dragStart
		Window.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + delta.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + delta.Y)
	end
end))
track(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	draggingWindow = false
end))

task.spawn(function()
	while Screen.Parent do
		local count = 0
		for _ in pairs(AnimalEntries) do
			count = count + 1
		end
		Footer.Text = "animals " .. count .. "   aim " .. aimStatus .. "   mine " .. mineStatus
		if mineStatusLabel and mineStatusLabel.Parent then
			if Settings.AutoMine then
				mineStatusLabel.Text = mineStatus .. "\n" .. (mineTarget and "gem locked" or "scanning")
				mineStatusLabel.TextColor3 = mineTarget and Theme.Good or Theme.PinkDeep
			else
				mineStatusLabel.Text = "off"
				mineStatusLabel.TextColor3 = Theme.PinkDeep
			end
		end
		task.wait(0.2)
	end
end)

local function unload()
	Settings.AimOn = false
	Settings.AutoMine = false
	pcall(haltMiner)
	pcall(function()
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.WalkSpeed == 0 then
			humanoid.WalkSpeed = 16
		end
	end)
	setZoom(false)
	stopDrag()
	disconnectAll()
	for model in pairs(AnimalEntries) do
		clearAnimal(model)
	end
	for player in pairs(PlayerEntries) do
		clearPlayer(player)
	end
	pcall(function()
		if zoomBlur then
			zoomBlur:Destroy()
		end
	end)
	pcall(function()
		local intro = PlayerGui:FindFirstChild("MY_WISH_INTRO")
		if intro then
			intro:Destroy()
		end
	end)
	pcall(function()
		Screen:Destroy()
	end)
	pcall(function()
		Visuals:Destroy()
	end)
	if getgenv then
		getgenv().MYWISH = nil
	end
end

if getgenv then
	getgenv().MYWISH = { Unload = unload }
end

local function playIntro()
	local intro = Instance.new("ScreenGui")
	intro.Name = "MY_WISH_INTRO"
	intro.IgnoreGuiInset = true
	intro.ResetOnSpawn = false
	intro.DisplayOrder = 200
	intro.Parent = PlayerGui
	Window.Visible = false

	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.fromRGB(58, 30, 44)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.Parent = intro
	TweenService:Create(dim, TweenInfo.new(0.3), { BackgroundTransparency = 0.45 }):Play()

	local petal = Instance.new("Frame")
	petal.AnchorPoint = Vector2.new(0.5, 0.5)
	petal.Position = UDim2.fromScale(0.5, 0.45)
	petal.Size = UDim2.fromOffset(258, 258)
	petal.BackgroundColor3 = Theme.Blossom
	petal.BackgroundTransparency = 0.25
	petal.BorderSizePixel = 0
	petal.Parent = intro
	Instance.new("UICorner", petal).CornerRadius = UDim.new(1, 0)

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.45)
	card.Size = UDim2.fromOffset(210, 214)
	card.BackgroundColor3 = Theme.Snow
	card.BorderSizePixel = 0
	card.ClipsDescendants = false
	card.Parent = intro
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 40)

	for _, spot in ipairs({ { 16, 22, 14 }, { 176, 40, 10 }, { 150, 186, 12 }, { 26, 176, 9 } }) do
		blossom(card, spot[3], Theme.Blossom, 1).Position = UDim2.fromOffset(spot[1], spot[2])
	end

	local function puff(w, h, x, y, color, z)
		local blob = Instance.new("Frame")
		blob.AnchorPoint = Vector2.new(0.5, 0.5)
		blob.Position = UDim2.fromOffset(x, y)
		blob.Size = UDim2.fromOffset(w, h)
		blob.BackgroundColor3 = color or Theme.Fluff
		blob.BorderSizePixel = 0
		blob.ZIndex = z or 3
		blob.Parent = card
		Instance.new("UICorner", blob).CornerRadius = UDim.new(1, 0)
		return blob
	end

	-- tail, fluffy bottom, body built from overlapping puffs so the outline is soft
	puff(30, 30, 62, 150, Theme.Snow, 2)
	puff(28, 26, 168, 158, Theme.Snow, 2)
	puff(44, 30, 74, 158, Theme.Snow, 2)
	puff(40, 28, 150, 160, Theme.Snow, 2)
	puff(96, 74, 105, 148, Theme.Bunny)
	puff(24, 24, 68, 140)
	puff(24, 24, 142, 142)
	puff(22, 22, 92, 172)
	puff(22, 22, 122, 174)
	puff(26, 22, 78, 112, nil, 2)
	puff(26, 22, 132, 112, nil, 2)

	-- ears, tilted outward with pink inner
	for _, ear in ipairs({ { -1, 26 }, { 1, 26 } }) do
		local side, dx = ear[1], ear[2]
		local outer = Instance.new("Frame")
		outer.AnchorPoint = Vector2.new(0.5, 1)
		outer.Position = UDim2.fromOffset(105 + side * dx, 78)
		outer.Size = UDim2.fromOffset(25, 66)
		outer.Rotation = side * 13
		outer.BackgroundColor3 = Theme.Bunny
		outer.BorderSizePixel = 0
		outer.ZIndex = 4
		outer.Parent = card
		Instance.new("UICorner", outer).CornerRadius = UDim.new(1, 0)
		local inner = Instance.new("Frame")
		inner.AnchorPoint = Vector2.new(0.5, 1)
		inner.Position = UDim2.new(0.5, 0, 0.94, 0)
		inner.Size = UDim2.new(0.45, 0, 0.62, 0)
		inner.BackgroundColor3 = Theme.PinkSoft
		inner.BorderSizePixel = 0
		inner.ZIndex = 5
		inner.Parent = outer
		Instance.new("UICorner", inner).CornerRadius = UDim.new(1, 0)
	end

	local head = puff(88, 76, 105, 92, Theme.Bunny, 6)
	local cheekL = puff(20, 13, 82, 104, Theme.Blossom, 7)
	local cheekR = puff(20, 13, 128, 104, Theme.Blossom, 7)
	cheekL.BackgroundTransparency = 0.25
	cheekR.BackgroundTransparency = 0.25

	local eyes = {}
	for _, x in ipairs({ 92, 118 }) do
		local eye = puff(9, 12, x, 92, Theme.Ink, 8)
		table.insert(eyes, eye)
		puff(3, 4, x + 1, 90, Theme.Snow, 9)
	end
	local nose = puff(9, 6, 105, 104, Theme.BlossomDeep, 8)
	nose.BackgroundTransparency = 0.1

	local mouth = Instance.new("TextLabel")
	mouth.Size = UDim2.fromOffset(24, 14)
	mouth.Position = UDim2.fromOffset(93, 106)
	mouth.BackgroundTransparency = 1
	mouth.Text = "ᴗ"
	mouth.Font = Enum.Font.GothamBold
	mouth.TextSize = 14
	mouth.TextColor3 = Theme.Ink
	mouth.ZIndex = 8
	mouth.Parent = card

	local wish = Instance.new("TextLabel")
	wish.Size = UDim2.new(1, 0, 0, 26)
	wish.Position = UDim2.new(0, 0, 1, -40)
	wish.BackgroundTransparency = 1
	wish.Text = "MY WISH"
	wish.Font = Enum.Font.Antique
	wish.TextSize = 24
	wish.TextColor3 = Theme.PinkDeep
	wish.ZIndex = 6
	wish.Parent = card

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, 0, 0, 14)
	sub.Position = UDim2.new(0, 0, 1, -16)
	sub.BackgroundTransparency = 1
	sub.Text = "sakura bunny says hi"
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 10
	sub.TextColor3 = Theme.Dim
	sub.ZIndex = 6
	sub.Parent = card

	card.Size = UDim2.fromOffset(210, 170)
	TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(210, 214) }):Play()

	task.spawn(function()
		for _ = 1, 2 do
			task.wait(0.55)
			for _, eye in ipairs(eyes) do
				TweenService:Create(eye, TweenInfo.new(0.07), { Size = UDim2.fromOffset(9, 2) }):Play()
			end
			task.wait(0.1)
			for _, eye in ipairs(eyes) do
				TweenService:Create(eye, TweenInfo.new(0.1), { Size = UDim2.fromOffset(9, 12) }):Play()
			end
		end
	end)

	task.wait(2)
	TweenService:Create(dim, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(card, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(petal, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	task.wait(0.26)
	intro:Destroy()
	Window.Visible = true
end

task.spawn(function()
	local ok = pcall(playIntro)
	if not ok then
		Window.Visible = true
	end
	pcall(refreshFriends)
	pcall(scanAnimals)
	pcall(scanPlayers)
	Footer.Text = "ready"
	print("[MY WISH] ready")
end)

-- END OF MY WISH

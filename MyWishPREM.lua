--[[
    MY WISH · STORM PREMIUM v2.1
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
        AUTO MINE targets the game's tagged crystal Model and NodeId
        it walks to the normal stand-off radius and taps the crystal on screen
        Tavern Town's MineController handles the validated mining request
        exact Pickaxe detection, response timeout, smart waypoint and HUD
        optional node highlight, auto pickaxe equip, stand-off and speed sliders
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")
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
	Bg = Color3.fromRGB(35, 22, 43),
	Bg2 = Color3.fromRGB(57, 34, 63),
	Bg3 = Color3.fromRGB(82, 48, 83),
	Card = Color3.fromRGB(49, 31, 57),
	Pink = Color3.fromRGB(255, 143, 190),
	PinkSoft = Color3.fromRGB(255, 190, 216),
	PinkDeep = Color3.fromRGB(255, 174, 207),
	Rose = Color3.fromRGB(255, 112, 169),
	Text = Color3.fromRGB(255, 242, 249),
	Dim = Color3.fromRGB(202, 166, 190),
	White = Color3.fromRGB(255, 255, 255),
	Line = Color3.fromRGB(160, 102, 143),
	Good = Color3.fromRGB(145, 235, 198),
	HitRed = Color3.fromRGB(255, 92, 120),
	Player = Color3.fromRGB(155, 196, 255),
	PlayerSoft = Color3.fromRGB(190, 216, 255),
	Friend = Color3.fromRGB(255, 150, 198),
	FriendSoft = Color3.fromRGB(255, 190, 220),
	Snow = Color3.fromRGB(255, 252, 255),
	Bunny = Color3.fromRGB(255, 250, 253),
	Ink = Color3.fromRGB(62, 42, 60),
}

local ROSE_IMAGE = "rbxassetid://8297102546"
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
	GemESP = true,
	GemESPDistance = 500,
	AdvancedHUD = true,
	SmartWaypoints = true,
	AutoFaceGem = true,
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
Window.Size = UDim2.fromOffset(344, 486)
Window.Position = UDim2.new(0.5, -172, 0.16, 0)
Window.BackgroundColor3 = Theme.Bg
Window.BorderSizePixel = 0
Window.Active = true
Window.ZIndex = 5
Window.Parent = Screen
Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 16)
local windowStroke = Instance.new("UIStroke", Window)
windowStroke.Color = Theme.Pink
windowStroke.Thickness = 2
local windowGradient = Instance.new("UIGradient")
windowGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(61, 37, 69)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(31, 20, 40)),
})
windowGradient.Rotation = 90
windowGradient.Parent = Window

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Theme.Bg2
Header.BorderSizePixel = 0
local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new(Color3.fromRGB(255, 188, 216), Color3.fromRGB(218, 112, 166))
headerGradient.Rotation = 0
headerGradient.Parent = Header
Header.ZIndex = 6
Header.Parent = Window
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 16)
local headerFill = Instance.new("Frame")
headerFill.Size = UDim2.new(1, 0, 0, 12)
headerFill.Position = UDim2.new(0, 0, 1, -12)
headerFill.BackgroundColor3 = Color3.fromRGB(239, 158, 194)
headerFill.BorderSizePixel = 0
headerFill.ZIndex = 6
headerFill.Parent = Header

local headerRose = Instance.new("ImageLabel")
headerRose.Size = UDim2.fromOffset(18, 18)
headerRose.Position = UDim2.new(0, 10, 0.5, -9)
headerRose.BackgroundTransparency = 1
headerRose.Image = ROSE_IMAGE
headerRose.ImageColor3 = Theme.Rose
headerRose.ZIndex = 8
headerRose.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -76, 1, 0)
Title.Position = UDim2.new(0, 34, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MY WISH  ✿  |  STORM"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 15
Title.TextColor3 = Theme.Ink
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 8
Title.Parent = Header

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
TabBar.Size = UDim2.new(1, -10, 0, 27)
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
Body.Size = UDim2.new(1, -10, 1, -89)
Body.Position = UDim2.new(0, 5, 0, 73)
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
	button.Size = UDim2.new(1/8, -3, 1, 0)
	button.BackgroundColor3 = Theme.Bg3
	button.Text = name
	button.Font = Enum.Font.GothamBold
	button.TextSize = 8
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

local PageHome = makePage("Home")
local PageAim = makePage("Aim")
local PageEsp = makePage("ESP")
local PageMove = makePage("Move")
local PageMobs = makePage("Mobs")
local PageMine = makePage("Mine")
local PagePath = makePage("Path")
local PageHud = makePage("HUD")
selectTab("Home")

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
	button.BackgroundColor3 = Theme.Bg3
	button.Text = text
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 11
	button.TextColor3 = Theme.PinkSoft
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
-- Uses the game's Mine config and the exact client-side MineController input path.
-- The game's controller owns the validated MineNode request and mining animation.

local CollectionService = game:GetService("CollectionService")
local MineConfig = nil
local MineLayout = nil
local MineSwing = nil
pcall(function()
	local shared = ReplicatedStorage:WaitForChild("Shared")
	local config = shared:WaitForChild("Config")
	MineConfig = require(config:WaitForChild("Mine"))
	MineLayout = require(config:WaitForChild("MineLayout"))
end)
pcall(function()
	local playerScripts = LocalPlayer:WaitForChild("PlayerScripts")
	local client = playerScripts:FindFirstChild("Client")
	local controllers = client and client:FindFirstChild("Controllers")
	local module = controllers and controllers:FindFirstChild("MineSwing")
	if module then
		MineSwing = require(module)
	end
end)

local function configNumber(key, fallback)
	local value = MineConfig and MineConfig[key]
	return type(value) == "number" and value or fallback
end
local function configString(key, fallback)
	local value = MineConfig and MineConfig[key]
	return type(value) == "string" and value or fallback
end

local NODE_TAG = configString("NODE_TAG", "GemNode")
local NODE_SWING = configNumber("SWING_EVERY", 1.15)
local NODE_REACH = configNumber("REACH", 11)
local NODE_FLOOR = configNumber("FLOOR_Y", -60)
local NODE_COUNT = configNumber("NODE_COUNT", 5)
local RESPAWN_WAIT = configNumber("RESPAWN_MIN", 8)
local MINE_SECONDS = configNumber("MINE_SECONDS", 6)
local NODE_SIZES = (MineConfig and MineConfig.SIZES) or {
	Small = { swings = 5, stand = 4 },
	Medium = { swings = 8, stand = 4.6 },
	Large = { swings = 12, stand = 5.4 },
}
local FALLBACK_HIT_TIMES = { 1, 2.15, 3.3, 4.45, 5.6 }

local mineStatus = "off"
local mineStatusLabel = nil
local mineTarget = nil
local mineActive = false
local mineMarked = {}
local mineCooldown = setmetatable({}, { __mode = "k" })
local lastMineSwing = 0

local function hitTimesFor(count)
	if MineConfig and type(MineConfig.hitTimes) == "function" then
		local ok, times = pcall(MineConfig.hitTimes, count)
		if ok and type(times) == "table" and #times == count then
			return times
		end
	end
	local times = {}
	for i = 1, count do
		times[i] = (i - 1) * NODE_SWING + 1
	end
	return times
end

local function screenAlive()
	return Screen ~= nil and Screen.Parent ~= nil and Screen.Enabled == true
end

local function taggedNodeFor(instance)
	local current = instance
	while current and current ~= Workspace do
		local ok, tagged = pcall(function()
			return CollectionService:HasTag(current, NODE_TAG)
		end)
		if ok and tagged and current:IsA("Model") then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function nodePart(instance)
	if not instance then return nil end
	local model = taggedNodeFor(instance) or instance
	if model:IsA("Model") then
		local crystal = model:FindFirstChild("Crystal")
		if crystal and crystal:IsA("BasePart") then return crystal end
		if model.PrimaryPart then return model.PrimaryPart end
		return model:FindFirstChildWhichIsA("BasePart", true)
	end
	if model:IsA("BasePart") then return model end
	return nil
end

local function nodeAlive(instance)
	local model = taggedNodeFor(instance) or instance
	if not model or not model.Parent or not model:IsA("Model") then return false end
	local nodeId = model:GetAttribute("NodeId")
	return type(nodeId) == "number" and CollectionService:HasTag(model, NODE_TAG)
end

local function nodeSize(instance)
	local node = taggedNodeFor(instance) or instance
	local current = node
	while current and current ~= Workspace do
		for _, key in ipairs({ "NodeSize", "Size", "size", "GemSize", "Kind" }) do
			local ok, value = pcall(function() return current:GetAttribute(key) end)
			if ok and type(value) == "string" then
				local normalized = string.lower(value)
				if normalized == "small" then return "Small" end
				if normalized == "medium" then return "Medium" end
				if normalized == "large" then return "Large" end
			end
		end
		current = current.Parent
	end
	local size = nodePart(node) and nodePart(node).Size or Vector3.new(3, 3, 3)
	if node and node:IsA("Model") then
		local ok, extents = pcall(function() return node:GetExtentsSize() end)
		if ok then size = extents end
	end
	local height = math.max(size.X, size.Y, size.Z)
	if height >= 5.6 then return "Large" end
	if height >= 4.2 then return "Medium" end
	return "Small"
end

local function nodeInfo(instance)
	local sizeName = nodeSize(instance)
	local info = NODE_SIZES[sizeName]
	if type(info) ~= "table" then return { swings = 5, stand = 4 }, sizeName end
	return info, sizeName
end

local function markNode(node, on)
	if not node then return end
	local existing = mineMarked[node]
	if on and not existing then
		local hl = Instance.new("Highlight")
		hl.Name = "MYWISH_MINE"
		hl.FillColor = Color3.fromRGB(130, 255, 210)
		hl.FillTransparency = 0.6
		hl.OutlineColor = Theme.Pink
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee = taggedNodeFor(node) or node
		hl.Parent = Visuals
		mineMarked[node] = hl
	elseif not on and existing then
		mineMarked[node] = nil
		pcall(function() existing:Destroy() end)
	end
end

local function clearMarks()
	for part, hl in pairs(mineMarked) do
		mineMarked[part] = nil
		pcall(function() hl:Destroy() end)
	end
end

-- Gem ESP: client-side labels/highlights only; it does not alter node state.
local GemEntries = {}
local function clearGemEntry(node)
	local entry = GemEntries[node]
	if not entry then return end
	GemEntries[node] = nil
	pcall(function() entry.highlight:Destroy() end)
	pcall(function() entry.billboard:Destroy() end)
end

local function ensureGemEntry(node)
	if not Settings.GemESP or not node or not node.Parent then return end
	local part = nodePart(node)
	if not part then return end
	local entry = GemEntries[node]
	if entry and entry.part == part and entry.highlight.Parent and entry.billboard.Parent then
		return entry
	end
	if entry then clearGemEntry(node) end

	local highlight = Instance.new("Highlight")
	highlight.Name = "MYWISH_GEM_ESP"
	highlight.Adornee = node
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = Color3.fromRGB(120, 245, 220)
	highlight.OutlineColor = Color3.fromRGB(255, 170, 210)
	highlight.FillTransparency = 0.78
	highlight.OutlineTransparency = 0.08
	highlight.Parent = Visuals

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MYWISH_GEM_TAG"
	billboard.Adornee = part
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(132, 34)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.MaxDistance = Settings.GemESPDistance
	billboard.Parent = Visuals

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(255, 242, 249)
	label.BackgroundTransparency = 0.12
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = "✦ GEM NODE"
	label.TextColor3 = Color3.fromRGB(75, 115, 105)
	label.TextSize = 11
	label.Parent = billboard
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 9)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 170, 210)
	stroke.Thickness = 1.4
	stroke.Parent = label

	entry = { part = part, highlight = highlight, billboard = billboard, label = label }
	GemEntries[node] = entry
	return entry
end

local function scanGemESP()
	local alive = {}
	for _, node in ipairs(CollectionService:GetTagged(NODE_TAG)) do
		if node and node.Parent then
			alive[node] = true
			ensureGemEntry(node)
		end
	end
	for node in pairs(GemEntries) do
		if not alive[node] or not node.Parent then
			clearGemEntry(node)
		end
	end
end

local function updateGemESP()
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	for node, entry in pairs(GemEntries) do
		local part = entry.part
		local valid = Settings.GemESP and node.Parent and part and part.Parent
		local distance = valid and root and (part.Position - root.Position).Magnitude or nil
		local visible = valid and (not distance or distance <= Settings.GemESPDistance)
		entry.highlight.Enabled = visible
		entry.billboard.Enabled = visible
		if visible then
			local sizeName = nodeSize(part)
			entry.label.Text = "✦ " .. string.upper(sizeName) .. " GEM" .. (distance and ("  ·  " .. math.floor(distance) .. "m") or "")
		end
	end
end

local function toolInHand()
	local character = LocalPlayer.Character
	return character and character:FindFirstChildOfClass("Tool") or nil
end

-- Tavern Town's MineController checks for a Tool named exactly "Pickaxe".
local function findPickaxe()
	local character = LocalPlayer.Character
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	for _, container in ipairs({ character, backpack }) do
		if container then
			local exact = container:FindFirstChild("Pickaxe")
			if exact and exact:IsA("Tool") then return exact end
		end
	end
	return nil
end

local function equipPickaxe()
	local character = LocalPlayer.Character
	if not character then return nil end
	local held = character:FindFirstChild("Pickaxe")
	if held and held:IsA("Tool") then return held end
	local tool = findPickaxe()
	if tool and tool.Parent ~= character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			pcall(function() humanoid:EquipTool(tool) end)
			task.wait(0.2)
		end
	end
	return character:FindFirstChild("Pickaxe")
end

local function nodeWorldPosition(node)
	local ok, position = pcall(function() return node:GetPivot().Position end)
	if ok then return position end
	local part = nodePart(node)
	return part and part.Position or nil
end

-- This sends a normal screen tap at the crystal. Tavern Town's own
-- MineController receives the input, validates NodeId/Pickaxe/range, walks
-- the player into its stand-off radius, and sends its own MineNode request.
local function tapCrystal(node)
	local part = nodePart(node)
	local camera = Workspace.CurrentCamera
	if not part or not camera then
		return false, "camera or gem part unavailable"
	end
	if not nodeAlive(node) then return false, "gem despawned" end

	local function pointFor(worldPosition)
		local screenPoint, onScreen = camera:WorldToViewportPoint(worldPosition)
		if screenPoint.Z <= 0 or not onScreen then return nil end
		local ray = camera:ViewportPointToRay(screenPoint.X, screenPoint.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = CollectionService:GetTagged(NODE_TAG)
		local hit = Workspace:Raycast(ray.Origin, ray.Direction * 120, params)
		local hitNode = hit and hit.Instance and taggedNodeFor(hit.Instance)
		if hitNode ~= node then return nil end
		return screenPoint
	end

	-- Face the selected crystal, then verify that the same ray the game's
	-- MineController uses actually intersects that tagged node.
	if Settings.AutoFaceGem then
		pcall(function()
			camera.CFrame = CFrame.lookAt(camera.CFrame.Position, part.Position)
		end)
		task.wait(0.12)
	end

	local candidates = {
		part.Position,
		part.Position + Vector3.new(0, part.Size.Y * 0.18, 0),
		part.Position - Vector3.new(0, part.Size.Y * 0.18, 0),
	}
	local point = nil
	for _, candidate in ipairs(candidates) do
		point = pointFor(candidate)
		if point then break end
	end
	if not point then
		return false, "gem is not clear in the camera ray; move closer or clear the view"
	end

	local inset = Vector2.zero
	pcall(function()
		local topLeft = GuiService:GetGuiInset()
		inset = Vector2.new(topLeft.X, topLeft.Y)
	end)
	local touchPoint = Vector3.new(point.X - inset.X, point.Y - inset.Y, 0)

	-- Mobile path: the game's controller listens for a short Touch begin/end
	-- and performs its own NodeId, Pickaxe, reach and server checks.
	if VirtualInput then
		local touchOk = pcall(function()
			VirtualInput:SendTouchEvent(1, Enum.UserInputState.Begin, touchPoint)
			task.wait(0.10)
			VirtualInput:SendTouchEvent(1, Enum.UserInputState.End, touchPoint)
		end)
		if touchOk then return true end

		-- Desktop / executor fallback: still an ordinary input event.
		local mouseOk = pcall(function()
			VirtualInput:SendMouseButtonEvent(point.X, point.Y, 0, true, false)
			task.wait(0.10)
			VirtualInput:SendMouseButtonEvent(point.X, point.Y, 0, false, false)
		end)
		if mouseOk then return true end
	end

	-- Some mobile executors expose VirtualUser but not VirtualInputManager.
	local virtualUserOk = pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton1(Vector2.new(point.X, point.Y))
	end)
	if virtualUserOk then return true end
	return false, "executor does not expose working touch/click simulation"
end

local function nearestNode(root)
	local best, bestDist = nil, math.huge
	local layoutData = MineLayout and MineLayout.Data
	local bounds = layoutData and layoutData.bounds
	for _, node in ipairs(CollectionService:GetTagged(NODE_TAG)) do
		if node and node:IsA("Model") and nodeAlive(node) then
			local part = nodePart(node)
			local position = nodeWorldPosition(node)
			if part and position and (not mineCooldown[node] or mineCooldown[node] <= os.clock()) then
				local inBounds = true
				if bounds then
					inBounds = position.X >= bounds.x0 - 8 and position.X <= bounds.x1 + 8
						and position.Z >= bounds.z0 - 8 and position.Z <= bounds.z1 + 8
				end
				if inBounds then
					local dist = (position - root.Position).Magnitude
					if dist < bestDist then best, bestDist = node, dist end
				end
			end
		end
	end
	return best
end

local function walkToMineStand(humanoid, root, destination, node)
	local pathOk, path = pcall(function()
		local route = PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = true,
			WaypointSpacing = 5,
		})
		route:ComputeAsync(root.Position, destination)
		return route
	end)
	if pathOk and path and path.Status == Enum.PathStatus.Success then
		local routeStarted = os.clock()
		for _, waypoint in ipairs(path:GetWaypoints()) do
			if os.clock() - routeStarted > 12 then break end
			if not Settings.AutoMine or not screenAlive() or not nodeAlive(node) then return false end
			humanoid:MoveTo(waypoint.Position)
			if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
			local finished = false
			local connection
			connection = humanoid.MoveToFinished:Connect(function() finished = true end)
			local began = os.clock()
			while not finished and os.clock() - began < 3.5 and Settings.AutoMine and nodeAlive(node) do
				task.wait(0.08)
			end
			if connection then connection:Disconnect() end
			if not Settings.AutoMine or not nodeAlive(node) then return false end
			local gap = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(destination.X, 0, destination.Z)).Magnitude
			if gap <= Settings.MineStand + 0.9 then return true end
		end
	end
	-- Some mine layouts have non-navmesh ledges; retain the normal Humanoid
	-- MoveTo fallback rather than teleporting the character.
	humanoid:MoveTo(destination)
	return true
end

local function mineOne(node)
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or not nodeAlive(node) then return false end
	if not findPickaxe() then
		mineStatus = "Pickaxe missing · equip the game's Pickaxe"
		return false
	end
	if Settings.MineEquip and not equipPickaxe() then
		mineStatus = "could not equip Pickaxe"
		return false
	end

	local info, sizeName = nodeInfo(node)
	local position = nodeWorldPosition(node)
	if not position then return false end
	local stand = math.clamp(tonumber(info.stand) or Settings.MineStand, 2, 9)
	local away = Vector3.new(root.Position.X - position.X, 0, root.Position.Z - position.Z)
	if away.Magnitude < 0.5 then away = Vector3.new(1, 0, 0) else away = away.Unit end
	local dest = Vector3.new(position.X + away.X * stand, root.Position.Y, position.Z + away.Z * stand)
	local savedWalkSpeed = humanoid.WalkSpeed
	if not Settings.SpeedOn then humanoid.WalkSpeed = math.clamp(Settings.MineSpeed, 16, 80) end

	mineStatus = "pathing to " .. string.lower(sizeName) .. " gem"
	walkToMineStand(humanoid, root, dest, node)
	local travelStarted = os.clock()
	local nextMoveRefresh = 0
	while Settings.AutoMine and nodeAlive(node) and screenAlive() and os.clock() - travelStarted < 18 do
		task.wait(0.12)
		character = LocalPlayer.Character
		root = character and character:FindFirstChild("HumanoidRootPart")
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		position = nodeWorldPosition(node)
		if not root or not humanoid or not position then break end
		local gap = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude
		if gap <= stand + 0.9 then break end
		if os.clock() >= nextMoveRefresh then
			local awayNow = Vector3.new(root.Position.X - position.X, 0, root.Position.Z - position.Z)
			if awayNow.Magnitude < 0.5 then awayNow = Vector3.new(1, 0, 0) else awayNow = awayNow.Unit end
			dest = Vector3.new(position.X + awayNow.X * stand, root.Position.Y, position.Z + awayNow.Z * stand)
			humanoid:MoveTo(dest)
			nextMoveRefresh = os.clock() + 1.1
		end
		mineStatus = "approaching gem · " .. math.floor(gap) .. " studs"
	end
	if humanoid and humanoid.Parent then
		pcall(function() humanoid:MoveTo(root and root.Position or dest) end)
		if not Settings.SpeedOn then humanoid.WalkSpeed = savedWalkSpeed end
	end
	if not Settings.AutoMine or not nodeAlive(node) or not root or not root.Parent then return not nodeAlive(node) end

	position = nodeWorldPosition(node)
	local gap = position and (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(position.X, position.Z)).Magnitude or math.huge
	if gap > NODE_REACH then
		mineStatus = "path blocked · gem is " .. math.floor(gap) .. " studs away"
		return false
	end

	-- One accepted tap starts the game's complete timed swing sequence. If
	-- the game rejects the input (e.g. executor touch injection unsupported),
	-- retry once after the controller's catch-up window instead of sleeping
	-- through a long cooldown and silently abandoning the gem.
	local attempts = 0
	local maxAttempts = 2
	while attempts < maxAttempts and Settings.AutoMine and nodeAlive(node) and screenAlive() do
		attempts += 1
		mineStatus = "tapping " .. string.lower(sizeName) .. " gem · attempt " .. attempts .. "/" .. maxAttempts
		local tapped, tapError = tapCrystal(node)
		if not tapped then
			mineStatus = tapError or "tap failed"
			task.wait(0.8)
		else
			local waitStarted = os.clock()
			local waitLimit = math.max(configNumber("MINE_SECONDS", 6) + 2.5, 8)
			while Settings.AutoMine and nodeAlive(node) and screenAlive() and os.clock() - waitStarted < waitLimit do
				task.wait(0.18)
				mineStatus = "mining " .. string.lower(sizeName) .. " · waiting for game"
			end
			if not nodeAlive(node) then
				mineStatus = "gem mined successfully"
				return true
			end
		end
	end
	return not nodeAlive(node)
end

local function farmTick()
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then mineStatus = "no character"; return end
	for node, hl in pairs(mineMarked) do
		if not node.Parent or not hl.Parent then
			mineMarked[node] = nil
			pcall(function() hl:Destroy() end)
		end
	end
	if not (mineTarget and nodeAlive(mineTarget)) then
		mineTarget = nearestNode(root)
	end
	if not mineTarget then
		mineStatus = "no gems up · " .. NODE_COUNT .. " node slots · respawn ~" .. RESPAWN_WAIT .. "s"
		task.wait(math.min(math.max(RESPAWN_WAIT, 1), 3))
		return
	end
	if Settings.MineMark then markNode(mineTarget, true) end
	local target = mineTarget
	local broke = mineOne(target)
	markNode(target, false)
	if broke or not nodeAlive(target) then
		mineTarget = nil
		mineStatus = "gem mined · scanning next"
	else
		mineCooldown[target] = os.clock() + 2.5
		mineStatus = mineStatus .. " · retrying after short pause"
		mineTarget = nil
	end
end

task.spawn(function()
	while screenAlive() do
		if Settings.AutoMine then
			if not mineActive then
				mineActive = true
				local ok, err = pcall(farmTick)
				mineActive = false
				if not ok then
					mineStatus = "error: " .. tostring(err)
					task.wait(0.5)
				end
			else
				task.wait(0.05)
			end
		else
			if mineStatus ~= "off" then mineStatus = "off" end
			if mineTarget then markNode(mineTarget, false); mineTarget = nil end
			task.wait(0.15)
		end
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
		pcall(scanGemESP)
		pcall(updateGemESP)
		task.wait(1.25)
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

-- ================= PREMIUM HOME / WAYPOINTS / ADVANCED HUD =================
local savedWaypoint = nil
local waypointMarker = nil
local waypointBeam = nil
local hudFrame = Instance.new("Frame")
hudFrame.Name = "STORM_AdvancedHUD"
hudFrame.Size = UDim2.fromOffset(196, 88)
hudFrame.Position = UDim2.new(1, -208, 0, 18)
hudFrame.BackgroundColor3 = Theme.Bg
hudFrame.BackgroundTransparency = 0.08
hudFrame.BorderSizePixel = 0
hudFrame.Visible = Settings.AdvancedHUD
hudFrame.ZIndex = 45
hudFrame.Parent = Screen
Instance.new("UICorner", hudFrame).CornerRadius = UDim.new(0, 13)
local hudStroke = Instance.new("UIStroke", hudFrame)
hudStroke.Color = Theme.Pink
hudStroke.Thickness = 1.5
local hudTitle = Instance.new("TextLabel")
hudTitle.Size = UDim2.new(1, -12, 0, 20)
hudTitle.Position = UDim2.new(0, 8, 0, 4)
hudTitle.BackgroundTransparency = 1
hudTitle.Text = "✿ STORM  /  LIVE HUD"
hudTitle.Font = Enum.Font.GothamBlack
hudTitle.TextSize = 10
hudTitle.TextColor3 = Theme.PinkSoft
hudTitle.TextXAlignment = Enum.TextXAlignment.Left
hudTitle.ZIndex = 46
hudTitle.Parent = hudFrame
local hudText = Instance.new("TextLabel")
hudText.Size = UDim2.new(1, -16, 1, -28)
hudText.Position = UDim2.new(0, 8, 0, 25)
hudText.BackgroundTransparency = 1
hudText.Text = "HP --  |  FPS --\nNearest gem --\nPosition --"
hudText.Font = Enum.Font.GothamMedium
hudText.TextSize = 9
hudText.TextColor3 = Theme.Text
hudText.TextXAlignment = Enum.TextXAlignment.Left
hudText.TextYAlignment = Enum.TextYAlignment.Top
hudText.ZIndex = 46
hudText.Parent = hudFrame

local hudDragging, hudDragStart, hudDragOrigin = false, nil, nil
hudFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		hudDragging = true
		hudDragStart = input.Position
		hudDragOrigin = hudFrame.Position
	end
end)
track(UserInputService.InputChanged:Connect(function(input)
	if hudDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - hudDragStart
		hudFrame.Position = UDim2.new(hudDragOrigin.X.Scale, hudDragOrigin.X.Offset + delta.X, hudDragOrigin.Y.Scale, hudDragOrigin.Y.Offset + delta.Y)
	end
end))
track(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then hudDragging = false end
end))

local function clearWaypointVisual()
	if waypointBeam then pcall(function() waypointBeam:Destroy() end); waypointBeam = nil end
	if waypointMarker then pcall(function() waypointMarker:Destroy() end); waypointMarker = nil end
end

local function setWaypoint(position, labelText)
	if typeof(position) ~= "Vector3" then return end
	savedWaypoint = position
	clearWaypointVisual()
	if not Settings.SmartWaypoints then return end
	local marker = Instance.new("Part")
	marker.Name = "MYWISH_WAYPOINT"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.Shape = Enum.PartType.Cylinder
	marker.Size = Vector3.new(0.18, 4, 4)
	marker.Material = Enum.Material.Neon
	marker.Color = Theme.Pink
	marker.Transparency = 0.22
	marker.CFrame = CFrame.new(position + Vector3.new(0, 0.18, 0)) * CFrame.Angles(0, 0, math.rad(90))
	marker.Parent = Visuals
	waypointMarker = marker
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(150, 30)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = marker
	billboard.Parent = marker
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Theme.Bg
	label.BackgroundTransparency = 0.08
	label.Text = "✦ " .. (labelText or "SAVED WAYPOINT")
	label.Font = Enum.Font.GothamBold
	label.TextSize = 10
	label.TextColor3 = Theme.PinkSoft
	label.Parent = billboard
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local a0 = Instance.new("Attachment")
		a0.Name = "MYWISH_WP_FROM"
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Name = "MYWISH_WP_TO"
		a1.Parent = marker
		local beam = Instance.new("Beam")
		beam.Name = "MYWISH_WAYPOINT_BEAM"
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Width0 = 0.12
		beam.Width1 = 0.05
		beam.FaceCamera = true
		beam.Color = ColorSequence.new(Theme.PinkSoft, Theme.Rose)
		beam.Transparency = NumberSequence.new(0.12)
		beam.Parent = Visuals
		waypointBeam = beam
		marker.Destroying:Connect(function() pcall(function() a0:Destroy() end) end)
	end
end

local function walkToWaypoint(position)
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or typeof(position) ~= "Vector3" then return false end
	humanoid:MoveTo(position)
	return true
end

local function waypointNearestGem()
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local node = root and nearestNode(root)
	local position = node and nodeWorldPosition(node)
	if not position then mineStatus = "no gem available for waypoint"; return end
	setWaypoint(position, "NEAREST GEM")
	local away = Vector3.new(root.Position.X - position.X, 0, root.Position.Z - position.Z)
	if away.Magnitude < 0.5 then away = Vector3.new(1, 0, 0) else away = away.Unit end
	local _, sizeName = nodeInfo(node)
	local info = NODE_SIZES[sizeName] or { stand = 4 }
	local stand = math.clamp(tonumber(info.stand) or Settings.MineStand, 2, 9)
	local destination = Vector3.new(position.X + away.X * stand, root.Position.Y, position.Z + away.Z * stand)
	walkToWaypoint(destination)
end

local fpsValue, fpsFrames, fpsElapsed = 0, 0, 0
track(RunService.RenderStepped:Connect(function(dt)
	fpsFrames = fpsFrames + 1
	fpsElapsed = fpsElapsed + dt
	if fpsElapsed >= 0.75 then
		fpsValue = math.floor(fpsFrames / math.max(fpsElapsed, 0.01) + 0.5)
		fpsFrames, fpsElapsed = 0, 0
	end
end))
task.spawn(function()
	while screenAlive() do
		if hudFrame.Parent and hudFrame.Visible then
			local character = LocalPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local hp = humanoid and math.floor(humanoid.Health) or 0
			local gemText = "none"
			if root then
				local node = nearestNode(root)
				local pos = node and nodeWorldPosition(node)
				if pos then gemText = tostring(math.floor((pos - root.Position).Magnitude)) .. " studs" end
				hudText.Text = "HP " .. hp .. "  |  FPS " .. fpsValue .. "\nNearest gem " .. gemText .. "\nMine " .. tostring(mineStatus) .. "\nXYZ " .. math.floor(root.Position.X) .. ", " .. math.floor(root.Position.Y) .. ", " .. math.floor(root.Position.Z)
			else
				hudText.Text = "HP " .. hp .. "  |  FPS " .. fpsValue .. "\nNearest gem " .. gemText .. "\nWaiting for character"
			end
		end
		task.wait(0.3)
	end
end)

section(PageHome, "WELCOME TO MY WISH")
local hero = card(PageHome, 142)
hero.BackgroundColor3 = Color3.fromRGB(67, 39, 72)
local heroStroke = hero:FindFirstChildOfClass("UIStroke")
if heroStroke then heroStroke.Color = Theme.Pink; heroStroke.Thickness = 1.6 end
local heroTitle = Instance.new("TextLabel")
heroTitle.Size = UDim2.new(1, -100, 0, 34)
heroTitle.Position = UDim2.new(0, 12, 0, 14)
heroTitle.BackgroundTransparency = 1
heroTitle.Text = "MY WISH"
heroTitle.Font = Enum.Font.GothamBlack
heroTitle.TextSize = 24
heroTitle.TextColor3 = Theme.White
heroTitle.TextXAlignment = Enum.TextXAlignment.Left
heroTitle.Parent = hero
local heroMade = Instance.new("TextLabel")
heroMade.Size = UDim2.new(1, -105, 0, 22)
heroMade.Position = UDim2.new(0, 13, 0, 49)
heroMade.BackgroundTransparency = 1
heroMade.Text = "MADE BY STORM"
heroMade.Font = Enum.Font.GothamBlack
heroMade.TextSize = 13
heroMade.TextColor3 = Theme.PinkSoft
heroMade.TextXAlignment = Enum.TextXAlignment.Left
heroMade.Parent = hero
local heroSub = Instance.new("TextLabel")
heroSub.Size = UDim2.new(1, -105, 0, 30)
heroSub.Position = UDim2.new(0, 13, 0, 76)
heroSub.BackgroundTransparency = 1
heroSub.Text = "Cherry blossom edition\nTavern Town mobile suite"
heroSub.Font = Enum.Font.Gotham
heroSub.TextSize = 9
heroSub.TextColor3 = Theme.Dim
heroSub.TextXAlignment = Enum.TextXAlignment.Left
heroSub.TextYAlignment = Enum.TextYAlignment.Top
heroSub.Parent = hero

-- A soft white bunny silhouette that hops at the bottom of the home card.
local bunny = Instance.new("Frame")
bunny.Name = "StormBunny"
bunny.Size = UDim2.fromOffset(76, 70)
bunny.Position = UDim2.new(1, -91, 0, 53)
bunny.BackgroundTransparency = 1
bunny.Parent = hero
local bunnyBody = Instance.new("Frame")
bunnyBody.Size = UDim2.fromOffset(43, 31)
bunnyBody.Position = UDim2.fromOffset(16, 31)
bunnyBody.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
bunnyBody.BorderSizePixel = 0
bunnyBody.Parent = bunny
Instance.new("UICorner", bunnyBody).CornerRadius = UDim.new(1, 0)
for i = 1, 5 do
	local puff = Instance.new("Frame")
	puff.Size = UDim2.fromOffset(18, 18)
	puff.Position = UDim2.fromOffset(14 + (i - 1) * 7, 27 + (i % 2) * 6)
	puff.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	puff.BorderSizePixel = 0
	puff.Parent = bunny
	Instance.new("UICorner", puff).CornerRadius = UDim.new(1, 0)
end
local bunnyHead = Instance.new("Frame")
bunnyHead.Size = UDim2.fromOffset(31, 29)
bunnyHead.Position = UDim2.fromOffset(36, 17)
bunnyHead.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
bunnyHead.BorderSizePixel = 0
bunnyHead.Parent = bunny
Instance.new("UICorner", bunnyHead).CornerRadius = UDim.new(1, 0)
for i, x in ipairs({ 39, 54 }) do
	local ear = Instance.new("Frame")
	ear.Size = UDim2.fromOffset(9, 26)
	ear.Position = UDim2.fromOffset(x, 0)
	ear.Rotation = i == 1 and -13 or 12
	ear.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ear.BorderSizePixel = 0
	ear.Parent = bunny
	Instance.new("UICorner", ear).CornerRadius = UDim.new(1, 0)
	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(0.42, 0, 0.68, 0)
	inner.Position = UDim2.new(0.29, 0, 0.15, 0)
	inner.BackgroundColor3 = Color3.fromRGB(255, 190, 215)
	inner.BorderSizePixel = 0
	inner.Parent = ear
	Instance.new("UICorner", inner).CornerRadius = UDim.new(1, 0)
end
local bunnyTail = Instance.new("Frame")
bunnyTail.Size = UDim2.fromOffset(16, 16)
bunnyTail.Position = UDim2.fromOffset(7, 37)
bunnyTail.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
bunnyTail.BorderSizePixel = 0
bunnyTail.Parent = bunny
Instance.new("UICorner", bunnyTail).CornerRadius = UDim.new(1, 0)
for _, x in ipairs({ 23, 46 }) do
	local eye = Instance.new("Frame")
	eye.Size = UDim2.fromOffset(3, 4)
	eye.Position = UDim2.fromOffset(x, 28)
	eye.BackgroundColor3 = Theme.Ink
	eye.BorderSizePixel = 0
	eye.Parent = bunny
	Instance.new("UICorner", eye).CornerRadius = UDim.new(1, 0)
end
local bunnyHop = TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
task.spawn(function()
	while screenAlive() and bunny.Parent do
		local up = TweenService:Create(bunny, bunnyHop, { Position = UDim2.new(1, -91, 0, 43) })
		up:Play(); up.Completed:Wait()
		local down = TweenService:Create(bunny, TweenInfo.new(0.28, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { Position = UDim2.new(1, -91, 0, 53) })
		down:Play(); down.Completed:Wait()
		task.wait(0.35)
	end
end)


local bunnyGarden = card(PageHome, 56)
bunnyGarden.BackgroundColor3 = Color3.fromRGB(61, 39, 69)
local gardenTitle = Instance.new("TextLabel")
gardenTitle.Size = UDim2.new(1, -12, 0, 14)
gardenTitle.Position = UDim2.fromOffset(8, 3)
gardenTitle.BackgroundTransparency = 1
gardenTitle.Text = "STORM'S LITTLE BUNNY GARDEN"
gardenTitle.Font = Enum.Font.GothamBold
gardenTitle.TextSize = 8
gardenTitle.TextColor3 = Theme.PinkSoft
gardenTitle.TextXAlignment = Enum.TextXAlignment.Left
gardenTitle.Parent = bunnyGarden
for i = 1, 3 do
	local mini = Instance.new("TextLabel")
	mini.Name = "BunnyHop_" .. i
	mini.Size = UDim2.fromOffset(42, 34)
	mini.Position = UDim2.new(0, 22 + (i - 1) * 62, 0, 18)
	mini.BackgroundTransparency = 1
	mini.Text = "🐇"
	mini.Font = Enum.Font.GothamBold
	mini.TextSize = i == 2 and 25 or 22
	mini.TextColor3 = Color3.fromRGB(255, 255, 255)
	mini.Parent = bunnyGarden
	task.spawn(function()
		while screenAlive() and mini.Parent do
			local baseX = 22 + (i - 1) * 62
			local up = TweenService:Create(mini, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0, baseX, 0, 13) })
			up:Play(); up.Completed:Wait()
			local down = TweenService:Create(mini, TweenInfo.new(0.32, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { Position = UDim2.new(0, baseX, 0, 18) })
			down:Play(); down.Completed:Wait()
			task.wait(0.12 + i * 0.16)
		end
	end)
end

section(PageHome, "QUICK ACCESS")
addToggle(PageHome, "Advanced live HUD", function() return Settings.AdvancedHUD end, function(value)
	Settings.AdvancedHUD = value
	hudFrame.Visible = value
end)
addToggle(PageHome, "Smart waypoint visuals", function() return Settings.SmartWaypoints end, function(value)
	Settings.SmartWaypoints = value
	if not value then clearWaypointVisual() end
end)
addToggle(PageHome, "Auto-face gem before tapping", function() return Settings.AutoFaceGem end, function(value)
	Settings.AutoFaceGem = value
end)
addButton(PageHome, "Open gem mining", function() selectTab("Mine") end)
addButton(PageHome, "Waypoint to nearest gem", waypointNearestGem)
addButton(PageHome, "Save current position", function()
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if root then setWaypoint(root.Position, "SAVED SPOT") end
end)
addButton(PageHome, "Walk to saved waypoint", function()
	if savedWaypoint then walkToWaypoint(savedWaypoint) end
end)
addButton(PageHome, "Clear waypoint", function() savedWaypoint = nil; clearWaypointVisual() end)


-- Dedicated controls so the advanced HUD and waypoint tools are easy to find.
section(PagePath, "SMART WAYPOINTS")
addToggle(PagePath, "Enable waypoint marker + beam", function() return Settings.SmartWaypoints end, function(value)
	Settings.SmartWaypoints = value
	if not value then clearWaypointVisual() elseif savedWaypoint then setWaypoint(savedWaypoint, "SAVED WAYPOINT") end
end)
addButton(PagePath, "Mark nearest gem", waypointNearestGem)
addButton(PagePath, "Save my current position", function()
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if root then setWaypoint(root.Position, "SAVED SPOT") end
end)
addButton(PagePath, "Walk to saved waypoint", function()
	if savedWaypoint then walkToWaypoint(savedWaypoint) else Footer.Text = "save a waypoint first" end
end)
addButton(PagePath, "Clear waypoint", function()
	savedWaypoint = nil
	clearWaypointVisual()
end)

section(PageHud, "ADVANCED LIVE HUD")
addToggle(PageHud, "Show floating status HUD", function() return Settings.AdvancedHUD end, function(value)
	Settings.AdvancedHUD = value
	hudFrame.Visible = value
end)
addButton(PageHud, "Move HUD to top-right", function()
	hudFrame.Position = UDim2.new(1, -208, 0, 18)
end)
addButton(PageHud, "Move HUD to bottom-right", function()
	hudFrame.Position = UDim2.new(1, -208, 1, -112)
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

section(PageMine, "GEM ESP")
addToggle(PageMine, "Gem ESP", function()
	return Settings.GemESP
end, function(value)
	Settings.GemESP = value
	if not value then
		for node in pairs(GemEntries) do clearGemEntry(node) end
	else
		pcall(scanGemESP)
	end
end)
addSlider(PageMine, "Gem ESP distance", 50, 1500, function()
	return Settings.GemESPDistance
end, function(value)
	Settings.GemESPDistance = value
	for _, entry in pairs(GemEntries) do
		entry.billboard.MaxDistance = value
	end
end)
addButton(PageMine, "Refresh gem ESP", function()
	pcall(scanGemESP)
	pcall(updateGemESP)
end)
addButton(PageMine, "Smart waypoint to nearest gem", waypointNearestGem)

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
	mineTarget = nil
	clearMarks()
	if value then
		mineStatus = "checking Pickaxe and scanning gems"
		task.spawn(function()
			local pickaxe = findPickaxe()
			if not pickaxe then
				mineStatus = "Pickaxe missing · enter the gem mine"
			elseif Settings.MineEquip then
				pcall(equipPickaxe)
			end
		end)
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
	task.spawn(function()
		pcall(function()
			local character = LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local part = root and nearestNode(root)
			if not part then
				mineStatus = "no gems up"
				return
			end
			mineStatus = "one shot"
			mineOne(part)
			mineStatus = "done"
		end)
	end)
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
mineNote.Text = "AUTO MINE now targets the actual tagged crystal Model + NodeId, equips the exact Pickaxe, walks into the game's stand-off range, then sends a screen tap so Tavern Town's own MineController handles the mining request. If Delta blocks virtual touch input, use the manual tap fallback. No direct reward or remote spoofing is used."
mineNote.Parent = PageMine

-- A draggable cherry-blossom launcher (five soft petals around a centre).
local Bubble = Instance.new("TextButton")
Bubble.Name = "BlossomLauncher"
Bubble.Size = UDim2.fromOffset(62, 62)
Bubble.Position = UDim2.new(0, 14, 0.72, 0)
Bubble.BackgroundTransparency = 1
Bubble.Text = ""
Bubble.Visible = false
Bubble.ZIndex = 60
Bubble.AutoButtonColor = false
Bubble.Parent = Screen

for i = 1, 5 do
	local petal = Instance.new("Frame")
	petal.Name = "Petal" .. i
	petal.Size = UDim2.fromOffset(27, 34)
	petal.AnchorPoint = Vector2.new(0.5, 0.5)
	petal.Position = UDim2.fromScale(0.5, 0.5)
	local angle = math.rad((i - 1) * 72 - 90)
	petal.Position = UDim2.new(0.5, math.cos(angle) * 13, 0.5, math.sin(angle) * 13)
	petal.Rotation = math.deg(angle) + 90
	petal.BackgroundColor3 = Color3.fromRGB(255, 190, 218)
	petal.BorderSizePixel = 0
	petal.ZIndex = 60
	petal.Parent = Bubble
	Instance.new("UICorner", petal).CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke", petal)
	stroke.Color = Color3.fromRGB(255, 245, 250)
	stroke.Thickness = 1.5
end
local flowerCentre = Instance.new("Frame")
flowerCentre.Size = UDim2.fromOffset(20, 20)
flowerCentre.AnchorPoint = Vector2.new(0.5, 0.5)
flowerCentre.Position = UDim2.fromScale(0.5, 0.5)
flowerCentre.BackgroundColor3 = Color3.fromRGB(255, 238, 174)
flowerCentre.BorderSizePixel = 0
flowerCentre.ZIndex = 62
flowerCentre.Parent = Bubble
Instance.new("UICorner", flowerCentre).CornerRadius = UDim.new(1, 0)
local centreStroke = Instance.new("UIStroke", flowerCentre)
centreStroke.Color = Color3.fromRGB(255, 255, 255)
centreStroke.Thickness = 2

CloseButton.MouseButton1Click:Connect(function()
	Window.Visible = false
	Bubble.Visible = true
end)
Bubble.MouseButton1Click:Connect(function()
	Bubble.Visible = false
	Window.Visible = true
end)

-- Touch/mouse drag for the mini flower. A short tap still reopens the panel.
local bubbleDrag = nil
Bubble.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		bubbleDrag = { input = input, start = input.Position, origin = Bubble.Position, moved = false }
	end
end)
track(UserInputService.InputChanged:Connect(function(input)
	if bubbleDrag and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - bubbleDrag.start
		if delta.Magnitude > 7 then
			bubbleDrag.moved = true
		end
		Bubble.Position = UDim2.new(bubbleDrag.origin.X.Scale, bubbleDrag.origin.X.Offset + delta.X, bubbleDrag.origin.Y.Scale, bubbleDrag.origin.Y.Offset + delta.Y)
	end
end))
track(UserInputService.InputEnded:Connect(function(input)
	if bubbleDrag and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
		local moved = bubbleDrag.moved
		bubbleDrag = nil
		if moved then
			-- Suppress the click generated at the end of a drag.
			Bubble.Active = false
			task.defer(function()
				if Bubble.Parent then Bubble.Active = true end
			end)
		end
	end
end))

local draggingWindow = false
local dragStart = nil
local dragOrigin = nil
local dragInputObject = nil
Header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if input.Position.X >= CloseButton.AbsolutePosition.X then
			return
		end
		draggingWindow = true
		dragInputObject = input
		dragStart = input.Position
		dragOrigin = Window.Position
	end
end)
track(UserInputService.InputChanged:Connect(function(input)
	if draggingWindow and (input == dragInputObject or input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		Window.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + delta.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + delta.Y)
	end
end))
track(UserInputService.InputEnded:Connect(function(input)
	if input == dragInputObject or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingWindow = false
		dragInputObject = nil
	end
end))

task.spawn(function()
	while Screen.Parent do
		local count = 0
		for _ in pairs(AnimalEntries) do
			count = count + 1
		end
		Footer.Text = "STORM  ✿  animals " .. count .. "   aim " .. aimStatus .. "   mine " .. mineStatus
		if mineStatusLabel and mineStatusLabel.Parent then
			if Settings.AutoMine then
				mineStatusLabel.Text = mineStatus .. "\n" .. (mineTarget and "gem locked" or "scanning for next gem")
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
	clearMarks()
	clearWaypointVisual()
	for node in pairs(GemEntries) do clearGemEntry(node) end
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
		hudFrame:Destroy()
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
	dim.BackgroundColor3 = Color3.fromRGB(40, 20, 35)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.Parent = intro
	TweenService:Create(dim, TweenInfo.new(0.3), { BackgroundTransparency = 0.4 }):Play()

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.46)
	card.Size = UDim2.fromOffset(226, 214)
	card.BackgroundColor3 = Theme.Snow
	card.BorderSizePixel = 0
	card.Parent = intro
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 24)
	local cardStroke = Instance.new("UIStroke", card)
	cardStroke.Color = Theme.PinkSoft
	cardStroke.Thickness = 3

	local function ear(x, rotation)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromOffset(20, 48)
		frame.Position = UDim2.new(0.5, x, 0, 8)
		frame.Rotation = rotation
		frame.BackgroundColor3 = Theme.Bunny
		frame.BorderSizePixel = 0
		frame.Parent = card
		Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)
		local inner = Instance.new("Frame")
		inner.Size = UDim2.new(0.42, 0, 0.5, 0)
		inner.Position = UDim2.new(0.29, 0, 0.28, 0)
		inner.BackgroundColor3 = Theme.PinkSoft
		inner.BorderSizePixel = 0
		inner.Parent = frame
		Instance.new("UICorner", inner).CornerRadius = UDim.new(1, 0)
	end
	ear(-40, -12)
	ear(18, 12)

	-- Soft fluffy body, cheeks and paws make the intro read as a bunny silhouette.
	local body = Instance.new("Frame")
	body.Size = UDim2.fromOffset(92, 66)
	body.Position = UDim2.new(0.5, -46, 0, 86)
	body.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	body.BorderSizePixel = 0
	body.Parent = card
	Instance.new("UICorner", body).CornerRadius = UDim.new(1, 0)
	for i = 1, 7 do
		local puff = Instance.new("Frame")
		puff.Size = UDim2.fromOffset(25, 25)
		puff.Position = UDim2.new(0, (i - 1) * 11, 0, (i % 2 == 0) and 0 or 7)
		puff.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		puff.BorderSizePixel = 0
		puff.Parent = body
		Instance.new("UICorner", puff).CornerRadius = UDim.new(1, 0)
	end
	local tail = Instance.new("Frame")
	tail.Size = UDim2.fromOffset(24, 24)
	tail.Position = UDim2.new(1, -10, 0.5, 2)
	tail.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	tail.BorderSizePixel = 0
	tail.Parent = body
	Instance.new("UICorner", tail).CornerRadius = UDim.new(1, 0)
	local head = Instance.new("Frame")
	head.Size = UDim2.fromOffset(84, 72)
	head.Position = UDim2.new(0.5, -42, 0, 48)
	head.BackgroundColor3 = Theme.Bunny
	head.BorderSizePixel = 0
	head.Parent = card
	Instance.new("UICorner", head).CornerRadius = UDim.new(1, 0)

	local function eye(x)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromOffset(10, 12)
		frame.Position = UDim2.new(0.5, x, 0.32, 0)
		frame.BackgroundColor3 = Theme.Ink
		frame.BorderSizePixel = 0
		frame.Parent = head
		Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)
	end
	eye(-20)
	eye(8)
	for _, x in ipairs({ -31, 21 }) do
		local cheek = Instance.new("Frame")
		cheek.Size = UDim2.fromOffset(18, 10)
		cheek.Position = UDim2.new(0.5, x, 0.58, 0)
		cheek.BackgroundColor3 = Color3.fromRGB(255, 205, 222)
		cheek.BackgroundTransparency = 0.18
		cheek.BorderSizePixel = 0
		cheek.Parent = head
		Instance.new("UICorner", cheek).CornerRadius = UDim.new(1, 0)
	end

	local smile = Instance.new("TextLabel")
	smile.Size = UDim2.fromOffset(30, 16)
	smile.Position = UDim2.new(0.5, -15, 0.58, 0)
	smile.BackgroundTransparency = 1
	smile.Text = "ᴗ"
	smile.Font = Enum.Font.GothamBold
	smile.TextSize = 16
	smile.TextColor3 = Theme.Ink
	smile.Parent = head

	local wish = Instance.new("TextLabel")
	wish.Size = UDim2.new(1, -12, 0, 28)
	wish.Position = UDim2.new(0, 6, 1, -46)
	wish.BackgroundTransparency = 1
	wish.Text = "MY WISH"
	wish.Font = Enum.Font.GothamBlack
	wish.TextSize = 22
	wish.TextColor3 = Theme.PinkDeep
	wish.Parent = card

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -12, 0, 16)
	sub.Position = UDim2.new(0, 6, 1, -20)
	sub.BackgroundTransparency = 1
	sub.Text = "MADE BY STORM  ·  snow bunny says hi"
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 9
	sub.TextColor3 = Theme.Dim
	sub.Parent = card

	task.wait(1.7)
	TweenService:Create(dim, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	task.wait(0.28)
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

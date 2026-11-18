--[[
    MY WISH
    Tavern Town | Delta | mobile
    One window for hunting and fishing.

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

    Fish
        a bite shows a HOOK button
        the first tap hooks the fish
        after that, tapping HOOK moves the wheel marker
        AUTO REEL keeps tapping that button so the marker stays in the green
        if the green zone cannot be read, it mashes instead of stopping
        that is what stops the line from snapping
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
	Bg = Color3.fromRGB(255, 236, 245),
	Bg2 = Color3.fromRGB(255, 220, 235),
	Bg3 = Color3.fromRGB(255, 200, 225),
	Card = Color3.fromRGB(255, 245, 250),
	Pink = Color3.fromRGB(255, 150, 190),
	PinkSoft = Color3.fromRGB(255, 190, 215),
	PinkDeep = Color3.fromRGB(240, 110, 165),
	Rose = Color3.fromRGB(255, 105, 155),
	Text = Color3.fromRGB(90, 50, 70),
	Dim = Color3.fromRGB(150, 110, 130),
	White = Color3.fromRGB(255, 255, 255),
	Line = Color3.fromRGB(255, 170, 200),
	Good = Color3.fromRGB(120, 210, 160),
	HitRed = Color3.fromRGB(255, 70, 90),
	Player = Color3.fromRGB(130, 180, 255),
	PlayerSoft = Color3.fromRGB(170, 205, 255),
	Friend = Color3.fromRGB(255, 140, 185),
	FriendSoft = Color3.fromRGB(255, 180, 210),
	Snow = Color3.fromRGB(255, 252, 255),
	Bunny = Color3.fromRGB(255, 248, 252),
	Ink = Color3.fromRGB(55, 40, 55),
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
	AutoReel = false,
	ReelSmart = true,
	ReelRate = 26,
	ReelHold = 0.4,
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

local FishingConfig = nil
pcall(function()
	FishingConfig = require(ReplicatedStorage.Shared.Config.Fishing)
end)

-- The window is built before ESP, aim, or fishing.
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
Title.Text = "MY WISH"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 15
Title.TextColor3 = Theme.PinkDeep
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
local PageFish = makePage("Fish")
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

-- AUTO REEL
-- Tavern Town shows a HOOK button when a fish bites.
-- The first tap hooks it. After that the wheel is up and every tap on
-- that same HOOK button moves the marker. If the marker leaves the green,
-- the line snaps. So while the button is on screen this loop taps it.
-- If the green zone can be read, taps slow down inside it so the marker
-- does not fly past. If the zone cannot be read, it mashes. Mashing is
-- the fallback that actually keeps the fish on.

local fishPhase = "off"
local fishZone = "idle"
local hookButton = nil
local lockedHook = nil
local armLock = false
local lastReelTap = 0
local tapMethod = "all"
local fishRemote = nil
local castId = nil
local hookedThisBite = false
local reelSamples = 0
local reelAxis = nil
local reelSign = 1
local lastMarkerPos = nil
local fishStatusLabel = nil
local lockButton = nil

local function rodOut()
	local character = LocalPlayer.Character
	if not character then
		return false
	end
	if FishingConfig and FishingConfig.ROD and character:FindFirstChild(FishingConfig.ROD) then
		return true
	end
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			local name = string.lower(tool.Name)
			if string.find(name, "rod", 1, true) or string.find(name, "fish", 1, true) then
				return true
			end
		end
	end
	return false
end

local function buttonAlive(object)
	if not object or not object.Parent then
		return false
	end
	if not object:IsA("GuiObject") or not object.Visible then
		return false
	end
	local node = object
	while node do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		if node:IsA("ScreenGui") and not node.Enabled then
			return false
		end
		node = node.Parent
	end
	return object.AbsoluteSize.X > 12 and object.AbsoluteSize.Y > 12
end

local function buttonText(object)
	local text = string.lower(object.Name or "")
	if object:IsA("TextButton") or object:IsA("TextLabel") then
		text = text .. " " .. string.lower(object.Text or "")
	end
	for _, child in ipairs(object:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			text = text .. " " .. string.lower(child.Text or "")
		end
		text = text .. " " .. string.lower(child.Name or "")
	end
	return text
end

local function isHookButton(object)
	local text = buttonText(object)
	if string.find(text, "hook", 1, true) then
		return true
	end
	if string.find(text, "reel", 1, true) then
		return true
	end
	return false
end

local function findHookButton()
	if buttonAlive(lockedHook) then
		hookButton = lockedHook
		return lockedHook
	end
	if buttonAlive(hookButton) and isHookButton(hookButton) then
		return hookButton
	end
	hookButton = nil
	local best, bestScore = nil, 0
	local roots = { PlayerGui }
	pcall(function()
		if gethui then
			table.insert(roots, gethui())
		end
	end)
	pcall(function()
		table.insert(roots, game:GetService("CoreGui"))
	end)
	for _, root in ipairs(roots) do
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("GuiButton") and buttonAlive(desc) and isHookButton(desc) and not desc:IsDescendantOf(Screen) then
				local score = desc.AbsoluteSize.X * desc.AbsoluteSize.Y
				if score > bestScore then
					bestScore = score
					best = desc
				end
			end
		end
	end
	hookButton = best
	return best
end

local function colorLooksGreen(color)
	return color.G > 0.42 and color.G > color.R + 0.08 and color.G > color.B * 0.85
end

local function findGreenAndMarker(button)
	local gui = button and button:FindFirstAncestorOfClass("ScreenGui")
	if not gui then
		return nil, nil
	end
	local green = nil
	for _, desc in ipairs(gui:GetDescendants()) do
		if desc:IsA("GuiObject") and desc.Visible and desc ~= button and not desc:IsDescendantOf(button) then
			local name = string.lower(desc.Name)
			local named = string.find(name, "green", 1, true)
				or string.find(name, "zone", 1, true)
				or string.find(name, "safe", 1, true)
				or string.find(name, "sweet", 1, true)
			local color = desc.BackgroundColor3
			if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
				color = desc.ImageColor3
			end
			local painted = desc.BackgroundTransparency < 0.55 and colorLooksGreen(color)
			if (named or painted) and desc.AbsoluteSize.X > 8 and desc.AbsoluteSize.Y > 8 then
				green = desc
				break
			end
		end
	end
	local marker = nil
	local bestMove = 0
	for _, desc in ipairs(gui:GetDescendants()) do
		if desc:IsA("GuiObject") and desc.Visible and desc ~= button and desc ~= green and not desc:IsDescendantOf(button) then
			if not (green and desc:IsDescendantOf(green)) then
				local size = desc.AbsoluteSize
				if size.X >= 4 and size.Y >= 4 and size.X < 80 and size.Y < 80 then
					local name = string.lower(desc.Name)
					local named = string.find(name, "marker", 1, true)
						or string.find(name, "fish", 1, true)
						or string.find(name, "cursor", 1, true)
						or string.find(name, "needle", 1, true)
						or string.find(name, "knob", 1, true)
						or string.find(name, "bobber", 1, true)
					local moved = 0
					if lastMarkerPos and lastMarkerPos.object == desc then
						moved = (desc.AbsolutePosition - lastMarkerPos.pos).Magnitude
					end
					if named then
						marker = desc
						break
					end
					if moved > bestMove then
						bestMove = moved
						marker = desc
					end
				end
			end
		end
	end
	if marker then
		lastMarkerPos = { object = marker, pos = marker.AbsolutePosition }
	end
	return green, marker
end

local function tapOnce(button, method)
	if not buttonAlive(button) then
		return false
	end
	local point = button.AbsolutePosition + button.AbsoluteSize * 0.5
	local screenY = point.Y + GuiService:GetGuiInset().Y
	if method == "conn" or method == "all" then
		pcall(function()
			if getconnections then
				for _, signalName in ipairs({ "MouseButton1Down", "MouseButton1Click", "Activated" }) do
					local signal = button[signalName]
					if typeof(signal) == "RBXScriptSignal" then
						for _, connection in ipairs(getconnections(signal)) do
							pcall(function()
								connection:Fire()
							end)
						end
					end
				end
			end
		end)
		if method == "conn" then
			return true
		end
	end
	if method == "signal" or method == "all" then
		pcall(function()
			if firesignal then
				firesignal(button.MouseButton1Down)
				firesignal(button.MouseButton1Click)
				firesignal(button.Activated)
			end
		end)
		if method == "signal" then
			return true
		end
	end
	if method == "activate" or method == "all" then
		pcall(function()
			button:Activate()
		end)
		if method == "activate" then
			return true
		end
	end
	if method == "vim" or method == "all" then
		pcall(function()
			if VirtualInput then
				VirtualInput:SendMouseButtonEvent(point.X, screenY, 0, true, game, 0)
				VirtualInput:SendMouseButtonEvent(point.X, screenY, 0, false, game, 0)
				VirtualInput:SendTouchEvent(11, Enum.UserInputState.Begin, point.X, screenY)
				VirtualInput:SendTouchEvent(11, Enum.UserInputState.End, point.X, screenY)
			elseif mouse1click then
				mouse1click(point.X, screenY)
			end
		end)
		if method == "vim" then
			return true
		end
	end
	if method == "user" or method == "all" then
		pcall(function()
			VirtualUser:Button1Down(Vector2.new(point.X, screenY))
			VirtualUser:Button1Up(Vector2.new(point.X, screenY))
		end)
	end
	return true
end

local function fireHookRemote()
	if not fishRemote then
		return
	end
	pcall(function()
		if castId ~= nil then
			fishRemote:FireServer("Hook", castId)
		else
			fishRemote:FireServer("Hook")
		end
	end)
end

local function noteFish(remote, args)
	local kind, id = nil, nil
	for _, arg in ipairs(args) do
		if type(arg) == "string" then
			local lower = string.lower(arg)
			if lower == "bite" or lower == "nibble" or string.find(lower, "bite", 1, true) then
				kind = "bite"
			elseif lower == "caught" or lower == "lost" or lower == "miss" or lower == "snap" or lower == "break" then
				kind = "done"
			end
		elseif type(arg) == "number" and arg > 0 and arg < 1e12 then
			id = arg
		end
	end
	if kind == "bite" then
		fishRemote = remote
		if id then
			castId = id
		end
		if not hookedThisBite then
			hookedThisBite = true
			fireHookRemote()
			fishPhase = "BITE"
			local button = findHookButton()
			if button then
				tapOnce(button, "all")
				lastReelTap = os.clock()
			end
		end
	elseif kind == "done" then
		hookedThisBite = false
		fishPhase = kind
		reelSamples = 0
		reelAxis = nil
	end
end

local function watchRemote(remote)
	if not remote or not remote:IsA("RemoteEvent") then
		return
	end
	local full = string.lower(remote:GetFullName())
	if not (string.find(full, "fish", 1, true) or string.find(full, "reel", 1, true) or string.find(full, "hook", 1, true)) then
		return
	end
	track(remote.OnClientEvent:Connect(function(...)
		noteFish(remote, { ... })
	end))
end

pcall(function()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local net = shared and shared:FindFirstChild("Net")
	if net then
		local remotes = net:FindFirstChild("Remotes")
		if remotes then
			local direct = remotes:FindFirstChild("Fish") or remotes:FindFirstChild("Fishing")
			if direct and direct:IsA("RemoteEvent") then
				fishRemote = direct
				watchRemote(direct)
			end
		end
		for _, desc in ipairs(net:GetDescendants()) do
			if desc:IsA("RemoteEvent") then
				watchRemote(desc)
			end
		end
	end
end)
pcall(function()
	local net = require(ReplicatedStorage.Shared.Net)
	if type(net) == "table" then
		for _, key in ipairs({ "Fish", "Fishing", "Reel" }) do
			local value = net[key]
			if typeof(value) == "Instance" and value:IsA("RemoteEvent") then
				fishRemote = fishRemote or value
				watchRemote(value)
			end
		end
	end
end)

local function shouldTap(button)
	if not Settings.ReelSmart then
		fishZone = "mash"
		return true, 1
	end
	local green, marker = findGreenAndMarker(button)
	if not green or not marker then
		fishZone = "no zone · mash"
		return true, 1
	end
	local center = marker.AbsolutePosition + marker.AbsoluteSize * 0.5
	local startPos = green.AbsolutePosition
	local endPos = startPos + green.AbsoluteSize
	local inside = center.X >= startPos.X and center.X <= endPos.X and center.Y >= startPos.Y and center.Y <= endPos.Y
	if lastMarkerPos and lastMarkerPos.object == marker and (os.clock() - lastReelTap) < 0.16 then
		local delta = center - (lastMarkerPos.pos + marker.AbsoluteSize * 0.5)
		if math.abs(delta.X) >= math.abs(delta.Y) and math.abs(delta.X) > 0.4 then
			reelAxis = "X"
			reelSign = delta.X > 0 and 1 or -1
			reelSamples = reelSamples + 1
		elseif math.abs(delta.Y) > 0.4 then
			reelAxis = "Y"
			reelSign = delta.Y > 0 and 1 or -1
			reelSamples = reelSamples + 1
		end
	end
	if inside then
		fishZone = "in green"
		return true, Settings.ReelHold
	end
	if reelSamples >= 3 and reelAxis then
		local mid = reelAxis == "X" and (startPos.X + endPos.X) * 0.5 or (startPos.Y + endPos.Y) * 0.5
		local value = reelAxis == "X" and center.X or center.Y
		local behind = (value - mid) * reelSign < 0
		if behind then
			fishZone = "behind · tap"
			return true, 1
		end
		fishZone = "ahead · ease"
		return true, Settings.ReelHold
	end
	fishZone = "out · mash"
	return true, 1
end

task.spawn(function()
	while Screen.Parent do
		if Settings.AutoReel then
			local ok = pcall(function()
				if not rodOut() then
					fishPhase = "no rod"
					fishZone = "equip rod"
					return
				end
				local button = findHookButton()
				if not button then
					if fishPhase ~= "BITE" then
						fishPhase = "waiting HOOK"
					end
					fishZone = "cast, then wait for HOOK"
					return
				end
				fishPhase = "REEL"
				local doTap, scale = shouldTap(button)
				local rate = math.max(8, Settings.ReelRate * (scale or 1))
				if doTap and (os.clock() - lastReelTap) >= (1 / rate) then
					tapOnce(button, tapMethod)
					lastReelTap = os.clock()
					if not hookedThisBite then
						fireHookRemote()
						hookedThisBite = true
					end
				end
			end)
			if not ok then
				fishPhase = "reel error"
			end
		else
			fishPhase = "off"
		end
		task.wait(0.02)
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

section(PageFish, "AUTO REEL")
fishStatusLabel = Instance.new("TextLabel")
fishStatusLabel.Size = UDim2.new(1, -2, 0, 32)
fishStatusLabel.BackgroundTransparency = 1
fishStatusLabel.Text = "off"
fishStatusLabel.Font = Enum.Font.GothamBold
fishStatusLabel.TextSize = 12
fishStatusLabel.TextColor3 = Theme.PinkDeep
fishStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
fishStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
fishStatusLabel.Parent = PageFish

addToggle(PageFish, "AUTO REEL", function()
	return Settings.AutoReel
end, function(value)
	Settings.AutoReel = value
	hookedThisBite = false
	lastReelTap = 0
end)
addToggle(PageFish, "Hold inside the green", function()
	return Settings.ReelSmart
end, function(value)
	Settings.ReelSmart = value
	reelSamples = 0
end)
addSlider(PageFish, "Taps per second", 10, 40, function()
	return Settings.ReelRate
end, function(value)
	Settings.ReelRate = value
end)

local methodNames = { "all", "conn", "signal", "activate", "vim", "user" }
local methodIndex = 1
local methodButton = addButton(PageFish, "Tap method  all", function()
	methodIndex = methodIndex % #methodNames + 1
	tapMethod = methodNames[methodIndex]
	methodButton.Text = "Tap method  " .. tapMethod
end)

lockButton = addButton(PageFish, "Lock HOOK, then tap it", function()
	armLock = true
	lockButton.Text = "now tap the real HOOK"
end)
addButton(PageFish, "Tap HOOK once", function()
	local button = findHookButton()
	if button then
		tapOnce(button, "all")
		fireHookRemote()
		fishStatusLabel.Text = "tapped " .. button.Name
	else
		fishStatusLabel.Text = "HOOK is not on screen"
	end
end)

local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -2, 0, 52)
note.BackgroundTransparency = 1
note.Font = Enum.Font.Gotham
note.TextSize = 10
note.TextColor3 = Theme.Dim
note.TextWrapped = true
note.TextXAlignment = Enum.TextXAlignment.Left
note.TextYAlignment = Enum.TextYAlignment.Top
note.Text = "Equip the rod and cast. Turn AUTO REEL on. When HOOK shows, it taps that button so the marker stays in the green. If it misses the button, press Lock HOOK and tap the real one."
note.Parent = PageFish

local Bubble = Instance.new("ImageButton")
Bubble.Name = "RoseBubble"
Bubble.Size = UDim2.fromOffset(50, 50)
Bubble.Position = UDim2.new(0, 10, 0.74, 0)
Bubble.BackgroundColor3 = Theme.Pink
Bubble.Image = ROSE_IMAGE
Bubble.ScaleType = Enum.ScaleType.Fit
Bubble.Visible = false
Bubble.ZIndex = 60
Bubble.Parent = Screen
Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1, 0)

CloseButton.MouseButton1Click:Connect(function()
	Window.Visible = false
	Bubble.Visible = true
end)
Bubble.MouseButton1Click:Connect(function()
	Bubble.Visible = false
	Window.Visible = true
end)

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
	if not armLock then
		return
	end
	local hits = {}
	pcall(function()
		hits = PlayerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
	end)
	for _, object in ipairs(hits) do
		if object:IsA("GuiButton") and not object:IsDescendantOf(Screen) then
			lockedHook = object
			hookButton = object
			armLock = false
			lockButton.Text = "locked " .. object.Name
			return
		end
	end
	armLock = false
	lockButton.Text = "Lock HOOK, then tap it"
end))

task.spawn(function()
	while Screen.Parent do
		local count = 0
		for _ in pairs(AnimalEntries) do
			count = count + 1
		end
		Footer.Text = "animals " .. count .. "   aim " .. aimStatus .. "   " .. fishPhase
		if fishStatusLabel and fishStatusLabel.Parent then
			fishStatusLabel.Text = Settings.AutoReel and (fishPhase .. "\n" .. fishZone) or "off"
			fishStatusLabel.TextColor3 = (fishPhase == "REEL" or fishPhase == "BITE") and Theme.Good or Theme.PinkDeep
		end
		task.wait(0.2)
	end
end)

local function unload()
	Settings.AimOn = false
	Settings.AutoReel = false
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
	dim.BackgroundColor3 = Color3.fromRGB(40, 20, 35)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.Parent = intro
	TweenService:Create(dim, TweenInfo.new(0.3), { BackgroundTransparency = 0.4 }):Play()

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.46)
	card.Size = UDim2.fromOffset(210, 200)
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

	local head = Instance.new("Frame")
	head.Size = UDim2.fromOffset(84, 72)
	head.Position = UDim2.new(0.5, -42, 0, 42)
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
	sub.Text = "snow bunny says hi"
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 11
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

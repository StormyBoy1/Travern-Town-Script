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
        travel uses the normal Humanoid:MoveTo controller, not CFrame teleporting
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
	AutoMine = false,
	MineStand = 4,
	MineSpeed = 55,
	MineEquip = true,
	MineMark = true,
	GemESP = true,
	GemESPDistance = 500,
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
local windowGradient = Instance.new("UIGradient")
windowGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 250, 253)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 224, 239)),
})
windowGradient.Rotation = 90
windowGradient.Parent = Window

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Theme.Bg2
Header.BorderSizePixel = 0
local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new(Color3.fromRGB(255, 232, 243), Color3.fromRGB(255, 190, 218))
headerGradient.Rotation = 0
headerGradient.Parent = Header
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
Title.Text = "MY WISH  ✿"
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
-- Uses the game's Mine config for node size, hit timing, reach and respawn.
-- MineSwing is the game's local animation controller; its play() function
-- animates the pickaxe swing but does not itself prove server-side damage.

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

local function taggedNodeFor(part)
	local current = part
	while current and current ~= Workspace do
		local ok, tagged = pcall(function()
			return CollectionService:HasTag(current, NODE_TAG)
		end)
		if ok and tagged then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function nodePart(instance)
	if not instance then return nil end
	if instance:IsA("BasePart") then return instance end
	if instance:IsA("Model") and instance.PrimaryPart then
		return instance.PrimaryPart
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function nodeAlive(part)
	return part ~= nil and part.Parent ~= nil and taggedNodeFor(part) ~= nil
end

local function nodeSize(part)
	local node = taggedNodeFor(part)
	local current = part
	while current and current ~= Workspace do
		for _, key in ipairs({ "Size", "NodeSize", "size", "GemSize", "Kind" }) do
			local ok, value = pcall(function()
				return current:GetAttribute(key)
			end)
			if ok and type(value) == "string" then
				local normalized = string.lower(value)
				if normalized == "small" then return "Small" end
				if normalized == "medium" then return "Medium" end
				if normalized == "large" then return "Large" end
			end
		end
		if current == node then break end
		current = current.Parent
	end
	local size = part.Size
	if node and node:IsA("Model") then
		local ok, extents = pcall(function() return node:GetExtentsSize() end)
		if ok then size = extents end
	end
	local height = math.max(size.X, size.Y, size.Z)
	if height >= 5.6 then return "Large" end
	if height >= 4.2 then return "Medium" end
	return "Small"
end

local function nodeInfo(part)
	local sizeName = nodeSize(part)
	local info = NODE_SIZES[sizeName]
	if type(info) ~= "table" then
		return { swings = 5, stand = 4 }, sizeName
	end
	return info, sizeName
end

local function markNode(part, on)
	if not part then return end
	local existing = mineMarked[part]
	if on and not existing then
		local hl = Instance.new("Highlight")
		hl.Name = "MYWISH_MINE"
		hl.FillColor = Color3.fromRGB(130, 255, 210)
		hl.FillTransparency = 0.6
		hl.OutlineColor = Theme.Pink
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee = taggedNodeFor(part) or part
		hl.Parent = part
		mineMarked[part] = hl
	elseif not on and existing then
		mineMarked[part] = nil
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
	if not character then return nil end
	local held = character:FindFirstChildOfClass("Tool")
	if held then return held end
	if not Settings.MineEquip then return nil end
	local tool = findPickaxe()
	if tool and tool.Parent ~= character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			pcall(function() humanoid:EquipTool(tool) end)
			task.wait(0.18)
		end
	end
	return character:FindFirstChildOfClass("Tool")
end

local function swingAt(part)
	if not part or not nodeAlive(part) then return false end
	local now = os.clock()
	if now - lastMineSwing < NODE_SWING * 0.85 then return false end
	local tool = equipPickaxe()
	if not tool then
		mineStatus = "equip a pickaxe"
		return false
	end
	lastMineSwing = now
	local ok = pcall(function() tool:Activate() end)
	return ok
end

local function nearestNode(root)
	local best, bestDist = nil, math.huge
	local layoutData = MineLayout and MineLayout.Data
	local bounds = layoutData and layoutData.bounds
	for _, instance in ipairs(CollectionService:GetTagged(NODE_TAG)) do
		local part = nodePart(instance)
		if part and nodeAlive(part) and (not mineCooldown[part] or mineCooldown[part] <= os.clock()) then
			local inBounds = true
			if bounds then
				inBounds = part.Position.X >= bounds.x0 - 8 and part.Position.X <= bounds.x1 + 8
					and part.Position.Z >= bounds.z0 - 8 and part.Position.Z <= bounds.z1 + 8
			end
			if inBounds then
				local dist = (part.Position - root.Position).Magnitude
				if dist < bestDist then best, bestDist = part, dist end
			end
		end
	end
	return best
end

local function playMineAnimation(character, swings)
	if not MineSwing or type(MineSwing.play) ~= "function" then return nil end
	local ok, stop = pcall(function()
		return MineSwing.play(character, 1, swings)
	end)
	if ok and type(stop) == "function" then return stop end
	return nil
end

local function mineOne(part)
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or not nodeAlive(part) then return false end

	local info, sizeName = nodeInfo(part)
	local swings = math.max(1, math.floor(tonumber(info.swings) or 5))
	local stand = math.clamp(Settings.MineStand, 2, 9)
	local away = Vector3.new(root.Position.X - part.Position.X, 0, root.Position.Z - part.Position.Z)
	if away.Magnitude < 0.5 then away = Vector3.new(0, 0, 1) end
	away = away.Unit
	local dest = Vector3.new(
		part.Position.X + away.X * math.min(stand, (tonumber(info.stand) or 4) + 1),
		root.Position.Y,
		part.Position.Z + away.Z * math.min(stand, (tonumber(info.stand) or 4) + 1)
	)

	local started = os.clock()
	local savedWalkSpeed = humanoid.WalkSpeed
	local timeout = math.min(18, math.max(10, (swings * NODE_SWING) + 5))
	local nextMoveRefresh = 0
	local miningStarted = nil
	local nextHit = 1
	local hitTimes = hitTimesFor(swings)
	local stopAnimation = nil

	while Settings.AutoMine and nodeAlive(part) and screenAlive() and os.clock() - started < timeout do
		task.wait(0.1)
		character = LocalPlayer.Character
		root = character and character:FindFirstChild("HumanoidRootPart")
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid then
			mineStatus = "waiting for character"
			if stopAnimation then pcall(stopAnimation) end
			return false
		end

		local gap = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(part.Position.X, 0, part.Position.Z)).Magnitude
		if gap > NODE_REACH then
			mineStatus = "walking to gem · " .. math.floor(gap) .. "m"
			if not Settings.SpeedOn then
				humanoid.WalkSpeed = math.clamp(Settings.MineSpeed, 16, 100)
			end
			if os.clock() >= nextMoveRefresh then
				humanoid:MoveTo(dest)
				nextMoveRefresh = os.clock() + 1
			end
		else
			if not Settings.SpeedOn then
				humanoid.WalkSpeed = savedWalkSpeed
			end
			if not miningStarted then
				miningStarted = os.clock()
				pcall(function() humanoid:MoveTo(root.Position) end)
				stopAnimation = playMineAnimation(character, swings)
				mineStatus = "mining " .. sizeName .. " · 0/" .. swings
			end
			local due = hitTimes[nextHit]
			if due and os.clock() - miningStarted >= due then
				if swingAt(part) then
					mineStatus = "mining " .. sizeName .. " · " .. nextHit .. "/" .. swings
					nextHit = nextHit + 1
				else
					-- Do not advance the hit index if the pickaxe is missing or activation failed.
					task.wait(0.2)
				end
			end
			if nextHit > swings then
				local done = os.clock() - miningStarted >= (hitTimes[swings] or MINE_SECONDS) + 0.8
				if done then break end
			end
		end
	end

	if stopAnimation then pcall(stopAnimation) end
	pcall(function()
		if humanoid and humanoid.Parent then
			humanoid:MoveTo(root and root.Position or dest)
			if not Settings.SpeedOn then humanoid.WalkSpeed = savedWalkSpeed end
		end
	end)
	return not nodeAlive(part)
end

local function farmTick()
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then mineStatus = "no character"; return end
	for part, hl in pairs(mineMarked) do
		if not part.Parent or not hl.Parent then
			mineMarked[part] = nil
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
	local broke = mineOne(mineTarget)
	markNode(mineTarget, false)
	if broke then
		mineTarget = nil
	elseif not nodeAlive(mineTarget) then
		mineTarget = nil
	else
		-- If the server leaves the node intact, cool it down before retrying so
		-- the loop can work through the other live nodes instead of getting stuck.
		mineCooldown[mineTarget] = os.clock() + math.max(RESPAWN_WAIT, 8)
		mineStatus = "hits sent · waiting for server node update"
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
		task.spawn(function()
			pcall(equipPickaxe)
			if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChildOfClass("Tool") then
				mineStatus = "equip a pickaxe"
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
mineNote.Text = "Gem ESP marks tagged gem nodes locally. AUTO MINE is best-effort: it walks with Humanoid:MoveTo and activates your equipped tool. The extracted game controller uses its own MineNode server interaction, so this client helper cannot guarantee node breaks; if the game does not accept tool activation, use the normal in-game mine control. A timeout prevents a stuck mining loop."
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
	clearMarks()
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

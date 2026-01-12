--================ SERVICES ================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local cam = workspace.CurrentCamera

--================ CONFIG ==================
local HEIGHT_CAP = 25
local PLATFORM_SPEED = 14
local MAX_ESP_DISTANCE = 500

--================ STATE ===================
local platform, baseY = nil, nil
local movingUp, movingDown = false, false

local ESP_PARTS = false
local ESP_ENEMIES = false
local ESP_PLAYERS = false
local DIST_LIMIT = false

local PART_NAMES = {}
local espCache = {}

--================ GUI =====================
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(260, 460)
frame.Position = UDim2.fromOffset(20, 60)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.Active = true
frame.Draggable = true

local layout = Instance.new("UIListLayout", frame)
layout.Padding = UDim.new(0,6)

local function button(txt)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,-10,0,30)
	b.Text = txt
	b.Font = Enum.Font.SourceSansBold
	b.TextSize = 13
	b.BackgroundColor3 = Color3.fromRGB(60,60,60)
	b.TextColor3 = Color3.new(1,1,1)
	b.Parent = frame
	return b
end

local function textbox(ph)
	local t = Instance.new("TextBox")
	t.Size = UDim2.new(1,-10,0,30)
	t.PlaceholderText = ph
	t.TextSize = 13
	t.ClearTextOnFocus = false
	t.BackgroundColor3 = Color3.fromRGB(35,35,35)
	t.TextColor3 = Color3.new(1,1,1)
	t.Parent = frame
	return t
end

--================ FULLBRIGHT ==============
local function fullbright()
	Lighting.ClockTime = 14
	Lighting.Brightness = 5
	Lighting.FogEnd = 1e6
	Lighting.Ambient = Color3.new(1,1,1)
	Lighting.OutdoorAmbient = Color3.new(1,1,1)
end

--================ PLATFORM =================
local function createPlatform()
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	baseY = hrp.Position.Y

	platform = Instance.new("Part")
	platform.Size = Vector3.new(8, 0.7, 8) -- BIGGER
	platform.Anchored = true
	platform.CanCollide = true
	platform.CFrame = hrp.CFrame * CFrame.new(0,-3,0)
	platform.Parent = workspace
end

local function removePlatform()
	if platform then platform:Destroy() end
	platform, baseY = nil, nil
	movingUp, movingDown = false, false
end

--================ ESP CORE =================
local function clearESP()
	for _,v in pairs(espCache) do
		v.h:Destroy()
		v.b:Destroy()
	end
	espCache = {}
end

local function addESP(obj, text, color)
	if espCache[obj] then return end

	local h = Instance.new("Highlight")
	h.FillTransparency = 1
	h.OutlineColor = color
	h.Adornee = obj
	h.Parent = gui

	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromOffset(160,20)
	b.StudsOffset = Vector3.new(0,2.2,0)
	b.AlwaysOnTop = true
	b.Adornee = obj
	b.Parent = gui

	local t = Instance.new("TextLabel", b)
	t.Size = UDim2.new(1,0,1,0)
	t.BackgroundTransparency = 1
	t.TextStrokeTransparency = 0.4
	t.TextColor3 = color
	t.Font = Enum.Font.SourceSansBold
	t.TextScaled = true
	t.Text = text

	espCache[obj] = {h=h,b=b,t=t}
end

--================ UI BUTTONS ===============
local DayBtn = button("☀ Day / Fullbright / No Fog")
local PlatBtn = button("⬛ Platform ON / OFF")
local UpBtn = button("⬆ HOLD UP")
local DownBtn = button("⬇ HOLD DOWN")

local PartEspBtn = button("🟢 Part ESP")
local EnemyEspBtn = button("🔴 Enemy ESP (Auto)")
local PlayerEspBtn = button("👤 Player ESP")
local DistBtn = button("📏 Distance Limit")

local PartBox = textbox("Part name → Enter")

--================ UI LOGIC =================
DayBtn.MouseButton1Click:Connect(fullbright)

PlatBtn.MouseButton1Click:Connect(function()
	if platform then removePlatform() else createPlatform() end
end)

UpBtn.MouseButton1Down:Connect(function() movingUp = true end)
UpBtn.MouseButton1Up:Connect(function() movingUp = false end)

DownBtn.MouseButton1Down:Connect(function() movingDown = true end)
DownBtn.MouseButton1Up:Connect(function() movingDown = false end)

PartEspBtn.MouseButton1Click:Connect(function()
	ESP_PARTS = not ESP_PARTS
	if not ESP_PARTS then clearESP() end
end)

EnemyEspBtn.MouseButton1Click:Connect(function()
	ESP_ENEMIES = not ESP_ENEMIES
	if not ESP_ENEMIES then clearESP() end
end)

PlayerEspBtn.MouseButton1Click:Connect(function()
	ESP_PLAYERS = not ESP_PLAYERS
	if not ESP_PLAYERS then clearESP() end
end)

DistBtn.MouseButton1Click:Connect(function()
	DIST_LIMIT = not DIST_LIMIT
end)

PartBox.FocusLost:Connect(function(e)
	if e and PartBox.Text ~= "" then
		PART_NAMES[PartBox.Text:lower()] = true
		PartBox.Text = ""
	end
end)

--================ MAIN LOOP ================
RunService.RenderStepped:Connect(function(dt)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- PLATFORM MOVE (HOLD ONLY)
	if platform then
		local y = platform.Position.Y
		if movingUp and y - baseY < HEIGHT_CAP then
			platform.CFrame += Vector3.new(0, PLATFORM_SPEED*dt, 0)
		elseif movingDown and baseY - y < HEIGHT_CAP then
			platform.CFrame -= Vector3.new(0, PLATFORM_SPEED*dt, 0)
		end
	end

	local closest, cd = nil, math.huge

	-- PART ESP
	if ESP_PARTS then
		for _,p in ipairs(workspace:GetDescendants()) do
			if p:IsA("BasePart") and PART_NAMES[p.Name:lower()] then
				local d = (p.Position - hrp.Position).Magnitude
				if not DIST_LIMIT or d <= MAX_ESP_DISTANCE then
					addESP(p, p.Name.." ["..math.floor(d).."s]", Color3.fromRGB(0,255,0))
					if d < cd then closest, cd = p, d end
				end
			end
		end
	end

	-- ENEMY ESP (AUTO)
	if ESP_ENEMIES then
		for _,m in ipairs(workspace:GetDescendants()) do
			if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then
				if not Players:GetPlayerFromCharacter(m) then
					local pp = m.PrimaryPart
					if pp then
						local d = (pp.Position - hrp.Position).Magnitude
						if not DIST_LIMIT or d <= MAX_ESP_DISTANCE then
							addESP(pp, m.Name.." ["..math.floor(d).."s]", Color3.fromRGB(255,0,0))
							if d < cd then closest, cd = pp, d end
						end
					end
				end
			end
		end
	end

	-- PLAYER ESP
	if ESP_PLAYERS then
		for _,plr in ipairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				local pp = plr.Character.HumanoidRootPart
				local d = (pp.Position - hrp.Position).Magnitude
				if not DIST_LIMIT or d <= MAX_ESP_DISTANCE then
					addESP(pp, plr.Name.." ["..math.floor(d).."s]", Color3.fromRGB(255,0,0))
				end
			end
		end
	end

	-- CLOSEST = PURPLE
	if closest and espCache[closest] then
		espCache[closest].h.OutlineColor = Color3.fromRGB(170,0,255)
		espCache[closest].t.TextColor3 = Color3.fromRGB(170,0,255)
	end
end)

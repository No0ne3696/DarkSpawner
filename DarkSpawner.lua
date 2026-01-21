-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

--================ GUI =================
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "MultiMenu"
gui.ResetOnSpawn = false

local menuBtn = Instance.new("TextButton", gui)
menuBtn.Size = UDim2.fromOffset(90,32)
menuBtn.Position = UDim2.fromOffset(20,20)
menuBtn.Text = "MENU"
menuBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
menuBtn.TextColor3 = Color3.new(1,1,1)
menuBtn.Active = true
menuBtn.Draggable = true

local frame = Instance.new("Frame", gui)
frame.Position = UDim2.fromOffset(20,60)
frame.Size = UDim2.fromOffset(220,300)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.Visible = false
frame.Active = true
frame.Draggable = true

local layout = Instance.new("UIListLayout", frame)
layout.Padding = UDim.new(0,8)

menuBtn.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

local function makeButton(text)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,-10,0,32)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(60,60,60)
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.SourceSansBold
	b.TextSize = 14
	b.Parent = frame
	return b
end

--================ BUTTONS =================
local lightBtn = makeButton("☀ Day / Fullbright / NoFog")
local platformBtn = makeButton("⬛ Platform OFF")
local upBtn = makeButton("⬆ UP")
local downBtn = makeButton("⬇ DOWN")
local hitboxBtn = makeButton("👁 Hitbox Viewer")

upBtn.Visible = false
downBtn.Visible = false

--================ FULLBRIGHT =================
lightBtn.MouseButton1Click:Connect(function()
	Lighting.ClockTime = 14
	Lighting.Brightness = 5
	Lighting.FogEnd = 100000
	Lighting.Ambient = Color3.new(1,1,1)
	Lighting.OutdoorAmbient = Color3.new(1,1,1)
end)

--================ PLATFORM =================
local platform
local moving = 0
local SPEED = 20

local function makePlatform()
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	platform = Instance.new("Part")
	platform.Size = Vector3.new(50,2,50) -- 500% bigger
	platform.Transparency = 0.75
	platform.Anchored = true
	platform.CanCollide = true
	platform.Position = char.HumanoidRootPart.Position - Vector3.new(0,5,0)
	platform.Parent = workspace
end

local function removePlatform()
	if platform then
		platform:Destroy()
		platform = nil
	end
end

platformBtn.MouseButton1Click:Connect(function()
	if platform then
		removePlatform()
		platformBtn.Text = "⬛ Platform OFF"
		upBtn.Visible = false
		downBtn.Visible = false
	else
		makePlatform()
		platformBtn.Text = "⬛ Platform ON"
		upBtn.Visible = true
		downBtn.Visible = true
	end
end)

upBtn.MouseButton1Down:Connect(function() moving = 1 end)
upBtn.MouseButton1Up:Connect(function() moving = 0 end)
downBtn.MouseButton1Down:Connect(function() moving = -1 end)
downBtn.MouseButton1Up:Connect(function() moving = 0 end)

--================ HITBOX VIEWER =================
local hitboxOn = false
local hitboxes = {}

hitboxBtn.MouseButton1Click:Connect(function()
	hitboxOn = not hitboxOn
	hitboxBtn.Text = hitboxOn and "👁 Hitbox ON" or "👁 Hitbox OFF"

	for _,h in pairs(hitboxes) do h:Destroy() end
	hitboxes = {}
end)

--================ LOOP =================
RunService.RenderStepped:Connect(function(dt)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Platform follow + move
	if platform then
		platform.Position = Vector3.new(hrp.Position.X, platform.Position.Y, hrp.Position.Z)

		if moving ~= 0 then
			platform.CFrame += Vector3.new(0, moving * SPEED * dt, 0)
		end
	end

	-- Hitbox viewer
	if hitboxOn then
		for _,m in ipairs(workspace:GetDescendants()) do
			if m:IsA("Model") and m:FindFirstChild("Humanoid") and m.PrimaryPart then
				if not hitboxes[m] then
					local h = Instance.new("Highlight")
					h.Adornee = m
					h.FillTransparency = 1
					h.OutlineColor = Color3.fromRGB(255,0,0)
					h.Parent = gui
					hitboxes[m] = h
				end
			end
		end
	end
end)

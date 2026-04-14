--[[
    UNIVERSAL MOBILE DASHBOARD - CYBER-GLITCH THEME
    Optimized for High FPS & Mobile Touch
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- // 1. Core UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CyberHub_Mobile"
ScreenGui.ResetOnSpawn = false
-- Protect GUI if executor supports it, otherwise fallback to PlayerGui
if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = game:GetService("CoreGui")
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = playerGui
end

local Colors = {
    Background = Color3.fromRGB(10, 10, 15),
    NeonCyan = Color3.fromRGB(0, 255, 255),
    NeonGreen = Color3.fromRGB(57, 255, 20),
    NeonRed = Color3.fromRGB(255, 20, 60),
    Glass = Color3.fromRGB(20, 20, 25)
}

-- // 2. FPS-Friendly Mobile Dragging Logic
local function MakeDraggable(uiElement, dragHandle)
    local dragging, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = uiElement.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    -- Direct coordinate updates for max FPS (No Tween Engine overhead during drag)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            uiElement.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- // 3. Dual-Zone FAB System
local activeFABs = {}

local function SpawnFAB(modName, callback)
    if activeFABs[modName] then
        activeFABs[modName]:Destroy()
        activeFABs[modName] = nil
        return
    end

    -- Outer Handle (The Mover)
    local FAB_Container = Instance.new("Frame")
    FAB_Container.Size = UDim2.new(0, 70, 0, 70)
    FAB_Container.Position = UDim2.new(0.5, -35, 0.8, -35)
    FAB_Container.BackgroundColor3 = Colors.Glass
    FAB_Container.BackgroundTransparency = 0.5
    FAB_Container.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = FAB_Container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.NeonCyan
    stroke.Thickness = 2
    stroke.Parent = FAB_Container

    -- Inner Button (The Switch)
    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.new(0, 40, 0, 40)
    Switch.Position = UDim2.new(0.5, -20, 0.5, -20)
    Switch.BackgroundColor3 = Colors.NeonRed
    Switch.Text = modName
    Switch.TextScaled = true
    Switch.TextColor3 = Color3.new(1, 1, 1)
    Switch.Parent = FAB_Container
    
    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(1, 0)
    innerCorner.Parent = Switch

    MakeDraggable(FAB_Container, FAB_Container) 
    activeFABs[modName] = FAB_Container

    -- Toggle Logic (Tween used ONLY on tap, which is FPS safe)
    local isOn = false
    Switch.Activated:Connect(function()
        isOn = not isOn
        TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = isOn and Colors.NeonGreen or Colors.NeonRed}):Play()
        task.spawn(callback, isOn) 
    end)
end

-- // 4. Feature Modules
local Modules = {}

Modules.AutoSafeZone = function(state)
    if state then
        -- Placeholder logic: Replace "SafeZone" with the actual part name in your game
        local safePart = workspace:FindFirstChild("SafeZone") 
        if safePart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local distance = (hrp.Position - safePart.Position).Magnitude
            local speed = 50 
            local timeToTravel = distance / speed
            
            local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = safePart.CFrame + Vector3.new(0, 5, 0)})
            tween:Play()
        end
    end
end

Modules.BatterySaver = function(state)
    local saverFrame = ScreenGui:FindFirstChild("SaverFrame")
    
    if state then
        if not saverFrame then
            saverFrame = Instance.new("Frame")
            saverFrame.Name = "SaverFrame"
            saverFrame.Size = UDim2.new(1, 0, 1, 0)
            saverFrame.BackgroundColor3 = Color3.new(0, 0, 0)
            saverFrame.ZIndex = -1 
            saverFrame.Parent = ScreenGui
        end
        saverFrame.Visible = true
        RunService:Set3dRenderingEnabled(false) -- Massive GPU/FPS saver
    else
        if saverFrame then saverFrame.Visible = false end
        RunService:Set3dRenderingEnabled(true)
    end
end

-- Anti-AFK (Passive)
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- // 5. Master Menu Construction
local MasterMenu = Instance.new("Frame")
MasterMenu.Size = UDim2.new(0, 200, 0, 200)
MasterMenu.Position = UDim2.new(0, 10, 0.3, 0)
MasterMenu.BackgroundColor3 = Colors.Background
MasterMenu.BackgroundTransparency = 0.2
MasterMenu.ClipsDescendants = true
MasterMenu.Parent = ScreenGui

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 10)
MenuCorner.Parent = MasterMenu

local MenuStroke = Instance.new("UIStroke")
MenuStroke.Color = Colors.NeonCyan
MenuStroke.Thickness = 1
MenuStroke.Parent = MasterMenu

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Colors.Glass
TopBar.Parent = MasterMenu

local TopBarText = Instance.new("TextLabel")
TopBarText.Size = UDim2.new(1, 0, 1, 0)
TopBarText.BackgroundTransparency = 1
TopBarText.Text = "  CYBER HUB"
TopBarText.TextColor3 = Colors.NeonCyan
TopBarText.TextXAlignment = Enum.TextXAlignment.Left
TopBarText.Font = Enum.Font.Code
TopBarText.TextSize = 16
TopBarText.Parent = TopBar

local ModContainer = Instance.new("ScrollingFrame")
ModContainer.Size = UDim2.new(1, 0, 1, -30)
ModContainer.Position = UDim2.new(0, 0, 0, 30)
ModContainer.BackgroundTransparency = 1
ModContainer.ScrollBarThickness = 4
ModContainer.Parent = MasterMenu

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ModContainer
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Dynamic layout resizing
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ModContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

local function AddMenuButton(name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.BackgroundColor3 = Colors.Glass
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.Code
    btn.TextSize = 14
    btn.Parent = ModContainer
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = btn

    btn.Activated:Connect(function()
        SpawnFAB(name, callback)
    end)
end

-- // 6. Initialize Features
AddMenuButton("Auto SafeZone", Modules.AutoSafeZone)
AddMenuButton("Battery Saver", Modules.BatterySaver)

-- Make the menu itself draggable via the TopBar
MakeDraggable(MasterMenu, TopBar)

--[[
    DELTA EXECUTOR — UNIFIED MOD MENU
    Features: Toggle IY, T-Pose, Click TP, Fly (Collide), Noclip, Spin, Speed, Fullbright, ESP, Aimbot, Killaura, Immortality, Fling, Position Changer, TP to Player
]]

--============================================================
-- SERVICES & SETUP
--============================================================
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local CoreGui    = game:GetService("CoreGui")
local Lighting   = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

local PlayerModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local Controls     = PlayerModule:GetControls()

-- Remove any old copies
for _, name in ipairs({"UnifiedModMenu", "DFG", "DMulti", "DESP"}) do
    local old = CoreGui:FindFirstChild(name)
    if old then old:Destroy() end
end

--============================================================
-- STATE
--============================================================
local State = {
    ClickTP     = false,
    Fly         = false,
    FlySpeed    = 50,
    Noclip      = false,
    Spin        = false,
    SpinSpeed   = 40,
    Speed       = false,
    SpeedRate   = 60,
    Fullbright  = false,
    ESP         = false,
    Aimbot      = false,
    AimbotFOV   = 150,
    AimbotPart  = "Head",
    Killaura    = false,
    KillauraRange = 20,
    Immortality = false,
    Fling       = false,
    TPose       = false,
}

-- Runtime refs
local FlyConn, FlyVel, FlyGyro
local NoclipConn
local ToolConn
local SpinConn, SpeedConn
local FullbrightConn
local AimbotConn, AimbotInput
local KillauraConn
local ImmortalConn, ImmortalDied
local FlingConn, FlingDied, FlingAngular
local TPoseConn, TPoseSavedAnimate

-- Save original Lighting values so we can restore them on toggle-off
local OriginalLighting = {
    Brightness     = Lighting.Brightness,
    ClockTime      = Lighting.ClockTime,
    FogEnd         = Lighting.FogEnd,
    GlobalShadows  = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

--============================================================
-- UI BUILD
--============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UnifiedModMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 240, 0, 480)
Main.Position = UDim2.new(0, 25, 0.25, 0)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(60, 60, 70)
MainStroke.Thickness = 1
MainStroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 34)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Title.BorderSizePixel = 0
Title.Text = "MOD MENU"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

-- Minimize button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 26, 0, 26)
MinimizeBtn.Position = UDim2.new(1, -30, 0, 4)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 18
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Parent = Title

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeBtn

-- Scrollable list
local List = Instance.new("ScrollingFrame")
List.Size = UDim2.new(1, -10, 1, -44)
List.Position = UDim2.new(0, 5, 0, 39)
List.BackgroundTransparency = 1
List.BorderSizePixel = 0
List.ScrollBarThickness = 4
List.CanvasSize = UDim2.new(0, 0, 0, 0)
List.AutomaticCanvasSize = Enum.AutomaticSize.Y
List.Parent = Main

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 6)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = List

-- Minimize / restore handler
local minimized = false
local expandedSize = Main.Size
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        expandedSize = Main.Size
        Main.Size = UDim2.new(0, 240, 0, 34)
        List.Visible = false
        MinimizeBtn.Text = "+"
    else
        Main.Size = expandedSize
        List.Visible = true
        MinimizeBtn.Text = "—"
    end
end)

--============================================================
-- UI HELPERS
--============================================================
local function createToggle(text, initialState, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -8, 0, 36)
    Row.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Row.BorderSizePixel = 0
    Row.Parent = List

    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 6)
    RowCorner.Parent = Row

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -80, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(230, 230, 230)
    Label.Font = Enum.Font.SourceSansBold
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Row

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 56, 0, 24)
    Toggle.Position = UDim2.new(1, -64, 0.5, -12)
    Toggle.BackgroundColor3 = initialState and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(80, 80, 90)
    Toggle.Text = initialState and "ON" or "OFF"
    Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    Toggle.Font = Enum.Font.SourceSansBold
    Toggle.TextSize = 13
    Toggle.BorderSizePixel = 0
    Toggle.Parent = Row

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 6)
    ToggleCorner.Parent = Toggle

    local enabled = initialState

    Toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        Toggle.BackgroundColor3 = enabled and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(80, 80, 90)
        Toggle.Text = enabled and "ON" or "OFF"
        callback(enabled)
    end)

    return Row, Toggle
end

local function createButton(text, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -8, 0, 36)
    Row.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Row.BorderSizePixel = 0
    Row.Parent = List

    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 6)
    RowCorner.Parent = Row

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -16, 0, 26)
    Btn.Position = UDim2.new(0, 8, 0.5, -13)
    Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.SourceSansBold
    Btn.TextSize = 13
    Btn.BorderSizePixel = 0
    Btn.Parent = Row

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Btn

    Btn.MouseButton1Click:Connect(callback)
    return Row, Btn
end

--============================================================
-- 0) TOGGLE IY
--============================================================
local IY_LOADED_KEY = "IY_LOADED"

createButton("Toggle IY (Load / Unload)", function()
    local isLoaded = getgenv() and getgenv()[IY_LOADED_KEY]
    if isLoaded then
        pcall(function() getgenv()[IY_LOADED_KEY] = nil end)
        print("[ModMenu] IY_LOADED flag cleared — next Toggle IY will reload IY.")
    else
        local ok, err = pcall(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
            ))()
        end)
        if ok then
            print("[ModMenu] Infinite Yield loaded.")
        else
            warn("[ModMenu] Failed to load IY: " .. tostring(err))
        end
    end
end)

--============================================================
-- 0b) T-POSE
--============================================================
local function setTPose(enabled)
    State.TPose = enabled

    local char = LocalPlayer.Character
    if not char then
        State.TPose = false
        return
    end

    local animate = char:FindFirstChild("Animate")
    if not animate then
        State.TPose = false
        return
    end

    if enabled then
        TPoseSavedAnimate = animate.Disabled
        animate.Disabled = true

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                pcall(function() track:Stop() end)
            end
        end

        if not TPoseConn then
            TPoseConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                if not State.TPose then return end
                local newAnimate = newChar:WaitForChild("Animate", 5)
                if newAnimate then
                    newAnimate.Disabled = true
                end
            end)
        end
    else
        animate.Disabled = (TPoseSavedAnimate == true)
        TPoseSavedAnimate = nil

        if TPoseConn then TPoseConn:Disconnect(); TPoseConn = nil end
    end
end

createToggle("T-Pose (NoAnim)", State.TPose, setTPose)

--============================================================
-- 1) CLICK TP
--============================================================
local function giveClickTPTool()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return end

    local existing = backpack:FindFirstChild("Click to TP")
    if existing then existing:Destroy() end

    local Tool = Instance.new("Tool")
    Tool.Name = "Click to TP"
    Tool.RequiresHandle = false

    Tool.Activated:Connect(function()
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local pos = Mouse.Hit.Position + Vector3.new(0, 3, 0)
            character.HumanoidRootPart.CFrame = CFrame.new(pos)
        end
    end)

    Tool.Parent = backpack
end

local function setClickTP(enabled)
    State.ClickTP = enabled
    if enabled then
        giveClickTPTool()
        if ToolConn then ToolConn:Disconnect() end
        ToolConn = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            if State.ClickTP then giveClickTPTool() end
        end)
    else
        if ToolConn then ToolConn:Disconnect(); ToolConn = nil end
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            local tool = backpack:FindFirstChild("Click to TP")
            if tool then tool:Destroy() end
        end
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChild("Click to TP")
            if tool then tool:Destroy() end
        end
    end
end

createToggle("Click TP", State.ClickTP, setClickTP)

--============================================================
-- 2) FLY (Collide)
--============================================================
local function stopFly()
    State.Fly = false
    if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
    if FlyVel then FlyVel:Destroy(); FlyVel = nil end
    if FlyGyro then FlyGyro:Destroy(); FlyGyro = nil end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    State.Fly = true
    hum.PlatformStand = true

    FlyVel = Instance.new("BodyVelocity")
    FlyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    FlyVel.Velocity = Vector3.zero
    FlyVel.Parent = root

    FlyGyro = Instance.new("BodyGyro")
    FlyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    FlyGyro.CFrame = Camera.CFrame
    FlyGyro.Parent = root

    FlyConn = RunService.RenderStepped:Connect(function()
        if not State.Fly or not root or not hum then return end
        local mv = Controls:GetMoveVector()
        if mv.Magnitude > 0 then
            local cf = Camera.CFrame
            local dir = (cf.LookVector * -mv.Z) + (cf.RightVector * mv.X)
            if dir.Magnitude > 0 then
                FlyVel.Velocity = dir.Unit * State.FlySpeed
            end
        else
            FlyVel.Velocity = Vector3.zero
        end
        FlyGyro.CFrame = Camera.CFrame
    end)
end

--============================================================
-- 3) NOCLIP
--============================================================
local function restoreCollisions()
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

local function stopNoclip()
    State.Noclip = false
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
    restoreCollisions()
end

local function startNoclip()
    State.Noclip = true
    if NoclipConn then NoclipConn:Disconnect() end

    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    NoclipConn = RunService.Stepped:Connect(function()
        if not State.Noclip then return end
        local ch = LocalPlayer.Character
        if not ch then return end
        for _, part in ipairs(ch:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
end

local function setFly(enabled)
    if enabled then startFly() else stopFly() end
end

local function setNoclip(enabled)
    if enabled then startNoclip() else stopNoclip() end
end

createToggle("Fly (Collide)", State.Fly, setFly)
createToggle("Noclip",        State.Noclip, setNoclip)

--============================================================
-- 4) SPIN
--============================================================
local function setSpin(enabled)
    State.Spin = enabled
    if enabled and not SpinConn then
        SpinConn = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(State.SpinSpeed), 0)
        end)
    elseif not enabled and SpinConn then
        SpinConn:Disconnect()
        SpinConn = nil
    end
end

createToggle("Spin", State.Spin, setSpin)

--============================================================
-- 5) SPEED
--============================================================
local function setSpeed(enabled)
    State.Speed = enabled
    if enabled and not SpeedConn then
        SpeedConn = RunService.RenderStepped:Connect(function(dt)
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not root or not hum then return end

            local mv = Controls:GetMoveVector()
            if mv.Magnitude > 0 then
                local camCF = Camera.CFrame
                local dir = (camCF.LookVector * -mv.Z) + (camCF.RightVector * mv.X)
                if dir.Magnitude > 0 then
                    root.CFrame = root.CFrame + Vector3.new(dir.X, 0, dir.Z).Unit * (State.SpeedRate * dt)
                end
            end
        end)
    elseif not enabled and SpeedConn then
        SpeedConn:Disconnect()
        SpeedConn = nil
    end
end

createToggle("Speed", State.Speed, setSpeed)

--============================================================
-- 6) FULLBRIGHT
--============================================================
local function applyFullbright()
    pcall(function()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end)
end

local function stopFullbright()
    State.Fullbright = false
    if FullbrightConn then FullbrightConn:Disconnect(); FullbrightConn = nil end

    pcall(function()
        Lighting.Brightness     = OriginalLighting.Brightness
        Lighting.ClockTime      = OriginalLighting.ClockTime
        Lighting.FogEnd         = OriginalLighting.FogEnd
        Lighting.GlobalShadows  = OriginalLighting.GlobalShadows
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    end)
end

local function startFullbright()
    State.Fullbright = true
    applyFullbright()

    FullbrightConn = RunService.Stepped:Connect(function()
        if not State.Fullbright then return end
        applyFullbright()
    end)
end

local function setFullbright(enabled)
    if enabled then startFullbright() else stopFullbright() end
end

createToggle("Fullbright", State.Fullbright, setFullbright)

--============================================================
-- 7) ESP
--============================================================
local function applyESP(character)
    if not character then return end
    local hl = character:FindFirstChild("E_Hl")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "E_Hl"
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = character
    end
    hl.Enabled = State.ESP
end

local function addESPForPlayer(plr)
    if plr == LocalPlayer then return end
    if plr.Character then applyESP(plr.Character) end
    plr.CharacterAdded:Connect(function(ch)
        task.wait(0.1)
        applyESP(ch)
    end)
end

for _, plr in ipairs(Players:GetPlayers()) do
    addESPForPlayer(plr)
end
Players.PlayerAdded:Connect(addESPForPlayer)

local function setESP(enabled)
    State.ESP = enabled
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hl = plr.Character:FindFirstChild("E_Hl")
            if hl then
                hl.Enabled = enabled
            elseif enabled then
                applyESP(plr.Character)
            end
        end
    end
end

createToggle("ESP", State.ESP, setESP)

--============================================================
-- 8) AIMBOT  (rotates the CHARACTER toward the target)
--    When enabled and holding right mouse button, your character
--    smoothly turns to face the closest player within FOV.
--============================================================
local function getClosestTarget()
    local localChar = LocalPlayer.Character
    if not localChar then return nil end
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end

    local closest, closestDist = nil, State.AimbotFOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            local tPart = plr.Character:FindFirstChild(State.AimbotPart)
            local hum   = plr.Character:FindFirstChildOfClass("Humanoid")
            if tRoot and tPart and hum and hum.Health > 0 then
                local _, onScreen = Camera:WorldToViewportPoint(tPart.Position)
                if onScreen then
                    local dist = (tPart.Position - localRoot.Position).Magnitude
                    local screenPos = Camera:WorldToViewportPoint(tPart.Position)
                    local screenCenter = Camera.ViewportSize / 2
                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if screenDist <= State.AimbotFOV and dist < closestDist then
                        closest = tPart
                        closestDist = dist
                    end
                end
            end
        end
    end
    return closest
end

local function stopAimbot()
    State.Aimbot = false
    if AimbotConn then AimbotConn:Disconnect(); AimbotConn = nil end
end

local function startAimbot()
    State.Aimbot = true
    if AimbotConn then AimbotConn:Disconnect() end

    AimbotConn = RunService.RenderStepped:Connect(function()
        if not State.Aimbot then return end
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local target = getClosestTarget()
        if not target then return end

        -- Rotate the character's root CFrame to face the target's part,
        -- preserving the character's current position.
        local charPos = root.Position
        local targetPos = target.Position
        local desiredCF = CFrame.lookAt(charPos, Vector3.new(targetPos.X, charPos.Y, targetPos.Z))
        root.CFrame = root.CFrame:Lerp(desiredCF, 0.25)
    end)
end

local function setAimbot(enabled)
    if enabled then startAimbot() else stopAimbot() end
end

createToggle("Aimbot", State.Aimbot, setAimbot)

--============================================================
-- 9) KILLAURA
--    Auto-attacks the closest player in range. Works with
--    equipped tools (fires Tool.Activated and touches the
--    target part) and with click-based melee if the game
--    fires ClickDetectors. Also fires a VirtualUser click so
--    games that use mouse1 for melee get the input.
--============================================================
State.KillauraRange = 20

local function getClosestKillTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local closest, closestDist = nil, State.KillauraRange
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum   = plr.Character:FindFirstChildOfClass("Humanoid")
            if tRoot and hum and hum.Health > 0 then
                local dist = (tRoot.Position - root.Position).Magnitude
                if dist < closestDist then
                    closest = plr
                    closestDist = dist
                end
            end
        end
    end
    return closest, closestDist
end

local function stopKillaura()
    State.Killaura = false
    if KillauraConn then KillauraConn:Disconnect(); KillauraConn = nil end
end

local function startKillaura()
    State.Killaura = true
    if KillauraConn then KillauraConn:Disconnect() end

    KillauraConn = RunService.Heartbeat:Connect(function()
        if not State.Killaura then return end

        local char = LocalPlayer.Character
        if not char then return end

        local targetPlr, dist = getClosestKillTarget()
        if not targetPlr then return end

        local targetChar = targetPlr.Character
        if not targetChar then return end

        -- 1) If holding a tool, fire its activation and touch its handle
        --    against the target's hitbox. This handles sword / weapon games.
        local equipped = char:FindFirstChildOfClass("Tool")
        if equipped then
            local handle = equipped:FindFirstChild("Handle")
            pcall(function() equipped:Activate() end)
            if handle and firetouchinterest then
                local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
                local tHead = targetChar:FindFirstChild("Head")
                if tRoot then
                    pcall(function()
                        firetouchinterest(handle, tRoot, 0)
                        firetouchinterest(handle, tRoot, 1)
                    end)
                end
                if tHead then
                    pcall(function()
                        firetouchinterest(handle, tHead, 0)
                        firetouchinterest(handle, tHead, 1)
                    end)
                end
            end
        end

        -- 2) Fire any ClickDetectors attached to the target character
        --    (many melee games use these for hit registration).
        for _, part in ipairs(targetChar:GetDescendants()) do
            if part:IsA("ClickDetector") then
                pcall(function() fireclickdetector(part) end)
            end
        end

        -- 3) Send a virtual mouse click so games using mouse1 melee
        --    register a hit. This is client-side input only.
        pcall(function()
            VirtualUser:Button1Down(Vector2.new(0, 0))
            VirtualUser:Button1Up(Vector2.new(0, 0))
        end)
    end)
end

local function setKillaura(enabled)
    if enabled then startKillaura() else stopKillaura() end
end

createToggle("Killaura", State.Killaura, setKillaura)

--============================================================
-- 10) IMMORTALITY  (Infinite Yield ;god style)
--============================================================
local immortalGodHumanoid = nil

local function stopImmortality()
    State.Immortality = false

    if ImmortalConn then ImmortalConn:Disconnect(); ImmortalConn = nil end
    if ImmortalDied then ImmortalDied:Disconnect(); ImmortalDied = nil end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                hum.BreakJointsOnDeath = true
            end)
        end
    end

    immortalGodHumanoid = nil
end

local function startImmortality()
    local char = LocalPlayer.Character
    if not char then return end
    local human = char:FindFirstChildOfClass("Humanoid")
    if not human then return end

    State.Immortality = true

    local Cam = Workspace.CurrentCamera
    local Pos = Cam.CFrame

    local nHuman = human:Clone()
    nHuman.Parent = char
    LocalPlayer.Character = nil

    nHuman:SetStateEnabled(15, false)
    nHuman:SetStateEnabled(1, false)
    nHuman:SetStateEnabled(0, false)
    nHuman.BreakJointsOnDeath = true

    human:Destroy()

    LocalPlayer.Character = char
    Cam.CameraSubject = nHuman
    Cam.CFrame = Pos

    nHuman.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

    local animateScript = char:FindFirstChild("Animate")
    if animateScript then
        animateScript.Disabled = true
        task.wait()
        animateScript.Disabled = false
    end

    nHuman.Health = nHuman.MaxHealth
    immortalGodHumanoid = nHuman

    ImmortalConn = RunService.Stepped:Connect(function()
        if not State.Immortality then return end
        local ch = LocalPlayer.Character
        if not ch then return end
        local h = ch:FindFirstChildOfClass("Humanoid")
        if not h then return end
        if h.Health < h.MaxHealth then
            h.Health = h.MaxHealth
        end
        if h.BreakJointsOnDeath then
            h.BreakJointsOnDeath = false
        end
    end)

    ImmortalDied = nHuman.Died:Connect(function()
        if not State.Immortality then return end
        task.wait(0.1)
        local ch = LocalPlayer.Character
        if ch then
            local h = ch:FindFirstChildOfClass("Humanoid")
            if h then
                h.Health = h.MaxHealth
                pcall(function()
                    h:SetStateEnabled(15, false)
                    h.BreakJointsOnDeath = false
                end)
            end
        end
    end)
end

local function setImmortality(enabled)
    if enabled then
        startImmortality()
    else
        stopImmortality()
    end
end

createToggle("Immortality", State.Immortality, setImmortality)

--============================================================
-- 11) FLING
--============================================================
local FlingSavedProps = {}

local function restoreFlingProps()
    for part, saved in pairs(FlingSavedProps) do
        if typeof(part) == "Instance" and part.Parent and part:IsA("BasePart") then
            part.CustomPhysicalProperties = saved.Props
            part.Massless = saved.Massless
        end
    end
    FlingSavedProps = {}
end

local function stopFling()
    State.Fling = false
    if FlingConn then FlingConn:Disconnect(); FlingConn = nil end
    if FlingDied then FlingDied:Disconnect(); FlingDied = nil end
    if FlingAngular then FlingAngular:Destroy(); FlingAngular = nil end
    restoreFlingProps()
end

local function startFling()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    stopFling()
    State.Fling = true

    FlingSavedProps = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            FlingSavedProps[part] = {
                Props    = part.CustomPhysicalProperties,
                Massless = part.Massless,
            }
            part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
            part.Massless = true
            part.Velocity = Vector3.zero
            part.RotVelocity = Vector3.zero
        end
    end

    FlingAngular = Instance.new("BodyAngularVelocity")
    FlingAngular.Name = "ModFling"
    FlingAngular.Parent = root
    FlingAngular.AngularVelocity = Vector3.new(0, 0, 0)
    FlingAngular.MaxTorque = Vector3.new(0, math.huge, 0)
    FlingAngular.P = math.huge

    FlingConn = RunService.Stepped:Connect(function()
        if not State.Fling then return end
        local ch = LocalPlayer.Character
        if not ch then return end

        for _, part in ipairs(ch:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.CanCollide then
                    part.CanCollide = false
                end
                if part.CustomPhysicalProperties ~= PhysicalProperties.new(100, 0.3, 0.5) then
                    part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
                end
                if not part.Massless then
                    part.Massless = true
                end
            end
        end
    end)

    task.spawn(function()
        while State.Fling do
            if FlingAngular and FlingAngular.Parent then
                FlingAngular.AngularVelocity = Vector3.new(0, 99999, 0)
            end
            task.wait(0.2)
            if FlingAngular and FlingAngular.Parent then
                FlingAngular.AngularVelocity = Vector3.new(0, 0, 0)
            end
            task.wait(0.1)
        end
    end)

    FlingDied = hum.Died:Connect(stopFling)
end

local function setFling(enabled)
    if enabled then
        startFling()
    else
        stopFling()
    end
end

createToggle("Fling", State.Fling, setFling)

--============================================================
-- 12) POSITION CHANGER
--============================================================
local PosRow = Instance.new("Frame")
PosRow.Size = UDim2.new(1, -8, 0, 132)
PosRow.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
PosRow.BorderSizePixel = 0
PosRow.Parent = List

local PosRowCorner = Instance.new("UICorner")
PosRowCorner.CornerRadius = UDim.new(0, 6)
PosRowCorner.Parent = PosRow

local PosTitle = Instance.new("TextLabel")
PosTitle.Size = UDim2.new(1, -20, 0, 22)
PosTitle.Position = UDim2.new(0, 10, 0, 4)
PosTitle.BackgroundTransparency = 1
PosTitle.Text = "POSITION"
PosTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
PosTitle.Font = Enum.Font.SourceSansBold
PosTitle.TextSize = 14
PosTitle.TextXAlignment = Enum.TextXAlignment.Left
PosTitle.Parent = PosRow

local function makeCoordBox(label, xPos)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 16, 0, 26)
    lbl.Position = UDim2.new(0, xPos, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(180, 180, 190)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 14
    lbl.Parent = PosRow

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 48, 0, 26)
    box.Position = UDim2.new(0, xPos + 18, 0, 30)
    box.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 13
    box.Text = "0"
    box.PlaceholderText = "0"
    box.BorderSizePixel = 0
    box.Parent = PosRow

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = box

    return box
end

local XBox = makeCoordBox("X", 8)
local YBox = makeCoordBox("Y", 92)
local ZBox = makeCoordBox("Z", 176)

local UseCurrentBtn = Instance.new("TextButton")
UseCurrentBtn.Size = UDim2.new(0, 100, 0, 26)
UseCurrentBtn.Position = UDim2.new(0, 8, 0, 66)
UseCurrentBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
UseCurrentBtn.Text = "Use Current"
UseCurrentBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UseCurrentBtn.Font = Enum.Font.SourceSansBold
UseCurrentBtn.TextSize = 12
UseCurrentBtn.BorderSizePixel = 0
UseCurrentBtn.Parent = PosRow

local UCBCorner = Instance.new("UICorner")
UCBCorner.CornerRadius = UDim.new(0, 4)
UCBCorner.Parent = UseCurrentBtn

local TeleportBtn = Instance.new("TextButton")
TeleportBtn.Size = UDim2.new(0, 100, 0, 26)
TeleportBtn.Position = UDim2.new(1, -108, 0, 66)
TeleportBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
TeleportBtn.Text = "Teleport"
TeleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportBtn.Font = Enum.Font.SourceSansBold
TeleportBtn.TextSize = 12
TeleportBtn.BorderSizePixel = 0
TeleportBtn.Parent = PosRow

local TPCorner = Instance.new("UICorner")
TPCorner.CornerRadius = UDim.new(0, 4)
TPCorner.Parent = TeleportBtn

local PosStatus = Instance.new("TextLabel")
PosStatus.Size = UDim2.new(1, -20, 0, 22)
PosStatus.Position = UDim2.new(0, 10, 0, 100)
PosStatus.BackgroundTransparency = 1
PosStatus.Text = "Enter coordinates or use current."
PosStatus.TextColor3 = Color3.fromRGB(150, 150, 160)
PosStatus.Font = Enum.Font.SourceSans
PosStatus.TextSize = 11
PosStatus.TextXAlignment = Enum.TextXAlignment.Left
PosStatus.Parent = PosRow

UseCurrentBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        XBox.Text = string.format("%.1f", root.Position.X)
        YBox.Text = string.format("%.1f", root.Position.Y)
        ZBox.Text = string.format("%.1f", root.Position.Z)
        PosStatus.Text = "Loaded current position."
        PosStatus.TextColor3 = Color3.fromRGB(150, 150, 160)
    else
        PosStatus.Text = "No character to read."
        PosStatus.TextColor3 = Color3.fromRGB(220, 53, 69)
    end
end)

TeleportBtn.MouseButton1Click:Connect(function()
    local x = tonumber(XBox.Text)
    local y = tonumber(YBox.Text)
    local z = tonumber(ZBox.Text)
    if not x or not y or not z then
        PosStatus.Text = "Invalid numbers."
        PosStatus.TextColor3 = Color3.fromRGB(220, 53, 69)
        return
    end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(Vector3.new(x, y, z))
        PosStatus.Text = string.format("Teleported to (%.1f, %.1f, %.1f).", x, y, z)
        PosStatus.TextColor3 = Color3.fromRGB(40, 167, 69)
    else
        PosStatus.Text = "No character to teleport."
        PosStatus.TextColor3 = Color3.fromRGB(220, 53, 69)
    end
end)

--============================================================
-- 13) TP TO PLAYER
--============================================================
local TPPlayerRow = Instance.new("Frame")
TPPlayerRow.Size = UDim2.new(1, -8, 0, 150)
TPPlayerRow.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
TPPlayerRow.BorderSizePixel = 0
TPPlayerRow.Parent = List

local TPPlayerRowCorner = Instance.new("UICorner")
TPPlayerRowCorner.CornerRadius = UDim.new(0, 6)
TPPlayerRowCorner.Parent = TPPlayerRow

local TPPlayerTitle = Instance.new("TextLabel")
TPPlayerTitle.Size = UDim2.new(1, -20, 0, 22)
TPPlayerTitle.Position = UDim2.new(0, 10, 0, 4)
TPPlayerTitle.BackgroundTransparency = 1
TPPlayerTitle.Text = "TP TO PLAYER"
TPPlayerTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
TPPlayerTitle.Font = Enum.Font.SourceSansBold
TPPlayerTitle.TextSize = 14
TPPlayerTitle.TextXAlignment = Enum.TextXAlignment.Left
TPPlayerTitle.Parent = TPPlayerRow

local PlayerScroll = Instance.new("ScrollingFrame")
PlayerScroll.Size = UDim2.new(1, -16, 0, 116)
PlayerScroll.Position = UDim2.new(0, 8, 0, 28)
PlayerScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
PlayerScroll.BorderSizePixel = 0
PlayerScroll.ScrollBarThickness = 4
PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerScroll.Parent = TPPlayerRow

local PlayerScrollCorner = Instance.new("UICorner")
PlayerScrollCorner.CornerRadius = UDim.new(0, 4)
PlayerScrollCorner.Parent = PlayerScroll

local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 3)
PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlayerListLayout.Parent = PlayerScroll

local playerButtons = {}

local function refreshPlayerList()
    for _, btn in ipairs(playerButtons) do
        if btn and btn.Parent then btn:Destroy() end
    end
    playerButtons = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -4, 0, 22)
            btn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
            btn.Text = plr.Name .. (plr.Character and "" or " (no char)")
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.SourceSans
            btn.TextSize = 12
            btn.BorderSizePixel = 0
            btn.Parent = PlayerScroll

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = btn

            btn.MouseButton1Click:Connect(function()
                local targetChar = plr.Character
                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

                if not targetRoot then
                    btn.Text = plr.Name .. " (no char)"
                    return
                end
                if not myRoot then
                    return
                end

                myRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
                btn.Text = "TP'd to " .. plr.Name
            end)

            table.insert(playerButtons, btn)
        end
    end

    if #playerButtons == 0 then
        local emptyLbl = Instance.new("TextLabel")
        emptyLbl.Size = UDim2.new(1, -4, 0, 22)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Text = "No other players."
        emptyLbl.TextColor3 = Color3.fromRGB(150, 150, 160)
        emptyLbl.Font = Enum.Font.SourceSans
        emptyLbl.TextSize = 12
        emptyLbl.Parent = PlayerScroll
        table.insert(playerButtons, emptyLbl)
    end
end

refreshPlayerList()
Players.PlayerAdded:Connect(function()
    task.wait(1)
    refreshPlayerList()
end)
Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    refreshPlayerList()
end)

--============================================================
-- CLEANUP ON RESPAWN
--============================================================
LocalPlayer.CharacterAdded:Connect(function()
    if State.Fly then stopFly() end
    if State.Noclip then stopNoclip() end
    if State.Fling then stopFling() end

    if State.Immortality then
        task.wait(0.5)
        if State.Immortality and LocalPlayer.Character then
            startImmortality()
        end
    end
end)

print("[UnifiedModMenu] Loaded successfully.")

-- Load Fluent-Renewed & Config Addons
local Fluent = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

---------------------------------------------------------
-- 0. GAME ENVIRONMENT DETECTION
---------------------------------------------------------
local MM2_PLACE_ID = 142823291
local isMM2 = (game.PlaceId == MM2_PLACE_ID) or (game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Gameplay") ~= nil)

local Window = Fluent:CreateWindow({
    Title = "TrannyWare",
    SubTitle = (isMM2 and "MM2" or "Universal") .. " [v1.00]",
    TabWidth = 160,
    Size = UDim2.fromOffset(720, 420),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightAlt
})

---------------------------------------------------------
-- 1. CORE VARIABLES & ENGINE SERVICES
---------------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting") or game:FindFirstChild("Lighting")
local Stats = game:GetService("Stats")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer

-- MM2 Specific Role States & Palettes
local espStates = { Murderer = false, Sheriff = false, Innocent = false, GunDrop = false, Friend = false, LobbyDisable = true }
local espStyle = { Type = "Glow", DepthMode = "Always On Top", FillTransparency = 0.45, OutlineTransparency = 0, TextSize = 14, ShowDistance = true, NameDisplay = "Both", TransSeq = NumberSequence.new(0.45) }

local roleColors = {
    Murderer = Color3.fromRGB(255, 70, 70),
    Sheriff = Color3.fromRGB(70, 150, 255),
    Innocent = Color3.fromRGB(80, 220, 100),
    GunDrop = Color3.fromRGB(255, 255, 0),
    Friend = Color3.fromRGB(255, 105, 180)
}

local cachedRoleColors = {
    Murderer = ColorSequence.new(roleColors.Murderer),
    Sheriff = ColorSequence.new(roleColors.Sheriff),
    Innocent = ColorSequence.new(roleColors.Innocent),
    GunDrop = ColorSequence.new(roleColors.GunDrop),
    Friend = ColorSequence.new(roleColors.Friend)
}

local notifySelfRole = true
local notifyWhitelistRole = true
local whisperIncludeMurderer = true
local whisperIncludeSheriff = true
local notifyGunPickup = true
local showNameESP = false
local showGunNameESP = true
local smartEspEnabled = false
local showHoldingIndicator = true

local serverPlayerData = {}
local whitelistedPlayerName = nil
local currentLocalRole = "Innocent"
local currentRoundActive = false
local mapIsLoadingState = false
local whisperedThisRound = false
local knownSheriff = nil

local activeGunDrop = nil
local autoPickupGun = false
local isGrabbingGun = false
local padPos1, padPos2, padPos3 = nil, nil, nil
local spamMap1, spamMap2, spamMap3 = false, false, false
local spamSpeed = 1.0

local triggerBotEnabled = false
local triggerBotFOV = 40
local tbDebounce = false
local showReloadBar = false
local showOffScreenArrows = false
local arrowRadius = 65
local arrowTrans = 0

local killAuraEnabled = false
local stabReachRange = 15
local excludeWhitelistFromKillAll = true

-- Universal Rendering & Clean Screen Variables
local showWatermark = false
local hideAvatarsEnabled = false
local hideGameGuiEnabled = false
local hideWepDisplays = false
local muteRadiosAndThemes = false
local streamerModeEnabled = false
local streamerCustomName = "Streamer"

-- Dedicated Freecam 1.09 / 1.10 State
local freecamEnabled = false
local freecamWarpEnabled = false
local freecamSpeed = 1.5
local freecamPosition = Vector3.new()
local freecamPitch = 0
local freecamYaw = 0
local freecamKeys = { W = false, A = false, S = false, D = false, Space = false, Shift = false }

-- Spectate System
local isSpectating = false
local spectateTarget = nil

local SpamMap1Toggle, SpamMap2Toggle, SpamMap3Toggle
local logJoinsLeaves = false

---------------------------------------------------------
-- 2. CUSTOM HUD (TACTICAL OVERLAY & RELOAD BAR)
---------------------------------------------------------
local CoreGui = pcall(gethui) and gethui() or game:GetService("CoreGui")
local CustomHUD = Instance.new("ScreenGui")
CustomHUD.Name = "TrannyWare_HUD"
CustomHUD.ResetOnSpawn = false
CustomHUD.ZIndexBehavior = Enum.ZIndexBehavior.Global
CustomHUD.IgnoreGuiInset = true

local success = pcall(function() CustomHUD.Parent = CoreGui end)
if not success or not CustomHUD.Parent then CustomHUD.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local RFrame = Instance.new("Frame", CustomHUD)
RFrame.Size = UDim2.new(0, 250, 0, 12)
RFrame.Position = UDim2.new(0.5, -125, 0.85, 0)
RFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
RFrame.BorderSizePixel = 2
RFrame.BorderColor3 = Color3.fromRGB(10, 10, 10)
RFrame.ZIndex = 999
RFrame.Visible = false

local RBar = Instance.new("Frame", RFrame)
RBar.Size = UDim2.new(0, 0, 1, 0)
RBar.BackgroundColor3 = Color3.fromRGB(60, 150, 255) 
RBar.BorderSizePixel = 0
RBar.ZIndex = 1000

local ArrowFrame = Instance.new("Frame", CustomHUD)
ArrowFrame.Size = UDim2.new(1, 0, 1, 0)
ArrowFrame.BackgroundTransparency = 1
ArrowFrame.ZIndex = 900

local MurdArrow = Instance.new("TextLabel", ArrowFrame)
MurdArrow.Text = "▲"
MurdArrow.TextColor3 = roleColors.Murderer
MurdArrow.TextStrokeTransparency = 0.3
MurdArrow.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
MurdArrow.BackgroundTransparency = 1
MurdArrow.TextSize = 22
MurdArrow.Size = UDim2.new(0, 40, 0, 40)
MurdArrow.AnchorPoint = Vector2.new(0.5, 0.5)
MurdArrow.Visible = false

local WMFrame = Instance.new("Frame", CustomHUD)
WMFrame.AutomaticSize = Enum.AutomaticSize.X
WMFrame.Size = UDim2.new(0, 0, 0, 32)
WMFrame.AnchorPoint = Vector2.new(0.5, 0)
WMFrame.Position = UDim2.new(0.5, 0, 0, 15)
WMFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
WMFrame.BackgroundTransparency = 0.2
WMFrame.BorderSizePixel = 1
WMFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
WMFrame.Visible = false
WMFrame.Active = true
WMFrame.Draggable = true

local WMCorner = Instance.new("UICorner", WMFrame)
WMCorner.CornerRadius = UDim.new(0, 6)

local UIPadding = Instance.new("UIPadding", WMFrame)
UIPadding.PaddingLeft = UDim.new(0, 15)
UIPadding.PaddingRight = UDim.new(0, 15)

local WMText = Instance.new("TextLabel", WMFrame)
WMText.AutomaticSize = Enum.AutomaticSize.X
WMText.Size = UDim2.new(0, 0, 1, 0)
WMText.BackgroundTransparency = 1
WMText.TextColor3 = Color3.fromRGB(220, 220, 220)
WMText.Font = Enum.Font.Code
WMText.TextSize = 13
WMText.TextXAlignment = Enum.TextXAlignment.Center
WMText.RichText = true
WMText.Text = "<b><font color=\"#9696FF\">TrannyWare</font></b> | Loading..."
WMText.Parent = WMFrame

local hudPositions = {
    ["Top Left"] = {Anchor = Vector2.new(0, 0), Pos = UDim2.new(0, 15, 0, 15)},
    ["Top Center"] = {Anchor = Vector2.new(0.5, 0), Pos = UDim2.new(0.5, 0, 0, 15)},
    ["Top Right"] = {Anchor = Vector2.new(1, 0), Pos = UDim2.new(1, -15, 0, 15)},
    ["Middle Left"] = {Anchor = Vector2.new(0, 0.5), Pos = UDim2.new(0, 15, 0.5, 0)},
    ["Middle Right"] = {Anchor = Vector2.new(1, 0.5), Pos = UDim2.new(1, -15, 0.5, 0)},
    ["Bottom Left"] = {Anchor = Vector2.new(0, 1), Pos = UDim2.new(0, 15, 1, -15)},
    ["Bottom Center"] = {Anchor = Vector2.new(0.5, 1), Pos = UDim2.new(0.5, 0, 1, -15)},
    ["Bottom Right"] = {Anchor = Vector2.new(1, 1), Pos = UDim2.new(1, -15, 1, -15)}
}

---------------------------------------------------------
-- 3. NATIVE LOGGING
---------------------------------------------------------
local function pushLogToChat(message, hexColor)
    pcall(function()
        local tcs = game:GetService("TextChatService")
        if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
            local channel = tcs.TextChannels:FindFirstChild("RBXSystem") or tcs.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                channel:DisplaySystemMessage("<font color='" .. hexColor .. "'>[TrannyWare] " .. message .. "</font>")
            end
        else
            game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                Text = "[TrannyWare] " .. message,
                Color = Color3.fromHex(hexColor),
                Font = Enum.Font.SourceSansBold,
                TextSize = 16
            })
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    if logJoinsLeaves then pushLogToChat(player.Name .. " joined the server.", "#64FF64") end
end)

Players.PlayerRemoving:Connect(function(player)
    if logJoinsLeaves then pushLogToChat(player.Name .. " left the server.", "#FF6464") end
    if spectateTarget == player then
        isSpectating = false
        spectateTarget = nil
        local cam = Workspace.CurrentCamera
        if cam and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            cam.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end
end)

-- =========================================================
-- 4. UNIVERSAL MODULE (STANDALONE MULTI-GAME ENGINE)
-- =========================================================
local UniversalModule = {
    -- Locomotion & Physics
    Noclip = false,
    InfJump = false,
    CtrlClickTP = false,
    SpeedEnabled = false,
    WalkSpeed = 16,
    Fly = false,
    FlySpeed = 2,
    FlyKeys = { W = false, A = false, S = false, D = false, Space = false, Shift = false },
    GravityEnabled = false,
    GravityValue = 196.2,
    JumpPowerEnabled = false,
    JumpPowerValue = 50,
    
    -- Defense & Automation
    AntiFling = true,
    AntiAFK = true,
    AntiVoid = false,
    AutoClicker = false,
    AutoClickerCPS = 15,
    AltClickDelete = false,

    -- World Mods & Optimization
    Fullbright = false,
    ShadersEnabled = false,
    PotatoMode = false,
    XRay = false,
    NoCamShake = false,
    InfZoom = false,
    FOV = 70,
    
    -- Universal ESP States
    ESPEnabled = false,
    ShowTeammates = true,
    UseTeamColors = true,
    EnemyColor = Color3.fromRGB(255, 65, 65),
    TeammateColor = Color3.fromRGB(65, 255, 65),
    ShowNames = true,
    ShowDistance = true
}

local flingerAlertDebounce = {}
local ghostedCharacters = {}
local cachedXRayParts = {}
local cachedPotatoStates = {}
local lastSafePos = Vector3.zero

local originalLightingState = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

-- Shaders Post-Processing Cache
local ShaderEffects = { ColorCorrection = nil, Bloom = nil, SunRays = nil }

local function setupShaders(enabled)
    UniversalModule.ShadersEnabled = enabled
    if enabled then
        if not ShaderEffects.ColorCorrection then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "TW_ColorCorrection"; cc.Saturation = 0.2; cc.Contrast = 0.15; cc.TintColor = Color3.fromRGB(255, 248, 240); cc.Parent = Lighting
            ShaderEffects.ColorCorrection = cc
        end
        if not ShaderEffects.Bloom then
            local b = Instance.new("BloomEffect")
            b.Name = "TW_Bloom"; b.Intensity = 0.45; b.Size = 22; b.Threshold = 0.85; b.Parent = Lighting
            ShaderEffects.Bloom = b
        end
        if not ShaderEffects.SunRays then
            local sr = Instance.new("SunRaysEffect")
            sr.Name = "TW_SunRays"; sr.Intensity = 0.12; sr.Spread = 0.8; sr.Parent = Lighting
            ShaderEffects.SunRays = sr
        end
    else
        for k, effect in pairs(ShaderEffects) do
            if effect and effect.Parent then effect:Destroy() end
            ShaderEffects[k] = nil
        end
    end
end

-- Exact 1.09 / 1.10 Keyboard & Mouse Input Engine
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    -- Exact 1.09 Mouse Lock Override
    if freecamEnabled and input.UserInputType == Enum.UserInputType.MouseButton2 then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Ctrl + Click TP
        if UniversalModule.CtrlClickTP and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            local mousePos = UserInputService:GetMouseLocation()
            local cam = Workspace.CurrentCamera
            if cam then
                local unitRay = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local res = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 2000, rayParams)
                if res and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0))
                end
            end
        end

        -- Alt + Click Delete
        if UniversalModule.AltClickDelete and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
            local mousePos = UserInputService:GetMouseLocation()
            local cam = Workspace.CurrentCamera
            if cam then
                local unitRay = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local res = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 2000, rayParams)
                if res and res.Instance and not res.Instance:IsA("Terrain") then res.Instance:Destroy() end
            end
        end
    end

    -- Freecam Warp Hotkey (F)
    if input.KeyCode == Enum.KeyCode.F and freecamEnabled and freecamWarpEnabled then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and Workspace.CurrentCamera then
            hrp.CFrame = Workspace.CurrentCamera.CFrame
            Fluent:Notify({Title="Freecam Warp", Content="Teleported to camera position.", Duration=2})
        end
    end

    -- Exact 1.09 Freecam Keys
    if freecamEnabled then
        if input.KeyCode == Enum.KeyCode.W then freecamKeys.W = true
        elseif input.KeyCode == Enum.KeyCode.S then freecamKeys.S = true
        elseif input.KeyCode == Enum.KeyCode.A then freecamKeys.A = true
        elseif input.KeyCode == Enum.KeyCode.D then freecamKeys.D = true
        elseif input.KeyCode == Enum.KeyCode.Space then freecamKeys.Space = true
        elseif input.KeyCode == Enum.KeyCode.LeftShift then freecamKeys.Shift = true
        end
    end

    -- Flight Directional Keys
    if UniversalModule.Fly then
        if input.KeyCode == Enum.KeyCode.W then UniversalModule.FlyKeys.W = true
        elseif input.KeyCode == Enum.KeyCode.S then UniversalModule.FlyKeys.S = true
        elseif input.KeyCode == Enum.KeyCode.A then UniversalModule.FlyKeys.A = true
        elseif input.KeyCode == Enum.KeyCode.D then UniversalModule.FlyKeys.D = true
        elseif input.KeyCode == Enum.KeyCode.Space then UniversalModule.FlyKeys.Space = true
        elseif input.KeyCode == Enum.KeyCode.LeftShift then UniversalModule.FlyKeys.Shift = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end

    if input.KeyCode == Enum.KeyCode.W then 
        freecamKeys.W = false; UniversalModule.FlyKeys.W = false
    elseif input.KeyCode == Enum.KeyCode.S then 
        freecamKeys.S = false; UniversalModule.FlyKeys.S = false
    elseif input.KeyCode == Enum.KeyCode.A then 
        freecamKeys.A = false; UniversalModule.FlyKeys.A = false
    elseif input.KeyCode == Enum.KeyCode.D then 
        freecamKeys.D = false; UniversalModule.FlyKeys.D = false
    elseif input.KeyCode == Enum.KeyCode.Space then 
        freecamKeys.Space = false; UniversalModule.FlyKeys.Space = false
    elseif input.KeyCode == Enum.KeyCode.LeftShift then 
        freecamKeys.Shift = false; UniversalModule.FlyKeys.Shift = false
    end
end)

-- Exact 1.09 Freecam Mouse Look Input
UserInputService.InputChanged:Connect(function(input, gpe)
    if freecamEnabled and input.UserInputType == Enum.UserInputType.MouseMovement then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local delta = input.Delta
            freecamYaw = freecamYaw - math.rad(delta.X * 0.2)
            freecamPitch = math.clamp(freecamPitch - math.rad(delta.Y * 0.2), -math.rad(89), math.rad(89))
        end
    end
end)

-- Infinite Jump Hook
UserInputService.JumpRequest:Connect(function()
    if UniversalModule.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Universal Anti-AFK
LocalPlayer.Idled:Connect(function()
    if UniversalModule.AntiAFK then
        VirtualUser:Button2Down(Vector2.zero, Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.zero, Workspace.CurrentCamera.CFrame)
    end
end)

-- Auto-Clicker Background Thread
task.spawn(function()
    while true do
        if UniversalModule.AutoClicker then
            pcall(function()
                VirtualUser:Button1Down(Vector2.new(0, 0))
                task.wait(0.01)
                VirtualUser:Button1Up(Vector2.new(0, 0))
                local char = LocalPlayer.Character
                local tool = char and char:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end)
            task.wait(1 / math.max(1, UniversalModule.AutoClickerCPS))
        else
            task.wait(0.2)
        end
    end
end)

-- Universal Server Utilities
local function UniversalServerHop()
    Fluent:Notify({ Title = "Server Hop", Content = "Searching for optimal public server...", Duration = 3 })
    task.spawn(function()
        local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        local targetUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if requestFunc then
            local success, response = pcall(function() return requestFunc({Url = targetUrl, Method = "GET"}) end)
            if success and response and response.Body then
                local data = HttpService:JSONDecode(response.Body)
                if data and data.data then
                    for _, server in ipairs(data.data) do
                        if server.playing < server.maxPlayers and server.id ~= game.JobId then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                            return
                        end
                    end
                end
            end
        end
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

local function UniversalRejoin() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end
local function TeleportToMM2() Fluent:Notify({ Title = "Teleporting", Content = "Joining Murder Mystery 2...", Duration = 3 }); TeleportService:Teleport(MM2_PLACE_ID, LocalPlayer) end

-- Universal Render & Clean Screen Engine
task.spawn(function()
    while task.wait(1.5) do
        if hideAvatarsEnabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and not LocalPlayer:IsFriendsWith(p.UserId) then
                    for _, v in ipairs(p.Character:GetChildren()) do
                        if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("SurfaceAppearance") or v:IsA("WrapLayer") then
                            v:Destroy()
                        end
                    end
                    local bc = p.Character:FindFirstChildWhichIsA("BodyColors")
                    if bc then
                        local grey = Color3.fromRGB(163, 162, 165)
                        bc.HeadColor3 = grey; bc.TorsoColor3 = grey; bc.LeftArmColor3 = grey
                        bc.RightArmColor3 = grey; bc.LeftLegColor3 = grey; bc.RightLegColor3 = grey
                    end
                end
            end
        end
    end
end)

local cachedGuis = {}
task.spawn(function()
    while task.wait(0.5) do
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            if hideGameGuiEnabled then
                for _, gui in ipairs(pGui:GetChildren()) do
                    if gui:IsA("ScreenGui") and gui.Name ~= "TrannyWare_HUD" and not string.find(gui.Name:lower(), "fluent") then
                        if cachedGuis[gui] == nil then cachedGuis[gui] = gui.Enabled end
                        gui.Enabled = false
                    end
                end
            else
                for gui, origState in pairs(cachedGuis) do
                    if gui and gui.Parent then gui.Enabled = origState end
                end
                cachedGuis = {}
            end
        end
    end
end)

-- Universal Team-Based ESP Engine
local function removeUniversalPlayerESP(char)
    if not char then return end
    local h = char:FindFirstChild("TW_UnivHighlight")
    local n = char:FindFirstChild("TW_UnivName")
    if h then h:Destroy() end
    if n then n:Destroy() end
end

local function applyUniversalPlayerESP(char, player, isTeammate)
    if not char or not player then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return removeUniversalPlayerESP(char) end

    local targetColor = UniversalModule.EnemyColor
    if isTeammate then targetColor = UniversalModule.TeammateColor end
    if UniversalModule.UseTeamColors and player.TeamColor then targetColor = player.TeamColor.Color end

    local highlight = char:FindFirstChild("TW_UnivHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "TW_UnivHighlight"; highlight.Adornee = char; highlight.FillColor = targetColor; highlight.OutlineColor = targetColor
        highlight.FillTransparency = 0.5; highlight.OutlineTransparency = 0; highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; highlight.Parent = char
    else
        if highlight.FillColor ~= targetColor then highlight.FillColor = targetColor; highlight.OutlineColor = targetColor end
    end

    if UniversalModule.ShowNames then
        local nameGui = char:FindFirstChild("TW_UnivName")
        local distStr = ""
        if UniversalModule.ShowDistance and Workspace.CurrentCamera then
            distStr = " [" .. math.floor((Workspace.CurrentCamera.CFrame.Position - hrp.Position).Magnitude) .. "s]"
        end
        local formatName = player.DisplayName .. " (@" .. player.Name .. ")" .. distStr

        if not nameGui then
            nameGui = Instance.new("BillboardGui")
            nameGui.Name = "TW_UnivName"; nameGui.AlwaysOnTop = true; nameGui.Size = UDim2.new(0, 200, 0, 35); nameGui.StudsOffset = Vector3.new(0, 3.2, 0); nameGui.Adornee = hrp
            local text = Instance.new("TextLabel")
            text.Name = "Label"; text.Size = UDim2.new(1, 0, 1, 0); text.BackgroundTransparency = 1; text.Font = Enum.Font.Code; text.TextStrokeTransparency = 0.5; text.TextSize = 13; text.TextColor3 = targetColor; text.Text = formatName; text.Parent = nameGui; nameGui.Parent = char
        else
            if nameGui.Label.TextColor3 ~= targetColor then nameGui.Label.TextColor3 = targetColor end
            nameGui.Label.Text = formatName
        end
    else
        local n = char:FindFirstChild("TW_UnivName")
        if n then n:Destroy() end
    end
end

if not isMM2 then
    task.spawn(function()
        while task.wait(0.08) do
            if not UniversalModule.ESPEnabled then
                for _, p in ipairs(Players:GetPlayers()) do if p.Character then removeUniversalPlayerESP(p.Character) end end
            else
                local myTeam = LocalPlayer.Team
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                        local isTeammate = (myTeam ~= nil and p.Team == myTeam)
                        if isTeammate and not UniversalModule.ShowTeammates then removeUniversalPlayerESP(p.Character)
                        else applyUniversalPlayerESP(p.Character, p, isTeammate) end
                    else
                        if p.Character then removeUniversalPlayerESP(p.Character) end
                    end
                end
            end
        end
    end)
end

-- Potato Mode (Patched with Safe Caching) & X-Ray Helpers
local function setPotatoMode(enabled)
    UniversalModule.PotatoMode = enabled
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                if enabled then
                    if not cachedPotatoStates[obj] then cachedPotatoStates[obj] = {Material = obj.Material, CastShadow = obj.CastShadow} end
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.CastShadow = false
                else
                    if cachedPotatoStates[obj] then
                        obj.Material = cachedPotatoStates[obj].Material
                        obj.CastShadow = cachedPotatoStates[obj].CastShadow
                    end
                end
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                if enabled then
                    if not cachedPotatoStates[obj] then cachedPotatoStates[obj] = {Transparency = obj.Transparency} end
                    obj.Transparency = 1
                else
                    if cachedPotatoStates[obj] then obj.Transparency = cachedPotatoStates[obj].Transparency end
                end
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                if enabled then
                    if not cachedPotatoStates[obj] then cachedPotatoStates[obj] = {Enabled = obj.Enabled} end
                    obj.Enabled = false
                else
                    if cachedPotatoStates[obj] then obj.Enabled = cachedPotatoStates[obj].Enabled end
                end
            end
        end
        Lighting.GlobalShadows = not enabled
        if not enabled then cachedPotatoStates = {} end
    end)
    Fluent:Notify({ Title = "Potato Mode", Content = enabled and "Max FPS optimizations applied." or "Graphics safely restored.", Duration = 3 })
end

local function setXRay(enabled)
    UniversalModule.XRay = enabled
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not (LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character)) then
                if enabled then
                    if not cachedXRayParts[obj] then cachedXRayParts[obj] = obj.Transparency end
                    obj.Transparency = math.max(obj.Transparency, 0.65)
                else
                    if cachedXRayParts[obj] then obj.Transparency = cachedXRayParts[obj] end
                end
            end
        end
        if not enabled then cachedXRayParts = {} end
    end)
end

-- UI Builder for Universal Tab
local function BuildUniversalTab(Tab)
    if not isMM2 then
        Tab:AddSection("Navigation")
        Tab:AddButton({ Title = "Teleport to Murder Mystery 2", Callback = TeleportToMM2 })
    end

    Tab:AddSection("Render & Clean Screen")
    Tab:AddToggle("UnivShowWatermark", { Title = "Show Tactical HUD Overlay", Default = false, Callback = function(v) showWatermark = v end })
    Tab:AddDropdown("UnivWatermarkPos", { Title = "HUD Overlay Position", Values = {"Top Left", "Top Center", "Top Right", "Middle Left", "Middle Right", "Bottom Left", "Bottom Center", "Bottom Right"}, Default = 2, Callback = function(v) 
        local p = hudPositions[v]
        if p then
            WMFrame.AnchorPoint = p.Anchor
            WMFrame.Position = p.Pos
        end
    end })
    Tab:AddToggle("UnivHideAvatars", { Title = "Hide Other Avatars (Friends Protected)", Default = false, Callback = function(v) hideAvatarsEnabled = v end })
    Tab:AddToggle("UnivHideGameGui", { Title = "Hide Game UI (Clean Screen)", Default = false, Callback = function(v) hideGameGuiEnabled = v end })

    Tab:AddSection("Flight & Locomotion")
    local FlyToggleUI = Tab:AddToggle("UnivFlyToggle", { 
        Title = "Character Fly Mode", 
        Default = false, 
        Callback = function(v) 
            UniversalModule.Fly = v 
            if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character.Humanoid.PlatformStand = false
            end
        end 
    })
    Tab:AddKeybind("UnivFlyBind", { Title = "Fly Keybind", Mode = "Toggle", Default = "None", Callback = function() FlyToggleUI:SetValue(not FlyToggleUI.Value) end })
    Tab:AddSlider("UnivFlySpeedSlider", { Title = "Flight Speed", Min = 0.5, Max = 10, Default = 2, Rounding = 1, Callback = function(v) UniversalModule.FlySpeed = v end })

    local NoclipToggleUI = Tab:AddToggle("UnivNoclipToggle", { Title = "Noclip (Ghost Walk)", Default = false, Callback = function(v) UniversalModule.Noclip = v end })
    Tab:AddKeybind("UnivNoclipBind", { Title = "Noclip Keybind", Mode = "Toggle", Default = "None", Callback = function() NoclipToggleUI:SetValue(not NoclipToggleUI.Value) end })

    Tab:AddSection("Movement & Character Physics")
    Tab:AddToggle("UnivInfJumpToggle", { Title = "Infinite Jump", Default = false, Callback = function(v) UniversalModule.InfJump = v end })
    Tab:AddToggle("UnivCtrlClickTP", { Title = "Ctrl + Click Teleport (Blink)", Default = false, Callback = function(v) UniversalModule.CtrlClickTP = v end })

    Tab:AddToggle("UnivSpeedToggle", { Title = "Enable Custom WalkSpeed", Default = false, Callback = function(v) 
        UniversalModule.SpeedEnabled = v 
        if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end
    end })
    Tab:AddSlider("UnivSpeedSlider", { Title = "WalkSpeed Value", Min = 16, Max = 150, Default = 16, Rounding = 0, Callback = function(v) UniversalModule.WalkSpeed = v end })

    Tab:AddToggle("UnivJumpPowerToggle", { Title = "Enable Custom JumpPower", Default = false, Callback = function(v) 
        UniversalModule.JumpPowerEnabled = v 
        if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.JumpPower = 50 end
    end })
    Tab:AddSlider("UnivJumpPowerSlider", { Title = "JumpPower Value", Min = 50, Max = 350, Default = 50, Rounding = 0, Callback = function(v) UniversalModule.JumpPowerValue = v end })

    Tab:AddToggle("UnivGravityToggle", { Title = "Enable Custom Gravity", Default = false, Callback = function(v) 
        UniversalModule.GravityEnabled = v; Workspace.Gravity = v and UniversalModule.GravityValue or 196.2
    end })
    Tab:AddSlider("UnivGravitySlider", { Title = "Gravity Value", Min = 0, Max = 196, Default = 196, Rounding = 1, Callback = function(v) 
        UniversalModule.GravityValue = v; if UniversalModule.GravityEnabled then Workspace.Gravity = v end
    end })

    Tab:AddSection("Automation & Defense")
    Tab:AddToggle("UnivAutoClickerToggle", { Title = "Universal Auto-Clicker", Default = false, Callback = function(v) UniversalModule.AutoClicker = v end })
    Tab:AddSlider("UnivAutoClickerCPSSlider", { Title = "Clicks Per Second (CPS)", Min = 5, Max = 35, Default = 15, Rounding = 0, Callback = function(v) UniversalModule.AutoClickerCPS = v end })
    Tab:AddToggle("UnivAntiFlingToggle", { Title = "Smart Anti-Fling (Ghost High-Torque Players)", Default = true, Callback = function(v) UniversalModule.AntiFling = v end })
    Tab:AddToggle("UnivAntiVoidToggle", { Title = "Anti-Void (Fall Saver)", Default = false, Callback = function(v) UniversalModule.AntiVoid = v end })
    Tab:AddToggle("UnivAntiAFKToggle", { Title = "Anti-AFK (Prevent 20m Kick)", Default = true, Callback = function(v) UniversalModule.AntiAFK = v end })

    Tab:AddSection("Freecam (Flight Camera)")
    -- Restored Exact 1.09 / 1.10 UI Toggle
    local FreecamToggleUI = Tab:AddToggle("UnivFreecamToggle", { 
        Title = "Enable Freecam (Right-Click to Aim)", 
        Default = false, 
        Callback = function(v) 
            freecamEnabled = v 
            local cam = Workspace.CurrentCamera
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if v and cam then
                freecamPosition = cam.CFrame.Position
                local rx, ry, rz = cam.CFrame:ToEulerAnglesYXZ()
                freecamPitch = rx
                freecamYaw = ry
                cam.CameraType = Enum.CameraType.Scriptable
                if hrp then hrp.Anchored = true end
            elseif cam then
                cam.CameraType = Enum.CameraType.Custom
                if hrp then hrp.Anchored = false end
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    cam.CameraSubject = LocalPlayer.Character.Humanoid
                end
            end
        end 
    })
    Tab:AddKeybind("UnivFreecamBind", { Title = "Freecam Keybind", Mode = "Toggle", Default = "None", Callback = function() FreecamToggleUI:SetValue(not FreecamToggleUI.Value) end })
    Tab:AddSlider("UnivFreecamSpeed", { Title = "Freecam Speed", Min = 0.5, Max = 10, Default = 1.5, Rounding = 1, Callback = function(v) freecamSpeed = v end })
    Tab:AddToggle("UnivFreecamWarp", { Title = "Freecam Warp (Press F to TP to Camera)", Default = false, Callback = function(v) freecamWarpEnabled = v end })

    if not isMM2 then
        Tab:AddSection("Universal Team-Based Player ESP")
        Tab:AddToggle("UnivESPToggle", { Title = "Enable Universal ESP", Default = false, Callback = function(v) UniversalModule.ESPEnabled = v end })
        Tab:AddToggle("UnivTeamColors", { Title = "Use In-Game Team Colors", Default = true, Callback = function(v) UniversalModule.UseTeamColors = v end })
        Tab:AddToggle("UnivShowTeammates", { Title = "Show Teammates", Default = true, Callback = function(v) UniversalModule.ShowTeammates = v end })
        Tab:AddToggle("UnivShowNames", { Title = "Show Player Names", Default = true, Callback = function(v) UniversalModule.ShowNames = v end })
        Tab:AddToggle("UnivShowDistance", { Title = "Show Distance [Studs]", Default = true, Callback = function(v) UniversalModule.ShowDistance = v end })
        
        local cEnemy = Tab:AddColorpicker("UnivEnemyColor", { Title = "Enemy Color Override", Default = UniversalModule.EnemyColor })
        cEnemy:OnChanged(function() UniversalModule.EnemyColor = cEnemy.Value end)
        
        local cTeam = Tab:AddColorpicker("UnivTeamColor", { Title = "Teammate Color Override", Default = UniversalModule.TeammateColor })
        cTeam:OnChanged(function() UniversalModule.TeammateColor = cTeam.Value end)
    end

    Tab:AddSection("World Manipulation & Optimization")
    Tab:AddToggle("UnivAltClickDelete", { Title = "Alt + Click Delete (Client BTools)", Default = false, Callback = function(v) UniversalModule.AltClickDelete = v end })
    Tab:AddToggle("UnivXRayToggle", { Title = "X-Ray Map Walls (65% Transparency)", Default = false, Callback = setXRay })
    Tab:AddToggle("UnivPotatoToggle", { Title = "Potato Mode / Ultra FPS Booster", Default = false, Callback = setPotatoMode })

    Tab:AddSection("World Lighting & Visual Shaders")
    Tab:AddToggle("UnivFullbrightToggle", { 
        Title = "Fullbright (No Shadows / Clear Vision)", 
        Default = false, 
        Callback = function(v) 
            UniversalModule.Fullbright = v 
            if v then
                Lighting.Ambient = Color3.fromRGB(255, 255, 255); Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
            else
                Lighting.Ambient = originalLightingState.Ambient; Lighting.OutdoorAmbient = originalLightingState.OutdoorAmbient
                Lighting.Brightness = originalLightingState.Brightness; Lighting.ClockTime = originalLightingState.ClockTime
                Lighting.FogEnd = originalLightingState.FogEnd; Lighting.GlobalShadows = originalLightingState.GlobalShadows
            end
        end 
    })
    Tab:AddToggle("UnivShadersToggle", { Title = "Enhanced Shaders / RTX Preset", Default = false, Callback = setupShaders })
    Tab:AddSlider("UnivFOVSlider", { Title = "Field of View (FOV)", Min = 50, Max = 120, Default = 70, Rounding = 0, Callback = function(v) UniversalModule.FOV = v end })
    Tab:AddSlider("UnivClockTimeSlider", { Title = "Time of Day", Min = 0, Max = 24, Default = 14, Rounding = 1, Callback = function(v) if not UniversalModule.Fullbright then Lighting.ClockTime = v end end })
    Tab:AddSlider("UnivBrightnessSlider", { Title = "Brightness", Min = 0, Max = 10, Default = 2, Rounding = 1, Callback = function(v) if not UniversalModule.Fullbright then Lighting.Brightness = v end end })
    
    local cAmb = Tab:AddColorpicker("UnivAmbientPicker", { Title = "Ambient Color", Default = Lighting.Ambient })
    cAmb:OnChanged(function() if not UniversalModule.Fullbright then Lighting.Ambient = cAmb.Value end end)

    local cOutAmb = Tab:AddColorpicker("UnivOutAmbientPicker", { Title = "Outdoor Ambient Color", Default = Lighting.OutdoorAmbient })
    cOutAmb:OnChanged(function() if not UniversalModule.Fullbright then Lighting.OutdoorAmbient = cOutAmb.Value end end)

    Tab:AddSlider("UnivFogEndSlider", { Title = "Fog Distance", Min = 100, Max = 5000, Default = 1000, Rounding = 0, Callback = function(v) if not UniversalModule.Fullbright then Lighting.FogEnd = v end end })
    local cFog = Tab:AddColorpicker("UnivFogPicker", { Title = "Fog Color", Default = Lighting.FogColor })
    cFog:OnChanged(function() if not UniversalModule.Fullbright then Lighting.FogColor = cFog.Value end end)

    Tab:AddSection("Camera & View Limits")
    Tab:AddToggle("UnivInfZoomToggle", { 
        Title = "Infinite Camera Zoom Limit", 
        Default = false, 
        Callback = function(v) 
            UniversalModule.InfZoom = v 
            LocalPlayer.CameraMaxZoomDistance = v and 100000 or 128
            LocalPlayer.CameraMinZoomDistance = v and 0 or 0.5
        end 
    })
    Tab:AddToggle("UnivNoCamShake", { Title = "Disable Camera Bobbing & Shake", Default = false, Callback = function(v) UniversalModule.NoCamShake = v end })

    Tab:AddSection("Server Utilities")
    Tab:AddToggle("UnivLogJoins", { Title = "Log Joins/Leaves in Native Chat", Default = false, Callback = function(v) logJoinsLeaves = v end })
    Tab:AddButton({ Title = "Rejoin Current Server", Callback = UniversalRejoin })
    Tab:AddButton({ Title = "Server Hop (Search Lowest Ping)", Callback = UniversalServerHop })
end

---------------------------------------------------------
-- 5. MM2 SPECIFIC LOGIC (ACTIVE ONLY IN MM2)
---------------------------------------------------------
local cachedPlayerRoles = {}
local cachedLobbyStates = {}
local cachedHoldingState = {}
local localPlayerHasGun = false
local cachedTimerPart = nil
local activeMurdererName = nil
local cachedOddsString = ""
local lastOddsFetch = 0

if isMM2 then
    local function isGunTool(obj)
        if not obj or not obj:IsA("Tool") then return false end
        local name = obj.Name:lower()
        if string.find(name, "fake") or string.find(name, "toy") or string.find(name, "water") or string.find(name, "cap") or string.find(name, "candy") then return false end
        if name == "knife" or obj:FindFirstChild("KnifeScript") or obj:FindFirstChild("KnifeClient") then return false end
        local hasCombatScripts = obj:FindFirstChild("GunScript") or obj:FindFirstChild("GunClient")
        local hasCombatEvents = obj:FindFirstChild("Shoot") or obj:FindFirstChild("Reload") or (obj:FindFirstChild("Events") and obj.Events:FindFirstChild("Shoot"))
        if hasCombatScripts or hasCombatEvents then return true end
        if name == "gun" or name == "revolver" then return true end
        return false
    end

    local function isKnifeTool(obj)
        if not obj or not obj:IsA("Tool") then return false end
        local name = obj.Name:lower()
        return name == "knife" or obj:FindFirstChild("KnifeScript") or obj:FindFirstChild("KnifeClient")
    end

    local function playerHasGun(player)
        if not player then return false end
        local function scanInventory(parent)
            if not parent then return false end
            for _, obj in ipairs(parent:GetChildren()) do
                if obj:IsA("Tool") and isGunTool(obj) then return true end
            end
            return false
        end
        return scanInventory(player.Character) or scanInventory(player:FindFirstChild("Backpack"))
    end

    local function isGunEquipped()
        local char = LocalPlayer.Character
        if not char then return false end
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") and isGunTool(obj) then return true end
        end
        return false
    end

    local function isHoldingWeapon(player)
        if not player or not player.Character then return false end
        for _, item in ipairs(player.Character:GetChildren()) do
            if item:IsA("Tool") and (isGunTool(item) or isKnifeTool(item)) then return true end
        end
        return false
    end

    -- Background MM2 Worker Thread
    task.spawn(function()
        while task.wait(0.15) do
            localPlayerHasGun = isGunEquipped()
            if not cachedTimerPart or not cachedTimerPart.Parent then
                cachedTimerPart = Workspace:FindFirstChild("RoundTimerPart")
            end
            
            if not currentRoundActive and (tick() - lastOddsFetch > 5) then
                lastOddsFetch = tick()
                pcall(function()
                    local chance = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Extras"):WaitForChild("GetChance"):InvokeServer()
                    if chance then cachedOddsString = " | Murderer Odds: " .. tostring(chance) .. "%" end
                end)
            elseif currentRoundActive then
                cachedOddsString = ""
            end

            local trueSheriffDead = false
            local trueSheriffFound = false
            activeMurdererName = nil

            for _, data in pairs(serverPlayerData) do
                if data.Role == "Sheriff" then
                    trueSheriffFound = true
                    if data.Killed or data.Dead then trueSheriffDead = true end
                elseif data.Role == "Murderer" then
                    for pName, d in pairs(serverPlayerData) do
                        if d.Role == "Murderer" then activeMurdererName = pName break end
                    end
                end
            end

            for _, p in ipairs(Players:GetPlayers()) do
                local inLobby = false
                local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                local pData = serverPlayerData[p.Name]
                
                if not currentRoundActive then inLobby = true
                elseif type(pData) == "table" and (pData.Killed or pData.Dead) then inLobby = true
                elseif hrp and cachedTimerPart then
                    if (hrp.Position - cachedTimerPart.Position).Magnitude < 1000 then inLobby = true end
                end
                cachedLobbyStates[p.Name] = inLobby

                local role = "Innocent"
                if type(pData) == "table" and (pData.Killed or pData.Dead) then role = "Dead"
                elseif type(pData) == "table" and pData.Role == "Murderer" then
                    role = "Murderer"
                    activeMurdererName = p.Name
                elseif type(pData) == "table" and (pData.Role == "Sheriff" or pData.Role == "Hero") then role = "Sheriff"
                elseif playerHasGun(p) then
                    if trueSheriffFound and not trueSheriffDead and (pData and pData.Role ~= "Sheriff") then
                        role = "Innocent"
                    else
                        role = "Sheriff"
                    end
                else
                    if type(pData) == "table" and pData.Role and pData.Role ~= "" then role = pData.Role
                    else role = "Innocent" end
                end
                cachedPlayerRoles[p.Name] = role
                cachedHoldingState[p.Name] = isHoldingWeapon(p)
            end
        end
    end)
end

local function getPlayerNameFormat(player)
    local baseName = ""
    if streamerModeEnabled and player == LocalPlayer then baseName = streamerCustomName 
    elseif espStyle.NameDisplay == "Username" then baseName = player.Name 
    elseif espStyle.NameDisplay == "Display Name" then baseName = player.DisplayName 
    else baseName = player.DisplayName .. " (@" .. player.Name .. ")" end

    if showHoldingIndicator and cachedHoldingState[player.Name] then
        baseName = baseName .. " <font color=\"#FFA500\">[EQUIPPED]</font>"
    end
    return baseName
end

local function getDistanceStr(targetPos)
    if not targetPos or not espStyle.ShowDistance then return "" end
    local cam = Workspace.CurrentCamera
    if not cam then return "" end
    local dist = math.floor((cam.CFrame.Position - targetPos).Magnitude)
    return " [" .. dist .. "s]"
end

local function ParseVector3(str)
    if not str or str == "" then return nil end
    local cleanStr = string.gsub(str, " ", "")
    local split = string.split(cleanStr, ",")
    if #split == 3 then
        local x, y, z = tonumber(split[1]), tonumber(split[2]), tonumber(split[3])
        if x and y and z then return Vector3.new(x, y, z) end
    end
    return nil
end

local function getClosestPlayerToCursor(fov)
    local cam = Workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()
    local closest = nil
    local shortestDist = fov

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 and not cachedLobbyStates[p.Name] then
                local pos, onScreen = cam:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = p
                    end
                end
            end
        end
    end
    return closest
end

---------------------------------------------------------
-- 6. MM2 ESP ENGINES
---------------------------------------------------------
local function removePlayerEsp(target)
    if not target then return end
    local h = target:FindFirstChild("MM2_Highlight")
    local n = target:FindFirstChild("MM2_Name")
    local b = target:FindFirstChild("MM2_TracerBeam")
    if h then h:Destroy() end
    if n then n:Destroy() end
    if b then b:Destroy() end
    
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if hrp then
        local ta = hrp:FindFirstChild("MM2_TarTracerAttach")
        if ta then ta:Destroy() end
    end
end

local function applyPlayerEsp(target, role, player, doTextUpdate)
    local color = roleColors[role]
    local cachedSeq = cachedRoleColors[role]
    
    if player and LocalPlayer:IsFriendsWith(player.UserId) then 
        if role == "Innocent" or role == "Dead" then
            color = roleColors.Friend
            cachedSeq = cachedRoleColors.Friend
        end
    end
    
    if not target or not color then return removePlayerEsp(target) end
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return removePlayerEsp(target) end

    if espStyle.Type == "Tracer" then
        local h = target:FindFirstChild("MM2_Highlight")
        if h then h:Destroy() end

        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myHRP then
            local myAttach = myHRP:FindFirstChild("MM2_MyTracerAttach")
            if not myAttach then
                myAttach = Instance.new("Attachment")
                myAttach.Name = "MM2_MyTracerAttach"
                myAttach.Parent = myHRP
            end

            local tarAttach = hrp:FindFirstChild("MM2_TarTracerAttach")
            if not tarAttach then
                tarAttach = Instance.new("Attachment")
                tarAttach.Name = "MM2_TarTracerAttach"
                tarAttach.Parent = hrp
            end

            local beam = target:FindFirstChild("MM2_TracerBeam")
            if not beam then
                beam = Instance.new("Beam")
                beam.Name = "MM2_TracerBeam"
                beam.FaceCamera = true
                beam.Width0 = 0.15
                beam.Width1 = 0.15
                beam.LightEmission = 1
                beam.LightInfluence = 0
                beam.Attachment0 = myAttach
                beam.Attachment1 = tarAttach
                beam.Parent = target
            end
            if beam.Color ~= cachedSeq then beam.Color = cachedSeq end
            if beam.Transparency ~= espStyle.TransSeq then beam.Transparency = espStyle.TransSeq end
        end
    else
        local b = target:FindFirstChild("MM2_TracerBeam")
        if b then b:Destroy() end
        local ta = hrp:FindFirstChild("MM2_TarTracerAttach")
        if ta then ta:Destroy() end

        local highlight = target:FindFirstChild("MM2_Highlight")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "MM2_Highlight"
            highlight.Adornee = target
            highlight.FillColor = color
            highlight.OutlineColor = color
            highlight.DepthMode = espStyle.DepthMode == "Always On Top" and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            highlight.FillTransparency = espStyle.Type == "Glow" and 1 or espStyle.FillTransparency
            highlight.OutlineTransparency = espStyle.Type == "Glow" and 0 or espStyle.OutlineTransparency
            highlight.Parent = target
        else
            if highlight.FillColor ~= color then
                highlight.FillColor = color
                highlight.OutlineColor = color
            end
        end
    end

    if showNameESP and player then
        local nameGui = target:FindFirstChild("MM2_Name")
        if not nameGui then
            nameGui = Instance.new("BillboardGui")
            nameGui.Name = "MM2_Name"
            nameGui.AlwaysOnTop = true
            nameGui.Size = UDim2.new(0, 200, 0, 40)
            nameGui.StudsOffset = Vector3.new(0, 3.5, 0)
            nameGui.Adornee = hrp
            
            local text = Instance.new("TextLabel")
            text.Name = "NameText"
            text.Size = UDim2.new(1, 0, 1, 0)
            text.BackgroundTransparency = 1
            text.Font = Enum.Font.Code
            text.RichText = true
            text.TextStrokeTransparency = 0.5
            text.TextSize = espStyle.TextSize
            text.TextColor3 = color
            text.Text = getPlayerNameFormat(player) .. getDistanceStr(hrp.Position)
            text.Parent = nameGui
            nameGui.Parent = target
        elseif doTextUpdate then
            nameGui.NameText.TextSize = espStyle.TextSize
            if nameGui.NameText.TextColor3 ~= color then nameGui.NameText.TextColor3 = color end
            nameGui.NameText.Text = getPlayerNameFormat(player) .. getDistanceStr(hrp.Position)
        end
    else
        local n = target:FindFirstChild("MM2_Name")
        if n then n:Destroy() end
    end
end

local function removeGunEsp(target)
    if not target then return end
    local h = target:FindFirstChild("MM2_GunHighlight")
    local n = target:FindFirstChild("MM2_Name")
    local b = target:FindFirstChild("MM2_TracerBeam")
    if h then h:Destroy() end
    if n then n:Destroy() end
    if b then b:Destroy() end
    
    local attachPart = target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart", true)
    if attachPart then
        local ta = attachPart:FindFirstChild("MM2_TarTracerAttach")
        if ta then ta:Destroy() end
    end
end

local function applyGunEsp(target, doTextUpdate)
    if not target then return end
    local attachPart = target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart", true)
    if not attachPart then return end
    local color = roleColors.GunDrop

    if espStyle.Type == "Tracer" then
        local h = target:FindFirstChild("MM2_GunHighlight")
        if h then h:Destroy() end

        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myHRP then
            local myAttach = myHRP:FindFirstChild("MM2_MyTracerAttach")
            if not myAttach then
                myAttach = Instance.new("Attachment")
                myAttach.Name = "MM2_MyTracerAttach"
                myAttach.Parent = myHRP
            end

            local tarAttach = attachPart:FindFirstChild("MM2_TarTracerAttach")
            if not tarAttach then
                tarAttach = Instance.new("Attachment")
                tarAttach.Name = "MM2_TarTracerAttach"
                tarAttach.Parent = attachPart
            end

            local beam = target:FindFirstChild("MM2_TracerBeam")
            if not beam then
                beam = Instance.new("Beam")
                beam.Name = "MM2_TracerBeam"
                beam.FaceCamera = true
                beam.Width0 = 0.15
                beam.Width1 = 0.15
                beam.LightEmission = 1
                beam.LightInfluence = 0
                beam.Attachment0 = myAttach
                beam.Attachment1 = tarAttach
                beam.Parent = target
            end
            if beam.Color ~= cachedRoleColors.GunDrop then beam.Color = cachedRoleColors.GunDrop end
            if beam.Transparency ~= espStyle.TransSeq then beam.Transparency = espStyle.TransSeq end
        end
    else
        local b = target:FindFirstChild("MM2_TracerBeam")
        if b then b:Destroy() end
        local ta = attachPart:FindFirstChild("MM2_TarTracerAttach")
        if ta then ta:Destroy() end

        local highlight = target:FindFirstChild("MM2_GunHighlight")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "MM2_GunHighlight"
            highlight.Adornee = target:IsA("Model") and target or attachPart
            highlight.FillColor = color
            highlight.OutlineColor = color
            highlight.DepthMode = espStyle.DepthMode == "Always On Top" and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            highlight.FillTransparency = espStyle.Type == "Glow" and 1 or espStyle.FillTransparency
            highlight.OutlineTransparency = espStyle.Type == "Glow" and 0 or espStyle.OutlineTransparency
            highlight.Parent = target
        end
    end

    if showGunNameESP then
        local nameGui = target:FindFirstChild("MM2_Name")
        if not nameGui then
            nameGui = Instance.new("BillboardGui")
            nameGui.Name = "MM2_Name"
            nameGui.AlwaysOnTop = true
            nameGui.Size = UDim2.new(0, 200, 0, 40)
            nameGui.StudsOffset = Vector3.new(0, 1.5, 0)
            nameGui.Adornee = attachPart
            
            local text = Instance.new("TextLabel")
            text.Name = "NameText"
            text.Size = UDim2.new(1, 0, 1, 0)
            text.BackgroundTransparency = 1
            text.Font = Enum.Font.Code
            text.TextStrokeTransparency = 0.5
            text.TextSize = espStyle.TextSize
            text.TextColor3 = color
            text.Text = "Dropped Gun" .. getDistanceStr(attachPart.Position)
            text.Parent = nameGui
            nameGui.Parent = target
        elseif doTextUpdate then
            nameGui.NameText.TextSize = espStyle.TextSize
            if nameGui.NameText.TextColor3 ~= color then nameGui.NameText.TextColor3 = color end
            nameGui.NameText.Text = "Dropped Gun" .. getDistanceStr(attachPart.Position)
        end
    else
        local n = target:FindFirstChild("MM2_Name")
        if n then n:Destroy() end
    end
end

---------------------------------------------------------
-- 7. MM2 SPECIFIC HOOKS & REMOTES
---------------------------------------------------------
local function executeKillAll()
    if not currentRoundActive or cachedPlayerRoles[LocalPlayer.Name] ~= "Murderer" then
        Fluent:Notify({ Title = "Kill All Failed", Content = "You must be the Murderer to execute Kill All.", Duration = 3 })
        return
    end
    local myChar = LocalPlayer.Character
    local knife = myChar and myChar:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
    if not knife then
        Fluent:Notify({ Title = "Kill All Failed", Content = "Knife not found! Equip it first.", Duration = 3 })
        return
    end
    local events = knife:FindFirstChild("Events")
    if not events then return end
    local stabEvent = events:FindFirstChild("KnifeStabbed")
    local touchEvent = events:FindFirstChild("HandleTouched")
    if not stabEvent or not touchEvent then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    
    local originalPos = myHRP.CFrame
    local count = 0
    task.spawn(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if excludeWhitelistFromKillAll and p.Name == whitelistedPlayerName then continue end
                local role = cachedPlayerRoles[p.Name] or "Innocent"
                if role ~= "Murderer" and role ~= "Dead" and not cachedLobbyStates[p.Name] then
                    local tHRP = p.Character.HumanoidRootPart
                    myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 1)
                    task.wait(0.05) 
                    stabEvent:FireServer()
                    touchEvent:FireServer(tHRP)
                    count = count + 1
                    task.wait(0.1) 
                end
            end
        end
        myHRP.CFrame = originalPos
        Fluent:Notify({ Title = "Packet Kill All", Content = "Eliminated " .. count .. " players via remote events.", Duration = 3 })
    end)
end

local function sendWhisper(targetPlayer, message)
    if not targetPlayer or not message then return end
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local id1 = math.min(LocalPlayer.UserId, targetPlayer.UserId)
            local id2 = math.max(LocalPlayer.UserId, targetPlayer.UserId)
            local channel = TextChatService.TextChannels:FindFirstChild("RBXWhisper:" .. id1 .. "_" .. id2)
            if channel then channel:SendAsync(message)
            else
                local general = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if general then general:SendAsync("/w @" .. targetPlayer.Name .. " " .. message) end
            end
        else
            local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
                chatEvents.SayMessageRequest:FireServer(message, "To " .. targetPlayer.Name)
            end
        end
        Fluent:Notify({ Title = "Whisper Dispatched", Content = "Alerted " .. targetPlayer.Name, Duration = 3 })
    end)
end

if isMM2 then
    local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
    if Remotes then
        local Gameplay = Remotes:WaitForChild("Gameplay", 5)
        if Gameplay then
            local GetCurrentPlayerData = Gameplay:WaitForChild("GetCurrentPlayerData", 5)
            local PlayerDataChanged = Gameplay:WaitForChild("PlayerDataChanged", 5)
            local LoadingMapEvent = Gameplay:FindFirstChild("LoadingMap")

            if LoadingMapEvent then
                LoadingMapEvent.OnClientEvent:Connect(function()
                    mapIsLoadingState = true
                    spamMap1, spamMap2, spamMap3 = false, false, false
                    pcall(function()
                        if SpamMap1Toggle then SpamMap1Toggle:SetValue(false) end
                        if SpamMap2Toggle then SpamMap2Toggle:SetValue(false) end
                        if SpamMap3Toggle then SpamMap3Toggle:SetValue(false) end
                    end)
                end)
            end

            local function syncRoles(data)
                if type(data) == "table" and next(data) ~= nil then
                    serverPlayerData = data
                    local hasRolesAssigned = false

                    for pName, pData in pairs(data) do
                        if type(pData) == "table" and pData.Role and pData.Role ~= "" then hasRolesAssigned = true end
                    end

                    if hasRolesAssigned and not currentRoundActive then
                        currentRoundActive = true
                        whisperedThisRound = false
                        knownSheriff = nil

                        local myData = data[LocalPlayer.Name]
                        if myData and myData.Role then
                            currentLocalRole = myData.Role
                            if notifySelfRole then Fluent:Notify({ Title = "Round Started", Content = "Your Role: " .. currentLocalRole, Duration = 6 }) end
                        end

                        if whitelistedPlayerName then
                            local wPlayer = Players:FindFirstChild(whitelistedPlayerName)
                            if wPlayer and notifyWhitelistRole then
                                local wData = data[whitelistedPlayerName]
                                if wData then Fluent:Notify({ Title = "Whitelist Role", Content = wPlayer.DisplayName .. " is: " .. wData.Role, Duration = 6 }) end
                            end

                            if wPlayer and not whisperedThisRound then
                                whisperedThisRound = true
                                task.spawn(function()
                                    task.wait(2.5) 
                                    local foundM = "None"
                                    local foundS = "None"
                                    for pName, role in pairs(cachedPlayerRoles) do
                                        if role == "Murderer" then foundM = pName end
                                        if role == "Sheriff" then foundS = pName end
                                    end
                                    local msgParts = {}
                                    if whisperIncludeMurderer and foundM ~= "None" then table.insert(msgParts, "Murderer: " .. foundM) end
                                    if whisperIncludeSheriff and foundS ~= "None" then table.insert(msgParts, "Sheriff: " .. foundS) end
                                    if #msgParts > 0 then sendWhisper(wPlayer, table.concat(msgParts, ", ")) end
                                end)
                            end
                        end
                    end
                else
                    serverPlayerData = {}
                    currentRoundActive = false
                    mapIsLoadingState = false 
                    currentLocalRole = "Innocent"
                    whisperedThisRound = false
                    knownSheriff = nil
                    activeGunDrop = nil
                end
            end

            if GetCurrentPlayerData then task.spawn(function() pcall(function() syncRoles(GetCurrentPlayerData:InvokeServer()) end) end) end
            if PlayerDataChanged then PlayerDataChanged.OnClientEvent:Connect(syncRoles) end
        end
    end
end

---------------------------------------------------------
-- 8. WEAPON CACHE PURGER & AVATAR CLEANER (MM2)
---------------------------------------------------------
if isMM2 then
    local WeaponDisplaysCache = nil
    task.spawn(function()
        while task.wait(1.5) do
            local wepDisp = Workspace:FindFirstChild("WeaponDisplays")
            if hideWepDisplays and wepDisp then
                WeaponDisplaysCache = wepDisp
                wepDisp.Parent = ReplicatedStorage
            elseif not hideWepDisplays and WeaponDisplaysCache then
                WeaponDisplaysCache.Parent = Workspace
                WeaponDisplaysCache = nil
            end
        end
    end)
end

---------------------------------------------------------
-- 9. SMART ANTI-FLING & RUNTIME PHYSICS LOOP
---------------------------------------------------------
local localPartsCache = {}
local function cacheLocalParts(char)
    localPartsCache = {}
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then table.insert(localPartsCache, v) end
    end
    char.DescendantAdded:Connect(function(v)
        if v:IsA("BasePart") then table.insert(localPartsCache, v) end
    end)
end
if LocalPlayer.Character then cacheLocalParts(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(cacheLocalParts)

RunService.Stepped:Connect(function(time, deltaTime)
    local myChar = LocalPlayer.Character
    if not myChar then return end

    -- 1. Noclip Engine
    if UniversalModule.Noclip then
        for _, part in ipairs(localPartsCache) do part.CanCollide = false end
    end

    -- 2. Custom Speed & JumpPower Engines
    local hum = myChar:FindFirstChildOfClass("Humanoid")
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")

    if hum then
        if UniversalModule.SpeedEnabled then hum.WalkSpeed = UniversalModule.WalkSpeed end
        if UniversalModule.JumpPowerEnabled then
            hum.UseJumpPower = true
            hum.JumpPower = UniversalModule.JumpPowerValue
            hum.JumpHeight = UniversalModule.JumpPowerValue / 7
        end
    end

    -- 3. Character Fly Loop
    if UniversalModule.Fly and myHRP and hum then
        hum.PlatformStand = true
        myHRP.AssemblyLinearVelocity = Vector3.zero
        myHRP.AssemblyAngularVelocity = Vector3.zero
        
        local cam = Workspace.CurrentCamera
        if cam then
            local moveVec = Vector3.zero
            if UniversalModule.FlyKeys.W then moveVec = moveVec + cam.CFrame.LookVector end
            if UniversalModule.FlyKeys.S then moveVec = moveVec - cam.CFrame.LookVector end
            if UniversalModule.FlyKeys.A then moveVec = moveVec - cam.CFrame.RightVector end
            if UniversalModule.FlyKeys.D then moveVec = moveVec + cam.CFrame.RightVector end
            if UniversalModule.FlyKeys.Space then moveVec = moveVec + Vector3.new(0, 1, 0) end
            if UniversalModule.FlyKeys.Shift then moveVec = moveVec - Vector3.new(0, 1, 0) end
            
            if moveVec.Magnitude > 0 then
                moveVec = moveVec.Unit * (UniversalModule.FlySpeed * 50)
            end
            myHRP.CFrame = myHRP.CFrame + (moveVec * deltaTime)
        end
    end

    -- 4. Anti-Void (Fall Saver)
    if UniversalModule.AntiVoid and myHRP and hum and hum.Health > 0 then
        if myHRP.Position.Y > -30 then
            if hum.FloorMaterial ~= Enum.Material.Air then
                lastSafePos = myHRP.Position
            end
        elseif myHRP.Position.Y < -40 then
            myHRP.AssemblyLinearVelocity = Vector3.zero
            myHRP.CFrame = CFrame.new(lastSafePos + Vector3.new(0, 5, 0))
            Fluent:Notify({Title="Anti-Void Triggered", Content="Saved from falling into the void.", Duration=2})
        end
    end

    -- 5. PROACTIVE SMART ANTI-FLING
    if UniversalModule.AntiFling and myHRP then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local pHRP = p.Character:FindFirstChild("HumanoidRootPart")
                if pHRP then
                    local pDist = (pHRP.Position - myHRP.Position).Magnitude
                    local pVel = pHRP.AssemblyLinearVelocity or pHRP.Velocity
                    local pRot = pHRP.AssemblyAngularVelocity or pHRP.RotVelocity

                    if pDist < 40 then
                        local isHighTorqueFlinger = (pRot.Magnitude > 85)
                        local isExtremeRammer = (pVel.Magnitude > 140)

                        if isHighTorqueFlinger or isExtremeRammer then
                            ghostedCharacters[p.Character] = true
                            for _, part in ipairs(p.Character:GetChildren()) do
                                if part:IsA("BasePart") then part.CanCollide = false end
                            end

                            local lastAlert = flingerAlertDebounce[p.Name] or 0
                            if isHighTorqueFlinger and (tick() - lastAlert > 8) then
                                flingerAlertDebounce[p.Name] = tick()
                                Fluent:Notify({
                                    Title = "Anti-Fling Triggered",
                                    Content = p.DisplayName .. " is flinging! Ghosting applied.",
                                    Duration = 4
                                })
                            end
                        else
                            if ghostedCharacters[p.Character] and pVel.Magnitude < 40 and pRot.Magnitude < 40 then
                                ghostedCharacters[p.Character] = nil
                                for _, part in ipairs(p.Character:GetChildren()) do
                                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then 
                                        part.CanCollide = true 
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        local myVel = myHRP.AssemblyLinearVelocity or myHRP.Velocity
        local myRot = myHRP.AssemblyAngularVelocity or myHRP.RotVelocity
        if myVel.Magnitude > 150 or myRot.Magnitude > 150 then
            myHRP.AssemblyLinearVelocity = Vector3.zero
            myHRP.AssemblyAngularVelocity = Vector3.zero
            pcall(function()
                myHRP.Velocity = Vector3.zero
                myHRP.RotVelocity = Vector3.zero
            end)
        end
    end
end)

-- Gun Reload Bar Animation Hook (MM2)
if isMM2 then
    local activeReloadTween = nil
    local function hookReloadAnimation(char)
        local hum = char:WaitForChild("Humanoid", 3)
        if hum then
            local animator = hum:WaitForChild("Animator", 3)
            if animator then
                animator.AnimationPlayed:Connect(function(track)
                    if not showReloadBar or not localPlayerHasGun then return end
                    if track.Priority == Enum.AnimationPriority.Action or string.find(track.Name:lower(), "reload") then
                        if track.Length > 1.5 and track.Length < 3.5 then
                            if activeReloadTween then activeReloadTween:Cancel() end
                            RFrame.Visible = true
                            RBar.Size = UDim2.new(0, 0, 1, 0)
                            activeReloadTween = TweenService:Create(RBar, TweenInfo.new(track.Length, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)})
                            activeReloadTween.Completed:Connect(function(state)
                                if state == Enum.PlaybackState.Completed then RFrame.Visible = false end
                            end)
                            activeReloadTween:Play()
                        end
                    end
                end)
            end
        end
    end
    if LocalPlayer.Character then hookReloadAnimation(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(hookReloadAnimation)
end

---------------------------------------------------------
-- 10. GUN DROP & MAP VOTE BACKGROUND WORKERS (MM2)
---------------------------------------------------------
local function checkVotingAllowed(showNotif)
    if currentRoundActive or mapIsLoadingState then
        if showNotif then Fluent:Notify({ Title = "Voting Locked", Content = "Round is active/loading. Spammer locked.", Duration = 3 }) end
        return false
    end
    return true
end

if isMM2 then
    local function grabDroppedGun()
        if isGrabbingGun or not currentRoundActive or not activeGunDrop or not activeGunDrop.Parent then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local targetCF = activeGunDrop:IsA("BasePart") and activeGunDrop.CFrame or (activeGunDrop:FindFirstChildWhichIsA("BasePart", true) and activeGunDrop:FindFirstChildWhichIsA("BasePart", true).CFrame)
            if targetCF then
                isGrabbingGun = true
                local prevPos = hrp.CFrame
                hrp.CFrame = targetCF + Vector3.new(0, 1, 0)
                task.spawn(function()
                    task.wait(0.35)
                    if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.CFrame = prevPos end
                    task.wait(0.2)
                    isGrabbingGun = false
                end)
            end
        end
    end

    local function checkGunInstance(descendant)
        if descendant.Name == "GunDrop" and (descendant:IsA("Model") or descendant:IsA("BasePart")) then
            activeGunDrop = descendant
            Fluent:Notify({ Title = "Gun Dropped", Content = "The Sheriff's gun is free on the map.", Duration = 5 })
            if autoPickupGun and not playerHasGun(LocalPlayer) and currentRoundActive then grabDroppedGun() end
        end
    end
    Workspace.ChildAdded:Connect(checkGunInstance)
    Workspace.DescendantAdded:Connect(function(v) if v.Name == "GunDrop" then checkGunInstance(v) end end)
    Workspace.DescendantRemoving:Connect(function(descendant) if descendant == activeGunDrop then activeGunDrop = nil end end)

    task.spawn(function()
        while task.wait(0.1) do
            local activePadPos = nil
            if spamMap1 then activePadPos = padPos1
            elseif spamMap2 then activePadPos = padPos2
            elseif spamMap3 then activePadPos = padPos3 end

            if activePadPos then
                if checkVotingAllowed(false) then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChild("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        hrp.CFrame = CFrame.new(activePadPos)
                        local safeToKill = true
                        local t = 0
                        while t < math.max(0.05, spamSpeed) do
                            if not checkVotingAllowed(false) then safeToKill = false break end
                            task.wait(0.05)
                            t = t + 0.05
                        end
                        if safeToKill and hrp.Parent and hum.Parent and hum.Health > 0 then
                            if (hrp.Position - activePadPos).Magnitude < 15 and checkVotingAllowed(false) then
                                hum.Health = 0
                            end
                        end
                    end
                else
                    pcall(function()
                        if SpamMap1Toggle then SpamMap1Toggle:SetValue(false) end
                        if SpamMap2Toggle then SpamMap2Toggle:SetValue(false) end
                        if SpamMap3Toggle then SpamMap3Toggle:SetValue(false) end
                    end)
                    spamMap1, spamMap2, spamMap3 = false, false, false
                end
            end
        end
    end)
end

---------------------------------------------------------
-- 11. DEDICATED VISUALS THREADS (MM2)
---------------------------------------------------------
local fpsFrameCount = 0
local fpsAccumulator = 0
local currentFPS = 60

if isMM2 then
    task.spawn(function()
        local doTextUpdate = false
        local espFrameSkip = 0

        while task.wait(0.05) do
            local aliveCount = 0
            local mName = "?"
            local sName = "?"
            local currentHero = nil
            
            espFrameSkip = espFrameSkip + 1
            doTextUpdate = (espFrameSkip % 5 == 0)
            if espFrameSkip >= 100 then espFrameSkip = 0 end

            for _, player in ipairs(Players:GetPlayers()) do
                local role = cachedPlayerRoles[player.Name] or "Innocent"
                local inLobby = cachedLobbyStates[player.Name] or false
                
                if role ~= "Dead" and not inLobby then 
                    aliveCount = aliveCount + 1 
                    if role == "Murderer" then mName = string.sub(player.Name, 1, 8) end
                    if role == "Sheriff" then 
                        sName = string.sub(player.Name, 1, 8) 
                        currentHero = player
                    end
                end
                
                if player == LocalPlayer then
                    removePlayerEsp(player.Character)
                    continue
                end

                local char = player.Character
                if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 or role == "Dead" then
                    removePlayerEsp(char)
                    continue
                end

                local shouldDraw = false
                local isFriend = LocalPlayer:IsFriendsWith(player.UserId)

                if espStates.LobbyDisable and inLobby then
                    shouldDraw = false
                else
                    if espStates.Friend and isFriend then
                        shouldDraw = true
                    elseif smartEspEnabled and currentRoundActive then
                        if not inLobby then
                            if currentLocalRole == "Sheriff" or currentLocalRole == "Hero" then
                                if role == "Murderer" then shouldDraw = true end
                            elseif currentLocalRole == "Innocent" then
                                if role == "Murderer" or role == "Sheriff" then shouldDraw = true end
                            elseif currentLocalRole == "Murderer" then
                                if role == "Innocent" or role == "Sheriff" then shouldDraw = true end
                            end
                        end
                    else
                        if role and espStates[role] then shouldDraw = true end
                    end
                end

                if shouldDraw then applyPlayerEsp(char, role, player, doTextUpdate)
                else removePlayerEsp(char) end
            end

            if showWatermark then
                WMFrame.Visible = true
                local ping = "0"
                pcall(function() ping = tostring(math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())) end)
                
                if currentRoundActive then
                    local timerStr = ""
                    if cachedTimerPart and cachedTimerPart:FindFirstChild("SurfaceGui") and cachedTimerPart.SurfaceGui:FindFirstChild("Timer") then
                        local tText = cachedTimerPart.SurfaceGui.Timer.Text
                        if tText ~= "0" and tText ~= "0:00" and not string.find(tText:lower(), "load") and not string.find(tText:lower(), "select") then
                            timerStr = " | <b>Time:</b> " .. tText
                        end
                    end
                    WMText.Text = string.format("<b>TrannyWare</b> | FPS: %d | Ping: %sms%s | M: <font color=\"#FF5555\">%s</font> | S: <font color=\"#5599FF\">%s</font> | Alive: %d", currentFPS, ping, timerStr, mName, sName, aliveCount)
                else
                    WMText.Text = string.format("<b>TrannyWare</b> | FPS: %d | Ping: %sms | Status: <font color=\"#AAAAAA\">In Lobby</font>%s", currentFPS, ping, cachedOddsString)
                end
            else
                WMFrame.Visible = false
            end

            if currentRoundActive then
                if currentHero and currentHero ~= knownSheriff then
                    if knownSheriff ~= nil and notifyGunPickup then
                        Fluent:Notify({ Title = "Gun Picked Up", Content = currentHero.Name .. " is the new Sheriff.", Duration = 5 })
                    end
                    knownSheriff = currentHero
                end
            else
                knownSheriff = nil
            end

            if activeGunDrop and activeGunDrop.Parent then
                local drawGun = false
                if smartEspEnabled and currentRoundActive then drawGun = true 
                elseif espStates.GunDrop then drawGun = true end
                if drawGun then applyGunEsp(activeGunDrop, doTextUpdate) else removeGunEsp(activeGunDrop) end
            end
        end
    end)
else
    -- Universal Non-MM2 Watermark Updates
    task.spawn(function()
        while task.wait(0.08) do
            if showWatermark then
                WMFrame.Visible = true
                local ping = "0"
                pcall(function() ping = tostring(math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())) end)
                WMText.Text = string.format("<b>TrannyWare</b> | FPS: %d | Ping: %sms", currentFPS, ping)
            else
                WMFrame.Visible = false
            end
        end
    end)
end

-- Universal Render Loop (Camera, FOV, No-CamShake)
RunService.RenderStepped:Connect(function(deltaTime)
    local cam = Workspace.CurrentCamera
    if not cam then return end

    if not freecamEnabled then
        cam.FieldOfView = UniversalModule.FOV
    end

    -- Disable Camera Bobbing / Shake
    if UniversalModule.NoCamShake and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.CameraOffset = Vector3.zero end
    end

    fpsFrameCount = fpsFrameCount + 1
    fpsAccumulator = fpsAccumulator + deltaTime
    if fpsAccumulator >= 0.5 then
        currentFPS = math.floor(fpsFrameCount / fpsAccumulator)
        fpsFrameCount = 0
        fpsAccumulator = 0
    end

    -- Exact 1.09 / 1.10 Camera Spectate Override Loop
    if isSpectating and spectateTarget and spectateTarget.Character then
        local tHum = spectateTarget.Character:FindFirstChild("Humanoid")
        if tHum and cam.CameraSubject ~= tHum then
            cam.CameraSubject = tHum
        end
    elseif not isSpectating and not freecamEnabled then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            if cam.CameraSubject ~= LocalPlayer.Character.Humanoid then
                cam.CameraSubject = LocalPlayer.Character.Humanoid
            end
        end
    end

    -- Exact 1.09 / 1.10 Smooth Freecam Flight Loop
    if freecamEnabled then
        local moveVec = Vector3.new()
        if freecamKeys.W then moveVec = moveVec + Vector3.new(0, 0, -1) end
        if freecamKeys.S then moveVec = moveVec + Vector3.new(0, 0, 1) end
        if freecamKeys.A then moveVec = moveVec + Vector3.new(-1, 0, 0) end
        if freecamKeys.D then moveVec = moveVec + Vector3.new(1, 0, 0) end
        if freecamKeys.Space then moveVec = moveVec + Vector3.new(0, 1, 0) end
        if freecamKeys.Shift then moveVec = moveVec - Vector3.new(0, 1, 0) end

        local rotation = CFrame.fromEulerAnglesYXZ(freecamPitch, freecamYaw, 0)
        local lookVec = rotation.LookVector
        local rightVec = rotation.RightVector
        local upVec = rotation.UpVector
        
        local deltaPos = (lookVec * -moveVec.Z + rightVec * moveVec.X + upVec * moveVec.Y) * freecamSpeed
        freecamPosition = freecamPosition + deltaPos

        cam.CFrame = CFrame.new(freecamPosition) * rotation
    end

    -- MM2 Combat Hooks
    if isMM2 then
        if triggerBotEnabled and currentRoundActive and cachedPlayerRoles[LocalPlayer.Name] == "Sheriff" and localPlayerHasGun then
            if not tbDebounce then
                local tbTarget = getClosestPlayerToCursor(triggerBotFOV)
                if tbTarget and cachedPlayerRoles[tbTarget.Name] == "Murderer" then
                    local char = LocalPlayer.Character
                    local gun = char and (char:FindFirstChild("Gun") or char:FindFirstChild("Revolver"))
                    if gun and gun:FindFirstChild("Shoot") then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        local attach = hrp and hrp:FindFirstChild("GunRaycastAttachment")
                        local muzzle = attach and attach.WorldCFrame or nil
                        tbDebounce = true
                        gun.Shoot:FireServer(muzzle, tbTarget.Character.Head.CFrame)
                        task.delay(2.5, function() tbDebounce = false end)
                    end
                end
            end
        end
        
        if showReloadBar then
            local isReloading = false
            local char = LocalPlayer.Character
            if char and localPlayerHasGun then
                local hum = char:FindFirstChild("Humanoid")
                local animator = hum and hum:FindFirstChild("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        if track.Length > 2.0 and track.Length < 3.0 then
                            isReloading = true
                            RFrame.Visible = true
                            RBar.Size = UDim2.new(math.clamp(track.TimePosition / track.Length, 0, 1), 0, 1, 0)
                            break
                        end
                    end
                end
            end
            if not isReloading then RFrame.Visible = false end
        else
            RFrame.Visible = false
        end

        local foundMurdForArrow = false
        if showOffScreenArrows and currentRoundActive and not cachedLobbyStates[LocalPlayer.Name] then
            local myChar = LocalPlayer.Character
            local myHum = myChar and myChar:FindFirstChild("Humanoid")
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHRP and myHum and myHum.Health > 0 then
                local murdHRP = nil
                for pName, role in pairs(cachedPlayerRoles) do
                    if role == "Murderer" and not cachedLobbyStates[pName] then
                        local p = Players:FindFirstChild(pName)
                        if p and p.Character then murdHRP = p.Character:FindFirstChild("HumanoidRootPart") end
                        break
                    end
                end
                if murdHRP then
                    foundMurdForArrow = true
                    MurdArrow.Visible = true
                    MurdArrow.TextColor3 = roleColors.Murderer
                    MurdArrow.TextTransparency = arrowTrans
                    MurdArrow.TextStrokeTransparency = math.min(1, arrowTrans + 0.3)
                    
                    local myScreenPos, myOnScreen = cam:WorldToViewportPoint(myHRP.Position)
                    local centerX = myOnScreen and myScreenPos.X or (cam.ViewportSize.X / 2)
                    local centerY = myOnScreen and myScreenPos.Y or (cam.ViewportSize.Y / 2)
                    local delta3D = murdHRP.Position - myHRP.Position
                    local x = delta3D:Dot(cam.CFrame.RightVector)
                    local y = delta3D:Dot(cam.CFrame.UpVector)
                    local angle = math.atan2(y, x)
                    MurdArrow.Position = UDim2.new(0, centerX + (math.cos(angle) * arrowRadius), 0, centerY - (math.sin(angle) * arrowRadius))
                    MurdArrow.Rotation = -math.deg(angle) + 90
                end
            end
        end
        if not foundMurdForArrow then MurdArrow.Visible = false end
    end
end)

---------------------------------------------------------
-- 12. TAB CONSTRUCTORS & ROUTING
---------------------------------------------------------
local Tabs = {
    About      = Window:AddTab({ Title = "About", Icon = "info" }),
    Universal  = Window:AddTab({ Title = "Universal", Icon = "globe" })
}

if isMM2 then
    Tabs.Visuals  = Window:AddTab({ Title = "ESP & Visuals", Icon = "eye" })
    Tabs.Combat   = Window:AddTab({ Title = "Combat", Icon = "crosshair" })
    Tabs.Voting   = Window:AddTab({ Title = "Map Voting", Icon = "map" })
    Tabs.Intel    = Window:AddTab({ Title = "Intel & Social", Icon = "users" })
    Tabs.Misc     = Window:AddTab({ Title = "Misc", Icon = "box" })
end

Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })

-- About Tab
Tabs.About:AddParagraph("AboutPara1", { Title = "Hi, " .. LocalPlayer.DisplayName, Content = "Username: " .. LocalPlayer.Name .. "\nUser ID: " .. LocalPlayer.UserId })
Tabs.About:AddParagraph("AboutPara2", { Title = "TrannyWare Status", Content = "Running Environment: " .. (isMM2 and "Murder Mystery 2" or "Multi-Game Hub") .. "\nVersion: Release 1.00" })
if not isMM2 then Tabs.About:AddButton({ Title = "Teleport to Murder Mystery 2", Callback = TeleportToMM2 }) end

-- Build Universal Tab
BuildUniversalTab(Tabs.Universal)

-- MM2 Dedicated Tabs
if isMM2 then
    -- Visuals Tab
    Tabs.Visuals:AddSection("Manual ESP Toggles")
    Tabs.Visuals:AddToggle("MurdererESPToggle", { Title = "Murderer ESP", Default = false, Callback = function(v) espStates.Murderer = v end })
    Tabs.Visuals:AddToggle("SheriffESPToggle", { Title = "Sheriff / Hero ESP", Default = false, Callback = function(v) espStates.Sheriff = v end })
    Tabs.Visuals:AddToggle("InnocentESPToggle", { Title = "Innocent ESP", Default = false, Callback = function(v) espStates.Innocent = v end })
    Tabs.Visuals:AddToggle("GunDropESPToggle", { Title = "Dropped Gun ESP", Default = false, Callback = function(v) espStates.GunDrop = v end })
    Tabs.Visuals:AddToggle("FriendESPToggle", { Title = "Friend ESP (Independent Override)", Default = false, Callback = function(v) espStates.Friend = v end })

    Tabs.Visuals:AddSection("Smart Features")
    Tabs.Visuals:AddToggle("SmartESPToggle", { Title = "Automatic Smart ESP", Default = false, Callback = function(v) smartEspEnabled = v end })
    Tabs.Visuals:AddToggle("NameESPToggle", { Title = "Show Player Names", Default = false, Callback = function(v) showNameESP = v end })
    Tabs.Visuals:AddToggle("GunNameESPToggle", { Title = "Show Dropped Gun Text", Default = true, Callback = function(v) showGunNameESP = v end })
    Tabs.Visuals:AddToggle("ESPDistanceToggle", { Title = "Show Distance [Studs]", Default = true, Callback = function(v) espStyle.ShowDistance = v end })
    Tabs.Visuals:AddToggle("HoldingIndicatorToggle", { Title = "Show [EQUIPPED] Weapon Status", Default = true, Callback = function(v) showHoldingIndicator = v end })

    Tabs.Visuals:AddSection("Streamer Mode")
    Tabs.Visuals:AddToggle("StreamerToggle", { Title = "Enable Streamer Mode", Default = false, Callback = function(v) streamerModeEnabled = v end })
    Tabs.Visuals:AddInput("StreamerNameInput", { Title = "Fake Display Name", Default = "Streamer", Finished = true, Callback = function(v) streamerCustomName = v end })

    Tabs.Visuals:AddSection("Advanced Visuals")
    Tabs.Visuals:AddToggle("OffScreenArrows", { Title = "Orbital Avatar Arrow (Points to Murderer)", Default = false, Callback = function(v) showOffScreenArrows = v end })
    Tabs.Visuals:AddSlider("ArrowRadiusSlider", { Title = "Arrow Orbit Distance", Min = 30, Max = 250, Default = 65, Rounding = 0, Callback = function(v) arrowRadius = v end })
    Tabs.Visuals:AddSlider("ArrowTransSlider", { Title = "Arrow Transparency %", Min = 0, Max = 100, Default = 0, Rounding = 0, Callback = function(v) arrowTrans = (v/100) end })

    -- Combat Tab
    Tabs.Combat:AddSection("Gun Utilities")
    Tabs.Combat:AddToggle("AutoPickupToggle", { Title = "Auto-Teleport to Dropped Gun", Default = false, Callback = function(v) autoPickupGun = v end })
    Tabs.Combat:AddButton({ Title = "Grab Dropped Gun (Instant)", Callback = function() task.spawn(grabDroppedGun) end })
    local GrabGunBind = Tabs.Combat:AddKeybind("GrabGunBind", { Title = "Grab Gun Keybind", Default = "None", Callback = function() end })
    UserInputService.InputBegan:Connect(function(input, gpe) if not gpe and GrabGunBind.Value ~= "None" and input.KeyCode.Name == GrabGunBind.Value then task.spawn(grabDroppedGun) end end)

    Tabs.Combat:AddSection("Sheriff Auto-Aims")
    local TBToggle = Tabs.Combat:AddToggle("TriggerBotToggle", { Title = "Auto-Shoot Triggerbot", Default = false, Callback = function(v) triggerBotEnabled = v end })
    Tabs.Combat:AddKeybind("TriggerBotBind", { Title = "Toggle Triggerbot", Mode = "Toggle", Default = "None", Callback = function() TBToggle:SetValue(not TBToggle.Value) end })
    Tabs.Combat:AddSlider("TBFovSlider", { Title = "Triggerbot FOV Tolerance", Min = 10, Max = 150, Default = 40, Rounding = 0, Callback = function(v) triggerBotFOV = v end })
    Tabs.Combat:AddToggle("ReloadBarToggle", { Title = "Show Sync'd Reload Bar UI", Default = false, Callback = function(v) showReloadBar = v end })
    local ReloadColorPicker = Tabs.Combat:AddColorpicker("ReloadBarColorPicker", { Title = "Reload Bar Color", Default = Color3.fromRGB(60, 150, 255) })
    ReloadColorPicker:OnChanged(function() RBar.BackgroundColor3 = ReloadColorPicker.Value end)

    Tabs.Combat:AddSection("Murderer Reach & Kill Aura")
    Tabs.Combat:AddToggle("KillAuraToggle", { Title = "Enable Invisible Ghost Reach", Default = false, Callback = function(v) killAuraEnabled = v end })
    Tabs.Combat:AddSlider("KillAuraReach", { Title = "Ghost Reach Range (Studs)", Min = 5, Max = 25, Default = 15, Rounding = 1, Callback = function(v) stabReachRange = v end })
    Tabs.Combat:AddButton({ Title = "Execute Kill All (Insta-Win)", Callback = executeKillAll })
    Tabs.Combat:AddKeybind("KillAllBind", { Title = "Kill All Keybind", Default = "None", Callback = executeKillAll })
    Tabs.Combat:AddToggle("ExcludeWhitelistKA", { Title = "Exclude Whitelist Player from Kill All", Default = true, Callback = function(v) excludeWhitelistFromKillAll = v end })

    -- Map Voting Tab
    Tabs.Voting:AddSection("1. Setup Pad Positions")
    local Pad1Input = Tabs.Voting:AddInput("Pad1DataSave", { Title = "Pad 1 System Data", Default = "", Callback = function(v) padPos1 = ParseVector3(v) end })
    local Pad2Input = Tabs.Voting:AddInput("Pad2DataSave", { Title = "Pad 2 System Data", Default = "", Callback = function(v) padPos2 = ParseVector3(v) end })
    local Pad3Input = Tabs.Voting:AddInput("Pad3DataSave", { Title = "Pad 3 System Data", Default = "", Callback = function(v) padPos3 = ParseVector3(v) end })

    Tabs.Voting:AddButton({ Title = "Save Position: Map Pad 1", Callback = function() 
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
            padPos1 = LocalPlayer.Character.HumanoidRootPart.Position; Pad1Input:SetValue(tostring(padPos1)); Fluent:Notify({ Title = "Saved", Content = "Map 1 location stored.", Duration = 3 }) 
        end 
    end })
    Tabs.Voting:AddButton({ Title = "Save Position: Map Pad 2", Callback = function() 
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
            padPos2 = LocalPlayer.Character.HumanoidRootPart.Position; Pad2Input:SetValue(tostring(padPos2)); Fluent:Notify({ Title = "Saved", Content = "Map 2 location stored.", Duration = 3 }) 
        end 
    end })
    Tabs.Voting:AddButton({ Title = "Save Position: Map Pad 3", Callback = function() 
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
            padPos3 = LocalPlayer.Character.HumanoidRootPart.Position; Pad3Input:SetValue(tostring(padPos3)); Fluent:Notify({ Title = "Saved", Content = "Map 3 location stored.", Duration = 3 }) 
        end 
    end })

    Tabs.Voting:AddSection("2. Exploit Spammers")
    SpamMap1Toggle = Tabs.Voting:AddToggle("SpamMap1Toggle", { Title = "Spam Vote Map 1", Default = false, Callback = function(v) 
        if v and not checkVotingAllowed(true) then task.spawn(function() pcall(function() SpamMap1Toggle:SetValue(false) end) end); spamMap1 = false; return end
        spamMap1 = v; if v then pcall(function() if SpamMap2Toggle then SpamMap2Toggle:SetValue(false) end if SpamMap3Toggle then SpamMap3Toggle:SetValue(false) end end) end 
    end })
    SpamMap2Toggle = Tabs.Voting:AddToggle("SpamMap2Toggle", { Title = "Spam Vote Map 2", Default = false, Callback = function(v) 
        if v and not checkVotingAllowed(true) then task.spawn(function() pcall(function() SpamMap2Toggle:SetValue(false) end) end); spamMap2 = false; return end
        spamMap2 = v; if v then pcall(function() if SpamMap1Toggle then SpamMap1Toggle:SetValue(false) end if SpamMap3Toggle then SpamMap3Toggle:SetValue(false) end end) end 
    end })
    SpamMap3Toggle = Tabs.Voting:AddToggle("SpamMap3Toggle", { Title = "Spam Vote Map 3", Default = false, Callback = function(v) 
        if v and not checkVotingAllowed(true) then task.spawn(function() pcall(function() SpamMap3Toggle:SetValue(false) end) end); spamMap3 = false; return end
        spamMap3 = v; if v then pcall(function() if SpamMap1Toggle then SpamMap1Toggle:SetValue(false) end if SpamMap2Toggle then SpamMap2Toggle:SetValue(false) end end) end 
    end })

    Tabs.Voting:AddSection("Spam Keybinds")
    Tabs.Voting:AddKeybind("SpamMap1Bind", { Title = "Toggle Map 1 Spam", Mode = "Toggle", Default = "None", Callback = function() pcall(function() if SpamMap1Toggle then SpamMap1Toggle:SetValue(not SpamMap1Toggle.Value) end end) end })
    Tabs.Voting:AddKeybind("SpamMap2Bind", { Title = "Toggle Map 2 Spam", Mode = "Toggle", Default = "None", Callback = function() pcall(function() if SpamMap2Toggle then SpamMap2Toggle:SetValue(not SpamMap2Toggle.Value) end end) end })
    Tabs.Voting:AddKeybind("SpamMap3Bind", { Title = "Toggle Map 3 Spam", Mode = "Toggle", Default = "None", Callback = function() pcall(function() if SpamMap3Toggle then SpamMap3Toggle:SetValue(not SpamMap3Toggle.Value) end end) end })

    -- Intel Tab
    Tabs.Intel:AddSection("Spectate Players")
    local SpectateDropdown = Tabs.Intel:AddDropdown("SpectateDropdown", { Title = "Select Target", Values = {"None"}, Default = 1, Callback = function(v) end })
    Tabs.Intel:AddButton({ Title = "Refresh Player List", Callback = function()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(list, p.Name) end end
        SpectateDropdown:SetValues(list)
    end })
    Tabs.Intel:AddButton({ Title = "Start Spectating", Callback = function()
        local pName = SpectateDropdown.Value
        if pName and pName ~= "None" then
            local target = Players:FindFirstChild(pName)
            if target and target.Character and target.Character:FindFirstChild("Humanoid") then
                isSpectating = true; spectateTarget = target
                local cam = Workspace.CurrentCamera
                if cam then cam.CameraSubject = target.Character.Humanoid end
                Fluent:Notify({ Title = "Spectating", Content = "Viewing " .. target.DisplayName, Duration = 3 })
            end
        end
    end })
    Tabs.Intel:AddButton({ Title = "Stop Spectating (Return to Self)", Callback = function()
        isSpectating = false; spectateTarget = nil
        local cam = Workspace.CurrentCamera
        if cam and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            cam.CameraSubject = LocalPlayer.Character.Humanoid
            Fluent:Notify({ Title = "Camera Reset", Content = "Returned to LocalPlayer.", Duration = 2 })
        end
    end })
    Tabs.Intel:AddKeybind("StopSpectateBind", { Title = "Stop Spectate Keybind", Default = "None", Callback = function()
        isSpectating = false; spectateTarget = nil
        local cam = Workspace.CurrentCamera
        if cam and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then cam.CameraSubject = LocalPlayer.Character.Humanoid end
    end })

    Tabs.Intel:AddSection("Player Warp")
    Tabs.Intel:AddButton({ Title = "Teleport to Selected Target", Callback = function()
        local pName = SpectateDropdown.Value
        if pName and pName ~= "None" then
            local target = Players:FindFirstChild(pName)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3) end
            end
        end
    end })

    Tabs.Intel:AddSection("Whitelisted Target Alerts")
    local WhitelistInput = Tabs.Intel:AddInput("WhitelistNameInput", {
        Title = "Type Whitelist Player Name", Default = "", Numeric = false, Finished = true,
        Callback = function(name)
            if name == "" then
                whitelistedPlayerName = nil; Fluent:Notify({ Title = "Whitelist Cleared", Content = "No player is whitelisted.", Duration = 3 })
            else
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Name:lower():sub(1, #name) == name:lower() or p.DisplayName:lower():sub(1, #name) == name:lower() then
                        whitelistedPlayerName = p.Name; Fluent:Notify({ Title = "Whitelist Updated", Content = "Linked to: " .. p.DisplayName, Duration = 4 })
                        if currentRoundActive then
                            local foundM = "None"; local foundS = "None"
                            for pName, role in pairs(cachedPlayerRoles) do
                                if role == "Murderer" then foundM = pName end
                                if role == "Sheriff" then foundS = pName end
                            end
                            local msgParts = {}
                            if whisperIncludeMurderer and foundM ~= "None" then table.insert(msgParts, "Murderer: " .. foundM) end
                            if whisperIncludeSheriff and foundS ~= "None" then table.insert(msgParts, "Sheriff: " .. foundS) end
                            if #msgParts > 0 then sendWhisper(p, table.concat(msgParts, ", ")) end
                        end
                        return
                    end
                end
                Fluent:Notify({ Title = "Error", Content = "Player not found.", Duration = 3 })
            end
        end
    })
    Tabs.Intel:AddToggle("NotifyWLToggle", { Title = "Notify Whitelist Player's Role", Default = true, Callback = function(v) notifyWhitelistRole = v end })
    Tabs.Intel:AddToggle("WhisperIncMurd", { Title = "Include Murderer in Whisper", Default = true, Callback = function(v) whisperIncludeMurderer = v end })
    Tabs.Intel:AddToggle("WhisperIncSher", { Title = "Include Sheriff in Whisper", Default = true, Callback = function(v) whisperIncludeSheriff = v end })
    Tabs.Intel:AddButton({ Title = "Clear / Unadd Whitelist", Callback = function() whitelistedPlayerName = nil; Fluent:Notify({ Title = "Whitelist Cleared", Content = "No player is currently whitelisted.", Duration = 3 }) end })

    -- Misc Tab
    Tabs.Misc:AddSection("Emote Unlocker")
    Tabs.Misc:AddToggle("EmoteUnlockToggle", { 
        Title = "Unlock All Emotes (Auto-Saves)", Default = false, Callback = function(v) 
            if v then
                task.spawn(function()
                    local success, err = pcall(function()
                        local ProfileData = require(ReplicatedStorage.Modules.ProfileData)
                        local Sync = require(ReplicatedStorage.Database.Sync)
                        if ProfileData and ProfileData.Emotes and ProfileData.Emotes.Owned and Sync and Sync.Emotes then
                            for emoteId, emoteData in pairs(Sync.Emotes) do
                                if type(emoteId) == "string" and type(emoteData) == "table" and emoteData.Name then
                                    if not table.find(ProfileData.Emotes.Owned, emoteId) then table.insert(ProfileData.Emotes.Owned, emoteId) end
                                end
                            end
                            if ReplicatedStorage.Remotes.Inventory:FindFirstChild("InventoryDataChanged") then ReplicatedStorage.Remotes.Inventory.InventoryDataChanged:Fire("Emotes") end
                        end
                    end)
                    if success then Fluent:Notify({Title="Emotes Unlocked", Content="Check your Emotes Menu in-game.", Duration=4})
                    else Fluent:Notify({Title="Spoof Failed", Content="Could not hook EmoteModule.", Duration=3}) end
                end)
            end
        end 
    })

    Tabs.Misc:AddSection("MM2 World Visuals")
    Tabs.Misc:AddToggle("HideDisplaysToggle", { Title = "Hide Lobby Weapon Displays (Boost FPS)", Default = false, Callback = function(v) hideWepDisplays = v end })
    Tabs.Misc:AddToggle("MuteAudioToggle", { 
        Title = "Auto-Mute Radios & Themes", Default = false, Callback = function(v) 
            muteRadiosAndThemes = v 
            local music = SoundService:FindFirstChild("Music")
            if music then music.Volume = v and 0 or 1 end
            pcall(function()
                local muteUI = LocalPlayer.PlayerGui.MainGUI.GameTopBar.Container.Mute.Container
                muteUI.Icon.MutedIcon.Visible = v
                muteUI.Icon.UnmutedIcon.Visible = not v
            end)
        end 
    })
    Tabs.Misc:AddToggle("GodlyEvasionToggle", { Title = "Godly Evasion (Anti-Stab Auto Blink)", Default = false, Callback = function(v) godlyEvasionEnabled = v end })
    Tabs.Misc:AddSlider("EvasionDistSlider", { Title = "Trigger Distance (Studs)", Min = 5, Max = 20, Default = 12, Rounding = 1, Callback = function(v) evasionDistance = v end })
end

-- Settings Tab
Tabs.Settings:AddSection("General Utilities")
local HideInjectToggle = Tabs.Settings:AddToggle("HideOnInjectToggle", { Title = "Minimize UI on Inject", Default = false, Callback = function(v) getgenv().HideOnInject = v end })

if isMM2 then
    Tabs.Settings:AddSection("ESP Customization")
    Tabs.Settings:AddDropdown("ESPTypeDropdown", { Title = "Render Style", Values = {"Glow", "Solid", "Tracer"}, Default = 1, Callback = function(v) espStyle.Type = v end })
    Tabs.Settings:AddDropdown("ESPDepthDropdown", { Title = "Depth Mode", Values = {"Always On Top", "Occluded (Hidden by Walls)"}, Default = 1, Callback = function(v) espStyle.DepthMode = v end })
    Tabs.Settings:AddDropdown("NameDisplayDrop", { Title = "Name Display Format", Values = {"Username", "Display Name", "Both"}, Default = 3, Callback = function(v) espStyle.NameDisplay = v end })
    Tabs.Settings:AddToggle("LobbyDisableToggle", { Title = "Disable ESP in Lobby", Default = true, Callback = function(v) espStates.LobbyDisable = v end })

    Tabs.Settings:AddSection("Adjustments")
    Tabs.Settings:AddSlider("FillTransSlider", { Title = "Fill Transparency %", Min = 0, Max = 100, Default = 45, Rounding = 0, Callback = function(v) espStyle.FillTransparency = (v / 100); espStyle.TransSeq = NumberSequence.new(v / 100) end })
    Tabs.Settings:AddSlider("OutlineTransSlider", { Title = "Outline Transparency %", Min = 0, Max = 100, Default = 0, Rounding = 0, Callback = function(v) espStyle.OutlineTransparency = (v / 100) end })
    Tabs.Settings:AddSlider("TextSizeSlider", { Title = "ESP Text Size", Min = 8, Max = 24, Default = 14, Rounding = 0, Callback = function(v) espStyle.TextSize = v end })

    Tabs.Settings:AddSection("Role Color Palette")
    local cMurd = Tabs.Settings:AddColorpicker("MurdColPicker", { Title = "Murderer Color", Default = roleColors.Murderer })
    cMurd:OnChanged(function() roleColors.Murderer = cMurd.Value; cachedRoleColors.Murderer = ColorSequence.new(cMurd.Value) end)
    local cSher = Tabs.Settings:AddColorpicker("SherColPicker", { Title = "Sheriff / Hero Color", Default = roleColors.Sheriff })
    cSher:OnChanged(function() roleColors.Sheriff = cSher.Value; cachedRoleColors.Sheriff = ColorSequence.new(cSher.Value) end)
    local cInno = Tabs.Settings:AddColorpicker("InnoColPicker", { Title = "Innocent Color", Default = roleColors.Innocent })
    cInno:OnChanged(function() roleColors.Innocent = cInno.Value; cachedRoleColors.Innocent = ColorSequence.new(cInno.Value) end)
    local cGun = Tabs.Settings:AddColorpicker("GunColPicker", { Title = "Dropped Gun Color", Default = roleColors.GunDrop })
    cGun:OnChanged(function() roleColors.GunDrop = cGun.Value; cachedRoleColors.GunDrop = ColorSequence.new(cGun.Value) end)
    local cFriend = Tabs.Settings:AddColorpicker("FriendColPicker", { Title = "Friend ESP Color", Default = roleColors.Friend })
    cFriend:OnChanged(function() roleColors.Friend = cFriend.Value; cachedRoleColors.Friend = ColorSequence.new(cFriend.Value) end)
end

---------------------------------------------------------
-- 13. PER-GAME ISOLATED CONFIG SAVER
---------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

local configFolder = isMM2 and "TrannyWare/MM2" or ("TrannyWare/Games/" .. tostring(game.PlaceId))
InterfaceManager:SetFolder("TrannyWare")
SaveManager:SetFolder(configFolder)

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

task.spawn(function()
    task.wait(1)
    if HideInjectToggle.Value then Window:Minimize() end
end)
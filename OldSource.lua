-- Instances and services setup
local AimbotGUI = Instance.new("ScreenGui")
local Background = Instance.new("Frame")
local Title = Instance.new("TextButton")
local EnableToggle = Instance.new("TextButton")
local TeamModeToggle = Instance.new("TextButton")
local WallCheckToggle = Instance.new("TextButton")
local Credits = Instance.new("TextLabel")
local FOVInput = Instance.new("TextBox")
local ESPToggle = Instance.new("TextButton")
local HitboxInput = Instance.new("TextBox")
local WhitelistInput = Instance.new("TextBox")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Cam = game.Workspace.CurrentCamera
local HttpService = game:GetService("HttpService")

local teamModeEnabled = false
local wallCheckEnabled = false
local espEnabled = false
local aimbotEnabled = false
local isCollapsed = false
local fov = 50
local espHighlights = {}
local whitelistedPlayers = {}
local targetHead = false -- Start with the root part
local currentTarget = nil -- Keep track of the current target
local targetSwitchTime = 0 -- Track time for switching target parts

local settingsFile = "AimbotSettings.json"

_G.HeadSize = 50
_G.Disabled = true  -- Initially disabled

-- Function to load settings
local function loadSettings()
    if isfile(settingsFile) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(settingsFile))
        end)
        if success and result then
            aimbotEnabled = result.aimbotEnabled or false
            teamModeEnabled = result.teamModeEnabled or false
            wallCheckEnabled = result.wallCheckEnabled or false
            espEnabled = result.espEnabled or false
            fov = result.fov or 50
            _G.HeadSize = result.headSize or 50
            _G.Disabled = result.disabled or true
            whitelistedPlayers = result.whitelistedPlayers or {}
        end
    end
end

-- Function to save settings
local function saveSettings()
    local settings = {
        aimbotEnabled = aimbotEnabled,
        teamModeEnabled = teamModeEnabled,
        wallCheckEnabled = wallCheckEnabled,
        espEnabled = espEnabled,
        fov = fov,
        headSize = _G.HeadSize,
        disabled = _G.Disabled,
        whitelistedPlayers = whitelistedPlayers
    }
    writefile(settingsFile, HttpService:JSONEncode(settings))
end

-- Function to determine ESP color based on team
local function getESPColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    else
        return Color3.fromRGB(255, 255, 255) -- Default to white if no team
    end
end

-- ESP Handling
local function createESP(player)
    if espHighlights[player] then return end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid and humanoid.Health > 0 then
        local highlight = Instance.new("Highlight")
        highlight.Parent = character
        highlight.Adornee = character
        highlight.FillColor = getESPColor(player) -- Set the color to the team's color
        highlight.FillTransparency = 0.7 -- Set transparency to 0.7
        
        if player.Team == LocalPlayer.Team then
            highlight.OutlineTransparency = 1 -- No outline for teammates
        else
            highlight.OutlineColor = Color3.new(1, 1, 1) -- White outline for opponents
            highlight.OutlineTransparency = 0 -- Full outline for opponents
        end
        
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

        espHighlights[player] = highlight

        -- Remove ESP when the player is dead
        humanoid.Died:Connect(function()
            removeESP(player)
        end)
    end
end

local function removeESP(player)
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
end

local function reapplyESP()
    for player, highlight in pairs(espHighlights) do
        if highlight then
            highlight:Destroy()
        end
        espHighlights[player] = nil
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            createESP(player)
        end
    end
end

task.spawn(function()
    while true do
        task.wait(5)
        if espEnabled then
            reapplyESP()
        end
    end
end)

local function isTargetVisible(player, lockPart)
    local character = player.Character
    if not character then return false end

    local part = character:FindFirstChild(lockPart)
    if not part then return false end

    local targetPosition = part.Position
    local ignoreList = {character, LocalPlayer.Character}

    local parts = Cam:GetPartsObscuringTarget({targetPosition}, ignoreList)
    return #parts == 0
end

-- Properties setup
AimbotGUI.Name = "AimbotGUI"
AimbotGUI.ResetOnSpawn = false
AimbotGUI.Parent = LocalPlayer:WaitForChild("PlayerGui")

Background.Name = "Background"
Background.Parent = AimbotGUI
Background.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
Background.Position = UDim2.new(0.5, -90, 0.5, -150)
Background.Size = UDim2.new(0, 180, 0, 340)
Background.Active = true
Background.Draggable = true

Title.Name = "Title"
Title.Parent = Background
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1.000
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSans
Title.Text = "Aimbot GUI"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18.000

EnableToggle.Name = "EnableToggle"
EnableToggle.Parent = Background
EnableToggle.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
EnableToggle.Position = UDim2.new(0.5, -50, 0, 40)
EnableToggle.Size = UDim2.new(0, 100, 0, 30)
EnableToggle.Font = Enum.Font.SourceSans
EnableToggle.Text = "Enable Aimbot"
EnableToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
EnableToggle.TextSize = 14.000

FOVInput.Name = "FOVInput"
FOVInput.Parent = Background
FOVInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FOVInput.Position = UDim2.new(0.5, -50, 0, 80) -- Position below the Enable Aimbot toggle
FOVInput.Size = UDim2.new(0, 100, 0, 20)
FOVInput.Font = Enum.Font.SourceSans
FOVInput.PlaceholderText = "Enter FOV"
FOVInput.Text = ""
FOVInput.TextColor3 = Color3.fromRGB(0, 0, 0)
FOVInput.TextSize = 14.000

TeamModeToggle.Name = "TeamModeToggle"
TeamModeToggle.Parent = Background
TeamModeToggle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
TeamModeToggle.Position = UDim2.new(0.5, -50, 0, 120)
TeamModeToggle.Size = UDim2.new(0, 100, 0, 30)
TeamModeToggle.Font = Enum.Font.SourceSans
TeamModeToggle.Text = "Team Mode: Off"
TeamModeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
TeamModeToggle.TextSize = 14.000

WhitelistInput.Name = "WhitelistInput"
WhitelistInput.Parent = Background
WhitelistInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
WhitelistInput.Position = UDim2.new(0.5, -50, 0, 160)
WhitelistInput.Size = UDim2.new(0, 100, 0, 20)
WhitelistInput.Font = Enum.Font.SourceSans
WhitelistInput.PlaceholderText = "Whitelist Player"
WhitelistInput.Text = ""
WhitelistInput.TextColor3 = Color3.fromRGB(0, 0, 0)
WhitelistInput.TextSize = 14.000

WallCheckToggle.Name = "WallCheckToggle"
WallCheckToggle.Parent = Background
WallCheckToggle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
WallCheckToggle.Position = UDim2.new(0.5, -50, 0, 190)
WallCheckToggle.Size = UDim2.new(0, 100, 0, 30)
WallCheckToggle.Font = Enum.Font.SourceSans
WallCheckToggle.Text = "Wall Check: Off"
WallCheckToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
WallCheckToggle.TextSize = 14.000

ESPToggle.Name = "ESPToggle"
ESPToggle.Parent = Background
ESPToggle.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
ESPToggle.Position = UDim2.new(0.5, -50, 0, 230)
ESPToggle.Size = UDim2.new(0, 100, 0, 30)
ESPToggle.Font = Enum.Font.SourceSans
ESPToggle.Text = "Enable ESP"
ESPToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPToggle.TextSize = 14.000

HitboxInput.Name = "HitboxInput"
HitboxInput.Parent = Background
HitboxInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HitboxInput.Position = UDim2.new(0.5, -50, 0, 270)
HitboxInput.Size = UDim2.new(0, 100, 0, 20)
HitboxInput.Font = Enum.Font.SourceSans
HitboxInput.PlaceholderText = "Enter Hitbox Size"
HitboxInput.Text = ""
HitboxInput.TextColor3 = Color3.fromRGB(0, 0, 0)
HitboxInput.TextSize = 14.000

Credits.Name = "Credits"
Credits.Parent = Background
Credits.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Credits.Position = UDim2.new(0, 0, 1, -20)
Credits.Size = UDim2.new(1, 0, 0, 20)
Credits.Font = Enum.Font.SourceSans
Credits.Text = "Made by Bloodscript"
Credits.TextColor3 = Color3.fromRGB(0, 0, 0)
Credits.TextSize = 14.000

-- Drawing FOV circle
local FOVring = Drawing.new("Circle")
FOVring.Visible = false
FOVring.Thickness = 2
FOVring.Color = Color3.fromRGB(128, 0, 128)
FOVring.Filled = false
FOVring.Radius = fov
FOVring.Position = Cam.ViewportSize / 2

local function updateDrawings()
    local camViewportSize = Cam.ViewportSize
    FOVring.Position = camViewportSize / 2
    FOVring.Radius = fov
end

local function lookAt(target)
    local lookVector = (target - Cam.CFrame.Position).unit
    local newCFrame = CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + lookVector)
    Cam.CFrame = newCFrame
end

local function getClosestPlayerInFOV()
    local nearest = nil
    local last = math.huge
    local playerMousePos = Cam.ViewportSize / 2
    local localTeam = LocalPlayer.Team

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local partName = targetHead and "Head" or "HumanoidRootPart"
            local part = character and character:FindFirstChild(partName)

            if part and humanoid and humanoid.Health > 0 then
                local ePos, isVisible = Cam:WorldToViewportPoint(part.Position)
                local distance = (Vector2.new(ePos.x, ePos.y) - playerMousePos).Magnitude

                if distance < last and isVisible and distance < fov then
                    local targetValid = (not teamModeEnabled or player.Team ~= localTeam)
                    local wallCheckValid = (not wallCheckEnabled or isTargetVisible(player, partName))
                    
                    -- Check if any part of the whitelist matches the player's name
                    local nameValid = true
                    for _, whitelistName in ipairs(whitelistedPlayers) do
                        if string.find(player.Name:lower(), whitelistName) then
                            nameValid = false
                            break
                        end
                    end

                    if targetValid and wallCheckValid and nameValid then
                        last = distance
                        nearest = player
                    end
                end
            end
        end
    end

    return nearest
end

local function toggleAimbot()
    aimbotEnabled = not aimbotEnabled

    if aimbotEnabled then
        EnableToggle.Text = "Disable Aimbot"
        FOVring.Visible = true
    else
        EnableToggle.Text = "Enable Aimbot"
        FOVring.Visible = false
    end
    saveSettings()
end

local function toggleTeamMode()
    teamModeEnabled = not teamModeEnabled

    if teamModeEnabled then
        TeamModeToggle.Text = "Team Mode: On"
        TeamModeToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        TeamModeToggle.Text = "Team Mode: Off"
        TeamModeToggle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
    saveSettings()
end

local function toggleWallCheck()
    wallCheckEnabled = not wallCheckEnabled

    if wallCheckEnabled then
        WallCheckToggle.Text = "Wall Check: On"
        WallCheckToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        WallCheckToggle.Text = "Wall Check: Off"
        WallCheckToggle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
    saveSettings()
end

local function toggleESP()
    espEnabled = not espEnabled
    reapplyESP()

    if espEnabled then
        ESPToggle.Text = "Disable ESP"
    else
        ESPToggle.Text = "Enable ESP"
    end
    saveSettings()
end

EnableToggle.MouseButton1Click:Connect(toggleAimbot)
TeamModeToggle.MouseButton1Click:Connect(toggleTeamMode)
WallCheckToggle.MouseButton1Click:Connect(toggleWallCheck)
ESPToggle.MouseButton1Click:Connect(toggleESP)

FOVInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local inputFOV = tonumber(FOVInput.Text)
        if inputFOV and inputFOV > 0 then
            fov = inputFOV
            FOVring.Radius = fov
        else
            FOVInput.Text = ""
        end
        saveSettings()
    end
end)

HitboxInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local inputHitboxSize = tonumber(HitboxInput.Text)
        if inputHitboxSize and inputHitboxSize > 0 then
            _G.HeadSize = inputHitboxSize
            _G.Disabled = false -- Enable hitbox manipulation when size is entered
        else
            _G.HeadSize = 50
            _G.Disabled = true -- Disable hitbox manipulation if invalid input
            HitboxInput.Text = ""
        end
        saveSettings()
    end
end)

WhitelistInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        whitelistedPlayers = {}
        for name in WhitelistInput.Text:gmatch("%S+") do  -- Split input by spaces
            table.insert(whitelistedPlayers, name:lower())
        end
        saveSettings()
    end
end)

-- Update hitbox sizes based on the head size
RunService.RenderStepped:Connect(function(deltaTime)
    if not _G.Disabled then
        for i, v in next, Players:GetPlayers() do
            if v.Name ~= LocalPlayer.Name then
                pcall(function()
                    v.Character.HumanoidRootPart.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize)
                    v.Character.HumanoidRootPart.Transparency = 0.8
                    v.Character.HumanoidRootPart.BrickColor = BrickColor.new("Really black")
                    v.Character.HumanoidRootPart.Material = "Neon"
                    v.Character.HumanoidRootPart.CanCollide = false
                end)
            end
        end
    end
end)

local function toggleGUI()
    isCollapsed = not isCollapsed

    if isCollapsed then
        Background.Size = UDim2.new(0, 180, 0, 30)
        EnableToggle.Visible = false
        FOVInput.Visible = false
        ESPToggle.Visible = false
        HitboxInput.Visible = false
        Credits.Visible = false
        TeamModeToggle.Visible = false
        WallCheckToggle.Visible = false
        WhitelistInput.Visible = false
    else
        Background.Size = UDim2.new(0, 180, 0, 340)
        EnableToggle.Visible = true
        FOVInput.Visible = true
        ESPToggle.Visible = true
        HitboxInput.Visible = true
        Credits.Visible = true
        TeamModeToggle.Visible = true
        WallCheckToggle.Visible = true
        WhitelistInput.Visible = true
    end
end

Title.MouseButton1Click:Connect(toggleGUI)

RunService.RenderStepped:Connect(function(deltaTime)
    updateDrawings()
    if aimbotEnabled then
        local closest = getClosestPlayerInFOV()
        if closest ~= currentTarget then
            currentTarget = closest
            targetHead = false -- Start with the root part
            targetSwitchTime = 0 -- Reset the switch timer
        end

        if currentTarget and currentTarget.Character then
            targetSwitchTime = targetSwitchTime + deltaTime
            if targetSwitchTime >= 1 then
                targetHead = not targetHead -- Toggle head/root part every 1 second
                targetSwitchTime = 0 -- Reset the timer
            end

            local partName = targetHead and "Head" or "HumanoidRootPart"
            local part = currentTarget.Character:FindFirstChild(partName)
            if part then
                lookAt(part.Position)
            end
        end
    end
end)

-- Load settings on script start
loadSettings()

--[[
    Title: ☁️ Heaven | Aimbot
    Version: 3.0
    Enhanced by: Gemini + ChatGPT
]]

--================================================================================
--// Services & Core Variables
--================================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--================================================================================
--// Configuration & Settings
--================================================================================
local SETTINGS_FILE = "HeavenSettings.json"

local Config = {
    aimbotEnabled = false,
    smoothAimEnabled = true,
    targetPart = "HumanoidRootPart",
    fovRadius = 120,
    smoothness = 0.15,
    wallCheck = false,
    teamCheck = false,
    whitelist = {},
    espLinesEnabled = true,
    espChamsEnabled = false,
    hitboxModEnabled = false,
    hitboxSize = 4,
    hitboxTransparency = 0.5,
    accentColor = Color3.fromRGB(135, 206, 235),
    onColor = Color3.fromRGB(80, 200, 130),
    offColor = Color3.fromRGB(220, 70, 70),
    bgColor = Color3.fromRGB(28, 29, 36),
    midBgColor = Color3.fromRGB(40, 42, 52),
    font = Enum.Font.GothamSemibold,
}

local espHighlights = {}
local originalHitboxData = {}

--================================================================================
--// Settings Persistence
--================================================================================
local function saveSettings()
    pcall(function()
        writefile(SETTINGS_FILE, HttpService:JSONEncode(Config))
    end)
end
local function loadSettings()
    if isfile(SETTINGS_FILE) then
        local ok, contents = pcall(function() return readfile(SETTINGS_FILE) end)
        if ok and contents then
            local s2, settings = pcall(function() return HttpService:JSONDecode(contents) end)
            if s2 and type(settings) == "table" then
                for k, v in pairs(settings) do
                    if Config[k] ~= nil then Config[k] = v end
                end
            end
        end
    end
end

--================================================================================
--// Welcome GUI
--================================================================================
local function showWelcomeScreen(onFinished)
    if CoreGui:FindFirstChild("WelcomeGUI_Heaven") then return end
    local welcomeGui = Instance.new("ScreenGui"); welcomeGui.Name = "WelcomeGUI_Heaven"; welcomeGui.ResetOnSpawn = false; welcomeGui.Parent = CoreGui
    local background = Instance.new("Frame", welcomeGui); background.BackgroundColor3 = Color3.new(0, 0, 0); background.BackgroundTransparency = 1; background.Size = UDim2.fromScale(1, 1)
    local welcomeFrame = Instance.new("Frame", background); welcomeFrame.BackgroundColor3 = Config.bgColor; welcomeFrame.Size = UDim2.new(0, 420, 0, 180); welcomeFrame.Position = UDim2.fromScale(0.5, 0.5); welcomeFrame.AnchorPoint = Vector2.new(0.5, 0.5); welcomeFrame.BorderSizePixel = 0; welcomeFrame.ClipsDescendants = true
    local corner = Instance.new("UICorner", welcomeFrame); corner.CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", welcomeFrame); stroke.Color = Config.accentColor; stroke.Transparency = 0.5; stroke.Thickness = 2
    local title = Instance.new("TextLabel", welcomeFrame); title.Text = "☁️ Heaven | Aimbot"; title.Font = Enum.Font.GothamBlack; title.TextColor3 = Color3.new(1, 1, 1); title.TextSize = 32; title.Size = UDim2.new(1, -40, 0, 40); title.Position = UDim2.new(0.5, 0, 0.3, 0); title.AnchorPoint = Vector2.new(0.5, 0.5); title.BackgroundTransparency = 1
    local subtitle = Instance.new("TextLabel", welcomeFrame); subtitle.Text = "Enhanced by Gemini and ChatGPT"; subtitle.Font = Config.font; subtitle.TextColor3 = Color3.fromRGB(180, 180, 190); subtitle.TextSize = 14; subtitle.Size = UDim2.new(1, -40, 0, 20); subtitle.Position = UDim2.new(0.5, 0, 0.5, 0); subtitle.AnchorPoint = Vector2.new(0.5, 0.5); subtitle.BackgroundTransparency = 1
    local progressBar = Instance.new("Frame", welcomeFrame); progressBar.Size = UDim2.new(1, -40, 0, 4); progressBar.Position = UDim2.new(0.5, 0, 0.8, 0); progressBar.AnchorPoint = Vector2.new(0.5, 0.5); progressBar.BackgroundColor3 = Config.midBgColor; local pCorner = Instance.new("UICorner", progressBar); pCorner.CornerRadius = UDim.new(1, 0)
    local progressFill = Instance.new("Frame", progressBar); progressFill.BackgroundColor3 = Config.accentColor; progressFill.Size = UDim2.fromScale(0, 1); local fCorner = Instance.new("UICorner", progressFill); fCorner.CornerRadius = UDim.new(1, 0)
    
    TweenService:Create(background, TweenInfo.new(0.28), {BackgroundTransparency = 0.7}):Play()
    welcomeFrame.Position = UDim2.fromScale(0.5, 0.45); TweenService:Create(welcomeFrame, TweenInfo.new(0.56, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
    task.wait(0.45); TweenService:Create(progressFill, TweenInfo.new(1.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1, 1)}):Play()
    task.wait(1.9); TweenService:Create(background, TweenInfo.new(0.38), {BackgroundTransparency = 1}):Play(); local exitTween = TweenService:Create(welcomeFrame, TweenInfo.new(0.36, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.fromScale(0.5, 0.55)}); exitTween:Play()
    exitTween.Completed:Connect(function() welcomeGui:Destroy(); onFinished() end)
end

--================================================================================
--// Main GUI (polished UI + stable helpers)
--================================================================================
local MainGUI = {}

-- helper: trim
local function trim(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end

-- parse whitelist from a comma separated string: "user1, user2," -> {"user1", "user2"}
local function parseWhitelist(text)
    local out = {}
    if not text then return out end
    for token in string.gmatch(text, "([^,]+)") do
        token = trim(token)
        if #token > 0 then
            table.insert(out, token:lower())
        end
    end
    return out
end

-- utility: safe tween wrapper
local function safeTween(instance, properties, info)
    local ok, t = pcall(function() return TweenService:Create(instance, info or TweenInfo.new(0.12), properties) end)
    if ok and t then
        t:Play()
        return t
    end
    return nil
end

function MainGUI:Create()
    if CoreGui:FindFirstChild("MainGUI_Heaven") then return {} end
    local updateMethods = {}
    
    local gui = Instance.new("ScreenGui"); gui.Name = "MainGUI_Heaven"; gui.ResetOnSpawn = false
    
    -- outer container has background + stroke so border ALWAYS wraps whole UI
    local mainContainer = Instance.new("Frame", gui);
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(0, 280, 0, 420)
    mainContainer.Position = UDim2.fromScale(0.15, 0.5)
    mainContainer.AnchorPoint = Vector2.new(0, 0.5)
    mainContainer.BackgroundColor3 = Config.bgColor
    mainContainer.BorderSizePixel = 0
    mainContainer.ClipsDescendants = false
    mainContainer.ZIndex = 1

    local corner = Instance.new("UICorner", mainContainer); corner.CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", mainContainer); stroke.Color = Config.accentColor; stroke.Thickness = 1.2; stroke.Transparency = 0.15

    -- content sits inside the container (transparent background since container provides bg)
    local contentContainer = Instance.new("Frame", mainContainer)
    contentContainer.Name = "Content"
    contentContainer.Size = UDim2.new(1, 0, 1, 0)
    contentContainer.Position = UDim2.new(0, 0, 0, 0)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ClipsDescendants = false

    -- visible drag handle (shorter) - bottom center (outside slightly)
    local dragFrame = Instance.new("Frame", mainContainer)
    dragFrame.Name = "DragHandle"
    dragFrame.Size = UDim2.new(0.45, 0, 0, 6)                       -- shorter width and small height
    dragFrame.AnchorPoint = Vector2.new(0.5, 1)                     -- anchor to bottom center
    dragFrame.Position = UDim2.new(0.5, 0, 1, 18)                   -- visual handle position (center ≈ bottom+15)
    dragFrame.BackgroundColor3 = Config.accentColor
    dragFrame.BackgroundTransparency = 0.55                          -- slightly more visible idle
    dragFrame.ZIndex = 50
    dragFrame.Active = true
    dragFrame.Draggable = false
    local dCorner = Instance.new("UICorner", dragFrame); dCorner.CornerRadius = UDim.new(1, 0)

    -- ---------- UPDATED HITBOX: centered on handle and extends above & below ----------
    local hitboxFrame = Instance.new("Frame", mainContainer)
    hitboxFrame.Name = "DragHitbox"
    hitboxFrame.Size = UDim2.new(0.85, 0, 0, 56)                    -- taller to cover above and below
    hitboxFrame.AnchorPoint = Vector2.new(0.5, 0.5)                 -- center-based anchor
    hitboxFrame.Position = UDim2.new(0.5, 0, 1, 15)                -- center placed at bottom + 15 (matches visual handle center)
    hitboxFrame.BackgroundTransparency = 1                          -- invisible but active
    hitboxFrame.ZIndex = 49
    hitboxFrame.Active = true
    -- -------------------------------------------------------------------------------

    -- header (no subtitle in main UI)
    local header = Instance.new("Frame", contentContainer); header.Name="Header"; header.Size=UDim2.new(1,0,0,48); header.Position=UDim2.new(0,0,0,0); header.BackgroundTransparency=1; header.ClipsDescendants=false
    local title = Instance.new("TextLabel", header);
    title.Size = UDim2.new(1, -40, 0, 32)
    title.Position = UDim2.new(0.5, 0, 0, 8)
    title.AnchorPoint = Vector2.new(0.5, 0)
    title.Text = "☁️ | Heaven"
    title.Font = Enum.Font.GothamBlack
    title.TextColor3 = Color3.new(1,1,1)
    title.TextSize = 20
    title.BackgroundTransparency = 1

    local minimizeBtn = Instance.new("TextButton", header)
    minimizeBtn.Size = UDim2.new(0,20,0,20)
    minimizeBtn.Position = UDim2.new(1,-20,0,14)
    minimizeBtn.AnchorPoint = Vector2.new(0.5,0)
    minimizeBtn.Text = "—"
    minimizeBtn.Font = Config.font
    minimizeBtn.TextSize = 20
    minimizeBtn.TextColor3 = Color3.new(1,1,1)
    minimizeBtn.BackgroundTransparency = 1

    -- body scrolling area
    local scrollingFrame = Instance.new("ScrollingFrame", contentContainer);
    scrollingFrame.Name="Scrolling"
    scrollingFrame.Size=UDim2.new(1,0,1,-48);
    scrollingFrame.Position = UDim2.new(0,0,0,48)
    scrollingFrame.BackgroundTransparency=1;
    scrollingFrame.BorderSizePixel=0;
    scrollingFrame.ScrollBarImageColor3=Config.accentColor;
    scrollingFrame.ScrollBarThickness=6;
    scrollingFrame.CanvasSize=UDim2.new(0,0,2,0);
    local listLayoutScroll = Instance.new("UIListLayout", scrollingFrame); listLayoutScroll.Padding=UDim.new(0,8); listLayoutScroll.SortOrder=Enum.SortOrder.LayoutOrder; listLayoutScroll.HorizontalAlignment=Enum.HorizontalAlignment.Center
    local padding = Instance.new("UIPadding", scrollingFrame); padding.PaddingTop=UDim.new(0,10); padding.PaddingBottom=UDim.new(0,10); padding.PaddingLeft=UDim.new(0,10); padding.PaddingRight=UDim.new(0,10)

    -- Helper: microinteraction setup (hover & press) - disabled on touch devices
    local touch = UserInputService.TouchEnabled
    local function addHover(target, enterProps, leaveProps)
        if touch then return end
        target.MouseEnter:Connect(function()
            safeTween(target, enterProps, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        end)
        target.MouseLeave:Connect(function()
            safeTween(target, leaveProps, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        end)
    end

    -- Helper functions for controls (createDivider, createToggle, createCycleButton, createSliderWithInput, createInput)
    -- ... identical to the previous version (kept for brevity here) ...
    -- I'll include them exactly as in your working polished script in the actual file.

    -- For the sake of a complete drop-in, below are the helper functions (unchanged):

    local function createDivider(order)
        local d = Instance.new("Frame", scrollingFrame)
        d.Size = UDim2.new(1, 0, 0, 1)
        d.BackgroundColor3 = Config.midBgColor
        d.LayoutOrder = order
        return d
    end

    local function createToggle(text, desc, order, callback)
        local f = Instance.new("Frame", scrollingFrame); f.Size = UDim2.new(1,0,0,45); f.BackgroundTransparency = 1; f.LayoutOrder = order
        local l = Instance.new("TextLabel", f); l.Text = text; l.Font = Config.font; l.TextSize = 16; l.TextColor3 = Color3.new(1,1,1); l.Size = UDim2.new(0.7,0,0,25); l.TextXAlignment = Enum.TextXAlignment.Left; l.BackgroundTransparency = 1
        local d = Instance.new("TextLabel", f); d.Text = desc; d.Font = Enum.Font.SourceSans; d.TextSize = 12; d.TextColor3 = Color3.fromRGB(150,150,160); d.Size = UDim2.new(0.7,0,0,15); d.Position = UDim2.new(0,0,0,25); d.TextXAlignment = Enum.TextXAlignment.Left; d.BackgroundTransparency = 1
        local s = Instance.new("TextButton", f); s.Size = UDim2.new(0,50,0,26); s.Position = UDim2.new(1,-50,0.5,-13); s.Text = ""; s.AutoButtonColor = false
        local sc = Instance.new("UICorner", s); sc.CornerRadius = UDim.new(1,0)
        local k = Instance.new("Frame", s); k.Size = UDim2.new(0,20,0,20); k.Position = UDim2.fromScale(0,0.5); k.AnchorPoint = Vector2.new(0,0.5); k.BackgroundColor3 = Color3.new(1,1,1)
        local kc = Instance.new("UICorner", k); kc.CornerRadius = UDim.new(1,0)
        local function set(a)
            local c = a and Config.onColor or Config.offColor
            local p = a and UDim2.fromScale(1,0.5) or UDim2.fromScale(0,0.5)
            k.AnchorPoint = a and Vector2.new(1,0.5) or Vector2.new(0,0.5)
            safeTween(s, {BackgroundColor3 = c}, TweenInfo.new(0.18))
            safeTween(k, {Position = p}, TweenInfo.new(0.18, Enum.EasingStyle.Quad))
        end
        s.MouseButton1Click:Connect(function()
            callback()
            if not touch then
                safeTween(s, {Size = UDim2.new(s.Size.X.Scale, s.Size.X.Offset, 0, 24)}, TweenInfo.new(0.06))
                task.delay(0.07, function() safeTween(s, {Size = UDim2.new(s.Size.X.Scale, s.Size.X.Offset, 0, 26)}, TweenInfo.new(0.08)) end)
            end
        end)
        addHover(s, {BackgroundTransparency = 0.9, Size = UDim2.new(0,50,0,28)}, {BackgroundTransparency = 1, Size = UDim2.new(0,50,0,26)})
        return set
    end

    local function createCycleButton(text, options, order, callback)
        local f = Instance.new("Frame", scrollingFrame); f.Size = UDim2.new(1,0,0,35); f.BackgroundTransparency = 1; f.LayoutOrder = order
        local l = Instance.new("TextLabel", f); l.Text = text; l.Font = Config.font; l.TextSize = 16; l.TextColor3 = Color3.new(1,1,1); l.Size = UDim2.new(0.5,0,1,0); l.TextXAlignment = Enum.TextXAlignment.Left; l.BackgroundTransparency = 1
        local b = Instance.new("TextButton", f); b.Size = UDim2.new(0.4,0,0.8,0); b.AnchorPoint = Vector2.new(1,0.5); b.Position = UDim2.new(1,-8,0.5,0); b.BackgroundColor3 = Config.midBgColor; b.Font = Config.font; b.TextSize = 14; b.TextColor3 = Color3.new(1,1,1); b.AutoButtonColor = false
        local bc = Instance.new("UICorner", b); bc.CornerRadius = UDim.new(0,6)
        local currentIndex = 1
        local function set(val)
            local idx = table.find(options, val) or 1
            currentIndex = idx
            b.Text = options[currentIndex]
        end
        b.MouseButton1Click:Connect(function()
            currentIndex = (currentIndex % #options) + 1
            b.Text = options[currentIndex]
            callback(options[currentIndex])
            if not touch then
                safeTween(b, {Position = b.Position - UDim2.new(0, 0, 0, 2)}, TweenInfo.new(0.06))
                task.delay(0.06, function() safeTween(b, {Position = b.Position + UDim2.new(0, 0, 0, 2)}, TweenInfo.new(0.08)) end)
            end
        end)
        addHover(b, {BackgroundColor3 = Color3.fromRGB(45,47,55)}, {BackgroundColor3 = Config.midBgColor})
        b.Text = options[currentIndex]
        return set
    end

    local function createSliderWithInput(text, min, max, order, getValue, setValue)
        local f = Instance.new("Frame", scrollingFrame); f.Size = UDim2.new(1,0,0,40); f.BackgroundTransparency = 1; f.LayoutOrder = order
        local l = Instance.new("TextLabel", f); l.Text = text; l.Font = Config.font; l.TextSize = 16; l.TextColor3 = Color3.new(1,1,1); l.Size = UDim2.new(0.5,0,0,20); l.TextXAlignment = Enum.TextXAlignment.Left; l.BackgroundTransparency = 1
        local vb = Instance.new("TextBox", f); vb.Size = UDim2.new(0.3,0,0,22); vb.Position = UDim2.new(0.65,0,0,0); vb.BackgroundColor3 = Config.midBgColor; vb.Font = Config.font; vb.TextColor3 = Color3.new(1,1,1); vb.TextSize = 14; vb.ClearTextOnFocus = false
        local vbc = Instance.new("UICorner", vb); vbc.CornerRadius = UDim.new(0,4)
        local sf = Instance.new("Frame", f); sf.Size = UDim2.new(1,0,0,12); sf.Position = UDim2.new(0,0,0,25); sf.BackgroundColor3 = Config.midBgColor
        local sc = Instance.new("UICorner", sf); sc.CornerRadius = UDim.new(1,0)
        local sfl = Instance.new("Frame", sf); sfl.BackgroundColor3 = Config.accentColor
        local fc = Instance.new("UICorner", sfl); fc.CornerRadius = UDim.new(1,0)
        local h = Instance.new("Frame", sf); h.Size = UDim2.new(0,16,0,16); h.AnchorPoint = Vector2.new(0.5,0.5); h.BackgroundColor3 = Color3.new(1,1,1); h.Active = true; h.ZIndex = 2
        local hc = Instance.new("UICorner", h); hc.CornerRadius = UDim.new(1,0)
        local function u(p) p = math.clamp(p, 0, 1); local v = min + (max - min) * p; h.Position = UDim2.fromScale(p, 0.5); sfl.Size = UDim2.fromScale(p, 1); vb.Text = string.format("%.1f", v); setValue(v) end
        local dr = false; local dragInput = nil
        h.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dr = true; dragInput = i; end end)
        UserInputService.InputEnded:Connect(function(i) if i == dragInput then dr = false; dragInput = nil; saveSettings(); end end)
        UserInputService.InputChanged:Connect(function(i) if i == dragInput then local p = (i.Position.X - sf.AbsolutePosition.X) / sf.AbsoluteSize.X; u(p) end end)
        vb.FocusLost:Connect(function() local n = tonumber(vb.Text); if n then setValue(n); saveSettings(); u((n - min) / (max - min)) else u((getValue() - min) / (max - min)) end end)
        local function ext() u((getValue() - min) / (max - min)) end
        return ext, f
    end

    local function createInput(placeholder, order, callback)
        local t = Instance.new("TextBox", scrollingFrame)
        t.Size = UDim2.new(1,0,0,35)
        t.BackgroundColor3 = Config.midBgColor
        t.Font = Enum.Font.SourceSans
        t.TextSize = 14
        t.TextColor3 = Color3.new(1,1,1)
        t.ClearTextOnFocus = false
        t.PlaceholderText = placeholder
        t.LayoutOrder = order
        local tc = Instance.new("UICorner", t); tc.CornerRadius = UDim.new(0,6)
        if callback then t.FocusLost:Connect(callback) end
        return t
    end

    -- Create controls and store "setter" functions in updateMethods
    updateMethods.aimbot = createToggle("Aimbot", "Locks onto targets", 2, function()
        Config.aimbotEnabled = not Config.aimbotEnabled
        if Config.aimbotEnabled then
            Config.smoothAimEnabled = false
            if updateMethods.smoothAim then updateMethods.smoothAim(false) end
        end
        if updateMethods.aimbot then updateMethods.aimbot(Config.aimbotEnabled) end
        saveSettings()
    end)

    updateMethods.smoothAim = createToggle("Smooth Aim", "Aims smoothly at targets", 3, function()
        Config.smoothAimEnabled = not Config.smoothAimEnabled
        if Config.smoothAimEnabled then
            Config.aimbotEnabled = false
            if updateMethods.aimbot then updateMethods.aimbot(false) end
        end
        if updateMethods.smoothAim then updateMethods.smoothAim(Config.smoothAimEnabled) end
        saveSettings()
    end)

    updateMethods.targetPart = createCycleButton("Target Part", {"Head", "Torso"}, 4, function(v)
        Config.targetPart = (v == "Torso") and "HumanoidRootPart" or v
        saveSettings()
    end)

    updateMethods.fovSlider, updateMethods.fovSliderFrame = createSliderWithInput("FOV Radius", 20, 500, 5, function() return Config.fovRadius end, function(v) Config.fovRadius = v end)

    createDivider(6)

    updateMethods.espLines = createToggle("ESP Lines", "Draws lines to players", 7, function()
        Config.espLinesEnabled = not Config.espLinesEnabled
        if updateMethods.espLines then updateMethods.espLines(Config.espLinesEnabled) end
        saveSettings()
    end)

    updateMethods.espChams = createToggle("ESP Chams", "Highlights players through walls", 8, function()
        Config.espChamsEnabled = not Config.espChamsEnabled
        if updateMethods.espChams then updateMethods.espChams(Config.espChamsEnabled) end
        saveSettings()
    end)

    updateMethods.wallCheck = createToggle("Wall Check", "Only targets visible players", 9, function()
        Config.wallCheck = not Config.wallCheck
        if updateMethods.wallCheck then updateMethods.wallCheck(Config.wallCheck) end
        saveSettings()
    end)

    updateMethods.teamCheck = createToggle("Team Check", "Ignores teammates", 10, function()
        Config.teamCheck = not Config.teamCheck
        if updateMethods.teamCheck then updateMethods.teamCheck(Config.teamCheck) end
        saveSettings()
    end)

    -- whitelist input now expects comma separated entries
    updateMethods.whitelistInput = createInput("Whitelist (e.g. user1, user2)", 11, function()
        local text = updateMethods.whitelistInput.Text or ""
        Config.whitelist = parseWhitelist(text)
        saveSettings()
    end)

    createDivider(12)

    updateMethods.hitboxMod = createToggle("Modify Hitboxes", "Increases player hitbox size", 13, function()
        Config.hitboxModEnabled = not Config.hitboxModEnabled
        if updateMethods.hitboxMod then updateMethods.hitboxMod(Config.hitboxModEnabled) end
        updateMethods.hitboxSliderFrame.Visible = Config.hitboxModEnabled
        updateMethods.hitboxTransSliderFrame.Visible = Config.hitboxModEnabled
        saveSettings()
    end)

    updateMethods.hitboxSlider, updateMethods.hitboxSliderFrame = createSliderWithInput("Hitbox Size", 2, 10, 14, function() return Config.hitboxSize end, function(v) Config.hitboxSize = v end)
    updateMethods.hitboxTransSlider, updateMethods.hitboxTransSliderFrame = createSliderWithInput("Hitbox Transparency", 0, 1, 15, function() return Config.hitboxTransparency end, function(v) Config.hitboxTransparency = v end)

    -- Minimize handling: change container size so stroke follows
    local isMinimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        scrollingFrame.Visible = not isMinimized
        if updateMethods.whitelistInput then updateMethods.whitelistInput.Visible = not isMinimized end
        local targetSize = isMinimized and UDim2.new(0,280,0,48) or UDim2.new(0,280,0,420)
        safeTween(mainContainer, {Size = targetSize}, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    end)

    gui.Parent = CoreGui

    -- Dragging logic (single set of variables used by both visible handle and invisible hitbox)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local dragInput = nil

    local fadeIn = TweenService:Create(dragFrame, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
    local fadeOut = TweenService:Create(dragFrame, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.55})

    local function beginDrag(input)
        if not input then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        dragStart = input.Position
        startPos = mainContainer.Position
        dragInput = input

        -- ensure the visible handle becomes solid when hitbox pressed
        fadeOut:Cancel(); fadeIn:Play()

        -- monitor the input end state
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                if dragging then
                    dragging = false
                    fadeIn:Cancel(); fadeOut:Play()
                end
                dragInput = nil
            end
        end)
    end

    local function endDrag(input)
        if not input then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = false
        dragInput = nil
        fadeIn:Cancel(); fadeOut:Play()
    end

    -- connect both visible handle and invisible hitbox to the same handlers
    dragFrame.InputBegan:Connect(beginDrag)
    hitboxFrame.InputBegan:Connect(beginDrag)
    dragFrame.InputEnded:Connect(endDrag)
    hitboxFrame.InputEnded:Connect(endDrag)

    -- throttle movement slightly to avoid tiny CPU spikes
    local lastMove = 0
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input ~= dragInput then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local now = tick()
            if now - lastMove < 0.01 then return end
            lastMove = now
            local delta = input.Position - dragStart
            mainContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    return updateMethods
end

function MainGUI:Update(methods)
    if not methods then return end
    if methods.aimbot then methods.aimbot(Config.aimbotEnabled) end
    if methods.smoothAim then methods.smoothAim(Config.smoothAimEnabled) end
    if methods.targetPart then methods.targetPart((Config.targetPart == "HumanoidRootPart") and "Torso" or Config.targetPart) end
    if methods.fovSlider then methods.fovSlider() end
    if methods.espLines then methods.espLines(Config.espLinesEnabled) end
    if methods.espChams then methods.espChams(Config.espChamsEnabled) end
    if methods.wallCheck then methods.wallCheck(Config.wallCheck) end
    if methods.teamCheck then methods.teamCheck(Config.teamCheck) end
    if methods.whitelistInput then methods.whitelistInput.Text = table.concat(Config.whitelist, ", ") end
    if methods.hitboxMod then methods.hitboxMod(Config.hitboxModEnabled) end
    if methods.hitboxSlider then methods.hitboxSlider() end
    if methods.hitboxSliderFrame then methods.hitboxSliderFrame.Visible = Config.hitboxModEnabled end
    if methods.hitboxTransSlider then methods.hitboxTransSlider() end
    if methods.hitboxTransSliderFrame then methods.hitboxTransSliderFrame.Visible = Config.hitboxModEnabled end
end

--================================================================================
--// Core Logic (robust guards; same behavior)
--================================================================================
local CoreLogic = {}
local FovCircle = nil
do
    local ok, circle = pcall(function() return Drawing and Drawing.new and Drawing.new("Circle") end)
    if ok then FovCircle = circle end
end
if FovCircle then
    FovCircle.Visible = false
    FovCircle.Thickness = 1.5
    FovCircle.Color = Config.accentColor
    FovCircle.NumSides = 64
    FovCircle.Filled = false
end

local espLines = {}

function CoreLogic.createCham(p)
    if espHighlights[p] then return end
    local c = p.Character
    if not c then return end
    local h = Instance.new("Highlight", c)
    h.FillTransparency = 0.6
    h.OutlineTransparency = 1
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    espHighlights[p] = h
end
function CoreLogic.removeCham(p) if espHighlights[p] then espHighlights[p]:Destroy(); espHighlights[p] = nil end end
function CoreLogic.applyHitboxMod(p)
    local c = p.Character
    if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart")
    if r then
        if not originalHitboxData[p] then
            originalHitboxData[p] = {
                Size = r.Size,
                Transparency = r.Transparency,
                Material = r.Material,
                CanCollide = r.CanCollide
            }
        end
        pcall(function()
            r.Size = Vector3.new(Config.hitboxSize, Config.hitboxSize, Config.hitboxSize)
            r.Transparency = Config.hitboxTransparency
            r.Material = Enum.Material.Neon
            r.CanCollide = false
        end)
    end
end
function CoreLogic.revertHitboxMod(p)
    if originalHitboxData[p] then
        local c = p.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local data = originalHitboxData[p]
            pcall(function()
                c.HumanoidRootPart.Size = data.Size
                c.HumanoidRootPart.Transparency = data.Transparency
                c.HumanoidRootPart.Material = data.Material
                c.HumanoidRootPart.CanCollide = data.CanCollide
            end)
        end
        originalHitboxData[p] = nil
    end
end
function CoreLogic.isAlive(p)
    if not p or not p.Character then return false end
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end
function CoreLogic.isVisible(part)
    if not part then return false end
    local cameraPos = Camera and Camera.CFrame and Camera.CFrame.Position or workspace.CurrentCamera.CFrame.Position
    local pa = RaycastParams.new()
    pa.FilterType = Enum.RaycastFilterType.Exclude
    pa.FilterDescendantsInstances = {}
    if LocalPlayer and LocalPlayer.Character then table.insert(pa.FilterDescendantsInstances, LocalPlayer.Character) end
    local direction = part.Position - cameraPos
    local r = workspace:Raycast(cameraPos, direction, pa)
    if not r then return true end
    if r.Instance and part and r.Instance:IsDescendantOf(part.Parent) then return true end
    return false
end
function CoreLogic.isSameTeam(p) return LocalPlayer and p and LocalPlayer.Team and p.Team and LocalPlayer.Team == p.Team end

-- whitelist check supports partial matching
function CoreLogic.isWhitelisted(p)
    if not p or not p.Name then return false end
    local name = p.Name:lower()
    for _, token in ipairs(Config.whitelist) do
        if token ~= "" and string.find(name, token, 1, true) then
            return true
        end
    end
    return false
end

function CoreLogic.getClosestTarget()
    local foundPart, bestDist = nil, Config.fovRadius
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and CoreLogic.isAlive(pl) and not (Config.teamCheck and CoreLogic.isSameTeam(pl)) and not CoreLogic.isWhitelisted(pl) then
            if pl.Character then
                local t = pl.Character:FindFirstChild(Config.targetPart)
                if t then
                    local s, onScreen = Camera:WorldToViewportPoint(t.Position)
                    if onScreen then
                        local m = (Vector2.new(s.X, s.Y) - center).Magnitude
                        if m < bestDist and (not Config.wallCheck or CoreLogic.isVisible(t)) then
                            foundPart = t
                            bestDist = m
                        end
                    end
                end
            end
        end
    end
    return foundPart
end

function CoreLogic.updateVisuals()
    local i, c = 1, Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local alive = CoreLogic.isAlive(p)
            local isTeammate = CoreLogic.isSameTeam(p)

            if alive and not CoreLogic.isWhitelisted(p) then
                -- Chams
                if Config.espChamsEnabled then
                    if Config.teamCheck and isTeammate then
                        CoreLogic.createCham(p)
                        if espHighlights[p] then espHighlights[p].FillColor = Color3.fromRGB(0, 0, 255) end
                    else
                        CoreLogic.createCham(p)
                        if espHighlights[p] then espHighlights[p].FillColor = Color3.fromRGB(255, 0, 0) end
                    end
                else
                    CoreLogic.removeCham(p)
                end

                -- Lines
                if Config.espLinesEnabled then
                    local rpart = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    if rpart then
                        local s, v = Camera:WorldToViewportPoint(rpart.Position)
                        if v then
                            if not espLines[i] then
                                if Drawing and Drawing.new then
                                    espLines[i] = Drawing.new("Line")
                                    espLines[i].Thickness = 1.5
                                    espLines[i].Transparency = 0.5
                                end
                            end
                            local l = espLines[i]
                            if l then
                                l.Visible = true
                                l.From = c
                                l.To = Vector2.new(s.X, s.Y)

                                if Config.teamCheck and isTeammate then
                                    l.Color = Color3.fromRGB(0, 255, 0)
                                else
                                    local lpRoot = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                    local d = 1000
                                    if lpRoot and rpart and lpRoot.Position and rpart.Position then
                                        d = (lpRoot.Position - rpart.Position).Magnitude
                                    end
                                    l.Color = Color3.fromHSV(math.clamp(0.3 - (d / 1000), 0, 1), 0.8, 1)
                                end
                            end
                            i = i + 1
                        end
                    end
                end
            else
                CoreLogic.removeCham(p)
            end
        end
    end
    for j = i, #espLines do
        if espLines[j] then
            espLines[j].Visible = false
        end
    end
    if not Config.espChamsEnabled then
        for p, _ in pairs(espHighlights) do
            CoreLogic.removeCham(p)
        end
    end
end

function CoreLogic.start()
    RunService.RenderStepped:Connect(function(dt)
        if FovCircle then
            FovCircle.Radius = Config.fovRadius
            if Camera and Camera.ViewportSize then
                FovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            end
            FovCircle.Visible = Config.aimbotEnabled or Config.smoothAimEnabled
        end

        CoreLogic.updateVisuals()
        local target = CoreLogic.getClosestTarget()

        if target then
            if Config.aimbotEnabled then
                if Camera and Camera.CFrame then
                    local camPos = Camera.CFrame.Position
                    Camera.CFrame = CFrame.new(camPos, target.Position)
                end
            elseif Config.smoothAimEnabled then
                if Camera and Camera.CFrame then
                    local camPos = Camera.CFrame.Position
                    local targetCFrame = CFrame.new(camPos, target.Position)
                    local ratio = math.clamp(dt / math.max(Config.smoothness, 0.0001), 0, 1)
                    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, ratio)
                end
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if Config.hitboxModEnabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then CoreLogic.applyHitboxMod(p) end
            end
        else
            for p, _ in pairs(originalHitboxData) do
                CoreLogic.revertHitboxMod(p)
            end
        end
    end)
end

--================================================================================
--// Initialization
--================================================================================
loadSettings()
showWelcomeScreen(function()
    print("☁️ Heaven | Aimbot Initialized.")
    local updateMethods = MainGUI:Create()
    MainGUI:Update(updateMethods)
    CoreLogic.start()
    Players.PlayerRemoving:Connect(function(player)
        if originalHitboxData[player] then originalHitboxData[player] = nil end
        if espHighlights[player] then espHighlights[player] = nil end
    end)
end)

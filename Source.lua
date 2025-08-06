--[[
    Title: ☁️ Heaven | Aimbot
    Description: A feature-rich enhancement script with a focus on a modern, fully functional UI.
    Version: 12.0 (Complete Rebuild & Stability Release)
    Enhanced by: Gemini
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
    aimbotEnabled = false, smoothAimEnabled = true, targetPart = "HumanoidRootPart", fovRadius = 120, smoothness = 0.15,
    wallCheck = false, teamCheck = false, whitelist = {},
    espLinesEnabled = true, espChamsEnabled = false,
    hitboxModEnabled = false, hitboxSize = 4,
    accentColor = Color3.fromRGB(135, 206, 235), onColor = Color3.fromRGB(80, 200, 130), offColor = Color3.fromRGB(220, 70, 70),
    bgColor = Color3.fromRGB(28, 29, 36), midBgColor = Color3.fromRGB(40, 42, 52), font = Enum.Font.GothamSemibold,
}

local espHighlights = {}
local originalHitboxData = {}

--// Settings Persistence
local function saveSettings() pcall(function() writefile(SETTINGS_FILE, HttpService:JSONEncode(Config)) end) end
local function loadSettings()
    if isfile(SETTINGS_FILE) then
        local s1, d1 = pcall(function() return readfile(SETTINGS_FILE) end)
        if s1 and d1 then
            local s2, settings = pcall(function() return HttpService:JSONDecode(d1) end)
            if s2 then for k, v in pairs(settings) do if Config[k] ~= nil then Config[k] = v end end end
        end
    end
end

--================================================================================
--// Welcome GUI
--================================================================================
local function showWelcomeScreen(onFinished)
    local welcomeGui = Instance.new("ScreenGui"); welcomeGui.Name = "WelcomeGUI_Heaven"; welcomeGui.ResetOnSpawn = false; welcomeGui.Parent = CoreGui
    local background = Instance.new("Frame", welcomeGui); background.BackgroundColor3 = Color3.new(0, 0, 0); background.BackgroundTransparency = 1; background.Size = UDim2.fromScale(1, 1)
    local welcomeFrame = Instance.new("Frame", background); welcomeFrame.BackgroundColor3 = Config.bgColor; welcomeFrame.Size = UDim2.new(0, 420, 0, 180); welcomeFrame.Position = UDim2.fromScale(0.5, 0.5); welcomeFrame.AnchorPoint = Vector2.new(0.5, 0.5); welcomeFrame.BorderSizePixel = 0; welcomeFrame.ClipsDescendants = true
    local corner = Instance.new("UICorner", welcomeFrame); corner.CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", welcomeFrame); stroke.Color = Config.accentColor; stroke.Transparency = 0.5; stroke.Thickness = 2
    local title = Instance.new("TextLabel", welcomeFrame); title.Text = "☁️ Heaven | Aimbot"; title.Font = Enum.Font.GothamBlack; title.TextColor3 = Color3.new(1, 1, 1); title.TextSize = 32; title.Size = UDim2.new(1, -40, 0, 40); title.Position = UDim2.new(0.5, 0, 0.3, 0); title.AnchorPoint = Vector2.new(0.5, 0.5); title.BackgroundTransparency = 1
    local subtitle = Instance.new("TextLabel", welcomeFrame); subtitle.Text = "Enhanced by Gemini"; subtitle.Font = Config.font; subtitle.TextColor3 = Color3.fromRGB(180, 180, 190); subtitle.TextSize = 16; subtitle.Size = UDim2.new(1, -40, 0, 20); subtitle.Position = UDim2.new(0.5, 0, 0.5, 0); subtitle.AnchorPoint = Vector2.new(0.5, 0.5); subtitle.BackgroundTransparency = 1
    local progressBar = Instance.new("Frame", welcomeFrame); progressBar.Size = UDim2.new(1, -40, 0, 4); progressBar.Position = UDim2.new(0.5, 0, 0.8, 0); progressBar.AnchorPoint = Vector2.new(0.5, 0.5); progressBar.BackgroundColor3 = Config.midBgColor; local pCorner = Instance.new("UICorner", progressBar); pCorner.CornerRadius = UDim.new(1, 0)
    local progressFill = Instance.new("Frame", progressBar); progressFill.BackgroundColor3 = Config.accentColor; progressFill.Size = UDim2.fromScale(0, 1); local fCorner = Instance.new("UICorner", progressFill); fCorner.CornerRadius = UDim.new(1, 0)
    
    TweenService:Create(background, TweenInfo.new(0.3), {BackgroundTransparency = 0.7}):Play()
    welcomeFrame.Position = UDim2.fromScale(0.5, 0.45); TweenService:Create(welcomeFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
    task.wait(0.5); TweenService:Create(progressFill, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1, 1)}):Play()
    task.wait(2); TweenService:Create(background, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play(); local exitTween = TweenService:Create(welcomeFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.fromScale(0.5, 0.55)}); exitTween:Play()
    exitTween.Completed:Connect(function() welcomeGui:Destroy(); onFinished() end)
end

--================================================================================
--// Main GUI
--================================================================================
local MainGUI = {}

function MainGUI:Create()
    local updateMethods = {}
    
    local gui = Instance.new("ScreenGui"); gui.Name = "MainGUI_Heaven"; gui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame", gui); mainFrame.Size = UDim2.new(0, 280, 0, 420); mainFrame.Position = UDim2.fromScale(0.15, 0.5); mainFrame.AnchorPoint = Vector2.new(0, 0.5); mainFrame.BackgroundColor3 = Config.bgColor; mainFrame.BorderSizePixel = 0; mainFrame.ClipsDescendants = true; mainFrame.Draggable = false
    local corner = Instance.new("UICorner", mainFrame); corner.CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", mainFrame); stroke.Color = Config.accentColor; stroke.Thickness = 1.5
    
    --// Rebuilt UI Structure for reliable dragging
    local dragFrame = Instance.new("Frame", mainFrame)
    dragFrame.Size = UDim2.new(1, 0, 0, 12); dragFrame.Position = UDim2.new(0,0,0,0); dragFrame.BackgroundColor3 = Config.accentColor; dragFrame.BackgroundTransparency = 1; dragFrame.ZIndex = 10
    dragFrame.Active = true; dragFrame.Draggable = true
    dragFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then TweenService:Create(dragFrame, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play() end end)
    dragFrame.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then TweenService:Create(dragFrame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play() end end)
    
    local contentContainer = Instance.new("Frame", mainFrame)
    contentContainer.Size = UDim2.new(1, 0, 1, 0); contentContainer.BackgroundTransparency = 1
    
    local listLayoutMain = Instance.new("UIListLayout", contentContainer); listLayoutMain.SortOrder = Enum.SortOrder.LayoutOrder
    
    local header = Instance.new("Frame", contentContainer); header.Size=UDim2.new(1,0,0,40); header.BackgroundColor3=Config.midBgColor; header.Draggable=false
    local title = Instance.new("TextLabel", header); title.Size=UDim2.fromScale(1,1); title.Text="☁️ | Heaven"; title.Font=Enum.Font.GothamBlack; title.TextColor3=Color3.new(1,1,1); title.TextSize=20; title.BackgroundTransparency=1
    local minimizeBtn = Instance.new("TextButton", header); minimizeBtn.Size=UDim2.new(0,20,0,20); minimizeBtn.Position=UDim2.new(1,-20,0.5,0); minimizeBtn.AnchorPoint=Vector2.new(0.5,0.5); minimizeBtn.Text="—"; minimizeBtn.Font=Config.font; minimizeBtn.TextSize=20; minimizeBtn.TextColor3=Color3.new(1,1,1); minimizeBtn.BackgroundTransparency=1
    
    local scrollingFrame = Instance.new("ScrollingFrame", contentContainer); scrollingFrame.Size=UDim2.new(1,0,1,-40); scrollingFrame.BackgroundTransparency=1; scrollingFrame.BorderSizePixel=0; scrollingFrame.ScrollBarImageColor3=Config.accentColor; scrollingFrame.ScrollBarThickness=6; scrollingFrame.CanvasSize=UDim2.new(0,0,2,0)
    local listLayoutScroll = Instance.new("UIListLayout", scrollingFrame); listLayoutScroll.Padding=UDim.new(0,8); listLayoutScroll.SortOrder=Enum.SortOrder.LayoutOrder; listLayoutScroll.HorizontalAlignment=Enum.HorizontalAlignment.Center
    local padding = Instance.new("UIPadding", scrollingFrame); padding.PaddingTop=UDim.new(0,10); padding.PaddingBottom=UDim.new(0,10); padding.PaddingLeft=UDim.new(0,10); padding.PaddingRight=UDim.new(0,10)
    
    --// Cleaned, readable helper functions
    local function createDivider(order) local d=Instance.new("Frame",scrollingFrame);d.Size=UDim2.new(1,0,0,1);d.BackgroundColor3=Config.midBgColor;d.LayoutOrder=order end
    local function createToggle(text,desc,order,callback) local f=Instance.new("Frame",scrollingFrame);f.Size=UDim2.new(1,0,0,45);f.BackgroundTransparency=1;f.LayoutOrder=order;local l=Instance.new("TextLabel",f);l.Text=text;l.Font=Config.font;l.TextSize=16;l.TextColor3=Color3.new(1,1,1);l.Size=UDim2.new(0.7,0,0,25);l.TextXAlignment=Enum.TextXAlignment.Left;l.BackgroundTransparency=1;local d=Instance.new("TextLabel",f);d.Text=desc;d.Font=Enum.Font.SourceSans;d.TextSize=12;d.TextColor3=Color3.fromRGB(150,150,160);d.Size=UDim2.new(0.7,0,0,15);d.Position=UDim2.new(0,0,0,25);d.TextXAlignment=Enum.TextXAlignment.Left;d.BackgroundTransparency=1;local s=Instance.new("TextButton",f);s.Size=UDim2.new(0,50,0,26);s.Position=UDim2.new(1,-50,0.5,-13);s.Text="";local sc=Instance.new("UICorner",s);sc.CornerRadius=UDim.new(1,0);local k=Instance.new("Frame",s);k.Size=UDim2.new(0,20,0,20);k.Position=UDim2.fromScale(0,0.5);k.AnchorPoint=Vector2.new(0,0.5);k.BackgroundColor3=Color3.new(1,1,1);local kc=Instance.new("UICorner",k);kc.CornerRadius=UDim.new(1,0);local function set(a) local c=a and Config.onColor or Config.offColor;local p=a and UDim2.fromScale(1,0.5)or UDim2.fromScale(0,0.5);k.AnchorPoint=a and Vector2.new(1,0.5)or Vector2.new(0,0.5);TweenService:Create(s,TweenInfo.new(0.2),{BackgroundColor3=c}):Play();TweenService:Create(k,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{Position=p}):Play()end;s.MouseButton1Click:Connect(callback);return set end
    local function createCycleButton(text,options,order,callback) local f=Instance.new("Frame",scrollingFrame);f.Size=UDim2.new(1,0,0,35);f.BackgroundTransparency=1;f.LayoutOrder=order;local l=Instance.new("TextLabel",f);l.Text=text;l.Font=Config.font;l.TextSize=16;l.TextColor3=Color3.new(1,1,1);l.Size=UDim2.new(0.5,0,1,0);l.TextXAlignment=Enum.TextXAlignment.Left;l.BackgroundTransparency=1;local b=Instance.new("TextButton",f);b.Size=UDim2.new(0.4,0,1,0);b.Position=UDim2.new(1,-b.AbsoluteSize.X,0,0);b.BackgroundColor3=Config.midBgColor;b.Font=Config.font;b.TextSize=14;b.TextColor3=Color3.new(1,1,1);local bc=Instance.new("UICorner",b);bc.CornerRadius=UDim.new(0,6);local currentIndex=1;local function set(val) local idx=table.find(options,val) or 1;currentIndex=idx;b.Text=options[currentIndex]end;b.MouseButton1Click:Connect(function()currentIndex=(currentIndex%#options)+1;b.Text=options[currentIndex];callback(options[currentIndex])end);return set end
    local function createSliderWithInput(text,min,max,order,getValue,setValue) local f=Instance.new("Frame",scrollingFrame);f.Size=UDim2.new(1,0,0,40);f.BackgroundTransparency=1;f.LayoutOrder=order;local l=Instance.new("TextLabel",f);l.Text=text;l.Font=Config.font;l.TextSize=16;l.TextColor3=Color3.new(1,1,1);l.Size=UDim2.new(0.5,0,0,20);l.TextXAlignment=Enum.TextXAlignment.Left;l.BackgroundTransparency=1;local vb=Instance.new("TextBox",f);vb.Size=UDim2.new(0.3,0,0,22);vb.Position=UDim2.new(0.65,0,0,0);vb.BackgroundColor3=Config.midBgColor;vb.Font=Config.font;vb.TextColor3=Color3.new(1,1,1);vb.TextSize=14;vb.ClearTextOnFocus=false;local vbc=Instance.new("UICorner",vb);vbc.CornerRadius=UDim.new(0,4);local sf=Instance.new("Frame",f);sf.Size=UDim2.new(1,0,0,12);sf.Position=UDim2.new(0,0,0,25);sf.BackgroundColor3=Config.midBgColor;local sc=Instance.new("UICorner",sf);sc.CornerRadius=UDim.new(1,0);local sfl=Instance.new("Frame",sf);sfl.BackgroundColor3=Config.accentColor;local fc=Instance.new("UICorner",sfl);fc.CornerRadius=UDim.new(1,0);local h=Instance.new("Frame",sf);h.Size=UDim2.new(0,16,0,16);h.AnchorPoint=Vector2.new(0.5,0.5);h.BackgroundColor3=Color3.new(1,1,1);local hc=Instance.new("UICorner",h);hc.CornerRadius=UDim.new(1,0);local function u(p)p=math.clamp(p,0,1);local v=min+(max-min)*p;h.Position=UDim2.fromScale(p,0.5);sfl.Size=UDim2.fromScale(p,1);vb.Text=string.format("%.1f",v);setValue(v)end;local dr=false;h.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true end end);UserInputService.InputEnded:Connect(function()if dr then dr=false;saveSettings()end end);UserInputService.InputChanged:Connect(function(i)if dr and i.UserInputType==Enum.UserInputType.MouseMovement then local p=(i.Position.X-sf.AbsolutePosition.X)/sf.AbsoluteSize.X;u(p)end end);vb.FocusLost:Connect(function()local n=tonumber(vb.Text);if n then setValue(n);saveSettings();u((n-min)/(max-min))else u((getValue()-min)/(max-min))end end);local function ext()u((getValue()-min)/(max-min))end;return ext,f end
    local function createInput(p,o,c)local t=Instance.new("TextBox",scrollingFrame);t.Size=UDim2.new(1,0,0,35);t.BackgroundColor3=Config.midBgColor;t.Font=Enum.Font.SourceSans;t.TextSize=14;t.TextColor3=Color3.new(1,1,1);t.ClearTextOnFocus=false;t.PlaceholderText=p;t.LayoutOrder=o;local tc=Instance.new("UICorner",t);tc.CornerRadius=UDim.new(0,6);t.FocusLost:Connect(c);return t end
    
    updateMethods.aimbot=createToggle("Aimbot","Locks onto targets",2,function()Config.aimbotEnabled=not Config.aimbotEnabled;if Config.aimbotEnabled then Config.smoothAimEnabled=false;updateMethods.smoothAim(false)end;updateMethods.aimbot(Config.aimbotEnabled);saveSettings()end)
    updateMethods.smoothAim=createToggle("Smooth Aim","Aims smoothly at targets",3,function()Config.smoothAimEnabled=not Config.smoothAimEnabled;if Config.smoothAimEnabled then Config.aimbotEnabled=false;updateMethods.aimbot(false)end;updateMethods.smoothAim(Config.smoothAimEnabled);saveSettings()end)
    updateMethods.targetPart=createCycleButton("Target Part",{"Head","Torso"},4,function(v)Config.targetPart=(v=="Torso")and"HumanoidRootPart"or v;saveSettings()end)
    updateMethods.fovSlider,_=createSliderWithInput("FOV Radius",20,500,5,function()return Config.fovRadius end,function(v)Config.fovRadius=v end)
    createDivider(6)
    updateMethods.espLines=createToggle("ESP Lines","Draws lines to players",7,function()Config.espLinesEnabled=not Config.espLinesEnabled;updateMethods.espLines(Config.espLinesEnabled);saveSettings()end)
    updateMethods.espChams=createToggle("ESP Chams","Highlights players through walls",8,function()Config.espChamsEnabled=not Config.espChamsEnabled;updateMethods.espChams(Config.espChamsEnabled);saveSettings()end)
    updateMethods.wallCheck=createToggle("Wall Check","Only targets visible players",9,function()Config.wallCheck=not Config.wallCheck;updateMethods.wallCheck(Config.wallCheck);saveSettings()end)
    updateMethods.teamCheck=createToggle("Team Check","Ignores teammates",10,function()Config.teamCheck=not Config.teamCheck;updateMethods.teamCheck(Config.teamCheck);saveSettings()end)
    updateMethods.whitelistInput=createInput("Whitelist (e.g. user1 user2)",11,function()local t=updateMethods.whitelistInput.Text;Config.whitelist={};for n in string.gmatch(t,"%S+")do table.insert(Config.whitelist,n:lower())end;saveSettings()end)
    createDivider(12)
    updateMethods.hitboxMod=createToggle("Modify Hitboxes","Increases player hitbox size",13,function()Config.hitboxModEnabled=not Config.hitboxModEnabled;updateMethods.hitboxMod(Config.hitboxModEnabled);updateMethods.hitboxSliderFrame.Visible=Config.hitboxModEnabled;saveSettings()end)
    updateMethods.hitboxSlider,updateMethods.hitboxSliderFrame=createSliderWithInput("Hitbox Size",2,10,14,function()return Config.hitboxSize end,function(v)Config.hitboxSize=v end)

    local isMinimized=false;minimizeBtn.MouseButton1Click:Connect(function()isMinimized=not isMinimized;scrollingFrame.Visible=not isMinimized;local s=isMinimized and UDim2.new(0,280,0,48)or UDim2.new(0,280,0,420);TweenService:Create(mainFrame,TweenInfo.new(0.2),{Size=s}):Play()end)

    gui.Parent=CoreGui; return updateMethods
end

function MainGUI:Update(methods)
    methods.aimbot(Config.aimbotEnabled);methods.smoothAim(Config.smoothAimEnabled);methods.targetPart(Config.targetPart=="HumanoidRootPart"and"Torso"or Config.targetPart);methods.fovSlider()
    methods.espLines(Config.espLinesEnabled);methods.espChams(Config.espChamsEnabled);methods.wallCheck(Config.wallCheck);methods.teamCheck(Config.teamCheck)
    methods.whitelistInput.Text=table.concat(Config.whitelist," ");methods.hitboxMod(Config.hitboxModEnabled);methods.hitboxSlider();methods.hitboxSliderFrame.Visible=Config.hitboxModEnabled
end

--================================================================================
--// Core Logic
--================================================================================
local CoreLogic={};local FovCircle=Drawing.new("Circle");FovCircle.Visible=false;FovCircle.Thickness=1.5;FovCircle.Color=Config.accentColor;FovCircle.NumSides=64;FovCircle.Filled=false
local espLines = {}
function CoreLogic.createCham(p)if espHighlights[p]then return end;local c=p.Character;if not c then return end;local h=Instance.new("Highlight",c);h.FillColor=Config.accentColor;h.FillTransparency=0.6;h.OutlineTransparency=1;h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;espHighlights[p]=h end
function CoreLogic.removeCham(p)if espHighlights[p]then espHighlights[p]:Destroy();espHighlights[p]=nil end end
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
            r.Transparency = 0.5
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
function CoreLogic.isAlive(p)return p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")and p.Character.Humanoid.Health>0 end
function CoreLogic.isVisible(p)local o=Camera.CFrame.Position;local pa=RaycastParams.new();pa.FilterType=Enum.RaycastFilterType.Exclude;pa.FilterDescendantsInstances={LocalPlayer.Character};local r=workspace:Raycast(o,p.Position-o,pa);return not r or r.Instance:IsDescendantOf(p.Parent)end
function CoreLogic.isSameTeam(p)return LocalPlayer.Team and p.Team and LocalPlayer.Team==p.Team end
function CoreLogic.isWhitelisted(p)for _,n in ipairs(Config.whitelist)do if p.Name:lower()==n then return true end end;return false end
function CoreLogic.getClosestTarget()
    local bestTarget, nearestDistance = nil, Config.fovRadius
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and CoreLogic.isAlive(player) and not (Config.teamCheck and CoreLogic.isSameTeam(player)) and not CoreLogic.isWhitelisted(player) then
            local character = player.Character
            local targetPart = character and character:FindFirstChild(Config.targetPart)

            if targetPart then
                local screenPosition, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - viewportCenter).Magnitude
                    if distance < nearestDistance then
                        if not Config.wallCheck or CoreLogic.isVisible(targetPart) then
                            bestTarget = targetPart
                            nearestDistance = distance
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end
function CoreLogic.updateVisuals()local i,c=1,Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2);for _,p in pairs(Players:GetPlayers())do if p~=LocalPlayer then local alive=CoreLogic.isAlive(p);if Config.espChamsEnabled and alive and not(Config.teamCheck and CoreLogic.isSameTeam(p))and not CoreLogic.isWhitelisted(p)then CoreLogic.createCham(p)else CoreLogic.removeCham(p)end;if Config.espLinesEnabled and alive and not(Config.teamCheck and CoreLogic.isSameTeam(p))and not CoreLogic.isWhitelisted(p)then local r=p.Character:FindFirstChild("HumanoidRootPart");if r then local s,v=Camera:WorldToViewportPoint(r.Position);if v then if not espLines[i]then espLines[i]=Drawing.new("Line");espLines[i].Thickness=1.5;espLines[i].Transparency=0.5 end;local l=espLines[i];l.Visible=true;l.From=c;l.To=Vector2.new(s.X,s.Y);local d=(LocalPlayer.Character.HumanoidRootPart.Position-r.Position).Magnitude;l.Color=Color3.fromHSV(0.3-(d/1000),0.8,1);i=i+1 end end end end end;for j=i,#espLines do if espLines[j]then espLines[j].Visible=false end end;if not Config.espChamsEnabled then for p,_ in pairs(espHighlights)do CoreLogic.removeCham(p)end end end
function CoreLogic.start()
    local aimTween
    RunService.RenderStepped:Connect(function()
        FovCircle.Radius=Config.fovRadius;FovCircle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2);FovCircle.Visible=Config.aimbotEnabled or Config.smoothAimEnabled
        CoreLogic.updateVisuals()
        local target=CoreLogic.getClosestTarget()
        if target then if Config.aimbotEnabled then if aimTween and aimTween.PlaybackState==Enum.PlaybackState.Playing then aimTween:Cancel()end;Camera.CFrame=CFrame.new(Camera.CFrame.Position,target.Position)elseif Config.smoothAimEnabled then if not(aimTween and aimTween.PlaybackState==Enum.PlaybackState.Playing)then local g=CFrame.new(Camera.CFrame.Position,target.Position);aimTween=TweenService:Create(Camera,TweenInfo.new(Config.smoothness,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{CFrame=g});aimTween:Play()end end end
    end)
    RunService.Heartbeat:Connect(function()if Config.hitboxModEnabled then for _,p in ipairs(Players:GetPlayers())do if p~=LocalPlayer then CoreLogic.applyHitboxMod(p)end end else for p,_ in pairs(originalHitboxData)do CoreLogic.revertHitboxMod(p)end end end)
end

--================================================================================

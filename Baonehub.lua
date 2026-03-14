local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local AF = {
    Enabled=false, AutoQuest=false, WeaponType="Melee",
    FarmMode="Level", AttackRange=20,
}
local KA = { Enabled=false, Range=30, Delay=0.2 }
local ESP = { Enabled=false, Players=true, Mobs=true, Fruits=false, Chests=false }
local RAID = { Enabled=false, AutoStart=false }

local function GetNearestMob()
    local r = Character and Character:FindFirstChild("HumanoidRootPart")
    if not r then return nil end
    local near, dist = nil, math.huge
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Model") and o ~= Character then
            local h = o:FindFirstChildOfClass("Humanoid")
            local rt = o:FindFirstChild("HumanoidRootPart")
            if h and rt and h.Health > 0 and not Players:GetPlayerFromCharacter(o) then
                local d = (r.Position - rt.Position).Magnitude
                if d < dist then near=o; dist=d end
            end
        end
    end
    return near, dist
end

local function AttackMob(mob)
    pcall(function()
        local r = Character:FindFirstChild("HumanoidRootPart")
        local mr = mob:FindFirstChild("HumanoidRootPart")
        if not r or not mr then return end
        if (r.Position - mr.Position).Magnitude > AF.AttackRange then
            r.CFrame = mr.CFrame * CFrame.new(0,0,5)
        end
        local ev = ReplicatedStorage:FindFirstChild("MainEvent") or ReplicatedStorage:FindFirstChild("RemoteEvent")
        if ev then ev:FireServer("Attacks", mob) end
    end)
end

local function DoKillAura()
    if not KA.Enabled then return end
    local r = Character and Character:FindFirstChild("HumanoidRootPart")
    if not r then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local pr = p.Character:FindFirstChild("HumanoidRootPart")
            local h  = p.Character:FindFirstChildOfClass("Humanoid")
            if pr and h and h.Health > 0 then
                if (r.Position - pr.Position).Magnitude <= KA.Range then
                    pcall(function()
                        local ev = ReplicatedStorage:FindFirstChild("MainEvent")
                        if ev then ev:FireServer("Attacks", p.Character) end
                    end)
                end
            end
        end
    end
end

local ESPFolder = Instance.new("Folder", workspace)
ESPFolder.Name = "RedzESP"
local ESPCache = {}
local ESPDist = {}

local function ClearESP(target)
    if ESPCache[target] then
        for _, v in pairs(ESPCache[target]) do if v and v.Parent then v:Destroy() end end
        ESPCache[target] = nil
    end
end

local function MakeESP(target, label, color)
    ClearESP(target)
    local root = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
    if not root then return end
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0,120,0,44)
    bb.StudsOffset = Vector3.new(0,3,0)
    bb.AlwaysOnTop = true
    bb.Adornee = root
    bb.Parent = ESPFolder
    local fr = Instance.new("Frame", bb)
    fr.Size = UDim2.new(1,0,1,0)
    fr.BackgroundColor3 = Color3.fromRGB(0,0,0)
    fr.BackgroundTransparency = 0.55
    fr.BorderSizePixel = 0
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0,4)
    local st = Instance.new("UIStroke", fr)
    st.Color = color
    st.Thickness = 1.5
    local nm = Instance.new("TextLabel", fr)
    nm.Size = UDim2.new(1,0,0.5,0)
    nm.Position = UDim2.new(0,0,0,2)
    nm.BackgroundTransparency = 1
    nm.Text = label
    nm.TextColor3 = Color3.fromRGB(255,255,255)
    nm.TextScaled = true
    nm.Font = Enum.Font.GothamBold
    local dl = Instance.new("TextLabel", fr)
    dl.Name = "Dist"
    dl.Size = UDim2.new(1,0,0.5,0)
    dl.Position = UDim2.new(0,0,0.5,0)
    dl.BackgroundTransparency = 1
    dl.Text = "?"
    dl.TextColor3 = Color3.fromRGB(200,200,255)
    dl.TextScaled = true
    dl.Font = Enum.Font.Gotham
    ESPCache[target] = {bb}
    return dl
end

local function UpdateESP()
    if not ESP.Enabled then
        for t in pairs(ESPCache) do ClearESP(t) end
        ESPDist = {}
        return
    end
    local r = Character and Character:FindFirstChild("HumanoidRootPart")
    if not r then return end
    if ESP.Players then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local pr = p.Character:FindFirstChild("HumanoidRootPart")
                if pr then
                    local d = math.floor((r.Position - pr.Position).Magnitude)
                    if not ESPCache[p.Character] then
                        local dl = MakeESP(p.Character, p.Name, Color3.fromRGB(0,180,255))
                        ESPDist[p.Character] = dl
                    end
                    if ESPDist[p.Character] then ESPDist[p.Character].Text = d.."m" end
                end
            end
        end
    end
    if ESP.Mobs then
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("Model") and not Players:GetPlayerFromCharacter(o) and o ~= Character then
                local h = o:FindFirstChildOfClass("Humanoid")
                local rt = o:FindFirstChild("HumanoidRootPart")
                if h and rt and h.Health > 0 then
                    local d = math.floor((r.Position - rt.Position).Magnitude)
                    if d < 400 then
                        if not ESPCache[o] then
                            local dl = MakeESP(o, o.Name, Color3.fromRGB(255,60,60))
                            ESPDist[o] = dl
                        end
                        if ESPDist[o] then ESPDist[o].Text = d.."m" end
                    else ClearESP(o); ESPDist[o]=nil end
                end
            end
        end
    end
end

local TPLocations = {
    ["Starter Island"]    = CFrame.new(1059,15,1550),
    ["Marine Ford"]       = CFrame.new(-967,13,4034),
    ["Sky Island"]        = CFrame.new(-7759,5606,-1862),
    ["Colosseum"]         = CFrame.new(-1580,6,-2986),
    ["Magma Village"]     = CFrame.new(-5565,9,8327),
    ["Ice Castle"]        = CFrame.new(1389,88,-1298),
    ["Underwater City"]   = CFrame.new(60943,17,1744),
    ["Fountain City"]     = CFrame.new(-429,71,1836),
    ["Green Zone"]        = CFrame.new(638,71,918),
    ["Kingdom of Rose"]   = CFrame.new(-986,72,1088),
    ["Whole Cake Island"] = CFrame.new(-2021,37,-12028),
    ["Chocolate Island"]  = CFrame.new(582,25,-12550),
    ["Candy Island"]      = CFrame.new(-1150,20,-14446),
    ["Haunted Castle"]    = CFrame.new(-9479,141,5566),
    ["Forest"]            = CFrame.new(-13234,331,-7625),
    ["Pineapple Island"]  = CFrame.new(-118,55,5649),
}

local function StartRaid(raidName)
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("StartRaid", raidName)
    end)
end

local kaTimer = 0
local espTimer = 0

RunService.Heartbeat:Connect(function(dt)
    Character = LocalPlayer.Character
    if not Character then return end
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    if AF.Enabled then
        local mob = GetNearestMob()
        if mob then AttackMob(mob) end
    end
    if KA.Enabled then
        kaTimer += dt
        if kaTimer >= KA.Delay then kaTimer=0; DoKillAura() end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    espTimer += dt
    if espTimer >= 0.5 then espTimer=0; UpdateESP() end
end)

LocalPlayer.CharacterAdded:Connect(function(c) Character=c end)local function Tw(o,p,t) TweenService:Create(o,TweenInfo.new(t or 0.2,Enum.EasingStyle.Quad),p):Play() end
local function New(cl,pr)
    local o=Instance.new(cl)
    for k,v in pairs(pr) do if k~="Parent" then o[k]=v end end
    if pr.Parent then o.Parent=pr.Parent end
    return o
end
local function Corn(o,r) New("UICorner",{CornerRadius=UDim.new(0,r or 6),Parent=o}) end
local function Strk(o,c,t) New("UIStroke",{Color=c or Color3.fromRGB(50,15,15),Thickness=t or 1,Parent=o}) end

local C = {
    BG=Color3.fromRGB(13,6,6), Side=Color3.fromRGB(9,4,4),
    Row=Color3.fromRGB(20,10,10), Accent=Color3.fromRGB(200,30,30),
    Text=Color3.fromRGB(255,255,255), Sub=Color3.fromRGB(170,170,170),
    ON=Color3.fromRGB(200,30,30), OFF=Color3.fromRGB(40,40,60),
}

for _, v in ipairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
    if v.Name == "RedzHub" then v:Destroy() end
end

local Gui = New("ScreenGui",{Name="RedzHub",ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    Parent=LocalPlayer:WaitForChild("PlayerGui")})

local Win = New("Frame",{Size=UDim2.new(0,600,0,450),
    Position=UDim2.new(0.5,-300,0.5,-225),
    BackgroundColor3=C.BG,BorderSizePixel=0,Parent=Gui})
Corn(Win,10) Strk(Win,Color3.fromRGB(120,0,0),1.5)
New("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(20,8,8)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(8,8,18)),
}),Rotation=135,Parent=Win})

local Top = New("Frame",{Size=UDim2.new(1,0,0,42),BackgroundColor3=Color3.fromRGB(16,5,5),
    BorderSizePixel=0,Parent=Win}) Corn(Top,10)
New("Frame",{Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),
    BackgroundColor3=Color3.fromRGB(16,5,5),BorderSizePixel=0,Parent=Top})
New("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(35,8,8)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(12,4,4)),
}),Rotation=90,Parent=Top})

local dot=New("Frame",{Size=UDim2.new(0,9,0,9),Position=UDim2.new(0,13,0.5,-4.5),
    BackgroundColor3=C.Accent,Parent=Top}) Corn(dot,5)
New("TextLabel",{Size=UDim2.new(0,150,1,0),Position=UDim2.new(0,29,0,0),
    BackgroundTransparency=1,Text="Redz Hub",TextColor3=C.Text,
    Font=Enum.Font.GothamBlack,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,Parent=Top})
New("TextLabel",{Size=UDim2.new(0,60,1,0),Position=UDim2.new(0,132,0,0),
    BackgroundTransparency=1,Text="v2.0",TextColor3=C.Accent,
    Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=Top})

local CloseB=New("TextButton",{Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-35,0.5,-14),
    BackgroundColor3=Color3.fromRGB(170,25,25),Text="✕",TextColor3=C.Text,
    Font=Enum.Font.GothamBold,TextSize=14,Parent=Top}) Corn(CloseB,6)
CloseB.MouseButton1Click:Connect(function()
    Tw(Win,{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)},0.3)
    task.wait(0.3); Gui:Destroy(); ESPFolder:Destroy()
end)

local MinB=New("TextButton",{Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-67,0.5,-14),
    BackgroundColor3=Color3.fromRGB(45,45,70),Text="–",TextColor3=C.Text,
    Font=Enum.Font.GothamBold,TextSize=16,Parent=Top}) Corn(MinB,6)
local mini=false
MinB.MouseButton1Click:Connect(function()
    mini=not mini
    Tw(Win,{Size=mini and UDim2.new(0,600,0,42) or UDim2.new(0,600,0,450)},0.3)
end)

local Side=New("Frame",{Size=UDim2.new(0,158,1,-42),Position=UDim2.new(0,0,0,42),
    BackgroundColor3=C.Side,BorderSizePixel=0,Parent=Win})
New("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder,Parent=Side})
New("UIPadding",{PaddingTop=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),Parent=Side})
New("Frame",{Size=UDim2.new(0,1,1,-42),Position=UDim2.new(0,158,0,42),
    BackgroundColor3=Color3.fromRGB(100,0,0),BorderSizePixel=0,Parent=Win})

local Content=New("Frame",{Size=UDim2.new(1,-158,1,-42),Position=UDim2.new(0,159,0,42),
    BackgroundTransparency=1,Parent=Win})

local Tabs,TabBtns,ActiveTab={},{},nil

local function NewTab(name,icon)
    local btn=New("TextButton",{Size=UDim2.new(1,0,0,36),
        BackgroundColor3=Color3.fromRGB(18,8,8),
        Text=icon.."  "..name,TextColor3=Color3.fromRGB(150,150,150),
        Font=Enum.Font.GothamMedium,TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=Side})
    Corn(btn,7)
    New("UIPadding",{PaddingLeft=UDim.new(0,10),Parent=btn})
    local sc=New("ScrollingFrame",{Size=UDim2.new(1,-10,1,-10),Position=UDim2.new(0,5,0,5),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
        ScrollBarImageColor3=C.Accent,AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.new(0,0,0,0),Visible=false,Parent=Content})
    New("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,Parent=sc})
    New("UIPadding",{PaddingTop=UDim.new(0,6),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),Parent=sc})
    Tabs[name]=sc; TabBtns[name]=btn
    btn.MouseEnter:Connect(function()
        if ActiveTab~=name then Tw(btn,{BackgroundColor3=Color3.fromRGB(28,12,12)},0.15) end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveTab~=name then Tw(btn,{BackgroundColor3=Color3.fromRGB(18,8,8)},0.15) end
    end)
    btn.MouseButton1Click:Connect(function()
        for _,s in pairs(Tabs) do s.Visible=false end
        for _,b in pairs(TabBtns) do
            Tw(b,{BackgroundColor3=Color3.fromRGB(18,8,8)},0.15)
            b.TextColor3=Color3.fromRGB(150,150,150)
        end
        sc.Visible=true; ActiveTab=name
        Tw(btn,{BackgroundColor3=Color3.fromRGB(130,18,18)},0.2)
        btn.TextColor3=C.Text
    end)
    return sc
end

local function Sec(tab,text)
    local f=New("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Parent=tab})
    New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=text,
        TextColor3=C.Accent,Font=Enum.Font.GothamBlack,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
    New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=Color3.fromRGB(110,0,0),BorderSizePixel=0,Parent=f})
end

local function Tog(tab,text,def,cb)
    local row=New("Frame",{Size=UDim2.new(1,0,0,38),BackgroundColor3=C.Row,
        BorderSizePixel=0,Parent=tab}) Corn(row,7) Strk(row)
    New("TextLabel",{Size=UDim2.new(1,-58,1,0),Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1,Text=text,TextColor3=C.Text,
        Font=Enum.Font.Gotham,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
    local bg=New("Frame",{Size=UDim2.new(0,42,0,20),Position=UDim2.new(1,-50,0.5,-10),
        BackgroundColor3=def and C.ON or C.OFF,Parent=row}) Corn(bg,10)
    local d=New("Frame",{Size=UDim2.new(0,14,0,14),
        Position=def and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
        BackgroundColor3=Color3.fromRGB(255,255,255),Parent=bg}) Corn(d,7)
    local st=def or false
    local cl=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=row})
    cl.MouseButton1Click:Connect(function()
        st=not st
        Tw(bg,{BackgroundColor3=st and C.ON or C.OFF},0.2)
        Tw(d,{Position=st and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)},0.2)
        if cb then cb(st) end
    end)
    row.MouseEnter:Connect(function() Tw(row,{BackgroundColor3=Color3.fromRGB(28,13,13)},0.15) end)
    row.MouseLeave:Connect(function() Tw(row,{BackgroundColor3=C.Row},0.15) end)
end

local function Drop(tab,text,opts,def,cb)
    local row=New("Frame",{Size=UDim2.new(1,0,0,38),BackgroundColor3=C.Row,
        BorderSizePixel=0,ClipsDescendants=true,Parent=tab}) Corn(row,7) Strk(row)
    New("TextLabel",{Size=UDim2.new(0,130,1,0),Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1,Text=text,TextColor3=C.Sub,
        Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
    local sel=New("TextButton",{Size=UDim2.new(0,130,0,26),Position=UDim2.new(1,-138,0.5,-13),
        BackgroundColor3=C.Accent,Text=def or opts[1],TextColor3=C.Text,
        Font=Enum.Font.GothamBold,TextSize=12,Parent=row}) Corn(sel,5)
    local selected=def or opts[1]; local open=false; local df
    sel.MouseButton1Click:Connect(function()
        open=not open
        if open then
            if df then df:Destroy() end
            df=New("Frame",{Size=UDim2.new(0,130,0,#opts*28+4),
                Position=UDim2.new(1,-138,1,2),
                BackgroundColor3=Color3.fromRGB(16,5,5),ZIndex=10,Parent=row})
            Corn(df,5) Strk(df,C.Accent)
            row.Size=UDim2.new(1,0,0,38+#opts*28+8); row.ClipsDescendants=false
            for i,o in ipairs(opts) do
                local ob=New("TextButton",{Size=UDim2.new(1,-4,0,26),
                    Position=UDim2.new(0,2,0,(i-1)*28+2),
                    BackgroundColor3=o==selected and C.Accent or Color3.fromRGB(16,5,5),
                    Text=o,TextColor3=C.Text,Font=Enum.Font.Gotham,TextSize=12,ZIndex=11,Parent=df})
                Corn(ob,4)
                ob.MouseButton1Click:Connect(function()
                    selected=o; sel.Text=o; open=false
                    row.Size=UDim2.new(1,0,0,38); row.ClipsDescendants=true
                    if df then df:Destroy(); df=nil end
                    if cb then cb(o) end
                end)
            end
        else
            row.Size=UDim2.new(1,0,0,38); row.ClipsDescendants=true
            if df then df:Destroy(); df=nil end
        end
    end)
end

local function Btn(tab,text,cb)
    local b=New("TextButton",{Size=UDim2.new(1,0,0,36),
        BackgroundColor3=Color3.fromRGB(120,18,18),Text=text,TextColor3=C.Text,
        Font=Enum.Font.GothamBold,TextSize=13,Parent=tab}) Corn(b,7)
    b.MouseEnter:Connect(function() Tw(b,{BackgroundColor3=Color3.fromRGB(170,22,22)},0.15) end)
    b.MouseLeave:Connect(function() Tw(b,{BackgroundColor3=Color3.fromRGB(120,18,18)},0.15) end)
    b.MouseButton1Click:Connect(function()
        Tw(b,{BackgroundColor3=Color3.fromRGB(80,10,10)},0.1)
        task.wait(0.1)
        Tw(b,{BackgroundColor3=Color3.fromRGB(120,18,18)},0.1)
        if cb then cb() end
    end)
end

local tFarm=NewTab("Auto Farm","🌾")
local tAura=NewTab("Kill Aura","⚔️")
local tESP=NewTab("ESP","👁")
local tTP=NewTab("Teleport","🌀")
local tRaid=NewTab("Raid","💥")
local tMisc=NewTab("Misc","⚙️")

Sec(tFarm,"⚔️  Auto Farm")
Tog(tFarm,"Start Farm",false,function(v) AF.Enabled=v end)
Tog(tFarm,"Auto Quest",false,function(v) AF.AutoQuest=v end)
Drop(tFarm,"Weapon",{"Melee","Sword","Fruit","Gun"},"Melee",function(v) AF.WeaponType=v end)
Drop(tFarm,"Mode",{"Level","Quest","Boss"},"Level",function(v) AF.FarmMode=v end)
Drop(tFarm,"Range",{"10","20","30","50"},"20",function(v) AF.AttackRange=tonumber(v) end)
Sec(tFarm,"📦  Thu Thập")
Tog(tFarm,"Auto Chest",false,function(v) _G.AutoChest=v end)
Tog(tFarm,"Auto Devil Fruit",false,function(v) _G.AutoFruit=v end)
Tog(tFarm,"Auto Mastery",false,function(v) _G.AutoMastery=v end)
Btn(tFarm,"Teleport to Mob",function()
    Character=LocalPlayer.Character
    local mob=GetNearestMob()
    if mob then
        local r=Character:FindFirstChild("HumanoidRootPart")
        local mr=mob:FindFirstChild("HumanoidRootPart")
        if r and mr then r.CFrame=mr.CFrame*CFrame.new(0,0,5) end
    end
end)

Sec(tAura,"⚔️  Kill Aura")
Tog(tAura,"Enable Kill Aura",false,function(v) KA.Enabled=v end)
Drop(tAura,"Range",{"10","20","30","50","100"},"30",function(v) KA.Range=tonumber(v) end)
Drop(tAura,"Speed",{"Chậm (0.5s)","Bình thường (0.2s)","Nhanh (0.1s)","Siêu nhanh (0.05s)"},"Bình thường (0.2s)",function(v)
    local m={["Chậm (0.5s)"]=0.5,["Bình thường (0.2s)"]=0.2,["Nhanh (0.1s)"]=0.1,["Siêu nhanh (0.05s)"]=0.05}
    KA.Delay=m[v] or 0.2
end)

Sec(tESP,"👁  ESP Settings")
Tog(tESP,"Enable ESP",false,function(v)
    ESP.Enabled=v
    if not v then for t in pairs(ESPCache) do ClearESP(t) end ESPDist={} end
end)
Tog(tESP,"Player ESP",true,function(v) ESP.Players=v end)
Tog(tESP,"Mob ESP",true,function(v) ESP.Mobs=v end)
Tog(tESP,"Devil Fruit ESP",false,function(v) ESP.Fruits=v end)
Tog(tESP,"Chest ESP",false,function(v) ESP.Chests=v end)

Sec(tTP,"🌀  Teleport Nhanh")
for name,cf in pairs(TPLocations) do
    local n,c=name,cf
    Btn(tTP,"📍  "..n,function()
        Character=LocalPlayer.Character
        local r=Character and Character:FindFirstChild("HumanoidRootPart")
        if r then r.CFrame=c end
    end)
end

Sec(tRaid,"💥  Raid")
Tog(tRaid,"Auto Join Raid",false,function(v) RAID.Enabled=v end)
Tog(tRaid,"Auto Start Raid",false,function(v) RAID.AutoStart=v end)
Drop(tRaid,"Raid Type",{"Flower","Darkbeard","Buddha","Phoenix","Gravity","Soul"},"Flower",function(v)
    _G.RaidType=v
end)
Btn(tRaid,"Join Raid Now",function() StartRaid(_G.RaidType or "Flower") end)
Btn(tRaid,"Teleport to Raid",function()
    pcall(function()
        local r=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local raid=workspace:FindFirstChild("Raid") or workspace:FindFirstChild("RaidArea")
        if r and raid then r.CFrame=raid:GetPivot() end
    end)
end)

Sec(tMisc,"🔧  Server")
Btn(tMisc,"Server Hop",function()
    local TS=game:GetService("TeleportService")
    local Http=game:GetService("HttpService")
    pcall(function()
        local data=Http:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        local servers={}
        for _,s in pairs(data.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                table.insert(servers,s.id)
            end
        end
        if #servers>0 then
            TS:TeleportToPlaceInstance(game.PlaceId,servers[math.random(1,#servers)],LocalPlayer)
        end
    end)
end)
Btn(tMisc,"Rejoin",function()
    game:GetService("TeleportService"):Teleport(game.PlaceId,LocalPlayer)
end)
Sec(tMisc,"🖥️  Display")
Tog(tMisc,"White Screen",false,function(v)
    game:GetService("RunService"):Set3dRenderingEnabled(not v)
end)
Tog(tMisc,"Anti-AFK",false,function(v)
    _G.AntiAFK=v
    if v then
        task.spawn(function()
            while _G.AntiAFK do
                task.wait(60)
                local vs=LocalPlayer:FindFirstChild("VirtualUser")
                if vs then vs:Button2Down(Vector2.new(0,0),CFrame.new()) end
            end
        end)
    end
end)

Tabs["Auto Farm"].Visible=true
ActiveTab="Auto Farm"
Tw(TabBtns["Auto Farm"],{BackgroundColor3=Color3.fromRGB(130,18,18)},0.2)
TabBtns["Auto Farm"].TextColor3=C.Text

do
    local drag,ds,dp
    Top.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; ds=i.Position; dp=Win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            Win.Position=UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

UserInputService.InputBegan:Connect(function(i,gpe)
    if not gpe and i.KeyCode==Enum.KeyCode.RightControl then
        Win.Visible=not Win.Visible
    end
end)

Win.Size=UDim2.new(0,0,0,0); Win.Position=UDim2.new(0.5,0,0.5,0)
Tw(Win,{Size=UDim2.new(0,600,0,450),Position=UDim2.new(0.5,-300,0.5,-225)},0.4)

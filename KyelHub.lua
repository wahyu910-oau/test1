--== Load KyelHub WindUI ==--
local WindUI = loadstring(game:HttpGet("https://getpotato.vercel.app/library/main"))()

WindUI:AddTheme({
    Name = "KyelHub",
    Accent = Color3.fromRGB(30, 144, 255),
    Background = Color3.fromRGB(0, 0, 139),
    Outline = Color3.fromRGB(25, 25, 112),
    Text = Color3.fromRGB(245, 225, 175),
    Placeholder = Color3.fromRGB(70, 130, 180),
    Button = Color3.fromRGB(0, 0, 205),
    Icon = Color3.fromRGB(135, 206, 235),
})

---------------------------------------------------
--== Services ==--
---------------------------------------------------
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

---------------------------------------------------
--== FPS Unlock ==--
---------------------------------------------------
if setfpscap then
    setfpscap(1000000)
    print("FPS Unlocked!")
end

---------------------------------------------------
--== Variables ==--
---------------------------------------------------
local LP = LocalPlayer
local Camera = Workspace.CurrentCamera

local featureStates = {
    WalkSpeed = false, WalkSpeedValue = 16, Noclip = false, AntiAFK = false,
    GodMode = false, NoFall = false, AntiStun = false, MoonWalk = false,
    ESPFillTransparency = 0.7, ESPOutlineTransparency = 0, ESPTextSize = 14,
    SurvivorESP = false, KillerESP = false, Nametags = false, DistanceESP = false,
    SurvivorColor = Color3.fromRGB(0,255,0), KillerColor = Color3.fromRGB(255,0,0),
    GeneratorESP = false, HookESP = false, GateESP = false, WindowESP = false, PalletESP = false,
    GeneratorColor = Color3.fromRGB(0,170,255), HookColor = Color3.fromRGB(255,0,0),
    GateColor = Color3.fromRGB(255,225,0), WindowColor = Color3.fromRGB(255,255,255), PalletColor = Color3.fromRGB(255,140,0),
    SurvivorItemsESP = false, SurvivorItemsColor = Color3.fromRGB(0,170,255),
    AutoLever = false, BypassGate = false, NoSkillcheck = false,
    AutoParry = false, ParryRange = 8, ParryCooldown = 0.5,
    ParryAnimation1 = "rbxassetid://127096285501517", ParryAnimation2 = "rbxassetid://104952902180174",
    FullBright = false, NoFog = false, TimeOfDay = false, TimeOfDayValue = 14,
}

-- ========== AUTO PARRY SYSTEM (FIXED) ==========
local autoParryRunning = false
local lastParryTime = 0
local animationTrack1 = nil
local animationTrack2 = nil
local parryHumanoid = nil

local function loadParryAnimations()
    if not parryHumanoid then return end
    local animator = parryHumanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = parryHumanoid
    end
    local anim1 = Instance.new("Animation")
    anim1.AnimationId = featureStates.ParryAnimation1
    animationTrack1 = animator:LoadAnimation(anim1)
    local anim2 = Instance.new("Animation")
    anim2.AnimationId = featureStates.ParryAnimation2
    animationTrack2 = animator:LoadAnimation(anim2)
end

local function playParryAnimation(isHit)
    if isHit and animationTrack2 then
        if animationTrack2.IsPlaying then animationTrack2:Stop() end
        animationTrack2:Play()
        animationTrack2.TimePosition = 0
    elseif not isHit and animationTrack1 then
        if animationTrack1.IsPlaying then animationTrack1:Stop() end
        animationTrack1:Play()
        animationTrack1.TimePosition = 0
    end
end

local function findParryRemote()
    local possiblePaths = {
        ReplicatedStorage:FindFirstChild("ParryClient"),
        ReplicatedStorage:FindFirstChild("AnimationControl") and ReplicatedStorage.AnimationControl:FindFirstChild("ParryClient"),
        ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ParryClient"),
        ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Combat") and ReplicatedStorage.Remotes.Combat:FindFirstChild("ParryClient"),
        ReplicatedStorage:FindFirstChild("Combat") and ReplicatedStorage.Combat:FindFirstChild("ParryClient"),
    }
    for _, remote in ipairs(possiblePaths) do
        if remote and remote:IsA("RemoteEvent") then
            return remote
        end
    end
    for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
        if child:IsA("RemoteEvent") and (child.Name:lower():find("parry") or child.Name:lower():find("block")) then
            return child
        end
    end
    return nil
end

local function triggerParryViaAnimationHandler()
    local animHandler = ReplicatedStorage:FindFirstChild("AnimationHandler")
    if animHandler and animHandler:IsA("ModuleScript") then
        local success, module = pcall(function() return require(animHandler) end)
        if success and module then
            if module.Parry then pcall(function() module.Parry() end); return true end
            if module.OnParry then pcall(function() module.OnParry() end); return true end
            if module.ClientParry then pcall(function() module.ClientParry() end); return true end
        end
    end
    return false
end

local function getParryingDagger()
    local backpack = LP:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool.Name:lower():find("parrying") or tool.Name:lower():find("dagger") then
                return tool
            end
        end
    end
    local char = LP.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("parrying") or tool.Name:lower():find("dagger")) then
                return tool
            end
        end
    end
    return nil
end

local function triggerParryViaTool()
    local dagger = getParryingDagger()
    if dagger then
        if dagger.Parent ~= LP.Character then
            dagger.Parent = LP.Character
            task.wait(0.05)
        end
        local humanoid = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:EquipTool(dagger)
            task.wait(0.02)
            dagger:Activate()
            return true
        end
    end
    return false
end

local function triggerParry()
    local parryRemote = findParryRemote()
    if parryRemote then
        pcall(function() parryRemote:FireServer() end)
        local dagger = getParryingDagger()
        if dagger then pcall(function() parryRemote:FireServer(dagger) end) end
        pcall(function() parryRemote:FireServer("Parrying Dagger") end)
        return true
    end
    if triggerParryViaAnimationHandler() then return true end
    if triggerParryViaTool() then return true end
    return false
end

local function getRoleFast(p)
    if p.Team then
        local tn = p.Team.Name:lower()
        if tn:find("killer") then return "Killer" end
        if tn:find("survivor") then return "Survivor" end
    end
    if p.TeamColor then
        local tc = p.TeamColor.Name:lower()
        if tc:find("red") then return "Killer" end
        if tc:find("blue") or tc:find("green") then return "Survivor" end
    end
    return "Survivor"
end

local function isKillerAttacking(killerChar)
    if not killerChar then return false end
    local killerHumanoid = killerChar:FindFirstChildOfClass("Humanoid")
    if not killerHumanoid then return false end
    local killerAnimator = killerHumanoid:FindFirstChildOfClass("Animator")
    if not killerAnimator then return false end
    for _, track in pairs(killerAnimator:GetPlayingAnimationTracks()) do
        local anim = track.Animation
        if anim then
            local animId = anim.AnimationId or ""
            if animId:lower():find("attack") or animId:lower():find("swing") or 
               animId:lower():find("hit") or animId:lower():find("slash") or
               animId:lower():find("stab") or animId:lower():find("melee") then
                return true
            end
        end
    end
    return false
end

local function isHitboxNearby(killerChar, rootPart)
    if not killerChar or not rootPart then return false end
    for _, part in ipairs(killerChar:GetDescendants()) do
        if part:IsA("BasePart") then
            local name = part.Name:lower()
            if name:find("hit") or name:find("damage") or name:find("weapon") or name:find("blade") then
                if (rootPart.Position - part.Position).Magnitude < 5 then
                    return true
                end
            end
        end
    end
    return false
end

local function checkAndParry()
    if not featureStates.AutoParry then return end
    if not LP.Character then return end
    
    local currentTime = tick()
    if currentTime - lastParryTime < featureStates.ParryCooldown then return end
    
    local char = LP.Character
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local nearestKiller = nil
    local nearestDistance = featureStates.ParryRange
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local role = getRoleFast(player)
            if role == "Killer" then
                local killerChar = player.Character
                if killerChar and killerChar:FindFirstChild("HumanoidRootPart") then
                    local distance = (root.Position - killerChar.HumanoidRootPart.Position).Magnitude
                    if distance <= nearestDistance then
                        nearestDistance = distance
                        nearestKiller = player
                    end
                end
            end
        end
    end
    
    if nearestKiller then
        local shouldParry = false
        local killerChar = nearestKiller.Character
        
        if isKillerAttacking(killerChar) then
            shouldParry = true
        end
        
        if not shouldParry and isHitboxNearby(killerChar, root) then
            shouldParry = true
        end
        
        if shouldParry then
            lastParryTime = currentTime
            local isHit = isKillerAttacking(killerChar)
            playParryAnimation(isHit)
            triggerParry()
        end
    end
end

local function startAutoParry()
    if autoParryRunning then return end
    autoParryRunning = true
    loadParryAnimations()
    task.spawn(function()
        while autoParryRunning and featureStates.AutoParry do
            checkAndParry()
            task.wait(0.05)
        end
        autoParryRunning = false
    end)
end

local function stopAutoParry()
    autoParryRunning = false
    if animationTrack1 and animationTrack1.IsPlaying then animationTrack1:Stop() end
    if animationTrack2 and animationTrack2.IsPlaying then animationTrack2:Stop() end
end

local function toggleAutoParry(state)
    featureStates.AutoParry = state
    if state then startAutoParry() else stopAutoParry() end
end

-- ========== VISUAL FUNCTIONS ==========
local function safeNotify(title, content, duration)
    WindUI:Notify({Title=title, Content=content, Duration=duration or 2, Icon="info"})
end

local function toggleFullBright(state)
    featureStates.FullBright = state
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        safeNotify("FullBright", "FullBright activated", 2)
    else
        Lighting.Brightness = 0.5
        Lighting.FogEnd = 100
        Lighting.GlobalShadows = true
        safeNotify("FullBright", "FullBright deactivated", 2)
    end
end

local function toggleNoFog(state)
    featureStates.NoFog = state
    if state then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        safeNotify("NoFog", "Fog removed", 2)
    else
        Lighting.FogEnd = 100
        Lighting.FogStart = 0
        safeNotify("NoFog", "Fog restored", 2)
    end
end

local function setTimeOfDay(state)
    featureStates.TimeOfDay = state
    if state then
        Lighting.ClockTime = featureStates.TimeOfDayValue
        safeNotify("Time of Day", "Time set to " .. featureStates.TimeOfDayValue .. ":00", 2)
    end
end

local function updateTimeOfDay(value)
    featureStates.TimeOfDayValue = value
    if featureStates.TimeOfDay then
        Lighting.ClockTime = value
    end
end

-- ========== PLAYER FEATURES ==========
local speedHumanoid, speedBound = nil, false
local noclipConn, antiAFKConn, godModeConn, charAddedConn, antiStunConn, moonwalkConn, worldThread, distThread, playerConns = nil, nil, nil, nil, nil, nil, nil, nil, {}
local godModeEnabled, godModeChar, godModeHum, NoFallEnabled = false, nil, nil, false
local worldReg = {Generator={}, Hook={}, Gate={}, Window={}, Palletwrong={}}
local mapAdd, mapRem, palletState, windowState = {}, {}, setmetatable({},{__mode="k"}), setmetatable({},{__mode="k"})

local function setNoclip(s)
    if s and not noclipConn then
        noclipConn = RunService.Stepped:Connect(function()
            local c = LP.Character; if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)
    elseif not s and noclipConn then
        noclipConn:Disconnect(); noclipConn = nil
        local c = LP.Character; if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
    end
end

local function enableGodMode()
    if godModeEnabled then return end
    godModeEnabled = true
    godModeChar = LP.Character or LP.CharacterAdded:Wait()
    godModeHum = godModeChar:FindFirstChildOfClass("Humanoid")
    charAddedConn = LP.CharacterAdded:Connect(function(c) godModeChar = c; godModeHum = c:WaitForChild("Humanoid") end)
    godModeConn = RunService.Heartbeat:Connect(function()
        if godModeHum then
            godModeHum.Health = godModeHum.MaxHealth
            if godModeHum.MaxHealth < 100 then godModeHum.MaxHealth = 100 end
            godModeHum.BreakJointsOnDeath = false
        end
    end)
end

local function disableGodMode()
    godModeEnabled = false
    if godModeConn then godModeConn:Disconnect(); godModeConn = nil end
    if charAddedConn then charAddedConn:Disconnect(); charAddedConn = nil end
end

local function setWalkSpeed(h, v) if h and h.Parent then pcall(function() h.WalkSpeed = v end) end end

local function bindSpeedLoop()
    if speedBound then return end
    speedBound = true
    RunService:BindToRenderStep("VD_SpeedEnforcer", 300, function()
        if speedHumanoid and speedHumanoid.Parent and featureStates.WalkSpeed and speedHumanoid.WalkSpeed ~= featureStates.WalkSpeedValue then
            setWalkSpeed(speedHumanoid, featureStates.WalkSpeedValue)
        end
    end)
end

local function unbindSpeedLoop()
    if speedBound then
        speedBound = false
        pcall(function() RunService:UnbindFromRenderStep("VD_SpeedEnforcer") end)
    end
end

local function hookHumanoid(h)
    speedHumanoid = h
    if featureStates.WalkSpeed then
        setWalkSpeed(h, featureStates.WalkSpeedValue)
        bindSpeedLoop()
    else
        pcall(function() if h and h.Parent then h.WalkSpeed = 16 end end)
    end
    h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if h.Parent and featureStates.WalkSpeed and h.WalkSpeed ~= featureStates.WalkSpeedValue then
            setWalkSpeed(h, featureStates.WalkSpeedValue)
        end
    end)
end

local function onCharacterAdded(char)
    local h = char:WaitForChild("Humanoid", 10) or char:FindFirstChildOfClass("Humanoid")
    if h then
        hookHumanoid(h)
        parryHumanoid = h
        loadParryAnimations()
    end
    char.ChildAdded:Connect(function(ch)
        if ch:IsA("Humanoid") then
            hookHumanoid(ch)
            parryHumanoid = ch
            loadParryAnimations()
        end
    end)
end

local function startAntiAFK()
    antiAFKConn = LP.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    end)
end

local function stopAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect(); antiAFKConn = nil end
end

local function toggleAntiStun(s)
    featureStates.AntiStun = s
    if s then
        antiStunConn = RunService.Heartbeat:Connect(function()
            if not featureStates.AntiStun then antiStunConn:Disconnect(); antiStunConn = nil; return end
            local c = LP.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then
                    if h.PlatformStand then h.PlatformStand = false end
                    if h:GetState() == Enum.HumanoidStateType.FallingDown or h:GetState() == Enum.HumanoidStateType.Ragdoll then
                        h:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end
            end
        end)
        safeNotify("AntiStun", "Activated", 3)
    elseif antiStunConn then
        antiStunConn:Disconnect(); antiStunConn = nil
        safeNotify("AntiStun", "Deactivated", 3)
    end
end

local function toggleMoonwalk(s)
    featureStates.MoonWalk = s
    if s then
        moonwalkConn = RunService.RenderStepped:Connect(function()
            local c = LP.Character
            if not c then return end
            local h = c:FindFirstChildOfClass("Humanoid")
            local r = c:FindFirstChild("HumanoidRootPart")
            if h and r then
                h.AutoRotate = false
                if h.MoveDirection.Magnitude > 0 then
                    local dir = h.MoveDirection
                    local tl = Vector3.new(-dir.X,0,-dir.Z)
                    if tl.Magnitude > 0 then
                        r.CFrame = CFrame.lookAt(r.Position, r.Position + tl.Unit)
                    end
                end
            end
        end)
        safeNotify("MoonWalk", "Activated", 3)
    else
        if moonwalkConn then
            moonwalkConn:Disconnect(); moonwalkConn = nil
            local c = LP.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then h.AutoRotate = true end
            end
        end
        safeNotify("MoonWalk", "Deactivated", 3)
    end
end

local FallRemote = pcall(function() return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Mechanics"):WaitForChild("Fall") end) and ReplicatedStorage.Remotes.Mechanics.Fall or nil
local NoFallMT, NoFallOrig = nil, nil

local function setupNoFall()
    if NoFallMT then return end
    NoFallMT = getrawmetatable(game)
    if not NoFallMT then return end
    NoFallOrig = NoFallMT.__namecall
    setreadonly(NoFallMT, false)
    NoFallMT.__namecall = newcclosure(function(self, ...)
        if NoFallEnabled and FallRemote and self == FallRemote and getnamecallmethod() == "FireServer" then
            return nil
        end
        return NoFallOrig(self, ...)
    end)
    setreadonly(NoFallMT, true)
end

local function enableNoFall()
    NoFallEnabled = true
    featureStates.NoFall = true
    if not NoFallMT then setupNoFall() end
end

local function disableNoFall()
    NoFallEnabled = false
    featureStates.NoFall = false
end

local lastInputTime, noSkillcheckEnabled, hookedMeta, origNamecall = tick(), false, false, nil

local function setupNoSkillcheck()
    if noSkillcheckEnabled then return end
    noSkillcheckEnabled = true
    local mt = getrawmetatable(game)
    if not mt then safeNotify("No Skillcheck", "Failed", 3) return end
    origNamecall = mt.__namecall
    local function onInput(a,s,i) if s == Enum.UserInputState.Begin then lastInputTime = tick() end end
    UserInputService.InputBegan:Connect(onInput)
    UserInputService.InputChanged:Connect(onInput)
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        if noSkillcheckEnabled and getnamecallmethod() == "FireServer" and tostring(self):lower():find("skill") then
            if tick() - lastInputTime > 2 then
                args[1] = "Great"
                safeNotify("No Skillcheck", "Auto skillcheck!", 1)
            end
        end
        return origNamecall(self, unpack(args))
    end)
    setreadonly(mt, true)
    hookedMeta = true
    safeNotify("No Skillcheck", "Activated", 4)
end

local function disableNoSkillcheck()
    if not noSkillcheckEnabled then return end
    noSkillcheckEnabled = false
    if hookedMeta then
        local mt = getrawmetatable(game)
        if mt and origNamecall then
            setreadonly(mt, false)
            mt.__namecall = origNamecall
            setreadonly(mt, true)
        end
        hookedMeta = false
    end
    safeNotify("No Skillcheck", "Deactivated", 3)
end

local function setBypassGate(s)
    featureStates.BypassGate = s
    local function gatherGates()
        local g={}
        local mainMap = Workspace:FindFirstChild("Map")
        if mainMap then
            for _,f in pairs(mainMap:GetChildren()) do
                for _,ga in pairs(f:GetChildren()) do
                    if ga.Name=="Gate" then table.insert(g,ga) end
                end
            end
        end
        return g
    end
    for _,gate in pairs(gatherGates()) do
        local lg, rg = gate:FindFirstChild("LeftGate"), gate:FindFirstChild("RightGate")
        if lg then
            lg.Transparency = s and 1 or 0
            lg.CanCollide = s and false or true
        end
        if rg then
            rg.Transparency = s and 1 or 0
            rg.CanCollide = s and false or true
        end
    end
end

local autoLeverRunning = false

local function startAutoLever()
    autoLeverRunning = true
    task.spawn(function()
        local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Exit") and ReplicatedStorage.Remotes.Exit:FindFirstChild("LeverEvent")
        if not remote then return end
        while autoLeverRunning and featureStates.AutoLever do
            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                for model, _ in pairs(worldReg.Gate) do
                    if model and alive(model) then
                        local exitLever = model:FindFirstChild("ExitLever")
                        if exitLever then
                            local main = exitLever:FindFirstChild("Main")
                            if main and (root.Position - main.Position).Magnitude <= 10 then
                                remote:FireServer(main, true)
                            end
                        end
                    end
                end
            end
            task.wait(2)
        end
    end)
end

local function stopAutoLever()
    autoLeverRunning = false
end

-- ========== UTILITY FUNCTIONS ==========
local function alive(i)
    if not i then return false end
    local ok = pcall(function() return i.Parent end)
    return ok and i.Parent ~= nil
end

local function validPart(p) return p and alive(p) and p:IsA("BasePart") end
local function clamp(n,lo,hi) if n<lo then return lo elseif n>hi then return hi else return n end end

local function firstBasePart(inst)
    if not alive(inst) then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        if inst.PrimaryPart and inst.PrimaryPart:IsA("BasePart") and alive(inst.PrimaryPart) then return inst.PrimaryPart end
        local p = inst:FindFirstChildWhichIsA("BasePart", true)
        if validPart(p) then return p end
    end
    if inst:IsA("Tool") then
        local h = inst:FindFirstChild("Handle") or inst:FindFirstChildWhichIsA("BasePart")
        if validPart(h) then return h end
    end
    return nil
end

local function makeBillboard(text, color3)
    local g = Instance.new("BillboardGui")
    g.Name = "VD_Tag"
    g.AlwaysOnTop = true
    g.Size = UDim2.new(0, 200, 0, 20)
    g.StudsOffset = Vector3.new(0, 2.5, 0)
    g.MaxDistance = 0
    g.Adornee = nil
    local l = Instance.new("TextLabel")
    l.Name = "Label"
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, 0, 1, 0)
    l.Font = Enum.Font.GothamBold
    l.Text = text
    l.TextSize = featureStates.ESPTextSize
    l.TextColor3 = color3 or Color3.new(1,1,1)
    l.TextStrokeTransparency = 0.3
    l.TextStrokeColor3 = Color3.new(0,0,0)
    l.BorderSizePixel = 0
    l.Parent = g
    return g
end

local function makeColoredBillboard(playerName, itemText, playerColor, itemColor, distanceText)
    local g = Instance.new("BillboardGui")
    g.Name = "VD_Tag"
    g.AlwaysOnTop = true
    g.Size = UDim2.new(0, 200, 0, 20)
    g.StudsOffset = Vector3.new(0, 2.5, 0)
    g.MaxDistance = 0
    g.Adornee = nil
    local l = Instance.new("TextLabel")
    l.Name = "Label"
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, 0, 1, 0)
    l.Font = Enum.Font.GothamBold
    l.TextSize = featureStates.ESPTextSize
    l.TextStrokeTransparency = 0.3
    l.TextStrokeColor3 = Color3.new(0,0,0)
    l.BorderSizePixel = 0
    local fullText = ""
    if playerName and playerName ~= "" then fullText = playerName end
    if itemText and itemText ~= "" then
        if fullText ~= "" then fullText = fullText .. " " end
        fullText = fullText .. itemText
    end
    if distanceText and distanceText ~= "" then fullText = fullText .. " " .. distanceText end
    l.Text = fullText
    if itemText and itemText ~= "" then
        l.TextColor3 = itemColor
    else
        l.TextColor3 = playerColor
    end
    l.Parent = g
    return g
end

local function ensureHighlight(model, fill, isPlayer)
    if not (model and model:IsA("Model") and alive(model)) then return end
    local hl = model:FindFirstChild("VD_HL")
    if not hl then
        local ok, obj = pcall(function()
            local h = Instance.new("Highlight")
            h.Name = "VD_HL"
            h.Adornee = model
            h.FillTransparency = 0.9
            h.OutlineTransparency = 0.2
            h.Parent = model
            return h
        end)
        if ok then hl = obj else return end
    end
    hl.FillColor = fill
    hl.OutlineColor = fill
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    if isPlayer then
        hl.FillTransparency = 0.9
        hl.OutlineTransparency = 0.1
    else
        hl.FillTransparency = 0.95
        hl.OutlineTransparency = 0.3
    end
end

local function clearHighlight(model)
    if model and model:FindFirstChild("VD_HL") then
        pcall(function() model.VD_HL:Destroy() end)
    end
end

local displayNames = {
    ["Parrying Dagger"] = "Parrying Dagger",
    ["Motion Tracker"] = "Motion Tracker",
    ["Gate"] = "Gate",
    ["Flashlight"] = "Flashlight",
    ["Bandage"] = "Bandage",
    ["Adrenaline Shot"] = "Adrenaline Shot",
    ["Shadow Clone"] = "Shadow Clone",
}

local function getSurvivorItem(pl)
    if not pl.Character then return nil end
    for _, obj in ipairs(pl.Character:GetDescendants()) do
        if (obj:IsA("Tool") or obj:IsA("Accessory")) and displayNames[obj.Name] then
            return "("..displayNames[obj.Name]..")"
        end
    end
    return nil
end

local function pickRep(model, cat)
    if not (model and alive(model)) then return nil end
    if cat == "Generator" then
        local hb = model:FindFirstChild("HitBox", true)
        if validPart(hb) then return hb end
    elseif cat == "Palletwrong" then
        local a = model:FindFirstChild("HumanoidRootPart", true); if validPart(a) then return a end
        local b = model:FindFirstChild("PrimaryPartPallet", true); if validPart(b) then return b end
        local c = model:FindFirstChild("Primary1", true); if validPart(c) then return c end
        local d = model:FindFirstChild("Primary2", true); if validPart(d) then return d end
    end
    return firstBasePart(model)
end

local function genLabelData(model)
    local pct = tonumber(model:GetAttribute("RepairProgress")) or 0
    if pct>=0 and pct<=1.001 then pct = pct*100 end
    pct = clamp(pct,0,100)
    local repairers = tonumber(model:GetAttribute("PlayersRepairingCount")) or 0
    local paused = (model:GetAttribute("ProgressPaused")==true)
    local kickcount = tonumber(model:GetAttribute("kickcount")) or 0
    local abyss50 = (model:GetAttribute("Abyss50Triggered")==true)
    local parts = {"Gen "..tostring(math.floor(pct+0.5)).."%" }
    if repairers>0 then parts[#parts+1]="("..repairers.."p)" end
    if paused then parts[#parts+1]="⏸" end
    if abyss50 then parts[#parts+1]="⚠" end
    if kickcount and kickcount>0 then parts[#parts+1]="K:"..kickcount end
    local text = table.concat(parts," ")
    local hue = clamp((pct/100)*0.33,0,0.33)
    local labelColor = Color3.fromHSV(hue,1,1)
    return text, labelColor
end

local function isPalletGone(m)
    if not alive(m) then return true end
    if not m:IsDescendantOf(Workspace) then return true end
    if palletState[m]=="DEST" then return true end
    local ok, val = pcall(function() return m:GetAttribute("Destroyed") end)
    if ok and val == true then return true end
    if not m:FindFirstChildWhichIsA("BasePart", true) then return true end
    return false
end

local function ensureWorldEntry(cat, model)
    if not alive(model) or worldReg[cat][model] then return end
    if cat=="Palletwrong" and isPalletGone(model) then return end
    local rep = pickRep(model, cat)
    if not validPart(rep) then return end
    worldReg[cat][model] = {part = rep}
end

local function removeWorldEntry(cat, model)
    local e = worldReg[cat][model]
    if not e then return end
    if e.part then
        local c = e.part:FindFirstChild("VD_Text_"..cat)
        if c then pcall(function() c:Destroy() end) end
    end
    worldReg[cat][model] = nil
end

local function registerFromDescendant(obj)
    if not alive(obj) then return end
    if obj:IsA("Model") then
        local validCats = {Generator=true, Hook=true, Gate=true, Window=true, Palletwrong=true}
        if validCats[obj.Name] then
            ensureWorldEntry(obj.Name, obj)
            return
        end
    end
    if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") then
        local validCats = {Generator=true, Hook=true, Gate=true, Window=true, Palletwrong=true}
        if validCats[obj.Parent.Name] then
            ensureWorldEntry(obj.Parent.Name, obj.Parent)
        end
    end
end

local function unregisterFromDescendant(obj)
    if not obj then return end
    if obj:IsA("Model") then
        local validCats = {Generator=true, Hook=true, Gate=true, Window=true, Palletwrong=true}
        if validCats[obj.Name] then
            removeWorldEntry(obj.Name, obj)
            return
        end
    end
    if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") then
        local validCats = {Generator=true, Hook=true, Gate=true, Window=true, Palletwrong=true}
        if validCats[obj.Parent.Name] then
            local e = worldReg[obj.Parent.Name][obj.Parent]
            if e and e.part == obj then removeWorldEntry(obj.Parent.Name, obj.Parent) end
        end
    end
end

local function attachRoot(root)
    if not root or mapAdd[root] then return end
    mapAdd[root] = root.DescendantAdded:Connect(registerFromDescendant)
    mapRem[root] = root.DescendantRemoving:Connect(unregisterFromDescendant)
    for _,d in ipairs(root:GetDescendants()) do registerFromDescendant(d) end
end

local function refreshRoots()
    for _,cn in pairs(mapAdd) do if cn then cn:Disconnect() end end
    for _,cn in pairs(mapRem) do if cn then cn:Disconnect() end end
    mapAdd, mapRem = {}, {}
    local r1 = Workspace:FindFirstChild("Map")
    local r2 = Workspace:FindFirstChild("Map1")
    if r1 then attachRoot(r1) end
    if r2 then attachRoot(r2) end
end

local function labelForPallet(model)
    local st = palletState[model] or "UP"
    if st=="DOWN" then return "Pallet (down)"
    elseif st=="DEST" then return "Pallet (destroyed)"
    elseif st=="SLIDE" then return "Pallet (slide)"
    else return "Pallet" end
end

local function labelForWindow(model)
    local st = windowState[model] or "READY"
    return st=="BUSY" and "Window (busy)" or "Window"
end

local function anyWorldEnabled()
    return featureStates.GeneratorESP or featureStates.HookESP or featureStates.GateESP or 
           featureStates.WindowESP or featureStates.PalletESP
end

local function startWorldLoop()
    if worldThread then return end
    worldThread = task.spawn(function()
        while anyWorldEnabled() do
            for cat,models in pairs(worldReg) do
                local en, col = false, featureStates.GeneratorColor
                if cat == "Generator" then en = featureStates.GeneratorESP; col = featureStates.GeneratorColor
                elseif cat == "Hook" then en = featureStates.HookESP; col = featureStates.HookColor
                elseif cat == "Gate" then en = featureStates.GateESP; col = featureStates.GateColor
                elseif cat == "Window" then en = featureStates.WindowESP; col = featureStates.WindowColor
                elseif cat == "Palletwrong" then en = featureStates.PalletESP; col = featureStates.PalletColor end
                if en then
                    local textName = "VD_Text_"..cat
                    for model,entry in pairs(models) do
                        if cat=="Palletwrong" and isPalletGone(model) then
                            removeWorldEntry(cat, model)
                        else
                            local part = entry.part
                            if model and alive(model) then
                                if not validPart(part) then
                                    entry.part = pickRep(model, cat)
                                    part = entry.part
                                end
                                if validPart(part) then
                                    ensureHighlight(model, col, false)
                                    local bb = part:FindFirstChild(textName)
                                    if not bb then
                                        local disp = cat=="Palletwrong" and "Pallet" or cat
                                        bb = makeBillboard(disp, col)
                                        bb.Name = textName
                                        bb.Adornee = part
                                        bb.Parent = part
                                    end
                                    local lbl = bb:FindFirstChild("Label")
                                    if lbl then
                                        lbl.TextSize = featureStates.ESPTextSize
                                        if cat=="Generator" then
                                            local txt,lc = genLabelData(model)
                                            lbl.Text = txt
                                            lbl.TextColor3 = lc
                                        elseif cat=="Palletwrong" then
                                            lbl.Text = labelForPallet(model)
                                            lbl.TextColor3 = col
                                        elseif cat=="Window" then
                                            lbl.Text = labelForWindow(model)
                                            lbl.TextColor3 = col
                                        else
                                            lbl.Text = cat
                                            lbl.TextColor3 = col
                                        end
                                    end
                                end
                            else
                                removeWorldEntry(cat, model)
                            end
                        end
                        task.wait()
                    end
                else
                    for model,_ in pairs(models) do
                        if model and alive(model) then clearHighlight(model) end
                    end
                end
            end
            task.wait(0.25)
        end
        worldThread = nil
    end)
end

-- ========== ESP SYSTEMS ==========
local function applyPlayerESP(p)
    if p == LP then return end
    local c = p.Character
    if not (c and alive(c)) then return end
    local role = getRoleFast(p)
    clearHighlight(c)
    local head = c:FindFirstChild("Head")
    if head then
        local t = head:FindFirstChild("VD_Tag")
        if t then pcall(function() t:Destroy() end) end
    end
    local distanceText = ""
    if featureStates.DistanceESP and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        local root = LP.Character.HumanoidRootPart
        local targetRoot = c:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local distance = math.floor((root.Position - targetRoot.Position).Magnitude)
            distanceText = "[" .. distance .. "m]"
        end
    end
    if role == "Survivor" and featureStates.SurvivorESP then
        ensureHighlight(c, featureStates.SurvivorColor, true)
        if (featureStates.Nametags or featureStates.DistanceESP or featureStates.SurvivorItemsESP) and head and validPart(head) then
            local playerName = ""
            if featureStates.Nametags then playerName = p.Name end
            local itemText = ""
            if featureStates.SurvivorItemsESP then
                local item = getSurvivorItem(p)
                if item then itemText = item end
            end
            local tag = makeColoredBillboard(playerName, itemText, featureStates.SurvivorColor, featureStates.SurvivorItemsColor, distanceText)
            tag.Name = "VD_Tag"
            tag.Adornee = head
            tag.Parent = head
        end
    elseif role == "Killer" and featureStates.KillerESP then
        ensureHighlight(c, featureStates.KillerColor, true)
        if (featureStates.Nametags or featureStates.DistanceESP) and head and validPart(head) then
            local displayText = ""
            if featureStates.Nametags then displayText = "Killer" end
            displayText = displayText .. " " .. distanceText
            local tag = makeBillboard(displayText, featureStates.KillerColor)
            tag.Name = "VD_Tag"
            tag.Adornee = head
            tag.Parent = head
        end
    end
end

local function watchPlayer(p)
    if playerConns[p] then
        for _,cn in ipairs(playerConns[p]) do cn:Disconnect() end
    end
    playerConns[p] = {}
    table.insert(playerConns[p], p.CharacterAdded:Connect(function()
        task.delay(0.15, function() applyPlayerESP(p) end)
    end))
    table.insert(playerConns[p], p:GetPropertyChangedSignal("Team"):Connect(function() applyPlayerESP(p) end))
    if p.Character then applyPlayerESP(p) end
end

local function unwatchPlayer(p)
    if p.Character then
        clearHighlight(p.Character)
        local head = p.Character:FindFirstChild("Head")
        if head and head:FindFirstChild("VD_Tag") then
            pcall(function() head.VD_Tag:Destroy() end)
        end
    end
    if playerConns[p] then
        for _,cn in ipairs(playerConns[p]) do cn:Disconnect() end
    end
    playerConns[p] = nil
end

local function updateDistanceDisplay()
    if not featureStates.DistanceESP then return end
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP and pl.Character and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local head = pl.Character:FindFirstChild("Head")
            if head then
                local tag = head:FindFirstChild("VD_Tag")
                if tag and tag:FindFirstChild("Label") then
                    local label = tag.Label
                    local orig = label.Text:gsub(" %[%d+m%]", "")
                    local dist = math.floor((LP.Character.HumanoidRootPart.Position - (pl.Character.HumanoidRootPart and pl.Character.HumanoidRootPart.Position or Vector3.new(0,0,0))).Magnitude)
                    label.Text = orig .. " [" .. dist .. "m]"
                end
            end
        end
    end
end

local function startDistanceUpdate()
    if distanceUpdateThread then return end
    distanceUpdateThread = task.spawn(function()
        while featureStates.DistanceESP do
            updateDistanceDisplay()
            task.wait(0.2)
        end
        distanceUpdateThread = nil
    end)
end

local function stopDistanceUpdate()
    if distanceUpdateThread then distanceUpdateThread = nil end
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP and pl.Character then
            local head = pl.Character:FindFirstChild("Head")
            if head then
                local tag = head:FindFirstChild("VD_Tag")
                if tag and tag:FindFirstChild("Label") then
                    local label = tag.Label
                    local orig = label.Text:gsub(" %[%d+m%]", "")
                    label.Text = orig
                end
            end
        end
    end
end

-- ========== KILLER FEATURES ==========
local killerSurvivorESPConn = nil

local function toggleKillerSurvivorESP(s)
    if killerSurvivorESPConn then
        killerSurvivorESPConn:Disconnect()
        killerSurvivorESPConn = nil
    end
    if s then
        killerSurvivorESPConn = RunService.Heartbeat:Connect(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and getRoleFast(p) == "Survivor" and p.Character then
                    ensureHighlight(p.Character, Color3.fromRGB(255, 50, 50), true)
                end
            end
        end)
        safeNotify("Killer ESP", "Survivor ESP activated", 2)
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then clearHighlight(p.Character) end
        end
        safeNotify("Killer ESP", "Survivor ESP deactivated", 2)
    end
end

local function teleportToNearestSurvivor()
    local nearest, nearestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and getRoleFast(p) == "Survivor" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = p
            end
        end
    end
    if nearest and nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart") then
        LP.Character.HumanoidRootPart.CFrame = nearest.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        safeNotify("Teleport", "Teleported to " .. nearest.Name, 2)
    else
        safeNotify("Teleport", "No survivor found!", 2)
    end
end

-- ========== TELEPORT FEATURES ==========
local function teleportToNearestGenerator()
    local nearest, nearestDist = nil, math.huge
    for model, entry in pairs(worldReg.Generator) do
        local part = entry.part
        if part and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (LP.Character.HumanoidRootPart.Position - part.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = part
            end
        end
    end
    if nearest then
        LP.Character.HumanoidRootPart.CFrame = nearest.CFrame + Vector3.new(0, 3, 0)
        safeNotify("Teleport", "Teleported to nearest generator", 2)
    else
        safeNotify("Teleport", "No generator found!", 2)
    end
end

local function teleportToNearestGate()
    local nearest, nearestDist = nil, math.huge
    for model, entry in pairs(worldReg.Gate) do
        local part = entry.part
        if part and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (LP.Character.HumanoidRootPart.Position - part.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = part
            end
        end
    end
    if nearest then
        LP.Character.HumanoidRootPart.CFrame = nearest.CFrame + Vector3.new(0, 3, 0)
        safeNotify("Teleport", "Teleported to nearest gate", 2)
    else
        safeNotify("Teleport", "No gate found!", 2)
    end
end

local function teleportToNearestHook()
    local nearest, nearestDist = nil, math.huge
    for model, entry in pairs(worldReg.Hook) do
        local part = entry.part
        if part and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (LP.Character.HumanoidRootPart.Position - part.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = part
            end
        end
    end
    if nearest then
        LP.Character.HumanoidRootPart.CFrame = nearest.CFrame + Vector3.new(0, 3, 0)
        safeNotify("Teleport", "Teleported to nearest hook", 2)
    else
        safeNotify("Teleport", "No hook found!", 2)
    end
end

---------------------------------------------------
--== Create Enhanced Window ==--
---------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "KyelHub - Violence District",
    Author = "Kyel Hub",
    Icon = "rbxassetid://93825530139213",
    Folder = "KyelHub",
    Transparent = false,
    Size = UDim2.fromOffset(550, 450),
    Resizable = false,
    SideBarWidth = 150,
    HideSearchBar = false,
    ScrollBarEnabled = true,
    Theme = "KyelHub",
    OpenButton = { Enabled = false },
    User = { Enabled = true, Anonymous = false, Callback = function() end },
})

pcall(function()
    Window:CreateTopbarButton("TransparencyToggle", "eye", function()
        if getgenv().TransparencyEnabled then
            getgenv().TransparencyEnabled = false
            pcall(function() Window:ToggleTransparency(false) end)
            WindUI:Notify({ Title = "Transparency", Content = "Transparency disabled", Duration = 3, Icon = "eye" })
        else
            getgenv().TransparencyEnabled = true
            pcall(function() Window:ToggleTransparency(true) end)
            WindUI:Notify({ Title = "Transparency", Content = "Transparency enabled", Duration = 3, Icon = "eye-off" })
        end
    end, 990)
end)

---------------------------------------------------
--== Minimize Button ==--
---------------------------------------------------
for _, folder in ipairs(CoreGui:GetChildren()) do
    if folder:IsA("Folder") and folder.Name:len() > 10 then
        local gui = folder:FindFirstChild("KyelHubMinimizeButton")
        if gui then folder:Destroy(); break end
    end
end

local function randomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local str = ""
    for i = 1, length do
        local rand = math.random(1, #chars)
        str = str .. chars:sub(rand, rand)
    end
    return str
end

math.randomseed(os.time())
local folder = Instance.new("Folder")
folder.Name = randomString(20)
folder.Parent = CoreGui

local gui = Instance.new("ScreenGui")
gui.Name = "KyelHubMinimizeButton"
gui.Parent = folder
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.IgnoreGuiInset = true

local button = Instance.new("ImageButton")
button.Parent = gui
button.Size = UDim2.fromOffset(70, 70)
button.Position = UDim2.new(0, 20, 0, 100)
button.AnchorPoint = Vector2.new(0, 0)
button.Image = "rbxassetid://93825530139213"
button.BackgroundTransparency = 1
button.BorderSizePixel = 0
button.ScaleType = Enum.ScaleType.Fit
button.Visible = false
button.AutoButtonColor = false
button.Active = true
button.Draggable = false

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 0)
corner.Parent = button

local isMinimized = false
local dragging = false
local dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    local newX = startPos.X.Offset + delta.X
    local newY = startPos.Y.Offset + delta.Y
    local viewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
    if not viewportSize then viewportSize = game:GetService("GuiService"):GetScreenResolution() end
    local maxX = viewportSize.X - button.AbsoluteSize.X
    local maxY = viewportSize.Y - button.AbsoluteSize.Y
    newX = math.clamp(newX, 0, maxX)
    newY = math.clamp(newY, 0, maxY)
    button.Position = UDim2.new(0, newX, 0, newY)
end

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = button.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

button.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
        update(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging then update(input) end
end)

button.MouseButton1Click:Connect(function()
    if Window then
        Window:Open()
        button.Visible = false
        isMinimized = false
    end
end)

if Window then
    Window:OnOpen(function()
        button.Visible = false
        isMinimized = false
    end)
    Window:OnClose(function()
        if not isMinimized then
            button.Visible = true
            isMinimized = true
        end
    end)
end

---------------------------------------------------
--== Tabs ==--
---------------------------------------------------
local PlayerTab = Window:Tab({ Title = "Players", Icon = "user" })
local SurvivorTab = Window:Tab({ Title = "Survivor", Icon = "users" })
local KillerTab = Window:Tab({ Title = "Killer", Icon = "crosshair" })
local ESPTab = Window:Tab({ Title = "ESP", Icon = "eye" })
local WorldTab = Window:Tab({ Title = "World", Icon = "globe" })
local VisualTab = Window:Tab({ Title = "Visual", Icon = "sparkles" })
local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "compass" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

---------------------------------------------------
--== Player Tab ==--
---------------------------------------------------
local MovementSection = PlayerTab:Section({ Title = "Movement", Opened = true })

MovementSection:Toggle({
    Title = "Walk Speed",
    Default = false,
    Callback = function(s)
        featureStates.WalkSpeed = s
        if s then
            if speedHumanoid and speedHumanoid.Parent then
                setWalkSpeed(speedHumanoid, featureStates.WalkSpeedValue)
            end
            bindSpeedLoop()
        else
            unbindSpeedLoop()
            if speedHumanoid and speedHumanoid.Parent then
                setWalkSpeed(speedHumanoid, 16)
            end
        end
    end
})

MovementSection:Slider({
    Title = "Walk Speed Value",
    Step = 1,
    Value = {Min = 0, Max = 200, Default = 16},
    Callback = function(v)
        featureStates.WalkSpeedValue = v
        if featureStates.WalkSpeed and speedHumanoid and speedHumanoid.Parent then
            setWalkSpeed(speedHumanoid, v)
            bindSpeedLoop()
        end
    end
})

MovementSection:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(s)
        featureStates.Noclip = s
        setNoclip(s)
    end
})

MovementSection:Toggle({
    Title = "God Mode",
    Default = false,
    Callback = function(s)
        featureStates.GodMode = s
        if s then
            enableGodMode()
            safeNotify("God Mode", "God Mode activated! You are now invincible.", 3)
        else
            disableGodMode()
            safeNotify("God Mode", "God Mode deactivated.", 3)
        end
    end
})

MovementSection:Toggle({
    Title = "MoonWalk",
    Default = false,
    Callback = function(s)
        toggleMoonwalk(s)
    end
})

local UtilitySection = PlayerTab:Section({ Title = "Utilities", Opened = false })

UtilitySection:Toggle({
    Title = "Anti AFK",
    Default = false,
    Callback = function(s)
        featureStates.AntiAFK = s
        if s then startAntiAFK() else stopAntiAFK() end
    end
})

UtilitySection:Toggle({
    Title = "No Fall",
    Default = false,
    Callback = function(s)
        featureStates.NoFall = s
        if s then
            enableNoFall()
            safeNotify("No Fall", "No Fall activated! You won't take fall damage.", 3)
        else
            disableNoFall()
            safeNotify("No Fall", "No Fall deactivated.", 3)
        end
    end
})

UtilitySection:Toggle({
    Title = "Anti Stun",
    Default = false,
    Callback = function(s)
        toggleAntiStun(s)
    end
})

---------------------------------------------------
--== Survivor Tab ==--
---------------------------------------------------
local SurvivorMainSection = SurvivorTab:Section({ Title = "Survivor Main", Opened = true })

SurvivorMainSection:Toggle({
    Title = "⚔️ Auto Parry ⚔️",
    Default = false,
    Callback = function(s)
        toggleAutoParry(s)
    end
})

SurvivorMainSection:Slider({
    Title = "Parry Range",
    Step = 0.5,
    Value = {Min = 3, Max = 20, Default = 8},
    Callback = function(v)
        featureStates.ParryRange = v
    end
})

SurvivorMainSection:Slider({
    Title = "Parry Cooldown (detik)",
    Step = 0.1,
    Value = {Min = 0.2, Max = 2.0, Default = 0.5},
    Callback = function(v)
        featureStates.ParryCooldown = v
    end
})

SurvivorMainSection:Toggle({
    Title = "Auto Lever",
    Default = false,
    Callback = function(s)
        featureStates.AutoLever = s
        if s then startAutoLever() else stopAutoLever() end
    end
})

SurvivorMainSection:Toggle({
    Title = "No Skillcheck",
    Default = false,
    Callback = function(s)
        featureStates.NoSkillcheck = s
        if s then setupNoSkillcheck() else disableNoSkillcheck() end
    end
})

SurvivorMainSection:Toggle({
    Title = "Bypass Gate",
    Default = false,
    Callback = function(s)
        featureStates.BypassGate = s
        setBypassGate(s)
    end
})

---------------------------------------------------
--== Killer Tab ==--
---------------------------------------------------
local KillerMainSection = KillerTab:Section({ Title = "Killer Utilities", Opened = true })

KillerMainSection:Toggle({
    Title = "ESP Semua Survivor",
    Default = false,
    Callback = function(s)
        toggleKillerSurvivorESP(s)
    end
})

KillerMainSection:Button({
    Title = "Teleport ke Survivor Terdekat",
    Callback = teleportToNearestSurvivor
})

---------------------------------------------------
--== ESP Tab ==--
---------------------------------------------------
local ESPSettingsSection = ESPTab:Section({ Title = "ESP Settings", Opened = true })

ESPSettingsSection:Slider({
    Title = "ESP Fill Transparency",
    Step = 0.05,
    Value = {Min = 0, Max = 1, Default = 0.7},
    Callback = function(v)
        featureStates.ESPFillTransparency = v
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LP then applyPlayerESP(p) end
        end
    end
})

ESPSettingsSection:Slider({
    Title = "ESP Outline Transparency",
    Step = 0.05,
    Value = {Min = 0, Max = 1, Default = 0},
    Callback = function(v)
        featureStates.ESPOutlineTransparency = v
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LP then applyPlayerESP(p) end
        end
    end
})

ESPSettingsSection:Slider({
    Title = "ESP Text Size",
    Step = 1,
    Value = {Min = 8, Max = 20, Default = 14},
    Callback = function(v)
        featureStates.ESPTextSize = v
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LP then applyPlayerESP(p) end
        end
    end
})

local PlayerESPSection = ESPTab:Section({ Title = "Player ESP", Opened = true })

PlayerESPSection:Toggle({
    Title = "Survivor ESP",
    Default = false,
    Callback = function(s)
        featureStates.SurvivorESP = s
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LP and getRoleFast(p) == "Survivor" then applyPlayerESP(p) end
        end
    end
})

PlayerESPSection:Toggle({
    Title = "Killer ESP",
    Default = false,
    Callback = function(s)
        featureStates.KillerESP = s
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LP and getRoleFast(p) == "Killer" then applyPlayerESP(p) end
        end
    end
})

PlayerESPSection:Toggle({
    Title = "Nametags",
    Default = false,
    Callback = function(s)
        featureStates.Nametags = s
        for _,p in ipairs(Players:GetPlayers()) do if p ~= LP then applyPlayerESP(p) end end
    end
})

PlayerESPSection:Toggle({
    Title = "Distance ESP",
    Default = false,
    Callback = function(s)
        featureStates.DistanceESP = s
        if s then
            startDistanceUpdate()
            for _,p in ipairs(Players:GetPlayers()) do if p ~= LP then applyPlayerESP(p) end end
        else
            stopDistanceUpdate()
            for _,p in ipairs(Players:GetPlayers()) do if p ~= LP then applyPlayerESP(p) end end
        end
    end
})

PlayerESPSection:Toggle({
    Title = "Survivor Items ESP",
    Default = false,
    Callback = function(s)
        featureStates.SurvivorItemsESP = s
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LP and getRoleFast(p) == "Survivor" then applyPlayerESP(p) end
        end
    end
})

PlayerESPSection:Colorpicker({
    Title = "Survivor Color",
    Default = featureStates.SurvivorColor,
    Callback = function(c)
        featureStates.SurvivorColor = c
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LP and getRoleFast(p) == "Survivor" and featureStates.SurvivorESP then
                applyPlayerESP(p)
            end
        end
    end
})

PlayerESPSection:Colorpicker({
    Title = "Killer Color",
    Default = featureStates.KillerColor,
    Callback = function(c)
        featureStates.KillerColor = c
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LP and getRoleFast(p) == "Killer" and featureStates.KillerESP then
                applyPlayerESP(p)
            end
        end
    end
})

PlayerESPSection:Colorpicker({
    Title = "Survivor Items Color",
    Default = featureStates.SurvivorItemsColor,
    Callback = function(c)
        featureStates.SurvivorItemsColor = c
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LP and getRoleFast(p) == "Survivor" and featureStates.SurvivorESP and featureStates.SurvivorItemsESP then
                applyPlayerESP(p)
            end
        end
    end
})

---------------------------------------------------
--== World Tab ==--
---------------------------------------------------
local WorldTogglesSection = WorldTab:Section({ Title = "World ESP Toggles", Opened = true })

WorldTogglesSection:Toggle({
    Title = "Generators",
    Default = false,
    Callback = function(s)
        featureStates.GeneratorESP = s
        if s and not worldThread then startWorldLoop() end
    end
})

WorldTogglesSection:Toggle({
    Title = "Hooks",
    Default = false,
    Callback = function(s)
        featureStates.HookESP = s
        if s and not worldThread then startWorldLoop() end
    end
})

WorldTogglesSection:Toggle({
    Title = "Gates",
    Default = false,
    Callback = function(s)
        featureStates.GateESP = s
        if s and not worldThread then startWorldLoop() end
    end
})

WorldTogglesSection:Toggle({
    Title = "Windows",
    Default = false,
    Callback = function(s)
        featureStates.WindowESP = s
        if s and not worldThread then startWorldLoop() end
    end
})

WorldTogglesSection:Toggle({
    Title = "Pallets",
    Default = false,
    Callback = function(s)
        featureStates.PalletESP = s
        if s and not worldThread then startWorldLoop() end
    end
})

local WorldColorsSection = WorldTab:Section({ Title = "World ESP Colors", Opened = false })

WorldColorsSection:Colorpicker({
    Title = "Generator Color",
    Default = featureStates.GeneratorColor,
    Callback = function(c) featureStates.GeneratorColor = c end
})

WorldColorsSection:Colorpicker({
    Title = "Hook Color",
    Default = featureStates.HookColor,
    Callback = function(c) featureStates.HookColor = c end
})

WorldColorsSection:Colorpicker({
    Title = "Gate Color",
    Default = featureStates.GateColor,
    Callback = function(c) featureStates.GateColor = c end
})

WorldColorsSection:Colorpicker({
    Title = "Window Color",
    Default = featureStates.WindowColor,
    Callback = function(c) featureStates.WindowColor = c end
})

WorldColorsSection:Colorpicker({
    Title = "Pallet Color",
    Default = featureStates.PalletColor,
    Callback = function(c) featureStates.PalletColor = c end
})

---------------------------------------------------
--== Visual Tab ==--
---------------------------------------------------
local VisualSection = VisualTab:Section({ Title = "Visual Enhancements", Opened = true })

VisualSection:Toggle({
    Title = "FullBright",
    Default = false,
    Callback = function(s) toggleFullBright(s) end
})

VisualSection:Toggle({
    Title = "No Fog",
    Default = false,
    Callback = function(s) toggleNoFog(s) end
})

VisualSection:Toggle({
    Title = "Custom Time of Day",
    Default = false,
    Callback = function(s) setTimeOfDay(s) end
})

VisualSection:Slider({
    Title = "Time of Day Value",
    Step = 1,
    Value = {Min = 0, Max = 24, Default = 14},
    Callback = function(v) updateTimeOfDay(v) end
})

---------------------------------------------------
--== Teleport Tab ==--
---------------------------------------------------
local TeleportSection = TeleportTab:Section({ Title = "Teleport Locations", Opened = true })

TeleportSection:Button({
    Title = "Teleport ke Generator Terdekat",
    Callback = teleportToNearestGenerator
})

TeleportSection:Button({
    Title = "Teleport ke Gate Terdekat",
    Callback = teleportToNearestGate
})

TeleportSection:Button({
    Title = "Teleport ke Hook Terdekat",
    Callback = teleportToNearestHook
})

---------------------------------------------------
--== Settings Tab ==--
---------------------------------------------------
local SettingsSection = SettingsTab:Section({ Title = "Configuration", Opened = true })

SettingsSection:Button({
    Title = "Save Configuration",
    Callback = function()
        local cfg = Window.ConfigManager:Config("violence")
        cfg:Save()
        safeNotify("Settings", "Configuration saved!", 2)
    end
})

SettingsSection:Button({
    Title = "Load Configuration",
    Callback = function()
        local cfg = Window.ConfigManager:Config("violence")
        cfg:Load()
        safeNotify("Settings", "Configuration loaded!", 2)
    end
})

---------------------------------------------------
--== Initialize Systems ==--
---------------------------------------------------
if LP.Character then onCharacterAdded(LP.Character) end
LP.CharacterAdded:Connect(onCharacterAdded)

for _,p in ipairs(Players:GetPlayers()) do    if p ~= LP then watchPlayer(p) end
end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(unwatchPlayer)

refreshRoots()
Workspace.ChildAdded:Connect(function(ch)
    if ch.Name == "Map" or ch.Name == "Map1" then attachRoot(ch) end
end)
if anyWorldEnabled() then startWorldLoop() end

setupNoFall()

local MyConfig = Window.ConfigManager:Config("violence")
MyConfig:Load()

task.spawn(function()
    task.wait(3)
    safeNotify("KyelHub - Violence District", "Successfully loaded! Enjoy the features.", 6)
end)

Window:SelectTab(1)
Window:UnlockAll()
Window:Open()
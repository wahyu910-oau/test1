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
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

if setfpscap then setfpscap(1000000) print("FPS Unlocked!") end

local LP = LocalPlayer
local Camera = Workspace.CurrentCamera

-- Feature states storage
local featureStates = {
    WalkSpeed = false, WalkSpeedValue = 16, Noclip = false, AntiAFK = false,
    GodMode = false, NoFall = false, AntiStun = false, MoonWalk = false,
    ESPFillTransparency = 0.7, ESPOutlineTransparency = 0, ESPTextSize = 14,
    SurvivorESP = false, KillerESP = false, ZombieESP = false,
    Nametags = false, DistanceESP = false,
    SurvivorColor = Color3.fromRGB(0,255,0), KillerColor = Color3.fromRGB(255,0,0), ZombieColor = Color3.fromRGB(128,0,128),
    GeneratorESP = false, HookESP = false, GateESP = false, WindowESP = false, PalletESP = false,
    GeneratorColor = Color3.fromRGB(0,170,255), HookColor = Color3.fromRGB(255,0,0),
    GateColor = Color3.fromRGB(255,225,0), WindowColor = Color3.fromRGB(255,255,255), PalletColor = Color3.fromRGB(255,140,0),
    SurvivorItemsESP = false, SurvivorItemsColor = Color3.fromRGB(0,170,255),
    AutoLever = false, BypassGate = false, NoSkillcheck = false,
    AutoParry = false, ParryRange = 10, ParryCooldown = 0.5,
    AutoGenerator = false, GenQuality = "Perfect",
    FullBright = false, NoFog = false, TimeOfDay = false, TimeOfDayValue = 14,
}

-- ========== AUTO PARRY SYSTEM (FIXED) ==========
local autoParryRunning = false
local lastParryTime = 0
local parryHumanoid = nil
local currentParrySkin = "Default"

local skinList = {"Default", "BloodShield", "Enten", "Feedbecker", "Fih", "Parry-Circle", "StopWatch"}

local function getParryAnimationFromSkin(skinName)
    local animControl = ReplicatedStorage:FindFirstChild("AnimationControl")
    if animControl then
        for _, anim in ipairs(animControl:GetChildren()) do
            if anim:IsA("Animation") and (anim.Name:lower():find(skinName:lower()) or skinName:lower():find(anim.Name:lower())) then
                return anim.AnimationId
            end
        end
    end
    return nil
end

local function playParryAnimation()
    local char = LP.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    local animId = getParryAnimationFromSkin(currentParrySkin)
    if animId then
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        local track = animator:LoadAnimation(anim)
        if track then track:Play(); track.TimePosition = 0 end
    end
end

local function findParryClient()
    local paths = {
        ReplicatedStorage:FindFirstChild("ParryClient"),
        ReplicatedStorage:FindFirstChild("AnimationControl") and ReplicatedStorage.AnimationControl:FindFirstChild("ParryClient"),
        ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ParryClient"),
        ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Combat") and ReplicatedStorage.Remotes.Combat:FindFirstChild("ParryClient"),
    }
    for _, r in ipairs(paths) do if r and r:IsA("RemoteEvent") then return r end end
    for _, c in ipairs(ReplicatedStorage:GetDescendants()) do
        if c:IsA("RemoteEvent") and (c.Name:lower():find("parry") or c.Name:lower():find("block")) then return c end
    end
    return nil
end

local function findAttackEvent()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local attackFolder = remotes and remotes:FindFirstChild("Attack")
    if attackFolder then
        local attackEvent = attackFolder:FindFirstChild("AttackEvent")
        if attackEvent then return attackEvent end
        local basicAttack = attackFolder:FindFirstChild("BasicAttack")
        if basicAttack then return basicAttack end
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
            if tool.Name:lower():find("parrying") or tool.Name:lower():find("dagger") then return tool end
        end
    end
    local char = LP.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("parrying") or tool.Name:lower():find("dagger")) then return tool end
        end
    end
    return nil
end

local function triggerParry()
    playParryAnimation()
    local parryClient = findParryClient()
    if parryClient then
        local dagger = getParryingDagger()
        pcall(function() parryClient:FireServer() end)
        if dagger then pcall(function() parryClient:FireServer(dagger) end) end
        return true
    end
    if triggerParryViaAnimationHandler() then return true end
    local attackEvent = findAttackEvent()
    if attackEvent then pcall(function() attackEvent:FireServer() end); return true end
    local dagger = getParryingDagger()
    if dagger then
        if dagger.Parent ~= LP.Character then dagger.Parent = LP.Character end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:EquipTool(dagger); task.wait(0.02); dagger:Activate(); return true end
    end
    return false
end

local function getNearestKiller()
    local char = LP.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local nearest, nearestDist = nil, featureStates.ParryRange
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP then
            local role = "Survivor"
            if pl.Team then
                local tn = pl.Team.Name:lower()
                if tn:find("killer") then role = "Killer"
                elseif tn:find("survivor") then role = "Survivor" end
            end
            if role == "Killer" then
                local kChar = pl.Character
                if kChar and kChar:FindFirstChild("HumanoidRootPart") then
                    local dist = (root.Position - kChar.HumanoidRootPart.Position).Magnitude
                    if dist < nearestDist then nearestDist = dist; nearest = pl end
                end
            end
        end
    end
    return nearest
end

local function isAttacking(killerChar)
    if not killerChar then return false end
    local hum = killerChar:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return false end
    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
        local id = track.Animation and track.Animation.AnimationId or ""
        if id:lower():find("attack") or id:lower():find("swing") or id:lower():find("hit") or id:lower():find("lunge") then
            return true
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
                if (rootPart.Position - part.Position).Magnitude < 5 then return true end
            end
        end
    end
    return false
end

local function checkAndParry()
    if not featureStates.AutoParry then return end
    if tick() - lastParryTime < featureStates.ParryCooldown then return end
    local killer = getNearestKiller()
    if killer then
        local killerChar = killer.Character
        if isAttacking(killerChar) or isHitboxNearby(killerChar, LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")) then
            lastParryTime = tick()
            triggerParry()
        end
    end
end

local function startAutoParry()
    if autoParryRunning then return end
    autoParryRunning = true
    task.spawn(function() while autoParryRunning and featureStates.AutoParry do checkAndParry(); task.wait(0.05) end; autoParryRunning = false end)
end

local function stopAutoParry() autoParryRunning = false end
local function toggleAutoParry(s) featureStates.AutoParry = s; if s then startAutoParry() else stopAutoParry() end end
local function setParrySkin(skin) if table.find(skinList, skin) then currentParrySkin = skin end end

-- ========== AUTO GENERATOR ==========
local autoGenRunning = false
local lastGenTime = 0

local function findNearestGenerator()
    local char = LP.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local nearest, nearestDist = nil, 20
    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and model.Name == "Generator" then
            local part = model:FindFirstChild("HitBox") or model:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (root.Position - part.Position).Magnitude
                if dist < nearestDist then nearestDist = dist; nearest = model end
            end
        end
    end
    return nearest
end

local function doGenerator()
    if not featureStates.AutoGenerator then return end
    if tick() - lastGenTime < 0.3 then return end
    
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local genFolder = remotes and remotes:FindFirstChild("Generator")
    local repairEvent = genFolder and genFolder:FindFirstChild("RepairEvent")
    local repairAnim = genFolder and genFolder:FindFirstChild("RepairAnim")
    local skillCheckResult = genFolder and genFolder:FindFirstChild("SkillCheckResultEvent")
    local skillCheckEvent = genFolder and genFolder:FindFirstChild("SkillCheckEvent")
    
    if featureStates.GenQuality == "Instant" then
        if repairEvent then
            local gen = findNearestGenerator()
            pcall(function() repairEvent:FireServer(gen) end)
            lastGenTime = tick()
        end
    elseif featureStates.GenQuality == "Perfect" then
        if skillCheckResult then
            pcall(function() skillCheckResult:FireServer("Perfect") end)
            lastGenTime = tick()
        elseif skillCheckEvent then
            pcall(function() skillCheckEvent:FireServer("Perfect") end)
            lastGenTime = tick()
        end
    else -- Normal
        if repairAnim then
            local gen = findNearestGenerator()
            pcall(function() repairAnim:FireServer(gen) end)
            lastGenTime = tick()
        elseif repairEvent then
            local gen = findNearestGenerator()
            pcall(function() repairEvent:FireServer(gen) end)
            lastGenTime = tick()
        end
    end
end

local function startAutoGenerator()
    if autoGenRunning then return end
    autoGenRunning = true
    task.spawn(function() while autoGenRunning and featureStates.AutoGenerator do doGenerator(); task.wait(0.2) end; autoGenRunning = false end)
end

local function stopAutoGenerator() autoGenRunning = false end
local function toggleAutoGen(s) featureStates.AutoGenerator = s; if s then startAutoGenerator() else stopAutoGenerator() end end
local function setGenQuality(q) if q == "Normal" or q == "Instant" or q == "Perfect" then featureStates.GenQuality = q end end

-- ========== ESP ZOMBIE ==========
local zombieEspRunning = false

local function isZombieTheCure(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name:lower()
    if name:find("zombie") or name:find("thecure") or name:find("cure") then return true end
    if model:FindFirstChild("TheCureStaff") or model:FindFirstChild("CureStaff") or model:FindFirstChild("Handle") or model:FindFirstChild("Flask") or model:FindFirstChild("Cure") then return true end
    if model:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(model) then
        if model:FindFirstChild("TheCureStaff") or model:FindFirstChild("Flask") then return true end
    end
    return false
end

local function applyZombieHighlight(model)
    if not featureStates.ZombieESP then
        if model and model:FindFirstChild("Zombie_HL") then pcall(function() model.Zombie_HL:Destroy() end) end
        return
    end
    local hl = model:FindFirstChild("Zombie_HL")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "Zombie_HL"
        hl.Adornee = model
        hl.Parent = model
    end
    hl.FillColor = featureStates.ZombieColor
    hl.OutlineColor = featureStates.ZombieColor
    hl.FillTransparency = featureStates.ESPFillTransparency
    hl.OutlineTransparency = featureStates.ESPOutlineTransparency
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function scanZombies()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and isZombieTheCure(obj) then
            applyZombieHighlight(obj)
        end
    end
end

local function startZombieESP()
    if zombieEspRunning then return end
    zombieEspRunning = true
    task.spawn(function() while zombieEspRunning and featureStates.ZombieESP do scanZombies(); task.wait(0.25) end; zombieEspRunning = false end)
end

local function stopZombieESP() zombieEspRunning = false end
local function toggleZombieESP(s) featureStates.ZombieESP = s; if s then startZombieESP() else stopZombieESP() end end

-- ========== VISUAL FUNCTIONS ==========
local function safeNotify(t, c, d) WindUI:Notify({Title=t, Content=c, Duration=d or 2, Icon="info"}) end

local function toggleFullBright(s)
    featureStates.FullBright = s
    if s then Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
    else Lighting.Brightness = 0.5; Lighting.FogEnd = 100; Lighting.GlobalShadows = true end
    safeNotify("FullBright", s and "Activated" or "Deactivated", 2)
end

local function toggleNoFog(s)
    featureStates.NoFog = s
    if s then Lighting.FogEnd = 100000 else Lighting.FogEnd = 100 end
    safeNotify("NoFog", s and "Fog removed" or "Fog restored", 2)
end

local function setTimeOfDay(s) featureStates.TimeOfDay = s; if s then Lighting.ClockTime = featureStates.TimeOfDayValue; safeNotify("Time of Day", "Set to "..featureStates.TimeOfDayValue..":00", 2) end end
local function updateTimeOfDay(v) featureStates.TimeOfDayValue = v; if featureStates.TimeOfDay then Lighting.ClockTime = v end end

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
    elseif not s and noclipConn then noclipConn:Disconnect(); noclipConn = nil; local c = LP.Character; if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end end
end

local function enableGodMode()
    if godModeEnabled then return end
    godModeEnabled = true
    godModeChar = LP.Character or LP.CharacterAdded:Wait()
    godModeHum = godModeChar:FindFirstChildOfClass("Humanoid")
    charAddedConn = LP.CharacterAdded:Connect(function(c) godModeChar = c; godModeHum = c:WaitForChild("Humanoid") end)
    godModeConn = RunService.Heartbeat:Connect(function()
        if godModeHum then godModeHum.Health = godModeHum.MaxHealth; if godModeHum.MaxHealth < 100 then godModeHum.MaxHealth = 100 end; godModeHum.BreakJointsOnDeath = false end
    end)
end

local function disableGodMode()
    godModeEnabled = false
    if godModeConn then godModeConn:Disconnect(); godModeConn = nil end
    if charAddedConn then charAddedConn:Disconnect(); charAddedConn = nil end
end

local function setWalkSpeed(h, v) if h and h.Parent then pcall(function() h.WalkSpeed = v end) end end
local function bindSpeedLoop()
    if speedBound then return end; speedBound = true
    RunService:BindToRenderStep("VD_SpeedEnforcer", 300, function()
        if speedHumanoid and speedHumanoid.Parent and featureStates.WalkSpeed and speedHumanoid.WalkSpeed ~= featureStates.WalkSpeedValue then
            setWalkSpeed(speedHumanoid, featureStates.WalkSpeedValue)
        end
    end)
end
local function unbindSpeedLoop() if speedBound then speedBound = false; pcall(function() RunService:UnbindFromRenderStep("VD_SpeedEnforcer") end) end end

local function hookHumanoid(h)
    speedHumanoid = h
    if featureStates.WalkSpeed then setWalkSpeed(h, featureStates.WalkSpeedValue); bindSpeedLoop()
    else pcall(function() if h and h.Parent then h.WalkSpeed = 16 end end) end
    h:GetPropertyChangedSignal("WalkSpeed"):Connect(function() if h.Parent and featureStates.WalkSpeed and h.WalkSpeed ~= featureStates.WalkSpeedValue then setWalkSpeed(h, featureStates.WalkSpeedValue) end end)
end

local function onCharacterAdded(char)
    local h = char:WaitForChild("Humanoid", 10) or char:FindFirstChildOfClass("Humanoid")
    if h then hookHumanoid(h); parryHumanoid = h end
    char.ChildAdded:Connect(function(ch) if ch:IsA("Humanoid") then hookHumanoid(ch); parryHumanoid = ch end end)
end

local function startAntiAFK() antiAFKConn = LP.Idled:Connect(function() VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame); task.wait(1); VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame) end) end
local function stopAntiAFK() if antiAFKConn then antiAFKConn:Disconnect(); antiAFKConn = nil end end

local function toggleAntiStun(s)
    featureStates.AntiStun = s
    if s then
        antiStunConn = RunService.Heartbeat:Connect(function()
            if not featureStates.AntiStun then antiStunConn:Disconnect(); antiStunConn = nil; return end
            local c = LP.Character; if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then if h.PlatformStand then h.PlatformStand = false end; if h:GetState() == Enum.HumanoidStateType.FallingDown or h:GetState() == Enum.HumanoidStateType.Ragdoll then h:ChangeState(Enum.HumanoidStateType.Running) end end end
        end)
        safeNotify("AntiStun", "Activated", 3)
    elseif antiStunConn then antiStunConn:Disconnect(); antiStunConn = nil; safeNotify("AntiStun", "Deactivated", 3) end
end

local function toggleMoonwalk(s)
    featureStates.MoonWalk = s
    if s then
        moonwalkConn = RunService.RenderStepped:Connect(function()
            local c = LP.Character; if not c then return end; local h = c:FindFirstChildOfClass("Humanoid"); local r = c:FindFirstChild("HumanoidRootPart")
            if h and r then h.AutoRotate = false; if h.MoveDirection.Magnitude > 0 then local dir = h.MoveDirection; local tl = Vector3.new(-dir.X,0,-dir.Z); if tl.Magnitude > 0 then r.CFrame = CFrame.lookAt(r.Position, r.Position + tl.Unit) end end end
        end)
        safeNotify("MoonWalk", "Activated", 3)
    else
        if moonwalkConn then moonwalkConn:Disconnect(); moonwalkConn = nil; local c = LP.Character; if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.AutoRotate = true end end end
        safeNotify("MoonWalk", "Deactivated", 3)
    end
end

local FallRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Mechanics") and ReplicatedStorage.Remotes.Mechanics:FindFirstChild("Fall")
local NoFallMT, NoFallOrig = nil, nil
local function setupNoFall()
    if NoFallMT then return end
    NoFallMT = getrawmetatable(game)
    if not NoFallMT then return end
    NoFallOrig = NoFallMT.__namecall
    setreadonly(NoFallMT, false)
    NoFallMT.__namecall = newcclosure(function(self, ...)
        if NoFallEnabled and FallRemote and self == FallRemote and getnamecallmethod() == "FireServer" then return nil end
        return NoFallOrig(self, ...)
    end)
    setreadonly(NoFallMT, true)
end
local function enableNoFall() NoFallEnabled = true; featureStates.NoFall = true; if not NoFallMT then setupNoFall() end end
local function disableNoFall() NoFallEnabled = false; featureStates.NoFall = false end

local lastInputTime, noSkillcheckEnabled, hookedMeta, origNamecall = tick(), false, false, nil
local function setupNoSkillcheck()
    if noSkillcheckEnabled then return end
    noSkillcheckEnabled = true
    local mt = getrawmetatable(game)
    if not mt then safeNotify("No Skillcheck", "Failed", 3) return end
    origNamecall = mt.__namecall
    local function onInput(a,s,i) if s == Enum.UserInputState.Begin then lastInputTime = tick() end end
    UserInputService.InputBegan:Connect(onInput); UserInputService.InputChanged:Connect(onInput)
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        if noSkillcheckEnabled and getnamecallmethod() == "FireServer" and tostring(self):lower():find("skill") then
            if tick() - lastInputTime > 2 then args[1] = "Great"; safeNotify("No Skillcheck", "Auto skillcheck!", 1) end
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
    if hookedMeta then local mt = getrawmetatable(game); if mt and origNamecall then setreadonly(mt, false); mt.__namecall = origNamecall; setreadonly(mt, true) end; hookedMeta = false end
    safeNotify("No Skillcheck", "Deactivated", 3)
end

local function setBypassGate(s)
    featureStates.BypassGate = s
    local function gatherGates() local g={}; local mainMap = Workspace:FindFirstChild("Map"); if mainMap then for _,f in pairs(mainMap:GetChildren()) do for _,ga in pairs(f:GetChildren()) do if ga.Name=="Gate" then table.insert(g,ga) end end end end; return g end
    for _,gate in pairs(gatherGates()) do
        local lg, rg = gate:FindFirstChild("LeftGate"), gate:FindFirstChild("RightGate")
        if lg then lg.Transparency = s and 1 or 0; lg.CanCollide = s and false or true end
        if rg then rg.Transparency = s and 1 or 0; rg.CanCollide = s and false or true end
    end
end

local autoLeverRunning = false
local function startAutoLever()
    autoLeverRunning = true
    task.spawn(function()
        local leverEvent = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Exit") and ReplicatedStorage.Remotes.Exit:FindFirstChild("LeverEvent")
        if not leverEvent then return end
        while autoLeverRunning and featureStates.AutoLever do
            local char = LP.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                for model, _ in pairs(worldReg.Gate) do
                    if model and alive(model) then
                        local exitLever = model:FindFirstChild("ExitLever")
                        if exitLever then local main = exitLever:FindFirstChild("Main"); if main and (root.Position - main.Position).Magnitude <= 10 then pcall(function() leverEvent:FireServer(main, true) end) end
                    end
                end
            end
            task.wait(2)
        end
    end)
end
local function stopAutoLever() autoLeverRunning = false end

-- ========== UTILITY FUNCTIONS ==========
local function alive(i) if not i then return false end local ok, _ = pcall(function() return i.Parent end); return ok and i.Parent ~= nil end
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

local function makeBillboard(text, color)
    local g = Instance.new("BillboardGui"); g.Name = "VD_Tag"; g.AlwaysOnTop = true; g.Size = UDim2.new(0,200,0,20); g.StudsOffset = Vector3.new(0,2.5,0)
    local l = Instance.new("TextLabel"); l.Name = "Label"; l.BackgroundTransparency = 1; l.Size = UDim2.new(1,0,1,0); l.Font = Enum.Font.GothamBold
    l.Text = text; l.TextSize = featureStates.ESPTextSize; l.TextColor3 = color or Color3.new(1,1,1); l.TextStrokeTransparency = 0.3; l.TextStrokeColor3 = Color3.new(0,0,0); l.Parent = g
    return g
end

local function makeColoredBillboard(pName, iText, pColor, iColor, dText)
    local g = Instance.new("BillboardGui"); g.Name = "VD_Tag"; g.AlwaysOnTop = true; g.Size = UDim2.new(0,200,0,20); g.StudsOffset = Vector3.new(0,2.5,0)
    local l = Instance.new("TextLabel"); l.Name = "Label"; l.BackgroundTransparency = 1; l.Size = UDim2.new(1,0,1,0); l.Font = Enum.Font.GothamBold
    l.TextSize = featureStates.ESPTextSize; l.TextStrokeTransparency = 0.3; l.TextStrokeColor3 = Color3.new(0,0,0)
    local full = (pName or "") .. (iText and iText ~= "" and (" "..iText) or "") .. (dText or "")
    l.Text = full; l.TextColor3 = (iText and iText~="") and iColor or pColor; l.Parent = g
    return g
end

local function ensureHighlight(model, fill, isPlayer)
    if not (model and model:IsA("Model") and alive(model)) then return end
    local hl = model:FindFirstChild("VD_HL")
    if not hl then hl = Instance.new("Highlight"); hl.Name = "VD_HL"; hl.Adornee = model; hl.Parent = model end
    hl.FillColor = fill; hl.OutlineColor = fill; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    if isPlayer then hl.FillTransparency = 0.9; hl.OutlineTransparency = 0.1
    else hl.FillTransparency = featureStates.ESPFillTransparency; hl.OutlineTransparency = featureStates.ESPOutlineTransparency end
end

local function clearHighlight(model) if model and model:FindFirstChild("VD_HL") then pcall(function() model.VD_HL:Destroy() end) end end

local displayNames = {["Parrying Dagger"]="Parrying Dagger", ["Motion Tracker"]="Motion Tracker", ["Gate"]="Gate", ["Flashlight"]="Flashlight", ["Bandage"]="Bandage", ["Adrenaline Shot"]="Adrenaline Shot", ["Shadow Clone"]="Shadow Clone"}

local function getRole(p)
    if p.Team then local tn = p.Team.Name:lower(); if tn:find("killer") then return "Killer" elseif tn:find("survivor") then return "Survivor" end end
    if p.TeamColor then local tc = p.TeamColor.Name:lower(); if tc:find("red") then return "Killer" elseif tc:find("blue") or tc:find("green") then return "Survivor" end end
    return "Survivor"
end

local function getSurvivorItem(pl)
    if not pl.Character then return nil end
    for _, obj in ipairs(pl.Character:GetDescendants()) do
        if (obj:IsA("Tool") or obj:IsA("Accessory")) and displayNames[obj.Name] then return "("..displayNames[obj.Name]..")" end
    end
    return nil
end

local function pickRep(model, cat)
    if not (model and alive(model)) then return nil end
    if cat == "Generator" then return model:FindFirstChild("HitBox", true) or firstBasePart(model)
    elseif cat == "Palletwrong" then return model:FindFirstChild("HumanoidRootPart", true) or firstBasePart(model)
    else return firstBasePart(model) end
end

local function genLabelData(model)
    local pct = tonumber(model:GetAttribute("RepairProgress")) or 0; if pct<=1 then pct = pct*100 end; pct = clamp(pct,0,100)
    local rep = tonumber(model:GetAttribute("PlayersRepairingCount")) or 0
    return "Gen "..math.floor(pct+0.5).."%"..(rep>0 and "("..rep.."p)" or ""), Color3.fromHSV(clamp(pct/100*0.33,0,0.33),1,1)
end

local function isPalletGone(m) return not (m and alive(m) and m:IsDescendantOf(Workspace) and m:FindFirstChildWhichIsA("BasePart",true)) end
local function ensureWorldEntry(cat, model)
    if not alive(model) or worldReg[cat][model] then return end
    if cat=="Palletwrong" and isPalletGone(model) then return end
    local rep = pickRep(model, cat); if not validPart(rep) then return end
    worldReg[cat][model] = {part=rep}
end
local function removeWorldEntry(cat, model) local e=worldReg[cat][model]; if e then if e.part then local c = e.part:FindFirstChild("VD_Text_"..cat); if c then pcall(function() c:Destroy() end) end end; worldReg[cat][model]=nil end end
local function anyWorldEnabled() return featureStates.GeneratorESP or featureStates.HookESP or featureStates.GateESP or featureStates.WindowESP or featureStates.PalletESP end

local function refreshRoots()
    for _,cn in pairs(mapAdd) do if cn then cn:Disconnect() end end
    for _,cn in pairs(mapRem) do if cn then cn:Disconnect() end end
    mapAdd, mapRem = {}, {}
    local r1 = Workspace:FindFirstChild("Map")
    local r2 = Workspace:FindFirstChild("Map1")
    if r1 then
        mapAdd[r1] = r1.DescendantAdded:Connect(registerFromDescendant)
        mapRem[r1] = r1.DescendantRemoving:Connect(unregisterFromDescendant)
        for _,d in ipairs(r1:GetDescendants()) do registerFromDescendant(d) end
    end
    if r2 then
        mapAdd[r2] = r2.DescendantAdded:Connect(registerFromDescendant)
        mapRem[r2] = r2.DescendantRemoving:Connect(unregisterFromDescendant)
        for _,d in ipairs(r2:GetDescendants()) do registerFromDescendant(d) end
    end
end

local function registerFromDescendant(obj)
    if not alive(obj) then return end
    if obj:IsA("Model") then
        local validCats = {Generator=true, Hook=true, Gate=true, Window=true, Palletwrong=true}
        if validCats[obj.Name] then ensureWorldEntry(obj.Name, obj); return end
    end
    if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") then
        local validCats = {Generator=true, Hook=true, Gate=true, Window=true, Palletwrong=true}
        if validCats[obj.Parent.Name] then ensureWorldEntry(obj.Parent.Name, obj.Parent) end
    end
end

local function unregisterFromDescendant(obj)
    if not obj then return end
    if obj:IsA("Model") then
        local validCats = {Generator=true, Hook=true, Gate=true, Window=true, Palletwrong=true}
        if validCats[obj.Name] then removeWorldEntry(obj.Name, obj); return end
    end
    if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") then
        local validCats = {Generator=true, Hook=true, Gate=true, Window=true, Palletwrong=true}
        if validCats[obj.Parent.Name] then
            local e = worldReg[obj.Parent.Name][obj.Parent]
            if e and e.part == obj then removeWorldEntry(obj.Parent.Name, obj.Parent) end
        end
    end
end

local function startWorldLoop()
    if worldThread then return end
    worldThread = task.spawn(function()
        while anyWorldEnabled() do
            for cat,models in pairs(worldReg) do
                local en, col = false, featureStates.GeneratorColor
                if cat=="Generator" then en=featureStates.GeneratorESP; col=featureStates.GeneratorColor
                elseif cat=="Hook" then en=featureStates.HookESP; col=featureStates.HookColor
                elseif cat=="Gate" then en=featureStates.GateESP; col=featureStates.GateColor
                elseif cat=="Window" then en=featureStates.WindowESP; col=featureStates.WindowColor
                elseif cat=="Palletwrong" then en=featureStates.PalletESP; col=featureStates.PalletColor end
                if en then
                    for model,entry in pairs(models) do
                        if cat=="Palletwrong" and isPalletGone(model) then removeWorldEntry(cat,model)
                        else
                            local part = entry.part
                            if model and alive(model) then
                                if not validPart(part) then entry.part = pickRep(model,cat); part=entry.part end
                                if validPart(part) then
                                    ensureHighlight(model,col,false)
                                    local bb = part:FindFirstChild("VD_Text_"..cat)
                                    if not bb then
                                        local disp = cat=="Palletwrong" and "Pallet" or cat
                                        bb = makeBillboard(disp,col); bb.Name="VD_Text_"..cat; bb.Adornee=part; bb.Parent=part
                                    end
                                    local lbl = bb:FindFirstChild("Label")
                                    if lbl then
                                        lbl.TextSize = featureStates.ESPTextSize
                                        if cat=="Generator" then local txt,lc=genLabelData(model); lbl.Text=txt; lbl.TextColor3=lc
                                        elseif cat=="Palletwrong" then lbl.Text="Pallet"; lbl.TextColor3=col
                                        else lbl.Text=cat; lbl.TextColor3=col end
                                    end
                                end
                            else removeWorldEntry(cat,model) end
                        end
                        task.wait()
                    end
                else
                    for model,_ in pairs(models) do if model and alive(model) then clearHighlight(model) end end
                end
            end
            task.wait(0.25)
        end
        worldThread=nil
    end)
end

-- ========== ESP SYSTEMS ==========
local function applyPlayerESP(p)
    if p == LP then return end
    local c = p.Character; if not (c and alive(c)) then return end
    local role = getRole(p); clearHighlight(c)
    local head = c:FindFirstChild("Head")
    if head then local t = head:FindFirstChild("VD_Tag"); if t then pcall(function() t:Destroy() end) end end
    local distText = ""
    if featureStates.DistanceESP and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("HumanoidRootPart") then
        distText = "[" .. math.floor((LP.Character.HumanoidRootPart.Position - c.HumanoidRootPart.Position).Magnitude) .. "m]"
    end
    if role == "Survivor" and featureStates.SurvivorESP then
        ensureHighlight(c, featureStates.SurvivorColor, true)
        if (featureStates.Nametags or featureStates.DistanceESP or featureStates.SurvivorItemsESP) and head then
            local name = featureStates.Nametags and p.Name or ""
            local item = featureStates.SurvivorItemsESP and getSurvivorItem(p) or ""
            local tag = makeColoredBillboard(name, item, featureStates.SurvivorColor, featureStates.SurvivorItemsColor, distText)
            tag.Name = "VD_Tag"; tag.Adornee = head; tag.Parent = head
        end
    elseif role == "Killer" and featureStates.KillerESP then
        ensureHighlight(c, featureStates.KillerColor, true)
        if (featureStates.Nametags or featureStates.DistanceESP) and head then
            local display = (featureStates.Nametags and "Killer " or "") .. distText
            local tag = makeBillboard(display, featureStates.KillerColor)
            tag.Name = "VD_Tag"; tag.Adornee = head; tag.Parent = head
        end
    end
end

local function watchPlayer(p)
    if playerConns[p] then for _,cn in ipairs(playerConns[p]) do cn:Disconnect() end end
    playerConns[p] = {}
    table.insert(playerConns[p], p.CharacterAdded:Connect(function() task.delay(0.15, function() applyPlayerESP(p) end) end))
    table.insert(playerConns[p], p:GetPropertyChangedSignal("Team"):Connect(function() applyPlayerESP(p) end))
    if p.Character then applyPlayerESP(p) end
end

local function unwatchPlayer(p)
    if p.Character then clearHighlight(p.Character); local h = p.Character:FindFirstChild("Head"); if h and h:FindFirstChild("VD_Tag") then pcall(function() h.VD_Tag:Destroy() end) end end
    if playerConns[p] then for _,cn in ipairs(playerConns[p]) do cn:Disconnect() end end; playerConns[p] = nil
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
local function startDistUpdate() if distThread then return end; distThread = task.spawn(function() while featureStates.DistanceESP do updateDistanceDisplay(); task.wait(0.2) end; distThread = nil end) end
local function stopDistUpdate() distThread = nil; for _,pl in ipairs(Players:GetPlayers()) do if pl ~= LP and pl.Character then local h = pl.Character:FindFirstChild("Head"); if h then local t = h:FindFirstChild("VD_Tag"); if t and t:FindFirstChild("Label") then t.Label.Text = t.Label.Text:gsub(" %[%d+m%]", "") end end end end end

-- ========== CREATE UI ==========
local Window = WindUI:CreateWindow({
    Title = "KyelHub - Violence District", Author = "Kyel Hub",
    Folder = "KyelHub", Theme = "KyelHub", Size = UDim2.fromOffset(550, 450),
    SideBarWidth = 150, ScrollBarEnabled = true,
})

local PlayerTab = Window:Tab({ Title = "Players", Icon = "user" })
local SurvivorTab = Window:Tab({ Title = "Survivor", Icon = "users" })
local KillerTab = Window:Tab({ Title = "Killer", Icon = "crosshair" })
local ESPTab = Window:Tab({ Title = "ESP", Icon = "eye" })
local WorldTab = Window:Tab({ Title = "World", Icon = "globe" })
local VisualTab = Window:Tab({ Title = "Visual", Icon = "sparkles" })
local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "compass" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- Player Tab
local Movement = PlayerTab:Section({ Title = "Movement", Opened = true })
Movement:Toggle({ Title = "Walk Speed", Default = false, Callback = function(s) featureStates.WalkSpeed = s; if s then if speedHumanoid then setWalkSpeed(speedHumanoid, featureStates.WalkSpeedValue); bindSpeedLoop() end else unbindSpeedLoop(); if speedHumanoid then setWalkSpeed(speedHumanoid, 16) end end end })
Movement:Slider({ Title = "Walk Speed Value", Step = 1, Value = {Min=0,Max=200,Default=16}, Callback = function(v) featureStates.WalkSpeedValue = v; if featureStates.WalkSpeed and speedHumanoid then setWalkSpeed(speedHumanoid, v) end end })
Movement:Toggle({ Title = "Noclip", Default = false, Callback = function(s) featureStates.Noclip = s; setNoclip(s) end })
Movement:Toggle({ Title = "God Mode", Default = false, Callback = function(s) featureStates.GodMode = s; if s then enableGodMode() else disableGodMode() end end })
Movement:Toggle({ Title = "MoonWalk", Default = false, Callback = function(s) toggleMoonwalk(s) end })

local Utility = PlayerTab:Section({ Title = "Utilities", Opened = false })
Utility:Toggle({ Title = "Anti AFK", Default = false, Callback = function(s) featureStates.AntiAFK = s; if s then startAntiAFK() else stopAntiAFK() end end })
Utility:Toggle({ Title = "No Fall", Default = false, Callback = function(s) if s then enableNoFall() else disableNoFall() end end })
Utility:Toggle({ Title = "Anti Stun", Default = false, Callback = function(s) toggleAntiStun(s) end })

-- Survivor Tab
local SurvivorMain = SurvivorTab:Section({ Title = "Survivor Main", Opened = true })
SurvivorMain:Toggle({ Title = "⚔️ Auto Parry ⚔️", Default = false, Callback = toggleAutoParry })
SurvivorMain:Slider({ Title = "Parry Range", Step = 0.5, Value = {Min=3,Max=20,Default=10}, Callback = function(v) featureStates.ParryRange = v end })
SurvivorMain:Slider({ Title = "Parry Cooldown (detik)", Step = 0.1, Value = {Min=0.2,Max=2,Default=0.5}, Callback = function(v) featureStates.ParryCooldown = v end })

local GenSection = SurvivorTab:Section({ Title = "Auto Generator", Opened = true })
GenSection:Toggle({ Title = "Auto Generator", Default = false, Callback = toggleAutoGen })
GenSection:Dropdown({ Title = "Generator Quality", Options = {"Normal", "Instant", "Perfect"}, Default = "Perfect", Callback = function(v) setGenQuality(v) end })

local OtherSection = SurvivorTab:Section({ Title = "Other Features", Opened = false })
OtherSection:Toggle({ Title = "Auto Lever", Default = false, Callback = function(s) featureStates.AutoLever = s; if s then startAutoLever() else stopAutoLever() end end })
OtherSection:Toggle({ Title = "No Skillcheck", Default = false, Callback = function(s) featureStates.NoSkillcheck = s; if s then setupNoSkillcheck() else disableNoSkillcheck() end end })
OtherSection:Toggle({ Title = "Bypass Gate", Default = false, Callback = function(s) setBypassGate(s) end })

-- Killer Tab
local KillerMain = KillerTab:Section({ Title = "Killer Utilities", Opened = true })
KillerMain:Toggle({ Title = "ESP Semua Survivor", Default = false, Callback = function(s)
    featureStates.SurvivorESP = s
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP and getRole(p)=="Survivor" then applyPlayerESP(p) end end
end })
KillerMain:Button({ Title = "Teleport ke Survivor Terdekat", Callback = function()
    local nearest, nearestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and getRole(p) == "Survivor" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < nearestDist then nearestDist = dist; nearest = p end
        end
    end
    if nearest then LP.Character.HumanoidRootPart.CFrame = nearest.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0); safeNotify("Teleport", "Teleported to "..nearest.Name,2)
    else safeNotify("Teleport", "No survivor found!",2) end
end })

-- ESP Tab
local ESPSet = ESPTab:Section({ Title = "ESP Settings", Opened = true })
ESPSet:Slider({ Title = "ESP Fill Transparency", Step = 0.05, Value = {Min=0,Max=1,Default=0.7}, Callback = function(v) featureStates.ESPFillTransparency = v; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then applyPlayerESP(p) end end end })
ESPSet:Slider({ Title = "ESP Outline Transparency", Step = 0.05, Value = {Min=0,Max=1,Default=0}, Callback = function(v) featureStates.ESPOutlineTransparency = v; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then applyPlayerESP(p) end end end })
ESPSet:Slider({ Title = "ESP Text Size", Step = 1, Value = {Min=8,Max=20,Default=14}, Callback = function(v) featureStates.ESPTextSize = v; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then applyPlayerESP(p) end end end })

local PlayerESP = ESPTab:Section({ Title = "Player ESP", Opened = true })
PlayerESP:Toggle({ Title = "Survivor ESP", Default = false, Callback = function(s) featureStates.SurvivorESP = s; for _,p in ipairs(Players:GetPlayers()) do if p~=LP and getRole(p)=="Survivor" then applyPlayerESP(p) end end end })
PlayerESP:Toggle({ Title = "Killer ESP", Default = false, Callback = function(s) featureStates.KillerESP = s; for _,p in ipairs(Players:GetPlayers()) do if p~=LP and getRole(p)=="Killer" then applyPlayerESP(p) end end end })
PlayerESP:Toggle({ Title = "Zombie ESP", Desc = "ESP untuk TheCure / Zombie", Default = false, Callback = toggleZombieESP })
PlayerESP:Toggle({ Title = "Nametags", Default = false, Callback = function(s) featureStates.Nametags = s; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then applyPlayerESP(p) end end end })
PlayerESP:Toggle({ Title = "Distance ESP", Default = false, Callback = function(s) featureStates.DistanceESP = s; if s then startDistUpdate() else stopDistUpdate() end; for _,p in ipairs(Players:GetPlayers()) do if p~=LP then applyPlayerESP(p) end end end })
PlayerESP:Toggle({ Title = "Survivor Items ESP", Default = false, Callback = function(s) featureStates.SurvivorItemsESP = s; for _,p in ipairs(Players:GetPlayers()) do if p~=LP and getRole(p)=="Survivor" then applyPlayerESP(p) end end end })
PlayerESP:Colorpicker({ Title = "Survivor Color", Default = featureStates.SurvivorColor, Callback = function(c) featureStates.SurvivorColor = c; for _,p in ipairs(Players:GetPlayers()) do if p~=LP and getRole(p)=="Survivor" and featureStates.SurvivorESP then applyPlayerESP(p) end end end })
PlayerESP:Colorpicker({ Title = "Killer Color", Default = featureStates.KillerColor, Callback = function(c) featureStates.KillerColor = c; for _,p in ipairs(Players:GetPlayers()) do if p~=LP and getRole(p)=="Killer" and featureStates.KillerESP then applyPlayerESP(p) end end end })
PlayerESP:Colorpicker({ Title = "Zombie Color", Default = featureStates.ZombieColor, Callback = function(c) featureStates.ZombieColor = c; if featureStates.ZombieESP then scanZombies() end end })
PlayerESP:Colorpicker({ Title = "Survivor Items Color", Default = featureStates.SurvivorItemsColor, Callback = function(c) featureStates.SurvivorItemsColor = c; for _,p in ipairs(Players:GetPlayers()) do if p~=LP and getRole(p)=="Survivor" and featureStates.SurvivorESP and featureStates.SurvivorItemsESP then applyPlayerESP(p) end end end })

-- World Tab
local WorldTog = WorldTab:Section({ Title = "World ESP Toggles", Opened = true })
WorldTog:Toggle({ Title = "Generators", Default = false, Callback = function(s) featureStates.GeneratorESP = s; if s and not worldThread then startWorldLoop() end end })
WorldTog:Toggle({ Title = "Hooks", Default = false, Callback = function(s) featureStates.HookESP = s; if s and not worldThread then startWorldLoop() end end })
WorldTog:Toggle({ Title = "Gates", Default = false, Callback = function(s) featureStates.GateESP = s; if s and not worldThread then startWorldLoop() end end })
WorldTog:Toggle({ Title = "Windows", Default = false, Callback = function(s) featureStates.WindowESP = s; if s and not worldThread then startWorldLoop() end end })
WorldTog:Toggle({ Title = "Pallets", Default = false, Callback = function(s) featureStates.PalletESP = s; if s and not worldThread then startWorldLoop() end end })

local WorldCol = WorldTab:Section({ Title = "World ESP Colors", Opened = false })
WorldCol:Colorpicker({ Title = "Generator Color", Default = featureStates.GeneratorColor, Callback = function(c) featureStates.GeneratorColor = c end })
WorldCol:Colorpicker({ Title = "Hook Color", Default = featureStates.HookColor, Callback = function(c) featureStates.HookColor = c end })
WorldCol:Colorpicker({ Title = "Gate Color", Default = featureStates.GateColor, Callback = function(c) featureStates.GateColor = c end })
WorldCol:Colorpicker({ Title = "Window Color", Default = featureStates.WindowColor, Callback = function(c) featureStates.WindowColor = c end })
WorldCol:Colorpicker({ Title = "Pallet Color", Default = featureStates.PalletColor, Callback = function(c) featureStates.PalletColor = c end })

-- Visual Tab
local VisualSec = VisualTab:Section({ Title = "Visual Enhancements", Opened = true })
VisualSec:Toggle({ Title = "FullBright", Default = false, Callback = function(s) toggleFullBright(s) end })
VisualSec:Toggle({ Title = "No Fog", Default = false, Callback = function(s) toggleNoFog(s) end })
VisualSec:Toggle({ Title = "Custom Time of Day", Default = false, Callback = function(s) setTimeOfDay(s) end })
VisualSec:Slider({ Title = "Time of Day Value", Step = 1, Value = {Min=0,Max=24,Default=14}, Callback = function(v) updateTimeOfDay(v) end })

-- Teleport Tab
local TeleportSec = TeleportTab:Section({ Title = "Teleport Locations", Opened = true })
TeleportSec:Button({ Title = "Teleport ke Generator Terdekat", Callback = function()
    local nearest, nearestDist = nil, math.huge
    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and model.Name == "Generator" then
            local part = model:FindFirstChild("HitBox") or model:FindFirstChildWhichIsA("BasePart")
            if part and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (LP.Character.HumanoidRootPart.Position - part.Position).Magnitude
                if dist < nearestDist then nearestDist = dist; nearest = part end
            end
        end
    end
    if nearest then LP.Character.HumanoidRootPart.CFrame = nearest.CFrame + Vector3.new(0,3,0); safeNotify("Teleport", "Teleported to generator",2) end
end })
TeleportSec:Button({ Title = "Teleport ke Gate Terdekat", Callback = function()
    local nearest, nearestDist = nil, math.huge
    for _, gate in ipairs(Workspace:GetDescendants()) do
        if gate.Name == "Gate" then
            local part = gate:FindFirstChild("LeftGate") or gate:FindFirstChild("RightGate") or gate:FindFirstChildWhichIsA("BasePart")
            if part and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (LP.Character.HumanoidRootPart.Position - part.Position).Magnitude
                if dist < nearestDist then nearestDist = dist; nearest = part end
            end
        end
    end
    if nearest then LP.Character.HumanoidRootPart.CFrame = nearest.CFrame + Vector3.new(0,3,0); safeNotify("Teleport", "Teleported to gate",2) end
end })
TeleportSec:Button({ Title = "Teleport ke Hook Terdekat", Callback = function()
    local nearest, nearestDist = nil, math.huge
    for _, hook in ipairs(Workspace:GetDescendants()) do
        if hook.Name == "Hook" then
            local part = hook:FindFirstChildWhichIsA("BasePart")
            if part and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (LP.Character.HumanoidRootPart.Position - part.Position).Magnitude
                if dist < nearestDist then nearestDist = dist; nearest = part end
            end
        end
    end
    if nearest then LP.Character.HumanoidRootPart.CFrame = nearest.CFrame + Vector3.new(0,3,0); safeNotify("Teleport", "Teleported to hook",2) end
end })

-- Settings Tab
local SettingsSec = SettingsTab:Section({ Title = "Configuration", Opened = true })
SettingsSec:Button({ Title = "Save Configuration", Callback = function() local cfg = Window.ConfigManager:Config("violence"); cfg:Save(); safeNotify("Settings", "Configuration saved!", 2) end })
SettingsSec:Button({ Title = "Load Configuration", Callback = function() local cfg = Window.ConfigManager:Config("violence"); cfg:Load(); safeNotify("Settings", "Configuration loaded!", 2) end })

-- Initialize
if LP.Character then onCharacterAdded(LP.Character) end
LP.CharacterAdded:Connect(onCharacterAdded)
for _,p in ipairs(Players:GetPlayers()) do if p~=LP then watchPlayer(p) end end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(unwatchPlayer)

refreshRoots()
Workspace.ChildAdded:Connect(function(ch) if ch.Name=="Map" or ch.Name=="Map1" then attachRoot(ch) end end)
if anyWorldEnabled() then startWorldLoop() end
setupNoFall()

local MyConfig = Window.ConfigManager:Config("violence")
MyConfig:Load()

task.spawn(function() task.wait(3); safeNotify("KyelHub - Violence District", "Successfully loaded! Enjoy the features.", 6) end)

Window:SelectTab(1)
Window:UnlockAll()
Window:Open()

-- Aimbot with Flexible FOV Settings for Players and Bots/AI
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration
local AimSmoothness = 0.15
local ToggleKey = Enum.KeyCode.O
local ShowESP = true
local TracerColor = Color3.fromRGB(255, 50, 50)
local BotTracerColor = Color3.fromRGB(255, 150, 50)
local TracerThickness = 1
local MaxTracers = 15
local TargetBots = true
local AimFOV = 30 -- FOV for aiming restriction
local VisualFOV = 100 -- FOV for visual tracer display

-- States
local AimLockActive = false
local LockedTarget = nil
local AimbotEnabled = true

-- Store all tracers
local Tracers = {}

-- Initialize tracers
for i = 1, MaxTracers do
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = TracerColor
    tracer.Thickness = TracerThickness
    tracer.ZIndex = 1
    Tracers[i] = tracer
end

-- Function to check if a character is a bot/AI
local function IsAI(character)
    -- Check for common AI indicators
    if not character then return false end
    if character:FindFirstChild("IsNPC") then return true end
    if character:FindFirstChild("IsBot") then return true end
    if character.Name:match("[Bb]ot$") then return true end
    if character.Name:match("[Aa][Ii]$") then return true end
    if character.Name:match("[Nn][Pp][Cc]$") then return true end
    
    -- Check if it's not a player character
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == character then
            return false
        end
    end
    return true
end

-- Calculate angle between vectors
local function GetAngleBetweenVectors(a, b)
    return math.deg(math.acos(a:Dot(b)))
end

-- Get all potential targets (players and AI)
local function GetAllTargets()
    local targets = {}
    local cameraPos = Camera.CFrame.Position
    
    -- Add players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoidRootPart and head then
                table.insert(targets, {
                    object = player.Character,
                    head = head,
                    isAI = false
                })
            end
        end
    end
    
    -- Add AI if enabled
    if TargetBots then
        for _, model in ipairs(workspace:GetDescendants()) do
            if model:IsA("Model") and model ~= LocalPlayer.Character and IsAI(model) then
                local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")
                local head = model:FindFirstChild("Head")
                
                if humanoidRootPart and head then
                    table.insert(targets, {
                        object = model,
                        head = head,
                        isAI = true
                    })
                end
            end
        end
    end
    
    return targets
end

-- Find best target within AimFOV
local function GetBestTargetInFOV()
    if not AimbotEnabled then return nil end
    
    local bestTarget, closestAngle = nil, AimFOV / 2
    local cameraPos = Camera.CFrame.Position
    local cameraLook = Camera.CFrame.LookVector
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, target in ipairs(GetAllTargets()) do
        local direction = (target.head.Position - cameraPos).Unit
        local angle = GetAngleBetweenVectors(cameraLook, direction)
        local screenPoint, onScreen = Camera:WorldToViewportPoint(target.head.Position)
        
        if onScreen and angle <= closestAngle then
            closestAngle = angle
            bestTarget = target
        end
    end
    
    return bestTarget
end

-- Get all visible targets for tracers (within VisualFOV)
local function GetVisibleTargetsForTracers()
    local visibleTargets = {}
    local cameraPos = Camera.CFrame.Position
    local cameraLook = Camera.CFrame.LookVector
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, target in ipairs(GetAllTargets()) do
        local direction = (target.head.Position - cameraPos).Unit
        local angle = GetAngleBetweenVectors(cameraLook, direction)
        local screenPoint, onScreen = Camera:WorldToViewportPoint(target.head.Position)
        
        if onScreen and angle <= VisualFOV / 2 then
            table.insert(visibleTargets, {
                target = target.object,
                head = target.head,
                position = Vector2.new(screenPoint.X, screenPoint.Y),
                distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude,
                isAI = target.isAI,
                angle = angle
            })
        end
    end
    
    -- Sort by angle (closest to crosshair first)
    table.sort(visibleTargets, function(a, b) return a.angle < b.angle end)
    
    return visibleTargets
end

-- Aiming function with FOV restriction
local function AimAt(target)
    if not AimbotEnabled or not target or not target.head then return end
    
    local cameraPos = Camera.CFrame.Position
    local cameraLook = Camera.CFrame.LookVector
    local direction = (target.head.Position - cameraPos).Unit
    local angle = GetAngleBetweenVectors(cameraLook, direction)
    
    -- Strict FOV check before aiming
    if angle > AimFOV / 2 then return end
    
    local screenPoint, onScreen = Camera:WorldToViewportPoint(target.head.Position)
    if not onScreen then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(screenPoint.X, screenPoint.Y)
    local moveTo = mousePos:Lerp(targetPos, AimSmoothness)
    
    mousemoverel(moveTo.X - mousePos.X, moveTo.Y - mousePos.Y)
end

-- Update all tracers (shows targets within VisualFOV)
local function UpdateTracers()
    if not ShowESP or not AimbotEnabled then
        for _, tracer in ipairs(Tracers) do
            tracer.Visible = false
        end
        return
    end
    
    local visibleTargets = GetVisibleTargetsForTracers()
    local mousePos = UserInputService:GetMouseLocation()
    
    -- Hide all tracers first
    for _, tracer in ipairs(Tracers) do
        tracer.Visible = false
    end
    
    -- Update visible tracers
    for i, targetInfo in ipairs(visibleTargets) do
        if i > MaxTracers then break end
        
        Tracers[i].From = mousePos
        Tracers[i].To = targetInfo.position
        Tracers[i].Visible = true
        
        -- Set color based on target type
        if targetInfo.isAI then
            Tracers[i].Color = BotTracerColor
        else
            Tracers[i].Color = TracerColor
        end
        
        -- Highlight locked target
        if LockedTarget and LockedTarget == targetInfo.target then
            Tracers[i].Color = Color3.fromRGB(0, 255, 0)
            Tracers[i].Thickness = 2
        else
            Tracers[i].Thickness = TracerThickness
        end
        
        -- Dim targets outside aim FOV
        if targetInfo.angle > AimFOV / 2 then
            Tracers[i].Transparency = 0.7
        else
            Tracers[i].Transparency = 0
        end
    end
end

-- Main loop
RunService.RenderStepped:Connect(function()
    UpdateTracers()
    
    if not AimbotEnabled then return end
    
    if AimLockActive then
        if not LockedTarget or not LockedTarget.Parent or not LockedTarget:FindFirstChild("Head") then
            local target = GetBestTargetInFOV()
            if target then
                LockedTarget = target.object
            end
        end
        
        if LockedTarget then
            local targetData
            for _, t in ipairs(GetAllTargets()) do
                if t.object == LockedTarget then
                    targetData = t
                    break
                end
            end
            if targetData then
                AimAt(targetData)
            end
        end
    end
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and AimbotEnabled then
        AimLockActive = true
        local target = GetBestTargetInFOV()
        if target then
            LockedTarget = target.object
        end
    end
    
    if input.KeyCode == ToggleKey then
        AimbotEnabled = not AimbotEnabled
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Aimbot",
            Text = AimbotEnabled and string.format("ENABLED (%d° Aim FOV)", AimFOV) or "DISABLED",
            Duration = 2
        })
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        AimLockActive = false
        LockedTarget = nil
    end
end)

-- Cleanup
game:BindToClose(function()
    for _, tracer in ipairs(Tracers) do
        tracer:Remove()
    end
end)

-- Initial notification
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Advanced Aimbot Loaded",
    Text = string.format("%d° Aim FOV | %d° Visual FOV\nTargets: %s\nHold LMB to lock aim", 
                         AimFOV, VisualFOV, 
                         TargetBots and "Players + AI" or "Players Only"),
    Duration = 5
})

print(string.format("Aimbot initialized with %d° aim FOV and %d° visual FOV", AimFOV, VisualFOV))

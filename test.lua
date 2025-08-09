-- Aimbot for Players and Bots with Multi-Tracer
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration
local AimSmoothness = 1.0
local ToggleKey = Enum.KeyCode.O
local ShowESP = true
local TracerColor = Color3.fromRGB(255, 50, 50)
local BotTracerColor = Color3.fromRGB(255, 150, 50) -- Different color for bots
local TracerThickness = 1
local MaxTracers = 99
local TargetBots = true -- Set to false to ignore bots

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

-- Function to check if a character is a bot
local function IsBot(character)
    -- Add your bot detection logic here
    -- Example: Check for NPC tag or specific naming convention
    if character:FindFirstChild("IsBot") then return true end
    if character.Name:match("Bot$") or character.Name:match("NPC$") then return true end
    return false
end

-- Target finding (all visible enemies including bots)
local function GetVisibleTargets()
    if not AimbotEnabled then return {} end
    
    local visibleTargets = {}
    local mousePos = UserInputService:GetMouseLocation()
    
    -- Check players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoidRootPart and head then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    table.insert(visibleTargets, {
                        target = player.Character,
                        position = Vector2.new(screenPoint.X, screenPoint.Y),
                        distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude,
                        isBot = false
                    })
                end
            end
        end
    end
    
    -- Check bots if enabled
    if TargetBots then
        for _, npc in ipairs(workspace:GetChildren()) do
            if npc:IsA("Model") and npc ~= LocalPlayer.Character and IsBot(npc) then
                local humanoidRootPart = npc:FindFirstChild("HumanoidRootPart")
                local head = npc:FindFirstChild("Head")
                
                if humanoidRootPart and head then
                    local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        table.insert(visibleTargets, {
                            target = npc,
                            position = Vector2.new(screenPoint.X, screenPoint.Y),
                            distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude,
                            isBot = true
                        })
                    end
                end
            end
        end
    end
    
    -- Sort by distance to mouse
    table.sort(visibleTargets, function(a, b) return a.distance < b.distance end)
    
    return visibleTargets
end

-- Aiming function
local function AimAt(target)
    if not AimbotEnabled or not target or not target:FindFirstChild("Head") then return end
    
    local head = target:FindFirstChild("Head")
    local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(screenPoint.X, screenPoint.Y)
    local moveTo = mousePos:Lerp(targetPos, AimSmoothness)
    
    mousemoverel(moveTo.X - mousePos.X, moveTo.Y - mousePos.Y)
end

-- Update all tracers
local function UpdateTracers()
    if not ShowESP or not AimbotEnabled then
        for _, tracer in ipairs(Tracers) do
            tracer.Visible = false
        end
        return
    end
    
    local visibleTargets = GetVisibleTargets()
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
        if targetInfo.isBot then
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
    end
end

-- Main loop
RunService.RenderStepped:Connect(function()
    UpdateTracers()
    
    if not AimbotEnabled then return end
    
    if AimLockActive then
        if not LockedTarget or not LockedTarget.Parent or not LockedTarget:FindFirstChild("Head") then
            local targets = GetVisibleTargets()
            if #targets > 0 then
                LockedTarget = targets[1].target -- Lock closest target
            end
        end
        
        if LockedTarget then
            AimAt(LockedTarget)
        end
    end
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and AimbotEnabled then
        AimLockActive = true
        local targets = GetVisibleTargets()
        if #targets > 0 then
            LockedTarget = targets[1].target -- Lock closest target
        end
    end
    
    if input.KeyCode == ToggleKey then
        AimbotEnabled = not AimbotEnabled
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Aimbot",
            Text = AimbotEnabled and "ENABLED" or "DISABLED",
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

-- Cleanup on script termination
game:BindToClose(function()
    for _, tracer in ipairs(Tracers) do
        tracer:Remove()
    end
end)

-- Initial notification
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Universal Aimbot Loaded",
    Text = string.format("Targets: %s\nHold LMB to lock aim\nPress O to toggle", 
                         TargetBots and "Players + Bots" or "Players Only"),
    Duration = 5
})

print("Universal Aimbot initialized - Targeting players and bots")

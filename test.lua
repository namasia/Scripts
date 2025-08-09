-- Aimbot with 30 FOV Restriction for Players and Bots
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
local BotTracerColor = Color3.fromRGB(255, 150, 50)
local TracerThickness = 1
local MaxTracers = 15
local TargetBots = true
local MaxFOV = 30 -- Strict 30 degree FOV limit

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
    if character:FindFirstChild("IsBot") then return true end
    if character.Name:match("Bot$") or character.Name:match("NPC$") then return true end
    return false
end

-- Calculate angle between vectors
local function GetAngleBetweenVectors(a, b)
    return math.deg(math.acos(a:Dot(b)))
end

-- Target finding with strict 30 FOV limit
local function GetTargetsInFOV()
    if not AimbotEnabled then return {} end
    
    local targetsInFOV = {}
    local mousePos = UserInputService:GetMouseLocation()
    local cameraPos = Camera.CFrame.Position
    local cameraLook = Camera.CFrame.LookVector
    
    -- Check players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoidRootPart and head then
                local direction = (head.Position - cameraPos).Unit
                local angle = GetAngleBetweenVectors(cameraLook, direction)
                local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                
                if onScreen and angle <= MaxFOV/2 then
                    table.insert(targetsInFOV, {
                        target = player.Character,
                        position = Vector2.new(screenPoint.X, screenPoint.Y),
                        distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude,
                        isBot = false,
                        angle = angle
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
                    local direction = (head.Position - cameraPos).Unit
                    local angle = GetAngleBetweenVectors(cameraLook, direction)
                    local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                    
                    if onScreen and angle <= MaxFOV/2 then
                        table.insert(targetsInFOV, {
                            target = npc,
                            position = Vector2.new(screenPoint.X, screenPoint.Y),
                            distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude,
                            isBot = true,
                            angle = angle
                        })
                    end
                end
            end
        end
    end
    
    -- Sort by angle (closest to crosshair first)
    table.sort(targetsInFOV, function(a, b) return a.angle < b.angle end)
    
    return targetsInFOV
end

-- Aiming function with FOV check
local function AimAt(target)
    if not AimbotEnabled or not target or not target:FindFirstChild("Head") then return end
    
    local head = target:FindFirstChild("Head")
    local cameraPos = Camera.CFrame.Position
    local cameraLook = Camera.CFrame.LookVector
    local direction = (head.Position - cameraPos).Unit
    local angle = GetAngleBetweenVectors(cameraLook, direction)
    
    -- Strict FOV check before aiming
    if angle > MaxFOV/2 then return end
    
    local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(screenPoint.X, screenPoint.Y)
    local moveTo = mousePos:Lerp(targetPos, AimSmoothness)
    
    mousemoverel(moveTo.X - mousePos.X, moveTo.Y - mousePos.Y)
end

-- Update all tracers (only show targets in FOV)
local function UpdateTracers()
    if not ShowESP or not AimbotEnabled then
        for _, tracer in ipairs(Tracers) do
            tracer.Visible = false
        end
        return
    end
    
    local targetsInFOV = GetTargetsInFOV()
    local mousePos = UserInputService:GetMouseLocation()
    
    -- Hide all tracers first
    for _, tracer in ipairs(Tracers) do
        tracer.Visible = false
    end
    
    -- Update visible tracers
    for i, targetInfo in ipairs(targetsInFOV) do
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
            local targets = GetTargetsInFOV()
            if #targets > 0 then
                LockedTarget = targets[1].target -- Lock closest target to crosshair
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
        local targets = GetTargetsInFOV()
        if #targets > 0 then
            LockedTarget = targets[1].target -- Lock closest target to crosshair
        end
    end
    
    if input.KeyCode == ToggleKey then
        AimbotEnabled = not AimbotEnabled
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Aimbot",
            Text = AimbotEnabled and string.format("ENABLED (%d° FOV)", MaxFOV) or "DISABLED",
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
    Title = "Strict FOV Aimbot Loaded",
    Text = string.format("%d° FOV Restriction\nTargets: %s\nHold LMB to lock aim", 
                         MaxFOV, TargetBots and "Players + Bots" or "Players Only"),
    Duration = 5
})

print(string.format("Aimbot initialized with strict %d° FOV restriction", MaxFOV))

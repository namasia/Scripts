-- Aimbot with Always-Visible Tracer (Ignores FOV)
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
local TracerThickness = 1

-- States
local AimLockActive = false
local LockedTarget = nil
local AimbotEnabled = true

-- Drawing objects
local TracerLine = Drawing.new("Line")
TracerLine.Visible = false
TracerLine.Color = TracerColor
TracerLine.Thickness = TracerThickness

-- Target finding (ignores FOV)
local function GetBestTarget()
    if not AimbotEnabled then return nil end
    
    local bestTarget, closestDistance = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoidRootPart and head then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        bestTarget = player
                    end
                end
            end
        end
    end
    
    return bestTarget
end

-- Aiming function
local function AimAt(target)
    if not AimbotEnabled or not target or not target.Character then return end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    
    local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(screenPoint.X, screenPoint.Y)
    local moveTo = mousePos:Lerp(targetPos, AimSmoothness)
    
    mousemoverel(moveTo.X - mousePos.X, moveTo.Y - mousePos.Y)
end

-- Update Tracer
local function UpdateTracer()
    if ShowESP and AimbotEnabled then
        local target = LockedTarget or GetBestTarget()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = target.Character.HumanoidRootPart
            local screenPoint, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                TracerLine.From = mousePos
                TracerLine.To = Vector2.new(screenPoint.X, screenPoint.Y)
                TracerLine.Visible = true
                return
            end
        end
    end
    TracerLine.Visible = false
end

-- Main loop
RunService.RenderStepped:Connect(function()
    UpdateTracer()
    
    if not AimbotEnabled then return end
    
    if AimLockActive then
        if not LockedTarget or not LockedTarget.Character or not LockedTarget.Character:FindFirstChild("Head") then
            LockedTarget = GetBestTarget()
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
        LockedTarget = GetBestTarget()
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

-- Initial setup
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Aimbot Loaded",
    Text = "Hold left click to lock aim\nPress O to toggle",
    Duration = 5
})

print("Aimbot with always-visible tracer initialized")

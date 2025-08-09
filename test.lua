-- Aimbot with FOV 100, Left-Click Lock, Toggle, and ESP Tracer
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration
local AimSmoothness = 0.15
local FOV = 100
local AimLockKey = Enum.UserInputType.MouseButton1
local ToggleKey = Enum.KeyCode.O
local VisualizeFOV = true
local ShowESP = true
local TracerColor = Color3.fromRGB(255, 50, 50)
local TracerThickness = 1

-- States
local AimLockActive = false
local LockedTarget = nil
local AimbotEnabled = true

-- Drawing objects
local FOVCircle
local TracerLine = Drawing.new("Line")
TracerLine.Visible = false
TracerLine.Color = TracerColor
TracerLine.Thickness = TracerThickness

if VisualizeFOV then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = true
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Thickness = 1
    FOVCircle.Transparency = 0.5
    FOVCircle.Filled = false
end

-- Math functions
local function CalculateAngleBetweenVectors(a, b)
    return math.deg(math.acos(a:Dot(b)))
end

-- Target finding
local function GetBestTarget()
    if not AimbotEnabled then return nil end
    
    local bestTarget, closestAngle = nil, FOV / 2
    local cameraPos = Camera.CFrame.Position
    local cameraLook = Camera.CFrame.LookVector
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoidRootPart and head then
                local direction = (head.Position - cameraPos).Unit
                local angle = CalculateAngleBetweenVectors(cameraLook, direction)
                
                if angle < closestAngle then
                    closestAngle = angle
                    bestTarget = player
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

-- Update visuals
local function UpdateVisuals()
    -- FOV Circle
    if VisualizeFOV and FOVCircle then
        FOVCircle.Visible = AimbotEnabled
        if AimbotEnabled then
            local screenCenter = Camera.ViewportSize / 2
            local fovRadius = math.tan(math.rad(FOV/2)) * screenCenter.X
            FOVCircle.Position = screenCenter
            FOVCircle.Radius = fovRadius
        end
    end
    
    -- ESP Tracer
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
            else
                TracerLine.Visible = false
            end
        else
            TracerLine.Visible = false
        end
    else
        TracerLine.Visible = false
    end
end

-- Main loop
RunService.RenderStepped:Connect(function()
    UpdateVisuals()
    
    if not AimbotEnabled then return end
    
    -- Handle aim lock
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
    if input.UserInputType == AimLockKey and AimbotEnabled then
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
    if input.UserInputType == AimLockKey then
        AimLockActive = false
        LockedTarget = nil
    end
end)

-- Initial notification
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Aimbot Loaded",
    Text = "Hold left click to lock aim\nPress O to toggle",
    Duration = 5
})

print("Aimbot script initialized with FOV:", FOV)

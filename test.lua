-- Aimbot with Dynamic FOV Circle and Tracer
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration
local AimSmoothness = 1.0
local DefaultFOV = 100
local CurrentFOV = DefaultFOV
local ToggleKey = Enum.KeyCode.O
local ShowESP = true
local ShowFOV = true
local TracerColor = Color3.fromRGB(255, 50, 50)
local TracerThickness = 1
local FOVColor = Color3.fromRGB(255, 255, 255)

-- States
local AimLockActive = false
local LockedTarget = nil
local AimbotEnabled = true

-- Drawing objects
local TracerLine = Drawing.new("Line")
local FOVCircle = Drawing.new("Circle")

-- Initialize drawings
function InitializeDrawings()
    -- Tracer Line
    TracerLine.Visible = false
    TracerLine.Color = TracerColor
    TracerLine.Thickness = TracerThickness
    
    -- FOV Circle
    FOVCircle.Visible = ShowFOV and AimbotEnabled
    FOVCircle.Color = FOVColor
    FOVCircle.Thickness = 1
    FOVCircle.Transparency = 0.5
    FOVCircle.Filled = false
    UpdateFOVCircle()
end

-- Update FOV Circle
function UpdateFOVCircle()
    if not ShowFOV then return end
    
    local screenCenter = Camera.ViewportSize / 2
    local fovRadius = math.tan(math.rad(CurrentFOV/2)) * screenCenter.X
    
    FOVCircle.Position = screenCenter
    FOVCircle.Radius = fovRadius
    FOVCircle.Visible = AimbotEnabled and ShowFOV
end

-- Target finding with FOV check
local function GetBestTarget()
    if not AimbotEnabled then return nil end
    
    local bestTarget, closestDistance = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    local cameraPos = Camera.CFrame.Position
    local cameraLook = Camera.CFrame.LookVector
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoidRootPart and head then
                local direction = (head.Position - cameraPos).Unit
                local angle = math.deg(math.acos(cameraLook:Dot(direction)))
                local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                
                if onScreen and angle <= CurrentFOV/2 then
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
    UpdateFOVCircle()
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
        FOVCircle.Visible = AimbotEnabled and ShowFOV
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Aimbot",
            Text = AimbotEnabled and "ENABLED" or "DISABLED",
            Duration = 2
        })
    end
    
    -- FOV Adjustment with Mouse Wheel
    if input.KeyCode == Enum.KeyCode.PageUp then
        CurrentFOV = math.min(CurrentFOV + 10, 180)
        UpdateFOVCircle()
    elseif input.KeyCode == Enum.KeyCode.PageDown then
        CurrentFOV = math.max(CurrentFOV - 10, 10)
        UpdateFOVCircle()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        AimLockActive = false
        LockedTarget = nil
    end
end)

-- Initial setup
InitializeDrawings()
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Aimbot Loaded",
    Text = string.format("Hold LMB to lock aim\nPress O to toggle\nCurrent FOV: %d°\nPageUp/PageDown to adjust", CurrentFOV),
    Duration = 5
})

print("Aimbot with dynamic FOV circle initialized")

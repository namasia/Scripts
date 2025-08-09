-- Aimbot with 100 FOV and Left-Click Lock Feature
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration
local AimSmoothness = 0.15  -- Lower values = smoother aim (0.1-0.3 recommended)
local FOV = 100  -- Degrees
local AimLockKey = Enum.UserInputType.MouseButton1  -- Left click to lock aim
local VisualizeFOV = true  -- Show FOV circle

-- States
local AimLockActive = false
local LockedTarget = nil

-- FOV Visualization
local FOVCircle
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
    if not target or not target.Character then return end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    
    local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(screenPoint.X, screenPoint.Y)
    local moveTo = mousePos:Lerp(targetPos, AimSmoothness)
    
    mousemoverel(moveTo.X - mousePos.X, moveTo.Y - mousePos.Y)
end

-- Update FOV visualization
local function UpdateFOVVisual()
    if not VisualizeFOV or not FOVCircle then return end
    
    local screenCenter = Camera.ViewportSize / 2
    local fovRadius = math.tan(math.rad(FOV/2)) * screenCenter.X
    
    FOVCircle.Position = screenCenter
    FOVCircle.Radius = fovRadius
end

-- Main loop
RunService.RenderStepped:Connect(function()
    -- Update FOV visualization
    if VisualizeFOV then
        UpdateFOVVisual()
    end
    
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
    if input.UserInputType == AimLockKey then
        AimLockActive = true
        LockedTarget = GetBestTarget()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == AimLockKey then
        AimLockActive = false
        LockedTarget = nil
    end
end)

-- Cleanup
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Aimbot Loaded",
    Text = "Hold left click to lock aim",
    Duration = 5
})

print("Aimbot script initialized with FOV:", FOV)

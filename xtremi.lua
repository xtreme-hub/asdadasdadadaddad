getgenv().SilentAim = true      
getgenv().Fov = 250             
getgenv().ShowFovCircle = true  

local FovColor = Color3.fromRGB(255, 255, 255)
local FovLockedColor = Color3.fromRGB(255, 0, 0)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local CFrame_new = CFrame.new 

local currentTarget = nil
local FovCircle = Drawing.new("Circle")
FovCircle.Thickness = 1
FovCircle.Filled = false
FovCircle.NumSides = 64


local function isVisible(targetCharacter, targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter}
    local result = workspace:Raycast(origin, direction, params)
    return not result or result.Instance:IsDescendantOf(targetCharacter)
end

local function getClosestPlayerInFov()
    local closestPlayer, smallestDistance = nil, math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local targetPart = character:FindFirstChild("Head")
            local humanoid = character:FindFirstChild("Humanoid")
            if targetPart and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distanceFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if distanceFromCenter <= getgenv().Fov and distanceFromCenter < smallestDistance then
                        if isVisible(character, targetPart) then
                            smallestDistance = distanceFromCenter
                            closestPlayer = character
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

RunService.RenderStepped:Connect(function()
    if not getgenv().ShowFovCircle then
        FovCircle.Visible = false
        if getgenv().SilentAim then currentTarget = getClosestPlayerInFov() end
        return
    end
    FovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FovCircle.Radius = getgenv().Fov
    FovCircle.Visible = true
    
    currentTarget = getClosestPlayerInFov()
    FovCircle.Color = currentTarget and FovLockedColor or FovColor
end)


local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, index)
    if not getgenv().SilentAim or not currentTarget then
        return oldIndex(self, index)
    end
        local func = debug.getinfo(3, "n")
        if func and func.name == "castProjectile" and index == "CFrame" then
        local targetHead = currentTarget:FindFirstChild("Head")
        if targetHead then
            return CFrame_new(Camera.CFrame.Position, targetHead.Position)
        end
    end
    return oldIndex(self, index)
end)

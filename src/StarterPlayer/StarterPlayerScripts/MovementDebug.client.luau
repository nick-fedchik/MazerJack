local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local isDebugging = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Shared.Logger)
local log = Logger.new("MovementDebug", "1.0.0")

-- Create debug GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MovementDebugGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.BackgroundTransparency = 0.3
frame.Parent = screenGui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.Position = UDim2.new(0, 0, 0, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1, 1, 1)
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Font = Enum.Font.Code
label.TextSize = 12
label.Parent = frame

local function updateDebugInfo()
    if not isDebugging then return end
    
    local info = "=== MOVEMENT DEBUG ===\n"
    
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
        
        if humanoid then
            info = info .. "Humanoid State: " .. humanoid:GetState().Name .. "\n"
            info = info .. "WalkSpeed: " .. humanoid.WalkSpeed .. "\n"
            info = info .. "JumpPower: " .. humanoid.JumpPower .. "\n"
            info = info .. "MoveDirection: " .. tostring(humanoid.MoveDirection) .. "\n"
            info = info .. "MoveDirection.Magnitude: " .. humanoid.MoveDirection.Magnitude .. "\n"
            info = info .. "PlatformStand: " .. tostring(humanoid.PlatformStand) .. "\n"
            info = info .. "Sit: " .. tostring(humanoid.Sit) .. "\n"
        end
        
        if rootPart then
            info = info .. "RootPart Position: " .. tostring(rootPart.Position) .. "\n"
            info = info .. "RootPart Velocity: " .. tostring(rootPart.Velocity) .. "\n"
        end
    else
        info = info .. "No Character\n"
    end
    
    info = info .. "\n=== INPUT ===\n"
    local keys = {}
    for _, keyCode in ipairs({Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space}) do
        if UserInputService:IsKeyDown(keyCode) then
            table.insert(keys, keyCode.Name)
        end
    end
    info = info .. "Keys pressed: " .. table.concat(keys, ", ") .. "\n"
    
    label.Text = info
end

-- Update debug info every frame
RunService.Heartbeat:Connect(updateDebugInfo)

-- Toggle debug with F1 key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F1 then
        isDebugging = not isDebugging
        screenGui.Enabled = isDebugging
        log:Info("Movement debug: " .. (isDebugging and "ON" or "OFF"))
    end
end)

    log:Info("Movement debug script loaded. Press F1 to toggle debug GUI.")

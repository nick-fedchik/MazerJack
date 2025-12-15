local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function fixMovement()
    local player = Players.LocalPlayer
    if not player or not player.Character then return end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        -- Force movement properties every frame
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        humanoid.AutoRotate = true
        
        -- Ensure character is in proper state
        if humanoid:GetState() == Enum.HumanoidStateType.Physics then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end

-- Fix movement immediately and every frame
fixMovement()
RunService.Heartbeat:Connect(fixMovement)

-- Also fix when character respawns
Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    fixMovement()
end)

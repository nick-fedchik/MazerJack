--[[
        Тип: LocalScript
        Назва: MovementFix
        Версія: 1.2.0
        Розміщення: StarterPlayer/StarterPlayerScripts/MovementFix

        Призначення:
            Стабілізує рух гравця, примусово встановлюючи базові властивості `Humanoid`.

        Загальна логіка:
            - Встановлює WalkSpeed/JumpPower/AutoRotate кожен кадр
            - Повертає стан з Physics у Running за потреби
            - Реагує на `CharacterAdded`
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Shared.Logger)
local log = Logger.new("MovementFix", "1.2.0")

-- Function: fixMovement
-- Призначення:
-- Примусово встановити базові властивості руху та коректний стан Humanoid
-- Вхідні параметри: None
-- Вихід / ефект: модифікує властивості поточного персонажа гравця
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
            log:Info("Fix", "Changed state from Physics to Running")
        end
    end
end

-- Fix movement immediately and every frame
log:Info("Init", "MovementFix starting")
fixMovement()
RunService.Heartbeat:Connect(fixMovement)

-- Also fix when character respawns
Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    fixMovement()
end)

log:Info("Done", "MovementFix ready")

-- End of script: MovementFix v1.2.0

--[[
        Тип: LocalScript
        Назва: GuiController
        Версія: 1.2.1
        Розміщення: StarterPlayer/StarterPlayerScripts/GuiController

        Призначення:
            Керує видимістю Join/Station GUI в залежності від `CurrentMode` атрибуту гравця.

        Загальна логіка:
            - Слухає `AttributeChanged` для `CurrentMode`
            - Включає/вимикає відповідні GUI

        Архітектурні правила:
            - Не робить spawn або бізнес-логіку
            - Логує лише ключові зміни стану
--]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Shared.Logger)
local log = Logger.new("GuiController", "1.2.1")

log:Info("Init", "GuiController starting")

-- Чекаємо на PlayerGui
local playerGui = player:WaitForChild("PlayerGui")
log:Info("Resolve", "PlayerGui found")

-- Чекаємо на GUI
local joinGui = playerGui:WaitForChild("JoinGameGui", 10)
local stationGui = playerGui:WaitForChild("StationGui", 5)

if joinGui then
    log:Info("Resolve", "JoinGameGui found")
else
    log:Warn("Resolve", "JoinGameGui NOT found after 10 seconds")
end

if stationGui then
    log:Info("Resolve", "StationGui found")
else
    log:Warn("Resolve", "StationGui NOT found after 5 seconds")
end

-- Функція оновлення GUI
-- Function: updateGui
-- Призначення:
-- Оновлює видимість GUI на основі атрибуту `CurrentMode` гравця
-- Вхідні параметри: None
-- Вихід / ефект: змінює `Enabled` на `JoinGameGui` / `StationGui`
local function updateGui()
    local currentMode = player:GetAttribute("CurrentMode")
    log:Info("Update", "Updating GUI for mode=%s", tostring(currentMode))
    
    if currentMode == "Join" then
        if joinGui then
            joinGui.Enabled = true
            log:Info("JoinGameGui enabled")
        end
        if stationGui then
            stationGui.Enabled = false
            log:Info("StationGui disabled")
        end
    elseif currentMode == "Station" then
        if joinGui then
            joinGui.Enabled = false
            log:Info("JoinGameGui disabled")
        end
        if stationGui then
            stationGui.Enabled = true
            log:Info("StationGui enabled")
        end
    else
        log:Warn("Update", "Unknown mode=%s", tostring(currentMode))
    end
end

-- Слухаємо зміни атрибутів
player.AttributeChanged:Connect(function(attrName)
    if attrName == "CurrentMode" then
        updateGui()
    end
end)

-- Перевіряємо стан кожні 2 секунди
task.spawn(function()
    while task.wait(2) do
        updateGui()
    end
end)

-- Початкове оновлення
updateGui()

log:Info("Done", "GUI controller started")

-- End of script: GuiController v1.2.1

return "GuiController started"
--[[
        Тип: LocalScript
        Назва: AttributeMonitor
        Версія: 1.2.0
        Розміщення: StarterPlayer/StarterPlayerScripts/AttributeMonitor

        Призначення:
            Слідкує за змінами атрибутів гравця та логує важливі зміни (наприклад, CurrentMode).

        Загальна логіка:
            - Логує початкові атрибути
            - Слухає `AttributeChanged` та реагує на `CurrentMode`
--]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Shared.Logger)
local log = Logger.new("AttributeMonitor", "1.2.0")

log:Info("Init", "AttributeMonitor starting")

-- Перевіряємо початкові атрибути
log:Info("Initial attributes:")
for _, attr in ipairs(player:GetAttributes()) do
        log:Info("  " .. attr .. " = " .. tostring(player:GetAttribute(attr)))
end

-- Слухаємо зміни атрибутів
-- Function: handleAttributeChanged
-- Призначення:
-- Обробляє подію `AttributeChanged` і реагує на ключові атрибути
-- Вхідні параметри:
-- attrName: string — назва атрибуту
local function handleAttributeChanged(attrName)
    log:Info("Attribute changed: %s = %s", tostring(attrName), tostring(player:GetAttribute(attrName)))

    if attrName == "CurrentMode" then
        local mode = player:GetAttribute(attrName)
        log:Info("CurrentMode changed to: %s", tostring(mode))

        if mode == "Join" then
            log:Info("Should show JoinGameGui")
        elseif mode == "Station" then
            log:Info("Should show StationGui")
        end
    end
end

player.AttributeChanged:Connect(handleAttributeChanged)

-- Періодично перевіряємо атрибути
task.spawn(function()
    while task.wait(2) do
        local currentMode = player:GetAttribute("CurrentMode")
        if currentMode then
            log:Info("CurrentMode is: " .. tostring(currentMode))
        else
            log:Info("CurrentMode is not set yet")
        end
    end
end)

log:Info("Done", "Attribute monitoring started")

-- End of script: AttributeMonitor v1.2.0

return "AttributeMonitor started"
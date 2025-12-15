-- Attribute Monitor - перевіряє атрибути гравця
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Shared.Logger)
local log = Logger.new("AttributeMonitor", "1.0.0")

log:Info("Starting attribute monitoring...")

-- Перевіряємо початкові атрибути
log:Info("Initial attributes:")
for _, attr in ipairs(player:GetAttributes()) do
    log:Info("  " .. attr .. " = " .. tostring(player:GetAttribute(attr)))
end

-- Слухаємо зміни атрибутів
player.AttributeChanged:Connect(function(attrName)
    log:Info("Attribute changed: " .. tostring(attrName) .. " = " .. tostring(player:GetAttribute(attrName)))
    
    if attrName == "CurrentMode" then
        local mode = player:GetAttribute(attrName)
        log:Info("CurrentMode changed to: " .. tostring(mode))
        
        if mode == "Join" then
            log:Info("Should show JoinGameGui")
        elseif mode == "Station" then
            log:Info("Should show StationGui")
        end
    end
end)

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

log:Info("Attribute monitoring started")

return "AttributeMonitor started"
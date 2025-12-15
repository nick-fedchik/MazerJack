-- GUI Controller - керує видимістю GUI на основі атрибутів
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Shared.Logger)
local log = Logger.new("GuiController", "1.2.0")

log:Info("Starting GUI controller...")

-- Чекаємо на PlayerGui
local playerGui = player:WaitForChild("PlayerGui")
log:Info("PlayerGui found")

-- Чекаємо на GUI
local joinGui = playerGui:WaitForChild("JoinGameGui", 10)
local stationGui = playerGui:WaitForChild("StationGui", 5)

if joinGui then
    log:Info("JoinGameGui found")
else
    log:Warn("JoinGameGui NOT found after 10 seconds!")
end

if stationGui then
    log:Info("StationGui found")
else
    log:Warn("StationGui NOT found after 5 seconds!")
end

-- Функція оновлення GUI
local function updateGui()
    local currentMode = player:GetAttribute("CurrentMode")
    log:Info("Updating GUI for mode: " .. tostring(currentMode))
    
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
        log:Warn("Unknown mode: " .. tostring(currentMode))
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

log:Info("GUI controller started")

return "GuiController started"
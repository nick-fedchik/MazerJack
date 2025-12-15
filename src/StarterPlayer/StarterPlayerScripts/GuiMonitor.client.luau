--[[
        Тип: LocalScript
        Назва: GuiMonitor
        Версія: 1.2.1
        Розміщення: StarterPlayer/StarterPlayerScripts/GuiMonitor

        Призначення:
            Моніторить наявність та стан GUI елементів при вході гравця для швидкої діагностики.

        Загальна логіка:
            - Очікує `PlayerGui` і перевіряє ключові GUI (JoinGameGui, StationGui)
            - Логує статус та наявність елементів

        Взаємодія / контракти:
            - Не взаємодіє через Remotes; лише читає `PlayerGui`

        Архітектурні правила:
            - Використовує тільки `Logger` для логів
            - Не змінює state гри
--]]

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Shared.Logger)
local log = Logger.new("GuiMonitor", "1.2.1")

log:Info("Init", "GuiMonitor starting")

-- Чекаємо на PlayerGui
local playerGui = player:WaitForChild("PlayerGui")
log:Info("Resolve", "PlayerGui found")

-- Перевіряємо JoinGameGui
local joinGui = playerGui:WaitForChild("JoinGameGui", 10)
if joinGui then
    log:Info("Resolve", "JoinGameGui found Enabled=%s", tostring(joinGui.Enabled))

    local hasRoot = joinGui:FindFirstChild("Root") ~= nil
    if not hasRoot then
        log:Warn("Resolve", "JoinGameGui.Root not found (ok if UI uses a different container)")
    end

    local playerName = joinGui:FindFirstChild("PlayerName", true)
    local playerStatus = joinGui:FindFirstChild("PlayerStatus", true)
    local gameStatus = joinGui:FindFirstChild("GameStatus", true)
    local joinButton = joinGui:FindFirstChild("JoinGameButton", true)

    log:Info("Check", "PlayerName=%s", tostring(playerName ~= nil))
    log:Info("Check", "PlayerStatus=%s", tostring(playerStatus ~= nil))
    log:Info("Check", "GameStatus=%s", tostring(gameStatus ~= nil))
    log:Info("Check", "JoinGameButton=%s", tostring(joinButton ~= nil))

    if playerName and playerStatus and gameStatus and joinButton then
        log:Info("Check", "All JoinScreen expected elements found")
    else
        log:Warn("Check", "Some JoinScreen expected elements are missing")
    end
else
    log:Warn("Resolve", "JoinGameGui not found in PlayerGui after 10 seconds")
end

-- Перевіряємо StationGui
local stationGui = playerGui:WaitForChild("StationGui", 5)
if stationGui then
    log:Info("Resolve", "StationGui found Enabled=%s", tostring(stationGui.Enabled))
else
    log:Info("Resolve", "StationGui not found (expected to be disabled initially)")
end

log:Info("Done", "GUI monitoring completed")

-- End of script: GuiMonitor v1.2.1

return "GuiMonitor finished"
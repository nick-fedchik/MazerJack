-- GUI Monitor - перевіряє стан GUI при вході гравця
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Shared.Logger)
local log = Logger.new("GuiMonitor", "1.2.0")

log:Info("Starting GUI monitoring...")

-- Чекаємо на PlayerGui
local playerGui = player:WaitForChild("PlayerGui")
print("[GuiMonitor] PlayerGui found")

-- Перевіряємо JoinGameGui
local joinGui = playerGui:WaitForChild("JoinGameGui", 10)
if joinGui then
    log:Info("JoinGameGui found in PlayerGui")
    log:Info("JoinGameGui.Enabled: " .. tostring(joinGui.Enabled))
    
    -- Перевіряємо елементи
    local root = joinGui:FindFirstChild("Root")
    if root then
        log:Info("Root frame found")
        
        local gameTitle = root:FindFirstChild("GameTitle")
        local gameVersion = root:FindFirstChild("GameVersion")
        local playerContainer = root:FindFirstChild("PlayerContainer")
        local loadingIndicator = root:FindFirstChild("LoadingIndicator")
        local joinButton = root:FindFirstChild("JoinGameButton")
        
        log:Info("GameTitle: " .. tostring(gameTitle and "found" or "NOT FOUND"))
        log:Info("GameVersion: " .. tostring(gameVersion and "found" or "NOT FOUND"))
        log:Info("PlayerContainer: " .. tostring(playerContainer and "found" or "NOT FOUND"))
        log:Info("LoadingIndicator: " .. tostring(loadingIndicator and "found" or "NOT FOUND"))
        log:Info("JoinGameButton: " .. tostring(joinButton and "found" or "NOT FOUND"))
        
        if playerContainer then
            local avatarImage = playerContainer:FindFirstChild("AvatarImage")
            local playerName = playerContainer:FindFirstChild("PlayerName")
            local playerStatus = playerContainer:FindFirstChild("PlayerStatus")
            
            log:Info("AvatarImage: " .. tostring(avatarImage and "found" or "NOT FOUND"))
            log:Info("PlayerName: " .. tostring(playerName and "found" or "NOT FOUND"))
            log:Info("PlayerStatus: " .. tostring(playerStatus and "found" or "NOT FOUND"))
        end
        
        if gameTitle and gameVersion and playerContainer and loadingIndicator and joinButton then
            log:Info("✅ All main GUI elements found!")

            -- Перевіряємо видимість
            log:Info("GameTitle.Visible: " .. tostring(gameTitle.Visible))
            log:Info("GameVersion.Visible: " .. tostring(gameVersion.Visible))
            log:Info("PlayerContainer.Visible: " .. tostring(playerContainer.Visible))
            log:Info("LoadingIndicator.Visible: " .. tostring(loadingIndicator.Visible))
            log:Info("JoinGameButton.Visible: " .. tostring(joinButton.Visible))
        else
            log:Warn("Some GUI elements missing!")
        end
    else
        log:Warn("Root frame not found!")
    end
else
    log:Warn("JoinGameGui not found in PlayerGui after 10 seconds!")
end

-- Перевіряємо StationGui
local stationGui = playerGui:WaitForChild("StationGui", 5)
if stationGui then
    log:Info("StationGui found in PlayerGui")
    log:Info("StationGui.Enabled: " .. tostring(stationGui.Enabled))
else
    log:Info("StationGui not found in PlayerGui (expected to be disabled initially)")
end

log:Info("GUI monitoring completed")

return "GuiMonitor finished"
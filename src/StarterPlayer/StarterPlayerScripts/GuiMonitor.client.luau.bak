-- GUI Monitor - перевіряє стан GUI при вході гравця
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

print("[GuiMonitor] Starting GUI monitoring...")

-- Чекаємо на PlayerGui
local playerGui = player:WaitForChild("PlayerGui")
print("[GuiMonitor] PlayerGui found")

-- Перевіряємо JoinGameGui
local joinGui = playerGui:WaitForChild("JoinGameGui", 10)
if joinGui then
    print("[GuiMonitor] JoinGameGui found in PlayerGui")
    print("[GuiMonitor] JoinGameGui.Enabled:", joinGui.Enabled)
    
    -- Перевіряємо елементи
    local root = joinGui:FindFirstChild("Root")
    if root then
        print("[GuiMonitor] Root frame found")
        
        local gameTitle = root:FindFirstChild("GameTitle")
        local gameVersion = root:FindFirstChild("GameVersion")
        local playerContainer = root:FindFirstChild("PlayerContainer")
        local loadingIndicator = root:FindFirstChild("LoadingIndicator")
        local joinButton = root:FindFirstChild("JoinGameButton")
        
        print("[GuiMonitor] GameTitle:", gameTitle and "found" or "NOT FOUND")
        print("[GuiMonitor] GameVersion:", gameVersion and "found" or "NOT FOUND")
        print("[GuiMonitor] PlayerContainer:", playerContainer and "found" or "NOT FOUND")
        print("[GuiMonitor] LoadingIndicator:", loadingIndicator and "found" or "NOT FOUND")
        print("[GuiMonitor] JoinGameButton:", joinButton and "found" or "NOT FOUND")
        
        if playerContainer then
            local avatarImage = playerContainer:FindFirstChild("AvatarImage")
            local playerName = playerContainer:FindFirstChild("PlayerName")
            local playerStatus = playerContainer:FindFirstChild("PlayerStatus")
            
            print("[GuiMonitor] AvatarImage:", avatarImage and "found" or "NOT FOUND")
            print("[GuiMonitor] PlayerName:", playerName and "found" or "NOT FOUND")
            print("[GuiMonitor] PlayerStatus:", playerStatus and "found" or "NOT FOUND")
        end
        
        if gameTitle and gameVersion and playerContainer and loadingIndicator and joinButton then
            print("[GuiMonitor] ✅ All main GUI elements found!")
            
            -- Перевіряємо видимість
            print("[GuiMonitor] GameTitle.Visible:", gameTitle.Visible)
            print("[GuiMonitor] GameVersion.Visible:", gameVersion.Visible)
            print("[GuiMonitor] PlayerContainer.Visible:", playerContainer.Visible)
            print("[GuiMonitor] LoadingIndicator.Visible:", loadingIndicator.Visible)
            print("[GuiMonitor] JoinGameButton.Visible:", joinButton.Visible)
        else
            print("[GuiMonitor] ❌ Some GUI elements missing!")
        end
    else
        print("[GuiMonitor] ❌ Root frame not found!")
    end
else
    print("[GuiMonitor] ❌ JoinGameGui not found in PlayerGui after 10 seconds!")
end

-- Перевіряємо StationGui
local stationGui = playerGui:WaitForChild("StationGui", 5)
if stationGui then
    print("[GuiMonitor] StationGui found in PlayerGui")
    print("[GuiMonitor] StationGui.Enabled:", stationGui.Enabled)
else
    print("[GuiMonitor] StationGui not found in PlayerGui (expected to be disabled initially)")
end

print("[GuiMonitor] GUI monitoring completed")

return "GuiMonitor finished"
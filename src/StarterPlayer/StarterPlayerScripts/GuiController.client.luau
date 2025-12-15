-- GUI Controller - керує видимістю GUI на основі атрибутів
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("[GuiController] Starting GUI controller...")

-- Чекаємо на PlayerGui
local playerGui = player:WaitForChild("PlayerGui")
print("[GuiController] PlayerGui found")

-- Чекаємо на GUI
local joinGui = playerGui:WaitForChild("JoinGameGui", 10)
local stationGui = playerGui:WaitForChild("StationGui", 5)

if joinGui then
    print("[GuiController] JoinGameGui found")
else
    print("[GuiController] JoinGameGui NOT found after 10 seconds!")
end

if stationGui then
    print("[GuiController] StationGui found")
else
    print("[GuiController] StationGui NOT found after 5 seconds!")
end

-- Функція оновлення GUI
local function updateGui()
    local currentMode = player:GetAttribute("CurrentMode")
    print("[GuiController] Updating GUI for mode:", currentMode)
    
    if currentMode == "Join" then
        if joinGui then
            joinGui.Enabled = true
            print("[GuiController] JoinGameGui enabled")
        end
        if stationGui then
            stationGui.Enabled = false
            print("[GuiController] StationGui disabled")
        end
    elseif currentMode == "Station" then
        if joinGui then
            joinGui.Enabled = false
            print("[GuiController] JoinGameGui disabled")
        end
        if stationGui then
            stationGui.Enabled = true
            print("[GuiController] StationGui enabled")
        end
    else
        print("[GuiController] Unknown mode:", currentMode)
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

print("[GuiController] GUI controller started")

return "GuiController started"
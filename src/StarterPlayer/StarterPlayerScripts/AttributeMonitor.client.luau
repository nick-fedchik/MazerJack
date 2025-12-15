-- Attribute Monitor - перевіряє атрибути гравця
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("[AttributeMonitor] Starting attribute monitoring...")

-- Перевіряємо початкові атрибути
print("[AttributeMonitor] Initial attributes:")
for _, attr in ipairs(player:GetAttributes()) do
    print("  " .. attr .. " = " .. tostring(player:GetAttribute(attr)))
end

-- Слухаємо зміни атрибутів
player.AttributeChanged:Connect(function(attrName)
    print("[AttributeMonitor] Attribute changed:", attrName, "=", tostring(player:GetAttribute(attrName)))
    
    if attrName == "CurrentMode" then
        local mode = player:GetAttribute(attrName)
        print("[AttributeMonitor] CurrentMode changed to:", mode)
        
        if mode == "Join" then
            print("[AttributeMonitor] Should show JoinGameGui")
        elseif mode == "Station" then
            print("[AttributeMonitor] Should show StationGui")
        end
    end
end)

-- Періодично перевіряємо атрибути
task.spawn(function()
    while task.wait(2) do
        local currentMode = player:GetAttribute("CurrentMode")
        if currentMode then
            print("[AttributeMonitor] CurrentMode is:", currentMode)
        else
            print("[AttributeMonitor] CurrentMode is not set yet")
        end
    end
end)

print("[AttributeMonitor] Attribute monitoring started")

return "AttributeMonitor started"
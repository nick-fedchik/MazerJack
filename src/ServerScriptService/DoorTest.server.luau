--[[
    Тип: Script
    Назва: DoorTest
    Версія: 1.2.0
    Розміщення: ServerScriptService/DoorTest

    Призначення:
      Приватний тестовий скрипт для перевірки механіки дверей у StellarStation.

    Загальна логіка:
      - Реєструє всі двері в `StellarStation` та відстежує наближення гравців
      - Відкриває / закриває двері анімацією Tween

    Взаємодія / контракти:
      - Тимчасовий тестовий скрипт; у продакшені логіку реалізує `DoorService`

    Архітектурні правила:
      - Використовує `Logger` (не `print`)
      - Не змінює ігровий стан гравців
--]]

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------

local Logger = require(ReplicatedStorage.Shared.Logger)
local log = Logger.new("DoorTest", "1.2.0")

-- Configuration
local DOOR_OPEN_DISTANCE = 8
local DOOR_OPEN_HEIGHT = 4
local DOOR_TWEEN_TIME = 0.8
local CHECK_INTERVAL = 0.3

-- Find all doors
local doors = {}
local station = workspace:FindFirstChild("StellarStation")

if station then
    for _, doorModel in station:GetChildren() do
        if string.match(doorModel.Name, "Door$") then
            local door = doorModel:FindFirstChild("Door")
            local trigger = doorModel:FindFirstChild("Trigger")
            
            if door and trigger then
                table.insert(doors, {
                    model = doorModel,
                    door = door,
                    trigger = trigger,
                    originalPosition = door.Position,
                    isOpen = false,
                    tween = nil
                })
            end
        end
    end
end

log:Info("Init", "Found %d doors", #doors)

-- Door functions
local function openDoor(doorData)
    if doorData.isOpen or doorData.tween then
        return
    end
    
    doorData.isOpen = true
    
    local goalPosition = doorData.originalPosition + Vector3.new(0, DOOR_OPEN_HEIGHT, 0)
    local tweenInfo = TweenInfo.new(DOOR_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    doorData.tween = TweenService:Create(doorData.door, tweenInfo, {Position = goalPosition})
    doorData.tween:Play()
    
    doorData.tween.Completed:Connect(function()
        doorData.tween = nil
    end)
    
    log:Info("OpenDoor", "Opened door: %s", doorData.model.Name)
end

local function closeDoor(doorData)
    if not doorData.isOpen or doorData.tween then
        return
    end
    
    doorData.isOpen = false
    
    local tweenInfo = TweenInfo.new(DOOR_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    
    doorData.tween = TweenService:Create(doorData.door, tweenInfo, {Position = doorData.originalPosition})
    doorData.tween:Play()
    
    doorData.tween.Completed:Connect(function()
        doorData.tween = nil
    end)
    
    log:Info("CloseDoor", "Closed door: %s", doorData.model.Name)
end

-- Proximity check loop
task.spawn(function()
    while true do
        local players = Players:GetPlayers()
        
        -- Reset door states
        for _, doorData in ipairs(doors) do
            doorData.shouldBeOpen = false
        end
        
        -- Check each player's proximity to each door
        for _, player in players do
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local playerPos = character.HumanoidRootPart.Position
                
                for _, doorData in ipairs(doors) do
                    local distance = (playerPos - doorData.trigger.Position).Magnitude
                    if distance <= DOOR_OPEN_DISTANCE then
                        doorData.shouldBeOpen = true
                    end
                end
            end
        end
        
        -- Update door states
        for _, doorData in ipairs(doors) do
            if doorData.shouldBeOpen and not doorData.isOpen then
                openDoor(doorData)
            elseif not doorData.shouldBeOpen and doorData.isOpen then
                closeDoor(doorData)
            end
        end
        
        task.wait(CHECK_INTERVAL)
    end
end)

log:Info("Init", "Door system initialized")

----------------------------------------------------------------
-- End of script: DoorTest v1.2.0
----------------------------------------------------------------
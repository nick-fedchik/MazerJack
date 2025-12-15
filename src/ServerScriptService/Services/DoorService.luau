--[[
    Тип: ModuleScript
    Назва: DoorService
        Версія: 1.1.0
    Розміщення: ServerScriptService/Services/DoorService

    Призначення:
      Керує автоматичними дверима кабін, що відкриваються при наближенні гравця.

    Логіка:
      - Автоматично відкриває/закриває двері при наближенні гравця
      - Анімація дверей: рух вгору/вниз
      - Працює для всіх дверей кабін
    
        Взаємодія / контракти:
            - Використовується GameState/Spawn кодом гри через Services, не напряму клієнтом
            - Надає сервіси для інших модулів (за потреби)

        Архітектурні правила:
            - НЕ виконує spawn/teleport
            - НЕ використовує remotes
--]]

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------

local Logger = require(ReplicatedStorage.Shared.Logger)

----------------------------------------------------------------
-- Module setup
----------------------------------------------------------------

local DoorService = {}
DoorService.__index = DoorService

local log = Logger.new("DoorService", "1.0.0")

-- Configuration
local DOOR_OPEN_DISTANCE = 8 -- Distance in studs to trigger door
local DOOR_OPEN_HEIGHT = 4 -- How high the door moves when opening
local DOOR_TWEEN_TIME = 0.8 -- Time for door animation
local CHECK_INTERVAL = 0.3 -- How often to check player proximity

----------------------------------------------------------------
-- Construction
----------------------------------------------------------------

function DoorService.new()
    local self = setmetatable({}, DoorService)
    self.doors = {}
    self.playerNearDoors = {} -- Track which doors each player is near
    
    self:InitializeDoors()
    self:StartProximityCheck()
    
    return self
end

----------------------------------------------------------------
-- Door Management
----------------------------------------------------------------

function DoorService:InitializeDoors()
    local station = workspace:FindFirstChild("StellarStation")
    if not station then
        log:Error("InitializeDoors", "StellarStation not found")
        return
    end
    
    -- Find all door models
    for _, doorModel in station:GetChildren() do
        if string.match(doorModel.Name, "Door$") then
            self:RegisterDoor(doorModel)
        end
    end
    
    log:Info("InitializeDoors", "Registered %d doors", #self.doors)
end

function DoorService:RegisterDoor(doorModel)
    local door = doorModel:FindFirstChild("Door")
    local trigger = doorModel:FindFirstChild("Trigger")
    
    if not door or not trigger then
        log:Warn("RegisterDoor", "Door model %s missing Door or Trigger part", doorModel.Name)
        return
    end
    
    -- Store door data
    local doorData = {
        model = doorModel,
        door = door,
        trigger = trigger,
        originalPosition = door.Position,
        isOpen = false,
        tween = nil
    }
    
    table.insert(self.doors, doorData)
    log:Info("RegisterDoor", "Registered door: %s", doorModel.Name)
end

----------------------------------------------------------------
-- Door Animation
----------------------------------------------------------------

function DoorService:OpenDoor(doorData)
    if doorData.isOpen or doorData.tween then
        return
    end
    
    doorData.isOpen = true
    
    -- Create tween to move door up
    local goalPosition = doorData.originalPosition + Vector3.new(0, DOOR_OPEN_HEIGHT, 0)
    local tweenInfo = TweenInfo.new(DOOR_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    doorData.tween = TweenService:Create(doorData.door, tweenInfo, {Position = goalPosition})
    doorData.tween:Play()
    
    doorData.tween.Completed:Connect(function()
        doorData.tween = nil
    end)
    
    log:Info("OpenDoor", "Opened door: %s", doorData.model.Name)
end

function DoorService:CloseDoor(doorData)
    if not doorData.isOpen or doorData.tween then
        return
    end
    
    doorData.isOpen = false
    
    -- Create tween to move door down
    local tweenInfo = TweenInfo.new(DOOR_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    
    doorData.tween = TweenService:Create(doorData.door, tweenInfo, {Position = doorData.originalPosition})
    doorData.tween:Play()
    
    doorData.tween.Completed:Connect(function()
        doorData.tween = nil
    end)
    
    log:Info("CloseDoor", "Closed door: %s", doorData.model.Name)
end

----------------------------------------------------------------
-- Proximity Detection
----------------------------------------------------------------

function DoorService:StartProximityCheck()
    task.spawn(function()
        while true do
            self:CheckAllPlayerProximity()
            task.wait(CHECK_INTERVAL)
        end
    end)
end

function DoorService:CheckAllPlayerProximity()
    local players = Players:GetPlayers()
    
    -- Reset door states
    for _, doorData in ipairs(self.doors) do
        doorData.shouldBeOpen = false
    end
    
    -- Check each player's proximity to each door
    for _, player in players do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local playerPos = character.HumanoidRootPart.Position
            
            for _, doorData in ipairs(self.doors) do
                local distance = (playerPos - doorData.trigger.Position).Magnitude
                if distance <= DOOR_OPEN_DISTANCE then
                    doorData.shouldBeOpen = true
                end
            end
        end
    end
    
    -- Update door states based on proximity
    for _, doorData in ipairs(self.doors) do
        if doorData.shouldBeOpen and not doorData.isOpen then
            self:OpenDoor(doorData)
        elseif not doorData.shouldBeOpen and doorData.isOpen then
            self:CloseDoor(doorData)
        end
    end
end

return DoorService
----------------------------------------------------------------
-- End of script: DoorService v1.0.0
----------------------------------------------------------------
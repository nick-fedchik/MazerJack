--[[
    Тип: ModuleScript
    Назва: LandingZone
    Версія: 0.1.0
    Розміщення: ServerScriptService/Services/LandingZone

    Призначення:
      Простий сервіс для обробки CheckIn гравців у локаціях (позначення останнього чекпоінту).
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Logger)
local log = Logger.new("LandingZone", "0.1.0")

local LandingZone = {}
LandingZone.__index = LandingZone

local PersistenceService = require(script.Parent.PersistenceService)

function LandingZone.CheckIn(player, locationId)
    if not player or not locationId then
        log:Warn("CheckIn", "invalid args player=%s location=%s", tostring(player and (player.Name or player.UserId)), tostring(locationId))
        return false
    end

    local state = PersistenceService:GetCached(player)
    state.lastLocationId = locationId
    PersistenceService:Save(player, state)

    log:Info("CheckIn", "player=%s location=%s", tostring(player.Name or player.UserId), tostring(locationId))
    return true
end

return LandingZone

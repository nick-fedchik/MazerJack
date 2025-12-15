--[[
    Тип: ModuleScript
    Назва: StationService
    Версія: 0.1.0
    Розміщення: ServerScriptService/Services/StationService

    Призначення:
      Менеджер логіки станції: точки спавну, переміщення між локаціями, перевірки доступу.

    Архітектурні правила:
      - НЕ виконує прямого телепорту; повертає дані і дозволи для інших сервісів/скриптів
      - Використовує `Logger` для логів
      - Мінімальний API для MVP
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Logger)

local StationService = {}
StationService.__index = StationService

local log = Logger.new("StationService", "0.1.0")

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

-- Returns a default spawn zone name for `player` (string)
function StationService.GetDefaultSpawn(player)
    -- For MVP we always spawn at the Station
    return "Station"
end

-- Returns whether a player can enter the given moduleId
function StationService.CanEnterModule(player, moduleId)
    -- Basic checks; in MVP we allow access to all modules
    if not player then
        return false, "invalid_player"
    end

    -- future: check permissions, cooldown, energy, etc.
    return true
end

-- Request travel between locations. Returns success, reason
function StationService.RequestTravelToLocation(player, locationId)
    if not player then
        return false, "invalid_player"
    end

    if not locationId then
        return false, "invalid_location"
    end

    -- For MVP we accept the request; actual movement handled by PlayerSpawnService
    log:Info("RequestTravelToLocation", "player=%s location=%s", tostring(player.Name or player.UserId), tostring(locationId))
    return true
end

return StationService

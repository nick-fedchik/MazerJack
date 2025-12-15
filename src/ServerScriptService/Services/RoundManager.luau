--[[
    Тип: ModuleScript
    Назва: RoundManager
    Версія: 0.1.0
    Розміщення: ServerScriptService/Services/RoundManager

    Призначення:
      Простий менеджер раундів: старт/кінець раунду та перевірки стану.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Shared.Logger)

local RoundManager = {}
RoundManager.__index = RoundManager

local log = Logger.new("RoundManager", "0.1.0")

local _isActive = false
local _roundId = nil

function RoundManager.StartRound(durationSeconds)
    if _isActive then
        return false, "already_active"
    end

    _isActive = true
    _roundId = os.time()

    log:Info("StartRound", "roundId=%s duration=%s", tostring(_roundId), tostring(durationSeconds))

    if durationSeconds and type(durationSeconds) == "number" then
        task.delay(durationSeconds, function()
            RoundManager.EndRound()
        end)
    end

    return true
end

function RoundManager.EndRound()
    if not _isActive then
        return false, "not_active"
    end

    _isActive = false
    log:Info("EndRound", "roundId=%s", tostring(_roundId))
    _roundId = nil
    return true
end

function RoundManager.IsRoundActive()
    return _isActive
end

return RoundManager

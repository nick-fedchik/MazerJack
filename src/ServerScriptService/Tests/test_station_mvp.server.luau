--[[
    Тип: Script
    Назва: test_station_mvp
    Версія: 0.1.0
    Розміщення: ServerScriptService/Tests/test_station_mvp

    Призначення:
      Прості перевірки для Station MVP: RoundManager та LandingZone інтеграція з PersistenceService.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Shared.Logger)
local log = Logger.new("test_station_mvp", "0.1.0")

local RoundManager = require(script.Parent.Parent.Services.RoundManager)
local LandingZone = require(script.Parent.Parent.Services.LandingZone)
local PersistenceService = require(script.Parent.Parent.Services.PersistenceService)

-- Simple assertion helper
local function assertf(cond, msg, ...)
    if not cond then
        log:Error("assert", msg or "assertion failed", ...)
        error(msg or "assertion failed")
    end
end

-- Test RoundManager start/stop
do
    local ok, err = RoundManager.StartRound(1)
    assertf(ok == true, "StartRound should return true")
    assertf(RoundManager.IsRoundActive() == true, "Round should be active after StartRound")

    -- End round manually
    ok, err = RoundManager.EndRound()
    assertf(ok == true, "EndRound should return true")
    assertf(RoundManager.IsRoundActive() == false, "Round should be inactive after EndRound")
end

-- Test LandingZone CheckIn persists lastLocationId
do
    -- Create a fake player-like table
    local fakePlayer = { UserId = 999999, Name = "TestPlayer" }
    local state = PersistenceService:GetCached(fakePlayer)
    state.lastLocationId = nil
    PersistenceService:Save(fakePlayer, state)

    local ok = LandingZone.CheckIn(fakePlayer, "TestLocation")
    assertf(ok == true, "LandingZone.CheckIn should return true")

    local newState = PersistenceService:GetCached(fakePlayer)
    assertf(newState.lastLocationId == "TestLocation", "lastLocationId should be persisted by CheckIn")
end

log:Info("test_station_mvp", "All station MVP tests passed")

--[[
    Тип: ModuleScript
    Назва: Enums
    Версія: 1.2.0
    Розміщення: ReplicatedStorage/Shared/Enums

    Призначення:
      Центральне визначення «enum-подібних» констант (рядки), які спільні для Server/Client.

    Загальна логіка:
      - Enums.GameState значення МАЮТЬ відповідати іменам станів FSM.
      - Player Attribute "CurrentMode" встановлюється GameStateMachine в значення з Enums.GameState.
      - GUI на клієнті керує видимістю ТІЛЬКИ через "CurrentMode".

    Контракти / правила:
      - Усі значення — унікальні рядки.
      - Enums НЕ містить логіки.
      - У персистенс не пишемо Enums (лише рядки даних).
--]]

local Enums = {}

----------------------------------------------------------------
-- FSM стани (імена станів у StateMachine)
----------------------------------------------------------------

Enums.GameState = {
	Join     = "Join",
  StationSpawn = "StationSpawn",
  Station       = "Station",
  StationExplore= "StationExploration",
  Location      = "Location",
  LocationExplore = "LocationExploration",
  RoundActive   = "RoundActive",
}

----------------------------------------------------------------
-- SpawnZone (зарезервовано)
----------------------------------------------------------------

Enums.SpawnZone = {
	Station  = "Station",
	Location = "Location",
}

----------------------------------------------------------------
-- ResumeTarget (зарезервовано)
----------------------------------------------------------------

Enums.ResumeTarget = {
	Station       = "Station",
	LocationVisit = "LocationVisit",
	ResumeRun     = "ResumeRun",
}

return Enums

----------------------------------------------------------------
-- End of script: Enums v1.2.0
----------------------------------------------------------------

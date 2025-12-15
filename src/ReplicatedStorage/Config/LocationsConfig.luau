--[[
    Тип: ModuleScript
    Назва: LocationsConfig
    Версія: 1.2.0
    Розміщення: ReplicatedStorage/LocationsConfig

    Призначення:
      Конфігурація планет/локацій для наступних спринтів (зараз — заглушка).
      У Sprint 1 НЕ використовується для спавну, бо спавн завжди на космічній станції.

    Загальна логіка:
      - Мапа планет та локацій для майбутніх меню/переходів.
      - Параметри ModelPath/SpawnName визначають шлях до моделі та імʼя SpawnLocation.

    Контракти / правила:
      - Значення — лише дані (рядки/таблиці), без логіки.
--]]

local LocationsConfig = {}

LocationsConfig.Planets = {
	Planet_01 = {
		Locations = {
			Location_001 = {
				SpawnName = "SpawnLocation",
				ModelPath = "World/Planets/Planet_01/Locations/Location_001",
			},
		},
	},
}

return LocationsConfig

----------------------------------------------------------------
-- End of script: LocationsConfig v1.2.0
----------------------------------------------------------------

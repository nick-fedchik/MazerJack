--[[
    Тип скрипта: ModuleScript
    Назва: Constants
    Версія: 2.1.0
    Розміщення: ReplicatedStorage/Shared/Constants

    Призначення:
      Єдине джерело констант для гри MazerJack.
      Всі режими гри, назви атрибутів, RemoteEvent-ів та шляхи до об'єктів.

    Контракти:
      - Тільки read-only дані
      - Використовується і на Server, і на Client
      - Жодної логіки, тільки константи
--]]

local Constants = {}

----------------------------------------------------------------
-- Game Modes
----------------------------------------------------------------

--[[
    GameMode
    Призначення:
      Визначає можливі режими гри для гравця.
      Використовується як значення атрибута CurrentMode.
--]]
Constants.GameMode = {
	Join = "Join",         -- Початковий екран входу в гру
	Station = "Station",   -- Гравець на космічній станції
	Location = "Location", -- Гравець досліджує локацію (планету)
}

----------------------------------------------------------------
-- Player Attributes (stored on Player instance)
----------------------------------------------------------------

--[[
    Attribute
    Призначення:
      Назви атрибутів які встановлюються на Player instance.
      Єдине джерело правди для стану гравця.
--]]
Constants.Attribute = {
	CurrentMode = "CurrentMode",   -- string: Join | Station | Location
	IsNewPlayer = "IsNewPlayer",   -- boolean: true якщо гравець вперше в грі
}

----------------------------------------------------------------
-- Remote Events (for Client <-> Server communication)
----------------------------------------------------------------

--[[
    RemoteEvent
    Призначення:
      Назви RemoteEvents для комунікації Client ↔ Server.
    
    Потік переходів:
      Join → Station: JoinGame
      Station → Location: GoToLocation
      Location → Station: ReturnToStation
      Any → Join: ExitGame
--]]
Constants.RemoteEvent = {
	JoinGame = "JoinGame",               -- Client → Server: гравець натиснув Join (Join → Station)
	GoToLocation = "GoToLocation",       -- Client → Server: гравець хоче на локацію (Station → Location)
	ReturnToStation = "ReturnToStation", -- Client → Server: гравець повертається на станцію (Location → Station)
	ExitGame = "ExitGame",               -- Client → Server: гравець виходить з гри (Any → Join)
}

----------------------------------------------------------------
-- Workspace Paths (for finding game objects)
----------------------------------------------------------------

--[[
    Path
    Призначення:
      Шляхи до ключових об'єктів у Workspace.
      Використовується сервером для пошуку SpawnLocation тощо.
--]]
Constants.Path = {
	StellarStation = "StellarStation",
	Modules = "StellarStation/Modules",
	CommandModule = "StellarStation/Modules/CommandModule",
	SpawnLocation = "StellarStation/Modules/CommandModule/SpawnLocation",
}

----------------------------------------------------------------
-- Game Info
----------------------------------------------------------------

--[[
    Game
    Призначення:
      Метадані гри для логування та UI.
--]]
Constants.Game = {
	Name = "MazerJack",
	Version = "2.1.0",
}

return Constants

----------------------------------------------------------------
-- End of script: Constants v2.1.0
----------------------------------------------------------------

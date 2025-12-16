--[[
    Тип скрипта: ModuleScript
    Назва: Constants
    Версія: 2.0.0
    Розміщення: ReplicatedStorage/Shared/Constants

    Призначення:
      Єдине джерело констант для гри MazerJack.
      Всі режими гри, назви атрибутів та RemoteEvent-ів.

    Контракти:
      - Тільки read-only дані
      - Використовується і на Server, і на Client
      - Жодної логіки, тільки константи
--]]

local Constants = {}

----------------------------------------------------------------
-- Game Modes
----------------------------------------------------------------

Constants.GameMode = {
	Join = "Join",       -- Початковий екран входу в гру
	Station = "Station", -- Гравець на космічній станції
	Location = "Location", -- Гравець досліджує локацію (планету)
}

----------------------------------------------------------------
-- Player Attributes (stored on Player instance)
----------------------------------------------------------------

Constants.Attribute = {
	CurrentMode = "CurrentMode", -- string: Join | Station | Location
}

----------------------------------------------------------------
-- Remote Events (for Client <-> Server communication)
----------------------------------------------------------------

Constants.RemoteEvent = {
	JoinGame = "JoinGame",         -- Client → Server: гравець натиснув Join
	GoToLocation = "GoToLocation", -- Client → Server: гравець хоче на локацію
	ExitGame = "ExitGame",         -- Client → Server: гравець виходить
}

----------------------------------------------------------------
-- Game Info
----------------------------------------------------------------

Constants.Game = {
	Name = "MazerJack",
	Version = "2.0.0",
}

return Constants

----------------------------------------------------------------
-- End of script: Constants v2.0.0
----------------------------------------------------------------

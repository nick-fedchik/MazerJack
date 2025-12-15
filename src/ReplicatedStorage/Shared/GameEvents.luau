--[[
    Тип: ModuleScript
    Назва: GameEvents
    Версія: 1.1.0
    Розміщення: ReplicatedStorage/GameEvents

    Призначення:
      Контракт подій (імена + смисл) для RemoteEvent повідомлень між Client і Server.

    Загальна логіка:
      - Усі значення подій — УНІКАЛЬНІ рядки.
      - Client і Server повинні використовувати ТІЛЬКИ ці значення.
      - Sprint 1: JoinGame (одна кнопка Join Game).

    RemoteEvent обʼєкти:
      - ReplicatedStorage/GameEvent      (RemoteEvent)  — core lifecycle
      - ReplicatedStorage/StationEvent   (RemoteEvent)  — station actions

    Події (Sprint 1):
      - JoinGame (client -> server)
          payload: nil

      - EnteredMode (server -> client)
          payload: { mode = "StateStation" | "StateLocation" | ... }

      - Notify (server -> client)
          payload: { severity = "INFO"|"WARN"|"ERROR", text = string }

    Події (зарезервовано, не використовувати у Sprint 1):
      - RequestGoLocation (client -> server)
      - RequestExitGame (client -> server)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameEvents = {}

----------------------------------------------------------------
-- Remote імена (діагностично)
----------------------------------------------------------------

GameEvents.RemoteName = "GameEvent"
GameEvents.StationRemoteName = "StationEvent"

----------------------------------------------------------------
-- Event names (UNIQUE STRINGS)
----------------------------------------------------------------

GameEvents.Event = {
	-- Sprint 1
	JoinGame          = "JoinGame",

	-- Server -> Client
	EnteredMode       = "EnteredMode",
	Notify            = "Notify",

	-- Reserved (future)
	RequestGoLocation = "RequestGoLocation",
	RequestExitGame   = "RequestExitGame",
}

----------------------------------------------------------------
-- Init log (safe)
----------------------------------------------------------------

do
	local Logger = require(ReplicatedStorage.Shared:WaitForChild("Logger"))
	local log = Logger.new("GameEvents", "1.1.0")
	log:Info("Init", "GameEvents contract loaded")
end

return GameEvents

----------------------------------------------------------------
-- End of script: GameEvents v1.1.0
----------------------------------------------------------------

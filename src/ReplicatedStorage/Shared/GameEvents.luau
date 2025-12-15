--[[
    Тип: ModuleScript
    Назва: GameEvents
    Версія: 1.2.0
  Розміщення: ReplicatedStorage/Shared/GameEvents

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
local RunService = game:GetService("RunService")

local GameEvents = {}

----------------------------------------------------------------
-- Remote імена (діагностично)
----------------------------------------------------------------

GameEvents.RemoteName = "GameEvent"
GameEvents.StationRemoteName = "StationEvent"

----------------------------------------------------------------
-- Remote resolution (server creates, client waits)
----------------------------------------------------------------

local function resolveRemote(remoteName: string): RemoteEvent
  local existing = ReplicatedStorage:FindFirstChild(remoteName)
  if existing and existing:IsA("RemoteEvent") then
    return existing
  end

  if RunService:IsServer() then
    local created = Instance.new("RemoteEvent")
    created.Name = remoteName
    created.Parent = ReplicatedStorage
    return created
  end

  return ReplicatedStorage:WaitForChild(remoteName) :: any
end

function GameEvents.GetGameRemote(): RemoteEvent
  return resolveRemote(GameEvents.RemoteName)
end

function GameEvents.GetStationRemote(): RemoteEvent
  return resolveRemote(GameEvents.StationRemoteName)
end

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
  local log = Logger.new("GameEvents", "1.2.0")
	log:Info("Init", "GameEvents contract loaded")
end

return GameEvents

----------------------------------------------------------------
-- End of script: GameEvents v1.2.0
----------------------------------------------------------------

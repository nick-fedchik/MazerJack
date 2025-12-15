--[[
    Тип: ModuleScript
    Назва: PlayerService
    Версія: 1.2.0
    Розміщення: ServerScriptService/Services/PlayerService

    Призначення:
      Оркестратор життєвого циклу гравця на сервері.

    Загальна логіка:
      - Ініціалізує runtime-атрибути
      - Завантажує Persistence
      - Блокує spawn до JoinGame
      - Виконує cleanup при виході

    Контракти / правила:
      - Persistence.Load завжди виконується
      - Spawn ЗАВЖДИ заблокований до JoinGame
--]]

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------

local Logger = require(ReplicatedStorage.Shared.Logger)

----------------------------------------------------------------
-- Module setup
----------------------------------------------------------------

local PlayerService = {}
PlayerService.__index = PlayerService

local log = Logger.new("PlayerService", "1.2.0")

----------------------------------------------------------------
-- Construction
----------------------------------------------------------------

--[[
    Функція: new
    Призначення:
      Створює новий PlayerService.
    Вхід:
      persistenceService: PersistenceService
      spawnService: PlayerSpawnService
--]]
function PlayerService.new(persistenceService, spawnService)
	local self = setmetatable({}, PlayerService)
	self._persistence = persistenceService
	self._spawn = spawnService
	return self
end

----------------------------------------------------------------
-- Player lifecycle
----------------------------------------------------------------

--[[
    Функція: InitPlayer
    Призначення:
      Повна ініціалізація гравця при вході.
    Вхід:
      player: Player
    Вихід:
      table — PlayerPersistentState
--]]
function PlayerService:InitPlayer(player)
	local fn = "InitPlayer"

	player:SetAttribute("CurrentMode", "Join")
	player:SetAttribute("IsInStation", false)
	player:SetAttribute("IsInLocation", false)

	local state = self._persistence:Load(player)

	player:SetAttribute("XP", tonumber(state.xp) or 0)

	self._spawn:SetSpawnEnabled(player, false)

	log:Info(
		fn,
		"Initialized userId=%d XP=%s",
		player.UserId,
		tostring(player:GetAttribute("XP"))
	)

	return state
end

--[[
    Функція: OnPlayerRemoving
    Призначення:
      Cleanup при виході гравця.
    Вхід:
      player: Player
--]]
function PlayerService:OnPlayerRemoving(player)
	self._persistence:OnPlayerRemoving(player)
	log:Info("OnPlayerRemoving", "Cleanup userId=%d", player.UserId)
end

return PlayerService
----------------------------------------------------------------
-- End of script: PlayerService v1.1.0
----------------------------------------------------------------

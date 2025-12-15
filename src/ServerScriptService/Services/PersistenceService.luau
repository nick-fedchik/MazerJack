--[[
    Тип: ModuleScript
    Назва: PersistenceService
    Версія: 1.2.0
    Розміщення: ServerScriptService/Services/PersistenceService

    Призначення:
      Єдиний сервіс відповідальний за довготривале збереження
      та відновлення стану гравця між ігровими сесіями.

    Загальна логіка:
      - Завантажує стан гравця при вході
      - Кешує стан в памʼяті сервера
      - Зберігає стан при виході гравця
      - Повертає завжди валідну структуру (ніколи nil)

    Контракти / правила:
      - Зберігає ЛИШЕ дані (string / number / boolean)
      - НЕ використовує Enums
      - НЕ містить логіки станів гри
      - Безпечний для Studio (DataStore API може бути вимкнений)

    Кому потрібен:
      - PlayerService
      - StateStation
      - StateLocation (у наступних спринтах)
--]]

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------

local Logger = require(ReplicatedStorage.Shared.Logger)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)

----------------------------------------------------------------
-- Module setup
----------------------------------------------------------------

local PersistenceService = {}
PersistenceService.__index = PersistenceService

local log = Logger.new("PersistenceService", "1.2.0")

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

--[[
    Функція: nowUnix
    Призначення:
      Повертає поточний час у Unix-форматі.
    Вихід:
      number
--]]
local function nowUnix()
	return os.time()
end

--[[
    Функція: defaultState
    Призначення:
      Створює початковий стан для нового гравця.
    Вихід:
      table — PlayerPersistentState
--]]
local function defaultState()
	return {
		schemaVersion  = GameConfig.PersistentSchemaVersion,
		xp             = 0,
		lastMode       = "Station",
		lastSpawnZone  = "Station",
		lastLocationId = nil,
		updatedAtUnix  = nowUnix(),
	}
end

----------------------------------------------------------------
-- Construction
----------------------------------------------------------------

--[[
    Функція: new
    Призначення:
      Створює новий екземпляр PersistenceService.
    Вихід:
      PersistenceService
--]]
function PersistenceService.new()
	local self = setmetatable({}, PersistenceService)
	self._store = DataStoreService:GetDataStore(GameConfig.DataStoreName)
	self._cache = {} -- [userId] = state
	return self
end

----------------------------------------------------------------
-- Internal helpers
----------------------------------------------------------------

--[[
    Функція: _keyForUser
    Призначення:
      Формує ключ DataStore для конкретного гравця.
    Вхід:
      userId: number
    Вихід:
      string
--]]
function PersistenceService:_keyForUser(userId)
	return GameConfig.DataStoreKeyPrefix .. tostring(userId)
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--[[
    Функція: Load
    Призначення:
      Завантажує стан гравця з DataStore або створює дефолтний.
    Вхід:
      player: Player
    Вихід:
      table — PlayerPersistentState
--]]
function PersistenceService:Load(player)
	local fn = "Load"
	local key = self:_keyForUser(player.UserId)

	local ok, data = pcall(function()
		return self._store:GetAsync(key)
	end)

	local state

	if not ok or type(data) ~= "table" then
		state = defaultState()
		self._cache[player.UserId] = state

		if not ok then
			log:Warn(fn, "GetAsync failed, defaults used userId=%d", player.UserId)
		else
			log:Info(fn, "New player initialized userId=%d", player.UserId)
		end

		return state
	end

	state = defaultState()
	for k, v in pairs(data) do
		state[k] = v
	end

	state.updatedAtUnix = nowUnix()
	self._cache[player.UserId] = state

	log:Info(
		fn,
		"Loaded userId=%d xp=%d lastMode=%s",
		player.UserId,
		tonumber(state.xp) or 0,
		tostring(state.lastMode)
	)

	return state
end

--[[
    Функція: GetCached
    Призначення:
      Повертає кешований стан гравця.
    Вхід:
      player: Player
    Вихід:
      table — PlayerPersistentState
--]]
function PersistenceService:GetCached(player)
	local fn = "GetCached"
	local state = self._cache[player.UserId]

	if not state then
		state = defaultState()
		self._cache[player.UserId] = state
		log:Warn(fn, "Cache miss, default created userId=%d", player.UserId)
	end

	return state
end

--[[
    Функція: Save
    Призначення:
      Зберігає стан гравця у DataStore.
    Вхід:
      player: Player
      state: table | nil
    Вихід:
      boolean — успіх/невдача
--]]
function PersistenceService:Save(player, state)
	local fn = "Save"
	local s = state or self._cache[player.UserId]
	if not s then return false end

	s.schemaVersion = GameConfig.PersistentSchemaVersion
	s.updatedAtUnix = nowUnix()

	local ok, err = pcall(function()
		self._store:SetAsync(self:_keyForUser(player.UserId), s)
	end)

	if not ok then
		if RunService:IsStudio() then
			log:Warn(fn, "Save skipped (Studio) userId=%d", player.UserId)
			return false
		end
		log:Error(fn, "Save failed userId=%d err=%s", player.UserId, tostring(err))
		return false
	end

	log:Info(fn, "Saved userId=%d xp=%d", player.UserId, tonumber(s.xp) or 0)
	return true
end

--[[
    Функція: OnPlayerRemoving
    Призначення:
      Автозбереження стану при виході гравця.
    Вхід:
      player: Player
--]]
function PersistenceService:OnPlayerRemoving(player)
	local state = self._cache[player.UserId]
	if state then
		self:Save(player, state)
	end
end

return PersistenceService
----------------------------------------------------------------
-- End of script: PersistenceService v1.2.0
----------------------------------------------------------------

--[[
    Тип: ModuleScript
    Назва: StationContextService
	Версія: 1.2.1
    Розміщення: ServerScriptService/Services/StationContextService

    Призначення:
      Відстежує, в якому модулі/шлюзі Космічної Станції знаходиться гравець.
      Пише авторитетний runtime-контекст у Player Attributes.

    Загальна логіка:
      - Працює ТІЛЬКИ коли Player.CurrentMode == "Station"
      - Встановлює:
          CurrentStationModule: string?
          CurrentStationGate: string?
      - Базова реалізація використовує події Touched на частинах станції:
          StellarStation/Modules/<ModuleName>/** (BasePart)
          StellarStation/Gateways/<GateName>/** (BasePart)
      - На дотик до модуля: оновлює CurrentStationModule і очищає CurrentStationGate
	  - На дотик до шлюза: оновлює CurrentStationGate (модуль не змінює)
	  - Gateway model може мати Attribute GateLocked: boolean
		  true  => locked (лог спроби входу)
		  false => auto/unlocked (лог спроби входу)

    Взаємодія / контракти:
      - Викликається зі StateStation:OnEnter, щоб виставити стартовий модуль.
      - Не використовує Remotes.
      - Не виконує spawn.

    Архітектурні правила:
      - НЕ залежить від UI.
      - НЕ вимагає спеціальних "Zone" Part'ів; працює з реальними частинами моделей.
      - Якщо StellarStation або папки Modules/Gateways відсутні — лог і graceful no-op.
--]]

----------------------------------------------------------------
-- Services
----------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------

local Logger = require(ReplicatedStorage.Shared.Logger)
local Enums = require(ReplicatedStorage.Shared.Enums)

----------------------------------------------------------------
-- Module setup
----------------------------------------------------------------

local StationContextService = {}
StationContextService.__index = StationContextService

local log = Logger.new("StationContextService", "1.2.1")

local ATTR_MODE = "CurrentMode"
local ATTR_MODULE = "CurrentStationModule"
local ATTR_GATE = "CurrentStationGate"

local GATE_ATTR_LOCKED = "GateLocked"

----------------------------------------------------------------
-- Helpers (private)
----------------------------------------------------------------

-- Function: getPlayerFromTouchedPart
-- Призначення:
--   Визначає Player по частині персонажа, яка торкнулась елемента станції.
-- Вхідні параметри:
--   otherPart: BasePart
-- Вихід:
--   Player? | nil
-- Хто використовує:
--   StationContextService (Touched handlers)
local function getPlayerFromTouchedPart(otherPart: Instance)
	if not otherPart or not otherPart.Parent then
		return nil
	end

	local character = otherPart.Parent
	local player = Players:GetPlayerFromCharacter(character)
	return player
end

-- Function: resolveDirectChildName
-- Призначення:
--   Підіймається по ancestry і повертає ім'я direct-child під заданим container.
-- Вхідні параметри:
--   instance: Instance
--   container: Instance
-- Вихід:
--   string? | nil
-- Хто використовує:
--   resolveModuleName / resolveGateName
local function resolveDirectChildInstance(instance: Instance, container: Instance)
	local current = instance
	while current and current.Parent do
		if current.Parent == container then
			return current
		end
		current = current.Parent
	end
	return nil
end

-- Exposed for tests and reuse.
function StationContextService.ResolveDirectChildInstance(instance: Instance, container: Instance)
	return resolveDirectChildInstance(instance, container)
end

-- Exposed for tests and runtime: ensures GateLocked exists and returns it.
function StationContextService.GetOrInitGateLocked(gateModel: Instance, defaultLocked: boolean?)
	local v = gateModel:GetAttribute(GATE_ATTR_LOCKED)
	if type(v) == "boolean" then
		return v
	end

	local init = defaultLocked
	if init == nil then
		init = true
	end

	gateModel:SetAttribute(GATE_ATTR_LOCKED, init)
	return init
end

----------------------------------------------------------------
-- Construction
----------------------------------------------------------------

-- Function: new
-- Призначення:
--   Створює StationContextService та підключається до структури станції (якщо є).
-- Вхідні параметри:
--   none
-- Вихід:
--   StationContextService
-- Хто використовує:
--   MainServer
function StationContextService.new()
	local self = setmetatable({}, StationContextService)

	self._station = nil :: Instance?
	self._modules = nil :: Instance?
	self._gateways = nil :: Instance?
	self._hookedParts = {} :: { [Instance]: boolean }
	self._connections = {} :: { RBXScriptConnection }

	self:_bindWhenReady()

	return self
end

----------------------------------------------------------------
-- Internal binding
----------------------------------------------------------------

-- Function: _bindWhenReady
-- Призначення:
--   Знаходить StellarStation та підключає Touched listeners.
-- Вхідні параметри:
--   none
-- Вихід / ефект:
--   Підключає внутрішні connections
-- Хто використовує:
--   StationContextService.new
function StationContextService:_bindWhenReady()
	local fn = "Bind"

	local function tryBind()
		local station = workspace:FindFirstChild("StellarStation")
		if not station then
			return false
		end

		self._station = station
		self._modules = station:FindFirstChild("Modules")
		self._gateways = station:FindFirstChild("Gateways")

		if not self._modules then
			log:Warn(fn, "StellarStation.Modules missing")
		else
			self:_hookFolder(self._modules, "Modules")
		end

		if not self._gateways then
			log:Warn(fn, "StellarStation.Gateways missing")
		else
			self:_hookFolder(self._gateways, "Gateways")
		end

		log:Info(fn, "StationContextService bound")
		return true
	end

	if tryBind() then
		return
	end

	log:Warn(fn, "StellarStation not found (will bind later)")

	table.insert(
		self._connections,
		workspace.ChildAdded:Connect(function(child)
			if child.Name == "StellarStation" then
				tryBind()
			end
		end)
	)
end

-- Function: _hookFolder
-- Призначення:
--   Хукає всі BasePart у папці і стежить за новими.
-- Вхідні параметри:
--   folder: Instance
--   kind: string ("Modules"|"Gateways")
-- Вихід / ефект:
--   Додає connections
-- Хто використовує:
--   _bindWhenReady
function StationContextService:_hookFolder(folder: Instance, kind: string)
	local fn = "HookFolder"

	for _, inst in folder:GetDescendants() do
		if inst:IsA("BasePart") then
			self:_hookPart(inst, kind)
		end
	end

	table.insert(
		self._connections,
		folder.DescendantAdded:Connect(function(inst)
			if inst:IsA("BasePart") then
				self:_hookPart(inst, kind)
			end
		end)
	)

	log:Info(fn, "Hooked %s parts", kind)
end

-- Function: _hookPart
-- Призначення:
--   Підключає Touched handler до BasePart станції.
-- Вхідні параметри:
--   part: BasePart
--   kind: string
-- Вихід / ефект:
--   Реєструє part в _hookedParts і створює connection
-- Хто використовує:
--   _hookFolder
function StationContextService:_hookPart(part: BasePart, kind: string)
	if self._hookedParts[part] then
		return
	end
	self._hookedParts[part] = true

	table.insert(
		self._connections,
		part.Touched:Connect(function(otherPart)
			self:_onTouched(kind, part, otherPart)
		end)
	)
end

-- Function: _onTouched
-- Призначення:
--   Обробляє торкання частини станції частиною персонажа.
-- Вхідні параметри:
--   kind: string
--   stationPart: BasePart
--   otherPart: BasePart
-- Вихід / ефект:
--   Оновлює Player Attributes
-- Хто використовує:
--   _hookPart
function StationContextService:_onTouched(kind: string, stationPart: BasePart, otherPart: BasePart)
	local fn = "OnTouched"

	local player = getPlayerFromTouchedPart(otherPart)
	if not player then
		return
	end

	-- Only track station context while the player is in Station mode.
	if player:GetAttribute(ATTR_MODE) ~= Enums.GameState.Station then
		return
	end

	if kind == "Modules" and self._modules then
		local moduleInst = resolveDirectChildInstance(stationPart, self._modules)
		if moduleInst then
			self:SetPlayerModule(player, moduleInst.Name)
			-- When a module is known, player is no longer "in gate".
			self:SetPlayerGate(player, nil)
		end
		return
	end

	if kind == "Gateways" and self._gateways then
		local gateInst = resolveDirectChildInstance(stationPart, self._gateways)
		if gateInst then
			local gateName = gateInst.Name
			local locked = StationContextService.GetOrInitGateLocked(gateInst)
			self:SetPlayerGate(player, gateName)
			log:Info(fn, "userId=%d gate=%s attemptEnter locked=%s", player.UserId, gateName, tostring(locked))
		end
	end
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

-- Function: OnEnterStation
-- Призначення:
--   Викликається при переході гравця в Station, щоб виставити стартовий контекст.
-- Вхідні параметри:
--   player: Player
-- Вихід / ефект:
--   Ставить CurrentStationModule="CommandModule" (як MVP default), очищає gate
-- Хто використовує:
--   StateStation:OnEnter
function StationContextService:OnEnterStation(player: Player)
	local fn = "OnEnterStation"

	-- Default module for MVP: CommandModule (spawn is inside it).
	self:SetPlayerModule(player, "CommandModule")
	self:SetPlayerGate(player, nil)

	log:Info(fn, "userId=%d module=%s", player.UserId, tostring(player:GetAttribute(ATTR_MODULE)))
end

-- Function: OnExitStation
-- Призначення:
--   Викликається при виході зі стану Station.
-- Вхідні параметри:
--   player: Player
-- Вихід / ефект:
--   Очищає station-атрибути
-- Хто використовує:
--   StateStation:OnExit
function StationContextService:OnExitStation(player: Player)
	self:SetPlayerGate(player, nil)
	self:SetPlayerModule(player, nil)
end

-- Function: SetPlayerModule
-- Призначення:
--   Ставить атрибут поточного модуля, якщо змінився.
-- Вхідні параметри:
--   player: Player
--   moduleName: string?
-- Вихід / ефект:
--   Player:SetAttribute(CurrentStationModule, ...)
-- Хто використовує:
--   Service internal + StateStation
function StationContextService:SetPlayerModule(player: Player, moduleName: string?)
	local prev = player:GetAttribute(ATTR_MODULE)
	if prev == moduleName then
		return
	end

	player:SetAttribute(ATTR_MODULE, moduleName)
	log:Info("SetPlayerModule", "userId=%d module=%s", player.UserId, tostring(moduleName))
end

-- Function: SetPlayerGate
-- Призначення:
--   Ставить атрибут поточного шлюза, якщо змінився.
-- Вхідні параметри:
--   player: Player
--   gateName: string?
-- Вихід / ефект:
--   Player:SetAttribute(CurrentStationGate, ...)
-- Хто використовує:
--   Service internal + StateStation
function StationContextService:SetPlayerGate(player: Player, gateName: string?)
	local prev = player:GetAttribute(ATTR_GATE)
	if prev == gateName then
		return
	end

	player:SetAttribute(ATTR_GATE, gateName)
	log:Info("SetPlayerGate", "userId=%d gate=%s", player.UserId, tostring(gateName))
end

return StationContextService

----------------------------------------------------------------
-- End of script: StationContextService v1.2.1
----------------------------------------------------------------

--[[
    Тип: ModuleScript
    Назва: StateJoin
    Версія: 1.2.0
    Розміщення: ServerScriptService/StateMachine/StateJoin

    Призначення:
      Початковий стан гри.
      Гравець бачить JoinGameGui та НЕ присутній у світі.

    Загальна логіка:
      - Spawn завжди вимкнений
      - Жодного LoadCharacter
      - Очікування JoinGame
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

local StateJoin = {}
StateJoin.__index = StateJoin

local log = Logger.new("StateJoin", "1.2.0")

----------------------------------------------------------------
-- Construction
----------------------------------------------------------------

function StateJoin.new(machine, services)
	local self = setmetatable({}, StateJoin)
	self.Name = "Join"
	self._services = services
	return self
end

----------------------------------------------------------------
-- Lifecycle
----------------------------------------------------------------

--[[
    Функція: OnEnter
    Призначення:
      Вхід у Join-стан.
    Вхід:
      player: Player
--]]
function StateJoin:OnEnter(player)
	log:Info("OnEnter", "Join state entered userId=%d", player.UserId)

	self._services.PlayerSpawnService:SetSpawnEnabled(player, false)
	player:SetAttribute("IsInStation", false)
	player:SetAttribute("IsInLocation", false)
end

return StateJoin
----------------------------------------------------------------
-- End of script: StateJoin v1.1.0
----------------------------------------------------------------

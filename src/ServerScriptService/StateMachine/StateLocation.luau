--[[
    Тип: ModuleScript
    Назва: StateLocation
    Версія: 1.1.0
    Розміщення: ServerScriptService/StateMachine/StateLocation

    Призначення:
      Заглушка для Sprint 2+.
      У Sprint 1 НЕ використовується.

    Примітка:
      Навмисно не реалізує spawn.
--]]

----------------------------------------------------------------
-- Module setup
----------------------------------------------------------------

local StateLocation = {}
StateLocation.__index = StateLocation

function StateLocation.new()
	local self = setmetatable({}, StateLocation)
	self.Name = "Location"
	return self
end

return StateLocation
----------------------------------------------------------------
-- End of script: StateLocation v1.1.0
----------------------------------------------------------------

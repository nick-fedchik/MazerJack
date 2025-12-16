--[[
    Тип скрипта: ModuleScript
    Назва: Logger
    Версія: 2.1.0
    Розміщення: ReplicatedStorage/Shared/Logger

    Призначення:
      Уніфікований логгер для Client і Server частин гри MazerJack.
      Забезпечує стабільний, безпечний і читабельний лог у форматі:

        [SEVERITY][ModuleName Version][FunctionName] Message

    Загальна логіка:
      - Logger.new(...) створює окремий екземпляр логгера для модуля
      - Форматування повідомлень є fault-tolerant
      - Logger НІКОЛИ не кидає runtime-помилки
      - Конструктор логгера сам повідомляє, що ініціалізувався коректно

    Контракти та правила:
      - Logger не знає про GameState, Player або Services
      - Logger не логує GameVersion (це робить MainServer один раз)
      - Logger дозволений до використання ВСЮДИ
--]]

----------------------------------------------------------------
-- Module table
----------------------------------------------------------------

local Logger = {}
Logger.__index = Logger

----------------------------------------------------------------
-- Internal helpers
----------------------------------------------------------------

--[[
    fmt(formatStr, ...)
    Призначення:
      Безпечне форматування лог-повідомлень.

    Вхідні параметри:
      formatStr (any) — рядок формату або будь-що
      ... (vararg)    — аргументи для string.format

    Вихід:
      string — відформатований або fallback-рядок

    Гарантії:
      - НІКОЛИ не кидає помилку
      - Коректно працює без vararg
      - Захищений від помилок string.format
--]]
local function fmt(formatStr, ...)
	if select("#", ...) == 0 then
		return tostring(formatStr)
	end

	local args = { ... }

	local ok, result = pcall(function()
		return string.format(tostring(formatStr), unpack(args))
	end)

	if ok then
		return result
	end

	-- Fallback у випадку помилки форматування
	return tostring(formatStr)
end

--[[
    prefix(level, moduleName, moduleVersion, funcName)
    Призначення:
      Формує стандартизований префікс лог-повідомлення.

    Вхідні параметри:
      level (string)          — INFO | WARN | ERROR
      moduleName (string)     — назва модуля
      moduleVersion (string)  — версія модуля
      funcName (string|nil)   — назва функції

    Вихід:
      string — сформований префікс
--]]
local function prefix(level, moduleName, moduleVersion, funcName)
	return string.format(
		"[%s][%s %s][%s]",
		level,
		tostring(moduleName),
		tostring(moduleVersion),
		tostring(funcName or "?")
	)
end

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------

--[[
    Logger.new(moduleName, moduleVersion)
    Призначення:
      Створює екземпляр логгера для конкретного модуля.

    Вхідні параметри:
      moduleName (string)    — логічна назва модуля
      moduleVersion (string) — версія модуля

    Вихід:
      Logger — готовий до використання логгер

    Побічні ефекти:
      - Одноразово логує INFO про успішну ініціалізацію
--]]
function Logger.new(moduleName, moduleVersion)
	local self = setmetatable({}, Logger)

	self.ModuleName = tostring(moduleName or "UnknownModule")
	self.ModuleVersion = tostring(moduleVersion or "0.0.0")

	return self
end

----------------------------------------------------------------
-- Public logging API
----------------------------------------------------------------

--[[
    Logger:Info(funcName, formatStr, ...)
    Призначення:
      Лог повідомлення рівня INFO
--]]
function Logger:Info(funcName, formatStr, ...)
	print(
		prefix("INFO", self.ModuleName, self.ModuleVersion, funcName),
		fmt(formatStr, ...)
	)
end

--[[
    Logger:Warn(funcName, formatStr, ...)
    Призначення:
      Лог повідомлення рівня WARN
--]]
function Logger:Warn(funcName, formatStr, ...)
	warn(
		prefix("WARN", self.ModuleName, self.ModuleVersion, funcName),
		fmt(formatStr, ...)
	)
end

--[[
    Logger:Error(funcName, formatStr, ...)
    Призначення:
      Лог повідомлення рівня ERROR
--]]
function Logger:Error(funcName, formatStr, ...)
	warn(
		prefix("ERROR", self.ModuleName, self.ModuleVersion, funcName),
		fmt(formatStr, ...)
	)
end

----------------------------------------------------------------
-- Module return
----------------------------------------------------------------

return Logger

----------------------------------------------------------------
-- End of script: Logger v1.1.0
----------------------------------------------------------------

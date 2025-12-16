--[[
    Тип скрипта: ModuleScript
    Назва: Events
    Версія: 2.0.0
    Розміщення: ReplicatedStorage/Shared/Events

    Призначення:
      Централізоване створення та доступ до RemoteEvents.
      Гарантує що Server і Client використовують одні й ті ж події.

    Контракти:
      - Server викликає Events.Init() один раз при старті
      - Client викликає Events.WaitForReady() перед використанням
      - Обидва використовують Events.Get(name) для доступу до подій
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(script.Parent.Constants)

local Events = {}

----------------------------------------------------------------
-- Private state
----------------------------------------------------------------

local eventsFolder: Folder? = nil

----------------------------------------------------------------
-- Server-side initialization
----------------------------------------------------------------

--[[
    Events.Init()
    Призначення:
      Створює папку Events та всі RemoteEvents.
      ТІЛЬКИ для Server.

    Вихід:
      nil

    Побічні ефекти:
      - Створює ReplicatedStorage/Events з RemoteEvents
--]]
function Events.Init()
	-- Create folder
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "Events"
	eventsFolder.Parent = ReplicatedStorage

	-- Create all RemoteEvents from Constants
	for _, eventName in pairs(Constants.RemoteEvent) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = eventName
		remote.Parent = eventsFolder
	end
end

----------------------------------------------------------------
-- Client-side initialization
----------------------------------------------------------------

--[[
    Events.WaitForReady(timeout)
    Призначення:
      Очікує поки папка Events буде доступна.
      ТІЛЬКИ для Client.

    Вхідні параметри:
      timeout (number?) — максимальний час очікування (default: 10)

    Вихід:
      boolean — true якщо готово, false якщо timeout
--]]
function Events.WaitForReady(timeout: number?): boolean
	local maxWait = timeout or 10
	eventsFolder = ReplicatedStorage:WaitForChild("Events", maxWait)
	return eventsFolder ~= nil
end

----------------------------------------------------------------
-- Get event (works on both Server and Client)
----------------------------------------------------------------

--[[
    Events.Get(eventName)
    Призначення:
      Повертає RemoteEvent за назвою.

    Вхідні параметри:
      eventName (string) — назва з Constants.RemoteEvent

    Вихід:
      RemoteEvent | nil
--]]
function Events.Get(eventName: string): RemoteEvent?
	if not eventsFolder then
		eventsFolder = ReplicatedStorage:FindFirstChild("Events")
	end
	
	if eventsFolder then
		return eventsFolder:FindFirstChild(eventName) :: RemoteEvent?
	end
	
	return nil
end

return Events

----------------------------------------------------------------
-- End of script: Events v2.0.0
----------------------------------------------------------------

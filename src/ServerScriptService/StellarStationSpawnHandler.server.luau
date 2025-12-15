--[[
	Тип: Script
	Назва: StellarStationSpawnHandler
	Версія: 1.1.0
	Розміщення: ServerScriptService/StellarStationSpawnHandler

	Призначення:
	  Тимчасовий handler для позиціонування персонажа у PassengerRoom після спавну.

	Загальна логіка:
	  - Слухає `Player.CharacterAdded` та переміщує HumanoidRootPart до SpawnLocation

	Взаємодія / контракти:
	  - Тимчасовий скрипт; рекомендується делегувати spawn у `PlayerSpawnService`

	Архітектурні правила:
	  - НЕ змінює PlayerSpawnService поведінку — тільки позиціонує персонаж
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
local log = Logger.new("StellarStationSpawnHandler", "1.1.0")

local stellarStation = workspace:FindFirstChild("StellarStation")

----------------------------------------------------------------
-- Function: onPlayerAdded
-- Призначення:
--   Слухає `CharacterAdded` для гравця та позиціонує персонажа у PassengerRoom SpawnLocation
-- Вхідні параметри:
--   player: Player — гравець
-- Вихід / ефект:
--   Позиціює `HumanoidRootPart` гравця біля SpawnLocation (якщо є)
-- Хто використовує:
--   Локальний ServerScriptService
----------------------------------------------------------------
local function onPlayerAdded(player)
	-- Wait for the player to spawn their character
	player.CharacterAdded:Connect(function(character)
		-- Find the Passenger Room
		local passengerRoom = stellarStation and stellarStation:FindFirstChild("PassengerRoom")
		if passengerRoom then
			-- Find the spawn location in the passenger room
			local spawnLocation = passengerRoom:FindFirstChild("SpawnLocation")
			if spawnLocation then
				-- Move the character to the spawn location
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
				if humanoidRootPart then
					humanoidRootPart.CFrame = spawnLocation.CFrame * CFrame.new(0, 2, 0)
					log:Info("onPlayerAdded", "Positioned character for userId=%d", player.UserId)
				end
			end
		end
	end)
end

-- Connect to new players joining
Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle players already in the game
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

----------------------------------------------------------------
-- End of script: StellarStationSpawnHandler v1.1.0
----------------------------------------------------------------
-- First Person Camera Controller for StellarStation
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

-- Налаштування камери від першої особи
local CAMERA_OFFSET = Vector3.new(0, 1.5, 0) -- Висота камери відносно HumanoidRootPart
local CAMERA_SMOOTHNESS = 0.1 -- Плавність руху камери

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character = player.Character
local humanoid = character and character:FindFirstChild("Humanoid")
local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

-- Функція для налаштування камери
local function setupFirstPersonCamera()
	if not character then return end
	
	-- Встановлюємо камеру в режим від першої особи
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70 -- Поле зору для першої особи
	
	-- Приховуємо голову персонажа для кращого виду від першої особи
	local head = character:FindFirstChild("Head")
	if head then
		-- Змінюємо прозорість голови
		head.LocalTransparencyModifier = 1
	end
end

-- Оновлення позиції камери
local function updateCamera()
	if not character or not humanoidRootPart or not humanoid then return end
	
	-- Отримуємо напрямок руху
	local moveDirection = humanoid.MoveDirection
	
	-- Якщо гравець рухається, орієнтуємо камеру в напрямку руху
	if moveDirection.Magnitude > 0.1 then
		-- Плавно повертаємо камеру в напрямку руху
		local targetCFrame = CFrame.new(
			humanoidRootPart.Position + CAMERA_OFFSET,
			humanoidRootPart.Position + CAMERA_OFFSET + moveDirection
		)
		
		-- Плавний перехід до цільової позиції
		camera.CFrame = camera.CFrame:Lerp(targetCFrame, CAMERA_SMOOTHNESS)
	else
		-- Якщо гравець не рухається, камера залишається в поточній позиції
		local currentCFrame = camera.CFrame
		local newPosition = humanoidRootPart.Position + CAMERA_OFFSET
		camera.CFrame = CFrame.new(newPosition, newPosition + currentCFrame.LookVector)
	end
end

-- Обробка зміни персонажа
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:FindFirstChild("Humanoid")
	humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	-- Чекаємо невеликий час, щоб персонаж повністю завантажився
	task.wait(0.1)
	setupFirstPersonCamera()
end)

-- Підключення до оновлення кадрів
RunService.RenderStepped:Connect(updateCamera)

-- Початкове налаштування
setupFirstPersonCamera()

-- Вимикаємо стандартну камеру Roblox
StarterPlayer.CameraMode = Enum.CameraMode.LockFirstPerson

print("First Person Camera Controller initialized")
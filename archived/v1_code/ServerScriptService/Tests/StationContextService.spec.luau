local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage.Shared.Enums)

local StationContextService = require(script.Parent.Parent.Services.StationContextService)
local TestUtil = require(script.Parent.TestUtil)

local function run()
	local svc = setmetatable({}, StationContextService)
	local player = TestUtil.makeFakePlayer(456)

	player:SetAttribute("CurrentMode", Enums.GameState.Station)
	svc:OnEnterStation(player)
	TestUtil.assertEqual(player:GetAttribute("CurrentStationModule"), "CommandModule")
	TestUtil.assertEqual(player:GetAttribute("CurrentStationGate"), nil)

	-- GateLocked attribute contract
	local gateways = Instance.new("Folder")
	gateways.Name = "Gateways"

	local gateModel = Instance.new("Model")
	gateModel.Name = "MainGate"
	gateModel.Parent = gateways

	local trigger = Instance.new("Part")
	trigger.Name = "Trigger"
	trigger.Parent = gateModel

	local resolved = StationContextService.ResolveDirectChildInstance(trigger, gateways)
	TestUtil.assertEqual(resolved, gateModel, "ResolveDirectChildInstance should return gate model")

	-- Default to locked=true when missing
	local locked = StationContextService.GetOrInitGateLocked(gateModel)
	TestUtil.assertTrue(locked, "Gate should default to locked")
	TestUtil.assertTrue(gateModel:GetAttribute("GateLocked") == true, "GateLocked attribute must be set")

	gateModel:SetAttribute("GateLocked", false)
	TestUtil.assertFalse(StationContextService.GetOrInitGateLocked(gateModel), "GateLocked=false should be respected")
end

return {
	run = run,
}

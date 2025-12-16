local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage.Shared.Enums)

local GameStateMachine = require(script.Parent.Parent.StateMachine.GameStateMachine)
local TestUtil = require(script.Parent.TestUtil)

local function run()
	local calls = {}

	local states = {
		[Enums.GameState.Join] = {
			new = function()
				return {
					Name = Enums.GameState.Join,
					OnEnter = function(_, player)
						table.insert(calls, "Join:Enter:" .. player.UserId)
					end,
					OnExit = function(_, player)
						table.insert(calls, "Join:Exit:" .. player.UserId)
					end,
				}
			end,
		},
		[Enums.GameState.Station] = {
			new = function(machine)
				return {
					Name = Enums.GameState.Station,
					OnEnter = function(_, player)
						table.insert(calls, "Station:Enter:" .. player.UserId)
						-- Re-entrant transition must be blocked by lock
						local ok = machine:SetState(player, Enums.GameState.Join)
						TestUtil.assertFalse(ok, "Expected re-entrant transition to be blocked")
					end,
					OnExit = function(_, player)
						table.insert(calls, "Station:Exit:" .. player.UserId)
					end,
				}
			end,
		},
	}

	local fakeRemote = Instance.new("RemoteEvent")
	local gsm = GameStateMachine.new(states, {}, fakeRemote)
	local player = TestUtil.makeFakePlayer(123)

	TestUtil.assertTrue(gsm:SetState(player, Enums.GameState.Join), "Join transition should succeed")
	TestUtil.assertEqual(player:GetAttribute("CurrentMode"), Enums.GameState.Join, "CurrentMode must be set")

	TestUtil.assertTrue(gsm:SetState(player, Enums.GameState.Station), "Station transition should succeed")
	TestUtil.assertEqual(player:GetAttribute("CurrentMode"), Enums.GameState.Station, "CurrentMode must be updated")

	-- Order sanity: Join enter, Join exit, Station enter
	TestUtil.assertEqual(calls[1], "Join:Enter:123")
	TestUtil.assertEqual(calls[2], "Join:Exit:123")
	TestUtil.assertEqual(calls[3], "Station:Enter:123")
end

return {
	run = run,
}

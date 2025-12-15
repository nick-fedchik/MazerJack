local RunService = game:GetService("RunService")
local TestService = game:GetService("TestService")

if not RunService:IsStudio() then
	return
end

local tests = {
	require(script.Parent["GameStateMachine.spec"]),
	require(script.Parent["StationContextService.spec"]),
}

local passed = 0
local failed = 0

for _, t in ipairs(tests) do
	local ok, err = pcall(function()
		t.run()
	end)
	if ok then
		passed += 1
	else
		failed += 1
		TestService:Error("[Tests] " .. tostring(err))
	end
end

if failed > 0 then
	TestService:Error(("[Tests] FAILED %d/%d"):format(failed, passed + failed))
else
	TestService:Message(("[Tests] OK %d"):format(passed))
end

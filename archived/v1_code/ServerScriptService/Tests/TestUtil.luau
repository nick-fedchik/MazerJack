local TestUtil = {}

function TestUtil.assertEqual(actual, expected, message)
	if actual ~= expected then
		error((message or "assertEqual failed") .. (" (expected=%s actual=%s)"):format(tostring(expected), tostring(actual)), 2)
	end
end

function TestUtil.assertTrue(value, message)
	if value ~= true then
		error(message or "assertTrue failed", 2)
	end
end

function TestUtil.assertFalse(value, message)
	if value ~= false then
		error(message or "assertFalse failed", 2)
	end
end

function TestUtil.makeFakePlayer(userId)
	local attrs = {}
	local player = {
		UserId = userId,
		SetAttribute = function(_, key, value)
			attrs[key] = value
		end,
		GetAttribute = function(_, key)
			return attrs[key]
		end,
		_testAttrs = attrs,
	}
	return player
end

return TestUtil

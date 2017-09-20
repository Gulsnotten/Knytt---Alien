-- This file deals with errors. On Error event of XLua is broken.

local DoCall = DoCall
local xpcall = xpcall
local tostring = tostring
local unpack = unpack
local traceback = debug.traceback

local function errorf(s)
	s = traceback(tostring(s), 2)
	print(s)
	return s
end

local function check(code, ...)
	if code then
		return ...
	else
		return DoCall("Error", tostring(...))
	end
end

check(xpcall(function()  dofile(AppPath.."Data/Lua/main.lua")  end, errorf))

-- create wrappers for all functions called from MMF that would call "Error" function
local NeedFast = {
	_internal_0_32 = true,
	_internal_AddObject = true,
	_internal_CanCreateObject = true,
	_internal_OnCheckObstacleOverlap = true,
}

for k, v in pairs(_G) do
	if type(k) == "string" and k:sub(1, 10) == "_internal_" and not NeedFast[k] then
		_G[k] = function(...)
			local t = {...}
			return check(xpcall(function() return v(unpack(t)) end, errorf))
		end
	end
end


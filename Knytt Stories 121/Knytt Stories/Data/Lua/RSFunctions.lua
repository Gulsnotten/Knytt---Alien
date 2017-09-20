local type = type
local unpack = unpack
local error
local assert = assert
local string_format = string.format
local string_byte = string.byte
local string_sub = string.sub

local next = next
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local rawget = rawget
local rawset = rawset
local getfenv = getfenv
local setfenv = setfenv
local pcall = pcall
local xpcall = xpcall
local pcall2
local getmetatable = debug.getmetatable
local d_setmetatable = debug.setmetatable
local os_time = os.time
local debug_getinfo = debug.getinfo
local loadfile = loadfile
local loadstring = loadstring
local table_insert = table.insert
local table_remove = table.remove
local table_concat = table.concat
local math_min = math.min
local math_floor = math.floor
local math_ceil = math.ceil
local abs = math.abs
local coroutine_yield = coroutine.yield
local io_open = io.open
local select = select

--------- table

local function table_swap(t, min, max)
	min = min or 1
	max = max or #t
	for i = 1, (max - min + 1):div(2) do
		t[min], t[max] = t[max], t[min]
		min, max = min + 1, max + 1
	end
end
table.swap = table_swap

local function table_move(t, from, to)
	local it = t[from]
	if from < to then
		for i = from, to - 1 do
			t[i] = t[i+1]
		end
	elseif from > to then
		for i = from, to + 1, -1 do
			t[i] = t[i-1]
		end
	end
	t[to] = it
end
table.move = table_move

function table.copy(src, dest, overwrite)
	if not dest or overwrite then
		dest = dest or {}
		for k,v in pairs(src) do
			dest[k] = v
		end
	else
		for k,v in pairs(src) do
			if dest[k] == nil then
				dest[k] = v
			end
		end
	end
	return dest
end

function table.find(t, v0)
	for k, v in pairs(t) do
		if v == v0 then
			return k
		end
	end
end

function table.ifind(t, v0)
	local k = 1
	local v = rawget(t, k)
	while v ~= nil do
		if v == v0 then
			return k
		end
		k = k + 1
		v = rawget(t, k)
	end
end

function table.invert(t, out)
	local out = out or {}
	for k, v in pairs(t) do
		out[v] = k
	end
	return out
end

--------- coroutine

function coroutine.yieldN(n, ...)
	if n >= 1 then
		for i = 2, n do
			coroutine_yield(...)
		end
		return coroutine_yield(...)
	end
end

--------- path

path = {}

local string_match = string.match

function path.ext(s)
	return string_match(s, "%.[^%.\\/:]*$") or ""
end
path.Ext = path.ext

function path.setext(s, ext)
	return (string_match(s, "(.*)%.[^%.\\/:]*$") or s)..ext
end
path.SetExt = path.setext

function path.name(s)
	return string_match(s, "[^\\/:]*$")
end
path.Name = path.name

function path.dir(s)
	return string_match(s, "(.*[\\/:]).-$") or ""
end
path.Dir = path.dir


local slash1, slash2 = string_byte('/', 1), string_byte('\\', 1)

function path.addslash(s)
	local c = string_byte(s, #s)
	if c == slash1 or c == slash2 then
		return s
	end
	return s.."/"
end
path.AddSlash = path.addslash

function path.noslash(s)
	local c = string_byte(s, #s)
	if c == slash1 or c == slash2 then
		return string_sub(s, 1, -2)
	end
	return s
end
path.NoSlash = path.noslash

--------- io

function io.SaveString(path, s, translate)
	local f = assert(io_open(path, translate and "wt" or "wb"))
	f:setvbuf("no")
	f:write(s)
	f:close()
end

function io.LoadString(path, translate)
	local f = assert(io.open(path, translate and "rt" or "rb"))
	local s = f:read("*a")
	f:close()
	return s
end

function PrintToFile(fname)

	local opened
	
	local function print1(t, n, arg, ...)
		if n ~= 0 then
			t[#t + 1] = tostring(arg)
			if n ~= 1 then
				t[#t + 1] = "\t"
				return print1(t, n - 1, ...)
			end
		end
	end
	
	function print(...)
		local t = {}
		print1(t, select('#', ...), ...)
		t[#t + 1] = "\n"
		local f = io_open(fname, opened and "at" or "wt")
		opened = true
		f:write(table_concat(t))
		f:close()
	end
end

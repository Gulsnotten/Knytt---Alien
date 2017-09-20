--[[--------------------------------------------------------------------------------------------------------------

Map

Minimap by Sergey "GrayFace" Rozhenko

--]]--------------------------------------------------------------------------------------------------------------

Controls.Map = Controls.Map or mmf.VK_M
-- "MapShowAll = true" will make untravelled screens visible

local Width, Height = 24, 10
local CountX, CountY = 12, 12
local PixelW, PixelH = Width, Height
local PixelsX, PixelsY = 1, 1
local ColorPickX, ColorPickY = 15, 6
local BackTrans = 20
local PosX, PosY = 300, 120

local floor = math.floor
local max = math.max

local BlockW, BlockH = 8, 8
local LoadBlock, SaveBlock
local Blocks
local ChangedBlocks
local ColorStart = 40

local MapVisible = false

local LoadedFrames = {[40] = true}
local ImagePath = AppPath.."Data/Custom Objects/Map/map"
local Image
local function NeedImage()
	Image = Objects.NewGlobalTemplate(0, 0, 0)
	local Path = ImagePath
	ReplaceGraphics({TransparentColor = 0xFF,
		Path.."_0.png",
		Path.."_10.png",
		Path.."_1.png",
		Path.."_2.png",
		Path.."_3.png",
		Path.."_4.png",
		Path.."_40.png",
	}, Image)
	Image.BaseX, Image.BaseY, Image.Layer = nil
	Image.Permanent = 1
	Image:SetLayer(2)
	Image:SetPosition(PosX, PosY)
	Image:SetVisibility(false)
	Image.Animations = {blink = {1, 4, 2, Loop = true, Delay = 6}}
	return Image
end

----- Load blocks from savegame ini -----
do
	local sect = "Map_"..BlockW.."_"..BlockH.."_"..PixelsX.."_"..PixelsY
	local BlockSize = BlockW*BlockH*PixelsX*PixelsY
	local chars = {}
	for i = 1, 255 do
		chars[i] = string.char(i)
	end
	
	function LoadBlock(a, FromShift)
		local s
		if FromShift then
			s = SaveGameString(sect, a)
		else
			s = ReadIniString(Game.FullSavegamePath, sect, a)
		end
		local t = {}
		for i = 1, BlockSize do
			t[i] = s:byte(i + 1) or (ColorStart - 1)
		end
		Blocks[a] = t
		return t
	end
	
	function SaveBlock(a)
		local ta = Blocks[a]
		local t = {"!"}
		for i = 1, BlockSize do
			t[i + 1] = chars[ta[i]]
		end
		SaveGameWrite(sect, a, table.concat(t))
	end
end

local function BlockFromPos(x, y)
	local a = floor((x - 1000)/BlockW).."_"..floor((y - 1000)/BlockH)
	local t = Blocks[a] or LoadBlock(a)
	local i = (((y - 1000)%BlockH)*BlockW + (x - 1000)%BlockW)*PixelsX*PixelsY + 1
	return t, i, a
end

function events.global.LoadGame()
	Blocks = {}
	ChangedBlocks = {}
	if vars._MapBlocksToLoad then
		for a, _ in pairs(vars._MapBlocksToLoad) do
			LoadBlock(a, true)
			ChangedBlocks[a] = 1
		end
		vars._MapBlocksToLoad = nil
	end
end

function events.global.SaveGame()
	vars._MapBlocksToLoad = (Game.LoadShiftTemp ~= 0) and ChangedBlocks or nil
	for a, _ in pairs(ChangedBlocks) do
		SaveBlock(a)
	end
	ChangedBlocks = {}
end


----- map commands for advanced cartography -----

-- Syntax Examples:
-- [Map]
-- 1=x1000y1000-x1010y1010:  move x1021y1021
-- 2=x1000y1000:  show x1021y1021
-- 3=x1000y1000-x1010y1010:  hide
-- 4=x1000y1000-x1010y1010:  color 255 0 0

local CmdMove = {Step = 6}
local CmdShow = {Step = 6}
local CmdHide = {Step = 4}
local CmdColor = {Step = 5}

local function mapCommand(s)
	if type(s) == "table" then
		for _,v in ipairs(s) do
			mapCommand(v)
		end
		return
	end
	s = s:lower()
	local t = {}  -- fetch coordinates
	for n in s:gmatch("%-?[0-9]+") do
		t[#t+1] = tonumber(n)
	end
	local cmd
	if s:match("hide") then
		cmd = CmdHide
	elseif s:match("move") then
		cmd = CmdMove
	elseif s:match("show") then
		cmd = CmdShow
	elseif s:match("color") then
		cmd = CmdColor
		local r, g, b = t[#t-2] % 256, t[#t-1] % 256, t[#t] % 256
		t[#t] = nil
		t[#t] = nil
		t[#t] = ColorStart + floor(r*6/256) + floor(g*6/256)*6 + floor(b*6/256)*36
	else
		return
	end
	
	local delta = cmd.Step - #t
	assert(delta == 0 or delta == 2, "incorrect map command syntax")
	local n = #cmd
	for i = 1, cmd.Step do
		if i <= 2 then
			cmd[n + i] = t[i]
		elseif i <= 4 then
			cmd[n + i] = t[i - delta]
		elseif cmd ~= CmdColor then
			cmd[n + i] = t[i - delta] - t[1 + (i-1)%2]
		else
			cmd[n + i] = t[i - delta]
		end
	end
	if cmd[n+1] > cmd[n+3] then
		cmd[n+1], cmd[n+3] = cmd[n+3], cmd[n+1]
	end
	if cmd[n+2] > cmd[n+4] then
		cmd[n+2], cmd[n+4] = cmd[n+4], cmd[n+2]
	end
end
MapCommand = mapCommand

-- load commands from world.ini
do
	local s, i = nil, 1
	while true do
		s, i = WorldIniString("Map", i, "\r\n"), i + 1
		if s == "\r\n" then
			break
		end
		mapCommand(s)
	end
end

local function FindCommand(x, y, cmd, i)
	for i = (i and i - 4 + cmd.Step or 1), #cmd, cmd.Step do
		if x >= cmd[i] and y >= cmd[i+1] and x <= cmd[i+2] and y <= cmd[i+3] then
			return i + 4
		end
	end
end


----- reposition map according to CmdMove -----
local function GetMapPos()
	local x, y = Game.MapX, Game.MapY
	local i = FindCommand(x, y, CmdMove)
	if i then
		return x + CmdMove[i], y + CmdMove[i+1]
	end
	return x, y
end


----- render map -----
local MapHidden

function events.global.DeleteBackdrops(layer)
	if layer == 2 and MapVisible then
		Image:SetTransparency(BackTrans)
		Image:SetPosition(PosX, PosY)
		if MapHidden then
			Image:SetAnimationFrame(10)
			Image:AddBackdrop()
			Image:SetTransparency(0)
			return
		end
		Image:SetAnimationFrame(0)
		Image:AddBackdrop()
		Image:SetTransparency(0)
		local MapX, MapY = GetMapPos()
		local drawn = {}
		local cmd, i
		repeat
			i = 1
			local mx, my = MapX, MapY
			if cmd then
				mx, my = mx + CmdShow[cmd], my + CmdShow[cmd+1]
			end
			for y = -CountY, CountY do
				for x = -CountX, CountX do
					if not drawn[i] then
						local t, o = BlockFromPos(mx + x, my + y)
						if t[o] >= ColorStart or MapShowAll and WorkspaceExists(mx + x, my + y) and
								not FindCommand(mx + x, my + y, CmdHide) then
							drawn[i] = true
							Image:SetPosition(PosX + x*Width, PosY + y*Height)
							local k = max(t[o], ColorStart - 1)
							if not LoadedFrames[k] then
								LoadedFrames[k] = true
								ReplaceGraphics({TransparentColor = 0, ImagePath, k, k}, Image)
							end
							Image:SetAnimationFrame(k)
							Image:AddBackdrop()
						end
					end
					i = i + 1
				end
			end
			cmd = FindCommand(MapX, MapY, CmdShow, cmd)
		until not cmd
	end
end

local function ShowMap()
	Image = Image or NeedImage()
	DeleteBackdrops(2)
	if MapVisible and not MapHidden then
		Image:SetPosition(PosX, PosY)
		Image:Animate("blink")
	else
		Image:Animate(nil)
	end
	Image:SetVisibility(MapVisible and not MapHidden)
end
UpdateMap = ShowMap


----- update map -----
local NewScreen

function events.global.BeforeLoadScreen()
	MapHidden = FindCommand(Game.MapX, Game.MapY, CmdHide)
	if MapVisible then
		ShowMap()
	end
end

function events.global.LoadScreen()
	if (AllowMap or AllowMap == nil and AllowMapDefault or RecordMap) and not MapHidden then
		local MapX, MapY = GetMapPos()
		local t, o, a = BlockFromPos(MapX, MapY)
		NewScreen = t[o] < ColorStart and WorkspaceExists()
		if NewScreen then
			-- Search for custom color
			local i = FindCommand(MapX, MapY, CmdColor)
			if i then
				for y = 0, PixelsY - 1 do
					for x = 0, PixelsX - 1 do
						t[o] = CmdColor[i]
						o = o + 1
					end
				end
				ChangedBlocks[a], NewScreen = 1, nil
			elseif MapVisible then
				MapVisible = false
				DeleteBackdrops(2)
				MapVisible = true
			end
		end
	end
end

local function sqr(a)
	return a*a
end

local function GetColorCode(t)
	local r, g, b = 0, 0, 0
	for i = 1, #t do
		local r1, g1, b1 = ColorToRGB(t[i])
		r, g, b = r + r1, g + g1, b + b1
	end
	r, g, b = floor(r/#t), floor(g/#t), floor(b/#t)
	local best, dist = 0, math.huge
	for i = 1, #t do
		local r1, g1, b1 = ColorToRGB(t[i])
		-- 51 = 255/5
		d = sqr(floor(r1*6/256)*51 - r) + sqr(floor(g1*6/256)*51 - g) + sqr(floor(b1*6/256)*51 - b)
		if d < dist then
			best, dist = t[i], d
		end
	end
	r, g, b = ColorToRGB(best)
	-- minimap uses 6 variations of each color
	return ColorStart + floor(r*6/256) + floor(g*6/256)*6 + floor(b*6/256)*36
end

function events.global.Timer()
	if NewScreen then
		NewScreen = nil
		local t, o, a = BlockFromPos(GetMapPos())
		ChangedBlocks[a] = 1
		-- Use average color of 4 adjacent points for each color pick point
		local w, h = floor(600/2/PixelsX), (240/2/PixelsY)
		local c = GetPixelColor
		for y = 0, PixelsY - 1 do
			for x = 0, PixelsX - 1 do
				local x0, y0 = floor(600*x/PixelsX), floor(240*y/PixelsY)
				local ct = {}
				for y1 = 0, ColorPickY - 1 do
					for x1 = 0, ColorPickX - 1 do
						local x0, y0 = x0 + floor((2*w*x1 + w)/ColorPickX), y0 + floor((2*h*y1 + h)/ColorPickY)
						ct[#ct + 1] = c(x0, y0)
						ct[#ct + 1] = c(x0+1, y0)
						ct[#ct + 1] = c(x0, y0+1)
						ct[#ct + 1] = c(x0+1, y0+1)
					end
				end
				t[o] = GetColorCode(ct)
				o = o + 1
			end
		end
		-- Show map
		if MapVisible then
			ShowMap()
		end
	end

	-- show map when Map key is pressed
	local old = MapVisible
	MapVisible = (AllowMap or AllowMap == nil and AllowMapDefault) and IsKeysInputEnabled() and
		Controls.check("Map") and not mmf.Keyboard.KeyDown(mmf.VK_CONTROL) and
		not mmf.Keyboard.KeyDown(mmf.VK_MENU) and not mmf.Keyboard.KeyDown(mmf.VK_SHIFT)
	if old ~= MapVisible then
		ShowMap()
	end
end

-- Cheat: Space+Click on map to teleport
function events.global.MouseClick(x, y, double)
	if MapVisible and Objects.Player.Cheating ~= 0 then
		Game.MapX = Game.MapX + math.floor((x - PosX)/Width + 0.5)
		Game.MapY = Game.MapY + math.floor((y - PosY)/Height + 0.5)
	end
end

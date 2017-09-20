local abs = math.abs
local floor = math.floor
local ceil = math.ceil

local function sgn(x)
	return x > 0 and 1 or x < 0 and -1 or 0
end

-- Extra objects, because 3 signs and 3 shifts aren't enough
local function ExtraObject(latter, bank, obj, bank0, obj0, strVar)
	function events.global.CanCreateObject(t, st, x, y, z)
		if t == bank and st == obj then 
			CanCreateObject = false
			local o = Objects.new(bank0, obj0, x, y, z)
			o.Bank, o.Obj = t, st
			o:SetString(strVar, latter)
		end
	end
end

function ExtraSign(latter, bank, obj)
	return ExtraObject(latter, bank, obj, 0, 17, 1)
end

function ExtraSignArea(latter, bank, obj)
	return ExtraObject(latter, bank, obj, 0, 29, 1)
end

function ExtraShift(latter, bank, obj)
	return ExtraObject(latter, bank, obj, 0, 14, 0)
end

-- LoadTemplate
do
	TemplateResults = {}
	local TemplateProps
	
	function LoadTemplate(n, ...)
		local s, s1 = WorldIniString("Templates", n), ""
		if s ~= "" then
			s = WorldPath..s
			s1 = ReadIniString(s, "Object", "Load", "\r\n")
		end
		
		if not TemplateProps then
			TemplateProps = {}
			function events.global.NewTemplate(o)
				local props = TemplateProps[o.Obj]
				if props then
					table.copy(props, o, true)
				end
			end
		end
		
		local props = {}		
		local function ReadProp(name)
			local v = ReadIniNumber(s, "Object", name, 0)
			if v ~= 0 then
				props[name] = v
			end
		end
		ReadProp("DoesHurt")
		ReadProp("DetectRed")
		ReadProp("Solid")
		ReadProp("CanClimb")
		TemplateProps[n] = next(props) and props
		
		if s1 ~= "" then
			if s1 == "\r\n" then  -- default loading
				local image = ReadIniString(s, "Object", "Image", "")
				--local count = ReadIniNumber(s, "Object", "Frames Count", 1)
				if image ~= "" then
					ReplaceGraphics({{TransparentColor = 0xFF00FF}, path.dir(s)..image}, 254, n)
					local offX = ReadIniNumber(s, "Object", "Offset X", 0)
					local offY = ReadIniNumber(s, "Object", "Offset Y", 0)
					if offX ~= 0 or offY ~= 0 then
						events.global["NewTemplate"..n] = function(o)
							local x, y = o:GetPosition()
							o:SetPosition(x + offX, y + offY)
						end
					end
				end
			else
				local par = {assert(loadstring("return "..ReadIniString(s, "Object", "Params", "")))()}
				local par1
				if select("#", ...) > 0 then
					par1 = {...}
				else
					par1 = {assert(loadstring("return "..WorldIniString("Templates", "Params"..n, "")))()}
				end
				local m = ReadIniNumber(s, "Object", "Fixed Params Count", #par)
				if m == 0 then
					par = par1
				else
					for i = 1, #par1 do
						par[i + m] = par1[i]
					end
				end
				TemplateResults[n] = dofile(path.dir(s)..s1, n, unpack(par))
			end
		end
	end

	function LoadTemplates(from, to)
		for i = from or 1, to or 255 do
			LoadTemplate(i)
		end
	end
end

-- Space+B in cheat mode - Switch to ball mode
do
	local Forced

	function events.global.LoadGame()
		if Forced ~= nil then
			vars._ForceBallMode = Forced or nil
		elseif vars._ForceBallMode then
			BouncingBallMode()
		end
		Forced = not not vars._ForceBallMode
	end

	local KeyDown
	function events.global.Timer()
		local old = KeyDown
		KeyDown = mmf.Keyboard.KeyDown(mmf.VK_B)
		if KeyDown and not old and Objects.Player.Cheating ~= 0 and (BouncingBall == nil or vars._ForceBallMode) then
			Forced = not vars._ForceBallMode
			vars._ForceBallMode = Forced or nil
			RestartGameplay(true)
		end
	end
end

-- InvertGravity
-- do
	-- function events.global.IsStanding()
		-- if vars._UpsideDown then
			-- IsStanding = Objects.PlayerPos:OverlapsObstacle(0, -1)
		-- end
	-- end

	-- function events.global.SetPlayerDirection()
		-- if vars._UpsideDown then
			-- Objects.Player:SetY(Objects.PlayerPos:GetY() + 2)
			-- Objects.Player:SetDirection(16 - Objects.PlayerPos:GetDirection())
		-- end
	-- end

	-- function InvertGravity()
		-- vars._UpsideDown = not vars._UpsideDown or nil
		-- Objects.Platform.Gravity = math.abs(Objects.Platform.Gravity)*(vars._UpsideDown and -1 or 1)
		-- if BouncingBall then
			-- BouncingBall.UpsideDown = vars._UpsideDown
			-- BouncingBall.GravityY = math.abs(BouncingBall.GravityY)*(vars._UpsideDown and -1 or 1)
		-- else
			-- Objects.Player:SetAngle(vars._UpsideDown and 180 or 0)
			-- Objects.Player:SetDirection(16 - Objects.Player:GetDirection())
		-- end
	-- end

	-- function events.global.LoadGame()
		-- if vars._UpsideDown then
			-- vars._UpsideDown = nil
			-- InvertGravity()
		-- end
	-- end
-- end


-- ShowText
do
	local txt
	
	local function print1(t, n, arg, ...)
		if n ~= 0 then
			t[#t + 1] = tostring(arg)
			if n ~= 1 then
				t[#t + 1] = "\t"
				return print1(t, n - 1, ...)
			end
		end
	end
	
	function ShowText(...)
		local t = {}
		print1(t, select('#', ...), ...)
		if not (txt and txt.ID) then
			txt = Objects.Text{Layer = -1}
			txt:SetLayer(2)
			txt:MoveToBack()
			txt:SetPosition(5, 5)
			txt:SetHeight(13)
			txt:SetWidth(600 - 5)
			txt:ReplaceColor(15, 14, 14, 0, 150, 0)		
		end
		txt:SetText(table.concat(t))
	end
end

function ColorToRGB(c)
	local r = c%256
	c = c - r
	local g = c%0x10000
	return r, g/256, (c - g)/0x10000
end

-- Screenshots
do
	Controls.LastShot = 219
	Controls.NextShot = 221

	local ShotsCount, ShotsPlaces, ShotsPlacesOffset = 0, {}, 0
	local ShotObject, ShotBack, ShotBorder, ShotText
	local CurrentShot, ShotShown = 1, false
	
	-- Show Shots Objects
	local function myobj(name, o)
		o = o or Objects.new(254, ShotBack.Obj, -1, -1, 8)
		o.Name = name
		o.BaseX, o.BaseY, o.Layer = nil
		o.Permanent = 1
		o:SetLayer(2)
		o:SetPosition(300, 120)
		return o
	end
	
	local function ShowShot()
		if not ShotObject then
			ShotBack = myobj("ScreenshotBack", Objects.NewGlobalTemplate(-1, -1, 8))
			ReplaceGraphics({
				{TransparentColor = 0xFF},
				AppPath.."Data/Custom Objects/Screenshot/Screenshot", 1, 2
			}, ShotBack)
			ShotBack:SetAnimationFrame(1)
			ShotObject = myobj("Screenshot")
			ShotBorder = myobj("ScreenshotBorder")
			ShotBorder:SetAnimationFrame(2)
			ShotText = Objects.Text{Permanent = 1}
			ShotText.Name = "ScreenshotText"
			ShotText.Layer = nil
			ShotText:SetLayer(2)
			ShotText:SetPosition(12, 4)
			ShotText:SetHeight(13)
		end
		local f = path.setext(Game.FullSavegamePath, " "..CurrentShot..".png")
		if path.isfile(f) then
			ShotObject:LoadFrame{f, TransparentColor = 0}
			ShotObject:SetVisibility(true)
		else
			ShotObject:SetVisibility(false)
		end
		ShotBorder:SetVisibility(true)
		ShotText:SetText(CurrentShot)
		ShotText:SetVisibility(true)
		ShotShown = true
		ShotObject:Update()
		ShotBorder:Update()
	end
	
	local function HideShot()
		ShotBack:SetVisibility(false)
		ShotObject:SetVisibility(false)
		ShotBorder:SetVisibility(false)
		ShotText:SetVisibility(false)
		ShotShown = false
	end

	-- Save/Load Game
	function events.global.LoadGame()
		ShotsCount = tonumber(vars._ShotsCount) or 0
		ShotsPlaces = vars._ShotsPlaces or {}
		ShotsPlacesOffset = ShotsCount - #ShotsPlaces
		vars._ShotsPlaces = nil
		if CurrentShot > ShotsCount then
			CurrentShot = ShotsCount
		end
		if ShotShown then
			HideShot()
		end
	end

	function events.global.SaveGame()
		vars._ShotsCount = ShotsCount > 0 and ShotsCount or nil
		if Game.LoadShiftTemp ~= 0 then
			vars._ShotsPlaces = ShotsPlaces
		else
			for i = 1, #ShotsPlaces do
				SaveGameWrite("Screenshots", i + ShotsPlacesOffset, ShotsPlaces[i])
			end
		end
	end
	
	local ShotDown, LeftDown, RightDown
	function events.global.Timer()
		local old = ShotDown
		ShotDown = mmf.Keyboard.KeyDown(mmf.VK_SNAPSHOT)
		if ShotDown and not old then
			ShotsCount = ShotsCount + 1
			ShotsPlaces[#ShotsPlaces + 1] = "x"..Game.MapX.."y"..Game.MapY
			DoCall("Take Screenshot", ShotsCount)
		end
		
		local KBD = Objects.KBD
		if ShotShown and (KBD.LeftRight ~= 0 or KBD.UpDown ~= 0 or KBD.JumpOneshot ~= 0 or 
				KBD.ItemList ~= 0 or KBD.UmbrellaOneshot ~= 0 or KBD.Hologram ~= 0) then
			HideShot()
		end
		
		if not IsKeysInputEnabled() then
			if ShotShown then
				HideShot()
			end
			LeftDown, RightDown = false, false
			return
		end
		
		local old = LeftDown
		LeftDown = Controls.check("LastShot")
		if LeftDown and not old then
			if ShotsCount > 0 then
				if ShotShown then
					CurrentShot = CurrentShot - 1
				end
				if CurrentShot < 1 or CurrentShot > ShotsCount then
					CurrentShot = ShotsCount
				end
				ShowShot()
			end
		end
		
		local old = RightDown
		RightDown = Controls.check("NextShot")
		if RightDown and not old then
			if ShotsCount > 0 then
				if ShotShown then
					CurrentShot = CurrentShot + 1
				end
				if CurrentShot < 1 or CurrentShot > ShotsCount then
					CurrentShot = 1
				end
				ShowShot()
			end
		end
	end
end

-- OnKeyPress
function OnKeyPress(key, f, ...)
	local params = {...}
	local pressed
	function events.global.Timer()
		local old = pressed
		pressed = mmf.Keyboard.KeyDown(key)
		if pressed and not old then
			f(unpack(params))
		end
	end
end

-- Powers management
do
	Objects.UsedPower = {}
	for i = 0, 11 do
		Objects.UsedPower[i + 1] = Objects.Power[i]
	end
	Objects.PowerBar:LoadFrame{AppPath.."Data/Custom Objects/PowerBar.png",
		HotSpotX = 600, HotSpotY = 0, TransparentColor = 50}
	Objects.PowerBar:Move(24*#Objects.UsedPower)
	
	function NewPower(name, TemplateIndex, ShowCount)
		ShowCount = ShowCount and {}
		Objects.PowerBar:Move(24, 0)
		local power
		power = Objects.new(254, TemplateIndex or Objects.NewGlobalTemplate(), #Objects.UsedPower, 0, 0)
		power.BaseX, power.BaseY, power.Layer = nil
		if name then
			power.Name = name.." power"
		end
		power.Permanent = 1
		power:SetLayer(2)
		power:SetVisibility(false)
		power:SetY(power:GetY() - 2)
		Objects.UsedPower[#Objects.UsedPower + 1] = power
		power:event("DrawFrame", function()
			local show = Objects.PowerBar:GetVisibility()
			if power:GetVisibility() ~= show then
				power:SetVisibility(show)
				power:Update()
				ShowPowerCount(false, 0, 0, ShowCount)
			end
			if show and name then
				power:SetTransparency(vars[name] and vars[name] ~= 0 and 0 or 100)
				power:Update()
				if ShowCount then
					local x, y = power:GetPosition()
					ShowPowerCount((vars[name] or 0) ~= 0 and vars[name], x + 10, y - 9, ShowCount)
				end
			end
		end)
		return power
	end
	
	function FindPower(name)
		name = name.." power"
		for i, o in ipairs(Objects.UsedPower) do
			if o.Name == name then
				return o, i
			end
		end
	end
	
	function RemovePower(o)
		if type(o) == "number" then
			o = Objects.Power[o]
		end
		o:SetVisibility(false)
		local t = Objects.UsedPower
		for i = 1, #t do
			if not o or t[i] == o then
				t[i]:Move(o and -1000 or -24, 0)
				o = nil
				t[i] = t[i+1]
			end
		end
		if not o then
			Objects.PowerBar:Move(-24, 0)
		end
	end
	
	function MovePower(n, m)
		if type(n) == "number" then
			n = Objects.Power[n]
		end
		if type(m) == "number" then
			local m1 = m
			m = Objects.Power[m]
			while m and m:GetX() < -100 do
				m1 = m1 + 1
				m = Objects.Power[m1]
			end
		end
		if not m then
			return
		end
		
		local t = Objects.UsedPower
		local nx = 0
		for i = 1, #t do
			if t[i] == n then
				nx = n:GetX() - (i-1)*24
				break
			end
		end
		RemovePower(n)
		
		for i = 1, #t do
			if not m or t[i] == m then
				if m then
					n:SetX(nx + (i-1)*24)
					m = nil
				end
				t[i], n = n, t[i]
				n:Move(24, 0)
			end
		end
		if not m then
			Objects.PowerBar:Move(24, 0)
			t[#t + 1] = n
		end
	end
end


-- ShowPowerCount - show numbers on powers
do
	local NumTpl
	local Sizes = {}
	local StartSizes = {}
	
	local function InitTpl(WorldCoord)
		local o = Objects.NewGlobalTemplate(-1, -1, -1)
		NumTpl = o.Obj
		ReplaceGraphics({
			HotSpotX = 0, HotSpotY = 0, TransparentColor = 0xFF00FF,
			AppPath.."Data/Custom Objects/Power Numbers/num", 0, 10
		}, o)
		for i = 0, 10 do
			Sizes[i] = (i == 1 and 6) or (i == 10 and 7) or 8
			StartSizes[i] = (i == 1 and 6) or (i == 4 and 9) or (i == 10 and 7) or 8
		end
		return o
	end
	
	function ShowPowerCount(count, x, y, t)
		t = t or {}
		local i = 1
		if count then
			local function AddDigit(digit)
				local o = t[i] or NumTpl and Objects.new(254, NumTpl, -1, -1, -1) or InitTpl()
				t[i] = o
				x = x - (i == 1 and StartSizes or Sizes)[digit]
				o.BaseX, o.BaseY, o.Layer = nil
				o.Permanent = 1
				o:SetPosition(x + 1, y)
				o:SetLayer(2)
				o:SetAnimationFrame(digit)
				o:SetVisibility(true)
				o:Update()
				i = i + 1
			end

			local num = count < 0 and -count or count
			repeat
				local digit = num % 10
				AddDigit(digit)
				num = (num - digit)/10
			until num == 0
			
			if count < 0 then
				AddDigit(10)
			end
		end
		for i = i, #t do
			t[i]:SetVisibility(false)
		end
		return t
	end
end

-- Moving objects
function ObjectMovement(o)
	o.SpeedX = o.SpeedX or 0
	o.SpeedY = o.SpeedY or 0
	o.AccelX = o.AccelX or 0
	o.AccelY = o.AccelY or 0
	o.Deceleration = o.Deceleration or 0
	local moveX = (o.PosDeltaX or 0) + o.SpeedX/200
	local moveY = (o.PosDeltaY or 0) + o.SpeedY/200
	o.SpeedX = o.SpeedX + o.AccelX/2
	o.SpeedY = o.SpeedY + o.AccelY/2
	if o.Deceleration ~= 0 then
		local v = (o.SpeedX*o.SpeedX + o.SpeedY*o.SpeedY)^0.5
		if v <= o.Deceleration/2 then
			o.SpeedX, o.SpeedY = 0, 0
		else
			v = (v - o.Deceleration/2)/v
			o.SpeedX = o.SpeedX*v
			o.SpeedY = o.SpeedY*v
		end
	end
	moveX = moveX + o.SpeedX/200
	moveY = moveY + o.SpeedY/200
	local dx, dy = floor(moveX + 0.5), floor(moveY + 0.5)
	o.LastX, o.LastY = o:GetPosition()
	if dx ~= 0 or dy ~= 0 then
		moveX, moveY = moveX - dx, moveY - dy
		o:SetPosition(o.LastX + dx, o.LastY + dy)
		o:Update()
	end
	o.PosDeltaX, o.PosDeltaY = moveX, moveY
	return dx ~= 0 or dy ~= 0
end

function ObjectBounce(o)
	o.BounceMul = o.BounceMul or 1
	o.BounceFriction = o.BounceFriction or 0
	-- o.TreatSolidObjects = o.TreatSolidObjects or false
	local check = o.OverlapsBackdrop
	-- if o.TreatSolidObjects then
		-- function check(o)
			-- local lastSolid = o.Solid
			-- o.Solid = 0
			-- local r = o:OverlapsObstacle()
			-- o.Solid = lastSolid
			-- return r
		-- end
	-- end
	if not check(o) then
		return
	end
	
	-- find bounce point
	local x0, y0 = o:GetPosition()
	local tx, ty = o.LastX - x0, o.LastY - y0
	if tx == 0 and ty == 0 then
		return true
	end
	local dx, dy = (tx >= 0 and 1 or -1), (ty >= 0 and 1 or -1)
	local x, y = 0, 0
	local bounceX
	repeat
		bounceX = abs(tx*(y + dy)) > abs(ty*(x + dx))
		if bounceX then
			x = x + dx
		else
			y = y + dy
		end
		o:SetPosition(x0 + x, y0 + y)
	until not check(o)
	
	-- update speed
	local nameX, nameY = "SpeedX", "SpeedY"
	if bounceX then
		nameX, nameY = "SpeedY", "SpeedX"
	end
	local sy = o[nameY]
	o[nameY] = -sy*o.BounceMul
	local fric = abs(sy)*o.BounceFriction
	if fric == 0 then
		-- nothing
	elseif abs(o[nameX]) < fric then
		o[nameX] = 0
	else
		o[nameX] = o[nameX] - sgn(o[nameX])*fric
	end
	
	return true
end

function ObjectDestroyTooFar(o, dist)
	dist = dist or 200
	local x, y = o:GetPosition()
	if x < -dist or x >= 600 + dist or y < -dist or y >= 240 + dist then
		o:Destroy()
		return true
	end
end

function ObjectAnimateDestroy(o, anim)
	o:RemoveEvents()
	o.OnEndAnimation = o.Destroy
	o:Animate(anim)
end

function ObjectFadeDestroy(o, step)
	step = step or 8
	o:RemoveEvents()
	local function fade()
		local i = o:GetTransparency() + step
		if i >= 128 then
			return o:Destroy()
		end
		o:SetTransparency(i)
	end
	o:event("Timer", fade)
	fade()
end


-- other variations: GetDistance(obj1, x, y), GetDistance(obj1, obj2), GetDistance(x, y, obj2)
function GetDistance(x0, y0, x, y)
	if type(x0) == "table" then
		x, y = y0, x
		x0, y0 = x0:GetPosition()
	end
	if type(x) == "table" then
		x, y = x:GetPosition()
	end
	x, y = x - x0, y - y0
	return math.sqrt(x*x + y*y), x, y
end

-- variations are the same as in GetDistance
function SpeedInDirection(speed, x0, y0, x, y)
	local a, x, y = GetDistance(x0, y0, x, y)
	if a ~= 0 then
		a = speed/a
	end
	return a*x, a*y
end


-- returns a function that assigns an overlay template object to a standard object
function GraphicsOverlay(data)
	local frames
	return function(tpl, obj)
		obj:SetVisibility(false)
		if not frames then
			frames = {}
			local n = 0
			function data.LoadFrame(tpl, fname, anim, dir, frame, ...)
				assert(dir % 32 == dir and anim % 13 == anim)
				frames[anim + 13*(dir + 32*frame)] = n
				tpl:LoadFrame(fname, 0, 0, n, ...)
				n = n + 1
			end
			ReplaceGraphics(data, tpl)
		end
		function events.global.DrawFrame()
			if not obj.ID or not tpl.ID then
				return (events.global.Remove("DrawFrame", 1))  -- can't be tailcall!
			end
			local frame, anim, dir = obj:GetAnimationFrameEx()
			local fr = frames[anim + 13*(dir + 32*frame)]
			if not fr then
				local s = dir < 16 and 1 or -1
				for i = 1, 16 do
					fr = frames[anim + 13*((dir + i*s)%32 + 32*frame)]
					if fr then
						break
					end
					fr = frames[anim + 13*((dir - i*s)%32 + 32*frame)]
					if fr then
						break
					end
				end
			end
			if fr then
				tpl:SetAnimationFrame(fr)
			end
			tpl:SetPosition(obj:GetPosition())
			tpl:Update()
		end
	end
end

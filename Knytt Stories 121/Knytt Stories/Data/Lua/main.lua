dofile(AppPath.."Data/Lua/RSFunctions.lua")
dofile(AppPath.."Data/Lua/events.lua")
PrintToFile(AppPath.."LuaLog.txt")

local _G = _G

local function event(...)
	events.global.call(...)
	events.call(...)
end

function dofile(path, ...)
	return assert(loadfile(path))(...)
end

function debug.FunctionFile(f)
	if type(f) == "number" then
		f = f + 1
	end
	local s = debug.getinfo(f, "S").source
	return s:sub(1, 1) == '@' and s:sub(2) or ""
end

-----------------------------------------------
-- Forward
-----------------------------------------------

local globalTick, tick = 0, 0

-----------------------------------------------
-- Objects
-----------------------------------------------

local TemplatesBank = 254

local ObjList = {}
local AnimObjList = {}
local mmfObj = mmf.Object
local ObjIndex = {}
local DestroyList = {}
local CombineX, CombineY, CombineZ, CombineT, CombineObj
local UnbindEvents = {}

for k, v in pairs(mmfObj) do
	ObjIndex[k] = function(t, ...)
		return v(t.ID, ...)
	end
end

local function DoDestroyCallback(o, already)
	if already then
		o.ID = nil
	end
	event("DestroyObject", o)
	if o.OnDestroy then
		o:OnDestroy()
	end
	o:RemoveEvents()
	if not already and o.Bank == TemplatesBank then
		o:SetValue(5, 0)  -- for FindTemplateOverlap
	end
	o.ID = nil
	if o == Objects.PlayerHologram then
		Objects.PlayerHologram = nil
	else
		ObjList[o] = nil
	end
	setmetatable(o, nil)
end

function ObjIndex:Destroy(animate)
	local id = self.ID
	if animate then
		DoCall("Destroy Object", id)
	else
		DoDestroyCallback(self)
		mmfObj.SetPosition(id, -10000, -10000)
		mmfObj.Update(id)
		mmfObj.Destroy(id)
	end
end

function mmf.DestroyCallback(id)
	DestroyList[id] = nil
	local o = (id == 6 and Objects.PlayerHologram or Objects.Find{ID = id})
	if o then
		DoDestroyCallback(o, true)
	end
end

function _internal_DestroyingAll()
	for o in pairs(ObjList) do
		if o.Permanent == 0 then
			DoDestroyCallback(o)
		end
	end	
end

function ObjIndex:Move(dx, dy)
	local x, y = self:GetPosition()
	self:SetPosition(x + (dx or 0), y + (dy or 0))
	self:Update()
end

local function MoveToLayer(oid, z)
	if mmfObj.GetLayer(oid) ~= 1 then
		return
	end
	if z < 6 then
		mmfObj.MoveBelow(oid, Objects.Umbrella.ID)
	end
	for v in Objects.Enum() do
		if v:GetLayer() == 1 and v.Layer and z < v.Layer and mmfObj.IsAbove(oid, v.ID) then
			mmfObj.MoveBelow(oid, v.ID)
		end
	end
end

function ObjIndex:UpdateLayer()
	self:MoveToFront()
	MoveToLayer(self.ID, self.Layer)
end

function ObjIndex:ReplaceColor(r1, g1, b1, r2, g2, b2)
	if b1 then
		return DoCall("Recolor Object", self.ID, r1 + 256*(g1 + 256*b1), r2 + 256*(g2 + 256*b2))
	else
		return DoCall("Recolor Object", self.ID, r1, g1)
	end
end

function ObjIndex:GetAnimationFrameEx()
	return DoCall("Get Object Frame, Animation, Direction", self.ID)
end

function ObjIndex:GetAnimation()
	local frame, anim, dir = DoCall("Get Object Frame, Animation, Direction", self.ID)
	return anim
end

function ObjIndex:GetAnimationFrame()
	local frame, anim, dir = DoCall("Get Object Frame, Animation, Direction", self.ID)
	return frame
end

function ObjIndex:GetAnimationDirection()
	local frame, anim, dir = DoCall("Get Object Frame, Animation, Direction", self.ID)
	return dir
end

function ObjIndex:SetAnimation(v)
	DoCall("Set Object Animation", self.ID, v)
end

function ObjIndex:SetAnimationFrame(v, animate)
	DoCall("Set Object Frame", self.ID, v)
	if animate then
		DoCall("Restore Object Frame", self.ID, v)
	end
end

function ObjIndex:SetAnimationDirection(v)
	DoCall("Set Object Animation Direction", self.ID, v)
end

function ObjIndex:RestoreAnimationFrame()
	DoCall("Restore Object Frame", self.ID)
end

function ObjIndex:RestoreAnimation()
	DoCall("Restore Object Animation", self.ID)
end

function ObjIndex:RestoreAnimationDirection()
	DoCall("Restore Object Animation Direction", self.ID)
end

function ObjIndex:IsAnimated()
	return not DoCall("Is Animation Over", self.ID)
end

function ObjIndex:GetActionPoint(absolute)
	local x, y = DoCall("Get Action Point", self.ID)
	local hx, hy = self[absolute and "GetPosition" or "GetHotspot"](self)
	return x + hx, y + hy
end

function ObjIndex:GetActionX(absolute)
	return DoCall("Get Action Point", self.ID) + self[absolute and "GetX" or "GetHotspotX"](self)
end

function ObjIndex:GetActionY(absolute)
	local x, y = DoCall("Get Action Point", self.ID)
	return y + self[absolute and "GetY" or "GetHotspotY"](self)
end

function ObjIndex:GetSpeed()
	return DoCall("Get Speed", self.ID)*10
end

function ObjIndex:SetSpeed(v)
	DoCall("Set Speed", self.ID, v/10)
end

function ObjIndex:GetDeceleration()
	return DoCall("Get Deceleration", self.ID)
end

function ObjIndex:SetDeceleration(v)
	DoCall("Set Deceleration", self.ID, v)
end

function ObjIndex:GetGravity()
	return DoCall("Get Gravity", self.ID)*2
end

function ObjIndex:SetGravity(v)
	DoCall("Set Gravity", self.ID, v/2)
end

function ObjIndex:LookAt(x, y)
	if not y then
		x, y = x:GetPosition()
	end
	local x0, y0 = self:GetPosition()
	local a = math.atan2(y0 - y, x - x0)*16/math.pi
	self:SetDirection(math.floor(a + 0.5) % 32)
	return a
end

function ObjIndex:GetTransparency()
	return DoCall("GetTransparency", self.ID)
end
function ObjIndex:SetTransparency(v)
	DoCall("SetTransparency", self.ID, v)
end

function ObjIndex:OverlapsObstacle(dx, dy)
	dx = dx or 0
	dy = dy or 0
	if dx ~= 0 or dy ~= 0 then
		local x, y = self:GetPosition()
		self:SetPosition(x + dx, y + dy)
		ObstacleOverlap = (DoCall("CheckObstacleOverlap", self.ID) == true)
		event("CheckObstacleOverlap", self)
		self:SetPosition(x, y)
	else
		ObstacleOverlap = (DoCall("CheckObstacleOverlap", self.ID) == true)
		event("CheckObstacleOverlap", self)
	end
	return ObstacleOverlap
end

function ObjIndex:OverlapsBackdrop(dx, dy)
	dx = dx or 0
	dy = dy or 0
	if dx ~= 0 or dy ~= 0 then
		local x, y = self:GetPosition()
		self:SetPosition(x + dx, y + dy)
		local r = (DoCall("CheckBackdropOverlap", self.ID) == true)
		self:SetPosition(x, y)
		return r
	end
	return (DoCall("CheckBackdropOverlap", self.ID) == true)
end

function ObjIndex:AddBackdrop(IsObstacle)
	DoCall("Create Backdrop", self.ID, IsObstacle == nil and 0 or IsObstacle == false and 1 or IsObstacle == true and 2)
end

function ObjIndex:LoadFrame(file, anim, direction, frame, hotX, hotY, actionX, actionY, transp)
	local t
	if type(file) == "table" then
		t = file
		file, anim, direction, frame, hotX, hotY, actionX, actionY, transp = unpack(t)
	else
		t = {}
	end
	file = file or t.File
	anim = anim or t.Animation or 0
	direction = direction or t.Direction or 0
	frame = frame or t.Frame or 0
	hotX = hotX or t.HotSpotX or 100000
	hotY = hotY or t.HotSpotY or 100000
	actionX = actionX or t.ActionX or hotX
	actionY = actionY or t.ActionY or hotY
	transp = transp or t.TransparentColor or -1
	return DoCall("Load Frame", self.ID, file, anim, direction, frame, hotX, hotY, actionX, actionY, transp)
end

function ObjIndex:GotoPathNode(node)
	DoCall("Goto Path Node", self.ID, tostring(node))
end

function ObjIndex:Stop()
	DoCall("Stop Movement", self.ID)
end

-- Kinds: object, template, custom, child, text
local OverlapKind = {text = "text", special = "special", child = "special", object = "object", template = "object"}
local OverlapOrder = {text = 1, child = 2, special = 3, template = 4, object = 5}
-- 1 = must be the 1st parameter, 3 = must be the 3rd parameter

function ObjIndex:CheckOverlap(o)
	if self == Objects.PlayerPos then
		return (DoCall("Check Overlap player-"..OverlapKind[o.Kind], o.ID) == true)
	elseif o == Objects.PlayerPos then
		return (DoCall("Check Overlap player-"..OverlapKind[self.Kind], self.ID) == true)
	elseif OverlapOrder[self.Kind] > OverlapOrder[o.Kind] then
		o, self = self, o
	end
	local k1, k2 = OverlapKind[self.Kind], OverlapKind[o.Kind]
	if k1 == k2 then
		if self.Kind ~= o.Kind then
			return (DoCall(("Check Overlap %s-%s"):format(self.Kind, o.Kind), self.ID, o.ID) == true)
		end
		-- imposible to check overlap for the same kind
		error(('cannot check overlap of objects of the same kind ("%s")'):format(self.Kind), 2)
	end
	return (DoCall(("Check Overlap %s-%s"):format(k1, k2), self.ID, o.ID) == true)
end

local OverlapKind2 = {special = "special", child = "special", text = "text"}
function ObjIndex:FindTemplateOverlap(index)
	local id = DoCall("Find Template Overlap "..assert(OverlapKind2[self.Kind]), self.ID, index)
	if id then
		return assert(Objects.Find{ID = id})
	end
end

function ObjIndex:SetEffect(n)
	DoCall("Set Ink Effect", self.ID, n)
end

function ObjIndex:event(s, f, passSelf)
	if passSelf then
		local func = f
		function f(...)
			return func(self, ...)
		end
	end
	events.global[s] = f
	local t = UnbindEvents[self] or {}
	UnbindEvents[self] = t
	t[#t + 1] = s
	t[#t + 1] = f
end

function ObjIndex:RemoveEvents()
	local t = UnbindEvents[self]
	if t then
		for i = 1, #t, 2 do
			events.global.Remove(t[i], t[i + 1])
		end
		UnbindEvents[self] = nil
	end
end

function ObjIndex:Animate(t)
	self.Animation = nil
	self.AnimTick = nil
	self.AnimLoop = nil
	local tp = type(t)
	if t == nil then
		if self.OnEndAnimation then
			self:OnEndAnimation()
		end
		return
	elseif tp ~= "table" and tp ~= "function" then
		local t1 = self.Animations
		local t1 = t1 and t1[t]
		tp = type(t1)
		assert(tp == "table" or tp == "function", "Animation not found: "..tostring(t))
		t = t1
	end
	if tp == "function" then
		return t(self)
	end 
	self:SetAnimationFrame(assert(t[1]))
	self.Animation = t
	self.AnimGoal = 2
	self.AnimTick = globalTick + (t.Delay or 2)
	self.AnimLoop = 1
	AnimObjList[self.ID] = self
end

local function DoObjectsAnimation()
	for id, o in pairs(AnimObjList) do
		while true do
			local t = o.ID and o.Animation
			local animTick = o.AnimTick
			if not t then
				AnimObjList[id] = nil
				break
			elseif animTick > globalTick then
				break
			end
			local frame, goal = o:GetAnimationFrame(), t[o.AnimGoal]
			if goal then
				if frame < goal then
					frame = frame + 1
				elseif frame > goal then
					frame = frame - 1
				end
				o:SetAnimationFrame(frame)
				if frame == goal then
					o.AnimGoal = o.AnimGoal + 1
				end
			else
				if not t.Loop or type(t.Loop) == "number" and t.Loop > self.AnimLoop then
					o:Animate(t.Next)
				else
					local loop = o.AnimLoop
					o:Animate(t)
					o.AnimLoop = loop + 1
				end
			end
			o.AnimTick = o.AnimTick and (animTick + (t.Delay or 2))
		end
	end
end

----------- Text Blitter

local TextIndex = setmetatable({}, {__index = ObjIndex})

local function TextProp(name)
	local gname, sname = "T Get "..name, "T Set "..name
	TextIndex["Get"..name] = function (obj)
		return DoCall(gname, obj.ID)
	end
	TextIndex["Set"..name] = function (obj, val)
		return DoCall(sname, obj.ID, val)
	end
end

TextProp("Text")
TextProp("Width")
TextProp("Height")
TextProp("VScroll")
TextProp("CharXSpace")
TextProp("CharYSpace")
TextProp("HAlign")
TextProp("VAlign")

function TextIndex:SetCharacters(path, w, h)
	return DoCall("T Set Characters", self.ID, path, w, h)
end

function TextIndex:GetCharacterSize()
	return DoCall("T Get Char Width Height", self.ID)
end

function TextIndex:GetLinesCount()
	return DoCall("T Get Lines Count", self.ID)
end

----------- MakeObject

local function MakeObject(id, t, meta)
	meta = meta or ObjIndex
	t = t or {}
	t.ID = id
	t.Kind = t.Kind or "special"
	return setmetatable(t, {__index = meta})
end

local function MakeObjectEx(id, vals, t, meta)
	meta = meta or ObjIndex
	t = t or {}
	t.ID = id
	t.Kind = t.Kind or "special"

	local function index(t, name)
		local k = vals[name]
		return k and mmfObj.GetValue(id, k - 1) or meta[name]
	end
	
	local function newindex(t, name, v)
		local k = vals[name]
		if k then
			mmfObj.SetValue(id, k - 1, (assert(tonumber(v), "number expected")))
		else
			rawset(t, name, v)
		end
	end

	return setmetatable(t, {__index = index, __newindex = newindex})
end

Objects = {}

local ObjectProps = {
	PlacementOffsetX = 1,
	PlacementOffsetY = 2,
	DoesHurt = 3,
	Permanent = 22,
}

local TemplateProps = {
	PlacementOffsetX = 1,
	PlacementOffsetY = 2,
	DoesHurt = 3,        -- C
	DetectRed = 4,       -- D
	Solid = 5,           -- E
	-- Obj index = 6
	CanClimb = 10,       -- J
	Permanent = 22,      -- V
}

local TextProps = {
	Permanent = 22,
}

Objects.Player = MakeObjectEx(1, {
	Run = 1,
	Climb = 2,
	DoubleJump = 3,
	HighJump = 4,
	Eye = 5,
	Detector = 6,
	Umbrella = 7,
	Hologram = 8,
	Key1 = 9,
	Key2 = 10,
	Key3 = 11,
	Key4 = 12,
	AfterTeleportCountdown = 13,
	TeleportLightX = 14,
	TeleportLightY = 15,
	Cheating = 16,
	CanTeleport	= 17,
})

Objects.PlayerPos = MakeObjectEx(2, {
	Direction = 1,
	CanDoubleJump = 2,
	JustDoubleJumped = 3,
	JustJumped = 4,
	HologramActivationTimer = 5,
	JumpBlock = 6,
	PlayLandSoundOnGroundTouch = 7,
	LoopAction = 8,
	PrevAction = 9,
	DelayX = 10,
	DelayY = 11,
	NormalJumpCountdown = 12,
})

Objects.Umbrella = MakeObjectEx(3, {
	--UnusedA = 1,
	InUse = 2,
})
Objects.Flags = MakeObjectEx(4, {
	Flag0 = 1,
	Flag1 = 2,
	Flag2 = 3,
	Flag3 = 4,
	Flag4 = 5,
	Flag5 = 6,
	Flag6 = 7,
	Flag7 = 8,
	Flag8 = 9,
	Flag9 = 10,
	FlagWarpAX = 11,
	FlagWarpAY = 12,
	FlagWarpBX = 13,
	FlagWarpBY = 14,
	FlagWarpCX = 15,
	FlagWarpCY = 16,
})

Objects.Physics = MakeObjectEx(5, {
	MaxXWalk = 1,
	MaxXRun = 2,
	Jump = 3,
	HiJump = 4,
})

-- Objects.PlayerHologram = MakeObjectEx(6, {
	-- Run = 1,
	-- Climb = 2,
	-- DoubleJump = 3,
	-- HighJump = 4,
	-- Eye = 5,
	-- Detector = 6,
	-- Umbrella = 7,
	-- UndefinedPowerH = 8,
-- })

local PlayerHologramProps = {
	Run = 1,
	Climb = 2,
	DoubleJump = 3,
	HighJump = 4,
	Eye = 5,
	Detector = 6,
	Umbrella = 7,
	UndefinedPowerH = 8,
}

Objects.Sound = MakeObjectEx(7, {
	CurrentAmbianceA = 1,
	CurrentChannelA = 2,
	CurrentAmbianceB = 3,
	CurrentChannelB = 4,
	FaderAA = 5,
	FaderAB = 6,
	FaderBA = 7,
	FaderBB = 8,
	InitFadeupVolumeA = 9,
	NextAllocatedChannel = 10,
	InitFadeupVolumeB = 11,
	ForceMute = 12,
	CurrentMute = 13,
	AmbiFadeSpeedA = 14,
	AmbiFadeSpeedB = 15,
})

Objects.PlayerVisiblePos = MakeObject(8)
Objects.SignText = MakeObject(9, {Kind = "text", Permanent = 1}, TextIndex)
Objects.SignFrame = MakeObject(10)
--Objects.PickUpLight = MakeObject(11)
Objects.ScreenValues = MakeObjectEx(11, {
	TilesetA = 1,
	TilesetB = 2,
	AtmosA = 3,
	AtmosB = 4,
	Music = 5,
	Gradient = 6,
})

Objects.SecretsMarker = MakeObject(12)
Objects.DangerMarker = MakeObject(13)

Objects.KBD = MakeObjectEx(14, {
	LeftRight = 1,
	Jump = 2,
	JumpOneshot = 3,
	UpDown = 4,
	Walk = 5,
	ItemList = 6,
	UmbrellaOneshot = 7,
	DownOneshot = 8,
	Hologram = 9,
	ScrollUp = 10,
	ScrollDown = 11,
	ScrollHome = 12,
	ScrollEnd = 13,
})

Objects.BlackScreen = MakeObject(15)
Objects.WhiteScreen = MakeObject(16)

Objects.ClimbChecker = MakeObjectEx(17, {
	Overlap = 1,
	WasRescentlyClimbing = 2,
})

Objects.SignArrowDown = MakeObject(18)
Objects.SignArrowUp = MakeObject(19)

Objects.PowerBar = MakeObject(87)
Objects.Power = {}
for i = 0, 11 do
	Objects.Power[i] = MakeObject(88 + i)
end

local PickObjects

local function obj_enum(t, o)
	o = next(ObjList, o)
	if not t then
		return o
	end
	while o do
		local ok = true
		for k, v in pairs(t) do
			if o[k] ~= v then
				ok = false
				break
			end
		end
		if ok then
			return o
		end
		o = next(ObjList, o)
	end
end

Objects.Find = obj_enum

function Objects.Enum(t)
	if t then
		return obj_enum, t, nil
	else
		return next, ObjList, nil
	end
end

function Objects.new(t, st, x, y, z)
	z = z or 7
	local pick = {}
	PickObjects = pick
	if st ~= 0 then
		CombineT = 0
		DoCall("Create Object", t, st, x, y, z)
		return unpack(pick)
	end
end

Objects.New = Objects.new

local GlobalTemplates, TakenTemplates = {}, setmetatable({}, GlobalTemplates)
GlobalTemplates.__index = GlobalTemplates

function Objects.NewGlobalTemplate(x, y, z)
	for i = 255, 1, -1 do
		if not TakenTemplates[i] then
			GlobalTemplates[i] = true
			if x then
				return Objects.new(TemplatesBank, i, x, y, z)
			end
			return i
		end
	end
end

function Objects.NewTemplate(x, y, z)
	for i = 255, 1, -1 do
		if not TakenTemplates[i] then
			if x then
				return Objects.new(TemplatesBank, i, x, y, z)
			else
				TakenTemplates[i] = true
				return i
			end
		end
	end
end

function Objects.Text(t)
	t = t or {}
	t.Layer = t.Layer or 7
	t.Kind = "text"
	local perm = t.Permanent
	t = MakeObjectEx(DoCall("T Create"), TextProps, t, TextIndex)
	if perm then
		t.Permanent = nil
		t.Permanent = perm
	end
	ObjList[t] = true
	MoveToLayer(t.ID, t.Layer)
	return t
end

function Objects.Child(index)
	local id = DoCall("CreateChild", index)
	if id then
		t = MakeObjectEx(id, ObjectProps, {ChildIndex = index, Kind = "child"})
		ObjList[t] = true
		return t
	end
end
Objects.child = Objects.Child

-----------------------------------------------
-- Workspace Manipulation, Tiles Creation
-----------------------------------------------

function WorkspaceExists(x, y)
	return not not DoCall("Workspace Exists", x or Game.MapX, y or Game.MapY)
end

function ReadWorkspace(pos, size)
	return DoCall("Read Workspace", pos, size)
end

-- 0:32 NoWallswim object
local NoWallSwimSides, NoWallSwimSidesWatch
-- l, r, u, d
local NoWallswim_ScreenX = {-1, 1, 0, 0}
local NoWallswim_ScreenY = {0, 0, -1, 1}
local NoWallswim_x = {24, 0, 0, 0}
local NoWallswim_y = {0, 0, 9, 0}
local NoWallswim_dx = {0, 0, 1, 1}
local NoWallswim_dy = {1, 1, 0, 0}
local NoWallswim_count = {10, 10, 25, 25}

function DoNoWallswim(t)
	local x, y = Game.MapX, Game.MapY
	local warp = Objects.Find{Bank = 0, Obj = 20}
	-- local changed
	for i = 1, 4 do
		if t[i] then
			local x1, y1 = x + NoWallswim_ScreenX[i], y + NoWallswim_ScreenY[i]
			if warp then
				x1 = x1 + warp:GetValue((i - 1)*2)
				y1 = y1 + warp:GetValue((i - 1)*2 + 1)
			end
			if DoCall("Change Workspace For Tileset", x1, y1, false) then
				-- changed = true
				local sx, sy = NoWallswim_ScreenX[i]*600, NoWallswim_ScreenY[i]*240
				local x2, y2 = NoWallswim_x[i], NoWallswim_y[i]
				local dx, dy = NoWallswim_dx[i], NoWallswim_dy[i]
				for j = 1, NoWallswim_count[i] do
					DoCall("Create Workspace Tile", x2, y2, 3, true, sx + x2*24, sy + y2*24)
					x2, y2 = x2 + dx, y2 + dy
				end
			end
		end
	end
	-- currently there are no tile creation capabilities, so no need to switch back
	-- if changed then
		-- DoCall("Change Workspace For Tileset", x, y, true)
	-- end
end

-- 0:32  NoWallswim object
function _internal_0_32(x, y, z)
	local l, t, r, b
	l = (x == 0)
	r = (x == 24)
	u = (y == 0)
	d = (y == 9)
	if not (l or r or u or d) then
		l, r, u, d = true, true, true, true
	end
	if NoWallSwimSides then
		NoWallSwimSides[1] = l or NoWallSwimSides[1]
		NoWallSwimSides[2] = r or NoWallSwimSides[2]
		NoWallSwimSides[3] = u or NoWallSwimSides[3]
		NoWallSwimSides[4] = d or NoWallSwimSides[4]
	else
		DoNoWallswim{l, r, u, d}
	end
end

-----------------------------------------------
-- Graphics Replacement
-----------------------------------------------

local AnimByName = {
	stopped = 0,
	stop = 0,
	walking = 1,
	walk = 1,
	running = 2,
	run = 2,
	appearing = 3,
	appear = 3,
	disappearing = 4,
	disappear = 4,
	bouncing = 5,
	bounce = 5,
	shooting = 6,
	shoot = 6,
	jumping = 7,
	jump = 7,
	falling = 8,
	fall = 8,
	climbing = 9,
	climb = 9,
	["crounch down"] = 10,
	crounch = 10,
	crounchdown = 10,
	["stand up"] = 11,
	standup = 11,
	slide = 12,
}

local function ReplaceObjGraphics(data, obj)
	local t = {}
	local BaseIndex = data.BaseIndex or 0
	local i = 1
	while data[i] do
		local str = data[i]
		i = i + 1
		if type(str) == "table" then
			t = str
		else
			assert(type(str) == "string")
			local num1, num2 = data[i], 1
			if type(num1) == "number" then
				num2, i = data[i + 1], i + 1
				if type(num2) == "number" then
					i = i + 1
				else
					num2 = nil
				end
			else
				num1 = nil
			end
			for j = num1 or 1, num2 or math.huge do
				local a = num1 and str.."_"..j..".png" or str
				if num1 and not path.isfile(a) then
					a = str.."_0"..j..".png"
					if not path.isfile(a) then
						a = str.."_00"..j..".png"
						if not num2 and not path.isfile(a) then
							break
						end
					end
				end
				local name = path.name(a)
				local dir, anim, frame = name:match("_([^_]*)_([^_]*)_([^%.]*)")
				if dir then
					anim = AnimByName[anim:lower()] or tonumber(anim)
					dir = tonumber(dir)
					frame = tonumber(frame)
				else
					anim = 0
					dir = 0
					frame = tonumber(name:match("_([^%.]*)")) or 0
				end
				assert(anim and dir and frame and dir >= 0 and dir < 32 and frame >= 0)
				;(data.LoadFrame or obj.LoadFrame)(obj, a, anim, dir, frame - (t.BaseIndex or BaseIndex),
					t.HotSpotX or data.HotSpotX, t.HotSpotY or data.HotSpotY,
					t.ActionX or data.ActionX, t.ActionY or data.ActionY,
					t.TransparentColor or data.TransparentColor)
			end
		end
	end
end

local GraphicsReplacements = {}
local AnimationReplacements = {}

local function CheckGraphicsReplacements(obj)
	local n = 0
	for i = 1, #GraphicsReplacements do
		local t = GraphicsReplacements[i - n]
		if t[2] == obj.Obj and t[1] == obj.Bank and t[3] == obj.Piece then
			ReplaceObjGraphics(t[4], obj)
			table.remove(GraphicsReplacements, i - n)
			n = n + 1
		end
	end
	for i = 1, #AnimationReplacements do
		local t = AnimationReplacements[i]
		if t[2] == obj.Obj and t[1] == obj.Bank and t[3] == obj.Piece then
			obj.Animations = t[4]
			if t[5] then
				obj:Animate(t[5])
			end
		end
	end
end

function ReplaceGraphics(data, bank, obj, piece) -- or (data, object_instance)
	if obj then
		piece = piece or 0
		local o = Objects.Find{Bank = bank, Obj = obj, Piece = piece}
		if o then
			ReplaceObjGraphics(data, o)
			return o
		else
			GraphicsReplacements[#GraphicsReplacements + 1] = {bank, obj, piece, data}
		end
	else
		ReplaceObjGraphics(data, bank)
		return bank
	end
end

local HologramReplacements = {}

local function CheckHologramReplacements()
	for i = 1, #HologramReplacements do
		ReplaceGraphics(HologramReplacements[i], Objects.PlayerHologram)
	end
	HologramReplacements = {}
end

function ReplaceHologramGraphics(data)
	HologramReplacements[#HologramReplacements + 1] = data
end

function AnimateObjects(anims, anim, bank, obj, piece)
	piece = piece or 0
	AnimationReplacements[#AnimationReplacements + 1] = {bank, obj, piece, anims, anim}
end

-----------------------------------------------
-- XLua Functions
-----------------------------------------------

local OldKeyDown = mmf.Keyboard.KeyDown
local OldKeyUp = mmf.Keyboard.KeyUp

function mmf.Keyboard.KeyDown(...)
	return (DoCall("IsWindowActive") == true) and OldKeyDown(...)
end

function mmf.Keyboard.KeyUp(...)
	return (DoCall("IsWindowActive") ~= true) or OldKeyUp(...)
end

-----------------------------------------------
-- Controls
-----------------------------------------------

Controls = {
	Left = mmf.VK_LEFT,
	Right = mmf.VK_RIGHT,
	Up = mmf.VK_UP,
	Down = mmf.VK_DOWN,
	Walk = mmf.VK_A,
	Jump = mmf.VK_S,
	Umbrella = mmf.VK_D,
	ItemList = mmf.VK_Q,
	Hologram = mmf.VK_W,
	ScrollUp = mmf.VK_PRIOR,
	ScrollDown = mmf.VK_NEXT,
	ScrollHome = mmf.VK_HOME,
	ScrollEnd = mmf.VK_END,
}

do
	local Cache = {}

	setmetatable(Controls, {__call = function(t, name)
		if type(name) == "table" then
			table.copy(name, t, true)
			return
		end
		
		local key = t[name]
		key = Cache[key] or key
		if type(key) == "string" then
			local v = mmf["VK_"..key:upper()]
			Cache[key], key = v, v
		end	
		return key
	end})
end

function Controls.check(name)
	return mmf.Keyboard.KeyDown(Controls(name))
end

do
	local oneshots = {}
	
	local function one(name)
		local v, was = Controls.check(name), oneshots[name]
		oneshots[name] = v
		return v and not was
	end
	
	function _internal_FilterKBD()
		local c, k = Controls.check, Objects.KBD
		k.LeftRight = c("Right") and 1 or c("Left") and -1 or 0
		k.Jump = c("Jump") and 1 or 0
		k.JumpOneshot = one("Jump") and 1 or 0
		k.UpDown = c("Down") and 1 or c("Up") and -1 or 0
		k.DownOneshot = one("Down") and 1 or 0
		k.Walk = c("Walk") and 1 or 0
		k.ItemList = c("ItemList") and 1 or 0
		k.UmbrellaOneshot = one("Umbrella") and 1 or 0
		k.Hologram = one("Hologram") and 1 or 0
		
		event("KeysFilter")
	end
	
	-- in ms:
	ClockTick = 0
	LastClockTick = 0

	function _internal_OnIterationStart(AbsTimer)
		ClockTick, LastClockTick = AbsTimer, ClockTick
		local k = Objects.KBD
		k.ScrollUp = one("ScrollUp") and 1 or 0
		k.ScrollDown = one("ScrollDown") and 1 or 0
		k.ScrollHome = one("ScrollHome") and 1 or 0
		k.ScrollEnd = one("ScrollEnd") and 1 or 0
	end
end

-----------------------------------------------
-- Misc functions
-----------------------------------------------

local function BankObjList(banks)
	local r = {}
	for t, v in pairs(banks) do
		for _, st in pairs(v) do
			r[t*256 + st] = true
		end
	end
	return r
end

-----------------------------------------------
-- Game events and functions
-----------------------------------------------

local timeIntervals, timeFunctions
local movementTempDeact
local ghosts
local PermsList
local ScreenObjectsLoading
local MustDestroy = BankObjList{
	[0] = {12, 20},
	[3] = {4, 6, 22, 33},
	[4] = {18},
	[6] = {10, 11, 12, 13},
	[9] = {1, 2, 3, 4},
	[11] = {2, 6, 9},
	[12] = {6},
	[13] = {7, 8, 10, 11; 1, 2, 4, 5, 6, 14},
	[14] = {16, 18, 21, 22, 23, 24},
	[17] = {3, 10, 11, 12},
	[18] = {6},
}

function _internal_BeforeLoadScreen(x, y)
	timeIntervals = {}
	timeFunctions = {}
	ghosts = {}
	NoWallSwimSides = {}
	NoWallSwimSidesWatch = false
	tick = 0
	event("LeftScreen")
	events.RemoveAll()
	event("BeforeLoadScreen", x, y)
	-- sort permanents, remove temp objects
	PermsList = {}
	local PermsMap, i = {}, 1
	for o in pairs(ObjList) do
		if o.Permanent == 0 then
			-- for faster screen switching
			if o.Bank and o.Obj and not MustDestroy[o.Bank*256 + o.Obj] then
				o.Permanent = 1
				o:SetX(-10000)
				o:Update()
				DestroyList[o.ID] = true
			end
			DoDestroyCallback(o)
		elseif o:GetLayer() == 1 then
			local z = o:GetZOrder()
			PermsMap[z] = o
			PermsList[i] = z
			i = i + 1
		end
	end
	table.sort(PermsList)
	for i = 1, i - 1 do
		PermsList[i] = PermsMap[PermsList[i]]
	end
end

function _internal_AfterLoadScreen(x, y)
	-- reset music volume
	Game.MusicVolume = 100
	Game.AmbianceVolumeA = 100
	Game.AmbianceVolumeB = 100
	-- move up permanent objects
	ScreenObjectsLoading = false
	TakenTemplates = setmetatable({}, GlobalTemplates)
	for i = 1, #PermsList do
		PermsList[i]:MoveToFront()
	end
	for i = 1, #PermsList do
		local o = PermsList[i]
		MoveToLayer(o.ID, o.Layer)
		if o.Bank == TemplatesBank then
			TakenTemplates[o.Obj] = true
		end
	end
	PermsList = nil
	
	NoWallSwimSidesWatch = true
	if movementTempDeact then
		DoCall("Set Standard Movement Engine Active", true)
		movementTempDeact = false
	end
	event("LoadScreen", x, y)
	local f = _G['x'..x..'y'..y]
	if f then
		f(x, y)
	end
end

local NewTemplateEv = setmetatable({}, {__index = function(t, a)
	t[a] = "NewTemplate"..a
	return t[a]
end})

function _internal_AddObject(t, st, x, y, z, ...)
	local pieces = {...}
	-- count pieces from bottom to top
	if pieces[2] and mmfObj.IsAbove(pieces[1], pieces[2]) then
		pieces[1], pieces[2] = pieces[2], pieces[1]
	end
	for piece, id in ipairs(pieces) do
		local obj = {Bank = t, Obj = st, BaseX = x, BaseY = y, Layer = z, Piece = piece - 1}
		if t == TemplatesBank then
			obj.Kind = "template"
			obj = MakeObjectEx(id, TemplateProps, obj)
			obj:SetAnimationFrame(0)
			obj:SetValue(5, st)
			TakenTemplates[st] = true
		else
			obj.Kind = (t == 255 and "custom" or "object")
			obj = MakeObjectEx(id, ObjectProps, obj)
		end
		ObjList[obj] = true
		pieces[piece] = obj
		if PickObjects then
			PickObjects[piece] = obj
		end
		if not ScreenObjectsLoading then
			MoveToLayer(id, z)
		end
		CheckGraphicsReplacements(obj)
	end
	CombineObj = pieces[1]
	PickObjects = nil
	if pieces[1] then
		if t == TemplatesBank then
			event(NewTemplateEv[st], unpack(pieces))
			event("NewTemplate", unpack(pieces))
		end
		event("NewObject", unpack(pieces))
	end
end

local IsCombinable = BankObjList{
	[0] = {2, 11, 13, 25, 26, 27, 28, 29, 30, 31},
	[1] = {8, 9, 11, 17, 21, 24},
}

function _internal_CanCreateObject(t, st, ...)
	if not ScreenObjectsLoading then
		CombineT = 0
	end
	ScreenObjectsLoading = true
	CanCreateObject = true
	event("CanCreateObject", t, st, ...)
	-- LoadGhostsWhenEyeIsTaken - remember ghosts
	if t == 12 and CanCreateObject and Objects.Player.Eye == 0 then
		if LoadGhostsWhenEyeIsTaken and ghosts then
			ghosts[#ghosts + 1] = {t, st, ...}
		end
		CanCreateObject = false
	elseif CanCreateObject and CombineObjects and IsCombinable[t*256 + st] then
		local x, y, z = ...
		if CombineX == x and CombineY == y and CombineZ == z and CombineT == t*256 + st and CombineObj then
			CombineX = CombineX + 1
			local dx = CombineObj:GetScaleX()
			CombineObj:SetScaleX(dx + 1)
			CombineObj:SetX(CombineObj:GetX() + CombineObj.PlacementOffsetX)
			-- !!! Bug dependance: remove this 'if' if the bug is fixed in newer MMF
			if t == 1 then
				local x = CombineObj:GetX()
				CombineObj:SetX(x + dx*24)
				CombineObj:AddBackdrop(true)
				CombineObj:SetX(x)
			end
			CanCreateObject = false
		else
			CombineX, CombineY, CombineZ, CombineT = x + 1, y, z, t*256 + st
		end
	end
end

function _internal_HolorgamCreated()
	Objects.PlayerHologram = MakeObjectEx(6, PlayerHologramProps)
	CheckHologramReplacements()
	event("ShowHologram")
end

function _internal_OnCanShift(id)
	CanShift = true
	event("CanShift", id)
	event("CanShift"..id, id)
end

function _internal_OnShift(id, quantize)
	event("Shift", id, quantize)
	event("Shift"..id, id, quantize)
end

function _internal_OnWarp()
	event("Warp", Game.MapX, Game.MapY)
	event(("x%dy%dwarp"):format(Game.MapX, Game.MapY), Game.MapX, Game.MapY)
end

local CurrentTimer

function _internal_OnTimer()
	if IsMovementPaused() or Game.MapX == Game.LastMapX and Game.MapY == Game.LastMapY then
		tick = tick + 1
		globalTick = globalTick + 1
		event("Timer")
		for i = 1, #timeIntervals do
			local interval = timeIntervals[i]
			if (tick % interval)*interval < 1 then
				CurrentTimer = i
				timeFunctions[i](tick)
			end
		end
		CurrentTimer = nil

		-- load ghosts when eye is taken
		if ghosts and LoadGhostsWhenEyeIsTaken and Objects.Player.Eye ~= 0 then
			for i = 1, #ghosts do
				Objects.new(unpack(ghosts[i]))
			end
			ghosts = nil
		end
	end
	-- destroy up to 10 left-overs from privious frame
	for i = 1, 10 do
		local id = next(DestroyList)
		if not id then
			break
		end
		DestroyList[id] = nil
		mmfObj.Destroy(id)
	end
end

UmbrellaOffsetX, UmbrellaOffsetY = 0, 0

function _internal_OnTimer2()
	if (UmbrellaOffsetX ~= 0 or UmbrellaOffsetY ~= 0) and Objects.Umbrella:GetY() > -50 then
		Objects.Umbrella:SetX(Objects.PlayerPos:GetX() + UmbrellaOffsetX*(Objects.PlayerPos:GetDirection() == 0 and 1 or -1))
		Objects.Umbrella:SetY(Objects.PlayerPos:GetY() + UmbrellaOffsetY)
	end
	event("Timer2", not IsMovementPaused())
end

-- currently called from Text Blitter
function _internal_OnDrawFrame()
	if NoWallSwimSides and NoWallSwimSidesWatch then
		DoNoWallswim(NoWallSwimSides)
		NoWallSwimSides = nil
	end
	DoObjectsAnimation()
	event("DrawFrame")
end

function Timer(int, f)
	local i = #timeIntervals + 1
	if f == nil then
		int, f = 1, int
	end
	timeIntervals[i] = int
	timeFunctions[i] = f
end

local function nullsub()
end

function RemoveTimer(f)
	if f then
		for i = 1, #timeFunctions do
			if timeFunctions[i] == f then
				timeFunctions[i] = nullsub
			end
		end
	elseif CurrentTimer then
		timeFunctions[CurrentTimer] = nullsub
	end
end

function GetTick()
	return tick
end

function GetGlobalTick()
	return globalTick
end

vars = {}  -- variables for use of level scripts

local function serialize(o)
	local tp = type(o)
	if tp == "number" or tp == "boolean" or tp == "nil" then
		return tostring(o)
	elseif tp == "string" then
		return string.gsub(string.format("%q", o), "\\\n", "\\n")
	elseif tp == "table" then
		local a = {"{"}
		for k, v in pairs(o) do
			a[#a+1] = (#a == 1 and "[" or ", [")
			a[#a+1] = serialize(k)
			a[#a+1] = "] = "
			a[#a+1] = serialize(v)
		end
		a[#a+1] = "}"
		return table.concat(a)
	else
		error("cannot serialize a " .. tp)
	end
end

function _internal_SaveGame()
	event("SaveGame")
	local s, s1 = serialize(vars), ""
	local i = 0
	while #s > 1022*(i + 1) do
		DoCall("Write To Save Game", "Lua", i > 0 and "vars"..i or "vars", "|"..s:sub(1 + i*1022, 1022 + i*1022))
		i = i + 1
		s1 = "!"
	end
	DoCall("Write To Save Game", "Lua", i > 0 and "vars"..i or "vars", s1..s:sub(1 + i*1022))
end

local InitGame

function _internal_LoadGame()
	PlayerDead = false
	vars = {}
	local s = ""
	local s1 = DoCall("Read From Save Game", "Lua", "vars")
	local middle, last = ("|"):byte(), ("!"):byte()
	local i = 1
	while s1:byte() == middle do
		s = s..s1:sub(2)
		s1 = DoCall("Read From Save Game", "Lua", "vars"..i)
		i = i + 1
	end
	if s1:byte() == last then
		s = s..s1:sub(2)
	else
		s = s1
	end
	local f = loadstring("return "..s)
	if f then
		setfenv(f, {})
		local ok, v = pcall(f)
		if ok and v ~= nil then
			vars = v
		end
	end
	if InitGame then
		InitGame()
	end
	event("LoadGame")
end

function SaveGame(x, y)
	if not x then
		x = math.floor(Objects.PlayerPos:GetX()/24)
		if x < 0 then  x = 0  end
		if x > 24 then  x = 24 end
	end
	if not y then
		y = y or math.floor(Objects.PlayerPos:GetY()/24)
		if y < 0 then  y = 0  end
		if y > 9 then  y = 9  end
	end
	DoCall("Save Game", x, y)
end

function _internal_OnCheckObstacleOverlap(over)
	ObstacleOverlap = (over == true)
	event("CheckObstacleOverlap", Objects.PlayerPos)
end

function _internal_OnCanClimb(can)
	CanClimb = can
	event("CanClimb")
end

function CheckNoClimb()
	return (DoCall("CheckNoClimb") == true)
end

function _internal_IsNoJump(b)
	IsNoJump = (b == true)
	event("IsNoJump")
end

function CheckNoJump()
	_internal_IsNoJump(DoCall("CheckNoJump"))
	return not not IsNoJump
end

function _internal_IsSticky(b)
	IsSticky = (b == true)
	event("IsSticky")
end

function CheckSticky()
	_internal_IsSticky(DoCall("CheckSticky"))
	return not not IsSticky
end

function CheckUpWind()
	return (DoCall("CheckUpWind") == true)
end

function _internal_CheckHologramActivation(allow)
	AllowHologram = not not allow
	event("HologramActivateCheck")
end

function _internal_CheckDeath(restart)
	AllowDeath = true
	event("Death", restart)
	if AllowDeath then
		PlayerDead = true
	end
end

function Die()
	DoCall("Die")
end

function MakeDoubleJumpCloud(x, y)
	DoCall("MakeDoubleJumpCloud", x or 0, y or 6)
end

function PickUpLight(x, y)
	DoCall("PickUpLight", x or Objects.PlayerPos:GetX(), y or Objects.PlayerPos:GetY())
end

function RestartGameplay(TmpSave)
	DoCall("RestartGameplay", not not TmpSave)
end

function DeactivateMovement(perm)
	movementTempDeact = not perm or movementTempDeact
	DoCall("Set Standard Movement Engine Active", false)
end

function PlaySound(name, repeats, chan)
	if chan then
		chan, Objects.Sound.NextAllocatedChannel = Objects.Sound.NextAllocatedChannel, chan
	end
	DoCall(type(name) == "number" and "Play Default Sound" or "PlaySound", name, repeats or 1)
	if chan then
		Objects.Sound.NextAllocatedChannel = chan
	end
end

function MuteSounds(b)
	b = b or (b == nil)
	local r = Objects.Sound.ForceMute >= 2
	if b and not r then
		Objects.Sound.ForceMute = Objects.Sound.ForceMute + 2
	elseif not b and r then
		Objects.Sound.ForceMute = Objects.Sound.ForceMute % 2
	end
	StopSounds()
	return r
end

function MuteMusic(b)
	b = b or (b == nil)
	local r = Objects.Sound.ForceMute % 2 >= 0
	if b and not r then
		Objects.Sound.ForceMute = Objects.Sound.ForceMute + 1
	elseif not b and r then
		Objects.Sound.ForceMute = Objects.Sound.ForceMute - 1
	end
	return r
end

function _internal_PlaySound(snd, chan, repeats)
	ReplaceSound = snd
	event("ReplaceSound", snd)
	if repeats ~= 0 or type(ReplaceSound) ~= "number" then
		PlaySound(ReplaceSound, repeats, chan)
	end
end

function _internal_MayUseSpring(ok)
	MayUseSpring = (ok == true)
	event("MayUseSpring")
end

function _internal_IsStanding(stand)
	IsStanding = (stand == true)
	event("IsStanding")
end

function _internal_OnSetPlayerDirection()
	event("SetPlayerDirection")
end

function _internal_MusicLoops(song)
	event("MusicLoops", song)
end

function path.isfile(s)
	return not not DoCall("path.isfile", s)
end
path.IsFile = path.isfile

function DeleteBackdrops(layer)
	DoCall("DeleteBackdrops", assert(layer))
	event("DeleteBackdrops", layer)
end

function IsScreenLoading()
	return not not DoCall("Is Render Active")
end

-----------------------------------------------
-- Ini files manipulation
-----------------------------------------------

function WorldIniString(sect, ident, def)
	return DoCall("ReadWorldIni", sect or "World", assert(ident), def or "")
end

function SaveGameString(sect, ident)
	return DoCall("Read From Save Game", sect or "Lua", assert(ident))
end

function ReadIniString(ini, sect, ident, def)
	return DoCall("ReadIniString", assert(ini), assert(sect), assert(ident), def or "")
end


function WorldIniNumber(sect, ident, def)
	return tonumber(DoCall("ReadWorldIni", sect or "World", assert(ident), "")) or tonumber(def) or def ~= nil and 0 or nil
end

function SaveGameNumber(sect, ident, def)
	return tonumber(DoCall("Read From Save Game", sect or "Lua", assert(ident))) or tonumber(def) or def ~= nil and 0 or nil
end

function ReadIniNumber(ini, sect, ident, def)
	return tonumber(DoCall("ReadIniString", assert(ini), sect, assert(ident), "")) or tonumber(def) or def ~= nil and 0 or nil
end


local function tobool(r, def)
	local n = tonumber(r)
	if n then
		return n ~= 0
	end
	r = r:lower()
	if r == "true" then
		return true
	elseif r == "false" then
		return false
	end
	if def ~= nil then
		return not not def
	end
end

function WorldIniBool(sect, ident, def)
	return tobool(DoCall("ReadWorldIni", sect or "World", assert(ident), ""), def)
end

function SaveGameBool(sect, ident, def)
	return tobool(DoCall("Read From Save Game", sect or "Lua", assert(ident)), def)
end

function ReadIniBool(ini, sect, ident, def)
	return tobool(DoCall("ReadIniString", assert(ini), sect, assert(ident), ""), def)
end

function SaveGameWrite(sect, ident, v)
	DoCall("Write To Save Game", sect or "Lua", assert(ident), tostring(v))
end

-----------------------------------------------
-- Win events
-----------------------------------------------

-- local function ParseMCoords(a)
	-- local x = a % 0x10000
	-- local y = (a - x) / 0x10000
	-- return (x >= 0x8000 and x - 0x10000 or x), (y >= 0x8000 and y - 0x10000 or y)
-- end
local function ParseMCoords(lp)
	return mmf.Mouse.GetX(), mmf.Mouse.GetY()
end

win.ExportMessage(0x0200, function(wp, lp)
	event("MouseMove", ParseMCoords(lp))
end)

-- left

win.ExportMessage(0x0201, function(wp, lp)
	local x, y = ParseMCoords(lp)
	event("MouseDown", x, y)
	event("MouseClick", x, y, false)
end)

win.ExportMessage(0x0202, function(wp, lp)
	event("MouseUp", ParseMCoords(lp))
end)

win.ExportMessage(0x0203, function(wp, lp)
	local x, y = ParseMCoords(lp)
	event("MouseClick", x, y, true)
end)

-- right

win.ExportMessage(0x0204, function(wp, lp)
	DoCall("MouseRightDown")
	local x, y = ParseMCoords(lp)
	event("MouseRightDown", x, y)
	event("MouseRightClick", x, y, false)
end)

win.ExportMessage(0x0205, function(wp, lp)
	event("MouseRightUp", ParseMCoords(lp))
end)

win.ExportMessage(0x0206, function(wp, lp)
	DoCall("MouseRightDown")
	local x, y = ParseMCoords(lp)
	event("MouseRightClick", x, y, true)
end)

-- right

win.ExportMessage(0x0207, function(wp, lp)
	local x, y = ParseMCoords(lp)
	event("MouseMiddleDown", x, y)
	event("MouseMiddleClick", x, y, false)
end)

win.ExportMessage(0x0208, function(wp, lp)
	event("MouseMiddleUp", ParseMCoords(lp))
end)

win.ExportMessage(0x0209, function(wp, lp)
	local x, y = ParseMCoords(lp)
	event("MouseMiddleClick", x, y, true)
end)

-- wheel

win.ExportMessage(0x020A, function(wp, lp)
	local delta = math.floor(wp / 0x10000)
	event("MouseWheel", (delta >= 0x8000 and delta - 0x10000 or delta), ParseMCoords(lp))
end)

-----------------------------------------------
-- Game variables interface
-----------------------------------------------
Game = {}

do
	local vals = {
		MapX = 1,
		MapY = 2,
		Mode = 3,
		CurrentlyPlayingSong = 4,
		SongFader = 5,
		MusicVolume = 6,
		AmbianceVolumeA = 7,
		SoundVolume = 8,
		MenuMusicHasStarted = 9,
		MuteSound = 10,
		--UnusedB = 11,
		SettingsLoaded = 12,
		CheatEnabled = 13,
		LevelFormatVersion = 14,
		LastMapX = 15,
		LastMapY = 16,
		DeathDelay = 18,
		WhiteDeathDelay = 19,
		LoadShiftTemp = 20,
		--Version = 21,
		AmbianceVolumeB = 23,
	}

	local strs = {
		World = 1,
		FullSavegamePath = 2,
		Cutscene = 3,
		ScreenMode = 4,
		CriticalError = 5,
		CutsceneDestination = 6,
	}
	
	for k, v in pairs(strs) do
		vals[k] = -v
	end
	
	local function index(_, name)
		local id = vals[name]
		if id > 0 then
			return mmf.Global.GetValue(id - 1)
		else
			return mmf.Global.GetString(-id - 1)
		end
	end

	local function newindex(_, name, v)
		local id = vals[name]
		if id > 0 then
			mmf.Global.SetValue(id - 1, v)
		else
			--mmf.Global.SetString(-id - 1, v)
			error("attempt to change a read-only global string")
		end
	end

	setmetatable(Game, {__index = index, __newindex = newindex})
end

-----------------------------------------------
-- Platform object
-----------------------------------------------

do
	local props = {
		XVelocity = true,
		YVelocity = true,
		MaxXVelocity = true,
		MaxYVelocity = true,
		XAcceleration = true,
		XDeceleration = true,
		Gravity = true,
		JumpStrength = true,
		JumpHoldHeight = true,
		MaxStepUp = true,
		SlopeCorrection = true,
		AdditionalXVelocity = true,
		AdditionalYVelocity = true,
	}

	local function index(_, name)
		if props[name] then
			return DoCall("Platform.Get"..name)
		end
	end

	local function newindex(t, name, v)
		if props[name] then
			DoCall("Platform.Set"..name, v)
		else
			rawset(t, name, v)
		end
	end
	
	Objects.Platform = setmetatable({}, {__index = index, __newindex = newindex})
end

local function PlatformReg(name)
	Objects.Platform[name] = function(_, ...)
		return DoCall("Platform."..name, ...)
	end
end

PlatformReg "Pause"
PlatformReg "Unpause"
PlatformReg "Destroy"
PlatformReg "ObstacleOverlap"

-- PlatformReg "SetVelocity"
-- PlatformReg "SetMaxVelocity"
-- PlatformReg "SetXAcceleration"
-- PlatformReg "SetXDeceleration"
-- PlatformReg "SetGravity"
-- PlatformReg "SetJumpStrength"
-- PlatformReg "SetJumpHoldHeight"
-- PlatformReg "SetMaxStepUp"
-- PlatformReg "SetSlopeCorrection"
-- PlatformReg "SetAdditionalVelocity"
-- PlatformReg "GetVelocity"
-- PlatformReg "GetMaxVelocity"
-- PlatformReg "GetXAcceleration"
-- PlatformReg "GetXDeceleration"
-- PlatformReg "GetGravity"
-- PlatformReg "GetJumpStrength"
-- PlatformReg "GetJumpHoldHeight"
-- PlatformReg "GetMaxStepUp"
-- PlatformReg "GetSlopeCorrection"
-- PlatformReg "GetAdditionalVelocity"


-----------------------------------------------
-- Other Files
-----------------------------------------------

Version = mmf.Global.GetValue(20)

dofile(AppPath.."Data/Lua/Functions.lua")
dofile(AppPath.."Data/Lua/cutscene.lua")
dofile(AppPath.."Data/Lua/Map.lua")

function BouncingBallMode(...)
	return dofile(AppPath.."Data/Lua/BouncingBall.lua", ...)
end

function VVVVVVMode(...)
	return dofile(AppPath.."Data/Lua/VVVVVV.lua", ...)
end

function NoWalkOnAir(...)
	return dofile(AppPath.."Data/Lua/NoWalkOnAir.lua", ...)
end

function NoFishInWalls(...)
	return dofile(AppPath.."Data/Lua/NoFishInWalls.lua", ...)
end

-----------------------------------------------
-- Create Data\UserScript.lua
-----------------------------------------------

if not path.isfile(AppPath.."Data/UserScript.lua") then
	io.SaveString(AppPath.."Data/UserScript.lua", "")
end

-----------------------------------------------
-- Remove Dangerous Functions
-----------------------------------------------

local load_old = load
local string_byte = string.byte
local io_open = io.open

function load(f, name)
	local s
	repeat
		s = f()
	until s ~= ""
	if s ~= nil and string_byte(s) == 0x1B then
		return nil, "attempt to load a binary chunk"
	end
	return load_old(function()
		if s == "" then
			return f()
		end
		local s1 = s
		s = ""
		return s1
	end, name)
end

function loadstring(s, name)
	return load(function()
		local s1 = s
		s = nil
		return s1
	end, name)
end

function loadfile(path)
	local f, s = io_open(path, "rb")
	if f == nil then
		return nil, s
	end
	s = f:read("*a")
	f:close()
	return loadstring(s, "@"..path)
end

require = nil
io = nil
os.execute = nil
os.remove = nil
os.rename = nil

package.loadlib = nil
package.loaders[3] = nil
package.loaders[4] = nil

debug.getupvalue = nil
debug.setupvalue = nil
debug.getlocal = nil
debug.setlocal = nil

xlua = nil
win = nil
jit = nil  -- don't even know what's in there

do
	local DangerList = {9, 11, 12, 14, 20, 21, 22}
	local Dangerous = {}
	for _, v in ipairs(DangerList) do
		Dangerous[v - 1] = true
	end
	
	local old = mmf.Global.SetValue
	function mmf.Global.SetValue(id, v)
		id = assert(tonumber(id))
		if Dangerous[id] then
			error("attempt to change a read-only global value")
		end
		return old(id, v)
	end
end

mmf.Global.SetString = nil

-------------------------------------------------------------------------------
-- Run UserScript.lua, read some World.ini options, run Script.lua
-------------------------------------------------------------------------------

local function CheckFile(s)
	local f = io_open(s, "rb")
	if f then
		f:close()
		return s
	end
end

function LoadFont(s)
	if s ~= "" then
		s = CheckFile(("%s/Fonts/%s.png"):format(WorldPath, s)) or CheckFile(("%s/Data/Fonts/%s.png"):format(AppPath, s))
		if s then
			Objects.SignText:SetCharacters(s, 7, 13)
		end
	end
end

function InitGame()  -- defined before
	CombineObjects = true
	InitGame = nil
	dofile(AppPath.."Data/UserScript.lua")
	if not OriginalPickUpLight then
		ReplaceGraphics({BaseIndex = 1, HotSpotX = 13, HotSpotY = 13, ActionX = 13, ActionY = 13,
			AppPath.."Data/Custom Objects/Pick Up Light/Pick Up Light", 1, 2}, Objects.Child(22)):Destroy()
	end

	ScreenScrollDetectionDelta = WorldIniNumber("KS Ex", "ScreenScrollDetectionDelta", ScreenScrollDetectionDelta or 1)
	NoStuckUmbrella = WorldIniBool("KS Ex", "NoStuckUmbrella", NoStuckUmbrella or false)
	FixCutscenes = WorldIniBool("KS Ex", "FixCutscenes", FixCutscenes or false)
	AllowMap = WorldIniBool("KS Ex", "AllowMap", AllowMap)
	if WorldIniBool("KS Ex", "NoWalkOnAir") then
		NoWalkOnAir()
	end
	if WorldIniBool("KS Ex", "NoFishInWalls") then
		NoFishInWalls()
	end
	if WorldIniBool("KS Ex", "BouncingBallMode") then
		BouncingBallMode()
	end
	if WorldIniBool("KS Ex", "VVVVVVMode") then
		VVVVVVMode()
	end
	NoLoadScreenDelay = WorldIniBool("KS Ex", "NoLoadScreenDelay", NoLoadScreenDelay or false)
	MusicLoops = WorldIniNumber("KS Ex", "MusicLoops", MusicLoops or 1)
	ShiftsDelay = WorldIniNumber("KS Ex", "ShiftsDelay", -1)
	
	LoadFont(WorldIniString("KS Ex", "Font", DefaultFont or ""))

	if not WorldIniBool("Templates", "ManualLoad") then
		LoadTemplates()
	end
	
	if path.isfile(WorldPath.."Script.lua") then
		dofile(WorldPath.."Script.lua")
	end
	ShiftsDelay = ShiftsDelay >= 0 and ShiftsDelay or NoLoadScreenDelay and 0 or 1
end

local max = math.max
local min = math.min
local abs = math.abs
local floor = math.floor

BouncingBall = {
	-- force
	GravityX = 0,
	GravityY = 45,
	GravityMul = 1,
	GravityMulBase = 1,
	GravityMulUmbrella = 0.5,
	ForceX = 0,
	ForceY = 0,
	ForceMul = 1,

	-- friction
	Friction = 0.4,
	HAirFriction = 4,
	Deceleration = 0,
	
	-- keys
	KeysAccel = 50,
	MaxKeysSpeed = nil,
	MaxKeysSpeedRun = 10000,
	MaxKeysSpeedNoRun = 240,

	-- speed limits
	MaxSpeed = nil,
	MaxSpeedBase = 800,
	MaxSpeedUmbrella = 300,
	MaxBounceSpeed = nil,
	MaxBounceSpeedHiJump = 530,
	MaxBounceSpeedNoHiJump = 400,
	MinBounceSpeed = 200,
	MinBounceWallSpeed = 30,
	MinBounceClimbSpeed = 200,
	MinBounceStopSpeed = 150,
	NoWallBounceSpeed = 49,
	
	LiteBounceSoundSpeed = 380,
	NoBounceSoundSpeed = 80,
	
	-- climbing
	CanClimb = true,
	ClimbUpSpeed = 500,
	ClimbStaySpeed = 0,
	ClimbDownSpeed = 0,
	ClimbUpFriction = 0.8,
	ClimbStayFriction = 0.4,
	ClimbDownFriction = 0,
	-- current climbing
	WallClimbSpeed = nil,
	
	-- bounce speed multipliers
	BounceJump = 1.5,
	BounceNorm = 0.85,
	BounceStop = 0.3,
	-- current bounce speed multiplier
	BounceMul = nil,
	
	-- collision speed which leads to ball death
	--BreakSpeed = 650,
	
	-- flying
	FlyDelay = 10,
	FlyCount = 0,
	FlyCountLeft = 0,
	FlyCountBase = 3,
	FreeFly = false,
	FlySpeed = 220,
	FlyMul = 0.5,
	
	-- current speed
	SpeedX = 0,
	SpeedY = 0,
	
	-- max number of pixels the ball may move before a check for collision occurs
	-- set this to a value less than the radius of the ball
	MaxStep = 2,
	
	-- set Gravity to -45 and set UpsideDown to true to invert the thing
	UpsideDown = false,
	
	-- X, Y - current coordinates
	-- NoSlopes - disable slopes detection
	-- SlopeTests - ask me about it in case you decide to change the shape of the ball
	-- NoSlopeLimits - allow jumps higher than current powerups allow when bouncing off slopes/corners
	-- WasCollision - Set to true if there was a collision on this step
	-- BounceKind - kind of bounce: Norm, Jump, Stop
	-- NoStandardGraphics - set to true to use custom graphics for the ball
	-- NoStandardAnimation - set to true to choose ball animation manually
	
	-- OnBounce(LastSpeedX, LastSpeedY, FallSpeed) - called when a ball bounces to play bounce sound and break glass ball
	-- events.BallBounce(LastSpeedX, LastSpeedY, FallSpeed) - event happening after call to OnBounce
	-- UpdateConfig() - called to update ball parameters according to powers being used and pressed keys
}

local ball = BouncingBall

local AccelCoef = 1/2 /2  -- acceleration is applied twice a tick, which makes 1/2 a tick
local SpeedCoef = 1/100


local LastIntX, LastIntY
local MoveHologram
local CheckCollisions
local MoveDeact, MoveTempDeact
local DownSign
local BallBody

DeactivateMovement(true)
Objects.Platform:Destroy()
EnableKeysInput(false)
ScreenScrollDetectionDelta = 0



local function sgn1(a)  -- not quite 'sgn'
	if a >= 0 then
		return 1
	else
		return -1
	end
end

local KeysEnabled = true

function EnableKeysInput(on)
	KeysEnabled = not not on
end

function IsKeysInputEnabled()
	return KeysEnabled and not IsMovementPaused()
end

local function CheckKey(key)
	return KeysEnabled and Controls.check(key)
end

local CheckOverlap

do
	local function DoCheckOverlap()
		ObstacleOverlap = (DoCall("CheckObstacleOverlap", Objects.PlayerPos.ID) == true)
		CanClimb = ObstacleOverlap and not CheckNoClimb()
		events.global.CheckObstacleOverlap(Objects.PlayerPos)
		events.CheckObstacleOverlap(Objects.PlayerPos)
	end
	
	function CheckOverlap(dx, dy)
		dx = dx or 0
		dy = dy or 0
		if dx ~= 0 or dy ~= 0 then
			local x, y = Objects.PlayerPos:GetPosition()
			Objects.PlayerPos:SetPosition(x + dx, y + dy)
			DoCheckOverlap()
			Objects.PlayerPos:SetPosition(x, y)
		else
			DoCheckOverlap()
		end
		return ObstacleOverlap
	end
end



local function ApplyPos()
	LastIntX, LastIntY = floor(ball.X + 0.5), floor(ball.Y + 0.5)
	Objects.PlayerPos:SetPosition(LastIntX, LastIntY)
end

local function MoveByPixel(t)
	local sx, sy = ball.SpeedX, ball.SpeedY
	local x, y = ball.X, ball.Y
	t = min(t, min((LastIntX + sgn1(sx) - x)/sx, (LastIntY + sgn1(sy) - y)/sy))
	ball.X = x + sx*t
	ball.Y = y + sx*t
	return t
end

local function ApplySpeed(spdDone, NoSetDir)
	spdDone = spdDone or 0
	local sx, sy = ball.SpeedX, ball.SpeedY
	local spd = math.sqrt(sx*sx + sy*sy)
	local sx, sy = sx/spd, sy/spd
	if spd > ball.MaxSpeed then
		ball.SpeedX, ball.SpeedY = sx*ball.MaxSpeed, sy*ball.MaxSpeed
		spd = ball.MaxSpeed
	end
	if not nomove and spd > spdDone then
		spd = spd - spdDone
		if spd*SpeedCoef > ball.MaxStep then
			ball.X = ball.X + sx*ball.MaxStep
			ball.Y = ball.Y + sy*ball.MaxStep
			ApplyPos()
			if not CheckCollisions() then
				return ApplySpeed(spdDone + ball.MaxStep/SpeedCoef)
			end
		else
			ball.X = ball.X + sx*spd*SpeedCoef
			ball.Y = ball.Y + sy*spd*SpeedCoef
		end
	end
	if ball.SpeedX ~= 0 and not NoSetDir then
		Objects.PlayerPos:SetDirection(ball.SpeedX < 0 and 16 or 0)
		Objects.PlayerPos:SetAnimationDirection(0)
	end
	return ApplyPos()
end

-- Slopes checking

local PixelTest = Objects.ClimbChecker --NewGlobalTemplate(-1, -1)  -- temporary solution
--PixelTest.Permanent = 1
PixelTest:LoadFrame{AppPath.."Data/Custom Objects/Pixel.png", TransparentColor = 0xFF}
PixelTest:SetVisibility(false)

ball.SlopeTests = {
	7, 0, 0,
	7, 1, 9.5,
	5, 4, 45,
	6, 3, 31,
	7, 2, 18.5,
	4, 5, 59,
	3, 6, 71.5,
}

local function SetPixelTest(x, y)
	x = x < 0 and 0 or x > 599 and 599 or x
	y = y < 0 and 0 or y > 239 and 239 or y
	PixelTest:SetPosition(x, y)
end

local function SlopesTest(flip, ...)
	local x, y = ball.X, ball.Y
	local s = {...}
	local SlopeTests = ball.SlopeTests
	for i = 1, #SlopeTests, 3 do
		SetPixelTest(x + s[1]*SlopeTests[i + (flip and 1 or 0)], y + s[2]*SlopeTests[i + (flip and 0 or 1)])
		if PixelTest:OverlapsObstacle() then
			return SlopeTests[i + 2], s[1]*s[2]*(flip and 1 or -1)
		end
		s[flip and 1 or 2] = -s[flip and 1 or 2]
		SetPixelTest(x + s[1]*SlopeTests[i + (flip and 1 or 0)], y + s[2]*SlopeTests[i + (flip and 0 or 1)])
		if PixelTest:OverlapsObstacle() then
			return SlopeTests[i + 2], s[1]*s[2]*(flip and 1 or -1)
		end
		s[flip and 1 or 2] = -s[flip and 1 or 2]
	end
end

local function CheckSlopes(bounceX, bounceY, climb)
	local ax, ay, sx, sy
	if bounceX then
		ax, sx = SlopesTest(false, sgn1(ball.SpeedX), sgn1(ball.SpeedY))
	end
	if bounceY then
		ay, sy = SlopesTest(true, sgn1(ball.SpeedX), sgn1(ball.SpeedY))
	end
	if ay and ay >= (climb and ball.SpeedY*DownSign > 0 and 45 or 50) then
		ax, ay = nil, ay - 90
		bounceX, bounceY = true, false
	elseif ax and ax >= (ay and 45 or 50) then
		ax, ay = ax - 90, nil
		bounceX, bounceY = false, true
	elseif ax and ay then
		ax, ay = 0, nil
	end
	ax, ay = ax and ax*sx, ay and ay*sy
	return bounceX, bounceY, (ax or ay or 0)*math.pi/180
end

-- CheckCollisions

local function DoBounce(s, MinSpeed, mul)
	return -sgn1(s) * min(ball.MaxBounceSpeed, max(MinSpeed, abs(s) * (mul or ball.BounceMul)))
end

local function DoFriction(s, friction)
	return sgn1(s)*max(0, abs(s) - abs(friction))
end

local function DoSlopeLimit(s, old)
	local oldmod = old*sgn1(s)
	if abs(s) > max(oldmod, ball.MaxBounceSpeed) then
		if oldmod > ball.MaxBounceSpeed then
			return old
		end
		return ball.MaxBounceSpeed*sgn1(s)
	end
	return s
end

function CheckCollisions()
	local ix, iy = Objects.PlayerPos:GetPosition()
	if CheckOverlap() then
		ball.WasCollision = true
		events.global.CanClimb()
		events.CanClimb()
		local canClimb = CanClimb
		local impact = -1
		local sx, sy = ball.SpeedX, ball.SpeedY
		local bounceX, bounceY

		-- find collision point and direction (ugly, but reliable way that also works for wallswims)
		local function CheckInScreen(x, xo, lim)
			return not (x < xo and x < 0 and x >= -24 or x > xo and x >= lim and x < lim + 24)
		end
		
		local function test(dx, dy)
			if (dx ~= 0 or dy ~= 0) and (dx == 0 or dx*sx < 0) and (dy == 0 or dy*sy < 0) and
					CheckInScreen(ix + dx, ix, 600) and CheckInScreen(iy + dy, iy, 240) and not CheckOverlap(dx, dy) then
				if dx ~= 0 and dy ~= 0 then
					while not CheckOverlap(dx - sgn1(dx), dy) do
						dx = dx - sgn1(dx)
					end
					while not CheckOverlap(dx, dy - sgn1(dy)) do
						dy = dy - sgn1(dy)
					end
				end
				if dx ~= 0 then
					ball.X = ix + dx
					bounceX = true
				end
				if dy ~= 0 then
					ball.Y = iy + dy
					bounceY = true
				end
				return true
			end
		end

		if sx ~= 0 or sy ~= 0 then
			for i = 1, 50 do
				local j = math.floor(i*0.7 + 0.5)
				if test(0, -i) or test(0, i) or test(-i, 0) or test(i, 0) or
					 test(-j, -j) or test(j, -j) or test(-j, j) or test(j, j) then
					break
				end
			end
		end

		
		-- collision surface speed
		local SurfaceSpeed = {
			X = 0,
			Y = 0,
		}
		Objects.PlayerPos:SetPosition(ball.X + (bounceX and sgn1(sx) or 0), ball.Y + (bounceY and sgn1(sy) or 0))
		events.BounceSurfaceSpeed(SurfaceSpeed)
		sx, sy = sx - SurfaceSpeed.X, sy - SurfaceSpeed.Y
		local oldSX, oldSY = sx, sy
		
		local climb = ball.WallClimbSpeed ~= 0 and canClimb
		-- angles
		local angle, si, co
		if ball.NoSlopes then
			angle = 0
		else
			bounceX, bounceY, angle = CheckSlopes(bounceX, bounceY, climb)
		end
		si, co = math.sin(angle), math.cos(angle)
		if angle ~= 0 then
			sx, sy = sx*co - sy*si, sy*co + sx*si
		end
		
		local minBounceY = ball.BounceKind == "Stop" and ball.MinBounceStopSpeed or ball.MinBounceSpeed
		if bounceX then
			local minBounce = climb and ball.MinBounceClimbSpeed or ball.MinBounceWallSpeed
			if sy*DownSign > 0 then
				minBounce = minBounce*abs(co) + minBounceY*abs(si)
			end
			ball.SpeedX = DoBounce(sx, minBounce)
			impact = abs(sx)
			if ball.CanClimb and canClimb then
				ball.FlyCountLeft = 0
			end
		end
		if bounceY then
			local nojump = CheckNoJump()
			local mul = nojump and ball.BounceStop or ball.BounceMul
			if sy*DownSign > 0 then
				ball.SpeedY = DoBounce(sy, minBounceY*abs(co) + ball.MinBounceWallSpeed*abs(si), mul)
			else
				ball.SpeedY = DoBounce(sy, ball.MinBounceWallSpeed, mul)
			end
			impact = max(impact, abs(sy))
			if sy*DownSign > 0 then
				if not nojump then
					ball.FlyCountLeft = 0
				end
				if abs(ball.SpeedY) > ball.MinBounceSpeed then
					Objects.KBD.JumpOneshot = 1
					Objects.PlayerPos.JustJumped = 1
				end
				if MoveHologram and Objects.PlayerHologram then
					Objects.PlayerVisiblePos:SetPosition(ball.X, ball.Y)
					Objects.PlayerHologram:SetPosition(ball.X, ball.Y)
					Objects.PlayerHologram:SetAnimationDirection(0)
				end
				MoveHologram = false
			end
		end
		if not bounceX then
			ball.SpeedX = CheckSticky() and 0 or DoFriction(sx, sy*ball.Friction)--ball.SpeedY - sy)
		end
		if not bounceY then
			ball.SpeedY = DoFriction(sy, sx*(canClimb and ClimbFriction or ball.Friction)) --ball.SpeedX - sx)
			if ball.WallClimbSpeed ~= 0 and canClimb then
				local spd = math.sqrt(ball.SpeedX*ball.SpeedX + ball.SpeedY*ball.SpeedY)
				ball.SpeedY = ball.SpeedY - ball.WallClimbSpeed*abs(co)
				spd = spd/math.sqrt(ball.SpeedX*ball.SpeedX + ball.SpeedY*ball.SpeedY)
				ball.SpeedX = ball.SpeedX*spd
				ball.SpeedY = ball.SpeedY*spd
			elseif abs(ball.SpeedX) < ball.NoWallBounceSpeed then 
				ball.SpeedX = 0
			end
		end
		if angle ~= 0 then
			sx, sy = sx*co + sy*si, sy*co - sx*si
			ball.SpeedX, ball.SpeedY = ball.SpeedX*co + ball.SpeedY*si, ball.SpeedY*co - ball.SpeedX*si
			if not ball.NoSlopeLimits then
				ball.SpeedX = DoSlopeLimit(ball.SpeedX, oldSX)
				ball.SpeedY = DoSlopeLimit(ball.SpeedY, oldSY)
			end
		end
		sx, sy = sx + SurfaceSpeed.X, sy + SurfaceSpeed.Y
		ball.SpeedX, ball.SpeedY = ball.SpeedX + SurfaceSpeed.X, ball.SpeedY + SurfaceSpeed.Y
		ApplySpeed(math.huge, true)
		ball.OnBounce(sx, sy, impact)
		events.global.BallBounce(sx, sy, impact)
		events.BallBounce(sx, sy, impact)
		
		return true
	end
end

function ball.OnBounce(sx, sy, impact)
	if ball.BreakSpeed and impact > ball.BreakSpeed then
		return Die()
	end
	local spd = math.sqrt((sx - ball.SpeedX)^2 + (sy - ball.SpeedY)^2)
	if spd > ball.LiteBounceSoundSpeed*2 then
		PlaySound(AppPath.."Data/Sounds/Ball Bounce.wav")
	elseif spd > ball.NoBounceSoundSpeed*2 then
		PlaySound(AppPath.."Data/Sounds/Ball Bounce Lite.wav")
	end
end

local BounceNames = {"Stop", "Norm", "Jump"}
local wasHolo
local nextFly = 0

local function CheckKeys()
	ball.UpdateConfig()
	
	Objects.KBD.JumpOneshot = 0
	Objects.KBD.DownOneshot = 0
	Objects.KBD.ItemList = CheckKey("ItemList") and 1 or 0
	local holo = CheckKey("Hologram")
	Objects.KBD.Hologram = not wasHolo and holo and 1 or 0
	wasHolo = holo
	Objects.PlayerPos.JustJumped = 0
	
	local v = 0
	if not MoveDeact and not CheckSticky() then
		if CheckKey("Left") then
			v = v - 1
		end
		if CheckKey("Right") then
			v = v + 1
		end
	end
	Objects.KBD.LeftRight = v
	
	v = 0
	if not MoveDeact then
		if CheckKey("Up") then
			v = v - 1
		end
		if CheckKey("Down") then
			v = v + 1
			if Objects.KBD.UpDown < v then
				Objects.KBD.DownOneshot = 1
			end
		end
	end
	Objects.KBD.UpDown = v
	if not ball.CanClimb then
		ball.WallClimbSpeed = 0
		ClimbFriction = ball.Friction
	elseif v < 0 then
		ball.WallClimbSpeed = ball.ClimbUpSpeed*DownSign
		ClimbFriction = ball.ClimbUpFriction
	elseif v > 0 then
		ball.WallClimbSpeed = ball.ClimbDownSpeed*DownSign
		ClimbFriction = ball.ClimbDownFriction
	else
		ball.WallClimbSpeed = ball.ClimbStaySpeed*DownSign
		ClimbFriction = ball.ClimbStayFriction
	end
	
	local BounceKind = 2
	if not MoveDeact then
		if CheckKey("Jump") then
			BounceKind = BounceKind + 1
		end
		if CheckKey("Walk") then
			BounceKind = BounceKind - 1
		end
	end
	ball.BounceKind = BounceNames[BounceKind]
	ball.BounceMul = ball["Bounce"..ball.BounceKind]
end

function ball.UpdateConfig()
	ball.MaxKeysSpeed = (Objects.Player.Run ~= 0) and ball.MaxKeysSpeedRun or ball.MaxKeysSpeedNoRun
	ball.CanClimb = Objects.Player.Climb ~= 0
	ball.MaxBounceSpeed = (Objects.Player.HighJump ~= 0) and ball.MaxBounceSpeedHiJump or ball.MaxBounceSpeedNoHiJump
	ball.FlyCount = (Objects.Player.DoubleJump ~= 0) and ball.FlyCountBase or 0
	ball.FreeFly = (Objects.Player.Umbrella ~= 0) and CheckUpWind()
	ball.MaxSpeed = ball.MaxSpeedBase
	ball.GravityMul = ball.GravityMulBase
	if Objects.Player.Umbrella ~= 0 and CheckKey("Umbrella") then
		ball.MaxSpeed = ball.MaxSpeedUmbrella
		ball.GravityMul = ball.GravityMulUmbrella
	end
end

local function AirFriction(v, fric)
	if v >= 0 then
		return max(0, v - fric*AccelCoef)
	end
	return min(0, v + fric*AccelCoef)
end

local function ApplyAccel(tick)
	ball.SpeedX = ball.SpeedX + (ball.GravityX*ball.GravityMul + ball.ForceX*ball.ForceMul)*AccelCoef
	ball.SpeedY = ball.SpeedY + (ball.GravityY*ball.GravityMul + ball.ForceY*ball.ForceMul)*AccelCoef
	if ball.Deceleration ~= 0 then
		local v = (ball.SpeedX*ball.SpeedX + ball.SpeedY*ball.SpeedY)^0.5
		if v <= ball.Deceleration*AccelCoef then
			ball.SpeedX, ball.SpeedY = 0, 0
		else
			v = (v - ball.Deceleration*AccelCoef)/v
			ball.SpeedX = ball.SpeedX*v
			ball.SpeedY = ball.SpeedY*v
		end
	end
	v = ball.SpeedX + Objects.KBD.LeftRight*ball.KeysAccel*AccelCoef
	if ball.SpeedX == v then
		v = AirFriction(v, ball.HAirFriction)
	end
	if abs(v) < abs(ball.SpeedX) then
		ball.SpeedX = v
	elseif abs(ball.SpeedX) < ball.MaxKeysSpeed then
		ball.SpeedX = max(-ball.MaxKeysSpeed, min(ball.MaxKeysSpeed, v))
	end
end

local NeedCollisionsCheck

local function MoveBall(tick)
	DownSign = ball.UpsideDown and -1 or 1
	local ix, iy = Objects.PlayerPos:GetPosition()
	if not ball.X or ix ~= LastIntX or iy ~= LastIntY then
		ball.X, ball.Y = ix, iy
	end
	CheckKeys()
	if NeedCollisionsCheck then
		NeedCollisionsCheck = false
		CheckCollisions()
	end
	ApplyAccel()
	if (ball.FreeFly or ball.FlyCount > ball.FlyCountLeft) and GetGlobalTick() >= nextFly and Objects.KBD.UpDown < 0 and not CheckNoJump() then
		if not ball.FreeFly then
			ball.FlyCountLeft = ball.FlyCountLeft + 1
		end
		nextFly = GetGlobalTick() + ball.FlyDelay
		ball.SpeedY = ball.SpeedY*ball.FlyMul - ball.FlySpeed*DownSign
		Objects.KBD.JumpOneshot = 1
		Objects.PlayerPos.JustJumped = 1
		Objects.PlayerPos.JustDoubleJumped = 1
		MakeDoubleJumpCloud(0, 7*DownSign)
		PlaySound(AppPath.."Data/Sounds/Ball Fly.wav")
	else
		Objects.PlayerPos.JustDoubleJumped = 0
	end
	ApplySpeed()
	CheckCollisions()
	Objects.PlayerPos:Update()
	ApplyAccel()
end



local OldTimer = _internal_OnTimer

function _internal_OnTimer(...)
	ball.WasCollision = false
	if IsMovementPaused() or Objects.Player.Cheating ~= 0 then
		ball.X, ball.Y = Objects.PlayerPos:GetPosition()
		ball.SpeedX, ball.SpeedY = 0, 0
		if Objects.Player.Cheating ~= 0 then
			NeedCollisionsCheck = true
		end
		for i = 0, 8 do
			Objects.KBD:SetValue(i, 0)
		end
	elseif Game.MapX == Game.LastMapX and Game.MapY == Game.LastMapY then
		MoveBall()
	end
	BallBody:MoveAbove(Objects.Player.ID)
	BallBody:SetPosition(Objects.PlayerPos:GetPosition())
	BallBody:Update()
	return OldTimer(...)
end


local OldLoadScreen = _internal_AfterLoadScreen

function _internal_AfterLoadScreen(...)
	if MoveTempDeact then
		MoveDeact, MoveTempDeact = false, false
	end
	ball.X, ball.Y = nil, nil
	MoveHologram = false
	NeedCollisionsCheck = true
	BallBody:MoveAbove(Objects.Player.ID)
	BallBody:Update()
	return OldLoadScreen(...)
end


local OldOnShift = _internal_OnShift

function _internal_OnShift(id, quant, ...)
	ball.X, ball.Y = nil, nil
	if quant then
		ball.SpeedX, ball.SpeedY = 0, 0
	end
	NeedCollisionsCheck = true
	return OldOnShift(id, quant, ...)
end


local OldLoadGame = _internal_LoadGame

function _internal_LoadGame(...)
	ball.X, ball.Y = nil, nil
	ball.SpeedX, ball.SpeedY = 0, 0
	nextFly = 0
	ball.FlyCountLeft = 0
	return OldLoadGame(...)
end


local OldCheckHolo = _internal_CheckHologramActivation
function _internal_CheckHologramActivation(allow)
	allow = ((Objects.KBD.Hologram ~= 0 or Objects.PlayerPos.HologramActivationTimer >= 30))
	return OldCheckHolo(allow)
end


local OldShowHolo = _internal_HolorgamCreated
function _internal_HolorgamCreated(...)
	MoveHologram = true
	return OldShowHolo(...)
end


local OldMayUseSpring = _internal_MayUseSpring
function _internal_MayUseSpring()
	OldMayUseSpring(ball.SpeedY > 10)
	if MayUseSpring then
		local sy = ball.SpeedY
		ball.SpeedY = CheckKey("Jump") and -700 or -500
		ball.SpeedX = DoFriction(ball.SpeedX, (abs(ball.SpeedY) + abs(sy))/2)
		ball.FlyCountLeft = 0
	end
end


function DeactivateMovement(perm)
	MoveDeact = true
	MoveTempDeact = not perm or MoveTempDeact
end

-- Copy setup from parameter
if (...) then
	table.copy((...), BouncingBall, true)
end

-- Load ball frames

ball.DefaultReplaceColor = false

BallBody = Objects.NewGlobalTemplate(-1, -1, 5)
Objects.BouncingBall = BallBody
BallBody.Permanent = 1

local OldDrawFrame = _internal_OnDrawFrame

function _internal_OnDrawFrame()
	BallBody:SetVisibility(Objects.Player:GetVisibility())
	BallBody:SetTransparency(Objects.Player:GetTransparency())
	local anim = ball.BounceKind
	if Objects.Player.Umbrella ~= 0 and CheckKey("Umbrella") then
		anim = anim.."Float"
	end
	if not ball.NoStandardAnimation and BallBody.Animation ~= BallBody.Animations[anim] then
		BallBody:Animate(anim)
	end
	if MoveHologram and Objects.PlayerHologram then
		Objects.PlayerVisiblePos:SetPosition(Objects.PlayerPos:GetPosition())
		Objects.PlayerHologram:SetPosition(Objects.PlayerPos:GetPosition())
		Objects.PlayerHologram:SetAnimationDirection(0)
	end
	return OldDrawFrame()
end

local Path = AppPath.."Data/Custom Objects/Bouncing Ball/"
 
--Objects.Player:LoadFrame{AppPath.."Data/Custom Objects/Pixel.png", ActionY = 1}
Objects.Player:LoadFrame{AppPath.."Data/Custom Objects/Pixel.png", ActionY = 5}
Objects.Player:SetAnimation(0)
Objects.Player:SetAnimationFrame(0)
Objects.Player:SetAnimationDirection(0)

if not ball.NoStandardGraphics then

	Objects.PlayerPos:LoadFrame{Path.."Bouncing Ball_1.png", HotSpotX = 12, HotSpotY = 13}
	Objects.PlayerPos:LoadFrame{Path.."Bouncing Ball_1.png", Direction = 16, HotSpotX = 12, HotSpotY = 13}
	Objects.PlayerVisiblePos:LoadFrame{Path.."Bouncing Ball_1.png", HotSpotX = 12, HotSpotY = 13}
	Objects.PlayerVisiblePos:LoadFrame{Path.."Bouncing Ball_1.png", Direction = 16, HotSpotX = 12, HotSpotY = 13}

	ReplaceGraphics({Path.."Bouncing Ball", 0, 95, HotSpotX = 12, HotSpotY = 13}, BallBody)
 
	BallBody.Animations = {
		Norm = {0, 15, Delay = 4, Loop = true},
		Jump = {16, 31, Delay = 4, Loop = true},
		Stop = {32, 47, Delay = 4, Loop = true},
		NormFloat = {48, 63, Delay = 4, Loop = true},
		JumpFloat = {64, 79, Delay = 4, Loop = true},
		StopFloat = {80, 95, Delay = 4, Loop = true},
	}
	BallBody:Animate("Norm")

	-- Replace Hologram graphics
	ReplaceHologramGraphics({
		{HotSpotX = 12, HotSpotY = 13},
		AppPath.."Data/Custom Objects/Holographic Ball/Holographic Ball_0.png",
		AppPath.."Data/Custom Objects/Holographic Ball/Holographic Ball_1.png",
	})
 
	-- Replace Hologram object
	local Path = AppPath.."Data/Custom Objects/Ball Hologram/"
	ReplaceGraphics({
		HotSpotX = 0, HotSpotY = 0, ActionX = 11, ActionY = 15, TransparentColor = 0,
		Path.."Ball Hologram", 0, 7,
	}, 0, 10)

	-- Replace Hologram power
	for i = 0, 7 do
		Objects.Power[7]:LoadFrame(Path.."Ball Hologram_"..i..".png", 0, 7, i, 0, 2, 0, 2, 0)
	end
	
	-- Replace damger markers
	dofile(AppPath.."Data/Custom Objects/Ball Danger Marker/load.lua")
	dofile(AppPath.."Data/Custom Objects/Ball Secrets Marker/load.lua")
end

function BouncingBallMode()
	return ball
end

return ball

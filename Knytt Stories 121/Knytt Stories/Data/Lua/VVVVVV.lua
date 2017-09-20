
-- flip save points, shifts, powerups, enemies?
-- custom save points logic: check gravity, remember last triggered save point

VVVVVV = {
	JumpSpeed = 150,  -- velocity given to player when gravity direction is switched
	AlwaysAct = false,  
}

local VVVVVV = VVVVVV

local function sgn1(a)  -- not quite 'sgn'
	if a >= 0 then
		return 1
	else
		return -1
	end
end

local NextSwitch = 0
local DownPressed

function events.global.KeysFilter()
	local ActKey = Controls("VVVVVVAct") or VVVVVV_ActKey or mmf.VK_DOWN
	if Objects.KBD.Jump == 0 and (ActKey == mmf.VK_DOWN or Objects.KBD.UpDown == 0) then
		NextSwitch = 0
	elseif GetGlobalTick() >= NextSwitch
			and not IsScreenLoading()
			and (Objects.PlayerPos.NormalJumpCountdown > 1 or
			Objects.PlayerPos:OverlapsObstacle(0, sgn1(Objects.Platform.Gravity))) then
		Objects.PlayerPos.NormalJumpCountdown = 0
		vars.VVVVVV_Gravity = -vars.VVVVVV_Gravity
		Objects.Platform.Gravity = vars.VVVVVV_Gravity
		Objects.Platform.YVelocity = sgn1(vars.VVVVVV_Gravity)*VVVVVV.JumpSpeed
		Objects.Player:SetAngle(vars.VVVVVV_Gravity > 0 and 0 or 180)
		Objects.Player:SetDirection(16 - Objects.Player:GetDirection())
		NextSwitch = GetGlobalTick() + 13
	end
	Objects.KBD.JumpOneshot = 0
	Objects.KBD.Jump = 0
	if VVVVVV.AlwaysAct then
		Objects.KBD.UpDown = 1
	elseif ActKey ~= mmf.VK_DOWN then
		Objects.KBD.UpDown = mmf.Keyboard.KeyDown(ActKey) and 1 or 0
	end
	Objects.KBD.DownOneshot = Objects.KBD.UpDown > 0 and not DownPressed and 1 or 0
	DownPressed = Objects.KBD.UpDown > 0
end

function events.global.LoadGame()
	vars.VVVVVV_Gravity = vars.VVVVVV_Gravity or 45
	Objects.Platform.Gravity = vars.VVVVVV_Gravity
	Objects.Player:SetAngle(vars.VVVVVV_Gravity > 0 and 0 or 180)
	if vars.VVVVVV_Gravity < 0 then
		Objects.Player:SetDirection(16 - Objects.Player:GetDirection())
		Objects.PlayerPos:SetY(Objects.PlayerPos:GetY() - 7)
	end
end

function events.global.IsStanding()
	if vars.VVVVVV_Gravity < 0 then
		IsStanding = Objects.PlayerPos:OverlapsObstacle(0, -1)
	end
end

function events.global.SetPlayerDirection()
	if vars.VVVVVV_Gravity < 0 then
		Objects.Player:SetY(Objects.PlayerPos:GetY() + 2)
		Objects.Player:SetDirection(16 - Objects.PlayerPos:GetDirection())
	end
end

RemovePower(1)
RemovePower(2)
RemovePower(3)
RemovePower(6)

function VVVVVVMode()
	return VVVVVV
end

return VVVVVV

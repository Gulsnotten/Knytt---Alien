
local Include = {
	[3*256 + 1] = 12,
	[3*256 + 2] = 12,
	[3*256 + 3] = 14,
	[3*256 + 4] = 12,
	[3*256 + 5] = 13,
	[3*256 + 6] = 17,
	[3*256 + 7] = 17,
	[3*256 + 8] = 19,
	[3*256 + 9] = {12, 3},
	[3*256 + 10] = {12, 3},
	[3*256 + 11] = {12, 3},
	[3*256 + 15] = 8,
	[3*256 + 16] = 17,
	[3*256 + 17] = 13,
	[3*256 + 18] = 17,
	[3*256 + 19] = 16,
	[3*256 + 20] = 10,
	[3*256 + 22] = 9,
	[3*256 + 23] = 9,
	[3*256 + 24] = 9,
	[3*256 + 25] = 24,
	[3*256 + 28] = 7,
	[3*256 + 31] = 9,
	[3*256 + 32] = 11,
	[3*256 + 33] = 12,
	[3*256 + 34] = 11,
	[3*256 + 35] = 11,
	[3*256 + 36] = 16,
	[3*256 + 40] = 8,
	[3*256 + 44] = 16,
	[4*256 + 1] = 12,
	[4*256 + 3] = 16,
	[4*256 + 4] = 11,
	[4*256 + 5] = 7,
	[4*256 + 6] = 13,
	[4*256 + 7] = {11, -2},
	[4*256 + 9] = 34,
	[4*256 + 12] = 10,
	[4*256 + 14] = 20,
	[4*256 + 15] = 10,
	[4*256 + 16] = 23,
	[4*256 + 17] = 14,
	[4*256 + 19] = 10,
	[4*256 + 20] = 10,
	[5*256 + 2] = 11,
	[5*256 + 3] = 11,
	[10*256 + 6] = 14,
	[10*256 + 7] = {10, 2, true},
	[11*256 + 1] = 11,
	[11*256 + 2] = 11,
	[11*256 + 3] = 9,
	[11*256 + 4] = 11,
	[11*256 + 5] = 11,
	[11*256 + 6] = 11,
	[11*256 + 7] = 11,
	[11*256 + 8] = 11,
	[11*256 + 9] = 11,
	[11*256 + 10] = 11,
	[12*256 + 3] = 12,
	[14*256 + 1] = 20,
	[14*256 + 2] = 9,
	[14*256 + 3] = 17,
	[14*256 + 4] = 12,
	[14*256 + 5] = 8,
	[14*256 + 6] = 12,
	[14*256 + 7] = 8,
	[14*256 + 8] = 13,
	[14*256 + 9] = 13,
	[14*256 + 11] = 18,
	[14*256 + 12] = 13,
	[14*256 + 13] = {11, 3, true},
	[14*256 + 14] = {11, 3, true},
	[14*256 + 15] = 16,
	[14*256 + 17] = 11,
	[17*256 + 1] = 12,
	[17*256 + 2] = 8,
	[17*256 + 7] = {5, 4},
	On = true
}


local enumt = {Kind = "object"}

function events.global.Timer()
	if Include.On then
		for o in Objects.Enum(enumt) do
			local w = Include[(o.Bank or 0)*256 + (o.Obj or 0)]
			local dy = 2
			local ignoreDir
			if type(w) == "table" then
				dy = w[2]
				ignoreDir = w[3]
				w = w[1]
			end
			if w and o:OverlapsObstacle(0, dy) then
				if w == true then
					w = 12
				end
				local dir = o:GetDirection()
				if (dir < 16 or ignoreDir) and not o:OverlapsObstacle(w - 1, dy) then
					o:SetDirection(16)
					o:SetFlag(31, true)
					repeat
						o:SetX(o:GetX() - 2)
					until o:OverlapsObstacle(w - 1, dy)
					o:Update()
				elseif (dir >= 16 or ignoreDir) and not o:OverlapsObstacle(-w + 1, dy) then
					o:SetDirection(0)
					o:SetFlag(31, true)
					repeat
						o:SetX(o:GetX() + 2)
					until o:OverlapsObstacle(-w + 1, dy)
					o:Update()
				end
			end
		end
	end
end

function NoWalkOnAir()
	return Include
end

return Include

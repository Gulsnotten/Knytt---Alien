
local FishPath = {
	[1] = {24, 0; 48, 4; 69, 9; 95, 12; 120, 12; 139, 9; 169, 3; 195, 2; 224, 6; 245, 14; 278, 24; 310, 30; 344, 32; Speed = 4},
	[2] = {26, 5; 43, 10; 54, 15; 71, 20; 89, 23; 70, 27; 56, 33; 40, 38; 21, 40; 3, 40; 31, 46; 55, 46; 75, 52; 91, 52; Speed = 2},
	[3] = {-19, -1; -36, -4; -53, -13; -74, -17; -96, -16; -116, -8; -137, 6; -157, 18; -177, 27; -198, 31; -216, 30; -232, 26; -246, 19; -258, 16; -272, 16; Speed = 4},
	[4] = {30, 3; 52, 10; 74, 21; 95, 31; 119, 37; 149, 38; 177, 37; 144, 41; 123, 49; 107, 59; 89, 70; 65, 77; 41, 83; 19, 85; -7, 85; Speed = 4},
	[5] = {-18, 2; -36, 7; -54, 6; -71, 4; -87, -3; -102, -12; -116, -15; -125, -15; -101, -20; -88, -28; -73, -34; -51, -39; -32, -39; -17, -36; 0, -34; Speed = 2},
}

local Fish = {On = true}

-- init Fish
for k, v in pairs(FishPath) do
	local t = {}
	Fish[k] = t
	local lastX, lastY = 0, 0
	for i = 1, #v/2 do
		local x, y = v[i*2 - 1], v[i*2]
		x, y, lastX, lastY = x - lastX, y - lastY, x, y
		local ticks = math.floor(math.sqrt(x*x + y*y)*8/v.Speed)
		t[i*3 - 2], t[i*3 - 1], t[i*3] = ticks, x/ticks, y/ticks
	end
end


local function CheckIgnoreWalls(o)
	if o.IgnoreWalls then
		return true
	end
	if not o.TicksLeft and o:OverlapsObstacle() then
		o.IgnoreWalls = true
		return true
	end
end


local enumt = {Kind = "object"}

function events.global.Timer()
	if Fish.On then
		for o in Objects.Enum(enumt) do
			if o.Bank == 18 and Fish[o.Obj] and not CheckIgnoreWalls(o) then
				if not o.TicksLeft then
					o:Stop()
					o.TicksLeft = 0
					o.Node = -3
					o.NodeDirection = 3
					o.FlipX, o.FlipY = 1, 1
					o.PartX, o.PartY = 0, 0
				end
				local t = Fish[o.Obj]
				-- change node
				if o.TicksLeft <= 0 then
					local new = o.Node + o.NodeDirection
					if new < 0 or new >= #t then
						o.NodeDirection = -o.NodeDirection
						o.FlipX = -o.FlipX
						o.FlipY = -o.FlipY
					else
						o.Node = new
					end
					o.TicksLeft = t[o.Node + 1]
				end
				-- move
				local dx, dy = t[o.Node + 2]*o.FlipX, t[o.Node + 3]*o.FlipY
				local x, y = o:GetPosition()
				x, y = x + o.PartX + dx, y + o.PartY + dy
				local ix, iy = math.floor(x + 0.5), math.floor(y + 0.5)
				o:SetPosition(ix, iy)
				o.PartX, o.PartY = x - ix, y - iy
				o.TicksLeft = o.TicksLeft - 1
				-- check collissions
				if o:OverlapsObstacle() then
					local function test(dx1, dy1)
						if (dx ~= 0 or dy ~= 0) and not o:OverlapsObstacle(dx1, dy1) then
							if dx1 ~= 0 then
								if dx*dx1 < 0 then
									o.FlipX = -o.FlipX
									o.PartX = -o.PartX
									dx = -dx
								end
								o:SetX(ix + dx1)
							end
							if dy1 ~= 0 then
								if dy*dy1 < 0 then
									o.FlipY = -o.FlipY
									o.PartY = -o.PartY
									dy = -dy
								end
								o:SetY(iy + dy1)
							end
							return true
						end
					end

					for i = 1, 10 do
						local j = math.floor(i*0.7)
						if test(0, -i) or test(0, i) or test(-i, 0) or test(i, 0) or
							 test(-j, -j) or test(j, -j) or test(-j, j) or test(j, j) then
							break
						end
					end
				end
				-- set direction
				if dx > 0 then
					o:SetDirection(0)
				elseif dx < 0 then
					o:SetDirection(16)
				end
				o:Update()
			end
		end
	end
end

function NoFishInWalls()
	return Fish
end

return Fish

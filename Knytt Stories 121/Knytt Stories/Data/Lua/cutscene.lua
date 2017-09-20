local abs = math.abs

function CutsceneScreen(HasBack, HasNext)
	-- add back and next buttons
	local bBack = Objects.NewTemplate(0, 9, 100)
	bBack:LoadFrame{AppPath.."Data/Custom Objects/Back.png", TransparentColor = 0}
	bBack:SetPosition(30, 240-12)
	bBack:SetLayer(2)
	if not HasBack then
		bBack:SetTransparency(80)
	end
	local bNext = Objects.NewTemplate(24, 9, 100)
	bNext:LoadFrame{AppPath.."Data/Custom Objects/"..(HasNext and "Next.png" or "NextOK.png"), TransparentColor = 0}
	bNext:SetPosition(600-30, 240-12)
	bNext:SetLayer(2)
	local bBorder = Objects.NewTemplate(-1, -1, 100)
	bBorder:LoadFrame{AppPath.."Data/Custom Objects/ButtonSelection.png", TransparentColor = 0}
	bBorder:SetVisibility(false)
	bBorder:SetLayer(2)

	-- stop sounds
	local oldSnd = MuteSounds()

	-- no death
	function events.Death()
		AllowDeath = false
	end
	
	-- disable keys & cheat
	EnableCheat(false)
	EnableKeysInput(false)
	
	-- enable keys & cheat on screen leave
	function events.LeftScreen()
		MuteSounds(oldSnd)
		EnableCheat(true)
		EnableKeysInput(true)
	end
	
	-- back/next reaction
	local function ChangeScreen(lr)
		UpdSoundVolume()
		local o = Objects.new(0, lr > 0 and 15 or 14, -1, -1, -1)
		o:SetVisibility(false)
		o:SetPosition(Objects.PlayerPos:GetPosition())
		Objects.KBD.UpDown = 1
		Objects.KBD.DownOneshot = 1
		ChangeScreen = nil
	end
	
	-- react left/right
	Timer(1, function()
		local lr = HasBack and mmf.Keyboard.KeyDown(mmf.VK_LEFT) and -1 or mmf.Keyboard.KeyDown(mmf.VK_RIGHT) and 1
		if lr and ChangeScreen then
			ChangeScreen(lr)
		end
	end)
	
	local function IsInObjectRect(o, x, y)
		return x >= o:GetXLeft() and x < o:GetXRight() and y >= o:GetYTop() and y < o:GetYBottom() and o
	end
	
	-- react mouse over
	function events.MouseMove(x, y)
		local o = HasBack and IsInObjectRect(bBack, x, y) or IsInObjectRect(bNext, x, y)
		if o then
			bBorder:SetPosition(o:GetPosition())
			bBorder:SetVisibility(true)
		else
			bBorder:SetVisibility(false)
		end
	end

	-- react mouse click
	function events.MouseClick(x, y)
		local o = HasBack and IsInObjectRect(bBack, x, y) or IsInObjectRect(bNext, x, y)
		if o and ChangeScreen then
			ChangeScreen(o == bBack and -1 or 1)
			PlaySound(38)
		end
	end
end

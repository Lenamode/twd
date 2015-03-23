local PLUGIN = PLUGIN
PLUGIN.name = "New Fancy Third Person"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "FO3, Classic Third Person Plugin. Steal it hard with the credit!"

PLUGIN.config = PLUGIN.config or {}
PLUGIN.config.distance = PLUGIN.config.distance or 0
PLUGIN.config.sensitive = PLUGIN.config.sensitive or .05
PLUGIN.config.changedir = PLUGIN.config.changedir or false
PLUGIN.config.changedir = PLUGIN.config.classic or false
PLUGIN.config.maxdistance = 100

if CLIENT then

	function PLUGIN:SchemaInitialized()
		
		local contents 
		local decoded
		if (file.Exists("nutscript/client/thirdperson.txt", "DATA")) then
			contents = file.Read("nutscript/client/thirdperson.txt", "DATA")
		end
		if contents then
			decoded = von.deserialize(contents)
		end
		if decoded then
			PLUGIN.config = decoded
		end
		
	end

	function PLUGIN:ShutDown()
		local encoded = von.serialize(PLUGIN.config)
		file.CreateDir("nutscript/")
		file.CreateDir("nutscript/client/")
		file.Write("nutscript/client/thirdperson.txt", encoded)
	end

	local mc = math.Clamp	
	local playerMeta = FindMetaTable("Player")
	local GetVelocity = FindMetaTable("Entity").GetVelocity
	local Length2D = FindMetaTable("Vector").Length2D

	local function ffr()
		return mc(FrameTime(), 1/60,1)
	end
	
	local nobob = {
		"weapon_physgun",
		"gmod_tool",
	}

	function playerMeta:CanOverrideView()
		return ( 
			self:IsValid() && // If player is available.
			self:Alive() && // If player is alive.
			self.character && // If player's character is valid.
			!self:GetOverrideSeq()  && // If player is not in acting sequence.
			!self:IsRagdolled() && // If player is not ragdolled/fallover'd
			PLUGIN.config.distance > 0 // If player enabled the thirdperson.
		)
	end
	
	function PLUGIN:DistPerc()
		return mc(self.config.distance / self.config.maxdistance, 0, 1)
	end

	function PLUGIN:CreateQuickMenu(panel)
		local label = panel:Add("DLabel")
		label:Dock(TOP)
		label:SetText(" Third Person Settings")
		label:SetFont("nut_TargetFont")
		label:SetTextColor(Color(233, 233, 233))
		label:SizeToContents()
		label:SetExpensiveShadow(2, Color(0, 0, 0))

		local category = panel:Add("DPanel")
		category:Dock(TOP)
		category:DockPadding(10, 5, 0, 5)
		category:DockMargin(0, 5, 0, 5)
		category:SetTall(110)

		local distance = category:Add("DNumSlider")
		distance:Dock(TOP)
		distance:SetText( "View Distance" )   // Set the text above the slider
		distance.Label:SetTextColor(Color(22, 22, 22))
		distance:SetMin( 0 )                  // Set the minimum number you can slide to
		distance:SetMax( self.config.maxdistance )                // Set the maximum number you can slide to
		distance:SetDecimals( 0 )             // Decimal places - zero for whole number
		distance:SetTall( 25 )             // Decimal places - zero for whole number
		distance:SetValue( self.config.distance )

		function distance:OnValueChanged( val )
			local val = self:GetValue()
			PLUGIN.config.distance = val
		end

		local sensitive = category:Add("DNumSlider")
		sensitive:Dock(TOP)
		sensitive:SetText( "Mouse Sensitive" )   // Set the text above the slider
		sensitive.Label:SetTextColor(Color(22, 22, 22))
		sensitive:SetMin( 0 )                  // Set the minimum number you can slide to
		sensitive:SetMax( 1 )                // Set the maximum number you can slide to
		sensitive:SetDecimals( 2 )             // Decimal places - zero for whole number
		sensitive:SetTall( 25 )             // Decimal places - zero for whole number
		sensitive:SetValue( self.config.sensitive )

		function sensitive:OnValueChanged( val )
			local val = self:GetValue()
			PLUGIN.config.sensitive = val
		end

		local changedir = category:Add("DCheckBoxLabel")
		changedir:Dock(TOP)
		changedir:SetText( "Left Chasecam" )   // Set the text above the slider
		changedir.Label:SetTextColor(Color(22, 22, 22))
		changedir:SetTall( 25 )             // Decimal places - zero for whole number
		changedir:SetValue( self.config.changedir )
		changedir:DockMargin(0, 7, 0, 0)

		function changedir:OnChange( val )
			PLUGIN.config.changedir = val
		end

		local classic = category:Add("DCheckBoxLabel")
		classic:Dock(TOP)
		classic:SetText( "Classic" )   // Set the text above the slider
		classic.Label:SetTextColor(Color(22, 22, 22))
		classic:SetTall( 25 )             // Decimal places - zero for whole number
		classic:SetValue( self.config.classic )

		function classic:OnChange( val )
			PLUGIN.config.classic = val
		end

	end

	function PLUGIN:ShouldDrawLocalPlayer()
		if ( LocalPlayer():Alive() && LocalPlayer().character ) then
			if ( LocalPlayer():GetOverrideSeq() or LocalPlayer():IsRagdolled() ) then
				return true
			end

			if self.config.distance > 0 then
				return true
			end
		end
		return false
	end
	
	local class
	local camang = Angle(0, 0, 0)
	local addpos = Vector(0, 0, 0)
	local finaladdpos = addpos
	local finalang = camang
	local camx, camy = 0, 0

	local lastaim = Angle(0, 0, 0)
	if LocalPlayer() and LocalPlayer():IsValid() and LocalPlayer().character then
		lastaim = LocalPlayer():EyeAngles()
		camang = LocalPlayer():EyeAngles()
	end

	local movetrig = false


	function PLUGIN:CreateMove( cmd )
		local ply = LocalPlayer()
		local vel = math.floor( Length2D(GetVelocity(ply)) )

		if ply:CanOverrideView() and !self.config.classic then
			if (vel < 5 and !ply:WepRaised()) then
				cmd:SetViewAngles(lastaim)
				movetrig = true
			else
				if movetrig then
					cmd:SetViewAngles(camang)
					movetrig = false
				end
				lastaim = ply:EyeAngles()
			end
		end
	end

	function PLUGIN:InputMouseApply( cmd, x, y, ang ) // :C
		local ply = LocalPlayer()
		local vel = math.floor(Length2D(GetVelocity(ply)))

		camx = x * -self.config.sensitive
		camy = y * self.config.sensitive

		if (vel < 5 and !ply:WepRaised() and !self.config.classic) then
			camang = camang + Angle(camy, camx, 0)
			camang.p = mc(camang.p, -90, 90)
			addpos = camang:Up()*math.abs(camang.p*.1)
		end
	end

	local nodesync = false
	function PLUGIN:CalcView( ply, pos, ang, fov )
		local rt = RealTime()
		local ft = FrameTime()
		local vel = math.floor( Length2D(GetVelocity(ply)) )
		local runspeed = ply:GetRunSpeed()
		local walkspeed = ply:GetWalkSpeed()
		local wep = ply:GetActiveWeapon()
		if wep and wep:IsValid() then
			class = ply:GetActiveWeapon():GetClass()
		else
			class = ""
		end
		local v = {}
		if 
			ply:CanOverrideView()
		then

			if !(vel < 5 and !ply:WepRaised()) or self.config.classic then
				camang = ang
				addpos = ang:Up()*mc(self:DistPerc()*self.config.distance*.3, 10, self.config.maxdistance)
				if ply:WepRaised() then
					local difac = 1
					if self.config.changedir then
						difac = -1
					end

					addpos = addpos + difac * ang:Right()*mc(self:DistPerc()*self.config.distance*.8, 20, self.config.maxdistance)
				end
			end

			local data = {}
				data.start = pos
				data.endpos = data.start - finalang:Forward() * self.config.distance + finaladdpos
				data.filter = ply
			local trace = util.TraceLine(data)

			// The reson of Clamping Frametime to 1/60(60 fps): Because Lerp getting slow as fuck when you're having too good fps.
			// Also Lerp gets freak out when player is getting really low fps. 
			// Upgrade your fucking computer then.
			if FrameTime() < 1/10 then
				finalang = LerpAngle(ffr()*15, finalang, camang)
				finaladdpos = LerpVector(ffr()*15, finaladdpos, addpos)
			else
				finalang = camang
				finaladdpos = addpos
			end

			v.angles = finalang
			v.angles.r = 0
			v.origin = trace.HitPos + trace.HitNormal * 10
			v.fov = fov
			
			return GAMEMODE:CalcView(ply, v.origin, v.angles, v.fov)
			
		end
		
	end
	
end
ENT.Type = "anim"
ENT.PrintName = "Bucket"
ENT.Author = "Black Tea"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "NutScript"
ENT.RenderGroup 		= RENDERGROUP_BOTH

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_junk/MetalBucket01a.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetNetVar("active", false)
		self:SetUseType(SIMPLE_USE)
		self.loopsound = CreateSound( self, "ambient/fire/fire_small_loop1.wav" )
		local physicsObject = self:GetPhysicsObject()

		if (IsValid(physicsObject)) then
			physicsObject:Wake()
		end
	end

	function ENT:Use(activator)
		self:SetNetVar("active", !self:GetNetVar("active", false))
		if self:GetNetVar("active") then
			self:EmitSound( "ambient/fire/mtov_flame2.wav", 75, 100 )
			self.loopsound:Play()
		else
			self:EmitSound( "ambient/fire/mtov_flame2.wav", 75, 250 )
			self.loopsound:Stop()
		end
	end
else
	function ENT:Initialize()
		self.emitter = ParticleEmitter( self:GetPos() )
		self.emittime = CurTime()
	end
	
	local GLOW_MATERIAL = Material("sprites/glow04_noz.vmt")
	function ENT:Draw()
		self:DrawModel()
		
		if self:GetNetVar("active") then
			local position = 	self:GetPos() + ( self:GetUp() *20 ) + 	( self:GetRight() * 11) + ( self:GetForward() *3)
			local size = 20 + math.sin( RealTime()*15 ) * 5
			render.SetMaterial(GLOW_MATERIAL)
			render.DrawSprite(position, size, size, Color( 255, 162, 76, 255 ) )
			
			if self.emittime < CurTime() then
				local smoke = self.emitter:Add( "particle/smokesprites_000"..math.random(1,9), firepos	)
				smoke:SetVelocity(Vector( 0, 0, 100))
				smoke:SetDieTime(math.Rand(0.6,2.3))
				smoke:SetStartAlpha(math.Rand(150,200))
				smoke:SetEndAlpha(0)
				smoke:SetStartSize(math.random(0,5))
				smoke:SetEndSize(math.random(33,55))
				smoke:SetRoll(math.Rand(180,480))
				smoke:SetRollDelta(math.Rand(-3,3))
				smoke:SetColor(50,50,50)
				smoke:SetGravity( Vector( 0, 0, 10 ) )
				smoke:SetAirResistance(200)
				self.emittime = CurTime() + .1
			end
		end
		
	end
end

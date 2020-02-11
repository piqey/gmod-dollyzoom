AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "gmod_cameraprop"

ENT.Editable = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Key")
	self:NetworkVar("Bool", 0, "On")
	self:NetworkVar("Vector", 0, "vecTrack")
	self:NetworkVar("Entity", 0, "entTrack")
	self:NetworkVar("Entity", 1, "Player")
	
	self:NetworkVar("Float", 1, "Focal", {
		KeyName = "width",
		Edit = {
			type = "Float",
			order = 1,
			min = 1,
			max = 1024
		}
	})
end

if SERVER then return end

hook.Add("CalcView", "DollyZoomEffect", function(ply, origin, angles, fov, znear, zfar)
	local viewent = ply:GetViewEntity()
	
	if IsValid(viewent) then
		if viewent.GetFocal then
			local focal = viewent:GetFocal()
			local lpos = util.TraceLine{
				start = origin,
				endpos = origin + angles:Forward() * 1e5,
				filter = viewent
			}.HitPos
			
			if IsValid(viewent:GetentTrack()) then
				lpos = viewent:GetentTrack():LocalToWorld(viewent:GetvecTrack())
			end
			
			local distance = (origin:Distance(lpos))
			
			local view = {}
			view.origin = origin
			view.angles = angles
			view.fov = math.deg(2 * math.atan(focal / distance))
			
			return view
		end
	end
end)

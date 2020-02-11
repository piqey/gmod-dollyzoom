--[[
	Dolly Zoom Camera for Garry's Mod
	by piqey (John C.K.)
--]]

--[[
	Tool Information
--]]

TOOL.Category = "Render"
TOOL.Name = "#tool.dolly.name"
TOOL.Command = nil

--[[
	Tool Language Strings
--]]

if CLIENT then
	language.Add("tool.dolly.name", "Camera: Dolly Zoom")
	language.Add("tool.dolly.desc", "Places cameras that scale their field of view (FOV) to maintain perceived distance")

	language.Add("tool.dolly.left", "Place a Camera that uses dolly zoom")
	language.Add("tool.dolly.right", "Place a tracking Camera that uses dolly zoom")
	
	language.Add("tool.dolly.cconfig", "Stock camera configuration.")
	
	language.Add("tool.dolly.config", "Optical configuration of perceived width.")
	language.Add("tool.dolly.width", "Perceived width")
end

--[[
	Tool Client Configuration
--]]

TOOL.ClientConVar["locked"] = 0
TOOL.ClientConVar["key"] = 37
TOOL.ClientConVar["toggle"] = 1

TOOL.ClientConVar["width"] = 64

TOOL.Information = {
	{name = "left", stage = 0},
	{name = "right", stage = 0}
}

--[[
	Tool Functions
--]]

local function CheckLimit(ply, key)
	if CLIENT then return true end

	local found = false
	for id, camera in pairs(ents.FindByClass("gmod_cameraprop")) do
		if (not camera.controlkey or camera.controlkey ~= key) then continue end
		if (IsValid(camera:GetPlayer()) and ply ~= camera:GetPlayer()) then continue end
		found = true
		break
	end

	if (not found) then
		if (not ply:CheckLimit("cameras")) then return false end
	end

	return true
end

local function MakeCamera(ply, key, locked, toggle, width, Data)
	if CLIENT then return end
	
	if (IsValid(ply) and not CheckLimit(ply, key)) then return false end

	local ent = ents.Create("gmod_cameraprop_dolly")
	if (not IsValid(ent)) then return end

	duplicator.DoGeneric(ent, Data) -- not sure if I plan to keep this

	local cameras = ents.FindByClass("gmod_cameraprop")
	local dollycameras = ents.FindByClass("gmod_cameraprop_dolly")
	table.Add(cameras, dollycameras)

	if (key) then
		for id, camera in pairs(cameras) do
			if (not camera.controlkey or camera.controlkey ~= key) then continue end
			if (IsValid(ply) and IsValid(camera:GetPlayer()) and ply ~= camera:GetPlayer()) then continue end
			camera:Remove()
		end

		ent:SetKey(key)
		ent.controlkey = key
	end

	ent:SetPlayer(ply)
	
	ent:SetPos(Data.Pos)
	ent:SetAngles(Data.Angle)

	ent.toggle = toggle
	ent.locked = locked
	
	--ent.width = width
	ent:SetFocal(width)

	ent:Spawn()

	ent:SetTracking(NULL, Vector(0))
	ent:SetLocked(locked)

	if (toggle == 1) then
		numpad.OnDown(ply, key, "Camera_Toggle", ent)
	else
		numpad.OnDown(ply, key, "Camera_On", ent)
		numpad.OnUp(ply, key, "Camera_Off", ent)
	end

	if (IsValid(ply)) then
		ply:AddCleanup("cameras", ent)
		ply:AddCount("cameras", ent)
	end

	return ent
end

duplicator.RegisterEntityClass("gmod_cameraprop",
	MakeCamera,
	"controlkey",
	"locked",
	"toggle",
	"width",
	"Data"
)

--[[
	Tool Hooks
--]]

function TOOL:LeftClick(tr)
	local ply = self:GetOwner()
	local key = self:GetClientNumber("key")
	if (key == -1) then return false end
	
	if (not CheckLimit(ply, key)) then return false end
	
	--if CLIENT then return true end
	
	local locked = self:GetClientNumber("locked")
	local toggle = self:GetClientNumber("toggle")
	local width = self:GetClientNumber("width")
	
	local ent = MakeCamera(ply, key, locked, toggle, width, {
		Pos = tr.StartPos,
		Angle = ply:EyeAngles()
	})
	
	if CLIENT then return true end
	
	undo.Create("Camera")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish()
	
	return true, ent
end

function TOOL:RightClick(tr)
	local _, camera = self:LeftClick(tr, true)

	if CLIENT then return true end

	if not IsValid(camera) then return false end

	if (tr.Entity:IsWorld()) then
		tr.Entity = self:GetOwner()
		tr.HitPos = self:GetOwner():GetPos()
	end

	camera:SetTracking(tr.Entity, tr.Entity:WorldToLocal(tr.HitPos))

	return true
end

--[[
	Tool Configuration HUD
--]]

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", {
		Text = "Camera",
		Description = "#tool.dolly.cconfig"
	})
	panel:AddControl("Numpad", {
		Label = "#tool.camera.key",
		Command = "dolly_key"
	})
	panel:AddControl("CheckBox", {
		Label = "#tool.camera.static",
		Command = "dolly_locked",
		Help = true
	})
	panel:AddControl("CheckBox", {
		Label = "#tool.toggle",
		Command = "dolly_toggle"
	})
	
	panel:AddControl("Header", {
		Text = "Options",
		Description = "#tool.dolly.config"
	})
	panel:AddControl("Slider", {
		Label = "#tool.dolly.width",
		Type = "Float",
		Min = "1",
		Max = "1024",
		Command = "dolly_width"
	})
end

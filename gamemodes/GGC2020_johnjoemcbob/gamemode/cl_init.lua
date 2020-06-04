--
-- GGC2020_johnjoemcbob
-- 29/05/20
--
-- Main Clientside
--

include( "includes/modules/3d2dvgui.lua" )

include( "shared.lua" )

include( "cl_billboard.lua" )
include( "cl_modelcache.lua" )
include( "cl_shipeditor.lua" )

MAT_PLAYER = Material( "playersheet.png", "nocull 1 smooth 0" )
	-- MAT_PLAYER:SetInt( "$flags", bit.bor( MAT_PLAYER:GetInt( "$flags" ), 2 ^ 8 ) )

	local MAT_PLAYER_WIDTH = 643
	local MAT_PLAYER_HEIGHT = 831
	-- MAT_PLAYER:SetInt( "$flags", 2 ^ 3 )
	-- MAT_PLAYER:SetInt( "$flags", bit.bor( MAT_PLAYER:GetInt( "$flags" ), 2 ^ 8 ) )

MAT_GUNS_FUTURE = Material( "guns_future.png", "nocull 1 smooth 0" )
	-- MAT_GUNS_FUTURE:SetInt( "$flags", bit.bor( MAT_GUNS_FUTURE:GetInt( "$flags" ), 2 ^ 8 ) )

	local MAT_GUNS_FUTURE_WIDTH = 1024
	local MAT_GUNS_FUTURE_HEIGHT = 1024
	local GUNSCALE = 0.3

MAT_MUZZLEFLASH = Material( "muzzleflash.png", "nocull 1 smooth 0" )

MAT_TEST = Material( "test.png", "nocull 1 smooth 0" )

local PLAYER_WIDTH = 40
local PLAYER_HEIGHT = 74
local PLAYER_UV_WIDTH = 41
local PLAYER_UV_HEIGHT = 74

local ANIMS = {}
ANIMS[MAT_PLAYER] = {}
local x = 28
local y = 94
local w = PLAYER_UV_HEIGHT - 2
ANIMS[MAT_PLAYER]["idle"] = {
	Speed = 5,
	Vector( x + w * 0, y ),
	Vector( x + w * 1, y ),
	Vector( x + w * 2, y ),
	Vector( x + w * 1, y ),
}
local x = 32
local y = y + PLAYER_UV_HEIGHT + 4
local w = PLAYER_UV_HEIGHT + 4
ANIMS[MAT_PLAYER]["run"] = {
	Speed = 5,
	Vector( x + w * 0, y ),
	Vector( x + w * 1, y ),
	Vector( x + w * 2, y ),
	Vector( x + w * 3, y ),
	-- Vector( 17 + PLAYER_UV_SIZE * 4, y ),
}
local w = 0--16
ANIMS[MAT_PLAYER]["jump"] = {
	Speed = 1,
	Vector( 22 - w, 497 ),
	Vector( 81 - w, 484 ),
	Vector( 142 - w, 475 ),
	Vector( 196 - w, 467 ),
	Vector( 245 - w, 468 ),
}

VIEWMODEL_LERP_VECTOR	= 45
VIEWMODEL_LERP_ANGLE	= 25
VIEWMODEl_BREATHE		= 1
VIEWMODEl_BREATHE_SPEED	= 1

------------------------
  -- Gamemode Hooks --
------------------------
function GM:Initialize()
	LocalPlayer().ViewModelPos = Vector( 0, 0, 0 )
	LocalPlayer().ViewModelAngles = Angle( 0, 0, 0 )
end

function GM:Think()
	
end

function GM:PreRender()
	render.SetLightingMode( 0 )

	-- local dlight = DynamicLight( LocalPlayer():EntIndex() )
	-- if ( dlight ) then
		-- dlight.pos = LocalPlayer():GetPos() + Vector( 0, 0, 32 )
		-- dlight.r = 255
		-- dlight.g = 10
		-- dlight.b = 110
		-- dlight.brightness = 2
		-- dlight.Decay = 1000
		-- dlight.Size = 256 * 3
		-- dlight.DieTime = CurTime() + 1
	-- end
end

function GM:PreDrawOpaqueRenderables()
	render.Clear( 0, 0, 0, 255 )
	render.ClearDepth()
end

function GM:PrePlayerDraw( ply )
	local pos = ply:GetPos()
	local ang = LocalPlayer():GetAngles()
		ang.p = 0
		ang.r = 0
		ang:RotateAroundAxis( ang:Right(), 90 )
		ang:RotateAroundAxis( ang:Up(), -90 )

	-- Draw player
	local frame = 1
	local anim = "idle"
		if ( !ply:IsOnGround() ) then
			anim = "jump"

			local frames = #ANIMS[MAT_PLAYER][anim]
			local tr = util.TraceLine( {
				start = ply:GetPos(),
				endpos = ply:GetPos() - Vector( 0, 0, 10000 ),
				filter = ply
			} )
			local dist = math.floor( math.Clamp( ply:GetPos():Distance( tr.HitPos ) / 10, 0, frames - 1 ) )
			frame = dist + 1

			-- Animate wobble a little at height of jump
			if ( frame == frames ) then
				frame = math.floor( CurTime() * ANIMS[MAT_PLAYER][anim].Speed % 2 ) + frames - 1
			end

			-- Detect for npcs
			if ( dist == 0 ) then
				anim = "idle"
			end
		end
		if ( anim != "jump" ) then
			if ( ply:GetVelocity():LengthSqr() > 10 ) then
				anim = "run"
			end

			frame = math.floor( CurTime() * ( ANIMS[MAT_PLAYER][anim].Speed ) % #ANIMS[MAT_PLAYER][anim] + 1 )
		end
	local left = ply.BillboardLeft
		local dir = ply:GetVelocity():GetNormalized()
		local angBetween = dir:Dot( LocalPlayer():GetAngles():Right() )
		if ( angBetween != 0 ) then
			left = angBetween < 0
		end
		ply.BillboardLeft = left
	DrawPlayerWithUVs( ply, -PLAYER_WIDTH / 2, -PLAYER_HEIGHT, PLAYER_WIDTH, PLAYER_HEIGHT, MAT_PLAYER, anim, frame, left )

	-- Draw weapon
	-- TODO DOESN'T WORK, WEAPONS NEED TO REFACTOR TO DRAW THEMSELVES
	-- TODO DOESN'T WORK, WEAPONS NEED TO REFACTOR TO DRAW THEMSELVES
	-- TODO DOESN'T WORK, WEAPONS NEED TO REFACTOR TO DRAW THEMSELVES
	local reloading = false
		if ( ply:GetActiveWeapon() and ply:GetActiveWeapon():IsValid() ) then
			reloading = ( ply:GetActiveWeapon():GetActivity() == ACT_RELOAD ) or ( ply:GetActiveWeapon():GetActivity() == ACT_VM_RELOAD )
			-- print( ply:GetActiveWeapon():GetActivity() )
		end
		if ( reloading ) then
			ply.ReloadingProgress = ply.ReloadingProgress + FrameTime()
			ang:RotateAroundAxis( ang:Right(), ply.ReloadingProgress )
			-- print( ply.ReloadingProgress )
		else
			ply.ReloadingProgress = 0
		end
	-- cam.Start3D2D( pos, ang, 1 )
		local x = -PLAYER_WIDTH / 2
		local y = -PLAYER_HEIGHT / 5 * 3 + 1 * frame
		DrawWeapon( ply, x, y, 1, left )
	-- cam.End3D2D()

	return true
end

function GM:PostDrawOpaqueRenderables()
	for k, npc in pairs( ents.FindByClass( "npc_combine_s" ) ) do
		npc.RenderOverride = function( self )
			local wep = self:GetActiveWeapon()
			if ( wep and wep:IsValid() ) then
				wep:SetNoDraw( true )
			end

			GAMEMODE:PrePlayerDraw( self )
		end
	end
end

function GM:HUDPaint()
	render.SetLightingMode( 0 )

	-- Testing collision + rotation code!
	-- local x = ScrW() / 4 * 3
	-- local y = ScrH() / 2
	-- local w = 64
	-- local h = 32
	-- local a = { x, y, w, h, 0 }
	-- local b = {
		-- x + math.sin( CurTime() ) * w * 2,
		-- y + math.cos( CurTime() + 1 ) * h * 2,
		-- w, h,
		-- math.sin( CurTime() + 2 ) * 360
	-- }
	-- local b = {
		-- gui.MouseX(),
		-- gui.MouseY(),
		-- w, h,
		-- math.sin( CurTime() + 2 ) * 360
	-- }
	-- surface.SetDrawColor( COLOUR_WHITE )
	-- if ( intersect_squares( a, b ) ) then
		-- surface.SetDrawColor( COLOUR_GLASS )
	-- end
	-- surface.DrawTexturedRectRotated( a[1], a[2], a[3], a[4], a[5] )
	-- surface.DrawTexturedRectRotated( b[1], b[2], b[3], b[4], b[5] )
end

function GM:PreDrawViewModel( viewmodel, ply, weapon )
	if ( !ply ) then return end

	local ft = FrameTime()
	-- print( ft )
	ft = 0.016

	local scale = 2
	local ang = LocalPlayer():EyeAngles()
	local pos = LocalPlayer():EyePos() +
		ang:Right() * ( 14 + math.sin( CurTime() * VIEWMODEl_BREATHE_SPEED ) * VIEWMODEl_BREATHE ) +
		ang:Up() * ( -3 + math.cos( CurTime() * VIEWMODEl_BREATHE_SPEED ) * VIEWMODEl_BREATHE )
		-- Angle after pos
		ang:RotateAroundAxis( ang:Right(), 3 )
		ang:RotateAroundAxis( ang:Up(), 180 + 5 )
		ang:RotateAroundAxis( ang:Forward(), 90 )
	local reloading = false
		if ( ply:GetActiveWeapon() and ply:GetActiveWeapon():IsValid() ) then
			reloading = ( ply:GetActiveWeapon():GetActivity() == ACT_RELOAD ) or ( ply:GetActiveWeapon():GetActivity() == ACT_VM_RELOAD )
		end
		if ( reloading ) then
			ply.ReloadingProgress = ply.ReloadingProgress + ft * 230
			-- print( ply.ReloadingProgress )
			if ( ply.ReloadingProgress < 360 ) then
				pos = pos + ang:Forward() * -30
				ang:RotateAroundAxis( ang:Up(), ply.ReloadingProgress )
			end
		else
			ply.ReloadingProgress = 0
		end
	ply.ViewModelPos = LerpVector( ft * VIEWMODEL_LERP_VECTOR, UnNaNVector( ply.ViewModelPos, pos ), pos )
	ply.ViewModelAngles = LerpAngle( ft * VIEWMODEL_LERP_ANGLE, UnNaNAngle( ply.ViewModelAngles ), ang )

	cam.Start3D2D( ply.ViewModelPos, ply.ViewModelAngles, 1 )
		DrawWeapon( ply, -60, 0, scale, true, true )
	cam.End3D2D()

	return true
end

function GM:CalcView( ply, pos, ang, fov )
	local view = {}
	view.origin = pos
	view.angles = ang
		if ( ply:InVehicle() ) then
			view.angles = Angle( 0, 90, 0 )
		end
	view.fov = fov
	view.zfar = 1000

	return view
end
-------------------------
  -- /Gamemode Hooks --
-------------------------

-- UV anims
function DrawWeapon( ply, x, y, scale, left, viewmodel )
	local gun = Get2DGun()
	local start = gun[1]
	local w = gun[2].x
	local h = gun[2].y
	local border = 2

	-- Center origin better
	local dir = 1
	if ( left ) then
		x = x - w * scale * GUNSCALE * 0.2
		dir = -1
	end

	local last = 0
		if ( ply:GetActiveWeapon() and ply:GetActiveWeapon():IsValid() ) then
			last = ply:GetActiveWeapon():LastShootTime()
		end
	local firing = last + 0.1 >= CurTime()

	-- 
	if ( firing ) then
		x = x - 5 * dir
	end

	-- Draw gun
	surface.SetDrawColor( COLOUR_WHITE )
	surface.SetMaterial( MAT_GUNS_FUTURE )
	if ( viewmodel ) then
		DrawWithUVs( x, y, w * scale * GUNSCALE, h * GUNSCALE, start.x / MAT_GUNS_FUTURE_WIDTH, start.y / MAT_GUNS_FUTURE_HEIGHT, ( start.x + w ) / MAT_GUNS_FUTURE_WIDTH, ( start.y + h ) / MAT_GUNS_FUTURE_HEIGHT, left )
	else
		GAMEMODE:DrawBillboardedUVs( ply:GetPos(), Vector( w * scale * GUNSCALE, h * GUNSCALE ), MAT_GUNS_FUTURE, start.x / MAT_GUNS_FUTURE_WIDTH, start.y / MAT_GUNS_FUTURE_HEIGHT, ( start.x + w ) / MAT_GUNS_FUTURE_WIDTH, ( start.y + h ) / MAT_GUNS_FUTURE_HEIGHT, left )
	end

	-- Draw muzzle flash
	if ( firing ) then
		surface.SetMaterial( MAT_MUZZLEFLASH )
		local size = math.random( 0.9, 1.1 )
		local size = 1
		local colour = math.sin( CurTime() * 50 ) / 2 + 0.5
		local muzzle = 1 * dir
			muzzle = muzzle * size
		surface.SetDrawColor( Color( 255, 255, 255, 255 * colour ) )
		DrawWithUVs(
			x + w * scale * GUNSCALE * muzzle - border * muzzle,
			y - border * 2 + 14 * -size + 14,
			w * scale * size * GUNSCALE,
			h * size * GUNSCALE,
			0, 0, 1, 1,
			left
		)

		-- ply.ViewModelPos = ply.ViewModelPos - ply:GetForward() * 5
	end
end
function DrawPlayerWithUVs( ply, x, y, w, h, mat, anim, frame, left )
	-- 17 / 643, 94 / 831, ( 17 + 68 ) / 643, ( 94 + 68 ) / 831
	local uvs = ANIMS[mat][anim][frame]
	local u1 = uvs.x / MAT_PLAYER_WIDTH
	local v1 = uvs.y / MAT_PLAYER_HEIGHT
	local u2 = ( uvs.x + PLAYER_UV_WIDTH ) / MAT_PLAYER_WIDTH
	local v2 = ( uvs.y + PLAYER_UV_HEIGHT ) / MAT_PLAYER_HEIGHT

	if ( !left ) then
		local temp = u1
		u1 = u2
		u2 = temp
	end
	GAMEMODE:DrawBillboardedEntUVs( ply, mat, u1, v1, u2, v2 )
end
function DrawWithUVs( x, y, w, h, u1, v1, u2, v2, left )
	if ( left ) then
		local temp = u1
		u1 = u2
		u2 = temp
	end
	surface.DrawTexturedRectUV( x, y, w, h, u1, v1, u2, v2 )
end

function Get2DGun()
	return { Vector( 103, 92 ), Vector( 176, 76 ) }
end

function draw.StencilBasic( mask, inner )
	render.ClearStencil()
	render.SetStencilEnable( true )
		render.SetStencilWriteMask( 255 )
		render.SetStencilTestMask( 255 )
		render.SetStencilFailOperation( STENCILOPERATION_KEEP )
		render.SetStencilZFailOperation( STENCILOPERATION_REPLACE )
		render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_ALWAYS )
		render.SetBlend( 0 ) --makes shit invisible
		render.SetStencilReferenceValue( 10 )
			mask()
		render.SetBlend( 1 )
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
			inner()
	render.SetStencilEnable( false )
end

concommand.Add( "ggcj_getpos", function( ply, cmd, args )
	print( GetPrettyVector( ply:GetPos() ) )
end )

concommand.Add( "ggcj_getent", function( ply, cmd, args )
	-- TODO get trace ent and displays
end )

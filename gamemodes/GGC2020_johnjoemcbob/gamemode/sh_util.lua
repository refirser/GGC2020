--
-- GGC2020_johnjoemcbob
-- 01/06/20
--
-- Shared Util
--

function ForAllDataFilesInDir( localdir, onfound )
	local srchpath = localdir .. "*"
	local searches = {
		{ srchpath, "DATA" },
		{ gmod.GetGamemode().GamemodePath .. "content/data/" .. srchpath, "GAME" },
	}
	for k, search in pairs( searches ) do
		local files, directories = file.Find( search[1], search[2] )
		for k, file in pairs( files ) do
			onfound( file )
		end
		for k, dir in pairs( directories ) do
			ForAllDataFilesInDir( localdir .. dir .. "/", onfound )
		end
	end
end

function LoadTableFromJSON( path, name )
	local zone = "DATA"
	local path = path .. name
		if ( !string.find( path, ".json" ) ) then
			path = path .. ".json"
		end
	if ( !file.Exists( path, zone ) ) then
		path = gmod.GetGamemode().GamemodePath .. "content/data/" .. path
		zone = "GAME"
		if ( !file.Exists( path, zone ) ) then
			return
		end
	end

	local json = file.Read( path, zone )
	local tab = util.JSONToTable( json )
	return tab
end

function LerpColour( dif, current, target )
	return Color(
		Lerp( dif, current.r, target.r ),
		Lerp( dif, current.g, target.g ),
		Lerp( dif, current.b, target.b ),
		Lerp( dif, current.a, target.a )
	)
end

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

-- Make a shallow copy of a table (from http://lua-users.org/wiki/CopyTable)
-- Extended for recursive tables
function table.shallowcopy( orig )
	local orig_type = type( orig )
	local copy
	if ( orig_type == "table" ) then
		copy = {}
		for orig_key, orig_value in pairs( orig ) do
			if ( type( orig_value ) == "table" ) then
				copy[orig_key] = table.shallowcopy( orig_value )
			else
				copy[orig_key] = orig_value
			end
		end
	-- Number, string, boolean, etc
	else
		copy = orig
	end
	return copy
end

function UnNaNVector( vector, default )
	-- NaN isn't equal to itself
	if ( vector and vector.x == vector.x and vector.y == vector.y and vector.z == vector.z ) then
		return vector
	end
	if ( default ) then
		return default
	end
	return Vector( 0, 0, 0 )
end
function UnNaNAngle( angle, default )
	-- NaN isn't equal to itself
	if ( angle and angle.x == angle.x and angle.y == angle.y and angle.z == angle.z ) then
		return angle
	end
	if ( default ) then
		return default
	end
	return Angle( 0, 0, 0 )
end

-- function ClampVectorLength( vec, min, max )
	-- min = min:
	-- if ( vec:LengthSqr() < min
	-- local dir = vec:GetNormalized()
	-- local
-- end
function Clamp2DVectorLength( vec, min, max )
	-- Square these instead of rooting the length
	local len = math.abs( vec.x ) + math.abs( vec.y )
	if ( len < min or len > max ) then
		-- At least don't have to sqrroot when inside range? idk
		-- local len = vec:Length()

		local dir = vec:GetNormalized()
		return ( dir * math.Clamp( len, min, max ) )
	else
		return vec
	end
end

function ApproachVector( change, current, target )
	local dir = ( target - current ):GetNormalized()
	-- print( dir )
	return Vector(
		math.Approach( current.x, target.x, dir.x * change ),
		math.Approach( current.y, target.y, dir.y * change ),
		math.Approach( current.z, target.z, dir.z * change )
	)
end

function VectorIndividualMultiply( one, two )
	return Vector( one.x * two.x, one.y * two.y, one.z * two.z )
end

function GetPrettyVector( vector )
	return "Vector( " .. math.Round( vector.x ) .. ", " .. math.Round( vector.y ) .. ", " .. math.Round( vector.z ) .. " )"
end

function GetPrettyAngle( angle )
	return "Angle( " .. math.Round( angle.p ) .. ", " .. math.Round( angle.y ) .. ", " .. math.Round( angle.r ) .. " )"
end

function rotate_point( pointX, pointY, originX, originY, angle )
	angle = angle * math.pi / 180
	return {
		math.cos(angle) * (pointX-originX) - math.sin(angle) * (pointY-originY) + originX,
		math.sin(angle) * (pointX-originX) + math.cos(angle) * (pointY-originY) + originY
	}
end

function getpolygonfromsquare( x, y, w, h, ang )
	local poly = {}
		-- Convert to 4 line polygon
		local o = { x + w / 2, y + h / 2 }
		local lines = {
			rotate_point( x, y, o[1], o[2], -ang ),
			rotate_point( x + w, y, o[1], o[2], -ang ),
			rotate_point( x + w, y + h, o[1], o[2], -ang ),
			rotate_point( x, y + h, o[1], o[2], -ang ),
		}
		for k, rotated in pairs( lines ) do
			table.insert( poly, rotated )

			if ( CLIENT ) then
				local pos = DEBUG_SHIP_COLLISION_POS
				surface.DrawCircle( pos.x + rotated[1] - w / 2, pos.y + rotated[2] - w / 2, 4, Color( 255, 120, 0 ) )
			end
			local next = k + 1
				if ( k == 4 ) then
					next = 1
				end
			if ( CLIENT ) then
				local pos = DEBUG_SHIP_COLLISION_POS
				surface.DrawLine( pos.x + rotated[1] - w / 2, pos.y + rotated[2] - h / 2, pos.x + lines[next][1] - w / 2, pos.y + lines[next][2] - h / 2 )
			end
		end
	return poly
end

-- Take two tables of { x, y, w, h, ang }
function intersect_squares( a, b )
	return intersect_polygons(
		getpolygonfromsquare( a[1], a[2], a[3], a[4], a[5] ),
		getpolygonfromsquare( b[1], b[2], b[3], b[4], b[5] )
	)
end

-- https://stackoverflow.com/questions/10962379/how-to-check-intersection-between-2-rotated-rectangles
math.inf = 10000000
function intersect_polygons( a, b )
	polygons = {a,b}
	for i=1, #polygons do
		polygon = polygons[i]
		for i1=1, #polygon do
			i2 = i1 % #polygon + 1
			p1 = polygon[i1]
			p2 = polygon[i2]

			nx,ny = p2[2] - p1[2], p1[1] - p2[1]

			minA = math.inf
			maxA = -math.inf
			for j=1, #a do
				projected = nx * a[j][1] + ny * a[j][2]
				if projected < minA then minA = projected end
				if projected > maxA then maxA = projected end
			end

			minB = math.inf
			maxB = -math.inf
			for j=1, #b do
				projected = nx * b[j][1] + ny * b[j][2]
				if projected < minB then minB = projected end
				if projected > maxB then maxB = projected end
			end

			if maxA < minB or maxB < minA then return false end
		end
	end
	return true
end

-- http://stackoverflow.com/a/23976134/1190664
-- ray.position is a vector
-- ray.direction is a vector
-- plane.position is a vector
-- plane.normal is a vector
function intersect_ray_plane( ray, plane )
	local denom = plane.normal:Dot( ray.direction )

	-- Ray does not intersect plane
	if math.abs( denom ) < GAMEMODE.Epsilon then
		return false
	end

	-- Distance of direction
	local d = plane.position - ray.position
	local t = d:Dot( plane.normal ) / denom

	if t < GAMEMODE.Epsilon then
		return false
	end

	-- Return collision point and distance from ray origin
	return ray.position + ray.direction * t, t
end

-- point is a vector
-- rect.min is a vector
-- rect.max is a vector
-- angle is a float
function intersect_point_rotated_rect( point, rect, angle )
	-- From: https://love2d.org/forums/viewtopic.php?t=11585
	local function area( tri )
		local x1, y1 = tri[1].x, tri[1].y
		local x2, y2 = tri[2].x, tri[2].y
		local x3, y3 = tri[3].x, tri[3].y
		return math.abs( ( x1*y2 + x2*y3 + x3*y1 - x1*y3 - x3*y2 - x2*y1) / 2 )
	end
	local function point_on_triangle(P,A,B,C)
		local area0=area( { A, B, C } )
		local area1=area( { P, B, C } )
		local area2=area( { A, P, C } )
		local area3=area( { A, B, P } )
		local sum = area1 + area2 + area3
		local eps = 0.0001
		return area0 > sum - eps and area0 <area0 + eps
	end
	local function point_on_square(point,tab)	-- Uses sum-of-areas approach
		local test1 = point_on_triangle(point,tab[1],tab[2],tab[3])
		local test2 = point_on_triangle(point,tab[3],tab[4],tab[1])
		return test1 or test2
	end

	-- First get all initial non-rotated rect points
	local points = {
		rect.min,
		Vector( rect.min.x, rect.max.y ),
		rect.max,
		Vector( rect.max.x, rect.min.y ),
	}

	-- Rotate rect points
	-- TODO

	-- Check both triangles making this rect
	return point_on_square( point, points )
end

-- From: http://wiki.garrysmod.com/page/surface/DrawPoly
function GM.GetCirclePoints( x, y, radius, seg, rotate )
	local cir = {}
		for i = 0, seg do
			local a = math.rad( ( ( i / seg ) * -360 ) + rotate )
			table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
		end
	return cir
end

-- Create a physics prop which is frozen by default
-- Model (String), Position (Vector), Angle (Angle), Should Move? (bool)
function GM.CreateProp( mod, pos, ang, mov )
	local ent = ents.Create( "prop_physics" )
		ent:SetModel( mod )
		ent:SetPos( pos )
		ent:SetAngles( ang )
		ent:Spawn()
		if ( !mov ) then
			local phys = ent:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:EnableMotion( false )
			end
		end
	return ent
end

-- Create an ent which is frozen by default
-- Class (String), Model (String), Position (Vector), Angle (Angle), Should Move? (bool), Should auto spawn? (bool)
function GM.CreateEnt( class, mod, pos, ang, mov, nospawn )
	local ent = ents.Create( class )
		if ( mod ) then
			ent:SetModel( mod )
		end
		ent:SetPos( pos )
		ent:SetAngles( ang )
		if ( !nospawn ) then
			ent:Spawn()
		end
		if ( !mov ) then
			local phys = ent:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:EnableMotion( false )
			end
		end
	return ent
end

local meta = FindMetaTable( "Player" )
function meta:GetIndex()
	local index = 1
		for k, v in pairs( player.GetAll() ) do
			if ( v == self ) then
				break
			end
			index = index + 1
		end
	return index
end

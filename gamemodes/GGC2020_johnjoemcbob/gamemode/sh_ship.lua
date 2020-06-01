--
-- GGC2020_johnjoemcbob
-- 01/06/20
--
-- Shared Ship
--

Ship = Ship or {}
Ship.Ship = Ship.Ship or {}

local NETSTRING_SHIP = HOOK_PREFIX .. "Ship"

-- Net
if ( SERVER ) then
	util.AddNetworkString( NETSTRING_SHIP )
	util.AddNetworkString( NET_SHIPEDITOR_SPAWN )

	function Ship.SendToClient( self, ship )
		-- TODO need to send ship layouts to all clients
		net.Start( NETSTRING_SHIP )
			net.WriteInt( ship:GetIndex(), 9 )
			net.WriteTable( ship.Constructor )
		net.Broadcast()
	end

	net.Receive( NET_SHIPEDITOR_SPAWN, function( len, ply )
		-- Load ship data
		local tab = net.ReadTable()

		-- Clear old
		-- Ship:Clear( ply )

		-- Generate new
		Ship:Generate( ply, tab )
	end )
end
if ( CLIENT ) then
	net.Receive( NETSTRING_SHIP, function( lngth )
		local index = net.ReadInt( 9 )
		local tab = net.ReadTable()

		-- Store for render
		Ship.Ship[index].Constructor = tab
		print( index )
		PrintTable( Ship.Ship[index].Constructor )
	end )
end

if ( SERVER ) then
	Ship.Generate = function( self, ply, tab )
		local index = #self.Ship + 1

		self.Ship[index] = ents.Create( "ggcj_ship" )
			self.Ship[index]:SetPos( SHIPEDITOR_ORIGIN( index ) )
			self.Ship[index]:SetIndex( index )
		self.Ship[index]:Spawn()

		local first = nil
		self.Ship[index].Constructor = table.shallowcopy( tab )
		for k, v in pairs( tab ) do
			local part = SHIPPARTS[v.Name]
				v.Collisions = part[2]
				if ( v.Rotation % 2 != 0 ) then
					v.Collisions = Vector( v.Collisions.y, v.Collisions.x )
				end
			local ent = GAMEMODE.CreateProp(
				part[1],
				SHIPEDITOR_ORIGIN( index ) +
					Vector(
						v.Grid.x + math.floor( v.Collisions.x / 2 ) + part[3].x,
						-v.Grid.y - math.floor( v.Collisions.y / 2 ) + part[3].y
					) * SHIPPART_SIZE,
				Angle( 0, 90 * v.Rotation, 0 ),
				false
			)
			ent:SetColor( COLOUR_UNLIT )
			table.insert( self.Ship[index].Parts, ent )

			-- Temp testing
			if ( math.random( 1, 2 ) == 1 ) then
				local npc = GAMEMODE.CreateEnt( "npc_combine_s", nil, ent:GetPos(), Angle( 0, 0, 0 ) )
					npc:Give( "weapon_ar2" )
					npc:SetHealth( 20 )
					-- npc:SetNoDraw( true )
				table.insert( self.Ship[index].Parts, npc )
			else
				self.Ship[index].SpawnPoint = ent:GetPos() - Vector( 0, 0, 32 )
				ply:SetPos( self.Ship[index].SpawnPoint )
				ply:SetHealth( ply:GetMaxHealth() )
				ply:SetNWEntity( "CurrentShip", index )
				ply.OwnShip = index
			end

			if ( first ) then
				-- ent:SetParent( first )
			else
				first = ent
			end
		end
	end

	Ship.Clear = function( self, ply )
		if ( ply.OwnShip and self.Ship[ply.OwnShip] and self.Ship[ply.OwnShip]:IsValid() ) then
			for k, part in pairs( self.Ship[ply.OwnShip].Parts ) do
				if ( part and part:IsValid() ) then
					part:Remove()
				end
			end
			self.Ship[ply.OwnShip]:Remove()
			self.Ship[ply.OwnShip] = nil
		end
	end

	-- Gamemode Hooks
	hook.Add( "Think", HOOK_PREFIX .. "Ship_Think", function()
		for k, ply in pairs( player.GetAll() ) do
			local ship = ply:GetNWInt( "CurrentShip", -1 )
			if ( ship >= 0 and Ship.Ship[ship] and Ship.Ship[ship]:IsValid() ) then
				Ship.Ship[ship]:MoveInput( ply )
				-- print( ship )
			end
		end
	end )

	-- Command to join other ships for now
	concommand.Add( "ggcj_setship", function( ply, cmd, args )
		ply:SetNWInt( "CurrentShip", tonumber( args[1] ) )
		-- print( args[1] )
	end )
end
if ( CLIENT ) then
	hook.Add( "HUDPaint", HOOK_PREFIX .. "Ship_HUDPaint", function()
		local w = ScrW() / 4
		local h = w
		local x = ScrW() - w
		local y = 0

		-- Background
		surface.SetDrawColor( COLOUR_BLACK )
		surface.DrawRect( x, y, w, h )

		-- Draw world centered on own ship
		local ship = LocalPlayer():GetNWInt( "CurrentShip" )
		-- print( ship )
		if ( ship and ship >= 0 ) then
			local ship = Ship.Ship[ship]
			if ( ship and ship:IsValid() ) then
				local sw = w / 16
				local sh = sw
				local sx = x + w / 2
				local sy = y + h / 2
				surface.SetDrawColor( COLOUR_WHITE )
				surface.DrawLine( sx, sy, sx + ship:Get2DVelocity().x, sy - ship:Get2DVelocity().y )
				surface.SetDrawColor( COLOUR_GLASS )
				ship:HUDPaint( sx - sw / 2, sy - sw / 2, sw )
				-- surface.DrawRect( sx - sw / 2, sy - sw / 2, sw, sh )
				-- draw.SimpleText( ship:Get2DPos(), "DermaDefault", sx, sy, COLOUR_GLASS )
				-- draw.SimpleText( ship:Get2DVelocity(), "DermaDefault", sx, sy + 16, COLOUR_GLASS )

				-- Draw all other ships based on this position
				for k, other in pairs( Ship.Ship ) do
					if ( other != ship ) then
						local sx = sx + ( other:Get2DPos().x - ship:Get2DPos().x )
						local sy = sy - ( other:Get2DPos().y - ship:Get2DPos().y )
						surface.SetDrawColor( COLOUR_WHITE )
						ship:HUDPaint( sx, sy, sw )
					end
				end
			end
		end
	end )
end
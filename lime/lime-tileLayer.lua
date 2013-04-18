----------------------------------------------------------------------------------------------------
---- Lime - 2D Tile Engine for Corona SDK. (Original author: Graham Ranson)
---- http://OutlawGameTools.com
---- Copyright 2013 Three Ring Ranch
---- The MIT License (MIT) (see LICENSE.txt for details)
----------------------------------------------------------------------------------------------------
--
-- Date: Oct-2011
--
-- Version: 3.5
--
-- File name: lime-tileLayer.lua
--
----------------------------------------------------------------------------------------------------
----									REQUIRED MODULES										----
----------------------------------------------------------------------------------------------------

local base64 = require("lime.lime-external-base64")
local decompress = require("lime.lime-external-deflatelua")

----------------------------------------------------------------------------------------------------
----									CLASS METATABLE											----
----------------------------------------------------------------------------------------------------

TileLayer = {}
TileLayer_mt = { __index = TileLayer }

----------------------------------------------------------------------------------------------------
----									CLASS VARIABLES											----
----------------------------------------------------------------------------------------------------

TileLayer.version = 3.4

----------------------------------------------------------------------------------------------------
----									LOCALISED VARIABLES										----
----------------------------------------------------------------------------------------------------

local ceil = math.ceil
local floor = math.floor
local abs = math.abs

----------------------------------------------------------------------------------------------------
----									PRIVATE METHODS											----
----------------------------------------------------------------------------------------------------

--- Parse layer data (GIDs) from a CSV string.
-- @params data The CSV string.
-- @returns A list of parsed GIDs.
local getTileIDsFromCSV = function(data)
	local IDs = {}
	
	if(data) then
		local tileIDs = utils:splitString(data, ",")
		
		for i=1, #tileIDs, 1 do
			tileIDs[i] = utils:convertStringToNumberSafely( tileIDs[i] )
		end
		
		return tileIDs
	end
end

--- Parse layer data (GIDs) from a Base64 string.
-- @params layer The TileLayer object.
-- @params data The compressed string.
local getTileIDsFromBase64 = function(layer, data)

	if(data) then
	
		local tileIDs = {}
	
		if(layer.compression == "uncompressed") then
			tileIDs = base64.decode("int", data)
		elseif(layer.compression == "gzip" or layer.compression == "zlib") then
			
			local decompressionFunction = nil
			
			if( layer.compression == "gzip" ) then
				decompressionFunction = decompress.gunzip
			else
				decompressionFunction = decompress.inflate_zlib
			end
			
			if decompressionFunction then
			
				local bytes = {}
				decompressionFunction( {input = base64.decode("string", data), output = function (b) bytes[ #bytes + 1 ] = b end} )
				
				for i=1, #bytes, 4 do
					tileIDs[ #tileIDs + 1 ] = base64.glueInt( bytes[ i ], bytes[ i + 1 ], bytes[ i + 2 ], bytes[ i + 3 ])
				end
			
			end
			
		end
		
		return tileIDs
		
	end
end

--- Gets a tile that is at a  grid position on this layer.
-- @params tileList The list of tiles. 2D array of grid positions.
-- @params position The grid position to look for.
-- @params full If full then the tileList must be a 1D list rather than 2D and the search will use the individual tiles row/col positions incase they have been updated.
-- @return The found tile or nil if none found.
local getTileAt = function(tileList, position, full)

	local _tileList = tileList
	local _position = position
	local _full = full
	
	if _tileList  then
	
		if _full then
			
			for i = 1, #_tileList, 1 do
				
				if _tileList[i].row == _position.row and _tileList[i].column == _position.column then
					return _tileList[i]
				end
			end
			
		else
	
			if _tileList[_position.column] then
			
				if _tileList[_position.column][_position.row] then
					return _tileList[_position.column][_position.row]
				end
				
			end
			
		end
		
	end
	
end

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

--- Create a new instance of a TileLayer object.
-- @param data The XML data.
-- @param map The current Map object.
-- @return The newly created tileLayer.
function TileLayer:new(data, map)
			
    local self = {}    -- the new instance
    
    setmetatable( self, TileLayer_mt ) -- all instances share the same metatable

    self.properties = {}
    self.tiles = {}
    self.map = map
    
    -- Extract the header info, name, height and width
	for key, value in pairs(data['Attributes']) do 
		self:setProperty(key, value)
	end	
	
	local node = nil
	local attributes = nil
	local childNode = nil	
	
	-- Loop through all the child nodes
	for i=1, #data["ChildNodes"], 1 do
		
		node = data["ChildNodes"][i]
		
		if node.Name == "data" then
			
			if node['Attributes'] then
				local encoding = node['Attributes'].encoding or "xml"
				self:setProperty("encoding", encoding)
				
				local compression = node['Attributes'].compression or "uncompressed"
				self:setProperty("compression", compression)
			end
			
			local tileIDs = {}
			
			if(self.encoding == "xml") then
			
				-- Loop through all the child nodes
				for j=1, #node["ChildNodes"], 1 do
					
					childNode = node["ChildNodes"][j]
					childNode["Attributes"].index = j
					
					self.tiles[#self.tiles + 1] = Tile:new(childNode, self.map, self)
							
					tileIDs = nil
				end
				
			else
			
				if(self.encoding == "csv") then
					tileIDs = getTileIDsFromCSV(node.Value)
				elseif(self.encoding == "base64") then
					tileIDs = getTileIDsFromBase64(self, node.Value)
				end
				
				if(tileIDs) then -- Now create the tiles
					for i=1, #tileIDs, 1 do

						local data = {}
						data["Attributes"] = {}
						data["Attributes"].gid = tileIDs[i]
						data["Attributes"].index = i
						
						if(data["Attributes"].gid) then
							data["Attributes"].gid = tonumber(data["Attributes"].gid)
							self.tiles[#self.tiles + 1] = Tile:new(data, self.map, self)
						end
					end
				end	
				
			end
			
		elseif node.Name == "properties" then
			
			-- Loop through all the child nodes
			for j=1, #node["ChildNodes"], 1 do
				
				-- Each child node is a property, the attributes are the name and value
				attributes = node["ChildNodes"][j]["Attributes"]
				
				if attributes then	
					if attributes.name == "configFile" then
						utils:readInConfigFile(attributes.value, self)	
					else
						property = self:setProperty(attributes.name, attributes.value)
					end
				end
				
			end
		end
				
	end

    return self
    
end

--- Sets the value of a Property of the TileLayer. 
-- Will create a new Property if none found.
-- @param name The name of the Property.
-- @param value The new value.
-- @return The new value.
function TileLayer:setProperty(name, value)
		
	local property = self:getProperty(name)
	
	if property then
		return property:setValue(value)
	else
		self:addProperty(Property:new(name, value))
	end
	
	self[name] = self:getPropertyValue(name)
end

--- Gets a Property of the TileLayer.
-- @param name The name of the Property.
-- @return The Property. nil if no Property found.
function TileLayer:getProperty(name)
	return self.properties[name]
end

--- Gets the value of a Property of the TileLayer.
-- @param name The name of the Property.
-- @return The Property value. Nil if no Property found.
function TileLayer:getPropertyValue(name)
	
	local property = self:getProperty(name)
	
	if property then
		return property:getValue()
	end
	
end

--- Gets a list of all Properties of the TileLayer.
-- @return The list of Properties.
function TileLayer:getProperties()
	return self.properties
end

--- Gets a count of how many properties the Tile Layer has.
-- @return The Property count.
function TileLayer:getPropertyCount()

	local count = 0
	
	for _k, _v in pairs(self.properties) do
		count = count + 1
	end

	return count
end

---Checks whether the TileLayer has a certain Property.
-- @param name The name of the property to check for.
-- @return True if the TileLayer has the Property, false if not.
function TileLayer:hasProperty(name)
	return self:getProperty(name) ~= nil
end

--- Adds a Property to the TileLayer. 
-- @param property The Property to add.
-- @return The added Property.
function TileLayer:addProperty(property)
	self.properties[property:getName()] = property
	
	self[property:getName()] = property:getValue()
	
	return property
end

--- Removes a Property from the TileLayer. 
-- @param: name The name of the Property to remove.
function TileLayer:removeProperty(name)
	self.properties[name] = nil
end

--- Shows the TileLayer.
function TileLayer:show()

	if self.visible then
		
		local tiles = self.tiles
		
		if not lime.isScreenCullingEnabled() then
			for i=1, #tiles, 1 do	
				tiles[i]:show()	
			end	
		end
		
		local visual = self:getVisual()
		
		if visual then
			visual.isVisible = true
		end
		
	end
	
	self:updateTileVisibility()
end

--- Hides the TileLayer.
function TileLayer:hide()

	local tiles = self.tiles
	
	if not lime.isScreenCullingEnabled() then
		for i=1, #tiles, 1 do
			tiles[i]:hide()
		end
	end
	
	local visual = self:getVisual()
	
	if visual then
		visual.isVisible = false
	end
	
end

--- Gets the TileLayers visual.
function TileLayer:getVisual()
	return self.group
end

--- Gets a Tile on this TileLayer at a specified position.
-- @param position The position of the Tile. A table containing either x & y or row & column.
-- @params full If true the search will check all tiles using their updated rather than original grid position. Might be slower then non-full search so use with caution.
-- @return The found Tile. nil if none found.
function TileLayer:getTileAt(position, full)
	
	if(position.row and position.column) then
		
		if full then
			return getTileAt(self.tiles, position, true)
		else
			return getTileAt(self.tileGrid, position)
		end
	
	elseif(position.x and position.y) then
		
		local gridPos = utils:worldToGridPosition(self.map, position)
		
		return self:getTileAt(gridPos)
	end
end

--- Gets a list of Tiles on this TileLayer that have a specified property. 
-- @param name The name of the Property to look for.
-- @return A list of found Tiles. Empty if none found.
function TileLayer:getTilesWithProperty(name)

	local allTiles = self.tiles
	
	local tiles = {}
	
	for i = 1, #allTiles, 1 do
		if allTiles[i]:hasProperty(name) then
			tiles[#tiles + 1] = allTiles[i]
		end
	end

	return tiles
end

--- Swaps two tiles around.
-- @param tile1 The first tile.
-- @param tile2 The second tile.
-- @usage Originally created by Michał Kołodziejski - http://developer.anscamobile.com/forum/2011/02/12/how-swap-two-tiles-layer
function TileLayer:swapTiles(tile1, tile2)

	-- Make sure we actually have tiles
	if tile1 and tile2 then
	
		-- Make sure the tiles have sprites attached
		if tile1.sprite and tile2.sprite then
		
			-- Swap the tile world positions
			tile1.sprite.x, tile2.sprite.x = tile2.sprite.x, tile1.sprite.x
			tile1.sprite.y, tile2.sprite.y = tile2.sprite.y, tile1.sprite.y
			
			-- Swap the tiles in the tileGrid
			self.tileGrid[tile1.column][tile1.row], self.tileGrid[tile2.column][tile2.row] = self.tileGrid[tile2.column][tile2.row], self.tileGrid[tile1.column][tile1.row]
			
			-- Swap the tile grid positions
			tile1.column, tile2.column = tile2.column, tile1.column
			tile1.row, tile2.row = tile2.row, tile1.row			 
			
		end
	end
	
end

--- Swaps two tiles around based on their positions.
-- @param position1 The position of the first tile.
-- @param position2 The position of the second tile.
-- @usage Originally created by Michał Kołodziejski - http://developer.anscamobile.com/forum/2011/02/12/how-swap-two-tiles-layer
function TileLayer:swapTilesAtPositions(position1, position2)

	-- Get both tiles
	local tile1 = self:getTileAt(position1)
	local tile2 = self:getTileAt(position2)

	-- Swap the tiles
	self:swapTiles(tile1, tile2)
	
end

--- Destroys a tile at a certain position.
-- @param position The position of the tile, world or grid.
function TileLayer:removeTileAt(position)

	local tile = self:getTileAt(position)

	if tile then
		tile:destroy()
	end

end

--- Set a tile at a position.
-- @param gid The gid of the tile.
-- @param position The position of the tile, World or Grid.
-- @usage Originally created by Mattguest - http://developer.anscamobile.com/forum/2011/02/02/settile-function
function TileLayer:setTileAt(gid, position)
	
	local tile = self:getTileAt(position)
	
	-- First make sure there is a tile
	if tile then
		tile:setImage(gid)	
	end

end

--- Creates a new tile from a passed in GID. This will include all properties however it will not Build it ( by design ). If you wish to build it then simply call ":build()" on the returned tile.
-- @param gid The gid of the tile to create.
-- @return The created Tile.
function TileLayer:createTile(gid)

	local tileSet = self.map:getTileSetFromGID( gid )
	
	if tileSet then
	
		local data = {}
		
		data.isGenerated = true
		data.properties = tileSet:getPropertiesForTile( gid )
		
		local tile = Tile:new(data, self.map, self)
		
		if tile then
			
			local index = #self.tiles + 1
			
			tile.gid = gid
			
			tile:create( index )
			
			self.tiles[ index ] = tile
			
			tile:updateGridPosition()
			
		end
		
		-- Bring the new tile into focus
		tile:getVisual():toFront()
		tile:getVisual().isVisible = true
		
		return tile
	end
	
end

--- Creates and builds a new tile from a passed in GID. This will include all properties.
-- @param gid The gid of the tile to create.
-- @return The created Tile.
function TileLayer:createAndBuildTile(gid)
	local tile = self:createTile(gid)
	
	if tile then
		tile:build()
	end
	
	return tile
end

--- Creates a new tile from a passed in GID and sets its position. This will include all properties however it will not Build it ( by design ). If you wish to build it then simply call ":build()" on the returned tile.
-- @param gid The gid of the tile to create.
-- @param position The world position for the Tile.
-- @return The created Tile.
function TileLayer:createTileAt(gid, position)

	local tile = self:createTile(gid)
	
	if tile then
	
		if position.row and position.column then
			position = lime.utils:gridToWorldPosition( self.map, position )
		end
		
		tile:setPosition(position.x, position.y)
	end
	
	return tile
end

--- Creates and builds a new tile from a passed in GID and sets its position. This will include all properties.
-- @param gid The gid of the tile to create.
-- @param position The world position for the Tile.
-- @return The created Tile.
function TileLayer:createAndBuildTileAt(gid, position)

	local tile = self:createTileAt(gid, position)
	
	if tile then
		tile:build()
	end
	
	return tile
end

--- Adds a displayObject to the layer. 
-- @param displayObject The displayObject to add.
-- @return The added displayObject.
function TileLayer:addObject(displayObject)
	return utils:addObjectToGroup(displayObject, self.group)
end


--- Sets the position of the TileLayer.
-- @param x The new X position of the TileLayer.
-- @param y The new Y position of the TileLayer.
-- @param force If true then the layer will not be clamped or use the viewpoint calculator. Default is false. Optional.
function TileLayer:setPosition(x, y, force)

	if self.group then
	
		if force then 
			
			self.group.x = utils:round(x)
			self.group.y = utils:round(y)
			
		else
			local viewPoint = utils:calculateViewpoint(self.group, x, y)
	
			self.group.x = utils:round(viewPoint.x)
			self.group.y = utils:round(viewPoint.y)
	
			if self.map.orientation ~= "isometric" then
				self.group.x, self.group.y = utils:clampPosition(self.group.x, self.group.y, self.map.bounds)
			end
		end
	end
	
end

--- Moves the TileLayer.
-- @param x The amount to move the TileLayer along the X axis.
-- @param y The amount to move the TileLayer along the Y axis.
function TileLayer:move(x, y)
	utils:moveObject(self.group, x, y)
end

--- Drags the TileLayer.
-- @param event The Touch event.
function TileLayer:drag(event)
	utils:dragObject(self.group, event)
end

--- Sets the rotation of the TileLayer.
-- @param angle The new rotation.
function TileLayer:setRotation(angle)
	self.group.rotation = angle
end

--- Rotates the TileLayer.
-- @param angle The angle to rotate by.
function TileLayer:rotate(angle)
	self.group.rotation = self.group.rotation + angle
end

--- Updates the TileLayer.
-- @param event The enterFrame event.
function TileLayer:update( event )
	      
end

function TileLayer:updateTileVisibility()
	
	if self.visible then
		
		if self.visibleTiles then
			for i=1, #self.visibleTiles, 1 do
				if self.visibleTiles[i].isVisible then
					self.visibleTiles[i].isVisible = false
				end
			end
		end
		
		self.visibleTiles = nil
		self.visibleTiles = {}

		local xScale, yScale = self.map:getScale()
		local tileWidth = floor( self.map.tilewidth * xScale )
		local tileHeight = floor( self.map.tileheight * yScale )
		
		local cam = {}
		cam.x = abs( self.map.world.x - tileWidth )
		cam.y = abs( self.map.world.y - tileHeight )
		cam.width = floor( ( ( display.contentWidth * xScale ) + tileWidth ) * xScale )
		cam.height = floor( ( ( display.contentHeight * yScale ) + tileHeight ) * yScale )
			
		local buffer = {}
		buffer.left = tileWidth
		buffer.right = tileWidth
		buffer.top = tileHeight
		buffer.bottom = tileHeight

		local view = {}
		view.xMin = floor( ( ( cam.x - buffer.left ) / tileWidth ) )
		view.xMax = floor( ( ( cam.x + ( cam.width + buffer.right ) ) / tileWidth / xScale ) )
		view.yMin = floor( ( ( cam.y - buffer.top ) / tileHeight ) )
		view.yMax = floor( ( ( cam.y + ( cam.height + buffer.bottom ) ) / tileHeight / yScale ) )
	
		if view.xMin < 0 then
			view.xMin = 0 
		end
		
		if view.xMax > self.map.width * xScale then
			view.xMax = self.map.width * xScale
		end
		
		if view.yMin < 0 then
			view.yMin = 0
		end
		
		if view.yMax > self.map.height * yScale then
			view.yMax = self.map.height * yScale
		end

		for x = view.xMin, view.xMax, 1 do
	
			for y = view.yMin, view.yMax, 1 do 

				if not self.tileGrid then
					self.tileGrid = {}
				end
				
				if self.tileGrid[x] then
		
					if self.tileGrid[x][y] then
						local tile = self.tileGrid[x][y]
						
						if not tile.ignoreCulling then
							if tile and tile.sprite and tile.gid ~= 0 then 
					
								if not tile.sprite.isVisible then
									tile.sprite.isVisible = true
									self.visibleTiles[ #self.visibleTiles + 1 ] = tile.sprite
								end
						
							end
						end
					end
					
				end
	
			end 
			
		end
		
	end
	
end

--- Creates the visual representation of the layer.
-- @return The group containing the newly created layer.
function TileLayer:create()
	
	if not self.map.world then
		self.map.world = display.newGroup()
	end
	
	self.group = display.newGroup()

	if(lime.isDebugModeEnabled()) then
		print("Lime-Coconut: Creating layer - " .. self.name)
	end
		
	local tile = nil
	
	for i=1, #self.tiles, 1 do

		tile = self.tiles[i]
		
		tile:create(i)
	
		if(tile.sprite) then
			
		else
			-- If no sprite was created then chances are this was a blank section, delete the tile to save some memory (maybe). If problems start appearing simply comment out the next lines.
			--tile:destroy()
			--tile = nil
		end				
		
	end
	
	for key, value in pairs(self.properties) do
		self.map:firePropertyListener(self.properties[key], "layer", self)
	end		
	
	-- Override tile properties if this layer has been marked as static - NOTE: THIS IS A TEMPORARY FEATURE UNTIL A MORE FLEXIBLE / SECURE FEATURE SET HAS BEEN DECIDED ON!
	if self:getPropertyValue("IsStatic") then
		
		local tile = nil
		
		for i=1, #self.tiles, 1 do
			
			tile = self.tiles[i]
			
			if tile.gid ~= 0 then
				tile.HasBody = "true"
				tile.bodyType = "static"
			end
		
		end
		
	end
		
	if self.opacity then
		self.group.alpha = self.opacity 
	end
	
	self.pixelwidth = self.width * self.map.tilewidth
	self.pixelheight = self.height * self.map.tileheight
	
	self.visible = ( self.visible == 1 or self.visible == nil )
	
	return self.group
end

--- Builds the physical representation of the TileLayer.
function TileLayer:build()
		
	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Building Tile Layer - " .. self.name)
	end	
	
	for i=1, #self.tiles, 1 do
		self.tiles[i]:build()
	end
	
end

--- Completely removes all visual and physical objects associated with the TileLayer.
function TileLayer:destroy()

	if self.group and self.tiles then
	
		for i=1, #self.tiles, 1 do	
			self.tiles[i]:destroy()
		end
		
		self.tiles = nil
		
		self.group:removeSelf()
		self.group = nil
	end
	
end

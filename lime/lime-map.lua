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
-- File name: lime-map.lua
--
----------------------------------------------------------------------------------------------------
----									REQUIRED MODULES										----
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
----									CLASS METATABLE											----
----------------------------------------------------------------------------------------------------

Map = {}
Map_mt = { __index = Map }

----------------------------------------------------------------------------------------------------
----									CLASS VARIABLES											----
----------------------------------------------------------------------------------------------------

Map.version = 3.4

----------------------------------------------------------------------------------------------------
----									LOCALISED VARIABLES										----
----------------------------------------------------------------------------------------------------

local abs = math.abs 
local floor = math.floor

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

--- Create a new instance of a Map object.
-- @param filename
-- @param baseDirectory
-- @param customMapParams
-- @return The newly created Map instance.
function Map:new(filename, baseDirectory, customMapParams)

    local self = {}    -- the new instance
    
    setmetatable( self, Map_mt ) -- all instances share the same metatable
    
    self.properties = {}
    self.header = {}
    self.tileSets = {}
    self.tileLayers = {}
    self.objectLayers = {}
    
    self.objectListeners = {}
    self.propertyListeners = {}
    self.filename = filename
    self.baseDirectory = baseDirectory
    
	-- Get the absolute path
	local path = system.pathForFile(filename, baseDirectory or system.ResourcesDirectory)
	
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Lychee: Loading Map - " .. filename)
	end
	
	-- Map file exists
	if path then
		
		self.rootDir = utils:stripFilenameFromPath(path)
		
		if customMapParams then
			
			if(customMapParams.type == "dweezil") then
				
				if not customMapParams.tileset then
					return nil
				end
				
				if not customMapParams.tilewidth then
					return nil
				end
				
				if not customMapParams.tileheight then
					return nil
				end

				local tilesetImage = customMapParams.tileset
	
				local levelData = utils:readLines(path)
				
				--if tilesetImage and levelData then
				if levelData then
				
					local header = levelData[1]
					
					self.xml = {}
					
					if(header) then
					
						-- CREATE MAP DATA
						self.xml["Attributes"] = {}
						self.xml["Attributes"].version = "1.0"
						self.xml["Attributes"].width = header:sub(1, 3) --+ 1
						self.xml["Attributes"].height = header:sub(4, 6) --+ 1
						self.xml["Attributes"].tilewidth = customMapParams.tilewidth						
						self.xml["Attributes"].tileheight = customMapParams.tileheight
						self.xml["Attributes"].orientation = "orthogonal"
						
						-- CREATE THE CHILD NODES
						self.xml["ChildNodes"] = {}
						
						-- CREATE THE TILESET
						self.xml["ChildNodes"][1] = {}
						self.xml["ChildNodes"][1].Name = "tileset"
						self.xml["ChildNodes"][1]["Attributes"] = {}
						self.xml["ChildNodes"][1]["Attributes"].name = customMapParams.tilesetName or "tileset"
						self.xml["ChildNodes"][1]["Attributes"].tilewidth = customMapParams.tilewidth
						self.xml["ChildNodes"][1]["Attributes"].tileheight = customMapParams.tileheight
						self.xml["ChildNodes"][1]["Attributes"].firstgid = "1"
						
						self.xml["ChildNodes"][1]["ChildNodes"] = {}
						self.xml["ChildNodes"][1]["ChildNodes"][1] = {}
						self.xml["ChildNodes"][1]["ChildNodes"][1].Name = "image"
						self.xml["ChildNodes"][1]["ChildNodes"][1]["Attributes"] = {}
						self.xml["ChildNodes"][1]["ChildNodes"][1]["Attributes"].source = customMapParams.tileset
						
						-- CREATE THE LAYER
						self.xml["ChildNodes"][2] = {}
						self.xml["ChildNodes"][2].Name = "layer"
						
						self.xml["ChildNodes"][2]["Attributes"] = {}
						self.xml["ChildNodes"][2]["Attributes"].name = customMapParams.layerName or "layer"
						self.xml["ChildNodes"][2]["Attributes"].width = self.xml["Attributes"].width
						self.xml["ChildNodes"][2]["Attributes"].height = self.xml["Attributes"].height
						self.xml["ChildNodes"][2]["Attributes"].encoding = "csv"	
						
						
						-- CREATE THE TILES
						self.xml["ChildNodes"][2]["ChildNodes"] = {}
						self.xml["ChildNodes"][2]["ChildNodes"][1] = {}
						self.xml["ChildNodes"][2]["ChildNodes"][1].Name = "data"
						
						local tileIDString = ""
						
						for i=2, #levelData - 1, 1 do
							
							for j = 1, #levelData[i] - 1 do
								local tileID = levelData[i]:sub(j, j)
								
								if(tileID == " ") then
									tileID = "0"
								end

								tileIDString = tileIDString .. tileID .. ","
			
							end
						end
				
						self.xml["ChildNodes"][2]["ChildNodes"][1].Value = tileIDString
					
						
					end
				
				end
				
			end
			
			
		else -- A regular TMX map		
			-- Read in all the data
			self.xml = XmlParser:ParseXmlFile(path)
		end	
			
	end

	-------------------------------
	---- Load In Header Values ----
	-------------------------------
	
	-- Loop through the header BEFORE loading anything else
	for key, value in pairs(self.xml["Attributes"]) do 
		self:setProperty(key, value)
		self.header[key] = value
	end
	
	local tileLayer = nil
	local tileSet = nil
	local objectLayer = nil
	local property = nil
	
	local node = nil
	local nodeName = nil
	local attributes = nil
	
	-------------------------------
	----   Load In Map Items   ----
	-------------------------------
	for i=1, #self.xml["ChildNodes"], 1 do
		
		node = self.xml["ChildNodes"][i]
		nodeName = node.Name
		
		if(nodeName == "tileset") then
			
			tileSet = TileSet:new(node, self)
					
			self.tileSets[#self.tileSets + 1] = tileSet
					
			if(lime.isDebugModeEnabled() and tileSet) then
				print("Lime-Lychee: Loaded TileSet - " .. tileSet.name)
			end
					
		elseif(nodeName == "layer") then
		
			tileLayer = TileLayer:new(node, self)
				
			self.tileLayers[#self.tileLayers + 1] = tileLayer
				
			if(lime.isDebugModeEnabled() and tileLayer) then
				print("Lime-Lychee: Loaded Tile Layer - " .. tileLayer.name)
			end
			
		elseif(nodeName == "objectgroup") then
		
			objectLayer = ObjectLayer:new(node, self)
				
			self.objectLayers[#self.objectLayers + 1] = objectLayer
				
			if(lime.isDebugModeEnabled() and objectLayer) then
				print("Lime-Lychee: Loaded Object Layer - " .. objectLayer.name)
			end
					
		elseif(nodeName == "properties") then
			
			-- Loop through all the child nodes
			for j=1, #node["ChildNodes"], 1 do
			
				-- Each child node is a property, the attributes are the name and value
				attributes = node["ChildNodes"][j]["Attributes"]
				
				if attributes then
					
					if attributes.name == "configFile" then

						utils:readInConfigFile(attributes.value, self)
						
					else
						
						property = self:setProperty(attributes.name, attributes.value)
						
						if(lime.isDebugModeEnabled() and property) then
							print("Lime-Lychee: Loaded Map Property - " .. property.name)
						end
					end
				end
			end
		end
	end
			
			
	self.widestTile = 0
	self.tallestTile = 0

	for i = 1, #self.tileSets, 1 do
	
		local ts = self.tileSets[i]
		
		if ts.tilewidth > self.widestTile then self.widestTile = ts.tilewidth end
		if ts.tileheight > self.tallestTile then self.tallestTile = ts.tileheight end
		
	end
	
	self.screenClampingEnabled = true
	
    return self
    
end

--- Sets the value of a Property of the Map. Will create a new Property if none found.
-- @param name The name of the Property.
-- @param value The new value.
-- @return The property being set.
function Map:setProperty(name, value)
		
	local property = self:getProperty(name)
	
	if property then
		property:setValue(value)
	else
		property = self:addProperty(Property:new(name, value))
	end
	
	self[name] = self:getPropertyValue(name)
	
	return property
end

--- Gets a Property of the Map.
-- @param name The name of the Property.
-- @return The Property. nil if no Property found.
function Map:getProperty(name)
	return self.properties[name]
end

--- Gets the value of a Property of the Map.
-- @param name The name of the Property.
-- @return value The Property value. nil if no Property found.
function Map:getPropertyValue(name)
	
	local property = self:getProperty(name)
	
	if property then
		return property:getValue()
	end
	
end

--- Gets a list of all Properties of the Map.
-- @return The list of Properties.
function Map:getProperties()
	return self.properties
end

--- Gets a count of how many properties the Map has.
-- @return The Property count.
function Map:getPropertyCount()

	local count = 0
	
	for _k, _v in pairs(self.properties) do
		count = count + 1
	end

	return count
end

--- Checks whether the Map has a certain Property.
-- @param name The name of the property to check for.
-- @return True if the Map has the Property, false if not.
function Map:hasProperty(name)
	return self:getProperty(name) ~= nil
end

--- Adds a Property to the Map. 
-- @param property The Property to add.
-- @return The added Property.
function Map:addProperty(property)
	self.properties[property:getName()] = property
	
	self[property:getName()] = property:getValue()

	return property
end

--- Removes a Property from the Map. 
-- @param name The name of the Property to remove.
function Map:removeProperty(name)
	self.properties[name] = nil
	self[name] = nil
end

--- Gets the value of a header Property of the Map.
-- @param name The name of the header Property.
-- @return value The Property value. nil if no Property found.
function Map:getHeaderValue(name)
	
	return self.header[name]
	
end

--- Gets a TileLayer.
-- @param indexOrName The index or name of the TileLayer to get.
-- @return The tile layer at indexOrName.
function Map:getTileLayer(indexOrName)
	
	if type(indexOrName) == "number" then
		
		return self.tileLayers[indexOrName]
		 
	elseif type(indexOrName) == "string" then
		
		for i=1, #self.tileLayers, 1 do 
			
			if self.tileLayers[i].name == indexOrName then
				return self.tileLayers[i]
			end
			
		end
		
	end
	
end

--- Gets an ObjectLayer.
-- @param indexOrName The index or name of the ObjectLayer to get.
-- @return The object layer at indexOrName.
function Map:getObjectLayer(indexOrName)
	
	if type(indexOrName) == "number" then
		
		return self.objectLayers[indexOrName]
		 
	elseif type(indexOrName) == "string" then
		
		for i=1, #self.objectLayers, 1 do 
			
			if self.objectLayers[i].name == indexOrName then
				return self.objectLayers[i]
			end
			
		end
		
	end
	
end

--- Gets a list of TileLayers across the map that have a specified property. 
-- @param name The name of the Property to look for.
-- @return A list of found TileLayer. Empty if none found.
function Map:getTileLayersWithProperty(name)

	local tileLayers = {}
	
	for i = 1, #self.tileLayers, 1 do
	
		if self.tileLayers[i]:hasProperty(name) then
			tileLayers[#tileLayers + 1] = self.tileLayers[i]
		end
	end

	return tileLayers
	
end

--- Gets a list of ObjectLayers across the map that have a specified property. 
-- @param name The name of the Property to look for.
-- @return A list of found ObjectLayer. Empty if none found.
function Map:getObjectLayersWithProperty(name)

	local objectLayers = {}
	
	for i = 1, #self.objectLayers, 1 do
		
		if self.objectLayers[i]:hasProperty(name) then
			objectLayers[#objectLayers + 1] = self.objectLayers[i]
		end
	end

	return objectLayers
	
end

--- Gets a TileSet.
-- @param indexOrName The index or name of the TileSet to get.
-- @return The tileset at indexOrName.
function Map:getTileSet(indexOrName)

	if type(indexOrName) == "number" then
		
		return self.tileSets[indexOrName]
		 
	elseif type(indexOrName) == "string" then
		
		for i=1, #self.tileSets, 1 do 
			
			if self.tileSets[i].name == indexOrName then
				return self.tileSets[i]
			end
			
		end
		
	end
	
end


--- Gets a Tile image from a GID.
-- Fixed fantastically by FrankS - http://developer.anscamobile.com/forum/2011/02/18/bug-mapgettilesetfromgidgid
-- @param gid The gid to use.
-- @return The tileset at the gid location.
function Map:getTileSetFromGID(gid)

	if gid then
	
		local tileSets = self.tileSets

		if #tileSets > 0 and gid >= tileSets[1].firstgid then
            
            for i = 2, #tileSets, 1 do 
            	if tileSets[i].firstgid > gid then 
                	return tileSets[i-1] 
                end
            end
                
            return tileSets[#self.tileSets]  -- leap of faith that it's in the last tileset
            
        else
        
            return nil 
            
        end
        
	end
	
		--[[
		
		local tileSet = nil
		
		local nextTileSet = nil
	
		for i=1, #self.tileSets, 1 do 
			
			if self.tileSets[i].firstgid < gid then
							
				nextTileSet = self.tileSets[i + 1]
			
				if nextTileSet then
				
					if nextTileSet.firstgid then
						
						if tonumber(nextTileSet.firstgid) > tonumber(gid) then
							tileSet = self.tileSets[i]
						end
					end
					
				else
					
					return self.tileSets[i]
					
				end
				
			end
			
		end
	end
	
	return tileSet
	
	--]]
end

--- Shows the Map.
function Map:show()
	for i=1, #self.tiles, 1 do	
		self.tileLayers[i]:show()	
	end	
	
	local visual = self:getVisual()
	
	if visual then
		visual.isVisible = true
	end

end

--- Hides the Map.
function Map:hide()
	for i=1, #self.tileLayers, 1 do
		self.tileLayers[i]:hide()		
	end
	
	local visual = self:getVisual()
	
	if visual then
		visual.isVisible = false
	end
	
end

--- Gets the Maps visual.
function Map:getVisual()
	return self.world
end

--- Moves the Map.
-- @param x The amount to move the Map along the X axis.
-- @param y The amount to move the Map along the Y axis.
function Map:move(x, y)
	
	if self.world then
	
		utils:moveObject(self.world, x, y)
		
		if self:isScreenClampingEnabled() then
			self.world.x, self.world.y = utils:clampPosition( self.world.x, self.world.y, self.bounds, self.orientation == "isometric" )
		end
		
		if self.orientation == "orthogonal" then
			if self.ParallaxEnabled then
				self:setParallaxPosition{ x = self.world.x, y = self.world.y }
			end
		else
			
		end
		
		
		self:updateLayerVisibility()
		
	end
	
end

--- Drags the Map.
-- @param event The Touch event.
function Map:drag(event)

	if self.world then
	
		if self.slideTransition then
			transition.cancel( self.slideTransition )
			Runtime:removeEventListener( "enterFrame", self.onSlideTransitionUpdate )
		end
	
		utils:dragObject( self.world, event )
		
		if self:isScreenClampingEnabled() then
			self.world.x, self.world.y = utils:clampPosition( self.world.x, self.world.y, self.bounds, self.orientation == "isometric" )
		end
		
		if self.orientation == "orthogonal" then
			if self.ParallaxEnabled then
				self:setParallaxPosition{ x = self.world.x, y = self.world.y }
			end
		else
		
		end
		
		self:updateLayerVisibility()
		
	end		
end
	
--- Sets the rotation of the Map.
-- @param angle The new rotation.
function Map:setRotation(angle)

	for i=1, #self.tileLayers, 1 do 
		self.tileLayers[i]:setRotation(angle)
	end
	
	for i=1, #self.objectLayers, 1 do 
		self.objectLayers[i]:setRotation(angle)
	end
	
end

--- Rotates the Map.
-- @param angle The angle to rotate by.
function Map:rotate(angle)

	for i=1, #self.tileLayers, 1 do 
		self.tileLayers[i]:rotate(angle)
	end
	
	for i=1, #self.objectLayers, 1 do 
		self.objectLayers[i]:rotate(angle)
	end
	
end

--- Sets the scale of the Map.
-- @param xScale The new scale of the map by in the X direction.
-- @param yScale The new scale of the map by in the Y direction. Leave nil to set X and Y as the first paramater.
function Map:setScale( xScale, yScale )

	if self.world then
		self.world.xScale = ( xScale or 1 )
		self.world.yScale = ( yScale or self.world.xScale )
		self:updateLayerVisibility()
		--self.world.xReference = 0
		--self.world.yReference = 0
	end
	
	self:adjustClampingBoundsForScale()
	self:updateLayerVisibility()
	
end

--- Scales the Map.
-- @param xScale The amount to scale the map by in the X direction.
-- @param yScale The amount to scale the map by in the Y direction. Leave nil to scale X and Y as the first paramater.
function Map:scale( xScale, yScale )

	if self.world then
		self.world.xScale = self.world.xScale + ( xScale or 0 )
		self.world.yScale = self.world.yScale + ( yScale or xScale or 0 )
		self:updateLayerVisibility()
		--self.world.xReference = 0
		--self.world.yReference = 0
	end
	
	self:adjustClampingBoundsForScale()
	self:updateLayerVisibility()
	
end

--- Sets the scale of the Map centred around a position.
-- @param xScale The new scale of the map by in the X direction.
-- @param yScale The new scale of the map by in the Y direction. Leave nil to set X and Y as the first paramater.
-- @param position The world position to use. A table with x and y properties.
function Map:setScaleAtPosition( xScale, yScale, position )

	if self.world then
		
		-- Reset the reference points
		self:resetReferencePoint()
		
		-- Set them to the new position
		self.world.xReference = position.x
		self.world.yReference = position.y
	
	end
	
	-- Set scale
	self:setScale( xScale, yScale )
	
end

--- Scales the Map centred around a position.
-- @param xScale The amount to scale the map by in the X direction.
-- @param yScale The amount to scale the map by in the Y direction. Leave nil to scale X and Y as the first paramater.
-- @param position The world position to use. A table with x and y properties.
function Map:scaleAtPosition( xScale, yScale, position )

	if self.world then
	
		-- Reset the reference points
		self:resetReferencePoint()
	
		self.xReferenceDifference = position.x - self.world.xReference
		self.yReferenceDifference = position.y - self.world.yReference
		
		-- Set them to the new position
		self.world.xReference = position.x
		self.world.yReference = position.y
		
		-- Scale
		self:scale( xScale, yScale )
		
	end

end

--- Gets the scale of the Map.
-- @return The X scale of the Map.
-- @return The Y scale of the Map.
function Map:getScale()
	if self.world then
		return self.world.xScale, self.world.yScale
	end
end

--- Sets the position of the Map.
-- @param x The new X position of the Map.
-- @param y The new Y position of the Map.
function Map:setPosition(x, y)

	if self.world then
	
		local viewPoint = utils:calculateViewpoint(self.world, x, y)

		self.world.x = utils:round(viewPoint.x)
		self.world.y = utils:round(viewPoint.y)

		if self:isScreenClampingEnabled() then
			self.world.x, self.world.y = utils:clampPosition( self.world.x, self.world.y, self.bounds, self.orientation == "isometric" )
		end
		
		if self.orientation == "orthogonal" then
						
			if self.ParallaxEnabled then
				self:setParallaxPosition{ x = self.world.x, y = self.world.y }
			end
			
			if self:isScreenClampingEnabled() then
				self.world.x, self.world.y = utils:clampPosition( self.world.x, self.world.y, self.bounds, self.orientation == "isometric" )
			end
			
		end
		
		self:updateLayerVisibility()
		
	end	
end

--- Gets the position of the Map. Will return the position of the baseLayer if using parallax.
-- @return The X position of the Map.
-- @return The Y position of the Map.
function Map:getPosition()

	if self.world then
	
		if self.ParallaxEnabled and self.parallaxBaseLayer and self.parallaxBaseLayer.group then
			return self.parallaxBaseLayer.group.x, self.parallaxBaseLayer.group.y
		else
			return self.world.x, self.world.y
		end
		
	end

end

--- Fades the Map to a new position.
-- @param x The new X position of the Map.
-- @param y The new Y position of the Map.
-- @param fadeTime The time it will take to fade the Map out or in. Optional, default is 1000.
-- @param moveDelay The time inbetween both fades. Optional, default is 0.
-- @param onCompleteHandler Event handler to be called on movement completion. Optional.
-- @param easing Easing function for the transition. Optional.
function Map:fadeToPosition(x, y, fadeTime, moveDelay, onCompleteHandler, easing )
	utils:fadeObjectToPosition(self, self.world, x, y, fadeTime, moveDelay, onCompleteHandler, easing )
end

--- Fades the Map to a new alpha amount.
-- @param alpha The new alpha for the Map.
-- @param fadeTime The time it will take to fade the Map. Optional, default is 1000.
-- @param onCompleteHandler Event handler to be called on fade completion. Optional.
-- @param easing Easing function for the transition. Optional.
function Map:fadeToAmount( alpha, fadeTime, onCompleteHandler, easing )
	utils:fadeObjectToAmount( self, self.world, alpha, fadeTime, onCompleteHandler, easing )
end

--- Slides the Map to a new position.
-- @param x The new X position of the Map.
-- @param y The new Y position of the Map.
-- @param slideTime The time it will take to slide the Map to the new position.
-- @param onCompleteHandler Event handler to be called on movement completion. Optional.
-- @param easing Easing function for the transition. Optional.
function Map:slideToPosition( x, y, slideTime, onCompleteHandler, easing )
	
	local viewPoint = utils:calculateViewpoint(self.world, x, y)
	
	local clampedX, clampedY = x, y
	
	if self.orientation == "orthogonal" then
		-- Clamp the position first to ensure that it is not outside the bounds
		if self:isScreenClampingEnabled() then
			clampedX, clampedY = utils:clampPosition( utils:round( viewPoint.x, 0.5 ), utils:round( viewPoint.y, 0.5 ), self.bounds, self.orientation == "isometric" )
		end
	end

	utils:slideObjectToPosition( self, self.world, clampedX, clampedY, slideTime, onCompleteHandler, easing )
	
end

--- Cancels any slideTo/fadeTo transitions on the map. Should be called when destroying the map or changing Director scenes.
function Map:cancelTransitions()
	
	local visual = self:getVisual()
	
	if not visual then
		return
	end
	
	if visual.fadeTransition then
		transition.cancel( visual.fadeTransition )
		visual.moveDelayTimer = nil
	end
	
	if visual.slideTransition then
		transition.cancel( visual.slideTransition )
		visual.moveDelayTimer = nil
	end
	
	if visual.moveDelayTimer then
		timer.cancel( visual.moveDelayTimer )
		visual.moveDelayTimer = nil
	end
	
end

--- Shows all debug images on the Map.
function Map:showDebugImages()
	
	for i=1, #self.objectLayers, 1 do 
		self.objectLayers[i]:showDebugImages()
	end
end

--- Hides all debug images on the Map.
function Map:hideDebugImages()

	for i=1, #self.objectLayers, 1 do 
		self.objectLayers[i]:hideDebugImages()
	end
end

--- Toggles the visibility of all debug images on the Map.
function Map:toggleDebugImagesVisibility()
	
	for i=1, #self.objectLayers, 1 do 
		self.objectLayers[i]:toggleDebugImagesVisibility()
	end
	
end	

--- Gets all Tiles across all TileLayers at a specified position.
-- @param position The position of the Tiles. A table containing either x & y or row & column.
-- @param count The number of Tiles to get. Optional.
-- @params full If true the search will check all tiles using their updated rather than original grid position. Might be slower then non-full search so use with caution.
-- @return A table of found Tiles. Empty if none found.
function Map:getTilesAt(position, count, full)

	local tiles = {}
	local tile = nil
	
	for i=1, #self.tileLayers, 1 do
		
		tile = self.tileLayers[i]:getTileAt(position, full)
		
		if(tile) then
			tiles[#tiles + 1] = tile
		end
		
		if(count) then
			if(count == #tiles) then -- If they want more, wait till we have the correct amount
				return tiles
			end
		end
		
	end
	
	return tiles
end
	
--- Gets the first found tile at a specified position.
-- @param position The position of the Tile. A table containing either x & y or row & column.
-- @params full If true the search will check all tiles using their updated rather than original grid position. Might be slower then non-full search so use with caution.
-- @return tile The found Tile. nil if none found.	
function Map:getTileAt(position, full)
	local tiles = self:getTilesAt(position, 1, full)
	return tiles[1]
end
	
--- Gets a list of Tiles across all TileLayers that have a specified property. 
-- @param name The name of the Property to look for.
-- @return A list of found Tiles. Empty if none found.
function Map:getTilesWithProperty(name)

	local tiles = {}
	
	local tileLayers = {}
	
	for i = 1, #self.tileLayers, 1 do
		
		tileLayers = self.tileLayers[i]:getTilesWithProperty(name)
		
		for j = 1, #tileLayers, 1 do
			tiles[#tiles + 1] = tileLayers[j]
		end

	end

	return tiles
end

--- Gets a list of Objects across all ObjectLayers that have a specified property. 
-- @param name The name of the Property to look for.
-- @return A list of found Objects. Empty if none found.
function Map:getObjectsWithProperty(name)

	local objects = {}
	
	local objectLayers = {}
	
	for i = 1, #self.objectLayers, 1 do
		
		objectLayers = self.objectLayers[i]:getObjectsWithProperty(name)
		
		for j = 1, #objectLayers, 1 do
			objects[#objects + 1] = objectLayers[j]
		end

	end

	return objects
end

--- Gets a list of Objects across all ObjectLayers that have a specified name. 
-- @param name The name of the Objects to look for.
-- @return A list of found Objects. Empty if none found.
function Map:getObjectsWithName(name)

	local objects = {}
	
	local objectLayers = {}
	
	for i = 1, #self.objectLayers, 1 do
		
		objectLayers = self.objectLayers[i]:getObjectsWithName(name)
		
		for j = 1, #objectLayers, 1 do
			objects[#objects + 1] = objectLayers[j]
		end

	end

	return objects
end

--- Gets a list of Objects across all ObjectLayers that have a specified type. 
-- @param objectType The type of the Objects to look for.
-- @return A list of found Objects. Empty if none found.
function Map:getObjectsWithType(objectType)

	local objects = {}
	
	local objectLayers = {}
	
	for i = 1, #self.objectLayers, 1 do
		
		objectLayers = self.objectLayers[i]:getObjectsWithType(objectType)
		
		for j = 1, #objectLayers, 1 do
			objects[#objects + 1] = objectLayers[j]
		end

	end

	return objects
end

--- Gets a list of all tile properties across the map that have the same name.
--	Originally created by FrankS - http://developer.anscamobile.com/forum/2011/02/19/additional-convenience-functions-navigate-lime-world-tree
-- @param name The type of the Property to look for.
-- @return A list of found Objects. Empty if none found.
function Map:findValuesByTilePropertyName(name)

	local tiles = selfgetTilesWithProperty(name)
	local values = {}
	
	for i = 1, #tiles, 1 do
		values[#values + 1] = tiles[i]:getPropertyValue(name)
	end

	return values
	
end

--- Creates a sprite from a passed in GID
--	Originally created by FrankS - http://developer.anscamobile.com/forum/2011/02/19/additional-convenience-functions-navigate-lime-world-tree
-- @param gid The gid of the tile to create.
-- @return A corona display object. Nil if gid was invalid.
function Map:createSprite(gid)

	local tileSet = self:getTileSetFromGID( gid )
	
	if tileSet then
		return tileSet:createSprite(gid)
	end

end

--- Creates a new tile from a passed in GID. This will include all properties however it will not Build it ( by design ). If you wish to build it then simply call ":build()" on the returned tile.
-- @param gid The gid of the tile to create.
-- @param layerName The name of the TileLayer to create the Tile on.
-- @return tile The created Tile.
function Map:createTile(gid, layerName)
	
	local tileLayer = self:getTileLayer( layerName )
	
	if tileLayer then	
		return tileLayer:createTile( gid )
	end
	
end

--- Creates and builds a new tile from a passed in GID. This will include all properties.
-- @param gid The gid of the tile to create.
-- @param layerName The name of the TileLayer to create the Tile on.
-- @return tile The created Tile.
function Map:createAndBuildTile(gid, layerName)
	
	local tileLayer = self:getTileLayer( layerName )
	
	if tileLayer then	
		return tileLayer:createAndBuildTile( gid )
	end
	
end

--- Creates a new tile from a passed in GID and sets its position. This will include all properties however it will not Build it ( by design ). If you wish to build it then simply call ":build()" on the returned tile.
-- @param gid The gid of the tile to create.
-- @param layerName The name of the TileLayer to create the Tile on.
-- @param position The world position for the Tile.
-- @return tile The created Tile.
function Map:createTileAt(gid, layerName, position)
	
	local tileLayer = self:getTileLayer( layerName )
	
	if tileLayer then
		return tileLayer:createTileAt( gid, position )
	end
	
end

--- Creates and builds a new tile from a passed in GID and sets its position.
-- @param gid The gid of the tile to create.
-- @param layerName The name of the TileLayer to create the Tile on.
-- @param position The world position for the Tile.
-- @return tile The created Tile.
function Map:createAndBuildTileAt(gid, layerName, position)
	
	local tileLayer = self:getTileLayer( layerName )
	
	if tileLayer then
		return tileLayer:createAndBuildTileAt( gid, position )
	end
	
end

--- Gets a property value from a tileset.
--	Originally created by FrankS - http://developer.anscamobile.com/forum/2011/02/19/additional-convenience-functions-navigate-lime-world-tree
-- @param gid The gid of the tile to check.
-- @param name The name of the property to look for.
-- @return The value of the property. Nil if none found.
function Map:getTilePropertyValueForGID(gid, name)

	local tileSet = self:getTileSetFromGID(gid)
	
	if tileSet then
	
		local properties = tileSet:getPropertiesForTile(gid)
	
		for i = 1, #properties, 1 do
			if properties[i]:getName() == name then
				return properties[i]:getValue()
			end
		end
		
	end

end

--- Gets the GID and local id for a tile from a named tileset with a specified local id.
--	Originally created by FrankS - http://developer.anscamobile.com/forum/2011/02/19/additional-convenience-functions-navigate-lime-world-tree
-- @param tileSetName The name of the tileset to look for. Can also be specified in a single string - "tileSetName:localTileID".
-- @param localTileID The local id of the tile. Can also be specified in a single string - "tileSetName:localTileID".
-- @return The gid of the tile. Nil if none found.
-- @return The local id of the tile. Nil if none found.
function Map:getGIDForTileNameID(tileSetName, localTileID)

	-- see if only localTileID specified in first arg
	if type( tileSetName ) == "number" or tonumber(tileSetName) then 
		return nil, tonumber(tileSetName)   
	end
	
	-- (maybe) only localTileID specified in first arg string
	local name, localID = unpack( utils:splitString( tileSetName, ":" ) )
		
	if type(name) ~= "string" then 
		return nil, tonumber(name)  
	end
	
	 -- see if we can truly return gid, localTileID
	localID = tonumber(localID) or tonumber(localTileID) or 0
	
	local tileSet = self:getTileSet(name)
	
	if tileSet then 
		return (tonumber(tileSet.firstgid) + localID), localID 
	end
	
	-- fall-through...give up
	return nil  
end

--- Gets the name of the tileset and the local id of a specified gid
--	Originally created by FrankS - http://developer.anscamobile.com/forum/2011/02/19/additional-convenience-functions-navigate-lime-world-tree
-- @param gid The gid of the tile to check.
-- @return The name of the tileset. Nil if none found.
-- @return The local id of the tile. Nil if none found.
function Map:getTileNameIDForGID(gid)

	local tileSet = self:getTileSetFromGID(gid)
	
	if tileSet then
		return tileSet.name, (gid - tileSet.firstgid)
	end
	
end

--- Adds a displayObject to the world. 
-- @param displayObject The displayObject to add.
-- @return The added displayObject.
function Map:addObject(displayObject)
	return utils:addObjectToGroup(displayObject, self.world)
end

--- Adds an Object listener to the Map.
-- @param objectType The type of Object to listen for.
-- @param listener The listener function.
function Map:addObjectListener(objectType, listener)
	
	if(objectType and listener) then
		if(not self.objectListeners[objectType]) then
			self.objectListeners[objectType] = {} 
		end
		self.objectListeners[objectType][#self.objectListeners[objectType] + 1] = listener
	end
	
end

--- Gets a table containing all the object listeners that have been added to the Map.
-- @return The object listeners.
function Map:getObjectListeners()
	return self.objectListeners
end

--- Adds a Property listener to the Map.
-- @param propertyName The name of the Property to listen for.
-- @param listener The listener function.
function Map:addPropertyListener(propertyName, listener)
	if(propertyName and listener) then
		if(not self.propertyListeners[propertyName]) then
			self.propertyListeners[propertyName] = {} 
		end
		
		self.propertyListeners[propertyName][#self.propertyListeners[propertyName] + 1] = listener
	end		
end

--- Gets a table containing all the property listeners that have been added to the Map.
-- @return The property listeners.
function Map:getPropertyListeners()
	return self.propertyListeners
end

--- Fires an already added property listener.
-- @param property The property object that was hit.
-- @param propertyType The type of the property object. "map", "tileLayer", "objectLayer", "tile", "obeject".
-- @param object The object that has the property.
function Map:firePropertyListener(property, propertyType, object)

	if self.propertyListeners[property.name] then
	
		local listeners = self.propertyListeners[property.name] or {}
		
		for i=1, #listeners, 1 do
			listeners[i](property, propertyType, object)
		end
	end	
end

--- Fires an already added object listener
-- @param object The object that the listener was waiting for.
function Map:fireObjectListener(object)

	local listeners = self.objectListeners[object.type] or {}
			
	for i=1, #listeners, 1 do
		listeners[i](object)
	end

end			

--- Sets the focus for the Map.
-- @params object The object to track. nil if you wish to stop tracking.
-- @params xOffset The amount the tracking point should be offset from the object along the X axis. Optional, default is 0.
-- @params yOffset The amount the tracking point should be offset from the object along the Y axis. Optional, default is 0.
function Map:setFocus(object, xOffset, yOffset)
	self.focus = { object = object, xOffset = xOffset, yOffset = yOffset }
end

--- Sets the position of the Map for Parallax effects.
-- @params position The position for the Map.
function Map:setParallaxPosition(position)

	local newPosition = {}
	
	for i = 1, #self.tileLayers, 1 do
		
		newPosition.x = position.x * (self.tileLayers[i].parallaxFactorX or 1)
		newPosition.y = position.y * (self.tileLayers[i].parallaxFactorY or 1)

		self.tileLayers[i]:setPosition( newPosition.x, newPosition.y, true )
		
	end

	for i = 1, #self.objectLayers, 1 do
		
		newPosition.x = position.x * (self.objectLayers[i].parallaxFactorX or 1)
		newPosition.y = position.y * (self.objectLayers[i].parallaxFactorY or 1)

		self.objectLayers[i]:setPosition( newPosition.x, newPosition.y, true )
		
	end	
end

--- Updates the Map.
-- @params event The enterFrame event object.
function Map:update(event)
	
	if self.focus then
	
		if self.focus.object then
		
			self:setPosition(self.focus.object.x + (self.focus.xOffset or 0), self.focus.object.y + (self.focus.yOffset or 0))
			
			if self.ParallaxEnabled then
				self.world.x = self.world.x + self.world.x * -1
				self.world.y = self.world.y + self.world.y * -1
			end
			
		end
		
	end
	
	for i = 1, #self.tileLayers, 1 do
		self.tileLayers[i]:update( event )
	end
	
	if _G.limeScreenCullingEnabled then
		--utils:showScreenSpaceTiles(self)
	end
end

function Map:updateLayerVisibility()
	
	local performCull = false
	
	if self.previousCullX and self.previousCullY then

		local differenceX = self.previousCullX - self.world.x
		local differenceY = self.previousCullY - self.world.y
		
		if abs( differenceX ) > self.tilewidth then
			performCull = true
		elseif abs( differenceY ) > self.tileheight then
			performCull = true
		end
		
	else
		performCull = true
	end
	
	if _G.limeScreenCullingEnabled and performCull then
		for i = 1, #self.tileLayers, 1 do
			self.tileLayers[i]:updateTileVisibility()
				
			self.previousCullX, self.previousCullY = self.world.x, self.world.y
			
		end
	end
	
end

--- Enable screen clamping.
function Map:enableScreenClamping()
	self.screenClampingEnabled = true
end

--- Disable screen clamping.
function Map:disableScreenClamping()
	self.screenClampingEnabled = false
end	

--- Check if screen clamping is enabled.
-- @return True if enabled, false if not.
function Map:isScreenClampingEnabled()
	return self.screenClampingEnabled
end

-- Sets the clamping bounds.
-- @params x The x position of the bounds.
-- @params y The y position of the bounds.
-- @params width The width of the bounds.
-- @params height The height of the bounds.
function Map:setClampingBounds( x, y, width, height )

	if not self.bounds then
		self.bounds = {}
		self.bounds.offset = { x = 0, y = 0 }
	end
		
	self.bounds.x = x
	self.bounds.y = y
	self.bounds.width = width
	self.bounds.height = height
	
	self.unscaledBounds = {}
	self.unscaledBounds.x = self.bounds.x
	self.unscaledBounds.y = self.bounds.y
	self.unscaledBounds.width = self.bounds.width
	self.unscaledBounds.height = self.bounds.height
	self.unscaledBounds.offset = {}
	self.unscaledBounds.offset.x = self.bounds.offset.x
	self.unscaledBounds.offset.y = self.bounds.offset.y
	
end

-- Gets the clamping bounds.
-- @return A table containing the x, y, width, height and offset ( a sub table )
function Map:getClampingBounds()
	return self.bounds
end

-- Sets the offset values for the clamping bounds.
-- @params x The amount to offset the clamping along the x axis.
-- @params y The amount to offset the clamping along the y axis.
function Map:setClampingBoundsOffset( x, y )
	if self.bounds then
		self.bounds.offset = { x = x, y = y }
		self.unscaledBounds.offset = { x = x, y = y }
	end
end

-- Adjusts the clamping bounds when the map is scaled. Automatically called when using map:scale() and map:setScale()
function Map:adjustClampingBoundsForScale()

	local bounds = self:getClampingBounds()
	
	self:resetReferencePoint()
	
	if bounds then
		
		bounds.width = floor( self.unscaledBounds.width * self.world.xScale ) -- self.xReferenceDifference --+ ( self.world.xReference / self.world.xScale ) )
		bounds.height = floor( self.unscaledBounds.height * self.world.yScale ) -- ( self.world.yReference * self.world.yScale ) )
		
		if bounds.offset then
			bounds.offset.x = floor( self.unscaledBounds.offset.x * self.world.xScale )
			bounds.offset.y = floor( self.unscaledBounds.offset.y * self.world.yScale )
		end
		
	end
	
	if self:isScreenClampingEnabled() then
		self.world.x, self.world.y = utils:clampPosition( self.world.x, self.world.y, self.bounds, self.orientation == "isometric" )
	end
	
end

-- Gets the offset values for the clamping bounds.
-- @return X and Y values.
function Map:getClampingBoundsOffset()
	if self.bounds and self.bounds.offset then
		return self.bounds.offset.x, self.bounds.offset.y
	end
end

-- Resets the map reference points.
function Map:resetReferencePoint()

	if self.world then
		
		-- Reset the reference points
		--self.world.xReference = 0
		--self.world.yReference = 0
		
	end
	
end

--- Creates the visual representation of the map.
-- @return The newly created world a visual representation of the map.
function Map:create()
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Coconut: Creating map - " .. self.filename)
	end
	
	self.world = display.newGroup()
	
	for i=1, #self.tileLayers, 1 do

		self.tileLayers[i]:create()
			
		if self.tileLayers[i].group then
			self.world:insert(self.tileLayers[i].group)
		end
	end
	
	for i=1, #self.objectLayers, 1 do

		self.objectLayers[i]:create()
			
		if self.objectLayers[i].group then
			self.world:insert(self.objectLayers[i].group)
		end
	end	
	
	for key, value in pairs(self.properties) do
		self:firePropertyListener(self.properties[key], "map", self)
	end
	
	self.pixelwidth = self.width * self.tilewidth
	self.pixelheight = self.height * self.tileheight	
		
	if self.orientation == "orthogonal" then 
		
		self:setClampingBounds( 0, 0, self.pixelwidth, self.pixelheight )
	
		if self.ParallaxEnabled then
		
			self.parallaxBaseLayer = self:getTileLayersWithProperty("parallaxBase")[1]
			
			if not self.parallaxBaseLayer then
				self.parallaxBaseLayer = self.tileLayers[#self.tileLayers]
			end
			
			if self.parallaxBaseLayer then
				self.bounds.width = self.parallaxBaseLayer.pixelwidth
				self.bounds.height = self.parallaxBaseLayer.pixelheight
			end
			
			self:setClampingBoundsOffset( display.contentWidth / 2, 0 )
			
		end
		
	else
		
		local firstTileLayer = self:getTileLayer(1)
		
		if firstTileLayer then
		
			local topTile = firstTileLayer.tiles[1]
			local rightTile = firstTileLayer.tiles[firstTileLayer.width]
			
			local bottomTile = firstTileLayer.tiles[#firstTileLayer.tiles]
			local leftTile = firstTileLayer.tiles[#firstTileLayer.tiles - ( firstTileLayer.width - 1) ]
	
			self:setClampingBounds( rightTile.sprite.x + ( rightTile.sprite.width / 2 ), topTile.sprite.y - ( rightTile.sprite.height / 2), ( ( (leftTile.sprite.x - rightTile.sprite.x) * -1 ) / 2 ) + ( leftTile.sprite.width / 2 ), self.pixelheight + ( rightTile.sprite.height / 2 ) )

		end
	
	end
	
	self.visualCreated = true
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Coconut: Map Created - " .. self.filename)
	end
	
	if _G.limeScreenCullingEnabled then
		self:updateLayerVisibility()
	else
		for i = 1, #self.tileLayers, 1 do
			self.tileLayers[i]:show()
		end
	end

	return self.world
end

--- Builds the physical representation of the Map.
function Map:build()

	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Building map - " .. self.filename)
	end

	if not physics then
		require("physics")
		physics.start()
	end
	
	local gravityX, gravityY = physics.getGravity()
	
	physics.setGravity( self:getPropertyValue("Physics:GravityX") or gravityX, self:getPropertyValue("Physics:GravityY") or gravityY )
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Setting gravity (x|y) to " .. (self:getPropertyValue("Physics:GravityX") or gravityX) .. "|" .. (self:getPropertyValue("Physics:GravityY") or gravityY))
	end
	
	physics.setScale( self:getPropertyValue("Physics:Scale") or 30 ) 
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Setting scale to " .. (self:getPropertyValue("Physics:Scale") or 30))
	end
	
	physics.setDrawMode( self:getPropertyValue("Physics:DrawMode") or "normal" ) 

	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Setting draw mode to " .. (self:getPropertyValue("Physics:DrawMode") or "normal"))
	end
	
	physics.setPositionIterations( self:getPropertyValue("Physics:PositionIterations") or 8 ) 
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Setting position iterations to " .. (self:getPropertyValue("Physics:PositionIterations") or 8))
	end
	
	physics.setVelocityIterations( self:getPropertyValue("Physics:VelocityIterations") or 3 ) 
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Setting velocity iterations to " .. (self:getPropertyValue("Physics:VelocityIterations") or 3))
	end	
			
	for i=1, #self.objectLayers, 1 do
		self.objectLayers[i]:build()	
	end
	
	for i=1, #self.tileLayers, 1 do
		self.tileLayers[i]:build()
	end	
	
	self.physicalCreated = true
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Map Built - " .. self.filename)
	end
	
end

--- Completely removes all visual and physical objects associated with the Map.
function Map:destroy()

	if self.world then
			
		self:cancelTransitions()
		
		for i=1, #self.tileLayers, 1 do
			self.tileLayers[i]:destroy()
		end
		
		for i=1, #self.objectLayers, 1 do
			self.objectLayers[i]:destroy()
		end
		
		for i=1, #self.tileSets, 1 do
			self.tileSets[i]:destroy()
		end
		
		if self.world and self.world["removeSelf"] then
			self.world:removeSelf()
		end
		
		self.world = nil
	end

end

--- Completely destroys the Map and then reloads it from disk. 
-- Will also recreate the visual and then rebuild the physical if it was in the first place.
-- @return The reloaded Map object.
function Map:reload()
	
	local createVisual = self.visualCreated
	local createPhysical = self.physicalCreated
	local propertyListeners = self:getPropertyListeners()
	local objectListeners = self:getObjectListeners()
		
	self:destroy()
	
	self = Map:new(self.filename, self.baseDirectory)
	
	-- Re add the property listeners
	for propertyName, callbacks in pairs(propertyListeners) do
		for i = 1, #callbacks, 1 do
			self:addPropertyListener(propertyName, callbacks[i])
		end
	end

	-- Re add the object listeners
	for objectType, callbacks in pairs(objectListeners) do
		for i = 1, #callbacks, 1 do
			self:addObjectListener(objectType, callbacks[i])
		end
	end
	
	if createVisual then
		lime.createVisual(self)
	end
	
	if createPhysical then
		lime.buildPhysical(self)
	end
	
	return self
end

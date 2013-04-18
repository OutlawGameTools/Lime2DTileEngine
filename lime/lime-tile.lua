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
-- File name: lime-tile.lua
--
----------------------------------------------------------------------------------------------------
----									REQUIRED MODULES										----
----------------------------------------------------------------------------------------------------

local sprite = require("sprite") -- doh! old sprite stuff needs updated!

----------------------------------------------------------------------------------------------------
----									CLASS METATABLE											----
----------------------------------------------------------------------------------------------------

Tile = {}
Tile_mt = { __index = Tile }

----------------------------------------------------------------------------------------------------
----									CLASS VARIABLES											----
----------------------------------------------------------------------------------------------------

Tile.version = 3.4

----------------------------------------------------------------------------------------------------
----									LOCALISED VARIABLES										----
----------------------------------------------------------------------------------------------------

local contentWidth = display.contentWidth
local contentHeight = display.contentHeight

local newSpriteSet = sprite.newSpriteSet
local newSprite = sprite.newSprite
local newSpriteSheetFromData = sprite.newSpriteSheetFromData

local abs = math.abs
local floor = math.floor
local ceil = math.ceil

----------------------------------------------------------------------------------------------------
----									PRIVATE METHODS											----
----------------------------------------------------------------------------------------------------

local newSpriteSequence = function(spriteSet, sequenceName, startFrame, frameCount, time, loopCount)
	sprite.add( spriteSet, sequenceName, startFrame, frameCount, time, loopCount)
end

local newSpriteSequenceFromString = function(tile, sequenceName, string)
	if(string) then
		local sequence = {}
		string = utils:splitString(string, ",")
		
		for i=1, #string, 1 do
			local param = utils:splitString(string[i], "=")
			
			sequence[param[1]] = param[2]
		end
	
		newSpriteSequence(tile.spriteSet, sequenceName, (sequence.startFrame or 1), sequence.frameCount, sequence.time, sequence.loopCount)
	end
end

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

--- Create a new instance of a Tile object.
-- @param data The XML data.
-- @param map The current Map object.
-- @param layer The TileLayer the the Tile resides on.
-- @return The newly created tile.
function Tile:new(data, map, layer)

    local self = {}    -- the new instance

    setmetatable( self, Tile_mt ) -- all instances share the same metatable
    
    self.properties = {}
    self.map = map
    self.layer = layer
    
    self.mapTileWidth = self.map.tilewidth
    self.mapTileHeight = self.map.tileheight
    
    -- This means it has been manually created. Currently just used in the TileLayer:createTile() function but may be useful for other situations.
    if data.isGenerated then
    	
    	local name = ""
    	local value = ""
    	
    	for i = 1, #data.properties, 1 do
    	
    		name = data.properties[i].name
    		value = data.properties[i].value
    		
    		if name == "gid" then
				self[name] = utils:decodeJsonSafely(value)
			else
				self:setProperty(name, value)
			end
    	end
    	
	else
		
		-- Pull out all the details off this tile, currently it just seems to be the GID however Tiled may add more later.
		for key, value in pairs(data['Attributes']) do 
			if key == "gid" then
				self[key] = utils:decodeJsonSafely(value)
			else
				self:setProperty(key, value)
			end
		end
	
	end
	
	-- Absolutely make sure the gid is a number
	self.gid = utils:convertStringToNumberSafely( self.gid )
				
    return self
    
end

--- Sets the image of the Tile from a Tileset.
-- @param gid The gid of the tile image.
-- @usage Originally created by Mattguest - http://developer.anscamobile.com/forum/2011/02/02/settile-function
function Tile:setImage(gid)	

	local visual = self:getVisual()
	
	-- Make sure there is a visual
	if visual then
		
		-- Calculate the tile index
		--local index = self.map.width * ( tile.row - 1 ) + tile.column
		local index = self.index
		
		local map = self.map
		local tileLayer = self.layer
		
		-- Destroy the tile
		self:destroy()
		
		-- Fake the XML data
		local data = {}
		data["Attributes"] = {}
		data["Attributes"].gid = gid
	
		data["Attributes"].gid = tonumber(data["Attributes"].gid)
		
		-- Create the tile object
		self = Tile:new(data, map, tileLayer)
		
		-- Add the tile to the tile list
		tileLayer.tiles[index] = tile
	
		-- Create the tile visual
		self:create(index)
		
		-- Build the tile physical
		self:build()
		
		-- Bring the new tile into focus
		self:getVisual():toFront()
		self:getVisual().isVisible = true
		
	end

end

--- Sets the value of a Property of the Tile. 
-- Will create a new Property if none found.
-- @param name The name of the Property.
-- @param value The new value.
function Tile:setProperty(name, value)
		
	local property = self:getProperty(name)
	
	if property then
		property:setValue(value)
	else
		self:addProperty(Property:new(name, value))
	end
	
	self[name] = self:getPropertyValue(name)
end

--- Gets a Property of the Tile.
-- @param name The name of the Property.
-- @return The Property. nil if no Property found.
function Tile:getProperty(name)

	if not self.properties then
		self.properties = {}
	end
	
	return self.properties[name]
end

--- Gets the value of a Property of the Tile.
-- @param name The name of the Property.
-- @return The Property value. nil if no Property found.
function Tile:getPropertyValue(name)
	
	local property = self:getProperty(name)
	
	if property then
		return property:getValue()
	end
	
end

--- Gets a list of all Properties of the Tile.
-- @return The list of Properties.
function Tile:getProperties()
	return self.properties
end

--- Gets a count of how many properties the Tile has.
-- @return The Property count.
function Tile:getPropertyCount()

	if not self.properties then
		self.properties = {}
	end
	
	local count = 0
	
	for _k, _v in pairs(self.properties) do
		count = count + 1
	end

	return count
end

--- Checks whether the Tile has a certain Property.
-- @param name The name of the property to check for.
-- @return True if the Tile has the Property, false if not.
function Tile:hasProperty(name)
	return self:getProperty(name) ~= nil
end

--- Adds a Property to the Tile. 
-- @param property The Property to add.
-- @return The added Property.
function Tile:addProperty(property)

	if not self.properties then
		self.properties = {}
	end
	
	self.properties[property:getName()] = property
	
	self[property:getName()] = property:getValue()
	
	return property
end

--- Removes a Property from the Tile. 
-- @param name The name of the Property to remove.
function Tile:removeProperty(name)

	if not self.properties then
		self.properties = {}
	end
	
	self.properties[name] = nil
end

--- Moves the Tile.
-- @param x The amount to move the Tile along the X axis.
-- @param y The amount to move the Tile along the Y axis.
function Tile:move(x, y)
	utils:moveObject( self:getVisual(), x, y)
	self:updateGridPosition()
end

--- Drags the Tile.
-- @param The Touch event.
function Tile:drag(event)
	utils:dragObject( self:getVisual(), event)
	self:updateGridPosition()
end

--- Updates the grid position of the Tile. Called automatically, nothing to see here.
function Tile:updateGridPosition()
	
	local visual = self:getVisual()
	
	if visual then
		self.column = floor( visual.x / self.mapTileWidth ) + 1
		self.row = floor( visual.y / self.mapTileHeight ) + 1
	end
end

--- Sets the position of the Tile.
-- @param x The new X position.
-- @param y The new Y position.
function Tile:setPosition(x, y)

	local visual = self:getVisual()
	
	if visual then
		visual.x = x
		visual.y = y
	end
	
	if self.body then
		self.body.x = x
		self.body.y = y
	end
	
	self:updateGridPosition()
end

--- Slides the Tile to a new position.
-- @param x The new X position of the Tile.
-- @param y The new Y position of the Tile.
-- @param slideTime The time it will take to slide the Tile to the new position.
-- @param onCompleteHandler Event handler to be called on movement completion. Optional.
function Tile:slideToPosition(x, y, slideTime, onCompleteHandler)
	
	local visual = self:getVisual()
	
	if visual then
		utils:slideObjectToPosition(self, visual, x, y, slideTime, onCompleteHandler)
	end
	
end

--- Fades the Tile to a new position.
-- @param x The new X position of the Tile.
-- @param y The new Y position of the Tile.
-- @param fadeTime The time it will take to fade the Tile out or in. Optional, default is 1000.
-- @param moveDelay The time inbetween both fades. Optional, default is 0.
-- @param onCompleteHandler Event handler to be called on movement completion. Optional.
function Tile:fadeToPosition(x, y, fadeTime, moveDelay, onCompleteHandler)
	
	local visual = self:getVisual()
	
	if visual then
		utils:fadeObjectToPosition(self, visual, x, y, fadeTime, moveDelay, onCompleteHandler)
	end
	
end

--- Fades the Tile to a new alpha amount.
-- @param alpha The new alpha for the Tile.
-- @param fadeTime The time it will take to fade the Tile. Optional, default is 1000.
-- @param onCompleteHandler Event handler to be called on fade completion. Optional.
function Tile:fadeToAmount( alpha, fadeTime, onCompleteHandler )
	
	local visual = self:getVisual()
	
	if visual then
		utils:fadeObjectToAmount( self, visual, alpha, fadeTime, onCompleteHandler )
	end
	
end

--- Slides the Tile along a path of points.
-- @param path List of points to move the Object along. Must be a list of tables that have an X and Y value.
-- @param slideTime The time it will take to slide the Object to the next point.
-- @param cycles The amount of times to loop through the path. Optional. Default is unlimited.
function Tile:slideAlongPath(path, slideTime, cycles)

	local visual = self:getVisual()
	
	if visual then
		utils:slideObjectAlongPath(self, visual, path, slideTime, cycles)
	end
	
end

--- Sets the rotation of the Tile.
-- @param angle The new rotation.
function Tile:setRotation(angle)

	local visual = self:getVisual()
	
	if visual then
		visual.rotation = angle
	end
	
	if self.body then
		self.body.rotation = angle
	end
	
end

--- Rotates the Tile.
-- @param angle The angle to rotate by.
function Tile:rotate(angle)

	local visual = self:getVisual()

	if visual then
		visual.rotation = visual.rotation + angle
	end
	
	if self.body then
		self.body.rotation = self.body.rotation + angle
	end
	
end

--- Shows the Tile.
function Tile:show()

	local visual = self:getVisual()
	
	if visual then
		visual.isVisible = true
	end
	
end

--- Hides the Tile.
function Tile:hide()

	local visual = self:getVisual()
	
	if visual then
		visual.isVisible = false
	end
	
end


--- Adjusts the alpha of the tile by a specified amount.
-- @param amount The amount to adjust the alpha by.
function Tile:adjustAlpha( amount )

	local visual = self:getVisual()
	
	if visual then
		visual.alpha = visual.alpha + amount
	end
	
end

--- Sets the alpha of the tile to a specified amount.
-- @param alpha The new alpha for the tile.
function Tile:setAlpha( alpha )

	local visual = self:getVisual()
	
	if visual then
		visual.alpha = alpha
	end
	
end


--- Gets the Tiles visual.
function Tile:getVisual()
	return self.sprite
end

--- Gets the world position of the Tile. 
-- @return The X position of the Tile or nil if there is no sprite
-- @return The Y position of the Tile or nil if there is no sprite
function Tile:getWorldPosition()

	local visual = self:getVisual()
	
	-- Extra checks suggested by Pavel Nakaznenko
	if(visual and visual.parent and visual.isVisible) then
					
		local x = visual.x + self.map:getVisual().x
		local y = visual.y + self.map:getVisual().y
	
		return x, y
		
	end
	
	return nil
end

--- Gets the grid position of the Tile. 
-- @return The Row of the Tile.
-- @return The Column of the Tile.
function Tile:getGridPosition()
	return self.row, self.column
end
	
--- Checks whether the Tile is currently on screen.
-- @return True if the Tile is on screen, false if not.
function Tile:isOnScreen()

	local visual = self:getVisual()
	
	if visual then
	
		local worldX, worldY = self:getWorldPosition()
		
		if worldX and worldY then
			if ( ( worldX + visual.width ) < 0 or ( worldX - visual.width ) > contentWidth ) then
				return false
			elseif ( ( worldY + visual.height ) < 0 or ( worldY - visual.height ) > contentHeight ) then
				return false
			end	
		
			return true
		end
		
	end
	
	return nil
end

--- Creates the visual representation of the Tile.
-- @param index The Tile number. Not the gid.
function Tile:create(index)
	
	self.index = index
	
	if(self.gid) then

		if(self.gid ~= 0) then -- If it is 0 then there is no tile in this spot
			
			-- Check for flipped tiles.
			self.flippedHorizontally = false
			self.flippedVertically = false
			self.flippedDiagonally = false
			
			if self.gid >= 0x80000000 then
				self.flippedHorizontally = true
				self.gid = self.gid - 0x80000000
			end
			if self.gid >= 0x40000000 then
				self.flippedVertically = true
				self.gid = self.gid - 0x40000000
			end
			
			if self.gid >= 0x20000000 then
				self.flippedDiagonally = true
				self.gid = self.gid - 0x20000000
			end
			
			local tileSetIndex = 1
			local tileSet = self.map:getTileSet(tileSetIndex)
			
			if(tileSet) then
				-- If the GID is higher then the amount of tiles in this tileset then it must be in the next tileset (and so on)	
				while(self.gid + 1 > tileSet.tileCount + tileSet.firstgid) do
					tileSetIndex = tileSetIndex + 1
					tileSet = self.map.tileSets[tileSetIndex]
				end
			end
		
			if(tileSet) then
				
				self.tileSet = tileSet
				
				-- Get all the properties this tile should have from the tilese
				local properties = tileSet:getPropertiesForTile(self.gid)
				
				for i=1, #properties, 1 do
				
					-- Read in the Config file data if it has one, otherwise it is a normal property
					if properties[i].name == "configFile" then
						utils:readInConfigFile(properties[i].value, self)
					else	
						self:addProperty(properties[i])	
					end	
									
				end

				-- Is this tile animated?
				if(self.IsAnimated) then
				
					if self.dataFile and self.spriteSheet then
					
						self.spriteData = require( self.dataFile ).getSpriteSheetData()
						
						if self.spriteData then
						
							self.spriteSheet = newSpriteSheetFromData( self.spriteSheet, self.spriteData )
	
							self.spriteSet = newSpriteSet( self.spriteSheet, 1, #self.spriteData.frames )
	
							sprite.add( self.spriteSet, self.dataFile, 1, #self.spriteData.frames, self.time or 1000, self.loopCount ) 
							
							self.sprite = newSprite( self.spriteSet )
		
							self.sprite:play()
						
						end
						
						if(self.sequences) then
											
							if type(self.sequences) == "string" then
								self.sequences = utils:splitString(self.sequences, ",")
							elseif type(self.sequences) == "table" then
							end		
													
							-- Create all the sprite sequences	
							for i=1, #self.sequences, 1 do
								if(self[self.sequences[i]]) then
									newSpriteSequenceFromString(self, self.sequences[i], self[self.sequences[i]])
								end
							end
	
						end
						
					else
						
						self.startFrame = self.startFrame or (self.gid - (tileSet.firstgid) + 1)
				
						self.spriteSet = newSpriteSet(tileSet.spriteSheet, self.startFrame, (self.frameCount or (tileSet.tileCount - self.startFrame)), self.loopCount )
						self.sprite = newSprite( self.spriteSet )
							
						-- Does this tile have a set of sequences?				
						if(self.sequences) then
												
							if type(self.sequences) == "string" then
								self.sequences = utils:splitString(self.sequences, ",")
							elseif type(self.sequences) == "table" then
								
							end		
													
							-- Create all the sprite sequences	
							for i=1, #self.sequences, 1 do
								if(self[self.sequences[i]]) then
									newSpriteSequenceFromString(self, self.sequences[i], self[self.sequences[i]])
								end
							end
	
						else
			
							-- If the tile has a "frameTime" then create a single sequence allowing it to be time based, otherwise it will just be frame based.
							if self.frameTime then
								sprite.add( self.spriteSet, "DEFAULT", 1, self.frameCount, self.frameTime or 1000, self.loopCount)
								self.sprite:prepare("DEFAULT")
							end
							
							self.sprite:play()
						end
						
					end
					
				else
				
					-- Create the actual Corona sprite object
					self.sprite = newSprite(tileSet.spriteSet)

					-- Set the sprites frame to the current tile in the tileset
					self.sprite.currentFrame = self.gid - (tileSet.firstgid) + 1
				end
								
				-- Calculate and set the row position of this tile in the map
				self.row = floor((index + self.layer.width - 1) / self.layer.width)
				
				-- Calculate and set the column position of this tile in the map
				self.column = index - (self.row - 1) * self.layer.width
				
				self.sprite.xReference = self.xReference or self.sprite.xReference
				self.sprite.yReference = self.yReference or self.sprite.yReference
				
				if(self.map.orientation == "orthogonal" ) then
	
					-- Place this tile in the right X position
					--self.sprite.x = ( ( self.column - 1) * self.map.tilewidth ) + self.sprite.width  * 0.5
					--self.sprite.x = ( ( self.column - (1 / display.contentScaleX) ) * self.map.tilewidth ) + self.sprite.width  * 0.5                    

					if self.tileSet.usingHDSource then
						self.sprite.x = ( ( self.column - (1 / display.contentScaleX)) * self.map.tilewidth ) + self.sprite.width  * 0.5
					else
						self.sprite.x = ( ( self.column - 1 ) * self.map.tilewidth ) + self.sprite.width  * 0.5
					end 

					-- Place this tile in the right Y position
					self.sprite.y = ( self.row * self.map.tileheight ) - self.sprite.height * 0.5
					
				elseif(self.map.orientation == "isometric") then

					-- Correct the row/column numbers
					self.column = self.column - 1
					self.row = self.row - 1
					
					-- Place this tile in the right X position
					self.sprite.x = (self.column - self.row) * (self.map.tilewidth * 0.5)

					-- Place this tile in the right Y position
					self.sprite.y = (self.column + self.row) * (self.map.tileheight * 0.5)
			
				end
				
				-- Apply sprite properties
				self.sprite.alpha = self.alpha or 1
				self.sprite.isHitTestable = utils:stringToBool(self.isHitTestable) or true
				
				self.sprite.xOrigin = self.xOrigin or self.sprite.xOrigin
				self.sprite.yOrigin = self.yOrigin or self.sprite.yOrigin
			
				self.sprite.rotation = self.rotation or 0
				self.sprite.x = (self.x or self.sprite.x) + (self.xOffset or 0) 
				self.sprite.y = (self.y or self.sprite.y) + (self.yOffset or 0)
				
				-- Adjust the scale and position for Retina display
				if display.contentScaleX == 0.5 and self.tileSet.usingHDSource == true then
			
					-- Scale the sprite back down to 0.5			
					self.sprite.xScale = self.xScale or 0.5
					self.sprite.yScale = self.yScale or 0.5
				
					-- Readjust the position
					self.sprite.x = self.sprite.x + self.sprite.width / 4
					self.sprite.y = self.sprite.y + self.sprite.height / 4
					
				else
					self.sprite.xScale = self.xScale or 1
					self.sprite.yScale = self.yScale or 1	
				end
				
				if _G.limeScreenCullingEnabled then
					self.sprite.isVisible = false
				else
					self.sprite.isVisible = utils:stringToBool(self.isVisible) or true
				end
				
				if self.xTileOffset then
					self.sprite.x = self.sprite.x + (self.xTileOffset * self.sprite.width) 
				end
				
				if self.yTileOffset then
					self.sprite.y = self.sprite.y + (self.yTileOffset * self.sprite.height)
				end
				
				-- Correctly add the tile to the tileGrid of the layer
				if(self.gid ~= 0) then
				
					if(not self.layer.tileGrid) then
						self.layer.tileGrid = {}
					end
					
					if self.column and self.row then
					
						if(not self.layer.tileGrid[self.column]) then
							self.layer.tileGrid[self.column] = {}
						end	
					
						if(not self.layer.tileGrid[self.column][self.row]) then
							self.layer.tileGrid[self.column][self.row] = {}
						end
	
						self.layer.tileGrid[self.column][self.row] = self
					end
					
				end
				
				-- Add the sprite to the layer group
				if self.layer.group then
					self.layer.group:insert(self.sprite)
				end
				
				-- Make sure these are fired after the tile is created so that there is a sprite object
				for key, value in pairs(self.properties) do
					self.map:firePropertyListener(self.properties[key], "tile", self)	
				end
				
				-- Convert HasBody to a boolean value allowing explicit true/false setting. Blank is considered true as to not break old code.
				if self.HasBody then
	
					if self.HasBody == "" then
						self.HasBody = "true"
					end
					
					self.HasBody = utils:stringToBool( self.HasBody )
				end
				
				self.sprite.isVisible = false
				
				if self.ignoreCulling == true then
					self.sprite.isVisible = true
				end
				
				-- Tint the sprite if required
				utils:setSpriteFillColor( self.sprite, self.fillColor )
				
				-- Flip the sprite horizontally if required
				if self.flippedHorizontally then
					self.sprite.xScale = -self.sprite.xScale
				end
				
				-- Flip the sprite vertically if required
				if self.flippedVertically then
					self.sprite.yScale = -self.sprite.yScale
				end
				
			end
		end
	end
	
end

--- Builds the physical representation of the Tile.
function Tile:build()
	
	local visual = self:getVisual()
	
	if(self.HasBody and visual) then
	
		visual.owner = self
		
		local body = visual
		
		if(self.shape) then	
	
			if type(self.shape) == "table" then
			
			elseif type(self.shape) == "string" or type(self.shape) == "number" then
				
				local jsonVersion = "[0,-37,37,-10,23,34,-23,34,-37,-10]"			
				print("Lime-Banana: Using strings to define the shapes of Tile bodies is currently depreceated as Lime 3.0 and beyond is moving over to Json values for properties. Instead, define it similar to this - " .. jsonVersion)
				
				--[[
				local splitShape = utils:splitString(self.shape, ",")
				
				if #splitShape > 1 then
	   
					local shape = {}
					
					for i = 1, #splitShape, 1 do
						shape[#shape + 1] = tonumber(splitShape[i])
					end
				   
					self.shape = shape
					
				end
				
				--]]
			end		
		end
		
		-- Now that tiles can be set at runtime it is important to make sure physics is loaded as it may not have been at load time
		if not physics then
			require("physics")
			physics.start()
		end
		
		self.isSensor = utils:stringToBool(self.isSensor)
		
		-- If using Retina, half the tile size so the physics body is correct
		if self.tileSet.tileXScale ~= 1 or self.tileSet.tileXScale ~= 1 then
			
			visual.width = visual.width / self.tileSet.tileXScale
			visual.height = visual.height / self.tileSet.tileYScale

		end

		utils:addCollisionFilterToBody( self )
		
		physics.addBody( body, self ) 
		
		utils:applyPhysicalParametersToBody(body, self)
		
		utils:addPropertiesToBody(body, self)
		
		-- If using Retina, set the size back to original
		if  self.tileSet.tileXScale ~= 1 or self.tileSet.tileXScale ~= 1 then	
		
			visual.width = visual.width * self.tileSet.tileXScale
			visual.height = visual.height * self.tileSet.tileYScale

		end
	end
	
end

--- Completely removes all visual and physical objects associated with the Tile.
function Tile:destroy()

	-- Destroy the properties
 	if self.properties then
 		self.properties = nil
    end
 
 	-- Destroy the visual object
 	
 	local visual = self:getVisual()
 	
	if visual and visual["removeSelf"] then
		visual:removeSelf()
	end
	
	visual = nil
	
end

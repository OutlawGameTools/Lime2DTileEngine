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
-- File name: lime-tileSet.lua
--
----------------------------------------------------------------------------------------------------
----									REQUIRED MODULES										----
----------------------------------------------------------------------------------------------------

local sprite = require "sprite"

----------------------------------------------------------------------------------------------------
----									CLASS METATABLE											----
----------------------------------------------------------------------------------------------------

TileSet = {}
TileSet_mt = { __index = TileSet }

----------------------------------------------------------------------------------------------------
----									CLASS VARIABLES											----
----------------------------------------------------------------------------------------------------

TileSet.version = 3.4

----------------------------------------------------------------------------------------------------
----									LOCALISED VARIABLES										----
----------------------------------------------------------------------------------------------------

local newSprite = sprite.newSprite

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

--- Create a new instance of a TileSet object.
-- @param data The XML data.
-- @param map The current Map object.
-- @param firstgid The first GID of the tileset. Optional and only needed if different from the TMX data. Used for custom maps.
-- @param rootDir The root dir of the tileset image. Optional.
-- @return The newly created TileSet instance.
function TileSet:new(data, map, firstgid, rootDir)

    local self = {}    -- the new instance
    
    setmetatable( self, TileSet_mt ) -- all instances share the same metatable
    
    self.properties = {}
    self.tileProperties = {}
    self.map = map
    
    -- Extract tileset header info: name, tileheight, tilewidth, firstgid
	for key, value in pairs(data['Attributes']) do 
		self:setProperty(key, value)		
	end
	
	-- Allow overriding of the firstgid
	self.firstgid = utils:convertStringToNumberSafely(firstgid or self.firstgid)
	
	local node = nil
	local attributes = nil
	
	-- Extract the second set of data, currently the image to use	
	for i=1, #data["ChildNodes"], 1 do
		
		node = data["ChildNodes"][i]
		
		if node.Name == "image" then -- TileSet Source
			for key, value in pairs(node['Attributes']) do 
				self:setProperty(key, value)
			end
		elseif node.Name == "tile" then -- Tile Property
			
			local tileID = node['Attributes'].id + self.firstgid -- Add this on to ensure the correct GIDs are used
			
			-- Loop through all the child nodes
			for j=1, #node["ChildNodes"], 1 do
			
				if node["ChildNodes"][j].Name == "properties" then
				
					-- Loop through all the child nodes
					for k=1, #node["ChildNodes"][j]["ChildNodes"], 1 do
						
						if node["ChildNodes"][j]["ChildNodes"][k].Name == "property" then
			
							attributes = node["ChildNodes"][j]["ChildNodes"][k]["Attributes"]
							
							tileID = tonumber(tileID)
								
							--  Make sure we have a seperate table for each TileID
							if(not self.tileProperties[tileID]) then
								self.tileProperties[tileID] = {}
							end

							self.tileProperties[tileID][#self.tileProperties[tileID] + 1] = Property:new(attributes.name, attributes.value)
								
						end										
					end		
				end
			end	
		end	
	end
	
	if self.trans then -- IN PREPARATION FOR THE NEW COLOUR MASKING FEATURES
		self.maskColour = utils:hexToRGB(self.trans)
	end

	if(self.source) then

		local filename = utils:getFilenameFromPath(self.source)
		 		 
		if string.find( self.source, "../" ) then
			print("Lime-Lychee: Absoulute paths are not supported for TileSets. You may want to edit your map in a text editor to fix this." )
			return
		end
		
		self.rootDir = rootDir or "" -- "maps/"
		
		local extension = utils:getExtensionFromFilename( filename )

	   	if(extension == "tsx") then -- Using an external tileset
			
			local path = system.pathForFile(self.source, system.ResourceDirectory)

			if(path) then			
			
				local tilesetContents = utils:readInFileContents(path)

				local xml = XmlParser:ParseXmlFile(path)
				
				local tileSet = TileSet:new(xml, self.map, self.firstgid, rootDir)

				if(tileSet) then
				
					if(lime.isDebugModeEnabled()) then
						print("Lime-Lychee: Loaded External Tileset - " .. utils:getFilenameFromPath(path))
					end
					
					return tileSet
				end

			end
			
			return
		else
			
			-- Amount to scale the tile size by when creating the sprite sheet
			self.tileXScale = 1
			self.tileYScale = 1
			
			-- Check to see if on a Retina display
			if display.contentScaleX == 0.5 then
				
				self.retinaSource = utils:addSuffixToFileName(self.source, "@2x")

				-- Check if there is a HD version of the tileset image
				local path = system.pathForFile(self.rootDir .. self.retinaSource, system.ResourceDirectory)
				
				if(lime.isDebugModeEnabled() and not path) then
					print("Lime-Lychee: If you aren't intending to use Retina spritesheets then you can ignore the previous warning.")
				end
				
				if path then
				
					-- Mark the tileset as HD
					self.usingHDSource = true
					
					-- Adjust the source value
					self.source = self.retinaSource
				
					-- Adjust the scale amount for the tile size
					self.tileXScale = 2
					self.tileYScale = 2
	
				end

				
			end

			self.spriteSheet = sprite.newSpriteSheet(self.rootDir .. self.source, system.ResourceDirectory, self.tilewidth * self.tileXScale, self.tileheight * self.tileYScale)

			self.tileCount = self.spriteSheet.frameCount

			-- Create the actual spriteset object
			self.spriteSet = sprite.newSpriteSet(self.spriteSheet, 1, self.tileCount)
		
		end

	end
	
    return self
    
end

--- Sets the value of a Property of the TileSet. 
-- Will create a new Property if none found.
-- @param name The name of the Property.
-- @param value The new value.
function TileSet:setProperty(name, value)
		
	local property = self:getProperty(name)
	
	if property then
		return property:setValue(value)
	else
		self:addProperty(Property:new(name, value))
	end
	
	self[name] = self:getPropertyValue(name)
end

---Gets a Property of the TileSet.
-- @param name The name of the Property.
-- @return The Property. nil if no Property found.
function TileSet:getProperty(name)
	return self.properties[name]
end

---Gets the value of a Property of the TileSet.
-- @param name The name of the Property.
-- @return The Property value. nil if no Property found.
function TileSet:getPropertyValue(name)
	
	local property = self:getProperty(name)
	
	if property then
		return property:getValue()
	end
	
end

--- Gets a list of all Properties of the TileSet.
-- @return The list of Properties.
function TileSet:getProperties()
	return self.properties
end

--- Gets a count of how many properties the TileSet has.
-- @return The Property count.
function TileSet:getPropertyCount()

	local count = 0
	
	for _k, _v in pairs(self.properties) do
		count = count + 1
	end

	return count
end

--- Checks whether the TileSet has a certain Property.
-- @param name The name of the property to check for.
-- @return True if the TileSet has the Property, false if not.
function TileSet:hasProperty(name)
	return self:getProperty(name) ~= nil
end

---Adds a Property to the TileSet. 
-- @param property The Property to add.
-- @return The added Property.
function TileSet:addProperty(property)
	self.properties[property:getName()] = property
	
	self[property:getName()] = property:getValue()
	
	return property
end

--- Removes a Property from the TileSet. 
-- @param name The name of the Property to remove.
function TileSet:removeProperty(name)
	self.properties[name] = nil
end

--- Creates a new sprite instance from a specific tile in the tileset.
-- @param gid The gid of the tile.
-- @usage Originally suggested by draconar - http://developer.anscamobile.com/forum/2011/02/12/using-tile-internal-tileset-change-objects-image
function TileSet:createSprite(gid)

	-- Create the sprite instance
	local sprite = newSprite(self.spriteSet)
 
	-- Set the sprites frame to the current tile in the tileset
	sprite.currentFrame = gid - (self.firstgid) + 1
	
	return sprite
end

--- Gets a list of Properties on a Tile.
-- @param id The id of the Tile.
-- @return A table with a list of properties for the tile or an empty table.
function TileSet:getPropertiesForTile(id)
	return self.tileProperties[id] or {}
end

--- Completely removes the TileSet.
function TileSet:destroy()
	
	if self.spriteSheet and self.spriteSheet[ "dispose" ] then
		self.spriteSheet:dispose()
	end
	
	self.spriteSet = nil
	self.spriteSheet = nil

end

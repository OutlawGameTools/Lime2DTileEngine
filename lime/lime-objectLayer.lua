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
-- File name: lime-objectLayer.lua
--
----------------------------------------------------------------------------------------------------
----									REQUIRED MODULES										----
----------------------------------------------------------------------------------------------------

-- jij 20130616 Calls to utils:hexToRGB are throwing errors with that line in 
--#TODO Fix error in that file or see whether this is even necessary.
--local utils = require("lime.lime-utils")

----------------------------------------------------------------------------------------------------
----									CLASS METATABLE											----
----------------------------------------------------------------------------------------------------

ObjectLayer = {}
ObjectLayer_mt = { __index = ObjectLayer }

----------------------------------------------------------------------------------------------------
----									CLASS VARIABLES											----
----------------------------------------------------------------------------------------------------

ObjectLayer.version = 3.4

----------------------------------------------------------------------------------------------------
----									LOCALISED VARIABLES										----
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

--- Create a new instance of an ObjectLayer object.
-- @param data The XML data.
-- @param map The current Map object.
-- @return The newly created object layer.
function ObjectLayer:new(data, map)

    local self = {} -- the new instance
    
    setmetatable( self, ObjectLayer_mt ) -- all instances share the same metatable
    
	self.properties = {}
	self.objects = {}
	self.map = map
    
	-- Extract header info, name, width, height	
	for key, value in pairs(data["Attributes"]) do
		self:setProperty(key, value)
	end
	
	local node = nil
	local attributes = nil
	
	-- Loop through all the child nodes
	for i=1, #data["ChildNodes"], 1 do
	
		node = data["ChildNodes"][i]

		if node.Name == "object" then
			self.objects[#self.objects + 1] = Object:new(node, self.map, self)
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

--- Sets the value of a Property of the ObjectLayer. 
-- Will create a new Property if none found.
-- @param name The name of the Property.
-- @param value The new value.
function ObjectLayer:setProperty(name, value)
		
	local property = self:getProperty(name)
	
	if property then
		return property:setValue(value)
	else
		self:addProperty(Property:new(name, value))
	end
	
	self[name] = self:getPropertyValue(name)
end

--- Gets a Property of the ObjectLayer.
-- @param name The name of the Property.
-- @return The Property. nil if no Property found.
function ObjectLayer:getProperty(name)
	return self.properties[name]
end

--- Gets the value of a Property of the ObjectLayer.
-- @param name The name of the Property.
-- @return The Property value. nil if no Property found.
function ObjectLayer:getPropertyValue(name)
	
	local property = self:getProperty(name)
	
	if property then
		return property:getValue()
	end
	
end

--- Gets a list of all Properties of the ObjectLayer.
-- @return The list of Properties.
function ObjectLayer:getProperties()
	return self.properties
end

--- Gets a count of how many properties the Object Layer has.
-- @return The Property count.
function ObjectLayer:getPropertyCount()

	local count = 0
	
	for _k, _v in pairs(self.properties) do
		count = count + 1
	end

	return count
end

--- Checks whether the ObjectLayer has a certain Property.
-- @param name The name of the property to check for.
-- @return True if the ObjectLayer has the Property, false if not.
function ObjectLayer:hasProperty(name)
	return self:getProperty(name) ~= nil
end

--- Adds a Property to the ObjectLayer. 
-- @param property The Property to add.
-- @return The added Property.
function ObjectLayer:addProperty(property)
	self.properties[property:getName()] = property
	
	self[property:getName()] = property:getValue()
	
	return property
end

--- Removes a Property from the ObjectLayer. 
-- @param name The name of the Property to remove.
function ObjectLayer:removeProperty(name)
	self.properties[name] = nil
end

--- Get an object by its name. 
-- @param name The name of the Object to get.
-- @param objectType The type of the Object to get. Optional.
-- @return The found Object. nil if none found.
function ObjectLayer:getObject(name, objectType)

	for i=1, #self.objects, 1 do
		
		if(name) then
			
			local object = nil
			
			if(self.objects[i].name == name) then
				
				object = self.objects[i]
				
				if(objectType) then -- Type specified to check that it is equal
					if(object.type == objectType) then
						return object
					end
				
				else -- No type specified so just return the object
					return object
				end
				
			end
			
		end
	end
	
	return nil
end
	
--- Get a list of objects by their name. 
-- @param name The name of the Objects to get.
-- @param objectType The type of the Objects to get. Optional.
-- @return A list of the found Objects. Empty if none found.
function ObjectLayer:getObjects(name, objectType)
	
	local objects = {}
		
	for i=1, #self.objects, 1 do
		
		if(name) then
			
			local object = nil
			
			if(self.objects[i].name == name) then
				
				object = self.objects[i]
				
				if(objectType) then -- Type specified to check that it is equal
					if(object.type == objectType) then
						objects[#objects + 1] = self.objects[i]
					end
				
				else -- No type specified so just return the object
					objects[#objects + 1] = self.objects[i]
				end
				
			end
			
		end
	end
	
	return objects
end

--- Gets a list of Objects on this ObjectLayer that have a specified property. 
-- @param name The name of the Property to look for.
-- @return A list of found Objects. Empty if none found.
function ObjectLayer:getObjectsWithProperty(name)

	local objects = {}
	
	for i = 1, #self.objects, 1 do
		if self.objects[i]:hasProperty(name) then
			objects[#objects + 1] = self.objects[i]
		end
	end

	return objects
end

--- Gets a list of Objects on this ObjectLayer that have a certain name. 
-- @param name The name of the Object to look for.
-- @return A list of found Objects. Empty if none found.
function ObjectLayer:getObjectsWithName(name)

	local objects = {}
	
	for i = 1, #self.objects, 1 do
		if self.objects[i].name == name then
			objects[#objects + 1] = self.objects[i]
		end
	end

	return objects
end

--- Gets a list of Objects on this ObjectLayer that have a certain type. 
-- @param objectType - The type of the Object to look for.
-- @return A list of found Objects. Empty if none found.
function ObjectLayer:getObjectsWithType(objectType)

	local objects = {}
	
	for i = 1, #self.objects, 1 do
		if self.objects[i].type == objectType then
			objects[#objects + 1] = self.objects[i]
		end
	end

	return objects
end

--- Shows the ObjectLayer.
function ObjectLayer:show()
	for i=1, #self.objects, 1 do	
		self.objects[i]:show()	
	end	
	
	local visual = self:getVisual()
	
	if visual then
		visual.isVisible = false
	end
	
end

--- Hides the ObjectLayer.
function ObjectLayer:hide()
	for i=1, #self.tiles, 1 do
		self.objects[i]:hide()
	end
	
	local visual = self:getVisual()
	
	if visual then
		visual.isVisible = false
	end
	
end

--- Gets the ObjectLayers visual.
function ObjectLayer:getVisual()
	return self.group
end

--- Moves the ObjectLayer.
-- @param x The amount to move the ObjectLayer along the X axis.
-- @param y The amount to move the ObjectLayer along the Y axis.
function ObjectLayer:move(x, y)
	utils:moveObject(self.group, x, y)
	
	for i=1, #self.objects, 1 do
		self.objects[i]:move(x, y)
	end
end

--- Drags the ObjectLayer.
-- @param event The Touch event.
function ObjectLayer:drag(event)
	utils:dragObject(self.group, event)
	
	for i=1, #self.objects, 1 do
		self.objects[i]:drag(x, y)
	end	
end

--- Sets the position of the ObjectLayer.
-- @param x The new X position of the ObjectLayer.
-- @param y The new Y position of the ObjectLayer.
-- @param force If true then the layer will not be clamped or use the viewpoint calculator. Default is false. Optional.
function ObjectLayer:setPosition(x, y, force)

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

--- Sets the rotation of the ObjectLayer.
-- @param The new rotation.
function ObjectLayer:setRotation(angle)
	for i=1, #self.objects, 1 do 
		self.objects[i]:setRotation(angle)
	end
end

--- Rotates the ObjectLayer.
-- @param The angle to rotate by.
function ObjectLayer:rotate(angle)
	for i=1, #self.objects, 1 do 
		self.objects[i]:rotate(angle)
	end
end

--- Adds a displayObject to the layer. 
-- @param displayObject The displayObject to add.
-- @return The added displayObject.
function ObjectLayer:addObject(displayObject)
	return utils:addObjectToGroup(displayObject, self.group)
end

--- Shows all debug images on the ObjectLayer.
function ObjectLayer:showDebugImages()
	
	for i=1, #self.objects, 1 do 
		self.objects[i]:showDebugImage()
	end
end

--- Hides all debug images on the ObjectLayer.
function ObjectLayer:hideDebugImages()

	for i=1, #self.objects, 1 do 
		self.objects[i]:hideDebugImage()
	end
end

--- Toggles the visibility of all debug images on the ObjectLayer.
function ObjectLayer:toggleDebugImagesVisibility()
	
	for i=1, #self.objects, 1 do 
		self.objects[i]:toggleDebugImageVisibility()
	end
	
end	

--- Destroy an object by its reference.
-- @param object The Object reference of the Object to destroy.
function ObjectLayer:destroyObject(object)
	
	for i=1, #self.objects, 1 do
	
	   if( self.objects[i] == object ) then
		   table.remove( self.objects, i )
		   object:destroy()
		   object = nil
	   end

	end

end

--- Creates the visual debug representation of the ObjectLayer.
function ObjectLayer:create()
	
	if(lime.isDebugModeEnabled()) then
		print("Lime-Coconut: Creating object layer - " .. self.name)
	end
	
	if not self.map.world then
		self.map.world = display.newGroup()
	end

	-- Display group used for debug visuals and physics bodies
	if not self.group then
		self.group = display.newGroup()
	end
	
	local object = nil
	local listeners = nil
		
	local hexValue = nil
	
	if self.color then
		local strippedHex = utils:splitString(self.color, "#")

		if strippedHex[2] then
			hexValue = strippedHex[2]
		end					
	end
	
	self.color = utils:hexToRGB(hexValue or "A0A0A4")
	
	for j=1, #self.objects, 1 do
		self.objects[j]:create(self)				
	end
	
	self.map.world:insert(self.group)
	
	if self.visible then
		if self.visible == "0" then
			self.group.isVisible = false
		end
	end
	
	if self.opacity then
		self.group.alpha = self.opacity 
	end
	
	for key, value in pairs(self.properties) do
		self.map:firePropertyListener(self.properties[key], "objectLayer", self)
	end	
	
	self.visible = ( self.visible == 1 or self.visible == nil )
	
	self.group.isVisible = self.visible
	
end

--- Builds the physical representation of the ObjectLayer.
function ObjectLayer:build()

	if(lime.isDebugModeEnabled()) then
		print("Lime-Banana: Building Object Layer - " .. self.name)
	end	
	
	if not self.map.world then
		self.map.world = display.newGroup()
	end

	-- Display group used for debug visuals and physics bodies
	if not self.group then
		self.group = display.newGroup()
	end	
	
	for i=1, #self.objects, 1 do
		
		if( self.objects[i].type == "Body" or self.objects[i]:hasProperty("HasBody") ) then
			self.objects[i]:build(self)
		end
		
	end
	
	self.map.world:insert(self.group)
	
end

--- Completely removes all visual and physical objects associated with the TileLayer.
function ObjectLayer:destroy()

	if self.group and self.objects then
	
		for i=1, #self.objects, 1 do	
			self.objects[i]:destroy()
		end
		
		self.objects = nil
		
		if self.group and self.group["removeSelf"] then
			self.group:removeSelf()
		end
		
		self.group = nil
		
	end

end

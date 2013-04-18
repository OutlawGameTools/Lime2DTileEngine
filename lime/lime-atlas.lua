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
-- File name: lime-atlas.lua
--
----------------------------------------------------------------------------------------------------
----									REQUIRED MODULES										----
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
----									CLASS METATABLE											----
----------------------------------------------------------------------------------------------------

Atlas = {}
Atlas_mt = { __index = Atlas }

----------------------------------------------------------------------------------------------------
----									CLASS VARIABLES											----
----------------------------------------------------------------------------------------------------

Atlas.version = 3.4

----------------------------------------------------------------------------------------------------
----									LOCALISED VARIABLES										----
----------------------------------------------------------------------------------------------------

local abs = math.abs

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

--- Create a new instance of an Atlas object.
-- @return The newly created Atlas instance.
function Atlas:new()

    local self = {}    -- the new instance
    
    setmetatable( self, Atlas_mt ) -- all instances share the same metatable
    
    self.maps = {}
    self.mapGrid = nil
    
    self.globe = display.newGroup()
	
	lime.disableScreenCulling()

    return self
    
end

--- Adds an already created map to the Atlas.
-- @params map The Map object to add.
-- @params positionOffset The grid position offset for the Map relative to the previous map. Row and Column. Optional.
function Atlas:addMap(map, positionOffset)
	
	local addMapToGrid = function(map, column, row)
	
		if not self.mapGrid then
			self.mapGrid = {}
		end
		
		if not self.mapGrid[column] then
			 self.mapGrid[column] = {}
		end
		
		if not self.mapGrid[column][row] then
			 self.mapGrid[column][row] = {}
		end
		
		self.mapGrid[column][row] = map
		
		self.maps[#self.maps + 1] = map
	end
	
	if map then
		
		-- Create the bounds object used for clamping
		if not self.bounds then
		
			-- Set it to the first maps bounds
			self.bounds = map.bounds
			
			-- Store off the bounds as the previous ones
			self.previousBounds = self.bounds
		end
		
		-- First map will be passed in with a nil offset so set it to 0,0. This also allows for overlapping maps easily.
		if not positionOffset then
			positionOffset = { column = 0, row = 0 }
		end
		
		-- Store off the previous grid position
		if not self.previousGridPosition then
			self.previousGridPosition = { column = 1, row = 1 }
		else
			self.previousGridPosition = positionOffset
		end
		
		-- Calculate the new column and row based on the offset
		local column = self.previousGridPosition.column + positionOffset.column
		local row = self.previousGridPosition.row + positionOffset.row + 1
		
		-- Add the map to the grid
		addMapToGrid(map, column, row)
		
		-- Set the position of the map
		if self.previousMap then
			map.world.x = self.previousMap.world.x + ( self.previousMap.world.width * positionOffset.column )
			map.world.y = self.previousMap.world.y + ( self.previousMap.world.height * positionOffset.row )
		end
		
		-- Store off the previous map
		self.previousMap = map
		
		-- Insert the map to the globe
		self.globe:insert(map.world)
		
		-- Adjust the X position of the bounds to the lowest required
		if map.world.x < self.previousBounds.x then
			self.bounds.x = abs(map.world.x)
		end
	
		-- Adjust the Y position of the bounds to the lowest required
		if map.world.y < self.previousBounds.y then
			self.bounds.y = map.world.y
		end
		
		-- Addjust the width and height of the bounds
		self.bounds.width = self.globe.width
		self.bounds.height = self.globe.height 

		-- Store off the bounds
		self.previousBounds = self.bounds
	end
	
end

--- Sets the position of the Atlas.
-- @param x The new X position of the Atlas.
-- @param y The new Y position of the Atlas.
function Atlas:setPosition(x, y)

	if self.globe then
		local viewPoint = utils:calculateViewpoint(self.globe, x, y)

		self.globe.x = utils:round(viewPoint.x)
		self.globe.y = utils:round(viewPoint.y)

		self.globe.x, self.globe.y = utils:clampPosition(self.globe.x, self.globe.y, self.bounds)
		
	end	
	
end

--- @description Gets the position of the Atlas.
-- @return The X position of the Map.
-- @return The Y position of the Map.
function Atlas:getPosition()

	if self.globe then
		return self.globe.x, self.globe.y
	end

end

--- Drags the Atlas.
-- @param event The Touch event.
function Atlas:drag(event)

	utils:dragObject(self.globe, event)
		
	self.globe.x, self.globe.y = utils:clampPosition(self.globe.x, self.globe.y, self.bounds)

end

--- Moves the Atlas.
-- @param x The amount to move the Atlas along the X axis.
-- @param y The amount to move the Atlas along the Y axis.
function Atlas:move(x, y)

	utils:moveObject(self.globe, x, y)
	
	self.globe.x, self.globe.y = utils:clampPosition(self.globe.x, self.globe.y, self.bounds)

end

--- Slides the Atlas to a new position.
-- @param x The new X position of the Atlas.
-- @param y The new Y position of the Atlas.
-- @param slideTime The time it will take to slide the Atlas to the new position.
function Atlas:slideToPosition(x, y, slideTime)
	
	local onTransitionUpdate = function(event)
		--if self.ParallaxEnabled then
		--	self:setParallaxPosition{x = self.world.x, y = self.world.y }
		--end
	end
	
	local onSlideComplete = function(event)
		Runtime:removeEventListener("enterFrame", onTransitionUpdate)
	end
	
	local viewPoint = utils:calculateViewpoint(self.globe, x, y)
		
	if(self.slideTransition) then
		transition.cancel(self.slideTransition)
		Runtime:removeEventListener("enterFrame", onTransitionUpdate)
	end
	
	local clampedX, clampedY = x, y
	
	--if self.orientation ~= "isometric" then
		-- Clamp the position first to ensure that it is not outside the bounds
		clampedX, clampedY = utils:clampPosition(utils:round(viewPoint.x, 0.5), utils:round(viewPoint.y, 0.5), self.bounds)
	--end
	
	
	Runtime:addEventListener("enterFrame", onTransitionUpdate)
	
	self.slideTransition = transition.to( self.globe, {time=slideTime or 1000, x=clampedX, y=clampedY, onComplete=onSlideComplete})
end

--- Fades the Atlas to a new position.
-- @param x The new X position of the Atlas.
-- @param y The new Y position of the Atlas.
-- @param fadeTime The time it will take to fade the Atlas out or in. Optional, default is 1000.
-- @param moveDelay The time inbetween both fades. Optional, default is 0.
function Atlas:fadeToPosition(x, y, fadeTime, moveDelay)
	
	local beginFadeIn = function(event)
	
		if self.moveDelayTimer then
			timer.cancel(self.moveDelayTimer)
		end
		
		transition.to(self.globe, {alpha = 1, time=fadeTime or 1000})
	end
	
	local onFadeOut = function(event)
		self:setPosition(x, y)
		
		if moveDelay then
			self.moveDelayTimer = timer.performWithDelay(moveDelay, beginFadeIn, 1)
		else
			beginFadeIn()
		end
	end

	if(self.fadeTransition) then
		transition.cancel(self.fadeTransition)
	end
	
	self.fadeTransition = transition.to(self.globe, {alpha = 0, time=fadeTime or 1000, onComplete=onFadeOut})
end

--- Gets the map at a certain position.
-- @param position The grid position of the Map to get. Row and Column.
-- @return The found map. nil if none found.
function Atlas:getMap(position)

	if position then
		
		if position.column and position.row then
	
			return self.mapGrid[position.column][position.row]
			
		end
	end

end

--- Jumps the Atlas to a new position.
-- @param position The grid position of the Map to jump to. Row and Column.
function Atlas:jumpToMap(position)

	local map = self:getMap(position)
	
	if map then
	
		local x, y = map:getPosition()
		
		x = x + display.contentCenterX
		y = y + display.contentCenterY
		
		self:setPosition(x, y)
	end
	
end

--- Fades the Atlas to a new position.
-- @param position The grid position of the Map to fade to. Row and Column.
-- @param fadeTime The time it will take to fade the Atlas out or in. Optional, default is 1000.
-- @param moveDelay The time inbetween both fades. Optional, default is 0.
function Atlas:fadeToMap(position, fadeTime, moveDelay)

	local map = self:getMap(position)
	
	if map then

		local x, y = map:getPosition()
		
		x = x + display.contentCenterX
		y = y + display.contentCenterY
		
		self:fadeToPosition(x, y, fadeTime, moveDelay)
		
	end
	
end

--- Slides the Atlas to a new position.
-- @param position The grid position of the Map to slide to. Row and Column.
-- @param slideTime The time it will take to slide the Atlas to the new position.
function Atlas:slideToMap(position, slideTime)

	local map = self:getMap(position)
	
	if map then

		local x, y = map:getPosition()
		
		x = x + display.contentCenterX
		y = y + display.contentCenterY
		
		self:slideToPosition(x, y, slideTime)
		
	end

end

--- Updates the Atlas.
-- @params event The enterFrame event object.
function Atlas:update(event)
	
	for i = 1, #self.maps, 1 do
		self.maps[i]:update(event)
	end
	
end

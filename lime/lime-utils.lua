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
-- File name: lime-utils.lua
--
--- A list of utility functions provided as part of Lime.
----------------------------------------------------------------------------------------------------

module(..., package.seeall)

----------------------------------------------------------------------------------------------------
----									REQUIRED MODULES										----
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
----									CLASS METATABLE											----
----------------------------------------------------------------------------------------------------

Utils = {}
Utils_mt = { __index = Utils }

----------------------------------------------------------------------------------------------------
----									MODULE VARIABLES										----
----------------------------------------------------------------------------------------------------

version = 3.4

----------------------------------------------------------------------------------------------------
----									LOCALISED VARIABLES										----
----------------------------------------------------------------------------------------------------

local floor = math.floor
local abs = math.abs
local ceil = math.ceil
local atan = math.atan
local rad = math.rad
local deg = math.deg
local sqrt = math.sqrt
local pi = math.pi
local twoPi = pi * 2

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

function Utils:new()
	
	local self = {}
    
    setmetatable( self, Utils_mt )
    
    return self

end

--[[

	-- ORIGINAL UN-GRAHAMISED FUNCTIONS --
	
function tileIndexFromPos(x, y, posX, posY, tileWidth)
 posX = posX or 0
 posY = posY or 0
 local index = {x,y}
 
 index.x = ( (2 * y) + x - posX - posY) / 2
 index.y = ( posX - x + (2 * y) - posY) / 2
 
 index.x = math.floor( (index.x / tileWidth))
 index.y = math.floor( (index.y / tileWidth))

 return index
end

function posFromIndex(i, j, posX, posY, tileWidth)
 posX = posX or 0
 posY = posY or 0
 local posOrtho = {x,y}
 
 posOrtho.x = tileWidth * i
 posOrtho.y = tileWidth * j
 
 local posIso = {x = posX,y = posY}
 
 posIso.x = posIso.x + ( posOrtho.x - posOrtho.y )
 posIso.y = posIso.y + (( posOrtho.y + posOrtho.y ) / 2)
 
 posIso.x = posIso.x + 0.1
 posIso.y = posIso.y + 0.1
 
 return posIso
end

--]]

---Converts an isometric position into a world position.
-- @param map The current Map.
-- @param position The isometric position.
-- @returns The world position.
function Utils:isometricToWorldPosition(map, position)

	local _map = map
	local _position = position
	
	_position = _position or { x = 0, y = 0 }
	
	_position.x = _position.x or 0
	_position.y = _position.y or 0
	
	local _height = _map.header.height
	local _tileWidth = _map.header.tilewidth
	local _tileHeight = _map.header.tileheight

	local _worldPosition = {}
	_worldPosition.x = ( ( _position.x - _position.y ) / _tileHeight + _height - 1) * _tileWidth / 2
	_worldPosition.y = ( _position.x + _position.y ) / 2
	
	-- I don't like this :(
	local offset = display.contentHeight > display.contentWidth and display.contentHeight or display.contentWidth

	_worldPosition.x = _worldPosition.x - ( offset - _tileHeight )
	_worldPosition.y = _worldPosition.y + _tileWidth
	
	return _worldPosition
	
end

---Converts a world position into an isometric position.
-- @param map The current Map.
-- @param position The world position.
-- @returns The isometric position.
function Utils:worldToIsometricPosition(map, position)

	local _map = map
	local _position = position
	
	_position = _position or { x = 0, y = 0 }
	
	_position.x = _position.x or 0
	_position.y = _position.y or 0
	
	local _height = _map.header.height
	local _tileWidth = _map.header.tilewidth
	local _tileHeight = _map.header.tileheight
	
	local _isoPosition = {}

	_isoPosition.x = _position.y - ( _height - 1 ) * ( _tileHeight * 0.5 ) + ( _position.x * _tileHeight ) / _tileWidth 
	_isoPosition.y = ( 2 * _position.y ) - _isoPosition.x
	
	return _isoPosition
	
end

---Converts a screen position into a grid position
-- @param map The current Map.
-- @param position The world position.
-- @returns The grid position.
function Utils:worldToGridPosition(map, position)
	
	local _map = map
	local _position = position
	local _gridPosition = {}
	
	if _map.orientation == "orthogonal" then
	
		_gridPosition.column = ceil( _position.x / _map.tilewidth )
		_gridPosition.row = ceil( _position.y / _map.tileheight )
		
	elseif _map.orientation == "isometric" then
		
		
	end
	
	return _gridPosition
	
end

---Converts a grid position into a world position.
-- @param map The current Map.
-- @param position The grid position.
-- @param offset An amount to offset the final position by. Generally used in Isometric maps. Optional.
-- @returns The world position.
function Utils:gridToWorldPosition( map, position, offset )

	local _map = map
	local _position = position
	local _worldPosition = {}
	
	local xScale, yScale = _map:getScale()
	
	if _map.orientation == "orthogonal" then
	
		_worldPosition.x = ( ( _position.column - 1 ) * ( _map.tilewidth * xScale ) ) + ( _map.tilewidth * xScale ) * 0.5
	 	_worldPosition.y = ( _position.row * ( _map.tileheight * yScale ) ) - ( _map.tileheight * yScale ) * 0.5
		
	elseif _map.orientation == "isometric" then
		
		_worldPosition.x = ( _position.column - _position.row ) * ( _map.tilewidth * 0.5 )
		_worldPosition.y = ( _position.column + _position.row ) * ( _map.tileheight * 0.5 )
		
	end
	
	if offset then
		_worldPosition.x = _worldPosition.x + ( offset.x or 0 )
		_worldPosition.y = _worldPosition.y + ( offset.y or 0 )
	end
	
	return _worldPosition
	
end
--- Converts a screen position into a tile (grid) position.
-- @param map The current Map.
-- @param position The screen position.
-- @return The grid position.
function Utils:screenToGridPosition(map, position)

	local _map = map
	local _position = position
	
	return utils:worldToGridPosition( _map, { x =_position.x - _map.world.x, y = _position.y - _map.world.y } )
end

--- Converts a screen position into a world position.
-- @param map The current Map.
-- @param position The screen position.
-- @return The world position.
function Utils:screenToWorldPosition(map, position)

	local _map = map
	local _position = position
	
	local newPosition = {}
	
	if _map.world then

		local xScale, yScale = _map:getScale()
		
		newPosition.x = _position.x + _map.world.x * -1
		newPosition.y = _position.y + _map.world.y * -1
		
		newPosition.x = newPosition.x + ( _map.world.xReference * xScale )
		newPosition.y = newPosition.y + ( _map.world.yReference * xScale )
		
		newPosition.x = newPosition.x / xScale
		newPosition.y = newPosition.y / yScale
		
		if _map.ParallaxEnabled then
			newPosition.x = newPosition.x + _map.world.x * -1
			newPosition.y = newPosition.y + _map.world.y * -1
		end
	end
	
	newPosition.x = floor( newPosition.x )
	newPosition.y = floor( newPosition.y )
	
	return newPosition
end

--- Converts a world position into a screen position.
-- @param map The current Map.
-- @param position The world position.
-- @return The screen position.
function Utils:worldToScreenPosition(map, position)

	local _map = map
	local _position = position
	
	local newPosition = {}
	
	if _map.world then
		newPosition.x = _position.x + _map.world.x
		newPosition.y = _position.y + _map.world.y
	end
	
	return newPosition
end

--- Reads the entire contents of a file into a String.
-- @param path The complete path to the file.
-- @return A string containing the read in contents.
function Utils:readInFileContents(path)
		
	local _path = path
	
	local handle = io.open( _path, "r" )

	if(handle) then
		local contents = handle:read( "*a" )

		io.close( handle )

		return contents
	end
end

--- Reads the entire contents of a file into a table of lines.
-- @param path The complete path to the file.
-- @return A table of lines with the read in contents.
function Utils:readLines(path)

	local _path = path
	
	local handle = io.open( _path, "r" )
	local lines = {}
	
	while true do
	    line = handle:read()
	   	if line == nil then break end
	
		lines[#lines + 1] = line
	end
	
	handle:close()

	return lines
end

--- Split a string str in maximum maxNb parts given a delimiter delim.
-- from http://lua-users.org/wiki/SplitJoin - 
-- added  case "" for delim to split the str in array of chars.
--@param str String to split.
--@param delim Delimiter to split on.
--@param maxNb Maximum number of split parts. Optional.
--@return - Array of string-parts that were found during the split.
function Utils:splitString(str, delim, maxNb)
	
	local _str = str
	local _delim = delim
	local _maxNb = maxNb
	
	local result = {}
	if _maxNb == nil or _maxNb < 1 then
			_maxNb = 0    -- No limit
	end
	if(_delim == "")then
			local nb = 0
			for c in _str:gmatch"." do
					nb = nb+1
					result[nb] = c
					if(nb==_maxNb)then return result end
			end
			return result
	end
	if(string.find(_str, _delim) == nil) then
			-- eliminate bad case
			return { _str }
	end
	local pat = "(.-)" .. _delim .. "()"
	local nb = 0
	local lastPos
	for part, pos in string.gfind(_str, pat) do
			nb = nb + 1
			result[nb] = part
			lastPos = pos
			if nb == _maxNb then break end
	end
	-- Handle the last field
	if nb ~= _maxNb then
			result[nb + 1] = string.sub(_str, lastPos)
	end
	return result
end

--- Converts a string of either "true" or "false" to a boolean value. 
-- Case insensitive.
-- @param s The string to convert.
-- @return True or False based on the input string.
function Utils:stringToBool(s)

	local _s = s
	
	if(_s and type(_s) == "string") then
		if(string.lower(_s) == "true") then
			return true
		elseif(string.lower(_s) == "false") then
			return false
		end
	end
	
	return nil
end

--- Converts a boolean value into a string.
-- @param bool The boolean to convert.
-- @return "true" or "false".
function Utils:boolToString(bool)
	
	local _bool = bool
	
	if(_bool) then
		return "true"
	else
		return "false"
	end
end

--- Adds a displayObject to a displayGroup
-- @param displayObject The object to add.
-- @param group The group to add the object to.
-- @return The displayObject
function Utils:addObjectToGroup(displayObject, group)
	
	local _displayObject = displayObject
	local _group = group
	
	if _displayObject then
		
		if _group then
		
			_group:insert(_displayObject)
			
		end
		
	end
	
	return _displayObject
	
end

--- Moves an object a set distance.
-- (something that has an X and Y property)
-- @param object The object to move.
-- @param x The amount to move the object along the X axis.
-- @param y The amount to move the object along the Y axis.
function Utils:moveObject(object, x, y)
	
	local _object = object
	local _x = x
	local _y = y
	
	if not _object then
		return 
	end
	
	if not _object.x or not _object.y then
		return
	end
	
	_object.x = utils:round( (_object.x + (_x or 0) * -1) )
	_object.y = utils:round( _object.y + (_y or 0) )
	
end

--- Drags an object 
-- (something that has an X and Y property).
-- @param object The object to drag.
-- @param event The Touch event.
function Utils:dragObject(object, event)

	local _object = object
	local _event = event
	
	if not _object then
		return 
	end
	
	if not _object.x or not _object.y then
		return
	end
	
	if(_event.phase=="began") then

		_object.touchPosition = {}
    	_object.touchPosition.x = _event.x - _object.x
        _object.touchPosition.y = _event.y - _object.y

    elseif(_event.phase=="moved") then

		if not _object.touchPosition then
			_object.touchPosition = {}
	    	_object.touchPosition.x = _event.x - _object.x
	        _object.touchPosition.y = _event.y - _object.y
		end
		
   		_object.x = _event.x - _object.touchPosition.x
        _object.y = _event.y - _object.touchPosition.y

    end

end

--- Fades the object to a new alpha amount.
-- @param object The Object to move - Tile, Map, TileLayer etc
-- @param visual The visual to move - tile.sprite, map.world, tileLayer.group etc
-- @param alpha The new alpha of the object.
-- @param fadeTime The time it will take to fade the object out or in. Optional, default is 1000.
-- @param onCompleteHandler Event handler to be called on fade completion. Optional.
-- @param easing Easing function for the transition. Optional.
function Utils:fadeObjectToAmount( object, visual, alpha, fadeTime, onCompleteHandler, easing )
	
	local _object = object
	local _visual = visual
	local _alpha = alpha
	local _fadeTime = fadeTime
	local _onCompleteHandler = onCompleteHandler
	local _easing = easing
	
	if not _object or not _visual then
		return 
	end
	
	if not _visual.x or not _visual.y then
		return
	end

	local onFadeOut = function(event)
		if onCompleteHandler then
			onCompleteHandler( event )
		end
	end

	if(_object.fadeTransition) then
		transition.cancel(_object.fadeTransition)
	end
	
	_object.fadeTransition = transition.to( _visual, { alpha = _alpha or 0, time = _fadeTime or 1000, onComplete = onFadeOut, transition = _easing  } )
	
end

--- Fades the object to a new position.
-- @param object The Object to move - Tile, Map, TileLayer etc
-- @param visual The visual to move - tile.sprite, map.world, tileLayer.group etc
-- @param x The new X position of the object.
-- @param y The new Y position of the object.
-- @param fadeTime The time it will take to fade the object out or in. Optional, default is 1000.
-- @param moveDelay The time inbetween both fades. Optional, default is 0.
-- @param onCompleteHandler Event handler to be called on movement completion. Optional.
-- @param easing Easing function for the transition. Optional.
function Utils:fadeObjectToPosition( object, visual, x, y, fadeTime, moveDelay, onCompleteHandler, easing )
	
	local _object = object
	local _visual = visual
	local _x = x
	local _y = y
	local _fadeTime = fadeTime
	local _moveDelay = moveDelay
	local _onCompleteHandler = onCompleteHandler
	local _easing = easing
	
	if not _object or not _visual then
		return 
	end
	
	if not _visual.x or not _visual.y then
		return
	end
	
	local beginFadeIn = function(event)
	
		if _object.moveDelayTimer then
			timer.cancel(_object.moveDelayTimer)
		end
		
		transition.to(_visual, {alpha = 1, time=_fadeTime or 1000, onComplete=_onCompleteHandler})
	end
	
	local onFadeOut = function(event)
		_object:setPosition(x, y)
		
		if moveDelay then
			_object.moveDelayTimer = timer.performWithDelay(_moveDelay, beginFadeIn, 1)
		else
			beginFadeIn()
		end
	end

	if(_object.fadeTransition) then
		transition.cancel(_object.fadeTransition)
	end
	
	_object.fadeTransition = transition.to(_visual, {alpha = 0, time=_fadeTime or 1000, onComplete=onFadeOut, transition = _easing } )

end

--- Slides the Object to a new position.
-- @param object The Object to move - Tile, Map, TileLayer etc
-- @param visual The visual to move - tile.sprite, map.world, tileLayer.group etc
-- @param x The new X position of the Object.
-- @param y The new Y position of the Object.
-- @param slideTime The time it will take to slide the Object to the new position.
-- @param onCompleteHandler Event handler to be called on movement completion. Optional.
-- @param easing Easing function for the transition. Optional.
function Utils:slideObjectToPosition( object, visual, x, y, slideTime, onCompleteHandler, easing )
	
	local _object = object
	local _visual = visual
	local _x = x
	local _y = y
	local _slideTime = slideTime
	local _onCompleteHandler = onCompleteHandler
	local _easing = easing
	
	if not _object or not _visual then
		return 
	end
	
	if not _visual.x or not _visual.y then
		return
	end
	
	_object.onSlideTransitionUpdate = function(event)
		
		_visual.x = utils:round( _object._xPos )
		_visual.y = utils:round( _object._yPos )
		
		-- Special case for moving the map
		if _object.ParallaxEnabled and _object["setParallaxPosition"] then
			_object:setParallaxPosition{x = _visual.x, y = _visual.y }
		end
		
		-- Special case for the map
		if _object["updateLayerVisibility"] then
			_object:updateLayerVisibility()
		end
		
		-- Special case for moving tiles
		if _object["updateGridPosition"] then
			_object:updateGridPosition()
		end
		
	end
	
	local onSlideComplete = function(event)
	
		if _onCompleteHandler then
			_onCompleteHandler(event)
		end
		
		Runtime:removeEventListener("enterFrame", _object.onSlideTransitionUpdate)
	end
	
	if(_object.slideTransition) then
		transition.cancel(_object.slideTransition)
		Runtime:removeEventListener("enterFrame", _object.onSlideTransitionUpdate)
	end
	
	_object._xPos = _visual.x
	_object._yPos = _visual.y
	
	Runtime:addEventListener("enterFrame", _object.onSlideTransitionUpdate)
	
	_object.slideTransition = transition.to( _object, {time=_slideTime or 1000, _xPos=_x, _yPos=_y, onComplete=onSlideComplete, transition = _easing } )
end

--- Slides an object along a path of points.
-- @param object The Object to move.
-- @param visual The visual attached to the Object.
-- @param path List of points to move the Object along. Must be a list of tables that have an X and Y value.
-- @param slideTime The time it will take to slide the Object to the next point.
-- @param cycles The amount of times to loop through the path. Optional. Default is unlimited.
function Utils:slideObjectAlongPath(object, visual, path, slideTime, cycles)

	local _object = object
	local _visual = visual
	local _path = path
	local _slideTime = slideTime
	local _cycles = cycles
	
	local onCompleteHandler
	local currentPointIndex = 1
	local totalCycles = 0
	
	if not _object or not _visual then
		return 
	end
	
	if not _visual.x or not _visual.y then
		return
	end
	
	if not _path then
		return
	end
	
	if #_path < 1 then
		return
	end

	onCompleteHandler = function( event )
		
		currentPointIndex = currentPointIndex + 1
	
		if currentPointIndex > #_path then
			currentPointIndex = 1
			totalCycles = totalCycles + 1
		end
		
		local point = _path[ currentPointIndex ]
		
		if point and point.x and point.y then
		
			if _cycles and ( totalCycles >= _cycles ) then
				return
			end
					
			utils:slideObjectToPosition(_object, _visual, _path[ currentPointIndex ].x, _path[ currentPointIndex ].y, _slideTime, onCompleteHandler )	
		end
		
	end

	utils:slideObjectToPosition(_object, _visual, _path[1].x, _path[1].y, _slideTime, onCompleteHandler )
	
end

--- Converts a 6 digit Hex value into its RGB elements.
-- @param hex The hex value to convert.
-- @returns A table with the r, g and b values.
function Utils:hexToRGB(hex)
	
	if not hex or type( hex ) ~= "table" then
		return
	end
	
	local _hex = hex 
	
	local colour = {}
	
	colour.r = tonumber(_hex:sub(1, 2), 16)
	colour.g = tonumber(_hex:sub(3, 4), 16)
	colour.b = tonumber(_hex:sub(5, 6), 16)
	
	return colour
	
end

--- Extracts an extension from a filename.
-- @param filename The filename to use.
-- @returns The extracted extension.
function Utils:getExtensionFromFilename(filename)

	local _filename = filename
	
	local splitFilename = {}
	local pattern = string.format("([^%s]+)", ".")
	_filename:gsub(pattern, function(c) splitFilename[#splitFilename+1] = c end)
		
	return splitFilename[2]
end

--- Extracts a filename from a path.
-- @param path The path to use.
-- @returns The extracted filename.
function Utils:getFilenameFromPath(path)

	local _path = path
	
	local splitPath = utils:splitString(_path, "/")
		
	return splitPath[#splitPath]
end

--- Strips a filename from a path.
-- @param path The path to use.
-- @return The stripped path.
function Utils:stripFilenameFromPath(path)
	
	local _path = path
	
	local splitPath = utils:splitString(_path, "/")
	
	_path = ""
	
	for i=1, #splitPath - 1, 1 do
		_path = _path .. splitPath[i] .. "/"
	end
	
	return _path
	
end

--- Adds a suffix to a filename.
-- @param filename The filename to use.
-- @param suffix The suffix to use.
-- @return The new filename.
function Utils:addSuffixToFileName(filename, suffix)
	
	local _filename = filename
	local _suffix = suffix
	
	local splitFilename = {}
	local pattern = string.format("([^%s]+)", ".")
	_filename:gsub(pattern, function(c) splitFilename[#splitFilename+1] = c end)
	
	if #splitFilename == 2 then
		splitFilename[1] = splitFilename[1] .. _suffix
	end
	
	return table.concat(splitFilename, ".")
	
end

--- Gets the last directory in a path.
-- @param path The path to use.
-- @return The last directory.
function Utils:getLastDirectoryInPath(path)

	local _path = path
	
	local strippedPath = utils:stripFilenameFromPath(_path)
	
	local splitPath = utils:splitString(strippedPath, "/")
	
	return splitPath[#splitPath - 1]
	
end

--- Copies Properties from one object to another.
-- @param objectA The object that has the Properties.
-- @param objectB The object that will have the Properties coped to it. Must have an "addProperty" function.
function Utils:copyProperties(objectA, objectB)
	
	local _objectA = objectA
	local _objectB = objectV
	
	local properties = _objectA:getProperties()
	
	for _k, value in pairs(properties) do
		_objectB:addProperty(value)
	end
	
end

--- Adds a collision filter from an object to a body.
-- @param item The item to add the collision filter to.
function Utils:addCollisionFilterToBody(item)

	local _item = item
	
	local categoryBits = _item:getPropertyValue("categoryBits")
	local maskBits = _item:getPropertyValue("maskBits")
	local groupIndex = _item:getPropertyValue("groupIndex")
	
	if(categoryBits or maskBits or groupIndex) then
		
		local collisionFilter = {}
		
		collisionFilter.categoryBits = categoryBits
		collisionFilter.maskBits = maskBits
		collisionFilter.groupIndex = groupIndex
		
		_item.filter = collisionFilter
	end
end

--- Applies physical properties to a body.
-- @param body The body to apply the properties to.
-- @param params The physical properties.
function Utils:applyPhysicalParametersToBody(body, params)
 
	local _body = body
	local _params = params
	
	if(_body) then

		_body.isAwake = utils:convertStringToBoolSafely(_params.isAwake)
		_body.isBodyActive = utils:convertStringToBoolSafely(_params.isBodyActive) or true
		_body.isBullet = utils:convertStringToBoolSafely(_params.isBullet)
		_body.isSleepingAllowed = utils:convertStringToBoolSafely(_params.isSleepingAllowed)
		_body.isFixedRotation = utils:convertStringToBoolSafely(_params.isFixedRotation)
		_body.angularVelocity = _params.angularVelocity
		_body.linearDamping = _params.linearDamping
		_body.angularDamping = _params.angularDamping
		_body.bodyType = _params.bodyType
		_body.isSensor = utils:convertStringToBoolSafely(_params.isSensor)

	end
end

--- Adds the non-physical properties of an object to a body.
-- @param body The body to add the properties to.
-- @param object The object that has the properties.
function Utils:addPropertiesToBody(body, object)

	local _body = body
	local _object = object
	
	local properties = _object:getProperties()
	local property = {}
	local propertyName = ""
	
	for key, _v in pairs(properties) do
		
		property = properties[key]
		
		if property then

			propertyName = property:getName()

			if propertyName ~= "isAwake" and
				propertyName ~= "isBodyActive" and
				propertyName ~= "isBullet" and
				propertyName ~= "isSleepingAllowed" and
				propertyName ~= "isFixedRotation" and
				propertyName ~= "angularVelocity" and
				propertyName ~= "linearDamping" and
				propertyName ~= "angularDamping" and
				propertyName ~= "bodyType" and
				propertyName ~= "friction" and
				propertyName ~= "bounce" and
				propertyName ~= "density" and
				propertyName ~= "points" then
	
				_body[propertyName] = property:getValue()
			end
		end	
	end
end

--- Copies the Properties of one object to another. 
-- For adding to an object that doesn't have "addProperty" such as a Sprite.
-- @param objectA The object that has the Properties.
-- @param objectB The object that will have the Properties coped to it.
-- @param propertiesToIgnore A list of properties to not add if they exist. Optional.
function Utils:copyPropertiesToObject(objectA, objectB, propertiesToIgnore)

	local _objectA = objectA
	local _objectB = objectB
	local _propertiesToIgnore = propertiesToIgnore
	
	local properties = _objectA:getProperties()
	
	for key, property in pairs(properties) do
		
		local copyProperty = true
		
		if _propertiesToIgnore then
			
			for i = 1, #_propertiesToIgnore, 1 do
				if _propertiesToIgnore[i] == key then
					copyProperty = false
					break	
				end			
			end
			
		end
		
		if copyProperty then
			_objectB[key] = property:getValue()		
		end

	end
	
end

--- Clamps a position to within bounds.
-- @param x The X position to clamp.
-- @param y The Y position to clamp.
-- @param bounds The bounding box for the clamping. A table with x, y, width and height. X and y are top left corner.
-- @param isIsometric True if the map to clamp is Isometric.
-- @return The clamped X position.
-- @return The clamped Y position.
function Utils:clampPosition( x, y, bounds, isIsometric )

	local _x = x
	local _y = y
	local _bounds = bounds
	
	if not _bounds.offset then
		_bounds.offset = { x = 0, y = 0 }
	end
	
	if _bounds then
	
		if isIsometric then
	
			if _x <= -( _bounds.x - _bounds.offset.x ) + display.contentWidth then
				_x = -( _bounds.x - _bounds.offset.x ) + display.contentWidth
			elseif _x > _bounds.x then	
				_x = _bounds.x
			end
			
			if -_y < ( _bounds.y * 2 ) then
				_y = -_bounds.y * 2
			elseif _y <= -( ( _bounds.height - _bounds.offset.y ) + _bounds.y ) + display.contentHeight then
				_y = -( ( _bounds.height - _bounds.offset.y ) + _bounds.y ) + display.contentHeight
			end
			
		else
		
			if abs(_x) > ( _bounds.width - _bounds.offset.x ) - display.contentWidth then
				_x = - ( ( _bounds.width - _bounds.offset.x ) - display.contentWidth ) 
			elseif _x > _bounds.x then
				_x = _bounds.x
			end
			
			if abs(_y) > ( _bounds.height - _bounds.offset.y ) - display.contentHeight then
				_y = - ( ( _bounds.height - _bounds.offset.y ) - display.contentHeight )
			elseif y > _bounds.y then
				_y = _bounds.y
			end
			
		end
		
	end
	
	return _x, _y
	
end

--- Calculates a viewpoint for a given position.
-- @param group The display group.
-- @param x The X position for the viewpoint.
-- @param y The Y position for the viewpoint.
-- @return The calculated viewpoint.
function Utils:calculateViewpoint(group, x, y)

	local _group = group
	local _x = x
	local _y = y
	
	local xPos = _x or (_group.x + ( _group.width * 0.5 ) ) -- Don't like this
	local yPos = _y or (_group.y + ( _group.height * 0.5 ) ) -- Don't like this

	local actualPosition = { x = xPos, y = yPos }
	local centreOfView = { x = display.contentWidth * 0.5 , y = display.contentHeight * 0.5 }
	
	local viewPoint = { x = centreOfView.x - actualPosition.x, y = centreOfView.y - actualPosition.y }
         
	return viewPoint
end

--- Rounds a number.
-- @param number The number to utils:round.
-- @param fudge A value to add to the number before rounding. Optional.
-- @return The rounded number.
function Utils:round(number, fudge)
	
	local _number = number
	local _fudge = fudge 
	
	local fudgeValue = _fudge or 0
	
	return (floor(_number + fudgeValue))
end

--- Encodes a table into a JSON object and writes it out to a file in the documents directory.
-- @param path The path to the new file.
-- @param table The table to save.
function Utils:saveOutTable(path, table)
	
	local _path = path
	local _table = table
	
	if Json and _table then
	
		_path = system.pathForFile( _path, system.DocumentsDirectory )

		file = io.open( _path, "w" )
    	file:write( Json.Encode(_table) )
   		io.close( file )
   		
   	end
	
end

--- Reads a JSON object from a file and decodes it.
-- @param path The path to the file.
-- @param baseDirectory The base directory for the path. Default is system.DocumentsDirectory.
-- @return If successful returns a table with the data from the file. Otherwise returns nil.
function Utils:readInTable(path, baseDirectory)

	local _path = path
	local _baseDirectory = baseDirectory
	
	if Json then
		
		_path = system.pathForFile( _path, _baseDirectory or system.DocumentsDirectory )

		file = io.open( _path, "r" )
		
		if file then
	
			local table = Json.Decode( file:read( "*a" ) ) 
	
			io.close( file )
	
			return table
			
		else
			return nil
		end
	
	end
end

--- Converts a string into a table.
-- @param string The string to convert.
-- @param delimiter What the string should be split on.
-- @return table The converted table.
function Utils:stringToIntTable(string, delimiter)

	local _string = string
	local _delimiter = delimiter
	
	if _string then
	
    	local table = utils:splitString(_string, _delimiter or " ")
        
        for i,v in ipairs(table) do 
        	table[i] = tonumber(table[i]) 
        end
        
        return table
    end
end

--- Converts a table into a string.
-- @param table The table to convert.
-- @param indent Indentation amount. Used for recursive calls.
-- @return string The converted string.
function Utils:tableToString(table, indent) 

	local _table = table
	local _indent = indent
	
    local str = "" 

    if(_indent == nil) then 
        _indent = 0 
    end 

    -- Check the type 
    if(type(_table) == "string") then 
        str = str .. (" "):rep(_indent) .. _table .. "\n" 
    elseif(type(_table) == "number") then 
        str = str .. (" "):rep(_indent) .. _table .. "\n" 
    elseif(type(_table) == "boolean") then 
        if(_table == true) then 
            str = str .. "true" 
        else 
            str = str .. "false" 
        end 
    elseif(type(_table) == "table") then 
        local i, v 
        for i, v in pairs(_table) do 
            -- Check for a table in a table 
            if(type(v) == "table") then 
                str = str .. (" "):rep(_indent) .. i .. ":\n" 
                str = str .. utils:tableToString(v, _indent + 2) 
            else 
                str = str .. (" "):rep(_indent) .. i .. ": " .. utils:tableToString(v, 0) 
            end 
        end 
    else 
       -- print_debug(1, "Error: unknown data type: %s", type(data)) 
    end 

    return str 
end

--- Prints out a table to the Console.
-- @param table The table to print.
-- @param indent Indentation amount. Used for recursive calls.
function Utils:printTable(table, indent)
	local _table = table
	local _indent = indent
	print(utils:tableToString(_table, _indent))
end

--- Loads in a config file and copies all the stored properties over to an object.
-- @param definition The value from the Tiled property.
-- @param object The object to set the properties on. Must have a setProperty function!
function Utils:readInConfigFile(definition, object)
	
	local _definition = definition
	local _object = object
	
	if _definition and _object then
		local splitDefinition = utils:splitString(_definition, "|")

		-- Set the default path and directory assuming definition is just a single string
		local baseDirectory = system.ResourceDirectory
		local path = _definition
		
		if #splitDefinition == 2 then
			
			-- Get the new base directory
			local baseDirectory = system.ResourceDirectory
			
			if string.lower(splitDefinition[1]) == "resource" then
				baseDirectory = system.ResourceDirectory
			elseif string.lower(splitDefinition[1]) == "documents" then
				baseDirectory = system.DocumentsDirectory
			end
			
			-- Get the new path
			path = splitDefinition[2]
		end
		
		-- Read in and decode the data
		local configData = utils:readInTable(path, baseDirectory )
			
		if configData then
			
			-- Set all the lovely new properties on the object
			-- First deal with the configFiles before the "normal" props
			if configData["configFiles"] then
			
				value = configData["configFiles"]
				
				for i=0, #value, 1 do
					utils:readInConfigFile(value[i], object)
				end
			end
			
			-- Now deal with a single configFile value. If Specified.
			if configData["configFile"] then
				
				value = configData["configFile"]
				
				utils:readInConfigFile(value, object)
				
			end
			
			for key, value in pairs(configData) do 
				if key ~= "configFiles" then
					object:setProperty(key, value)
				end
			end
			
			if(lime.isDebugModeEnabled()) then
				print("Lime-Lychee: Loaded Config File - " .. path)
			end
		end
		
	end
end

--- Makes tiles on screen visible.
-- Sets tiles that are just off screen to be invisible and those on screen to be visible.
-- @usage If your application has a lot of sprites that end up off screen then it may benefit from calling 
-- this function either on a per frame basis or when moving the camera/grid.
-- @param map The current Map.
function Utils:showScreenSpaceTiles(map)
	
	local _map = map
	
	-- Use 1,1 to get top left corner as 0,0 returns nil
	local screenPos = {x = 1, y = 1}

	local gridPos = utils:screenToGridPosition(_map, screenPos)
	
	-- Find out how many tiles fit on screen width / height
	local numTilesScreenWidth  = display.contentWidth / _map.tilewidth
	local numTilesScreenHeight = display.contentHeight / _map.tileheight
	
	local tempTile  = 0
	
	-- Loop through tile layers
	for i = 1, #_map.tileLayers, 1 do
		-- Loop through tile columns
		for j = (gridPos.column - 1), (gridPos.column + numTilesScreenWidth + 1), 1 do
			-- Loop through tile rows
			for k = (gridPos.row - 1), (gridPos.row + numTilesScreenHeight + 1), 1 do
				-- Grab the tile at the current row / column
				tempTile = _map.tileLayers[i]:getTileAt{row = k, column = j}
				
				-- Check if there was a tile
				if tempTile then
					if j < gridPos.column or j > (gridPos.column + numTilesScreenWidth) or k < gridPos.row or k > gridPos.row + numTilesScreenHeight then
					
						-- Extra check suggested by Pavel Nakaznenko
						if (tempTile:isOnScreen()) then
							tempTile.sprite.isVisible = true
						else
							-- If the tile is just off screen make invisible					
							tempTile.sprite.isVisible = false
						end
						
						-- If the tile is just off screen make invisible
						--tempTile.sprite.isVisible = false
					else
						-- If the tile is onscreen then make visible
						tempTile.sprite.isVisible = true
					end
				end
			end
		end
	end
end

--- Safely loads an external module.
-- @param moduleName The name of the module. Ex. "ui"
-- @return The loaded module or nil if none found.
function Utils:loadModuleSafely(moduleName)

	local _moduleName = moduleName
	
	local path = system.pathForFile(_moduleName .. ".lua", system.ResourceDirectory)
	
	if path then
		return require(_moduleName)
	end

end

--- Converts a string into a number safely.
-- @param string The string to convert.
-- @return The number value or the original string if not numeric.
function Utils:convertStringToNumberSafely(string)

	local _string = string
	
	local numberValue = tonumber(_string)
	
	if numberValue then
		return numberValue
	end
	
	return _string

end

--- Converts a string into a boolean safely.
-- @param string The string to convert.
-- @return The boolean value or the original string if not a boolean.
function Utils:convertStringToBoolSafely(string)

	local _string = string
	
	if type(_string) ~= "string" then
		return _string
	end
	
	local boolValue = utils:stringToBool(_string)
	
	if boolValue ~= nil then
		return boolValue
	end
	
	return _string

end

--- Decodes a Json string safely.
-- @param string The string to decode.
-- @param strict If true the string will be decoded without any regard to error checking.
-- @return The decoded value for all proper Json. If there is an error it will append quotes to the string and return the decoded result along with the error.
function Utils:decodeJsonSafely(string, strict)

	local _string = string
	local _strict = strict
	
	if _strict then
		return Json.Decode(_string)
	else
		
		local success, value = pcall(Json.Decode, _string)
		
		if success then
			return value
		else
			if type( _string ) == "boolean" then
				return _string
			else
				return Json.Decode("\"".. _string .."\""), value
			end
		end		
	
	end

end

--- Checks if a property is a Seed.
-- @param The value string from Tiled.
-- @return True if it is, false otherwise.
function Utils:isPropertyASeed(value)
	
	local _value = value
	
	if _value then
	
		if type(_value) == "string" then
			
			local splitValue = utils:splitString(_value, ":")
			
			if #splitValue > 1 then
				
				if splitValue[1] == "seed" then
					return true
				end
				
			end
			
		end
		
	end
	
	return false

end

--- Returns a value from a seed if it exists.
-- @param The value string from Tiled. Should be "seed:seedName".
-- @return The seed value or the passed in value if it is not a seed.
function Utils:getValueFromSeed(value)
	
	local _value = value
	
	if _value and type(_value) == "string" then
	
		local splitValue = utils:splitString(_value, ":")
			
		if #splitValue > 1 then
			
			if splitValue[1] == "seed" then
				
				local seed = utils:loadModuleSafely("lime-seed-" .. splitValue[2])
				
				if seed then
					
					local params = nil
					
					if splitValue[3] then
						params = utils:splitString(splitValue[3], ",")
					end

					return seed.main(params)
					
				end
				
			end
			
		end
		
	end
	
	-- Not a seed property so just return whatever it is
	return _value
	
end

---Converts a frame count into minutes, seconds and tenths.
-- Can be used to display a timer like this -- minutes .. ":" .. seconds .. ":" .. tenths
-- @param frameCount The count of the frames
-- @param fps The current fps. Either 30 or 60, will default to 30.
-- @return minutes Minute value.
-- @return seconds Second value.
-- @return tenths Tenths of second value.
function Utils:convertFramesToTime(frameCount, fps)
		
	local _frameCount = frameCount
	local _fps = fps
	
	local decimalSeconds = _frameCount / (_fps or 30)
	local minutes = utils:round(decimalSeconds / 60)
	decimalSeconds = decimalSeconds - (minutes * 60)
	seconds = utils:round(decimalSeconds)
	local tenths = utils:round((decimalSeconds - seconds) * 10)
		
	return minutes, seconds, tenths
end

--- Gets the distance between two positions.
-- @param pos1 First position. Table containing X and Y values.
-- @param pos2 Second position. Table containing X and Y values.
-- @return distance The distance between the two positions.
function Utils:getDistanceBetween( pos1, pos2 )

	local _pos1 = pos1
	local _pos2 = pos2
	
	if not _pos1 or not _pos2 then
		return
	end
	
	if not _pos1.x or not _pos1.y or not _pos2.x or not _pos2.y then
		return
	end
	 
	local factor = { x = _pos2.x - _pos1.x, y = _pos2.y - _pos1.y }

	return sqrt( ( factor.x * factor.x ) + ( factor.y * factor.y ) )

end

--- Gets the angle between two positions.
-- @param pos1 First position. Table containing X and Y values.
-- @param pos2 Second position. Table containing X and Y values.
-- @param radians If true then convert the angle to radians.
-- @return angle The angle between the two positions.
function Utils:getAngleBetween( pos1, pos2, radians )
	
	local _pos1 = pos1
	local _pos2 = pos2
	local _radians = raidans
	
	if not _pos1 or not _pos2 then
		return
	end
	
	if not _pos1.x or not _pos1.y or not _pos2.x or not _pos2.y then
		return
	end

	local distance = { x = _pos2.x - _pos1.x, y = _pos2.y - _pos1.y }

	if distance then

		local angleBetween = atan( distance.y / distance.x ) --+ rad( 90 )
	
	     if ( _pos1.x < _pos2.x ) then 
			angleBetween = angleBetween + rad( 90 ) 
		else 
			angleBetween = angleBetween + rad( 270 ) 
		end		
		
		if angleBetween == pi or angleBetween == pi2 then
  			angleBetween = angleBetween - rad( 180 )
		end

		if not _radians then
			angleBetween = deg( angleBetween )
		end
		
		return angleBetween
	
	end

	return nil
end

--- Sets the fill colour ( tint ) of a sprite.
-- @param sprite The sprite to tint. Or a display object.
-- @param colour The colour to use. Table containing up to 4 values.
function Utils:setSpriteFillColor( sprite, colour )

	if sprite and sprite[ "setFillColor" ] and colour and type( colour ) == "table" then

		if #colour == 1 then
			sprite:setFillColor( colour[ 1 ] )
		elseif #colour == 2 then
			sprite:setFillColor( colour[ 1 ], colour [ 2 ] )
		elseif #colour == 3 then
			sprite:setFillColor( colour[ 1 ], colour [ 2 ], colour[ 3 ] )
		elseif #colour == 4 then
			sprite:setFillColor( colour[ 1 ], colour [ 2 ], colour[ 3 ], colour [ 4 ] )
		end
	
	elseif colour and type( colour ) == "number" and colour >= 0 and colour <= 255 then
		sprite:setFillColor( colour )
	end
	
end

_G.utils = Utils:new()

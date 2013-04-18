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
-- File name: lime.lua
--
--- The main Lime manager source file.
--  The API's in this source file can be seen as a set of manager methods for using Lime.

----------------------------------------------------------------------------------------------------

module(..., package.seeall)

----------------------------------------------------------------------------------------------------
----									LIME MODULES											----
----------------------------------------------------------------------------------------------------

require("lime.lime-utils")
limeInterface = require("lime.lime-interface")

require("lime.lime-external-xml_parser")
require("lime.lime-external-Json")

require("lime.lime-atlas")
require("lime.lime-map")
require("lime.lime-tileLayer")
require("lime.lime-objectLayer")
require("lime.lime-tile")
require("lime.lime-object")
require("lime.lime-tileSet")
require("lime.lime-property")

----------------------------------------------------------------------------------------------------
----									MODULE VARIABLES										----
----------------------------------------------------------------------------------------------------

version = 3.4

requiredVersions = {}
requiredVersions["atlas"] = 3.5
requiredVersions["map"] = 3.5
requiredVersions["tileLayer"] = 3.5
requiredVersions["objectLayer"] = 3.5
requiredVersions["tile"] = 3.5
requiredVersions["object"] = 3.5
requiredVersions["tileSet"] = 3.5
requiredVersions["property"] = 3.5
requiredVersions["utils"] = 3.5

----------------------------------------------------------------------------------------------------
----									GLOBAL (YIK) PROPERTIES									----
----------------------------------------------------------------------------------------------------

_G.limeScreenCullingEnabled = false

----------------------------------------------------------------------------------------------------
----									PUBLIC PROPERTIES										----
----------------------------------------------------------------------------------------------------

isSimulator = system.getInfo("environment") == "simulator"

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS										    ----
----------------------------------------------------------------------------------------------------

--- Checks to see if you are running the current version of Lime. 
-- Will display the results in the console.
-- @return True if OK. False if there is a version mismatch.
function verifyVersion()
	
	local allVersionsAreOK = true
	
	local displayVersionMismatchMessage = function(moduleName, moduleVersion, requiredVersion)
		print("Lime: Version mismatch! " .. moduleName .. " is version " .. moduleVersion .. " yet it needs to be " .. requiredVersion)
		
		allVersionsAreOK = false
	end

	if Atlas.version ~= requiredVersions["atlas"] then
		displayVersionMismatchMessage("'lime-atlas.lua'", Map.version, requiredVersions["atlas"] )
	end
	
	if Map.version ~= requiredVersions["map"] then
		displayVersionMismatchMessage("'lime-map.lua'", Map.version, requiredVersions["map"] )
	end
	
	if TileLayer.version ~= requiredVersions["tileLayer"] then
		displayVersionMismatchMessage("'lime-tileLayer.lua'", TileLayer.version, requiredVersions["tileLayer"] )
	end
	
	if ObjectLayer.version ~= requiredVersions["objectLayer"] then
		displayVersionMismatchMessage("'lime-objectLayer.lua'", ObjectLayer.version, requiredVersions["objectLayer"] )
	end
	
	if Tile.version ~= requiredVersions["tile"] then
		displayVersionMismatchMessage("'lime-tile.lua'", Tile.version, requiredVersions["tile"] )
	end
	
	if Object.version ~= requiredVersions["object"] then
		displayVersionMismatchMessage("'lime-object.lua'", Object.version, requiredVersions["object"] )
	end
	
	if TileSet.version ~= requiredVersions["tileSet"] then
		displayVersionMismatchMessage("'lime-tileSet.lua'", TileSet.version, requiredVersions["tileSet"] )
	end
	
	if Property.version ~= requiredVersions["property"] then
		displayVersionMismatchMessage("'lime-property.lua'", Property.version, requiredVersions["property"] )
	end	
	
	if utils.version ~= requiredVersions["utils"] then
		displayVersionMismatchMessage("'lime-utils.lua'", utils.version, requiredVersions["utils"] )
	end			

	if allVersionsAreOK then
		print("Lime: Using version " .. version .. " - All dependencies are A-OK.")
	end
	
	return allVersionsAreOK
end

--- Enables debug mode so messages are printed to the console when things happen.
function enableDebugMode()
	limeDebugModeEnabled = true
end

--- Disables debug mode so messages aren't printed to the console. Errors will still be printed.
function disableDebugMode()
	limeDebugModeEnabled = false
end	

--- Checks if debug mode is currently enabled or disabled.
-- @return True if enabled, false if not.
function isDebugModeEnabled()
	return limeDebugModeEnabled
end

--- Loads a map.
-- @param fileName The filename of the map.
-- @param baseDirectory Path to load the map data from filename. Default is system.ResourceDirectory.
---- @return The loaded Map object.
function loadMap(fileName, baseDirectory)
	return Map:new(fileName, baseDirectory)	
end

--- Loads a custom map.
-- @param fileName The filename of the map.
-- @param baseDirectory Path to load the map data from filename. Default is system.ResourceDirectory.
-- @param params Custom map parameters.
-- @return The loaded Map object.
function loadCustomMap(fileName, baseDirectory, params)
	return Map:new(fileName, baseDirectory, params)	
end

--- Creates the visual representation of a map.
-- @param map The map to create.
-- @return The display group for the map world.
function createVisual(map)
	return map:create()
end

--- Creates the visual representation of a single layer.
-- @param map The map that contains the layer.
-- @param layerName The name of the layer.
-- @return The created layer.
function createTileLayer(map, layerName)
	local layer = map:getTileLayer(layerName)
	
	if layer then
		return layer:create()
	end
end

--- Creates the visual debug representation of a single object layer.
-- @param map The map that contains the object layer.
-- @param layerName The name of the object layer.
-- @return The created object layer.
function createObjectLayer(map, layerName)
	local layer = map:getObjectLayer(layerName)
	
	if layer then
		return layer:create()
	end
end

--- Build a physical representation of a map.
-- @param map - The map to build. 
function buildPhysical(map)
	map:build()
end

--- Create an Atlas.
-- @return The created atlas.
function createAtlas()
	return Atlas:new()
end

--- Register a map so that an interface will be created from it.
-- @param map - The map object. 
function registerInterface(map)
	limeInterface.register(map)
end


--- Enable screen space culling.
function enableScreenCulling()
	_G.limeScreenCullingEnabled = true
end

--- Disable screen space culling.
function disableScreenCulling()
	_G.limeScreenCullingEnabled = false
end	

--- Check if screen culling is enabled.
-- @return True if enabled, false if not.
function isScreenCullingEnabled()
	return _G.limeScreenCullingEnabled
end

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
-- File name: lime-property.lua
--
----------------------------------------------------------------------------------------------------
----									CLASS METATABLE											----
----------------------------------------------------------------------------------------------------

Property = {}
Property_mt = { __index = Property }

----------------------------------------------------------------------------------------------------
----									CLASS VARIABLES											----
----------------------------------------------------------------------------------------------------

Property.version = 3.4

----------------------------------------------------------------------------------------------------
----									LOCALISED VARIABLES										----
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

---Create a new instance of a Property object.
-- @param name The name of the Property.
-- @param value The value of the Property.
-- @return The newly created property instance.
function Property:new(name, value)

    local self = {}    -- the new instance
    
    setmetatable( self, Property_mt ) -- all instances share the same metatable
    
    self.name = name
    
    -- First try to get a value from a seed.
    -- If the property is not a seed then
    -- it will just be returned untouched
    -- as a string.
    
    if utils:isPropertyASeed(value) then
    	self.value = utils:getValueFromSeed(value)
    else
    	self.value = utils:decodeJsonSafely(value)
    end	
	
    return self
    
end

--- Gets the name of the Property. 
-- @return The name of the Property.
function Property:getName()
	return self.name
end

--- Gets the value of the Property. 
-- @return The value of the Property.
function Property:getValue()	
	return self.value
end

--- Sets the value of the Property. 
-- @param value The new value.
function Property:setValue(value)
	self.value = utils:decodeJsonSafely(value)
end

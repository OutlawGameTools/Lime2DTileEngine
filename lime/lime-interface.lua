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
-- File name: lime-interface.lua
--
----------------------------------------------------------------------------------------------------

module(..., package.seeall)

----------------------------------------------------------------------------------------------------
----									MODULE VARIABLES										----
----------------------------------------------------------------------------------------------------

version = 3.4
defaultTextColour = {0, 0, 0, 255}

----------------------------------------------------------------------------------------------------
----									LOCALISED VARIABLES										----
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
----									REQUIRED MODULES										----
----------------------------------------------------------------------------------------------------

local ui = utils:loadModuleSafely("lime.ui")

----------------------------------------------------------------------------------------------------
----									PRIVATE METHODS											----
----------------------------------------------------------------------------------------------------

local onButtonObject = function(object)
	
	-- Force full alpha if none present
	if object.textColour then
		if not object.textColour[4] then
			object.textColour[4] = 255
		end
	else
		object.textColour = defaultTextColour
	end
	
	object.sprite = ui.newButton
	{
        default = object.default,
        over = object.over,
      --  onEvent = buttonHandler,
        text = object.text or object.name or "",
        font = object.font,
        textColor = object.textColour,
        size = object.size,
        emboss = object.emboss
	}
	
	utils:copyPropertiesToObject(object, object.sprite, {"width", "height"})
	
	object.sprite.x = object.sprite.x + object.sprite.width / 2
	object.sprite.y = object.sprite.y + object.sprite.height / 2

	object.objectLayer.group:insert(object.sprite)  
end

local onWebPopupObject = function(object)

	local baseDir = object.baseDirectory
	
	if baseDir then
		if string.tolower(baseDir) == "documents" or "docs" then
			baseDir = system.DocumentsDirectory
		elseif string.tolower(baseDir) == "temp" or "tmp" then
			baseDir = system.ResourceDirectory
		else
			baseDir = system.TempDirectory
		end	
	end
	
	if lime.isSimulator then
		object.sprite = display.newRect(object.objectLayer.group, object.x, object.y, object.width or 1, object.height or 1)
		object.sprite:setFillColor(255, 255, 255, 255)
		object.sprite.strokeWidth = 3
		object.sprite:setStrokeColor(255, 0, 0, 255)
	else
		native.showWebPopup( object.x, object.y, object.width, object.height, object.url or "http://www.justaddli.me", { baseDirectory = baseDir, hasBackground = object.hasBackground } )
	end
end

local onTextField = function(object)

	if lime.isSimulator then
		object.sprite = display.newRect(object.objectLayer.group, object.x, object.y, object.width or 1, object.height or 1)
		object.sprite:setFillColor(255, 255, 255, 255)
		object.sprite.strokeWidth = 3
		object.sprite:setStrokeColor(255, 0, 0, 255)
	else
	
		-- Force full alpha if none present
		if object.textColour then
			if not object.textColour[4] then
				object.textColour[4] = 255
			end
		else
			object.textColour = defaultTextColour
		end
		
		object.sprite = native.newTextField(object.x, object.y, object.width or 1, object.height or 1)
		object.sprite.align = object.align
		object.sprite.font = object.font
		object.sprite.isSecure = object.isSecure
		object.sprite.size = object.size
		object.sprite.text = object.text or ""
		object.sprite.inputType = object.inputType
		
		if textColour then
			object.sprite:setTextColor(object.textColour[1], object.textColour[2], object.textColour[3], object.textColour[4])
		end
		
	end
	
end

local onTextBox = function(object)

	if lime.isSimulator then
		object.sprite = display.newRect(object.objectLayer.group, object.x, object.y, object.width or 1, object.height or 1)
		object.sprite:setFillColor(255, 255, 255, 255)
		object.sprite.strokeWidth = 3
		object.sprite:setStrokeColor(255, 0, 0, 255)
	else
	
		-- Force full alpha if none present
		if object.textColour then
			if not object.textColour[4] then
				object.textColour[4] = 255
			end
		else
			object.textColour = defaultTextColour
		end
		
		object.sprite = native.newTextBox(object.x, object.y, object.width or 1, object.height or 1)
		object.sprite.align = object.align
		object.sprite.font = object.font
		object.sprite.size = object.size
		object.sprite.text = object.text or ""
		object.sprite.hasBackground = object.hasBackground
		
		if textColour then
			object.sprite:setTextColor(object.textColour[1], object.textColour[2], object.textColour[3], object.textColour[4])
		end
		
	end
	
end

local onLabelObject = function(object)

	-- Force full alpha if none present
	if object.textColour then
		if not object.textColour[4] then
			object.textColour[4] = 255
		end
	else
		object.textColour = defaultTextColour
	end
	
	object.sprite = ui.newLabel
	{
    	textColor = object.textColour,
        bounds = { object.x, object.y, object.width or 1, object.height or 1 },
        text = object.text or object.name or "",
        align = object.align,
        size = object.size,
        font = object.font,
        offset = object.offset
    }
 	
 	utils:copyPropertiesToObject(object, object.sprite, {"width", "height", "x", "y"})
 	
    object.objectLayer.group:insert(object.sprite)    
end

local onText = function(object)

	-- Force full alpha if none present
	if object.textColour then
		if not object.textColour[4] then
			object.textColour[4] = 255
		end
	else
		object.textColour = defaultTextColour
	end

	object.sprite = display.newText(object.objectLayer.group, object.text or object.name or "", 0, 0, object.font, object.size or 50)
	
	if object.textColour then
		object.sprite:setTextColor(object.textColour[1], object.textColour[2], object.textColour[3], object.textColour[4])
	end
  
  	utils:copyPropertiesToObject(object, object.sprite, {"width", "height", "x", "y"})
 	
 	object.sprite.x = object.x + object.sprite.width / 2
	object.sprite.y = object.y + object.sprite.height / 2 
end

----------------------------------------------------------------------------------------------------
----									PUBLIC METHODS											----
----------------------------------------------------------------------------------------------------

--- Register a map object so that an interface will be created from it. 
-- @param map - The map object. 
function register(map)

	if ui then
	
		map:addObjectListener("UILabel", onLabelObject)
		map:addObjectListener("UIButton", onButtonObject)
		map:addObjectListener("UIWebPopup", onWebPopupObject)
		map:addObjectListener("UITextField", onTextField)
		map:addObjectListener("UITextBox", onTextBox)
		map:addObjectListener("UIText", onText)
		
	end
	
end

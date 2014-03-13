Lime2DTileEngine
================

Lime is a 2D engine for making tile-based games with Corona SDK and Tiled (tile map editor).

Original Author: Graham Ranson of Glitch Games 
  
	http://glitchgames.co.uk


Lime was released as open-source under the MIT License in April 2013, and is currently being
overseen by Outlaw Game Tools. Copyright 2013 Three Ring Ranch.
	
	http://ThreeRingRanch.com
	http://OutlawGameTools.com


! ! ! W A R N I NG ! ! !

Lime is in a state where it will be *very* (I can't stress that enough) frustrating to anyone but an intermediate-advanced Corona dev. Beginners should steer clear of it. The changes made to the Corona framework in the last several months have made Lime unusable without at least some tweaking.

Lime was first, but there are now other tiling engines that have more features and are faster in operation. MTE (Million Tile Engine) is cheap, full-featured, and fast. Check it out of you want a tiling engine to use, not work on.



Usage (yes, I know this isn't enough - it's coming):

1. Copy the lime folder into your project. 
2. Copy the corona 1.0 sprite library shim sprite.lua into your project from https://github.com/coronalabs/framework-sprite-legacy
2. Then use this in your main.lua file:  `lime = require("lime")` NOTE: The lime variable must be global, not local.


Original Lime tutorials can be found here:
http://lime.outlawgametools.com/tutorials-3/

Updated versions will be added to [the wiki](https://github.com/anthonymoralez/Lime2DTileEngine/wiki)


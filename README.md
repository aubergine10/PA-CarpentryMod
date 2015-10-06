# Carpentry Mod

Features:

* Adds **"Carpentry" room** that's dedicated to woodwork
* Adds **"Carpentry Saw"** - cheaper than workshop saw but only cuts wood
* Ability to **impose an embargoes** on log and/or wood exports
 * The buttons to toggle embargoes can be found on Staff menu
 * Embargoed resources = more carpentry work = more profits
 * Foreman 'holds' the embargo details, see his tooltip for details
* **Trees are ordered in stacks** - no more single-tree deliveries!

## Credits

This mod is a fork of Trixi's ["Improved Workshop" mod](http://steamcommunity.com/sharedfiles/filedetails/?id=514236957). Trixi did all the hard work developing the features, sprites, etc., so all credit to him! All I did was refactor the mod.

This mod has following major changes from the original:

* Rebranded as Carpentry Mod
 * NOT compatible with original mod :(
* Extensively optimised scripts
* Foreman script now does most of the processing
* Several scripts no longer required and removed:
 * Log2.lua, Wood2.lua, Stack.lua - removed
 * Log.lua, Wood.lua - simplified
* Several objects renamed and sprites altered

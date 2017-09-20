Knytt Stories Extended Version v1.5.9
By Sergey Rozhenko <mailto:sergroj@mail.ru>
https://sites.google.com/site/sergroj/ks/

The goal of this mod is to introduce many new possibilities, while keeping gameplay of levels made for original KS exactly the same. This means that many gameplay corrections are optional and should be explicitly enabled in new levels.
Level Editor Ex is based on Looki's Level Editor Mod.

----- New World.ini values -----
Even when making a level for original KS it would still be a good idea to turn on a few fixes in KS Ex. Add this to World.ini file:
[KS Ex]
ScreenScrollDetectionDelta=0
NoStuckUmbrella=True
NoLoadScreenDelay=True

You can also add some of these options there:
AllowMap=True
MusicLoops=0
NoWalkOnAir=True
NoFishInWalls=True
FixCutscenes=True
BouncingBallMode=True
VVVVVVMode=True
Font=Clean

When making a level with Script.lua for KS Ex you should add this line:
Need Script=True

----- Object Templates -----
Object templates are like an advanced version of custom objects. Here are two reasons to use templates instead of custom objects:
[*] They can be made solid or dangerous for player.
[*] They are shown immediately as they are created. Custom objects are shown with a delay of 1 tick (or maybe more). This is important with NoLoadScreenDelay=true, because then you'll see no flickering when you use object templates.
There is one reason not to use them instead of custom objects:
[*] Custom objects take less CPU time to create on screen than any other kind of object, this matters if there's a lot of COs on screen.
A programmer can do a lot of stuff with object templates. You can see some of it in the example level.
A tool to convert custom objects into template objects can be found on my site.
More info is available in this thread: http://nifflas.lpchip.nl/index.php?topic=5017

----- Bank 0, Obj 32 - No Wall Swim object -----
It is designed to prevent wallswims in some harder situations, like slopes going from one screen to another. It works by adding necessary solid tiles from some of surrounding screens to the scene. This takes time, so don't use it if there's no need for it. Here are some usage examples:
1) Place it on the right side of the screen to prevent wallswims when going right.
2) Place it in the bottom-right corner to prevent wallswims when going right and down.
3) If you want to prevent wallswims on all 4 sides of the screen you can place the object somewhere in the middle of the screen. Otherwise you can place more than one object if you want to prevent wallswims for 2 or 3 screens.

----- Map -----
"AllowMap = true" in your Script.lua or [KS Ex] section of world.ini or Data\UserScript.lua would enable the map to be shown when you hold the M key.
Level that use warps and shifts can still make the map coherent by using map commands. See "Knytt Stories Ex Readme Map.txt" for more information.

----- Controls -----
You can change controls in Data\UserScript.lua. Here are default controls:
Controls.Left = "LEFT"
Controls.Right = "RIGHT"
Controls.Up = "UP"
Controls.Down = "DOWN"
Controls.Walk = "A"
Controls.Jump = "S"
Controls.Umbrella = "D"
Controls.ItemList = "Q"
Controls.Hologram = "W"
Controls.ScrollUp = "PRIOR"
Controls.ScrollDown = "NEXT"
Controls.ScrollHome = "HOME"
Controls.ScrollEnd = "END"
Controls.Map = "M"
Controls.LastShot = 219  -- "["
Controls.NextShot = 221  -- "]"


----- Changelog -----

Version 1.0 changes:

Game:
[+] Lua
[+] May set quick death without white flash
[+] F2 works in full screen
[+] Fullscreen is available when KS is started from editor
[+] Previous/Next page buttons react double clicks and repeat if you hold them, Left/Right arrows scroll the levels now
[+] Play button in Install Level dialog
[+] Ctrl+M sets music on/off
[+] Shifts with cutscenes and without Autosave flag now don't return you to the last save point if FixCutscenes is set to 'true' by Script.lua
[-] Scrolling (going to new screen) right or down didn't occur if the player is 1 pixel outside the screen, 2 pixels were required (now this change is activated by setting "ScreenScrollDetectionDelta" to 0)

Editor:
[+] List of objects, you can scroll it by clicking an object and holding the left button
[+] Now World.ini is automatically reloaded when it is changed by an external program (that is, by 3rd Party Tools)
[-] Ctrl+R didn't reload World.ini if the editor is invisible
[-] When KS is in full screen mode the editor no longer reacts clicks and no longer gets resized
[-] If KS Executable contained space, wrong executable could have been called by Test Level.


Version 1.1 changes:

Game:
[+] Animals don't walk on air if you call NoWalkOnAir() from your script
[+] Fish don't swim through walls if you call NoFishInWalls() from your script
[+] Signs of any length can be read using Page Up, Page Down, Home and End buttons to scroll them
[-] My bugs: Fixed screen edge glitches of ball mode
[-] My bug: Springs and direction-tracking monsters didn't work in ball mode
[-] Ctrl+S and F2 sometimes didn't work in full screen mode
[*] The change to scrolling from v1.0 disabled by default and only would take place if "ScreenScrollDetectionDelta = 0" is added to the script

Editor:
[+] Level -> Script menu item opens Script.lua
[-] Editor reacted Ctrl+C, Ctrl+S, Ctrl+V even if it's not focused.
[-] My bug: After using Reset or Reload, object list was scrolled by 2, then by 3 and so on.
[-] My bug: "Executable=Knytt Stories Ex.exe" was added to DefaultSavegame.ini on world opening.
[-] Backup of World.ini was placed into world folder when the world is loaded, thus changing the folder Date. Now it's placed there only when World.ini is changed.
[-] EditorSettings.temp was placed into world folder when the world is loaded, thus changing the folder Date.
[-] If Tileset B was selected and the tile (0,0) of tileset was inside selection, Tileset A was used instead for painting.


Version 1.1.1 changes:

Game:
[+] "Version" variable added to Lua.
[-] My bug: Sometimes signs displayed wrong text. I hope it's fixed now.

Editor:
[+] Ctrl+Q shortcut for KSManager (current screen).
[-] Some keys were reacting presses when KS Editor isn't focused.
[-] My bug: Level -> Script menu item didn't work correctly.
[-] Undo shortcut (Ctrl+Z) didn't work sometimes.


Version 1.1.2 changes:

Game:
[+] Files with *.lua extension are allowed in compressed levels.

Editor:
[+] Files with *.lua extension are included in compressed levels.


Version 1.2 changes:

Game:
[+] Keyboard shortcuts. Most menu buttons have their first letter as a shortcut. Levels in levels list are chosen by pressing buttons '1' to '8'. Save slots are chosen by pressing buttons '1' to '3'. 'Play', 'Start a new game' and 'Load game' have the right arrow as additional shortcut. Additional shortcut for 'Back' is BackSpace.
[+] Set Format=3 in World.ini to make a map require KS Ex (version 1.2 or higher).
[+] Set FormatEx in World.ini to make a map require a specific KS Ex version (or higher). For version 1.2 the FormatEx is 120, for 1.3 it is 130.
[+] Ball mode: improved wall bouncing, flying sound added.
[-] Diagonal scrolling now works correctly with warps. (incomplete fix appeared in 1.1, but wasn't fully working)

Editor:
[+] "Screen -> Hide error messages" menu item added that disables errors that inform of transparent tilesets, invalid music etc.
[-] My bug: if a level without EditorSettings.temp file was opened and "Test Level" was used, the next time the level was opened at position x0y0.
[-] World editor was catching Ctrl+Z, Ctrl+V shortcuts, thus messing things up.


Version 1.3 changes:

Game:
[+] Improved ball mode. Now with ball graphics and slopes/edges detection.
[+] VVVVVV mode.
[+] Reworked objects templates. Now they can have animation, may kill player or be solid. Now they can be used much like custom objects in Level Editor.
[+] Text objects added. You can use text of any color, use any custom font.
[+] Bank 0, Obj 32 - No Wall Swim object.
[+] All graphics can be changed.
[+] Music can now be turned on/off from within the menu, not just with a shortcut.
[+] Music can loop in a level. Add "MusicLoops = 0" to Script.lua for it. There is also an event "MusicLoops", so you can choose where it should loop.
[+] Setting "NoLoadScreenDelay = true" would remove the 1 tick delay that happens after screen tiles are rendered, but before objects are created. However, in object-intensive screens combined time to load tiles and objects becomes too big, so you may want to turn it on and off in BeforeLoadScreen event.
[+] Sorting by date, search and page buttons in level selection screen. Page buttons can be turned off by setting "No Level Page Numbers=1" in Data\settings.ini.
[+] Clickable links in Credits, a list of links for "Get More Levels" button.
[+] "Level Editor" button instead of "About MMF". "About MMF" is still accessible from Credits.
[+] You can set Permanent value to 1 for objects to make them persist between screens.
[+] Cheat improvements. You can now teleport between screens, save, turn powers on/off and turn ball mode on/off (in regular levels).
[-] After removing Detector or Hologram powers they still were on.
[-] Set "NoStuckUmbrella = true" to prevent umbrella from getting stuck on if it's shifted off while in use.
[-] egomassive's fix for objects facing bug is applied, see http://nifflas.lpchip.nl/index.php?topic=4648.0
[-] Music wasn't playing after cutscenes, see http://nifflas.lpchip.nl/index.php?topic=4744.0
[-] Worlds directory subfolders without World.ini are no longer listed as levels.
[-] Now Juni will no longer briefly appear in her old position when shifting to a new relative position on a new screen.
[-] Bank 17, Obj 1 used to redirect bullets of Bank 4, Obj 12.
[-] My bug: Big "vars" table couldn't be saved.
[-] My bug: Strings containing new line character couldn't be saved in "vars" table properly.
[-] My bug: object:LoadFrame ignored frame number.
[-] My bug: hologram wasn't exported correctly.
[-] My bug: slow screen loading if "NeedObjects = true".
[*] Backward incompatibility: hot spot of object templates is set to the middle of square, not top-left corner.

Editor:
[+] Full set of object icons for bank 255 in the original style.
[+] Now pressing Ctrl+arrow moves the view by 100.
[+] Author field for New Level is remembered.
[+] Other small things like Alt+F2 shortcut for Reset and double click reaction for minimap.
[*] When "Show custom objects" option is active, objects graphics is shown together with object index icon.
[-] There was a major slowdown when going from screen to screen in big levels due to world.ini editor line searching. Some other performance improvements have been done.
[-] Ctrl+Del was causing corruption and crashes due to no check for workspace existence.
[-] Sometimes custom objects were cropped with "Show custom objects" option.


Version 1.3.1 changes:

Game:
[-] Permanent objects were destroyed with player's death if Game.WhiteDeathDelay isn't 0.

Editor:
[-] Version 1.3 worked with big worlds very slowly.


Version 1.4 changes:

Game:
[+] Improved VVVVVV mode.
[+] You can take screenshots with Print Screen key and then view them with "[" and "]" keys. The savegame also stores coordinates of screens where the shots were taken.
[+] Map. Add "AllowMap = true" to Data\UserScript.lua and then you'll see the map when you hold M key.
[+] Lua functions for power icons manipulation (AddPower, RemovePower) and keys presses (OnKeyPress).
[-] My bug: Some objects behaved incorrectly with "NoLoadScreenDelay = true".
[-] My bug: Setting some values of Platform object didn't work.


Version 1.4.1 changes:

Game:
[+] Ball mode: support for moving platforms.
[+] Added "Fixed Params Count" parameter for templates objects.
[-] My bug: Bank 18 Obj 6 and Bank 17 Obj 3 objects behaved incorrectly with "NoLoadScreenDelay = true".
[-] My bug: Lua mouse events coordinates were wrong in fullscreen mode.

Editor:
[+] Find field on editor start now searches for names containing the text, not only starting with it.
[-] When minimized the editor consumed 100% CPU core time. (MMF2 bug)
[-] My bug: Objects list didn't work correctly sometimes.


Version 1.5 changes:

Game:
[+] New "Keep resolution in full screen" menu item to play the game in native monitor resolution, "Zoom" for windowed mode.
[+] Options menu added.
[+] High priority of game process, so background tasks won't spoil the gameplay.
[+] Now all sounds are stopped when KS is inactive.
[+] Ball mode: little air friction added, lower bounce when A is pressed, 45 degree slopes climbing, no more high jumps using corners, BouncingBallMode function accepts parameters now.
[+] Now you can drag & drop .knytt.bin files to install them while you're anywhere the menu screen.
[+] "Play" button in Install Level screen now leads directly to the installed level.
[+] Better looking map with ability to show unvisited places.
[+] Controls can be configured.
[+] Set "NoHologramDoubleDown = true" in Data\UserScript.lua to turn off triggering the Hologram when you press Down twice.
[+] New design of sign scroll arrows.
[+] egomassive's font for signs, Clean.png. It contains characters missing in original font. To use it add "Font=Clean" line to [KS Ex] section of World.ini.
[+] Support for gradients of any width.
[+] Lua: Now Script.lua is run when savegame data is already loaded.
[+] Lua: GetVAlign, SetVAlign, GetHAlign, SetHAlign for Text objects.
[+] Game.MusicVolume, Game.AmbianceVolumeA, Game.AmbianceVolumeB control music and ambiance volumes.
[+] Game.AmbiFadeSpeedA, Game.AmbiFadeSpeedB control ambiance fade speed.
[+] Faster screens switching. Note about scripting: one of the tricks used is turning a horizontal line of objects into one long object (e.g. this is done with sign areas). You may want to disable this in some case, to do so set "CombineObjects = false" in your script.
[+] Screens are always rendered in 1 step and objects are exported for Lua scripts ("NeedObjects" is ignored). "ShiftsDelay" variable controls the delay before shifts start working when you move to a new screen. "NoLoadScreenDelay" now only effects ShiftsDelay, reducing its default value from 1 to 0.
[-] If you go to a screen with different ambiance and then quickly go back the ambiance doesn't restart now.
[-] The music didn't stop when a fatal error message is shown.
[-] My bug: Some decorative objects (dust, leafs) behaved incorrectly with "NoLoadScreenDelay = true".
[*] Now map is only recorded when it is enabled or "RecordMap = true".

Editor:
[+] Adjacent screens previews.
[+] When you edit text of a sign in World.ini editor you see a preview of how it will look in the game.
[+] You can click on INI editor's margin near [x****y*****] to go to corresponding screen.
[+] Music and Ambients play buttons are now toggled by click.
[+] "Run Knytt Stories" menu item.
[+] Layer 3 is selected by default (can be changed by setting "Default Layer" in Worlds\EditorSettings.temp).
[+] Less flashy selection marks (set "Standard Markers=1" in Worlds\EditorSettings.temp to get back to default).
[+] Exit/Reset warning.
[+] Bigger World.ini editor window.
[+] The editor selects the last edited level at start up.
[+] Set options "ResolutionX" and "ResolutionY" in "Worlds\EditorSettings.temp" to make the editor switch to that resolution while you're working with it.
[+] Almost no CPU usage when inactive.
[+] Scrolling objects list with mouse wheel.
[+] Support for gradients of any width.
[-] My bug: When clicking the tile under the objects list, the list was scrolled.
[-] Hiding layers in an empty screen caused the contents of the last visited non-empty screen to be pasted.
[-] Level -> Script menu item didn't work sometimes.


Version 1.5.1 changes:

Game:
[+] Prettier pick up light. It's smoother now, but there's a chance you won't notice it. In an unlikely case you want to get the standard pick up light back, add "OriginalPickUpLight = true" line to Data\UserScript.lua.
[+] ReplaceSound(SndID) event lets you replace most important standard sounds. Set ReplaceSound variable to desired sound name in event handler.
[+] obj:GetSpeed, obj:SetSpeed methods control speed of standard moving objects. Use SetSpeed together with obj:SetDirection, obj:LookAt(x, y) or obj:LookAt(obj2).
[+] GetDeceleration, SetDeceleration, GetGravity, SetGravity methods control corresponding values of standard objects that support them.
[+] ObjectMovement(obj) function performs object movement according to parameters obj.SpeedX, obj.SpeedY, obj.AccelX, obj.AccelY, obj.Deceleration. It sould be called from a timer.
[+] ObjectBounce(obj) function makes an object bounce off solid tiles according to parameters obj.BounceMul, obj.BounceFriction. It sould be called from a timer after ObjectMovement.
[+] Other functions for object AI: ObjectDestroyTooFar, ObjectAnimateDestroy, ObjectFadeDestroy, GetDistance, SpeedInDirection.
[-] My bug: Some objects behaved incorrectly in version 1.5.
[-] My bug: In ball mode slopes detection didn't work with solid template objects.

Editor:
[-] Flood-fill (Shift+click) didn't work for Tileset B.


Version 1.5.2 changes:

Game:
[-] My bug: in 1.5.1 removing events in Lua from inside of them was causing an error.
[-] My bug: ObjectDestroyTooFar was incorrect.


Version 1.5.3 changes:

Game:
[+] Cyrillic font added. To use it add "Font=Russian" line to [KS Ex] section of World.ini. Note: you can use your own font and put it into WorldPath\Fonts\ folder.
[+] Add "DefaultFont = 'Clean'" line to Data\UserScript.lua to use the Clean font by default.
[+] GraphicsOverlay function lets you create new objects that use standard objects logic.
[-] My bug: Removing events could lead to slight misbehavior in previous versions.
[*] ReplaceHologramGraphics now doesn't change existing hologram and waits for the new one to be created instead.

Editor:
[+] Support of KS+ levels (that is, a message saying that you should download KS+).
[+] Signs font setup ([KS Ex] Font) is supported.


Version 1.5.4 changes:

Game:
[+] Support for animations with Delay value below 1.
[-] Custom objects were leaking resources, causing bugs after a period of playing.

Editor:
[+] Automatic template Objects (Bank 254) creation from current view of the screen (with or without background gradient). This lets you layer a picture made of tiles on top of Juni for example. Choose an unused Template object and you'll see a camera button to the right of Object selector.
[+] Simple 1-frame custom objects (Bank 255) are displayed in objects list.
[-] With big World.ini saving was slowed down.


Version 1.5.5 changes:

Game:
[+] Support for collectable items with quantity.
[+] New events: CanShift(shift_id), CanShiftA, CanShiftB, CanShiftC - called when shift is triggered and can set CanShift variable to "false" to prevent the shift.
[+] New forms of events: "x1000y1000warp" and "NewTemplate1", here "1" is template number and x1000y1000 are screen coordinates.


Version 1.5.6 changes:

Game:
[+] Support for golden creatures (new gold dust child object and various fixes).

Editor:
[+] Adding template objects easily with the "+" button near template index field.
[*] Template object icons for objects 201 to 255 removed, because they shouldn't be used.


Version 1.5.7 changes:

Game:
[+] Custom map colors support.
[+] Lua: FindTemplateOverlap to speed up template objects.
[+] "KS Ex Ignore" parameter of custom objects that makes KS Ex ignore them (useful for levels that should run both on KS Ex and normal KS if you change custom objects into template objects for KS Ex).
[-] GraphicsOverlay function didn't remove DrawFrame event causing slowdown after many calls.

Editor:
[+] Now template/custom objects badges are semi-transparent when "Show custom objects" menu item is on.


Version 1.5.8 changes:

Game:
[-] My bug: "Could not call user-defined destroy callback" occurring in slow death animation mode.
[-] My bug: Gold dust wasn't fully controllable from Lua.


Version 1.5.9 changes:

Game:
[+] Ball mode: If you hold Left or Right key, touch a wall and fully decelerate horizontally, you aren't pushed after you release the key anymore. BouncingBall.NoWallBounceSpeed parameter is added for this.
[+] Cheat: When cheats are enabled, pressing Space and Map key (M by default) and left clicking on a map will teleport to the clicked position.
[-] Level selection menu reacted to key presses when not focused.
[*] Better ShiftsDelay handling. Now during the delay shifts are triggered, but reaction is postponed.

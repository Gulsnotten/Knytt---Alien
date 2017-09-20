There are 4 map commands: hide, move, show, color.

"hide" simply disables the map on selected square and doesn't show the square on map when you move to other squares. Example: "x1000y1000 hide".

"move" moves a square to another virtual location. For example, if your level has a shift-based boss fight or animation, you can make all screens of animation appear as a single screen on the map by moving them all to the same location. Example: "x1000y1000 move x2000y2000" would move x1000y1000 to x2000y2000 on the map.

"show" shows view from square #2 underneath current view when you are in the square #1. For example, if your world warps like Mashu Prappa (when you go all the way right you appear on the left side of the world), you can show view from the left side of the world when you are on the right side of it and vise versa. In The Machine you would show the dark map underneath colorful map when the machine is off, so it looks like the map is being recolored as you go.

"color" sets custom color for map square. The color is set as 3 values - red, green and blue. Example: "x1000y1000 color 255 0 0" would set intense red color for the square.

All commands may operate on rectangular areas of squares instead of one square: "x0y0-x10y10 move x100y100" would mean 11 by 11 rectangle [x0y0, x10y10] would be moved so that x0y0 would become x100y100.

Note that the game always executes all "hide" commands first, then it executes all "move" commands and then all "show" and "color" commands.
You can invoke map commands from your Script.lua file or from [Map] section of world.ini.

As an example, here is Script.lua to show good map in The Machine:

MapCommand{
	-- show Normal in Easy
	"x979y993-x1040y1008 show x979y1013",
	-- show Easy in Normal
	"x979y1013-x1040y1028 show x979y993",
	-- machine off segment: move away from main map, show main map underneath
	"x979y1015-x997y1017  move x979y915",
	"x979y915-x997y917  show x983y1019",
	"x979y915-x997y917  show x983y999",
	"x975y1018-x980y1024  move x975y918",
	"x975y918-x980y924  show x979y1022",
	"x975y918-x980y924  show x979y1002",
	-- game end segment: hide it
	"x1001y1009-x1002y1010  hide",
	--"x1001y1009-x1002y1010  move x1000y950",
	-- blue key segment: move away from main map, show main map underneath
	"x1016y1013-x1021y1013  move x1016y913",
	"x1021y913-x1016y913  show x1021y1017",
}

And here is the same thing as a world.ini section:

[Map]
; show Normal in Easy
1=x979y993-x1040y1008  show x979y1013
; show Easy in Normal
2=x979y1013-x1040y1028  show x979y993
; machine off segment: move away from main map, show main map underneath
3=x979y1015-x997y1017  move x979y915
4=x979y915-x997y917  show x983y1019
5=x979y915-x997y917  show x983y999
6=x975y1018-x980y1024  move x975y918
7=x975y918-x980y924  show x979y1022
8=x975y918-x980y924  show x979y1002
; game end segment: hide it
9=x1001y1009-x1002y1010  hide",
; blue key segment: move away from main map, show main map underneath
10=x1016y1013-x1021y1013  move x1016y913
11=x1021y913-x1016y913  show x1021y1017


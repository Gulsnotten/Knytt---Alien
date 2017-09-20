--[[--------------------------------------------------------------------------------------------------------------

Danger Marker

Script for object frames replacement by Sergey "GrayFace" Rozhenko

--]]--------------------------------------------------------------------------------------------------------------

local Path = path.dir(debug.FunctionFile(1))

ReplaceGraphics({
	BaseIndex = 1,
	TransparentColor = 0,
	{HotSpotX = 10, HotSpotY = 10, ActionX = 0, ActionY = 0},
	Path.."Danger Marker_0_stopped_1.png",
	Path.."Danger Marker_0_stopped_2.png",
	Path.."Danger Marker_0_stopped_3.png",
	Path.."Danger Marker_0_walking_1.png",
	Path.."Danger Marker_0_walking_2.png",
	Path.."Danger Marker_0_walking_3.png",
}, Objects.DangerMarker)

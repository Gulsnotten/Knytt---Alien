--[[--------------------------------------------------------------------------------------------------------------

Secrets Marker

Script for object frames replacement by Sergey "GrayFace" Rozhenko

--]]--------------------------------------------------------------------------------------------------------------

local Path = path.dir(debug.FunctionFile(1))

ReplaceGraphics({
	BaseIndex = 1,
	TransparentColor = 0,
	{HotSpotX = 10, HotSpotY = 10, ActionX = 0, ActionY = 0},
	Path.."Blue Marker_0_stopped_1.png",
	Path.."Blue Marker_0_stopped_2.png",
	Path.."Blue Marker_0_stopped_3.png",
	Path.."Blue Marker_16_stopped_1.png",
	Path.."Blue Marker_16_stopped_2.png",
	Path.."Blue Marker_16_stopped_3.png",
}, Objects.SecretsMarker)

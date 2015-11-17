require("app/model/cWorld")

local scheduler = require(cc.PACKAGE_NAME .. ".scheduler") --加载定时器
local GuideHelper = import("app/ui/GuideHelper")

local CHANGE_GUNS_INTERVAL = 3.0

local SceneBaseClass = import("app/scenes/SceneBaseClass")

local NewSceneChoiceMission = class("NewSceneChoiceMission", SceneBaseClass)


function NewSceneChoiceMission:onCreate()

end

function NewSceneChoiceMission:onEnter()
	local uiManager = MyApp.uiManager
	if uiManager == nil then
		return
	end
    uiManager:showUI( "UIChoiceMission", true, callback )
end

function NewSceneChoiceMission:onExit()

end

function NewSceneChoiceMission:update( dt )

end

return NewSceneChoiceMission
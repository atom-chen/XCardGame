local SceneManager = class("SceneManager")

function SceneManager:ctor()
	self.curScene = nil;
end

function SceneManager:getInstance()
	if _G.__SceneManager == nil then
		_G.__SceneManager = SceneManager:new();
	end
	return _G.__SceneManager;
end

function SceneManager:enterScene( sceneName, args, transitionType, time, more)
    local uiManager = MyApp.uiManager
    local sceneClass = require(string.format("app/scenes/%s", sceneName))
    if sceneClass ~= nil and uiManager ~= nil then
        if self.curScene ~= nil then
            uiManager:closeAllUI()
            uiManager:destoryAllUI()
        end
    	local scene = sceneClass:new()
    	if scene ~= nil then
            local sceneRoot = display.newScene( sceneName );
            if sceneRoot ~= nil then
                scene:setSceneRoot( sceneRoot );
                scene:onCreate( unpack(checktable(args)) );
                scene.name = sceneName
                self.curScene = scene
        		display.replaceScene( sceneRoot, transitionType, time, more)
            end
    	end
        Factory.clearUnitPool()   
        if DEBUG_INFO_PANEL == true then
            uiManager:showUI( "UIDebugInfoPanel" )
        end    
    end
end

function SceneManager:getCurScene()
	return self.curScene
end

return SceneManager

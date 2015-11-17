
local SceneBaseClass = class( "SceneBaseClass" )

function SceneBaseClass:ctor()
	self.sceneRoot = nil
	self.uiLayer = nil
	self.gameLayer = nil
	self.name = name
end

function SceneBaseClass:setSceneRoot( sceneRoot )
    sceneRoot.onEnter = 
    function( ... )
    	self:onEnter( ... )
    end
    sceneRoot.onExit = 
    function( ... )
    	self:onExit( ... )
    end
    sceneRoot.onEnterTransitionDidFinish =
    function( ... )
    	self:onEnterTransitionDidFinish( ... )
    end
    local uiLayer = CCLayer:create()
   	if uiLayer ~= nil then
	   	self.uiLayer = uiLayer
	   	sceneRoot:addChild( uiLayer, 10 )
	end
	local gameLayer = CCLayer:create()
	if gameLayer ~= nil then
	   	sceneRoot:addChild( gameLayer, 1 )
	   	self.gameLayer = gameLayer
	end
	self.sceneRoot = sceneRoot
end

function SceneBaseClass:getSceneRoot()
	return self.sceneRoot
end

function SceneBaseClass:getUILayer()
	return self.uiLayer
end

function SceneBaseClass:getGameLayer()
	return self.gameLayer
end

function SceneBaseClass:addChild( node, zorder, tag )
	if self.sceneRoot ~= nil then
		self.sceneRoot:addChild( node, 1, 1 )
	end
end

function SceneBaseClass:scheduleUpdate()
	if self.sceneRoot ~= nil then
		self.sceneRoot:scheduleUpdate();
	end
end

function SceneBaseClass:unscheduleUpdate()
	if self.sceneRoot ~= nil then
		self.sceneRoot:unscheduleUpdate()
	end
end

function SceneBaseClass:addNodeEventListener( ... )
	if self.sceneRoot ~= nil then
		self.sceneRoot:addNodeEventListener( ... )
	end
end

function SceneBaseClass:convertToNodeSpace( ... )
	if self.sceneRoot ~= nil then
		return self.sceneRoot:convertToNodeSpace( ... )
	end
end

function SceneBaseClass:runAction( ... )
	if self.sceneRoot ~= nil then
		self.sceneRoot:runAction( ... )
	end
end

return SceneBaseClass;
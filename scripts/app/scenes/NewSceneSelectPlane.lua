require("app/model/cWorld")

local scheduler = require(cc.PACKAGE_NAME .. ".scheduler") --加载定时器
local GuideHelper = import("app/ui/GuideHelper")

local CHANGE_GUNS_INTERVAL = 3.0

local SceneBaseClass = import("app/scenes/SceneBaseClass")

local NewSceneSelectPlane = class("NewSceneSelectPlane", SceneBaseClass)


function NewSceneSelectPlane:onCreate()
	self.showPlane = nil
	self.showGunLevel = 1
end

function NewSceneSelectPlane:onEnter()
	Factory.clearUnitPool()
	local uiManager = MyApp.uiManager
    local function callback()
    	local uiSelectPlane = uiManager:getUIByName( "UISelectPlane" )
	    if uiSelectPlane ~= nil then
	    	local showPlaneNode = uiSelectPlane:seekNodeByPath( "showPlaneNode" )
	    	if showPlaneNode ~= nil then
			    self.world = cWorld.new( showPlaneNode, nil, 69999 )
			    self.world:onEnter()
			    local tBgs = self.world:getUnitsByGroup( UG_BG )
			    if tBgs ~= nil then
			    	for i, v in ipairs( tBgs ) do
			    		v.view:setVisible( false )
			    	end
			    end
			    showPlaneNode:setPosition( CCPoint( 0, 150 ) )
			    uiSelectPlane:updateWingmanInfo()
			    uiSelectPlane:updateFuncLayer2UI()
			end
		end
    end
    uiManager:showUI( "UISelectPlane", true, callback )
	-- 启动帧侦听
   	self:scheduleUpdate()  
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function( dt ) self:update(dt) end)    
    self.handle_CHANGE_GUNS = scheduler.scheduleGlobal(function(dt) self:onUpdatePlaneGuns(dt) end, CHANGE_GUNS_INTERVAL)
end

function NewSceneSelectPlane:onExit()
	scheduler.unscheduleGlobal(self.handle_CHANGE_GUNS)
	self:unscheduleUpdate()
end

function NewSceneSelectPlane:update( dt )
	if dt > 0.02 then dt = 0.02 end
	self.world:update( dt )
	if app.uiManager ~= nil and app.uiManager.update ~= nil then
		app.uiManager:update( dt )
	end
end

function NewSceneSelectPlane:onUpdatePlaneGuns(dt)
	local uiManager = app.uiManager
    local plane = self.world.plane
    if plane ~= nil and uiManager ~= nil then
    	local uiSelectPlane = uiManager:getUIByName( "UISelectPlane" )
    	if uiSelectPlane ~= nil then
    		if uiSelectPlane.curShowFuncLayerIdx == 1 then
    			return
    		end
	    	if self.showGunLevel ~= nil then
	    		self.showGunLevel = self.showGunLevel + 1
	    		if self.showGunLevel > 4 then
	    			self.showGunLevel = 1
	    		end
	    		plane:changeGuns( self.showGunLevel )
	    	end
	        if self.showGunLevel == 4 then
		        local props = app.propsData[PROPS_TYPE_FULL_POWER]
		   		if props ~= nil then
		   			plane:enterFullPower( 3.0, false, props )
		   		end
		   	end
		end
    end
end

return NewSceneSelectPlane
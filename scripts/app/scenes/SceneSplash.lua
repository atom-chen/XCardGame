local StepLoading = import("app/ui/StepLoading")
local SceneBaseClass = import("app/scenes/SceneBaseClass")

local SceneSplash = class("SceneSplash", SceneBaseClass )

function SceneSplash:onCreate()
    self.uiGame = nil
end

function SceneSplash:onEnter()
    local logoPng = cc.Sprite:create( "icon.png" )
    if logoPng ~= nil then
    	local actionFadeIn = CCFadeIn:create(1)
    	local actionFadeOut = CCFadeOut:create(2.5)
    	local array = CCArray:create()
    	local callback = CCCallFunc:create( function() 
    											self:stepload()
    										end)
    	array:addObject(actionFadeIn)
    	array:addObject(actionFadeOut)
    	array:addObject(callback)
    	local sequence = CCSequence:create( array )
    	logoPng:setPosition( CCPoint( display.width/ 2, display.height/2) )
    	logoPng:setOpacity( 0 )
    	logoPng:runAction( sequence )
    	self:addChild( logoPng )
    end
end

function SceneSplash:stepload()
	audio.loadSwitch()
	local steps = 
    {
        SceneSplash.stepSound,
        SceneSplash.stepMusic,
        SceneSplash.stepConfig,
        SceneSplash.stepProps,
        SceneSplash.stepPlane,
        SceneSplash.stepPList,
    }

    local layer = StepLoading.new(self, steps, SceneSplash.stepFinish)
    self.uiGame = layer
    self:addChild(layer)
end

function SceneSplash:onExit()
    if self.uiGame then
        self.uiGame:removeFromParent(true)
        self.uiGame = nil
    end
end

function SceneSplash:stepSound(step)
    local kv = StepLoading.lookupTable(GAME_SFX, step.progress)
    if kv then
        audio.preloadSound(kv.value)
        step:gotoNext()
        return false
    end

    return true
end

function SceneSplash:stepMusic(step)
    local kv = StepLoading.lookupTable(GAME_MUSIC, step.progress)
    if kv then
        audio.preloadMusic(kv.value)
        step:gotoNext()
        return false
    end

    return true
end

function SceneSplash:stepConfig(step)

	local result = CfgData.stepLoad(step.progress)
    if not result then
        step:gotoNext()
    end

    return result
end

function SceneSplash:stepProps(step)
    app:initProps()
    app:loadProps()

    app:loadLoginData()
    app:loadGuide()
    app:loadMissionData()
    app:loadItemsData()
    app:loadAchiveData()
    app:loadIFreeLottery()
    app:loadTechData()
    return true
end

function SceneSplash:stepPlane(step)
    if not app:loadPlaneData() then
        app:initPlaneData()
    end
    if not app:loadWingmanData() then
        app:initWingmanData()
    end
    return true
end

function SceneSplash:stepPList(step)
    local kv = StepLoading.lookupTable(CFG_FILE_NAMES, step.progress)
    if kv then
        local plist = kv.value
        local png = string.gsub(plist, ".plist", ".png")
        --TODO("addSpriteFrames", plist)
        display.addSpriteFramesWithFile(plist, png, function() 
            step:gotoNext()
        end)

        return false
    end

    return true
end

function SceneSplash:stepFinish()
    app:enterSelectPlane()
    app:setLanguage( CONFIG_GAME_LANGUAGE )
    app.uiManager:initControlStrMap()
    app.techMgr:init()
    return true
end

return SceneSplash

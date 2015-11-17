local sharedSpriteFrameCache = CCSpriteFrameCache:sharedSpriteFrameCache()

local StepLoading = class("StepLoading", function() return display.newLayer() end)

function StepLoading:ctor(target, STEPS, finish, jsonUI)

    self.paused = false
    self.step = 1
    self.progress = 1
    self.target = target
    self.STEPS = STEPS
    self.finish = finish
    
    self:pos(0, 0)
    self:setContentSize(CCSize(display.width, display.height))

    self:setTouchSwallowEnabled(true)
    self:setTouchEnabled(true)
    self:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)
    
    self:scheduleUpdate()  
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function( dt ) self:update(dt) end)    

    if not jsonUI then 
        jsonUI = "res/ui/waitLoading.json"
    end
	local ui, width, height = cc.uiloader:load(jsonUI)
    if not ui then
        return 
    end
    self:addChild(ui)

end

function StepLoading:update(dt)
    if self.paused then
        return 
    end

    local stepUpdate = self.STEPS[self.step]
    if stepUpdate then
        --Logger.warn("Loading step = " .. self.step .. ", progress = " .. self.progress)

        self.paused = true
        local result = stepUpdate(self.target, self)
        if result then
            self.paused = false
            self.step = self.step + 1
            self.progress = 1
        end
    else
        if self.finish then
            self.paused = true
            self.finish(self.target, self)
            self.finish = nil
        end
    end
end

function StepLoading:gotoNext()
    self.paused = false
    self.progress = self.progress + 1
end

function StepLoading.lookupTable(t, index)
    local i = 1
    for k, v in pairs(t) do
        if i == index then
            return {key= k,value = v}
        end
        i = i + 1
    end

    return nil
end

function StepLoading.createSprite(plist, pngtexture, fps)
    local frames = {}

   	local frameNames = sharedSpriteFrameCache:addSpriteFramesWithFile(plist, pngtexture) -- 载入图像到帧缓存 
	for _, frameName in ipairs(frameNames) do
		local frame = display.newSpriteFrame(frameName)
		table.insert(frames, frame)
	end

    if (fps or 0) <= 0 then fps = 16.0 end

 	local sp = display.newSprite("#" .. frameNames[1])
	local animation = display.newAnimation(frames, 1.0 / fps)
    sp:playAnimationForever(animation, 0)

	return sp
end

function StepLoading.createArmature(skeleton, armatureName)
    local manager = CCArmatureDataManager:sharedArmatureDataManager()
	manager:addArmatureFileInfo(skeleton)

    local armature = CCArmature:create(armatureName)
	return armature
end

return StepLoading

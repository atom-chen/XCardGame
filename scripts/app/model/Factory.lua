
local _tinsert = table.insert
local _tremove = table.remove
local sharedSpriteFrameCache = CCSpriteFrameCache:sharedSpriteFrameCache()

Factory = {}


local unitPools = {}
local spCache = {}
local tBulletsCache={}
local tBulletsUnusedIdTable={}

gUnitCount = 0
local function _getUnitPool(cfgId, forceGet)
	local p = unitPools[cfgId]
	if not p and forceGet then
		p = {}
		unitPools[cfgId] = p
	end

	return p
end

function Factory.__createUnitByCfg(cfg, unit_type)
	local unit = unit_type.new(nil, nil)
	if unit:initByCfg(cfg) then
		return unit 
	end
	return nil
end

function Factory.__getUnit(cfgId, cfg_type, unit_type)
	local cfg = CfgData.getCfg(cfg_type, cfgId)
	if not cfg then
		return nil, nil
	end

	local pool = _getUnitPool(cfgId, true)
	local size = #pool

    local unit
    if size > 0 then
		unit = pool[size]
		_tremove(pool, size)
    else
		unit = Factory.__createUnitByCfg(cfg, unit_type)
	    if not unit then
		    return nil, nil
	    end

		gUnitCount = gUnitCount + 1
	end

	unit:playView()
	return unit, cfg
end

function Factory.getUnit(cfgId, score)
    local unit, cfg = Factory.__getUnit(cfgId, CFG_UNIT, cUnit)
    if unit and cfg then
	    unit.hp = cfg.hp
	    unit.maxHP = cfg.hp
	    unit.hurt = cfg.hurt
	    unit.score = score or 0
    end
    return unit
end


function Factory.isBulletCache( cfgId )
	return (tBulletsCache[cfgId] ~= nil)
end

function Factory.addBulletCacheId( cfgId )
	if tBulletsCache[cfgId] == nil then
		tBulletsCache[cfgId] = {}
		tBulletsUnusedIdTable[cfgId] = {}
		local cfg = CfgData.getCfg(CFG_UNIT, cfgId)
		if cfg ~= nil then
			for i = 1, 10 do
				local bullet = Factory.__createUnitByCfg(cfg, cUnit)
			  	if bullet ~= nil then
				    bullet.cacheIdx = i
					_tinsert( tBulletsCache[cfgId], bullet )
					_tinsert( tBulletsUnusedIdTable[cfgId], i )
				end
			end
		end
	end
end

function Factory.getUnusedBullect( cfgId )
	local tUnusedIdTable = tBulletsUnusedIdTable[cfgId]
	local tCache = tBulletsCache[cfgId]
	if tUnusedIdTable ~= nil and tCache ~= nil then
		if #tUnusedIdTable == 0 then
			local cfg = CfgData.getCfg(CFG_UNIT, cfgId)
			if cfg ~= nil then
				local bulletCacheCount = #tCache;
				for i = 1, 5 do
					local bullet = Factory.__createUnitByCfg( cfg, cUnit)
			  		if bullet ~= nil then
			  			bullet.hp = cfg.hp
			  			bullet.cacheIdx = bulletCacheCount + i
			  			_tinsert( tCache, bullet )
						_tinsert( tUnusedIdTable, bullet.cacheIdx )
			  		end
				end
			end
		end
		local bullet = tCache[tUnusedIdTable[1]]
		_tremove( tUnusedIdTable, 1 )
		return bullet
	end
end

function Factory.createPlaneById(planeId)
    local unit, cfg = Factory.__getUnit(planeId, CFG_UNIT, cPlane)
	return unit
end

function Factory.createItemById(cfgId)
    local unit, cfg = Factory.__getUnit(cfgId, CFG_ITEM, cItem)
    if unit then
	    unit.hp = 1
	    unit.hurt = 0
	    unit.score = 0
    end
	return unit
end

function Factory.putUnit(unit)
    if not unit then return end
    local cfgId = unit.cfgId
    if cfgId == nil then 
    	return 
    end
    if tBulletsCache[cfgId] ~= nil then
		local tUnusedIdTable= tBulletsUnusedIdTable[cfgId]
		local tCache = tBulletsCache[cfgId]
		if tUnusedIdTable ~= nil and tCache ~= nil then
			_tinsert( tUnusedIdTable, unit.cacheIdx )
		end
    	return
    end
	local pool = _getUnitPool(unit.cfgId, false)
	if pool then
		_tinsert(pool, unit)
    else
        unit:dtor()
	end
end

function Factory.clearUnitPool()

    gUnitCount = 0
    for _, pool in pairs(unitPools) do
        for _, unit in ipairs(pool) do
            unit:dtor()
            gUnitCount = gUnitCount + 1
        end
    end
	tBulletsCache={}
	tBulletsUnusedIdTable={}
 
    TODO("Factory.clearUnitPool()", gUnitCount)
    unitPools = {}
end

--end cUnit
----------------------------------------------------------------------------------------------------

function Factory.createGunById(gunId , ...)
	local cfg = CfgData.getCfg(CFG_GUN, gunId)
	if not cfg then
		return nil
	end	

	local gun = cGun.new(...)
	if gun:initByCfg(cfg) then
		return gun
	end

	return nil
end

function Factory.createAnim( animId, playOnce, removeWhenFinished, onComplete, delay )
	local cfg = CfgData.getCfg( CFG_ANIMATION, animId )
	if not cfg then
		return nil, nil
	end

	local anim = nil
	if cfg.type == 1 then
		anim = Factory.createDragonBounAnimById(cfg)
	elseif cfg.type == 2 then
		anim = Factory.createSprite(cfg, playOnce, removeWhenFinished, onComplete, delay)
	elseif cfg.type == 3 then
		anim = Factory.createArmature(cfg, playOnce, removeWhenFinished, onComplete, delay)
	end

	if not anim then
		return nil, nil
	end

	if cfg.scale > 0 then
		anim:setScale(cfg.scale)
	-- else
	-- 	anim:setScale(1)
	end


	if #cfg.RGB == 3 then
		anim:setColor(cc.c3(unpack(cfg.RGB)))
	end

	return anim, cfg
end

--创建ttflabel参数,str,字体,字号,对齐方式
--ui.TEXT_ALIGN_LEFT 左对齐
--ui.TEXT_ALIGN_CENTER 水平居中对齐
--ui.TEXT_ALIGN_RIGHT 右对齐
--ui.TEXT_VALIGN_TOP 垂直顶部对齐
--ui.TEXT_VALIGN_CENTER 垂直居中对齐
--ui.TEXT_VALIGN_BOTTOM 垂直底部对齐
function Factory.createTTFLabel(str,font,size,align,localX,localY)
		local label = ui.newTTFLabel({
	    text = str,
	    font = font,
	    size = size,
	    align = align -- 文字内部居中对齐
	})

	label:pos(localX or 0,localY or 0)

	return label
end

function Factory.createNormalSprite(img,localX,localY)
	
	local sprite = display.newSprite("#" .. img)

	sprite:pos(localX,localY)

	return sprite
end

function Factory.loadSprite(img,localX,localY)
	
	local sprite = display.newSprite(img)

	sprite:pos(localX,localY)

	return sprite
end

--display.PROGRESS_TIMER_BAR 
--display.PROGRESS_TIMER_RADIAL 环形
function Factory.createProgressTimer(img,type)
	local progress = display.newProgressTimer("#" .. img,type)

	return progress
end


function Factory.createMenuItemImage(img,imgSelected,localX,localY,clickListener)

	local item = ui.newImageMenuItem({
		image = "#" .. img,
		imageSelected = "#" .. imgSelected,
		listener = clickListener
	})

	item:pos(localX,localY)

	return item
end

function Factory.createEnableMaskItem()
	local item = Factory.createMenuItemImage("menu_bg_01.jpg","menu_bg_01.jpg",display.width/2,display.height/2,function()
		TODO("nothing")
	end)
	item:setOpacity(0) 
	local touchMask = ui.newMenu({item})
	return touchMask
end

function Factory.createBMFont(s,f)
	local label = ui.newBMFontLabel({ text = s,
    font = "res/font/" ..f})

	return label
end


function Factory.createScale9Sprite(img,localX,localY,size)

	local sprite = display.newScale9Sprite("#" .. img,localX,localY,size)

	return sprite
end

function Factory.createSprite(cfg, playOnce, removeWhenFinished, onComplete, delay)
	if not spCache[cfg.batchNodeKey] then
		spCache[cfg.batchNodeKey] = true
    	display.addSpriteFrames(cfg.skeleton, cfg.texture) -- 载入图像到帧缓存 
	end

	local animationKey = tostring(cfg.id)
	local animation = display.getAnimationCache(animationKey)
	local frameNames = cfg.animationName
	if not animation then

        if not frameNames or #frameNames == 0 then
            frameNames = sharedSpriteFrameCache:addSpriteFramesWithFile(cfg.skeleton, cfg.texture)
            --Logger.printTable(frameNames)
        end

        local frames = {}

		local frame
		for _,frameName in ipairs(frameNames) do
			frame = display.newSpriteFrame(frameName)
			_tinsert(frames, frame)
		end

		local len = #frames
		local fps = cfg.fps
		if fps <= 0 then
			fps = 15
		end

		animation = display.newAnimation(frames, 1 / fps)
	end
 	local sp = display.newSprite("#" .. frameNames[1])
 	if playOnce then
 		sp:playAnimationOnce(animation, removeWhenFinished, onComplete, delay)
 	else
 		sp:playAnimationForever(animation, delay)
 	end

	return sp
end

-- function Factory.getAnimation( cfg )
-- 	if not spCache[cfg.batchNodeKey] then
-- 		spCache[cfg.batchNodeKey] = true
--     	display.addSpriteFrames(cfg.skeleton, cfg.texture) -- 载入图像到帧缓存 
-- 	end


-- end

-- 根据配置创建动画对象
local cacheDragonBoun = {}
function Factory.createDragonBounAnimById( cfg )

	local key = cfg.skeleton .. "___" .. cfg.texture

	local animationName = cfg.animationName[1]
	local info = {
		armatureName=cfg.armatureName,
		animationName=animationName,
		skeletonName=cfg.skeletonName,
	}
	if not cacheDragonBoun[key] then
		info.skeleton=cfg.skeleton
		info.texture=cfg.texture
		cacheDragonBoun[key] = true
	end

	local db = dragonbones.new( info )
	db:gotoAndPlay(animationName)

	return db
end


function Factory.createAI( id, xMirror, yMirror )
	local cfg = CfgData.getCfg( CFG_UNIT_AI, id)
	if not cfg then
		return Factory.createAIEx( id, xMirror, yMirror )
	end
	local ai = cAI.new()
	ai.id = id
	ai:initByCfg(cfg, xMirror, yMirror)
	return ai
end

function Factory.createAIEx( id, xMirror, yMirror )
	--找不到AI的时候,再去扩展AI里面找
	local cfg = CfgData.getCfg( CFG_UNIT_AI_EX, id )
	if cfg == nil then
		return
	end
	local aiEx = cAIEx.new()
	if aiEx ~= nil then
		aiEx.id = id
		aiEx:initByCfg( cfg, xMirror, yMirror )
		return aiEx
	end
end

function Factory.createArmature(cfg, playOnce, removeWhenFinished, onComplete, delay)
	--print("createArmature : " .. cfg.skeleton)
	--print("texture list : " .. cfg.texture)
	--print("armatureName : " .. cfg.armatureName)
	--print("animationName : " .. cfg.animationName[1])
	--print("scale : " .. cfg.scale)
	--print("fps : " .. cfg.fps)

    local manager = CCArmatureDataManager:sharedArmatureDataManager()
	if cfg.texture ~= "" then
		manager:addArmatureFileInfo(cfg.texture .. ".png", cfg.texture .. ".plist", cfg.skeleton)
	else
		manager:addArmatureFileInfo(cfg.skeleton)
	end

    local armature = CCArmature:create(cfg.armatureName)
	if not armature then
		return nil
	end

    local animation = armature:getAnimation()
	if cfg.fps > 0 then
		animation:setSpeedScale(cfg.fps / 60)
	end

    if removeWhenFinished or onComplete then
        local __bridge = function(animature, evtType, name) 
            if evtType == 1 or evtType == 2 then
                if onComplete then
                    onComplete()
                end
                if removeWhenFinished then
                    armature:removeFromParent()
                end
            end
        end

        animation:setMovementEventCallFunc(__bridge)        
    end

    local loopCount = -1
    if playOnce then loopCount = 0 end
    local actName = cfg.animationName[1]

    if delay and delay > 0 then

        armature:setVisible(false)
        armature:runAction(
            CCSequence:createWithTwoActions(
                CCDelayTime:create(delay), 
                CCCallFunc:create(function() 
                    armature:setVisible(true)
                    animation:play(actName, -1, -1, loopCount)
                end)
            )
        )

    else
        animation:play(actName, -1, -1, loopCount)
    end
    
	return armature
end


function Factory.dropItemById( id )
    -- print("Factory.dropItemById: id = " .. id)

	local cfg = CfgData.getCfg(CFG_DROP, id)
	if not cfg then
		return nil, 0
	end

    local itemNum = #cfg
    -- print("Factory.dropItemById: itemNum = " .. itemNum)
    if itemNum <= 0 then
        return nil, 0
    end

    local totalWeight = cfg[itemNum].weight
    if totalWeight <= 0 then
        return nil, 0
    end

    local r = math.random(1, totalWeight)
    for _, drop in pairs(cfg) do
        if drop.weight >= r then
            return drop.itemId, drop.count
        end
    end
    
    return nil, 0
end


cPlane = class("cPlane", cUnit)

function cPlane:ctor(cfg)

 	cUnit.ctor(self, UG_PLANE, cfg)

    self.buffers =              -- 各个道具的BUFFER数据{power, time, animateId, maxTime}
    {
        [PROPS_TYPE_POWER] = {power = 0, time = 0, animateId = 0, maxTime = 8},
        [PROPS_TYPE_FULL_POWER] = {power = 0, time = 0, animateId = 0, maxTime = 0},
        [PROPS_TYPE_BOMB] = {power = 0, time = 0, animateId = 0, maxTime = 0},
        [PROPS_TYPE_INVINCIBLE] = {power = 0, time = 0, animateId = 0, maxTime = 0},
        [PROPS_TYPE_ADSORPTION] = {power = 0, time = 0, animateId = 0, maxTime = 0},
    }

    self.hurtAdd = 0
    self.hurtMul = 0
    self.wingmanHurtAdd = 0
    self.wingmanHurtMul = 0
    self.enhanceGunLevel = 0
    self.data = nil
    self.bufferChanged = nil    -- 当buffers的内容被修改时的通知. bufferChanged(typeId, buffer, event)
                                -- event : 0,时间变化;1,有增加;2,有删除;3,数量发生变化
                                -- 但在时间递减的时候并不通知
    self.gunLevel = 0                            
end

function cPlane:dtor()
    self.data = nil
    self.bufferChanged = nil
end

function cPlane:onExit()
    cUnit.onExit(self)

    self.data = nil
    self.bufferChanged = nil    -- 当buffers的内容被修改时的通知. bufferChanged(typeId, buffer, event)
                                -- event : 0,时间变化;1,有增加;2,有删除;3,数量发生变化
                                -- 但在时间递减的时候并不通知
end

-- 更新Buffer数据,如果时间到,返回true
function cPlane:updateBuffer(typeId, dt)

    local buffer = self.buffers[typeId]

    local timeLife = buffer.time
    if timeLife > 0 then
        timeLife = timeLife - dt
        buffer.time = timeLife

        if timeLife < 0 then
            if self.bufferChanged then
                self.bufferChanged(typeId, buffer, 2)
            end

            buffer.power = 0
            buffer.maxTime = 0
            
            if buffer.animateId and buffer.animateId > 0 then
                self:removeAnimate(buffer.animateId)
                buffer.animateId = 0
            end

            return true
        else
            if self.bufferChanged then
                self.bufferChanged(typeId, buffer, 0)
            end
        end
    end

    return false
end


function cPlane:update( dt )
 	cUnit.update(self, dt)

    if not self:isValid() then
        return
    end

    -- 处理爆走逻辑
    if self:updateBuffer(PROPS_TYPE_FULL_POWER, dt) then
        self:updateHurt()
        self:updateLevelView(4)
        if self.world ~= nil then
            local tWingmans = self.world.wingmans
            if tWingmans ~= nil then
                for idx, wingman in ipairs( tWingmans ) do
                    wingman:updateLevelView(4)
                end
            end
        end
        if self.gunLevel > 0 then
            local powerLevel = self.buffers[PROPS_TYPE_POWER]
            if powerLevel ~= nil then
                powerLevel.power = self.gunLevel - 1
                powerLevel.time = FUNC_CONST_FIRE_POW_LAST_TIME
                self:changeGuns(self.gunLevel)
                self.gunLevel = self.gunLevel - 1
            end
            if self.bufferChanged then
                self.bufferChanged(PROPS_TYPE_POWER, powerLevel, 1)
            end
        end
    elseif self:updateBuffer( PROPS_TYPE_POWER, dt ) then
        if self.gunLevel > 0 then
            local powerLevel = self.buffers[PROPS_TYPE_POWER]
            if powerLevel ~= nil then
                powerLevel.power = self.gunLevel - 1
                powerLevel.time = FUNC_CONST_FIRE_POW_LAST_TIME
                self:changeGuns(self.gunLevel)
                self.gunLevel = self.gunLevel - 1
            end
            if self.bufferChanged then
                self.bufferChanged(PROPS_TYPE_POWER, powerLevel, 1)
            end
        end
    end

    -- 处理吸附逻辑
    self:updateBuffer(PROPS_TYPE_ADSORPTION, dt)
end

-- 无敌模式的消减逻辑
function cPlane:updateInvncible(dt)

    if self:updateBuffer(PROPS_TYPE_INVINCIBLE, dt) then
        self.invncibleTime = 0
    end
end

-- 爆走模式下,不能吃升级道具
function cPlane:upgradePower(duration, count, props)
    
    local buffer = self.buffers[PROPS_TYPE_POWER]
    if buffer.power >= 4 then
        return false
    end
    
    buffer.power = buffer.power + 1
    buffer.time = FUNC_CONST_FIRE_POW_LAST_TIME
    self.gunLevel = self.gunLevel + 1
    local takeEffect = self:onCheckMechCoreGetPow()
    if takeEffect == true then
        buffer.power = 4
    end

    if self.bufferChanged then
        self.bufferChanged(PROPS_TYPE_POWER, buffer, 1)
    end

    if buffer.power >= 4 then
        self:enterFullPower(duration, true, props)
    else
        buffer.animateId = self:showAnimate(props)
        self:changeGuns(self.gunLevel + 1)
    end

    return true
end

-- 我方飞机进入爆走模式
-- 正常情况下,爆走模式下不能再接受爆走效果
function cPlane:enterFullPower(duration, force, props)
 	local techMgr = app.techMgr
    if techMgr ~= nil then
        local lv, addTime = techMgr:getTechInfo( ENUM_TECH_TYPE_FULL_POW_TIME )
        if lv ~= nil and lv > 0 and addTime > 0 then
            duration = duration + addTime
        end
    end
    local buffer = self.buffers[PROPS_TYPE_FULL_POWER]

    if force then
        if duration < buffer.time then
            return false
        end

        buffer.maxTime = duration
    elseif buffer.time > 0 then
        return false
    else
        buffer.maxTime = duration
    end

    buffer.power = props.power
    buffer.time = duration
    buffer.animateId = self:showAnimate(props)
    self:updateHurt()
    self:changeGuns(5 + self.enhanceGunLevel)
    local function movementEventCallback( armature, movementEvetType, movementId )
        if movementId == "tran" and movementEvetType == 1 then
            if self.world ~= nil then
            local tWingmans = self.world.wingmans
                if tWingmans ~= nil then
                    for idx, wingman in ipairs( tWingmans ) do
                        wingman:updateLevelView(3)
                    end
                end
            end
            self:updateLevelView(3)
        end
    end
    self:updateLevelView(2,movementEventCallback)
    if self.world ~= nil then
        local tWingmans = self.world.wingmans
        if tWingmans ~= nil then
            for idx, wingman in ipairs( tWingmans ) do
                wingman:updateLevelView(2)
            end
        end
    end
    if self.bufferChanged then
        self.bufferChanged(PROPS_TYPE_FULL_POWER, buffer, 1)
    end

    audio.playSound(GAME_SFX.fullPower)

    return true
end

-- 我方飞机进入无敌模式的逻辑稍有不一样
-- 正常情况下,无敌模式下不能再接受无敌效果
function cPlane:enterInvncible(duration, force, props)

    local buffer = self.buffers[PROPS_TYPE_INVINCIBLE]

    if force then
        if duration < buffer.time then
            return false
        end
        buffer.maxTime = duration
    elseif buffer.time > 0 then
        return false
    else
        buffer.maxTime = duration
    end

    self.invncibleTime = duration
    buffer.time = duration
    props.duration = duration
    buffer.animateId = self:showAnimate(props)

    if self.bufferChanged then
        self.bufferChanged(PROPS_TYPE_INVINCIBLE, buffer, 1)
    end

    return true
end

-- 我方飞机进入吸附模式
function cPlane:enterAdsorption(duration, force, props)

    local buffer = self.buffers[PROPS_TYPE_ADSORPTION]

    if duration < buffer.time then
        return false
    end

    buffer.power = props.power
    buffer.time = duration
    buffer.maxTime = duration
    buffer.animateId = self:showAnimate(props)
    
    if self.bufferChanged then
        self.bufferChanged(PROPS_TYPE_ADSORPTION, buffer, 1)
    end

    return true
end

function cPlane:showAnimate(props)
    if props.viewPlane > 0 then
        self:attachAnimate(props.viewPlane, props.duration, props.offsetX, props.offsetY)
    end

    if props.viewFullscreen > 0 then
        local centerX, centerY = display.width * 0.5, display.height * 0.5;
        self.world:addEffectAnim(props.viewFullscreen, true, centerX + props.screenX, centerY + props.screenY, UZ_EFFECT_ANIM)
    end

    return props.viewPlane
end

function cPlane:propsChanged(props, changeCount)

    -- 处理爆走状态下的金币加成
    if props and props.classify == PROPS_TYPE_GOLD then
        local planeData = self.data
        local buffer = self.buffers[PROPS_TYPE_FULL_POWER]

        if planeData and buffer.time > 0 then
            local mulAdd = planeData.enhancePower.gold
            changeCount = changeCount * mulAdd.x + mulAdd.y

            props.count = props.count + changeCount
        end
    end

    if self.bufferChanged then
        self.bufferChanged(props.classify, props, 3)
    end
end

-- 子弹初始化时的伤害加成
function cPlane:getHurt(isWingman)
    return self.hurtMul
end

function cPlane:mergeHurt(isWingman)
    local hurtAdd, hurtMul = 0, 0

    local planeData = self.data
    if planeData then
        local addHurt
        if false then
            addHurt = planeData.wingmanHurt
        else
            addHurt = planeData.hurt
        end

        hurtAdd = hurtAdd + 0
        hurtMul = hurtMul + addHurt
    end
    
    local buffer = self.buffers[PROPS_TYPE_FULL_POWER]
    if buffer.time > 0 then
        hurtMul = hurtMul + buffer.power

        if planeData then
            local addHurt = planeData.enhancePower.hurt;
            hurtAdd = hurtAdd + addHurt.y
            hurtMul = hurtMul + addHurt.x
        end
    end

    return hurtAdd, hurtMul
end

function cPlane:updateHurt()
    self.hurtAdd, self.hurtMul = self:mergeHurt(false)
end

-- 吸附道具的距离
function cPlane:adsorptionDistance()
    local buffer = self.buffers[PROPS_TYPE_ADSORPTION]
    return buffer.power
end

-- 子弹初始化时的伤害加成
function cPlane:setPlaneData(planeData)
    self.data = planeData
    self.hp = planeData.hp
    self.maxHP = planeData.hp
    self.enhanceGunLevel = planeData.enhanceLevel.gun
    self.mechCoreTakeEffect = { 0, 0, 0, 0 }
    self:updateHurt()
end

function cPlane:onRevive()
	self.needDel = false
	self.stopFire = false
    self.invncibleTime = 0
    self.needDel = false
    self.hp = self.maxHP
    self.mechCoreTakeEffect = { 0, 0, 0, 0 }
    for typeId, buffer in pairs(self.buffers) do
        if buffer.time >= 0 then
            buffer.time = -1.0
            buffer.power = 0

            if self.bufferChanged then
                self.bufferChanged(typeId, buffer, 2)
            end
            if buffer.animateId and buffer.animateId > 0 then
                self:removeAnimate(buffer.animateId)
                buffer.animateId = 0
            end
        end
    end

    self:updateHurt()
    self:updateLevelView(1)
    self:changeGuns(1)
    if self.world ~= nil then
        local tWingmans = self.world.wingmans
        if tWingmans ~= nil then
            for idx, wingman in ipairs( tWingmans ) do
                wingman:updateLevelView(1)
            end
        end
    end
    self:pos(CONFIG_WORLD_CX, CONFIG_WORLD_CY)

    local bomb = app.propsData[PROPS_TYPE_BOMB]
    self.world:useBomb(bomb)
end

function cPlane:getDamage( dmg )
    if self.hp <= 0 then
        return
    end
    if self.invncibleTime <= 0 then
        local bTakeEffect = self:onCheckMechCoreGetDamage( dmg )
        if bTakeEffect == true then
            if self == self.world.plane then
                local props = app.propsData[PROPS_TYPE_INVINCIBLE]
                if props ~= nil then
                    self.world.plane:enterInvncible( 1, true, props)
                end
            end
            return
        end
        local hp = self.hp - dmg
        if hp <= 0 then
            local ownerDrops = nil
            local team = self.team
            if team then
                local count = team.memberCount - 1
                team.memberCount = count
                if count == 0 then
                    ownerDrops = team.dropIds
                end
            end
            self:doExplosion( false )
            self:dropItemes(self.dropIds, ownerDrops)
            self:showDeadView()
            self:remove()
            if self.sndExplosion then audio.playSound(self.sndExplosion) end
            hp = 0
        end

        self.hp = hp
        if self == self.world.plane then
            local props = app.propsData[PROPS_TYPE_INVINCIBLE]
            if props ~= nil then
                self.world.plane:enterInvncible( 1, true, props)
            end
        end
    else
        --self:showInvncibleView()
    end
end

function cPlane:onCheckMechCoreGetDamage( dmg )
    local planeData = self.data
    if planeData == nil then
        return
    end
    if self.mechCoreTakeEffect == nil then
        self.mechCoreTakeEffect = { 0, 0, 0, 0 }
    end
    local mechCoreSlotData = planeData:getMechCoreSlotData()
    if mechCoreSlotData == nil then
        return
    end
    for i, v in ipairs( self.mechCoreTakeEffect ) do
        local itemId = mechCoreSlotData[i]
        if itemId > 0 then
            local itemData = CfgData.getCfg(CFG_BAG_ITEM, itemId )
            if itemData ~= nil then
                if itemData.param1 == ENUM_MECH_CORE_TYPE_CRI_DEF and (v < itemData.param2) then
                    local beforePercent = (self.hp / self.maxHP)
                    local afterHp = self.hp - dmg
                    if (beforePercent >= itemData.param3) and (afterHp <= 0) then
                        self.mechCoreTakeEffect[i] = v + 1
                        self.hp = 1
                        return true
                    end
                end
            end
        end
    end
    return false
end

function cPlane:onCheckMechCoreGetPow()
    local planeData = self.data
    if planeData == nil then
        return
    end
    if self.mechCoreTakeEffect == nil then
        self.mechCoreTakeEffect = { 0, 0, 0, 0 }
    end
    local mechCoreSlotData = planeData:getMechCoreSlotData()
    if mechCoreSlotData == nil then
        return
    end
    for i, v in ipairs( self.mechCoreTakeEffect ) do
        local itemId = mechCoreSlotData[i]
        if itemId > 0 then
            local itemData = CfgData.getCfg(CFG_BAG_ITEM, itemId )
            if itemData ~= nil then
                if itemData.param1 == ENUM_MECH_CORE_TYPE_FIRE_CRI then
                    local randomVal = math.random( 1, 10000 )
                    if randomVal < itemData.param3 * 10000 then
                        return true
                    end
                end
            end
        end
    end
    return false
end
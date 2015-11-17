require("app/model/cUnit")
require("app/model/cItem")
require("app/model/cProps")
require("app/model/cPlane")
require("app/model/cGun")
require("app/model/cBag")
require("app/model/cBagItem")
require("app/model/cAI")
require("app/model/cAIEx")
require("app/model/Factory")

require("bdlib/tools/util")

local _tinsert = table.insert
local _tremove = table.remove
local _strfmt = string.format
local _math_abs = math.abs
local ipairs = ipairs
local pairs = pairs

-- 游戏世界管理器
cWorld = class("cWorld")


-- 摄像机的活动范围
local _cameraXmin = 0
local _cameraXmax = 0
local _cameraXmaxHalf = 0

local _cameraYmin = 0
local _cameraYmax = 0
local _cameraYmaxHalf = 0
local _needUpdateCamera = true

local _worldWidthHalf = 0
local _worldHeightHalf = 0

local _startX = 0
local _startY = 0

local _endX = 0
local _endY = 0

local showPlaneId = 1  --展示飞机index


function cWorld:ctor( scene, cfg ,playMissionId)
    self.scene = scene
    self.cfg = cfg
    self.units = {}
    self.batchNodes = {}
    self.plane = nil
    self.tempPlane = nil

    self.bulletBatchNode = nil

    self.missionId = nil
    self.missionTime = nil -- 关卡当前进行的时间
    self.enemys = nil

    self.cameraX = 0
    self.cameraY = 0

    self.enemyCount = 0 --场内存活敌机数量
    self.stopUpdateEnemy = false -- 暂停更新敌机
    self.waveId = 1 --当前波次id
    self.waveCount = 0 --波次数量

    self.currentScore = 0 --当前获得积分
    self.passScore = 0 --通关积分

    self.effectFuncs = {}

    self:regEffectFuncs()

    self.collisionFuncs = {}

    self:regCollisionFuncs()

    self.missionId = playMissionId
    self.curMissType = 0
    self.missFailedTime = 0
    self.savedProps = nil
    self.pickedProps = {}
    self.missionMaps = {}
    self.missionResult = nil

    self._isChanging = false

    self.planesIds = {20001, 20002, 20003 }

    self.wingmanIds = { 20101, 20102, 20103 }

    self.protectBalls = {}

    self.activeFlags = {true, true, true, true, true, true, true, true}

    self.auxNode = cc.Node:create()

    scene:addChild( self.auxNode, 1, 1 )
end

function cWorld:onEnter(planeId)
    -- print("cWorld:ctor()::::::::nimei====================")
    -- self:testBullet()
    -- self:testSpirite()
    -- print("cWorld:ctor()::::::::nimei222====================")   
    -- self:testBatchNode()

    -- TODO("需要设置关卡id来源", self.missionId)
    -- self.missionId = self.missionId or 60001 

    --=-=-=-=-=-=-=-=-=-=-=-=-=-=-= 我是分割线 =-=-=-=-=-=-=-=-=-=-=-=-=-=-=--

    --=-=-=-=-=-=-=-=-=-=-=-=-=-=-= 我是分割线 =-=-=-=-=-=-=-=-=-=-=-=-=-=-=--

    self.enemyCount = 0 --场内存活敌机数量
    self.stopUpdateEnemy = false -- 暂停更新敌机
    self.waveId = 1 --当前波次id
    self.waveCount = 0 --波次数量

    self:initMission()

    self:createPlane(planeId) -- 创建主角

    self:createWingman( app.curWingmanPlaneId )
    -- self:testEnemy()
    

    
    -- 摄像机实际的x坐标范围
    _cameraXmax = (CONFIG_WORLD_WIDTH - CONFIG_SCREEN_WIDTH)/2
    _cameraXmin = -_cameraXmax
    CONFIG_SCREEN_WIDTH_HALF = CONFIG_SCREEN_WIDTH / 2
    _cameraXmaxHalf = _cameraXmax / 2
    CONFIG_WORLD_WIDTH_HALF = CONFIG_WORLD_WIDTH / 2
     _worldWidthHalf = CONFIG_WORLD_WIDTH_HALF / 2

    _cameraYmin = 0
    _cameraYmax = CONFIG_WORLD_HEIGHT - CONFIG_SCREEN_HEIGHT
    _cameraYmaxHalf = _cameraYmax / 2
    _worldHeightHalf = CONFIG_WORLD_HEIGHT / 2

    self.cameraX = 0
    self.cameraY = ( _cameraYmin + _cameraYmax ) / 2

    if (CONFIG_WORLD_WIDTH / CONFIG_WORLD_HEIGHT) < ( display.width / display.height ) then
        _needUpdateCamera = false
    end
    --=-=-=-=-=-=-=-=-=-=-=-=-=-=-= 我是分割线 =-=-=-=-=-=-=-=-=-=-=-=-=-=-=--
    --self:testAnim()

end

function cWorld:onExit()
    
    for _, list in pairs(self.units) do
        for _, unit in ipairs(list) do
            unit:remove()
            unit:onDelete()
            self:removeUnit(unit)
        end
    end

    self.missionResult = nil
end

-- 每帧更新
local loadt = 2
function cWorld:update( dt )
    -- loadt = loadt - dt
    -- if loadt <= 0 then
    --     print("gUnitCount:", gUnitCount)
    --     loadt = 2
    -- end

    self:updateCarmera( dt )

    local delList = {}
    local tempList
    local len, idx

    local units = self.units
    local activeFlags = self.activeFlags

    self:updateEffect()

    -- 观察者进行逻辑处理
    if activeFlags[UG_ENEMY] then
        self:updateEnemys(dt)
    end
    local bIsMissEnded = false
    -- 遍历单位列表, 更新所有单位逻辑
    for unitGroup,list in pairs(units) do
        if activeFlags[unitGroup] then

            tempList = {}
            -- update逻辑并检查是否需要删除
            for i,v in ipairs(list) do
                v:update(dt)

                if v.needDel then

                    if unitGroup == UG_ENEMY then
                        _tinsert(tempList, i) -- 添加到待删除列表中

                        self.enemyCount = self.enemyCount - 1  -- 如果删除的是敌机敌机数量减少
                        if v.endedMark == true then
                            bIsMissEnded = true
                        end
                    elseif unitGroup == UG_PLANE then
                        if self.missionId ~= 69999 then
                            v.needDel = false
                            v:stopGuns()

                            if self.missionResult then
                                self.missionResult(self.missionId, false)
                            end
                        else
                            _tinsert(tempList, i)
                        end
                    else
                        _tinsert(tempList, i) -- 添加到待删除列表中
                    end --if unitGroup == UG_ENEMY then

                end --if v.needDel then

            end --for i,v in ipairs(list) do

            if #tempList > 0 then
                delList[unitGroup] = tempList
            end

        end --if activeFlags[unitGroup] then
    end --for unitGroup,list in pairs(units) do

    --检测到通关标志，则通关
    if self.missionResult and bIsMissEnded then
        self.plane:stopGuns()
        self.missionResult(self.missionId, true)
        self.missionResult = nil
    end

    -- 真正的删除各个对象
    for k,idxList in pairs(delList) do
        len = #idxList
        list = units[k]

        for i=len,1,-1 do
            idx = idxList[i]
            unit = list[idx]
            unit:onDelete()
            self:removeUnit( unit )
            _tremove(list, idx)
        end
    end

    self:updateWingManPos()
    self:updateProtectBall( dt )
end

-- 确保获取绘制节点
function cWorld:ensureBatchNode( cfg, zOrder, tag )
    local key = cfg.batchNodeKeyVal + zOrder
    local batchNode = self.batchNodes[ key ]
    if not batchNode then
        batchNode = display.newBatchNode(cfg.texture)
        self.batchNodes[ key ] = batchNode
        self.scene:addChild( batchNode, zOrder, tag or 0 )
    end
    return batchNode
end

-- 向控制世界中添加一个对象
function cWorld:addUnit(unitGroup, unit, zOrder, tag)
    zOrder = zOrder or UZ_PLANE
    tag = tag or 0

    local list = self.units[unitGroup] 
    if not list then
        list = {}
        self.units[unitGroup] = list
    end
    _tinsert(list, unit)

    unit.scene = self.scene
    unit.world = self
    unit.needDel = false
    unit.zvalue = zOrder
    unit.group = unitGroup
    unit:onEntrance()
    
    -- 根据batchNodeKey的值, 放入不同的父节点中
    if unit.viewCfg ~= nil then
        local batchNodeKey = unit.viewCfg.batchNodeKey
        if batchNodeKey then
            local batchNode = self:ensureBatchNode(unit.viewCfg, zOrder, tag)
            batchNode:addChild(unit.view , zOrder, tag)
        else
            self.scene:addChild(unit.view, zOrder, tag)
        end
        if unit.lifeBar then
            --TODO("unit.lifeBar")
            self.scene:addChild(unit.lifeBar, UZ_EFFECT_ANIM)
        end
        if unit.specialType == ENUM_UNIT_SPECIAL_TYPE_COMP_BOSS then
            for i, v in ipairs( unit.components ) do
                self.scene:addChild( v.lifeBar, UZ_EFFECT_ANIM )
            end
        end
        if unit.debugInfoLabel ~= nil then
            self.scene:addChild( unit.debugInfoLabel )
        end
    end
end

function cWorld:getUnitsByGroup( unitGroup )
    return self.units[unitGroup]
end

-- 从控制世界中移除对象
function cWorld:removeUnitEx(unit, putUnit)
    unit:onExit()
    if putUnit ~= false then
        Factory.putUnit(unit)
    else
        unit:dtor()
    end
end

function cWorld:removeUnit(unit)
    unit:onExit()
    Factory.putUnit(unit)
end

function cWorld:missionAward()

    local awardProps = {}

    for classify = 1, PROPS_TYPE_MAX__ do
        local picked = self.pickedProps[classify]
        local props = app.propsData[classify]
        if picked and props and picked ~= props then
            props:merge(picked)
        end

        if props then
            local add_count = props.count - self.savedProps[classify]
            if add_count > 0 then
                awardProps[classify] = add_count
            end
        end
    end

    app:propsChanged()

    self:removePlane()

    return awardProps
end

function cWorld:removePlane()
    local plane = self.plane
    if plane then
        self.plane = nil

        plane:stopGuns()
        plane:remove()
        plane:onDelete()
        self:removeUnitEx(plane,false)
    end
end

function cWorld:addPlane()

    self.plane = self.tempPlane
    self.plane:pos(0,CONFIG_SHOW_PLANE_CY)
    self.plane:openGuns()

    self._isChanging = false
end

--展示上一挂飞机
function cWorld:showPrePlane()
    if self._isChanging then
        return
    end

    local plane = self.plane
    plane:stopGuns()

    self._isChanging = true

    --创建一个飞机副本
    if showPlaneId > 1 then
        showPlaneId = showPlaneId - 1
    else 
        showPlaneId = #self.planesIds
    end

    app.planeId = self.planesIds[showPlaneId]

    local temp = Factory.createPlaneById(self.planesIds[showPlaneId])
    temp:stopGuns()
    self:addUnit(UG_PLANE, temp, UZ_PLANE)
    temp:pos(0, CONFIG_SHOW_PLANE_CY)
    if self.tempPlane then
        self.tempPlane:remove()
    end
    self.tempPlane = temp
    self:removePlane()
    self:addPlane()

    --[[
    plane:run(transition.sequence({CCMoveTo:create(0.6, CCPoint(display.width + 300,CONFIG_SHOW_PLANE_CY)),
    CCCallFunc:create(function()
        self:removePlane()
    end)}))

    temp:run(transition.sequence({CCMoveTo:create(0.6, CCPoint(display.width/2,CONFIG_SHOW_PLANE_CY)),
    CCCallFunc:create(function()
        self:addPlane()
    end)}))
    --]]
end

--展示下一挂飞机
function cWorld:showNextPlane( selectedId )
    if self._isChanging then
        return
    end

    if selectedId then
        if showPlaneId == selectedId or selectedId > #self.planesIds then
            return
        end
    end

    local plane = self.plane
    plane:stopGuns()

    self._isChanging = true

    if showPlaneId >= #self.planesIds then
        showPlaneId = 1
    else 
        showPlaneId = showPlaneId + 1
    end

    if selectedId then
        showPlaneId = selectedId
    end

    app.planeId = self.planesIds[showPlaneId]

    local temp = Factory.createPlaneById(self.planesIds[showPlaneId])
    self:addUnit(UG_PLANE, temp, UZ_PLANE)
    temp:pos(0,CONFIG_SHOW_PLANE_CY)
    if self.tempPlane then
        self.tempPlane:remove()
    end
    self.tempPlane = temp
    temp:stopGuns()
    --math.random(1,5)
    self:removePlane()
    self:addPlane()
    --[[
    local outAction = CCMoveTo:create(0.6, CCPoint(-300,CONFIG_WORLD_CY))

    plane:run(transition.sequence({CCMoveTo:create(0.6, CCPoint(-300,CONFIG_SHOW_PLANE_CY)),
    CCCallFunc:create(function()
        self:removePlane()
    end)}))

    temp:run(transition.sequence({CCMoveTo:create(0.6, CCPoint(display.width/2,CONFIG_SHOW_PLANE_CY)),
    CCCallFunc:create(function()
        self:addPlane()
    end)}))
    --]]
end


function cWorld:setPlaneVisible( visible )
    if self.plane ~= nil and self.plane.view ~= nil then
        if visible == false then
            self.plane:stopGuns()
        else
            self.plane:openGuns()
        end
        self.plane.view:setVisible( visible )
    end
end

function cWorld:setWingManVisible( visible )
    if self.wingmans ~= nil then
        for i, v in ipairs( self.wingmans ) do
            if visible == false then
                v:stopGuns()
            else
                v:openGuns()
            end
            v.view:setVisible( visible )
        end
    end
end

function cWorld:resetWingmanPos()
    local tWingmanPos = CfgData.getCfg(CFG_WINGMAN_POS, app.curSelFormation)
    if self.plane ~= nil and self.wingmans ~= nil and tWingmanPos ~= nil then
        for i, v in ipairs( self.wingmans ) do
            local gunsId = tWingmanPos[string.format( "gun%s", i )]
            v:resetGuns()
            v:addGuns( gunsId )
            v:pos( self.plane.x, self.plane.y )
        end
    end
end


-- 触摸处理
function cWorld:onTouch( event )
    local plane = self.plane

    if not plane then
        return false
    end

    local srcX, srcY, prevX, prevY = event.x, event.y, event.prevX, event.prevY

   
    if self.missionId == 69999 then

        if event.name == "began" then

            _startX = srcX
            _startY = srcY

        end

        if event.name == "ended" then
            _endX = event.x
            _endY = event.y

            local distansX = _endX - _startX

            if distansX > 40 then
                --TODO(distansX .. "向右移动")
                self:showPrePlane()
            elseif distansX < -40 then
                --TODO(distansX .. "向左移动")
                self:showNextPlane(nil)
            end

        end

        return true ---如果是选择战机关卡飞机就停止触摸移动
    end
   
    if true then
        -- 飞机和手指同步移动
        if event.name == "began" then
        elseif event.name == "moved" then
            local x, y = plane:getPosition()
            local originX, originY = x, y
            local deltaX, deltaY

            deltaX = srcX - prevX
            deltaY = srcY - prevY


            -- 飞机的位置调整
            x = x + deltaX
            y = y + deltaY

            if x < -CONFIG_WORLD_WIDTH_HALF then
                x = -CONFIG_WORLD_WIDTH_HALF + 1
            elseif x >= CONFIG_WORLD_WIDTH_HALF then
                x = CONFIG_WORLD_WIDTH_HALF - 1
            end

            if y < 1 then
                y = 1 
            elseif y >= CONFIG_WORLD_HEIGHT then
                y = CONFIG_WORLD_HEIGHT - 1
            end

            plane:pos(x, y)

        elseif event.name == "ended" then
        end
    else
        -- 飞机用固定速度移动
        local speed = nil
        local angle = nil

        if event.name == "began" then
            return true
        elseif event.name == "moved" then
            speed = 200
            -- angle = math.atan2(y - prevY, x - prevX) * 180 / 3.1415 - 90
            angle = math.atan2( x - prevX, y - prevY) * 180 / 3.1415
        elseif event.name == "ended" then
            speed = 0
            angle = 0
        end
        plane:setSAR(speed, angle, nil)
    end

    return true
end

-- 创建背景和前景 
function cWorld:createBG( cfg )

    local cx, cy = CONFIG_WORLD_CX,CONFIG_WORLD_CY
    self.missionMaps = {}
    for i=0,2 do
        -- 创建背景
        local height = CONFIG_WORLD_HEIGHT
        local bg
        bg = Factory.getUnit( cfg.bgId )
        bg.isBg = true
        bg:setSAR(cfg.bgSpeed, 0, 180)
        if height < bg.halfBoundHeight * 2 then
            height = bg.halfBoundHeight
        end
        bg:pos( cx, cy  + i * (height - 0))
        if bg.view ~= nil then
            bg.view:getTexture():setAliasTexParameters()
        end
        self:addUnit(UG_BG, bg, UZ_BG_1) 
        _tinsert( self.missionMaps, bg )
    end

    for i=0,2 do
        -- 创建前景
        local fg

        fg = Factory.getUnit( cfg.fg1_id )
        if fg then
            fg.isBg = true
            fg:setSAR(cfg.fg1_speed, 0, 180)
            fg:pos( cfg.fg1_pos[1] or 0 , (cfg.fg1_pos[2] or 0)  + i * CONFIG_WORLD_HEIGHT )
            self:addUnit(UG_BG, fg, UZ_FG_1)
        end

        fg = Factory.getUnit( cfg.fg2_id )
        if fg then
            fg.isBg = true
            fg:setSAR(cfg.fg2_speed, 0, 180)
            fg:pos( cfg.fg2_pos[1] or 0 , (cfg.fg2_pos[2] or 0) + i * CONFIG_WORLD_HEIGHT)
            self:addUnit(UG_BG, fg, UZ_FG_2)  
        end

        fg = Factory.getUnit( cfg.fg3_id )
        if fg then
            fg.isBg = true
            fg:setSAR(cfg.fg3_speed, 0, 180)
            fg:pos( cfg.fg3_pos[1] or 0 ,( cfg.fg3_pos[2] or 0) + i * CONFIG_WORLD_HEIGHT)
            self:addUnit(UG_BG, fg, UZ_FG_3)    
        end
    end

end

-- 创建主角的飞机 
function cWorld:createPlane(planeId)
    if not planeId then
        planeId = app.planeId
    end

    local plane = Factory.createPlaneById(planeId)

    plane:pos( 0, CONFIG_WORLD_HEIGHT/2)

    self:addUnit(UG_PLANE, plane, UZ_PLANE)
    self.plane = plane
end

--创建僚机
function cWorld:createWingman( wingmanPlaneId )
    local plane = self.plane
    local tWingmanPos = CfgData.getCfg(CFG_WINGMAN_POS, app.curSelFormation)
    self.wingmans = {};
    local wingmanData = app.wingmanDatas[wingmanPlaneId]
    if plane ~= nil then
        local wingmanHurt = 1
        local wingmanNum = 2
        if wingmanData ~= nil then
            wingmanNum = wingmanData:getWingmanNum()
            wingmanHurt = wingmanData.hurt
        end
        for i = 1, wingmanNum do
            local tPos = tWingmanPos[string.format( "pos%d", i) ]
            local gunsId = tWingmanPos[string.format( "gun%d", i )]
            local wingManPlane = Factory.createPlaneById( wingmanPlaneId )
            if wingManPlane ~= nil then
                wingManPlane:pos( plane.x, plane.y )
                self:addUnit(UG_PLANE, wingManPlane, UZ_PLANE)
                self.wingmans[i] = wingManPlane
                wingManPlane:resetGuns()
                wingManPlane:addGuns( gunsId )
                wingManPlane.hurtAdd = 0
                wingManPlane.hurtMul = 1
                --变枪
                wingManPlane:setModifier( 1, 1, wingmanHurt )
                wingManPlane:openGuns()
            end
        end
        self.winMaxPosX = CONFIG_WORLD_CX
        self.winMaxPosY = CONFIG_WORLD_CY
    end
end

function cWorld:updateWingManPos()
    if self.wingmans ~= nil then
        local plane = self.plane;
        if plane == nil then
            return
        end
        local x = plane.x
        local y = plane.y
        local tWingmanPos = CfgData.getCfg(CFG_WINGMAN_POS, app.curSelFormation )
        if tWingmanPos ~= nil then
            for i, wingman in ipairs( self.wingmans ) do
                local tPos = tWingmanPos[string.format( "pos%d", i) ]
                if tPos ~= nil then
                    local distX = tPos.x + x
                    local distY = tPos.y + y
                    local distance = MathAngle_distance( distX, distY, wingman.x, wingman.y );
                    if distance == nil then
                        distance = 0
                    end
                    if distance <= 16 then
                        wingman:setSAR( 0, 0, nil)
                        wingman:pos( distX, distY )
                    else
                        local speed = 16 * distance
                        if speed < 10 then
                            speed = 10
                        end
                        if speed > 2400 then
                            speed = 2400
                        end
                        local angle = MathAngle_pointAngle( distX, distY, wingman.x, wingman.y)
                        wingman:setSAR( speed, angle + 90, nil)
                    end
                end
            end
        end
    end
end

function cWorld:removeAllWingman()
    if self.wingmans ~= nil then
        for i, v in ipairs( self.wingmans ) do
            v:stopGuns()
            v:remove()
            v:onDelete()
            self:removeUnitEx(v,false)
        end
        self.wingmans = {}
    end
end

function cWorld:createProtectBall( planeData )
    if planeData == nil then
        return
    end
    self.protectBalls = {}
    local mechCoreSlotData = planeData:getMechCoreSlotData()
    if mechCoreSlotData ~= nil then
        local ballNum = 0
        for i, v in ipairs( mechCoreSlotData ) do
            if v > 0 then
                local itemData = CfgData.getCfg(CFG_BAG_ITEM, v )
                if itemData ~= nil and itemData.param1 == ENUM_MECH_CORE_TYPE_PROTECT_BALL then
                    ballNum = tonumber( itemData.param3 )
                    break
                end
            end
        end
        if ballNum > 0 then
            for i = 1, ballNum do
                local protectBall = Factory.createPlaneById( 22001 )
                if protectBall ~= nil then
                    protectBall.circleAngle = i * ( 360 / ballNum )
                    _tinsert( self.protectBalls, protectBall )
                    self:addUnit(UG_PLANE, protectBall, UZ_PLANE)
                end
            end
        end
    end
end

function cWorld:updateProtectBall( dt )
    local plane = self.plane;
    if plane == nil then
        return
    end
    if #self.protectBalls == 0 then
        return
    end
    local x = plane.x
    local y = plane.y
    for i, protectBall in ipairs( self.protectBalls ) do
        local radii = protectBall.circleAngle * (math.pi / 180)
        protectBall:pos( x + 200 * math.cos(radii), y + 200 * math.sin(radii) )
        protectBall.circleAngle = protectBall.circleAngle + dt * 100
    end
end


-- 初始化关卡相关数据
function cWorld:initMission(  )
    self.missionTime = 0 -- 关卡时间清零

    -- 其他道具拾取到后直接累加到玩家的道具上去
    self.savedProps = {}
    for classify=1, PROPS_TYPE_MAX__ do
        local props = app.propsData[classify]
        if props ~= nil then
            self.pickedProps[classify] = props
            self.savedProps[classify] = props.count
        end
    end

    -- 金币和碎片拾取到后,累加到临时的道具上去,最后通关结算的时候再累加到玩家的道具上去
    for _, classify in ipairs(PROPS_NEED_PICKED) do
        local i = cProps.new(nil)
        if i:init(classify) then
            i.count = 0
            self.pickedProps[classify] = i
        end
    end

    -- 取出关卡的基本配置
    local missionCfg = CfgData.getCfg(CFG_MISSION,self.missionId)

    if not missionCfg then
        self.missionId = 60001
        missionCfg = CfgData.getCfg(CFG_MISSION, self.missionId)
        TODO("检查配置，进入60001关卡...")
    end

    self:createBG( missionCfg )

    self.passScore  = missionCfg.score

    local enemysCfg = CfgData.getCfg( CFG_ENEMYS, self.missionId)
    self:initEnemys( enemysCfg ) -- 准备敌人列表

end

-- 初始化敌人列表
function cWorld:initEnemys( enemysCfg )

    local enemys = {}
    local unitCount = 0
    local enemyGrop = {}
    local team = {memberCount = 0, dropIds = nil}

    self.enemys = enemys
    local waveCount = self.waveCount
    -- 遍历敌人列表

    if not enemysCfg then
        return
    end
    for i,info in ipairs(enemysCfg) do
        waveCount = waveCount + 1
        if info.unitId > 0 then
            unitCount = unitCount + 1
            local unitCfg = CfgData.getCfg( CFG_UNIT, info.unitId )
            if unitCfg ~= nil and unitCfg.specialType == ENUM_UNIT_SPECIAL_TYPE_MISSILE then
                local warningTime = (info.time - (tonumber(unitCfg.params1[1]) or 2) )
                if warningTime < 0 then
                    warningTime = 0
                end
                local warnningInfo = 
                {
                    id = info.id,
                    unitId = 99999,
                    time = warningTime,
                    pos = { info.pos[1], info.pos[2] },
                    isWarningLine = true,
                }
                _tinsert( enemyGrop, warnningInfo )
                unitCount = unitCount + 1
            end
        end

        local clone_info = clone(info)
        clone_info.team = team
        _tinsert(enemyGrop, clone_info)

        if info.isWave then
            team.memberCount = unitCount
            team.dropIds = info.groupDrops

            _tinsert(enemys, enemyGrop)

            unitCount = 0
            enemyGrop = {}
            team = {memberCount = 0, dropIds = nil}
        end

    end

    self.waveCount = waveCount
end

-- 更新敌人列表
function cWorld:updateEnemys(dt)
    
    if self.missionId == 69999 then
        return
    end

    local waveCount = self.waveCount

    if waveCount <= 0 then
        return
    end

    local enemys = self.enemys
    local stopUpdateEnemy = self.stopUpdateEnemy
    local enemyGrop = enemys[self.waveId]
    if not enemyGrop then
        return
    end
    local size = #enemyGrop

    if stopUpdateEnemy then
        if self.enemyCount <= 0 then
            self.stopUpdateEnemy = false
            self.waveId = self.waveId + 1
        end 

        return
    end

    local info, t, e, ai
    local enemyCount = self.enemyCount
    for i= size, 1,-1 do
        info = enemyGrop[i]
        t = info.time - dt
        if t <= 0 then -- 此敌人到达出击时间
            audio.playSound(info.soundEntrance)
            if info.command == "mapSpeedChange" then
                local newSpeed = tonumber(info.params[1])
                if newSpeed ~= nil then
                    for idx, map in ipairs( self.missionMaps ) do
                        map:setSAR( newSpeed, 0, 180)
                    end
                end
            elseif info.command == "planeFire" then
                local openGun = (tonumber(info.params[1]) == 1)
                if openGun == true then
                    self.plane:openGuns()
                    for idx, wingman in ipairs( self.wingmans ) do
                        wingman:openGuns()
                    end
                else
                    self.plane:stopGuns()
                    for idx, wingman in ipairs( self.wingmans ) do
                        wingman:stopGuns()
                    end
                end
            end  
            if info.unitId <= 0 then
                if info.isWave then
                    stopUpdateEnemy = true
                end

                waveCount = waveCount - 1;
            else
                if info.isWarningLine == true then
                    if self.scene ~= nil then
                        local delayTime = CCDelayTime:create( 2 * (1 / DEBUG_TIME_SPEED) )
                        local removeSelf = CCRemoveSelf:create()
                        local sequence = CCSequence:createWithTwoActions( delayTime, removeSelf )
                        local drawNode = cc.DrawNode:create()
                        if drawNode ~= nil then
                            local xScreen = info.pos[1] + CONFIG_SCREEN_WIDTH / 2 - self.cameraX * 1
                            drawNode:drawLine( { xScreen, info.pos[2] }, { xScreen, 0 }, 2, cc.c4f(1,0,0,0.8) )
                            self.scene:addChild( drawNode, 999 )
                            drawNode:runAction( sequence )
                        end
                    end
                else
                    e = Factory.getUnit(info.unitId, info.score)
                    if e then
                        local groupType = e.group
                        if (groupType or 0) == 0 then
                            groupType = UG_ENEMY
                        end
                        self:addUnit(UG_ENEMY, e, UZ_ENEMY)
                        e.group = groupType
                        e.rotation = 0
                        e.rotSpeed = 0
                        e.cantDmgTime = info.entranceInvTime or 0
                        e.fireDelayTime = info.fireDelayTime or 0
                        -- 替换掉落
                        local dropIds = info.dropIds
                        if dropIds and #dropIds > 0 then
                            e.dropIds = dropIds
                        end
                        
                        -- 设置攻击，血量等修正系数
                        e:setModifier( info.hp or 1, info.collisionHurt or 1, info.gunHurt or 1)

                        -- 设置组所有者
                        e.team = info.team                   

                        e:pos(info.pos[1] or 0, info.pos[2] or 0)
                        e:setAI(info.aiId, info.xMirror, info.yMirror)

                        if info.isWave then
                            stopUpdateEnemy = true
                        end

                        if e.specialType == ENUM_UNIT_SPECIAL_TYPE_BOMB then
                            e:setSelfExplosionData( unpack( e.params1 ) )
                        end
                        enemyCount = enemyCount + 1 --如果是敌机添加数量增加
                        waveCount = waveCount - 1;
                        if e.specialType == ENUM_UNIT_SPECIAL_TYPE_COMP_BOSS then
                            self.curBoss = e
                        end
                        e.endedMark = (info.command == "END")
                    end
                end
            end
            _tremove( enemyGrop , i)
        end
        info.time = t
    end

    self.enemyCount = enemyCount
    self.waveCount = waveCount
    self.stopUpdateEnemy = stopUpdateEnemy
end


-- 更新摄像机
function cWorld:updateCarmera( dt )
    if not _needUpdateCamera then
        return
    end
    local plane = self.plane
    if not plane then
        return
    end

    -- 获取飞机在战场上的坐标
    local x, y = plane:getPosition()

    local wcxHalf, wcyHalf = _worldWidthHalf, _worldHeightHalf -- 战场的四分之一

    -- 飞机相对于战场中心的偏移量
    local deltaX = x
    local deltaY = y - _worldHeightHalf

    if deltaX > wcxHalf then
        deltaX = wcxHalf
    elseif deltaX < -wcxHalf then
        deltaX = -wcxHalf
    end

    if deltaY > wcyHalf then
        deltaY = wcyHalf
    elseif deltaY < -wcyHalf then
        deltaY = -wcyHalf
    end

    -- 根据飞机离战场中心的偏移量来计算新的摄像机位置
    --self.cameraX = _cameraXmaxHalf * ( 1 + deltaX  / wcxHalf ) 
    --self.cameraY = _cameraYmaxHalf * ( 1 + deltaY  / wcyHalf ) 
    -- print("cameraXY", x, y, deltaX, deltaY ,self.cameraX, self.cameraY)
end
-------------------------------------------------------------------
-- 撞击相关处理
-------------------------------------------------------------------
local function _mkEffectFuncKey( atkGroup, defGroup )
    return atkGroup * 10000 + defGroup
end

local function _mkCollisionFuncKey( defColliType, atkColliType )
    return defColliType * 10000 + atkColliType
end

-- 攻击( 碰撞 ) 计算
local function _effFunc_mkDmg( world, atkGroup, atkUnits, defGroup, defUnits )
    if not atkUnits or not defUnits then
        return
    end
    local checkSectorRadius = 1
    for _, defUnit in ipairs( defUnits ) do
        if defUnit:canEffect() and defUnit.collisionType ~= 0 and defUnit.cantDmgTime == 0 then
            if defUnit.collisionType == 1 then
                defUnit:refreshRect()
            end
            for __, atkUnit in ipairs( atkUnits ) do
                if atkUnit:canEffect() and atkUnit.collisionType ~= 0 and atkUnit.cantDmgTime == 0 then
                    checkSectorRadius = defUnit.checkSectorRadius + atkUnit.checkSectorRadius + 1
                    if _math_abs(defUnit.sectorXIdx - atkUnit.sectorXIdx) < checkSectorRadius and     --检测分区范围内才进行真正的检验
                       _math_abs( defUnit.sectorYIdx - atkUnit.sectorYIdx) < checkSectorRadius then
                        if atkUnit.collisionType == 1 then
                            atkUnit:refreshRect()
                        end
                        if defUnit.specialType == ENUM_UNIT_SPECIAL_TYPE_COMP_BOSS and 
                           defUnit.state ~= ENUM_UNIT_TYPE_CRAZY and
                           defUnit:isAllComponentDestoryed() == false then
                            local tComponents = defUnit.components
                            if tComponents ~= nil then
                                local key = _mkCollisionFuncKey( 1, atkUnit.collisionType )
                                if key ~= nil then
                                    local collisionFunc = world.collisionFuncs[ key ]
                                    if collisionFunc ~= nil then
                                        for i, v in ipairs( tComponents ) do
                                            if v:isDestoryed() == false then
                                                v.sectorXIdx = atkUnit.sectorXIdx
                                                v.sectorYIdx = atkUnit.sectorYIdx
                                                if collisionFunc( world, v, atkUnit ) then
                                                    atkUnit:getDamage( defUnit.hurt )
                                                    v:getDamage( atkUnit.hurt )
                                                    atkUnit:showHitView( defUnit )
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        else
                            local collisionFunc = world:getCollisionFunc( defUnit, atkUnit )
                            if collisionFunc ~= nil and collisionFunc( world, defUnit, atkUnit ) then
                                atkUnit:getDamage( defUnit.hurt )
                                defUnit:getDamage( atkUnit.hurt )
                                atkUnit:showHitView( defUnit )
                            end
                        end
                    end
                end
            end
        end
    end   
end

-- 道具被我方飞机拾取操作
local function _effFunc_eatItem( world, itemGroup, itemUnits, planeGroup, planeUnits )
    if not itemUnits or not planeUnits then
        return
    end
    local checkSectorRadius = 3
    for _,plane in ipairs(planeUnits) do
        if plane.noEffect ~= true then
            plane:refreshRect();
            for _,item in ipairs(itemUnits) do
                if item.noEffect ~= true then
                    local posX2, posY2 = item:getPosition();
                    if _math_abs(item.sectorXIdx - plane.sectorXIdx) < checkSectorRadius and
                       _math_abs(item.sectorYIdx - plane.sectorYIdx) < checkSectorRadius then
                        item:refreshRect();
                        -- 两个单位都有效,并且矩形相交
                        if item:canEffect() and plane:canEffect() and MathAngle_checkRectsIntersection( item:getRect() , plane:getRect() ) then
                            world:pickItem( item )
                            item:remove()
                            item:showDeadView()
                            item.hp = 0
                        end
                    end
                end
            end
        end
    end

    -- print("mkdmg", world, atkUnits, defUnits)
end

local function _collisionFunc_AABB_AABB( world, defUnit, atkUnit )
    atkUnit:refreshRect();
    return MathAngle_checkRectsIntersection( defUnit:getRect(),  atkUnit:getRect() )
end

local function _collisionFunc_AABB_circle( world, defUnit, atkUnit )
    local rect = defUnit:getRect()
    local circle = { atkUnit.x, atkUnit.y, atkUnit.boundCircleRadius }
    return MathAngle_checkRectAndCircleIntersection( rect,  circle )
end

local function _collisionFunc_AABB_OBB( world, defUnit, atkUnit )
    local xDiff = defUnit.x - atkUnit.x
    local yDiff = defUnit.y - atkUnit.y
    local collisionDistance = (defUnit.boundCircleRadius + atkUnit.boundCircleRadius)
    if ((xDiff * xDiff) + (yDiff * yDiff)) < (collisionDistance * collisionDistance) then
        local auxNode = world.auxNode
        local rect = defUnit:getRect()
        local tWorldPolygonA = 
        {
            { rect[1], rect[2] },
            { rect[3], rect[2] },
            { rect[3], rect[4] },
            { rect[1], rect[4] },
        }
        local tWorldPolygonB = {}
        local w = atkUnit.halfBoundWidth
        local h = atkUnit.halfBoundHeight
        local tPolygonB = { {-w, h}, {w, h}, {w, -h}, {-w, -h} }
        auxNode:setPosition( CCPoint(atkUnit.x,atkUnit.y) )
        auxNode:setRotation( 180 - atkUnit.rotation )
        for i = 1, 4 do
            point = auxNode:convertToWorldSpace( CCPoint(tPolygonB[i][1], tPolygonB[i][2]) )
            tWorldPolygonB[i] = { point.x, point.y }
        end
        return MathAngle_checkPolygonIntersection( tWorldPolygonA,  tWorldPolygonB )
    end
end

local function _collisionFunc_circle_AABB( world, defUnit, atkUnit )
    return _collisionFunc_AABB_circle( world, atkUnit, defUnit )
end

local function _collisionFunc_circle_circle( world, defUnit, atkUnit )
    local xDiff = defUnit.x - atkUnit.x
    local yDiff = defUnit.y - atkUnit.y
    local collisionDistance = (defUnit.boundCircleRadius + atkUnit.boundCircleRadius)
    if ((xDiff * xDiff) + (yDiff * yDiff)) < (collisionDistance * collisionDistance) then
        return true
    end
end

local function _collisionFunc_circle_OBB( world, defUnit, atkUnit )
    local xDiff = defUnit.x - atkUnit.x
    local yDiff = defUnit.y - atkUnit.y
    local collisionDistance = (defUnit.boundCircleRadius + atkUnit.boundCircleRadius)
    if ((xDiff * xDiff) + (yDiff * yDiff)) < (collisionDistance * collisionDistance) then
        local w = defUnit.halfBoundWidth
        local h = defUnit.halfBoundHeight
        local auxNode = world.auxNode
        auxNode:setPosition( CCPoint(0,0) )
        auxNode:setRotation( 180 - atkUnit.rotation )
        local p = auxNode:convertToNodeSpace( CCPoint(xDiff, yDiff ) );
        local rect = { -w, h, w, -h, w, h }
        local circle = { p.x, p.y, defUnit.boundCircleRadius }
        return MathAngle_checkRectAndCircleIntersection( rect,  circle )
    end
end

local function _collisionFunc_OBB_AABB( world, defUnit, atkUnit )
    return _collisionFunc_AABB_OBB( world, atkUnit, defUnit )
end

local function _collisionFunc_OBB_circle( world, defUnit, atkUnit )
    return _collisionFunc_circle_OBB( world, atkUnit, defUnit )
end

local function _collisionFunc_OBB_OBB( world, defUnit, atkUnit )
    local xDiff = atkUnit.x - defUnit.x
    local yDiff = atkUnit.y - defUnit.y
    local collisionDistance = (defUnit.boundCircleRadius + atkUnit.boundCircleRadius)
    if ((xDiff * xDiff) + (yDiff * yDiff)) < (collisionDistance * collisionDistance) then
        if atkUnit:canEffect() and defUnit:canEffect() then
            local w = defUnit.halfBoundWidth
            local h = defUnit.halfBoundHeight
            local auxNode = world.auxNode
            local tPolygonA = { {-w, h}, {w, h}, {w, -h}, {-w, -h} }
            local tWorldPolygonA = {}
            w = atkUnit.halfBoundWidth
            h = atkUnit.halfBoundHeight
            local point 
            local tPolygonB = { {-w, h}, {w, h}, {w, -h}, {-w, -h} }
            local tWorldPolygonB = {}
            auxNode:setPosition( CCPoint(defUnit.x,defUnit.y) )
            auxNode:setRotation( 180 - defUnit.rotation )
            for i = 1, 4 do
                point = auxNode:convertToWorldSpace( CCPoint(tPolygonA[i][1], tPolygonA[i][2]) );
                tWorldPolygonA[i] = { point.x, point.y }
            end
            auxNode:setPosition( CCPoint(atkUnit.x,atkUnit.y) )
            auxNode:setRotation(  180 - atkUnit.rotation )
            for i = 1, 4 do
                point = auxNode:convertToWorldSpace( CCPoint(tPolygonB[i][1], tPolygonB[i][2]) );
                tWorldPolygonB[i] = { point.x, point.y }
            end
            return MathAngle_checkPolygonIntersection( tWorldPolygonA,  tWorldPolygonB )
        end
    end
end

-- 注册撞击处理函数
function cWorld:regEffectFuncs( )
    local key

    -- 敌方子弹对我方飞机
    key = _mkEffectFuncKey( UG_BULLET_ENEMY,  UG_PLANE )
    self.effectFuncs[ key ] = _effFunc_mkDmg

    -- 敌机对我方飞机
    key = _mkEffectFuncKey( UG_ENEMY,  UG_PLANE )
    self.effectFuncs[ key ] = _effFunc_mkDmg

    -- 我方子弹对敌机
    key = _mkEffectFuncKey( UG_BULLET,  UG_ENEMY )
    self.effectFuncs[ key ] = _effFunc_mkDmg

    -- 道具对我方飞机
    key = _mkEffectFuncKey( UG_ITEM,  UG_PLANE )
    self.effectFuncs[ key ] = _effFunc_eatItem

end

function cWorld:regCollisionFuncs()
    local key
    key = _mkCollisionFuncKey( 1, 1 )
    self.collisionFuncs[key] = _collisionFunc_AABB_AABB
    key = _mkCollisionFuncKey( 1, 2 )
    self.collisionFuncs[key] = _collisionFunc_AABB_circle
    key = _mkCollisionFuncKey( 1, 3 )
    self.collisionFuncs[key] = _collisionFunc_AABB_OBB
    key = _mkCollisionFuncKey( 2, 1 )
    self.collisionFuncs[key] = _collisionFunc_circle_AABB
    key = _mkCollisionFuncKey( 2, 2 )
    self.collisionFuncs[key] = _collisionFunc_circle_circle
    key = _mkCollisionFuncKey( 2, 3 )
    self.collisionFuncs[key] = _collisionFunc_circle_OBB
    key = _mkCollisionFuncKey( 3, 1 )
    self.collisionFuncs[key] = _collisionFunc_OBB_AABB
    key = _mkCollisionFuncKey( 3, 2 )
    self.collisionFuncs[key] = _collisionFunc_OBB_circle
    key = _mkCollisionFuncKey( 3, 3 )
    self.collisionFuncs[key] = _collisionFunc_OBB_OBB
end

-- 根据攻防双方的组别,找到对应的处理函数
function cWorld:getEffectFunc( atkGroup, defGroup )
    local key = _mkEffectFuncKey( atkGroup, defGroup )
    return self.effectFuncs[ key ]
end

function cWorld:getCollisionFunc( defUnit, atkUnit )
    local key = _mkCollisionFuncKey( defUnit.collisionType, atkUnit.collisionType )
    return self.collisionFuncs[ key ]
end

-- 撞击效果计算
function cWorld:updateEffect()
    -- 准备进行撞击
    local units = self.units
    local activeFlags = self.activeFlags

    local func
    for atkGroup,defGroup in pairs(GROUP_AFFECT_LIST) do

        --if activeFlags[atkGroup] and activeFlags[defGroup] then
            func = self:getEffectFunc(atkGroup, defGroup)
            if func then
                func(self, atkGroup, units[atkGroup], defGroup, units[defGroup] )
            end
        --end

    end
end

-- 在游戏世界中添加效果动画
function cWorld:addEffectAnim(animId, playOnce, x, y, zorder, scale )
    local sp,cfg = Factory.createAnim(animId, playOnce, playOnce, nil, nil)
    if not cfg or not sp then
        return
    end

    if cfg.batchNodeKey then
        local batchNode = self:ensureBatchNode(cfg, zorder)
        sp:pos(x, y)
        sp:addTo(batchNode, zorder)
        sp:setScale( scale or 1)
    else
        sp:pos(x, y)
        sp:setScale( scale or 1)
        self.scene:addChild(sp, UZ_EFFECT_ANIM)
    end
end

-- 根据道具ID数组创建多个道具对象,并控制创建的道具对象的位置/角度间隔
function cWorld:addItemes(itemIds, x, y)

    local count = #itemIds
    if count <= 0 then 
        return
    end

    local angleDistance
    if count <= 4 then
        angleDistance = math.pi / 6.0
    elseif count <= 8 then
        angleDistance = math.pi / 9.0
    else
        angleDistance = math.pi / 18.0
    end

    local startAngle = -(count - 1.0) * 0.5 * angleDistance

    for _, itemId in ipairs(itemIds) do

        local item = Factory.createItemById(itemId)
        if item then
            self:addUnit(UG_ITEM, item, UZ_PLANE)

            if item.moveType ~= 0 then
                startAngle = math.random() * math.pi * 2.0
            end
            item:startAngle(startAngle)
            item:pos(x, y)

            startAngle = startAngle + angleDistance
        end --end if
    end --end for

end --end function

-- 处理拾取到一个道具的逻辑
function cWorld:pickItem(item)
    local props = self.pickedProps[item.classify]
    if props and props.funPick then
        props:funPick(self, item.classify, item.count)
    end
end

-- 根据坐标和群组id, 寻找最近的目标
function cWorld:getRandomUnit( x, y, groups )
    if not groups then
        return nil
    end
    local units = self.units
    local list
    for _,gid in ipairs(groups) do
        list = units[gid]
        if list then
            for _,target in ipairs(list) do
                if target.group == gid and target:isValid() then
                    return target
                end
            end
        end
    end

    return nil

end

function cWorld:useBomb(props)

    local list = self.units[UG_ENEMY]
    if list then
        for i, enemy in ipairs(list) do
            enemy:getDamage(props.power)
        end
    end

    list = self.units[UG_BULLET_ENEMY]
    if list then
        for i, bullet in ipairs(list) do
            bullet:getDamage(props.power)
        end
    end

end

function cWorld.showPlaneIndex()
    return showPlaneId
end

function cWorld:convertToScreen(xWorld, yWorld, zvalue)
	-- local modify = UZ_TO_XY_MODIFY[ zvalue ] or 1
	-- return x -  self.cameraX * modify + _worldWidthHalf, y - ( self.cameraY * modify )
    --local modify = UZ_TO_XY_MODIFY[ zvalue ] or 1
    --local xScreen = xWorld + CONFIG_SCREEN_WIDTH / 2 - self.cameraX * modify
    --local yScreen = yWorld - self.cameraY * modify
    --return xScreen, yScreen
    return xWorld + CONFIG_SCREEN_WIDTH_HALF - self.cameraX, yWorld - self.cameraY
end

function cWorld:convertToWorld(xScreen, yScreen, zvalue)
	-- local modify = UZ_TO_XY_MODIFY[ zvalue ] or 1
	-- return x +  self.cameraX * modify - _worldWidthHalf , y + ( self.cameraY * modify )
    local modify = UZ_TO_XY_MODIFY[ zvalue ] or 1
    local xWorld = xScreen - CONFIG_SCREEN_WIDTH / 2 + self.cameraX * modify
    local yWorld = yScreen - self.cameraY * modify
    return xWorld, yWorld
end

-------------------------------------------------------------------
-- test
-------------------------------------------------------------------
function cWorld:testEnemy( )
    local aiId = 30002
    local planeId = 20002

    local plane = Factory.getUnit( planeId )

    plane:pos( -10, 400)
    -- plane:pos( CONFIG_WORLD_CX,CONFIG_WORLD_CY)
    self:addUnit(UG_PLANE, plane, UZ_PLANE)

    local ai = Factory.createAI( aiId, false, false )
    plane.AI = ai
    ai:nextCmd( plane, 0 )


    local aiId = 30002
    local planeId = 20002

    local plane = Factory.createPlaneById( planeId )
    
    plane:pos( 370, 400)
    -- plane:pos( CONFIG_WORLD_CX,CONFIG_WORLD_CY)
    self:addUnit(UG_PLANE, plane, UZ_PLANE)

    local ai = Factory.createAI( aiId, true, false )
    plane.AI = ai
    ai:nextCmd( plane, 0 )    
end


function cWorld:testSpirite( )
    -- ui.newTTFLabel({text = "Hello, World", size = 64, align = ui.TEXT_ALIGN_CENTER})
    --     :pos(CONFIG_WORLD_CX,CONFIG_WORLD_CY)
    --     :addTo(self.scene)
end

function cWorld:testAnim( )
    display.addSpriteFrames("png/boom.plist", "png/boom.png") -- 载入图像到帧缓存 
    -- -- 创建一个数组，包含 Walk0001.png 到 Walk0008.png 的 8 个图像帧对象

    local frames = display.newFrames("zd%01d.png", 0, 4)
    local animation = display.newAnimation(frames, 0.5 / 4) -- 0.5 秒播放 4 桢    
    display.setAnimationCache("zdboom", animation)

    -- local sp = display.newSprite("#zd0.png")
    -- sp:addTo( self.scene , 10000)
    -- sp:pos( 160, 320 )    
    
    -- 在需要使用 zdboom 动画的地方
    animation = display.getAnimationCache("zdboom")

    -- sp:playAnimationForever( animation ) -- 播放动画



     -- display.addSpriteFramesWithFile("png/boom.plist", "png/boom.png") --添加帧缓存
     -- local sp = display.newSprite("#zd0.png", display.cx, display.cy)
     -- self.scene:addChild(sp, 10000 )
     -- local frames = display.newFrames("zd%d.png", 0, 4)
     -- local animation = display.newAnimation(frames, 0.5/4)
     -- sp:playAnimationForever(animation)    
end



function cWorld:testBatchNode()
    -- local plistName = "png/bullet.plist"
    -- local imageName = "png/bullet.png"

    -- display.addSpriteFrames(plistName, imageName) -- 载入图像到帧缓存 

    -- local bulletBatchNode  = display.newBatchNode(imageName)
    -- self.bulletBatchNode = bulletBatchNode

    -- bulletBatchNode:addTo(self.scene)

    -- local count = 1000
    -- local key,sp
    -- for i = 1, count do
    --     key, sp = Factory.createAnim( 11101 )
    --     bulletBatchNode:addChild(sp)
    --     -- sp:addTo(self.scene)
    --     sp:pos( CONFIG_WORLD_CX,CONFIG_WORLD_CY)
    -- end    
end
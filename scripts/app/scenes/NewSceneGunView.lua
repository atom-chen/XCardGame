local tinsert = table.insert

local SceneBaseClass = import("app/scenes/SceneBaseClass")

local NewSceneGunView = class("NewSceneGunView", SceneBaseClass )

function NewSceneGunView:onCreate()
end

function NewSceneGunView:onEnter()
    Factory.clearUnitPool()
    local uiManager = MyApp.uiManager
    local function callback()
        local uiGunView = uiManager:getUIByName( "UIGunView" )
        if uiGunView ~= nil then
            local worldNode = uiGunView:seekNodeByPath( "worldNode" )
            if worldNode ~= nil then
                self.world = cWorld.new( worldNode, nil, 69999 )
                self.world:onEnter()
                local tBgs = self.world:getUnitsByGroup( UG_BG )
                if tBgs ~= nil then
                    for i, v in ipairs( tBgs ) do
                        v.view:setVisible( false )
                    end
                end
                self:changeEnemy( 21003 )
                if self.world.plane ~= nil then
                    self.world.plane:pos( 0, 300 )
                    self.world.plane:stopGuns()
                    self.world:removeAllWingman()
                end
            end
        end
    end
    uiManager:showUI( "UIGunView", true, callback )
    -- 启动帧侦听
    self:scheduleUpdate()  
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function( dt ) self:update(dt) end)
end

function NewSceneGunView:onExit()
end

function NewSceneGunView:changeGuns( plane, newGunId )
    
    -- 删除现有的枪
    -- self:deleteGuns()
    local gunIds = { newGunId }

    -- 删除新枪组里没有的枪
    local guns = {}
    if plane.guns then
        for i,gun in ipairs(plane.guns) do

            -- 检查新添加的枪组里是否有,没有则删除
            local finded = false
            for _, id in ipairs(gunIds) do
                finded = finded or (id == gun.id)
            end

            if not finded then
                gun:onDelete()
            else
                tinsert(guns, gun)
            end
        end
    end

    -- 添加新枪
    for i, gunId in ipairs(gunIds) do
        local finded = false
        for _, gun in ipairs(guns) do
            finded = finded or (gunId == gun.id)
        end

        -- 现有的枪组里没有的,添加之
        if not finded then
            local gun = Factory.createGunById(gunId) 
            if gun then
                gun.masterUnit = plane
                gun.noEffect = self.notCalcEffect
                tinsert(guns, gun)
            end
        end
    end

    plane.guns = guns
end

function NewSceneGunView:changeEnemy( nEnemyId )
    if self.enemy ~= nil then
        self.enemy:remove()
        self.enemy = nil
    end
    self.enemy = Factory.getUnit( nEnemyId, 1 )
    if self.enemy ~= nil then
        if nEnemyId >= 20001 and nEnemyId <= 20100 then
            self.world:addUnit(UG_ITEM, self.enemy, UZ_ENEMY )
        else
            self.world:addUnit(UG_ENEMY, self.enemy, UZ_ENEMY )
        end
        self.enemy:pos( 0, 800 );
        self.enemy.noEffect = self.notCalcEffect;
        if self.enemy.lifeBar ~= nil then
            local lifeBar = self.enemy.lifeBar
            if lifeBar then
                lifeBar:pos( self.enemy.lifePosition.x, 800 + self.enemy.lifePosition.y)
            end
        end
        for i, gun in ipairs( self.enemy.guns ) do
            gun.masterUnit = self.enemy
            gun.noEffect = self.notCalcEffect;
        end
    end
end

function NewSceneGunView:update(dt)
    if self.world ~= nil then
        self.world:update( dt )
    end
    if app.uiManager ~= nil and app.uiManager.update ~= nil then
        app.uiManager:update( dt )
    end
end

return NewSceneGunView
--cProps 道具数据，在战斗外存在的数据
--cItem 道具单元，在战斗中屏幕上的一个表现单位

cItem = class("cItem", cUnit)

function cItem:ctor( unitType, cfg )
    cUnit.ctor( self, unitType, nil )

    self.classify = 0           -- 道具分类: 0-金币, 1-升级, 2-火力
    self.count = 0              -- 道具数量,主要针对金币
    self.dampingX = 0.0         -- X方向的阻尼系数
    self.initSpeed = 0.0        -- 初始速度
    self.following = false      -- 一旦进入跟随距离以内后,就将一直跟随
    self.followDistance = 0     -- 跟随飞机距离,全屏跟踪则设置较大的数
    self.attraction = 0         -- 吸引力,决定了靠近飞机的速度
    self.moveType = 0
    self.cfgMoveType = 0

    self:initByCfg( cfg )
end

function cItem:initByCfg( cfg )
	if not cfg then
		return false
	end

	self.cfgId = cfg.id
	self.group = cfg.group
    self.hp = 1

    self.classify = cfg.classify
    self.count = cfg.count
    self.acceleration = cfg.G
    self.dampingX = cfg.dampingX
    self.initSpeed = cfg.initSpeed
    self.followDistance = cfg.followDistance
    self.attraction = cfg.attraction
    self.moveType = cfg.moveType
    self.cfgMoveType = cfg.moveType

	-- 外观相关处理
	self.viewIds = cfg.viewIds 	-- 行动姿态,对应八个方向
	self.currentViewId = self.viewIds[self.unitLevel]
	self.deadViewId = cfg.deadViewId

	if not self.currentViewId then
		self.currentViewId = self.viewIds[1]
	end

	self:setView(self.currentViewId) -- 设置默认外观

	return true
end

-- 每帧update
function cItem:update( dt )

	if not self:isValid() then
		return
	end

    if self.moveType == 0 then
	    self:move(dt)
    elseif self.moveType == 1 then
        self:move2(dt)
    end

    local x, y = self:getPosition()
	if y < -32 then
		self:remove()
	end

end

-- 求解一元两次方程的两个跟
function cItem.QuadraticEquations(a,b,c)
    local delta = b * b - 4 * a * c
    if delta < 0 then
        return nil, nil
    end

    local sqrt_delta = math.sqrt(delta)
    local a2 = 2 * a
    return (-b + sqrt_delta) / a2, (-b - sqrt_delta) / a2
end

-- 基础移动函数
function cItem:move( dt )
	if not self.view then
		return
	end

    --获得道具的位置
	local x,y = self:getPosition()

    local plane = self.world.plane

    local speedX
    if plane and (plane.hp > 0) then

        --获得飞机的位置
        local tx,ty = plane:getPosition()
        --计算道具与飞机之间的距离差
        local dx,dy = tx - x, ty - y

        --道具在上升途中不进入跟随模式，以完整的表现多个道具的爆炸效果
        --(也为了后面一元二次方程的第二个解是真正需要的解)
        if not self.following and self.speedY < 0 then
            local distance = math.sqrt(dx * dx + dy * dy)
            --检测与飞机的距离,小于跟随距离则进入跟随模式
            if distance <= self.followDistance + plane:adsorptionDistance() then
                self.following = true
            end
        end
    
        if self.following and y > ty then   --跟随模式下,道具在飞机的上方
            --根据道具与飞机的垂直距离,重力加速度,当前速度计算 道具到达飞机高度需要的时间t
            local _, t = cItem.QuadraticEquations(self.acceleration * 0.5, self.speedY, -dy)
            --在t时间内,道具与飞机的横向距离为0,则目标速度speedX应该是:
            speedX = dx * 2 / t - self.speedX
        else
            --因为初始的时候,道具是向四周爆炸开来的,为了避免道具分散太开,在横向做阻尼计算,从而不断减小横向的速度
            speedX = self.speedX - self.speedX * self.dampingX * dt
        end

    else
        --因为初始的时候,道具是向四周爆炸开来的,为了避免道具分散太开,在横向做阻尼计算,从而不断减小横向的速度
        speedX = self.speedX - self.speedX * self.dampingX * dt
    end

    --道具纵向速度受重力加速度影响
    local speedY = self.speedY + self.acceleration * dt

	x = x + (self.speedX + speedX) * dt * 0.5
	y = y + (self.speedY + speedY) * dt * 0.5
    self.speedX = speedX
    self.speedY = speedY

	self:pos(x, y)

	return x, y
end

-- 在屏幕内弹跳的版本
function cItem:move2( dt )
	if not self.view then
		return
	end

    -- 当飞机有效的时候, 可转入吸附模式
    --[[
    local plane = self.world.plane
    if plane and (plane.hp > 0) then
        --获得飞机的位置
        local tx,ty = plane:getPosition()
        if self.y - 100 > ty or self.y > display.height - 50 then
            self.moveType = 0
            self.following = true

            return self:move(dt)
        end
    end
    --]]
    
	local world = self.world

    --获得屏幕内坐标
    local x, y = world:convertToScreen(self.x, self.y, self.zvalue)

    --计算屏幕坐标系下新的位置
	x = x + self.speedX * dt
	y = y + self.speedY * dt

    --限定在屏幕范围内
    if x < 0 then
        x = -x
        self.speedX = math.abs(self.speedX)
    end
    if x > display.width then 
        x = display.width * 2 - x
        self.speedX = -math.abs(self.speedX) 
    end
    if y < 0 then 
        y = -y
        self.speedY = math.abs(self.speedY) 
    end
    if y > display.height then 
        y = display.height * 2 - y
        self.speedY = -math.abs(self.speedY) 
    end

    --转换为战场中的坐标
    x, y = world:convertToWorld(x, y, self.zvalue)

    --更新位置
    self:pos(x, y)

	return x, y
end

-- 根据角度设置初始的X,Y方向的速度
function cItem:startAngle(angle)
    self.speedX = math.sin(angle) * self.initSpeed
    self.speedY = math.cos(angle) * self.initSpeed
end

function cItem:onEntrance()
    self.hp = 1
    self.moveType = self.cfgMoveType
end

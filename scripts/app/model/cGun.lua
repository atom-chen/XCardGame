	local tinsert = table.insert
local tremove = table.remove

cGun = class( "cGun" )

local BULLET_TYPE_NORMAL = 1

local bulletGroupInfoMap = {}

function cGun:ctor(masterUnit)

	self.masterUnit 			= nil

    self.id                     = 0
    self.wingman                = false -- 僚机的枪否
	self.bulletGroupList 		= nil 	-- 子弹组
	self.bulletCache 			= {} 	-- 子弹池

	-- 相对挂载者的坐标
	self.deltaX					= 0
	self.deltaY					= 0

	self.fireDeltaTime 		    = nil  	-- 开火间隔
	self.fireTime 			    = 0		-- 还有多久进行下一次开会
	self.fireDelayTime			= 0 	-- 延迟开火
    self.sndShoot               = nil
    self.hurtModifier			= 1
    self.stopFire				= false
end

function cGun:initByCfg( cfg )
	if not cfg then
		return false
	end

	-- Logger.printTable( cfg )

    self.id                 = cfg.id
    self.wingman            = cfg.wingman
	self.bulletGroupIds 	= cfg.bulletGroupIds
	self.fireDeltaTime 		= cfg.fireDeltaTime
	self.fireDelayTime 		= cfg.fireDelayTime
    self.sndShoot           = cfg.sndShoot

	self.deltaX 			= cfg.points[1]
	self.deltaY 			= cfg.points[2]

	self:initBulletGroupInfo( cfg )
	return true
end

function cGun:initBulletGroupInfo( cfg )
	if bulletGroupInfoMap[cfg.id] == nil then
		bulletGroupInfoMap[cfg.id] = {}
		for i, id in ipairs( cfg.bulletGroupIds ) do
			local bulletGroupCfg = CfgData.getCfg( CFG_BULLETS_GROUP, id )
			if bulletGroupCfg ~= nil then
				self:createBulletGroupNormal( bulletGroupCfg )
				Factory.addBulletCacheId( bulletGroupCfg.unitId )
			end
		end
	end
end

function cGun:update( dt )
	if self.stopFire == true then
		self:updateBulletCache( dt )
		return
	end
	if self.fireDelayTime > 0 then
		local t = self.fireDelayTime - dt
		if t > 0 then
			self.fireDelayTime = t
			self:updateBulletCache( dt )
			return
		end
	end
	local t = self.fireTime - dt
	if t <= 0 then
		self.fireTime = t + self.fireDeltaTime
		self:fire()
	else
		self.fireTime = t
	end

	self:updateBulletCache( dt )
end

function cGun:getPosition()
	local x,y =  self.masterUnit:getPosition()
	return self.deltaX + x , self.deltaY + y
end

function cGun:getWorld()
	return self.masterUnit.world
end


function cGun:fire( )
	local bulletInfo = bulletGroupInfoMap[self.id];
	if bulletInfo ~= nil then
		local bulletCache = self.bulletCache
		for i, v in ipairs( bulletInfo ) do
			tinsert( bulletCache, { delayTime = v.delayTime or 0, info = v } )
		end
	end

    if self.sndShoot then audio.playSound(self.sndShoot) end
end

function cGun:createBulletGroupNormal( cfg )
	local unitId = cfg.unitId
	local unitCfg = CfgData.getCfg( CFG_UNIT, unitId )
	if not unitCfg then
		return
	end

	local bulletInfo = bulletGroupInfoMap[self.id];
	if bulletInfo == nil then
		return;
	end
    local startX = cfg.startX
    local startY = cfg.startY
    local deltaX = cfg.deltaX
    local deltaY = cfg.deltaY
    local startAngle = cfg.startAngle
    local deltaAngle = cfg.deltaAngle
    local speed = cfg.speed
    local count = cfg.count
    local startTime = cfg.startTime
    local deltaTime = cfg.deltaTime
    local rotSpeed = cfg.rotSpeed
	local bulletId, bullet
    local x, y
    local angle, lifeTime, time
    local info
	local acceleration = cfg.acceleration
	local speedMin = cfg.speedMin
	local speedMax = cfg.speedMax   
	local unitAI = cfg.unitAI 

	lifeTime = 0

	x = cfg.startX
	y = cfg.startY
	angle = startAngle
	delayTime = startTime

    for i=0,count - 1 do
    	info = {}

		info.unitId = unitId
		info.x = x
		info.y = y
		info.speed = speed
		info.angle = angle
		info.delayTime = delayTime
		info.acceleration = acceleration
		info.speedMin = speedMin
		info.speedMax = speedMax
		info.unitAI = unitAI
		info.rotSpeed = rotSpeed

	    tinsert( bulletInfo, info)   
        x = x +  deltaX
        y = y +  deltaY
        angle = angle + deltaAngle	 
        delayTime = delayTime + deltaTime
    end


    -- x轴镜像
    if cfg.yMirror  == 1 then
	    startX = -cfg.startX
	    startY = cfg.startY
	    deltaX = -cfg.deltaX
	    deltaY = -cfg.deltaY    	
    	startAngle = -cfg.startAngle
    	deltaAngle = -cfg.deltaAngle

		x = startX
		y = startY
		angle = startAngle
		delayTime = startTime

   		for i=0,count - 1 do
	    	info = {}
	    	
			info.unitId = unitId
			info.x = x
			info.y = y
			info.speed = speed
			info.angle = angle
			info.delayTime = delayTime
			info.acceleration = acceleration
			info.speedMin = speedMin
			info.speedMax = speedMax
			info.unitAI = unitAI
			info.rotSpeed = rotSpeed

		    tinsert( bulletInfo, info)   


	        x = x +  deltaX
	        y = y +  deltaY
	        angle = angle + deltaAngle	 
	        delayTime = delayTime + deltaTime
	    end
    end
end

function cGun:updateBulletCache( dt )
	if #self.bulletCache <= 0 or self.masterUnit == nil then
		return
	end
	local bulletCache = self.bulletCache
	local gunX, gunY = self:getPosition()
	local x, y
	local world = self:getWorld()
	local unit = self.masterUnit
	local addHurt, mulHurt = unit:getHurt()
	local group = UNIT_GROUP_TO_BULLET_GROUP[unit.group]  or UG_BG
	local zvalue = UZ_TO_BULLET_Z[unit.zvalue] or UZ_ENEMY_BULLET
	local keepedBulletCache = {}
	local bullet, moveDt, cacheInfo, info, delayTime
	for i, cacheInfo in ipairs( bulletCache ) do
		if cacheInfo.delayTime <= 0 then
			info = cacheInfo.info
			-- 到达发射时间了
			Factory.addBulletCacheId(info.unitId)
	        bullet = Factory.getUnusedBullect(info.unitId)
			world:addUnit(group, bullet, zvalue)
            bullet.masterUnit = unit
			bullet:setAcceleration( info.acceleration , info.speedMin, info.speedMax)
	        bullet:setSAR( info.speed, info.angle, info.angle + 180)
	        bullet.rotSpeed = info.rotSpeed
	        bullet:setLifeTime( info.lifeTime )
			--moveDt = -info.delayTime 暂时不进行位置修正
			-- 根据枪的当前位置进行子弹的位置修正
			x = info.x + gunX
			y = info.y + gunY
			bullet.x = x
			bullet.y = y
			bullet.hp = bullet.maxHP
			--bullet:move(-info.delayTime)
            -- 调整子弹伤害数值
            bullet.hurt = addHurt
            if bullet.specialType == ENUM_UNIT_SPECIAL_TYPE_BOMB_BULLET then
            	bullet.explosionDmg = addHurt * bullet.explosionDmg
            end
			if info.unitAI ~= 0 then
				if bullet.AI ~= nil then
                	bullet.AI:reset()
                else
                	bullet:setAI( info.unitAI, false, false )
               	end
			end
		else
			cacheInfo.delayTime = cacheInfo.delayTime - dt
			tinsert( keepedBulletCache, cacheInfo )
		end
	end
	self.bulletCache = keepedBulletCache
end


-- 单位被删除时的调用
function cGun:onDelete( )
	self.bulletCache = {}
end

function cGun:setModifier( hurtModifier )
	self.hurtModifier = hurtModifier
end

function cGun:remove()
end


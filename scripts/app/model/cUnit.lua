local tinsert = table.insert
local _mathfloor = math.floor
local _mathPow = math.pow
local _mathSqrt = math.sqrt
local _math_sin = math.sin
local _math_cos = math.cos
--[[
	ËùÓÐµ¥Î»µÄ»ù´¡Àà
]]

local cComponent = import("app/model/cComponent")

-- local class = require("bdlib/lang/class")
-- cUnit = class( "cUnit",  function() return display.newNode() end )
cUnit = class("cUnit")

function cUnit:ctor( unitType, cfg )

	self.scene 			= nil
	self.world 			= nil
	self._type 			= unitType
	self.needDel 		= false -- É¾³ý±ê¼Ç
	self.stopFire       = false -- Í£Ö¹¿ª»ð
	self.fireDelayTime	= 0

	self.cfgId 			= 0 -- µ¥Î»µÄÔ­Ê¼ÅäÖÃid

	self.angle 			= 0	-- unitµÄ½Ç¶È

	self.speed 			= 0	-- unitµÄÏßËÙ¶È
	self.acceleration	= 0 -- unitµÄ¼ÓËÙ¶È
	self.speedMax 		= 0 -- ËÙ¶ÈÉÏÏÞ(0±íÊ¾Ã»ÓÐÏÞÖÆ)
	self.speedMin 		= 0 -- ËÙ¶ÈÏÂÏÞ(0±íÊ¾Ã»ÓÐÏÞÖÆ)

	self.speedX 		= 0	-- unitÔÚXÖáµÄ·ÖËÙ¶È
	self.speedY 		= 0	-- unitÔÚYÖáµÄ·ÖËÙ¶È

	self.rotation 		= 0 -- Ðý×ª½Ç¶È
	self.rotSpeed		= 0 -- Ðý×ªËÙ¶È
	self.collisionType	= 0 -- Åö×²¼ì²âÀàÐÍ

	self.lifeTime 		= 0	-- ´æ»îÊ±¼ä
	self.delayTime		= 0 -- ÑÓ³ÙÊ±¼ä( ÓÃÓÚÄ³Ð©Çé¿öÏÂµÄÑÓÊ±Ê±¼ä¼ÆËã, ±ÈÈç×Óµ¯µÄÑÓ³Ù½øÈë³¡µØ )


	self.viewIds 		= nil 	-- ÐÐ¶¯×ËÌ¬,¶ÔÓ¦°Ë¸ö·½Ïò
	self.view 			= nil 	-- µ±Ç°¶¯»­¶ÔÏó
	self.viewCfg 		= nil 	-- µ±Ç°viewµÄÅäÖÃÐÅÏ¢

	self.AI 			= nil 	-- AI¶ÔÏó
    self.team           = nil   -- ËùÊôµÄ¶ÓÎé¶ÔÏó{memberCount = 0, dropIds = nil}

	self.group 			= 0 	-- ËùÊô×é±ð(ÓÃÓÚ´¦ÀíµÐ¶Ô¹ØÏµ)
	self.zvalue 		= UZ_PLANE -- ËùÊô²ã´Î
	self.guns 			= nil 	-- Ç¹
    self.guns__         = nil   -- ÅäÖÃ±íÀïµÄÇ¹
    self.gunLevels__    = nil   -- ÅäÖÃ±íÀïµÄÇ¹Éý¼¶µÄÊý×é
	self.hp 			= 0 	-- µ±Ç°ÑªÁ¿
    self.maxHP          = 0     -- ×î´óÑªÁ¿,ÓÃÓÚUI±íÏÖÑªÌõ
	self.hurt 			= 0 	-- ×²»÷ÉËº¦ 
	self.hitViewId 		= nil 	-- ×²»÷ÌØÐ§
	self.deadViewId 	= nil 	-- ËÀÍöÌØÐ§
    self.dropIds        = nil   -- µôÂäÁÐ±í
    self.sndExplosion   = nil   -- ±¬Õ¨ÒôÐ§

	self.unitLevel      = 1     -- ³õÊ¼µÈ¼¶

    self.invncibleTime  = 0     -- ÎÞµÐÊ£ÓàÊ±¼ä

    self.animates       = nil   -- ËùÓÐµÄ¸½¼Ó¶¯»­[animateId] = {animate,duration}
    self.debug_box      = nil   -- µ÷ÊÔ°üÎ§ºÐ

    self.lifePosition   = nil   -- ÑªÌõÎ»ÖÃ
    self.lifeBar        = nil   -- ÑªÌõ
    self.delBulletOnDead = false

    self.gunHurtModifier= 1 	-- 枪攻击系数
    self.specialType 	= 0
    self.sectorXIdx		= -99
    self.sectorYIdx		= -99
    self.selfExplosionTime = nil
    self.cantDmgTime = 0
    self.state 			= 0 	
	if cfg then
		self.initByCfg( cfg )
	end

	self.x 				= 0
	self.y 				= 0
	self.checkSectorRadius = 1
	self.boundCircleRadius = 1
end

function cUnit:dtor()
    self.scene = nil
    self.world = nil
	self.AI = nil
    self.team = nil
	self.guns = nil
    self.guns__ = nil
    self.gunLevels__ = nil
	self.viewIds = nil
	self.viewCfg = nil
	self.hitViewId = nil
	self.deadViewId = nil
    self.dropIds = nil
    self.sndExplosion = nil
    self.animates = nil
    self.selfExplosionTime = nil

    if self.view then
        self.view:removeFromParentAndCleanup(true)
        self.view:release()
        self.view = nil
    end
    if self.specialType > 1000 then
    	if self.lifeBar then
	        self.lifeBar:removeFromParentAndCleanup(true)
	        self.lifeBar:release()
	        self.lifeBar = nil
	    end
    	for i, v in ipairs( self.components ) do
    		if v.lifeBar ~= nil then
    			v.lifeBar:removeFromParentAndCleanup(true)
    		end
    	end
    end
end

-- ¿ÉÒÔÁ¢¼´É¾³ýµÄÇåÀí
function cUnit:remove()
	self.needDel = true
    local animates = self.animates
	if animates then
        for _, animate in pairs(animates) do
            animate.target:removeFromParentAndCleanup(true)
        end
        self.animates = nil
	end
    if self.specialType > 1000 then
    	for i, v in ipairs( self.components ) do
    		if v.lifeBar ~= nil then
    			v.lifeBar:removeFromParentAndCleanup(false)
    		end
    	end
    end
end

-- ÐèÒªÑÓ³ÙÉ¾³ýµÄÇåÀí
function cUnit:onDelete( )
	self:deleteGuns()
end

-- ×îºóµÄÒýÓÃÇåÀí
function cUnit:onExit()
    if self.view then
        self.view:removeFromParentAndCleanup(false)
    end
    if self.specialType > 1000 then
    	if self.lifeBar then
	        self.lifeBar:removeFromParentAndCleanup(false)
	    end
    	for i, v in ipairs( self.components ) do
    		if v.lifeBar ~= nil then
    			v.lifeBar:removeFromParentAndCleanup(false)
    		end
    	end
    end
end

function cUnit:initByCfg(cfg)
	if not cfg then
		return false
	end

	self.cfgId          = cfg.id
	self.group 			= cfg.group 	-- ËùÊô×é±ð(ÓÃÓÚ´¦ÀíµÐ¶Ô¹ØÏµ)
	self.type 			= cfg.type 		-- ÀàÐÍ
	self.AI 			= nil           -- AIÁÐ±í
	self.components		= {}			-- ²¿¼þ

    self.guns__         = cfg.guns
    local gunLevels     = CfgData.getCfg(CFG_GUN_LEVLES, cfg.gunLevels)
    if gunLevels then
        self.gunLevels__ = {}
        for _, guns in ipairs(gunLevels) do
            tinsert(self.gunLevels__, guns.guns)
        end
    end
    self:changeGuns(1)

	self.hp 			= cfg.hp
    self.maxHP          = cfg.hp
	self.hurt 			= cfg.hurt
	self.hurtBase 		= cfg.hurt

    local lifeBarName = cfg.lifeBar
    local lifePosition = cfg.lifeBarPosition
    self.lifePosition   = lifePosition
    if lifeBarName and string.len(lifeBarName) > 0 then
        local lifeBar, width, height = cc.uiloader:load("res/ui/bloodBar.json")
        lifeBar = ccuiloader_seekNodeEx(lifeBar, lifeBarName)
        if lifeBar then
            local progress_ui = ccuiloader_seekNodeEx(lifeBar, "progress")
	        if progress_ui ~= nil then
	        	progress_ui:setPercent( 100 )
	        end	
            lifeBar:retain()
            lifeBar:setVisible(true)
            lifeBar:removeFromParentAndCleanup(false)
        end
        self.lifeBar = lifeBar
    end

	-- Íâ¹ÛÏà¹Ø´¦Àí
	self.viewIds 		= cfg.viewIds 	-- ÐÐ¶¯×ËÌ¬,¶ÔÓ¦°Ë¸ö·½Ïò

	self.currentViewId = self.viewIds[self.unitLevel]

	if not self.currentViewId then
		self.currentViewId = self.viewIds[1]
	end

	self:setView(self.currentViewId) -- ÉèÖÃÄ¬ÈÏÍâ¹Û

	self.hitViewId 		= cfg.hitViewId
	self.deadViewId 	= cfg.deadViewId
    self.dropIds        = cfg.dropIds
    self.sndExplosion   = cfg.sndExplosion
    self.delBulletOnDead= cfg.delBullet
    self.collisionType	= cfg.collisionType
    self.specialType 	= cfg.specialType or 0

    if self.specialType ~= 0 then
    	self:initComponents()
		self.params1 = cfg.params1
		self.params2 = cfg.params2
		if self.specialType == ENUM_UNIT_SPECIAL_TYPE_BOMB_BULLET then
			self:setSelfExplosionData( nil, tonumber(self.params1[1]), tonumber(self.params1[2]) )
		end
	end
	return true
end

function cUnit:initComponents()
	local tComponentData = CfgData.getCfg( CFG_BOSS_COMPONENT, self.cfgId )
	if tComponentData ~= nil then
		local allDestoryComps = tComponentData[ "allDestoryComps" ]
		local allDestoryGuns  = tComponentData[ "allDestoryGuns" ]
		if allDestoryComps == nil or allDestoryGuns == nil then
			return
		end
	    for i = 1, 8 do
	    	local compName = tComponentData[ "compName" .. i ]
	    	local compPos = tComponentData[ "compPos" .. i ]
	    	local compSize = tComponentData[ "compSize" .. i ]
	    	local compHpFactor = tComponentData[ "compHpFactor" .. i ]
	    	local compBloodbarOffset = tComponentData[ "compBloodbarOffset" .. i ]
	    	local compAtkFactor = tComponentData[ "compAtkFactor" ..i  ]
	    	local compGuns = tComponentData[ "compGuns" .. i ]
	    	if compName ~= nil and #compName > 0 and compPos ~= nil and compSize ~= nil and compHpFactor ~= nil and compBloodbarOffset ~= nil and compGuns ~= nil and compAtkFactor ~= nil then
				local tCompConfData = 
				{
					CompName = compName or "", 
					BloodBarOffset = compBloodbarOffset, 
					Guns = compGuns, 
					AllDestoryComps = allDestoryComps, 
					AllDestoryGuns = allDestoryGuns, 
					Rect = { compPos.x, compPos.y, compSize.x, compSize.y }, 
					HpFactor = compHpFactor, 
					AtkFactor = compAtkFactor
				}
				self.components[i] = cComponent.new( tCompConfData )
				self.components[i]:setMasterUnit( self )
			end
		end
		if self.lifeBar ~= nil then
			self.lifeBar:setVisible( false )
		end
	end
end

function cUnit:setComponentsVisible( visible )
	for i, v in ipairs( self.components ) do
		v:showLifeBar( visible )
	end
end

function cUnit:setLifeBarVisible( visible )
	if self.lifeBar ~= nil then
		self.lifeBar:setVisible( visible )
	end
end

function cUnit:isAllComponentDestoryed()
	for i, v in ipairs( self.components ) do
		if v:isDestoryed() == false then
			return false
		end
	end
	return true
end

function cUnit:setView(viewId, movementEventCallback )
	if not viewId then
		return false
	end
	local cfg = CfgData.getCfg(CFG_ANIMATION, viewId)
    if cfg and cfg.type == 3 
        and self.viewCfg 
        and cfg.skeleton == self.viewCfg.skeleton then

        local animation = self.view:getAnimation()
        animation:play(cfg.animationName[1], -1, -1, -1)
        if movementEventCallback ~= nil then
      		animation:setMovementEventCallFunc( movementEventCallback )
      	end
        return false
    else
	    local view, cfg = Factory.createAnim(viewId)
	    if not view then
		    return false
	    end

        view:retain()
        if self.view then
            self.view:removeFromParentAndCleanup(true)
            self.view:autorelease()
        end

	    self.viewCfg = cfg
	    self.view = view
	   	if movementEventCallback ~= nil and cfg.type == 3 then
      		local animation = self.view:getAnimation()
	        animation:play(cfg.animationName[1], -1, -1, -1)
	        if movementEventCallback ~= nil then
	      		animation:setMovementEventCallFunc( movementEventCallback )
	      	end
      	end
	    local contentSize = self.view:getContentSize()
	    local boundSize = cfg.boundSize
	    if boundSize.x > 0 and boundSize.y > 0 then
	        self.halfBoundWidth = boundSize.x * 0.5
	        self.halfBoundHeight = boundSize.y * 0.5
	    else
	        self.halfBoundWidth = contentSize.width * 0.5
	        self.halfBoundHeight = contentSize.height * 0.5
	    end
	    self.boundCircleRadius = _mathSqrt( self.halfBoundWidth * self.halfBoundWidth + self.halfBoundHeight * self.halfBoundHeight )
	    self.checkSectorRadius = math.ceil(self.boundCircleRadius / 40)
		local offset = cfg.boundOffset
	    if offset ~= nil then
		    self.boundOffsetX = offset.x or 0
	    	self.boundOffsetY = offset.y or 0
	    end	
    end

    return true

end

function cUnit:getType(  )
	return self._type
end

-- ¼ì²éµ¥Î»ÊÇ·ñ»¹ÓÐÐ§, Ê§Ð§µ¥Î»½«´ÓworldÖÐÇå³ý³öÈ¥
function cUnit:isValid(  )
	return ( not self.needDel )
end

-- ÊÇ·ñ¿ÉÒÔ½øÐÐ×÷ÓÃ( Åö×², ·¢Éä×Óµ¯µÈ )
function cUnit:canEffect(  )
	return self.hp > 0 and not self.needDel
end

-- Ã¿Ö¡update
function cUnit:update( dt )

	if not self:isValid() then
		return
	end

	-- ±³¾°Ê¹ÓÃÌØÊâÒÆ¶¯·½Ê½
	if self.isBg then
		self:updateBg( dt )
		return
	end
	if self.cantDmgTime > 0 then
		self.cantDmgTime = self.cantDmgTime - dt
	else
		self.cantDmgTime = 0
	end
	if self.fireDelayTime > 0 then
		local time = self.fireDelayTime - dt
		if time < 0 then
			time = 0
		end
		self.fireDelayTime = time
	end
    self:updateInvncible(dt)
    self:updateAnimates(dt)

    if self.group == UG_BULLET_ENEMY then
        self:updateBullet(dt)
    end
	if self.AI then
		-- ÓÐAIµÄ°´AIÖ´ÐÐ
		return self.AI:update( self, dt )
	end
	local selfExplosionTime = self.selfExplosionTime
	if selfExplosionTime ~= nil and selfExplosionTime > 0 then
		selfExplosionTime = selfExplosionTime - dt
		self.selfExplosionTime = selfExplosionTime
		if selfExplosionTime <= 0 then
			self:doExplosion( true )
			self.needDel = true
			return
		end
	end
	local lifeTime = self.lifeTime
	if lifeTime and lifeTime > 0 then
		lifeTime = lifeTime - dt
		self.lifeTime = lifeTime

		if lifeTime <= 0 then
			self.needDel = true
			return 
		end
	end

	self:move( dt )

	if self:checkOutOfRange() then

		if self.group ~= UG_PLANE then
			self:remove()
			return
		else
			if stopFire == false then
			self:remove()
			return
			end
		end
	end

	if self.fireDelayTime == 0 and not self.stopFire then
		self:updateGuns( dt )
	end

end

function cUnit:updateBg(dt)
	self:move( dt )
	local x, y = self.x, self.y
	if self.speed > 0 then
		if y >= CONFIG_WORLD_CY + 2 * CONFIG_WORLD_HEIGHT then
			y = y - 3 * CONFIG_WORLD_HEIGHT
			self:pos(x, y)
		end		
	else
		if y <= -display.height then
			y = y + 3 * CONFIG_WORLD_HEIGHT
			self:pos(x, y)
		end
	end
end

function cUnit:updateBullet(dt)

    local unit = self.masterUnit
    if unit then
        --TODO("self:updateBullet(dt)")
        if unit.delBulletOnDead and not unit:canEffect() then
            self.needDel = true
        end
    end
end

function cUnit:pos( x, y )
	self.x = x
	self.y = y
	self.sectorXIdx = _mathfloor( x * 0.025 )
	self.sectorYIdx = _mathfloor( y * 0.025 )
	local world = self.world
	if world and self.view then
		x, y = world:convertToScreen(x, y, self.zvalue)
	    self.view:pos(x, y)
        if self.specialType > 1000 then
        	for i, v in ipairs( self.components ) do
        		if v.lifeBar ~= nil then
        			v.lifeBar:pos( x + v.bloodBarOffset.x + v.boundOffsetX, y + v.bloodBarOffset.y + v.boundOffsetY )
        		end
        	end
        	local lifeBar = self.lifeBar
	        if lifeBar then
	        	if self.specialType == ENUM_UNIT_SPECIAL_TYPE_COMP_BOSS then
	        		x, y = world:convertToScreen( 0, y, self.zvalue )
	            	lifeBar:pos( x, 1130 )
	            else
	            	lifeBar:pos(x + self.lifePosition.x, y + self.lifePosition.y)
	            end
	        end
        end
	else
		self.view:pos(x, y)
	end
	self.rect = nil
end

function cUnit:refreshRect( )
    if self.rect ~= nil then
    	return self.rect
    end
	local w = self.halfBoundWidth 
	local h = self.halfBoundHeight
    local x = self.x + self.boundOffsetX
    local y = self.y - self.boundOffsetY
	self.rect = {x - w, y - h, x + w, y + h, w, h }
	return rect
end

function cUnit:setModifier( hpModifier, hurtModifier, gunHurtModifier )
	self.hp = self.maxHP * hpModifier
	self.maxHP = self.maxHP * hpModifier
	self.hurt = self.hurt * hurtModifier
	self.gunHurtModifier = gunHurtModifier
	if self.lifeBar ~= nil then
		local progress_ui = ccuiloader_seekNodeEx(self.lifeBar, "progress")
		if progress_ui ~= nil then
        	progress_ui:setPercent( 100 )
        end
	end
	if self.specialType == ENUM_UNIT_SPECIAL_TYPE_COMP_BOSS then
		--boss削弱造成影响
		local weekFactor = 0
		local techMgr = app.techMgr
		if techMgr ~= nil then
			local level, factor = techMgr:getTechInfo( ENUM_TECH_TYPE_BOSS_WEEK )
            if factor ~= nil and factor ~= 0 then
            	weekFactor = factor
                self.hp = self.maxHP * ( 1 + weekFactor )
                local lifeBar = self.lifeBar
		        if lifeBar then
		            local progress_ui = ccuiloader_seekNodeEx(lifeBar, "progress")
		            progress_ui:setPercent( self.hp * 100 / self.maxHP)
		        end
            end
		end
		self:changeGuns( 1 )
		for i, v in ipairs( self.components ) do
			v:resetData()
			self:addGuns( v:getGunsId() )
			v.hp = v.maxHP * ( 1 + weekFactor )
			v:updateLifeBar()
		end
	end
end

function cUnit:getRect( )
	return self.rect
end

function cUnit:getPosition()
	return self.x, self.y
	-- if not self.view then
	-- 	return 0, 0
	-- end
	-- return self.view:getPosition()
end

function cUnit:getPositionOnScreen()
    if not self.view then return 0, 0 end

	return self.view:getPosition()
end

function cUnit:playView()
    self:changeGuns(1)
    if self.view ~= nil then
    	self.view:setRotation( 0 )
    end
	--local cfg = self.viewCfg
	--if cfg and cfg.type == 1 then
    --	local animationName = cfg.animationName[1]
	--end
end

--Éý¼¶
function cUnit:updateAndLvlupView()
	local viewIds = self.viewIds
	local maxLv = #viewIds

	if maxLv == 1 then
		return
	end

    local gunLevel = 1
	if self.unitLevel >= maxLv then
		self.unitLevel = 1
        gunLevel = 1
	else
		self.unitLevel = self.unitLevel + 1
        gunLevel = 5
	end
	self.currentViewId = viewIds[self.unitLevel]
	if self:setView(self.currentViewId) then
	    self.scene:addChild(self.view, self.zvalue)
    end

    self:changeGuns(gunLevel + self.enhanceGunLevel)
end

function cUnit:updateLevelView(level, callback )

    local id = self.viewIds[level]
    if not id then
        id = self.viewIds[1]
    end

    if self.currentViewId == id then
        return 
    end

    local animates = self.animates
	if animates then
        for _, animate in pairs(animates) do
            animate.target:removeFromParentAndCleanup(false)
        end
	end

	self.currentViewId = id
	if self:setView(id, callback) then
	    self.scene:addChild(self.view, self.zvalue)
    end

	if animates then
        for _, animate in pairs(animates) do
            self.view:addChild(animate.target, UZ_EFFECT_ANIM + 999)
        end
	end

end

-- »ù´¡ÒÆ¶¯º¯Êý
function cUnit:move( dt )
	if not self.view then
		return
	end
	if self.rotSpeed ~= 0 then
		self.rotation = self.rotation + self.rotSpeed * dt
		self:setSAR( nil, nil, self.rotation )
	end
	-- ¸ù¾Ý¼ÓËÙ¶ÈÖØËãËÙ¶È(×¢Òâ! ÕâÀïÖ»ÊÇÒ»¸ö½üËÆËã·¨)
	local spAcc = self.acceleration
	if spAcc ~= 0 then
		local speedNew = self.speed + spAcc * dt

		if spAcc > 0 then
			-- ¼ÓËÙ¶ÈÎªÕý, ÐèÒª¼ì²éunitÊÇ·ñ´ïµ½ÁËËÙ¶ÈÉÏÏÞ
			if self.speedMax ~= 0 and speedNew > self.speedMax then
				speedNew = self.speedMax
			end
		else
			-- ¼ÓËÙ¶ÈÎª¸º, ÐèÒª¼ì²éunitÊÇ·ñ´ïµ½ÁËËÙ¶ÈÏÂÏÞ
			if self.speedMin ~= 0 and speedNew < self.speedMin then
				speedNew = self.speedMin
			end
		end

		if self.speed ~= speedNew then
			-- ËÙ¶È·¢ÉúÁË±ä»¯,ÐèÒªÖØËã
			self.speed = speedNew
			self:refreshSpeedXY()
		end
	end
	self:pos( self.x + self.speedX * dt, self.y + self.speedY * dt )
end

function cUnit:updateGuns( dt )
	if self.guns then
		for i,gun in ipairs(self.guns) do
			gun:update( dt )
		end
	end
end

function cUnit:deleteGuns()
	if self.guns then
		for i,gun in ipairs(self.guns) do
			gun:onDelete()
		end
        self.guns = nil
	end
end

function cUnit:changeGuns( level )
    -- É¾³ýÏÖÓÐµÄÇ¹
    -- self:deleteGuns()

    local gunIds = self.guns__
    if not gunIds then
        return
    end

    -- ÓÅÏÈÈ¡Éý»úµÄÇ¹
    local gunLevels = self.gunLevels__
	if gunLevels then
    	gunIds = gunLevels[level]
        if not gunIds then
            gunIds = gunLevels[#gunLevels]
        end

        --print("cUnit:initGuns gunIds, gunLevels", #gunIds, #gunLevels)
    end

    --if #gunIds > 0 then Logger.printTable(gunIds) end

    -- É¾³ýÐÂÇ¹×éÀïÃ»ÓÐµÄÇ¹
	local guns = {}
	if self.guns then
		for i,gun in ipairs(self.guns) do

            -- ¼ì²éÐÂÌí¼ÓµÄÇ¹×éÀïÊÇ·ñÓÐ,Ã»ÓÐÔòÉ¾³ý
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
    -- Ìí¼ÓÐÂÇ¹
	for i, gunId in ipairs(gunIds) do
        local finded = false
        for _, gun in ipairs(guns) do
            finded = finded or (gunId == gun.id)
        end

        -- ÏÖÓÐµÄÇ¹×éÀïÃ»ÓÐµÄ,Ìí¼ÓÖ®
        if not finded then
		    local gun = Factory.createGunById(gunId) 
		    if gun then
			    gun.masterUnit = self
			    tinsert(guns, gun)
		    end
        end
	end

    self.guns = guns
end

function cUnit:addGunById( gunId )
	local gun = Factory.createGunById( gunId )
	if gun ~= nil then
		gun.masterUnit = self
		tinsert( self.guns, gun )
	end
end

function cUnit:addGuns( gunsId )
	if gunsId == nil then
		return
	end
	for i, v in ipairs( gunsId ) do
		if self:haveGun( v ) ~= true then
			self:addGunById( v )
		end
	end
end

function cUnit:haveGun( gunId )
	for i, gun in ipairs( self.guns ) do
		if gun.id == gunId then
			return true
		end
	end
	return false
end

function cUnit:getGunById( gunId )
	for i, gun in ipairs( self.guns ) do
		if gun.id == gunId then
			return gun
		end
	end
end

function cUnit:removeGuns( gunsId )
	if gunsId == nil then
		return
	end
	for i, v in ipairs( gunsId ) do
		self:removeGunById( v )
	end
end

function cUnit:resetGuns()
	for i, gun in ipairs( self.guns ) do
		gun:onDelete()
	end
	self.guns = {}
end

function cUnit:removeGunById( gunId )
	for i, gun in ipairs( self.guns ) do
		if gun.id == gunId then
			gun:onDelete()
			table.remove( self.guns, i )
			return
		end
	end
end

function cUnit:setColor( r, g, b )
	if self.view ~= nil then
		self.view:setColor( cc.c3(r, g, b) )
	end
end

-- ¸ù¾Ýµ±Ç°µÄÏßËÙ¶ÈºÍ½Ç¶È,ÖØËãXY×ø±ê
local _angle_radian = (math.pi / 180)
local _angle = 0
function cUnit:refreshSpeedXY()
	_angle = (self.angle + 90) * _angle_radian
	self.speedX = _math_cos( _angle ) * self.speed
	self.speedY = _math_sin(_angle ) * self.speed
end


-- »ñÈ¡µ¥ÔªµÄ½Ç¶ÈºÍËÙ¶È
function cUnit:getSpeedAndAngle( )
	return self.speed, self.angle
end

-- ÉèÖÃµ¥ÔªµÄ¼ÓËÙ¶ÈºÍËÙ¶ÈÏÞÖÆ
function cUnit:setAcceleration( acceleration , speedMin, speedMax)
	self.acceleration = acceleration or 0
	self.speedMin = speedMin or 0
	self.speedMax = speedMax or 0
end

-- ÉèÖÃµ¥ÔªµÄÏßËÙ¶È, ÒÆ¶¯½Ç¶ÈºÍÏÔÊ¾½Ç¶È
-- Èç¹û´«ÈënilÔò±íÊ¾²»ÐÞ¸Ä¶ÔÓ¦µÄÖµ
function cUnit:setSAR( speed, angle, rotation )

	if speed then
		self.speed = speed
	end

	if angle then
		self.angle = angle
	end

	if rotation and self.view then
		-- self:setRotation( rotation )	
		self.rotation = rotation
		self.view:setRotation( 180 - rotation )	
	end

	self:refreshSpeedXY()
end



-- ÉèÖÃµ¥Î»µÄ´æ»îÊ±¼ä
function cUnit:setLifeTime( lifeTime )
	self.lifeTime = lifeTime
end

function cUnit:setDelayTime( delayTime )
	self.delayTime = delayTime
end

function cUnit:setAI( aiId, xMirror, yMirror )
    local ai = Factory.createAI( aiId, xMirror, yMirror )
    if not ai then
    	return
    end
    self.AI = ai
    ai:nextCmd( self, 0 )
end

function cUnit:clearAI()
	self.AI = nil
end

function cUnit:openGuns()
	self.stopFire = false
end

function cUnit:openGunsEx()
	self.stopFire = true
	for i, v in ipairs( self.guns ) do
		v.stopFire = false
	end
end

function cUnit:fireGunsNow( guns )
	if guns == nil then
		return
	end
	for i, v in ipairs( guns ) do
		if v ~= nil then
			local gun = self:getGunById( v )
			if gun ~= nil then
				gun:fire()
			end
		end
	end
end

function cUnit:changeAnimView( animViewId, timeScale )
	timeScale = timeScale or 1
	if animViewId == nil or self.currentViewId == nil then
		return
	end
	local viewId = self.currentViewId
	if animViewId ~= 0 and animViewId ~= viewId then
		local function movementEventCallback( armature, movementEvetType, movementId )
	        if movementEvetType == 1 then
	            if self:setView( viewId ) then
				    self.scene:addChild(self.view, self.zvalue)
			    end
	        end
	    end
		if self:setView( animViewId, movementEventCallback ) then
		    self.scene:addChild(self.view, self.zvalue)
	    end
	end
	if self.view ~= nil and self.viewCfg ~= nil and self.viewCfg.type == 3 then
		local animation = self.view:getAnimation()
		if animation ~= nil then
			local originTime = 1
			if self.viewCfg.fps ~= nil and self.viewCfg.fps > 0 then
				originTime = self.viewCfg.fps / 60
			end
			animation:setSpeedScale( timeScale * originTime )
		end
	end
end

function cUnit:stopGuns()
	self.stopFire = true
end

function cUnit:stopGunsEx()
	self.stopFire = true
	for i, v in ipairs( self.guns ) do
		v.stopFire = true
	end
end

function cUnit:run(action)
    if self.view then
	    self.view:runAction(action)
    end
end

-- ¼ì²éµ¥Î»ÊÇ·ñ³¬³öÆÁÄ»ÍâÃæ, ³¬³öÔòÉ¾³ý×Ô¼º
function cUnit:checkOutOfRange( )
	if self.stateType == ENUM_UNIT_TYPE_ENTRANCE then
		return false
	end
	return ( self.x < -CONFIG_WORLD_WIDTH_HALF or self.x > CONFIG_WORLD_WIDTH_HALF or 
			 self.y < 0 or self.y > CONFIG_WORLD_HEIGHT )
end

-- »ñÈ¡µ½ÉËº¦Ê±µÄ´¦Àí
function cUnit:getDamage( dmg )
	if self.hp <= 0 then
		return
	end

    if self.invncibleTime <= 0 then
	    local hp = self.hp - dmg

        local lifeBar = self.lifeBar
        if lifeBar then
            local progress_ui = ccuiloader_seekNodeEx(lifeBar, "progress")
            progress_ui:setPercent(hp * 100 / self.maxHP)
        end
        if self.specialType == ENUM_UNIT_SPECIAL_TYPE_PENETRATE_BULLET then
        	self.cantDmgTime = tonumber(self.params1[1]) or 0.1
        	return
        elseif self.specialType == ENUM_UNIT_SPECIAL_TYPE_COMP_BOSS then
        	if self:isAllComponentDestoryed() == false and self.state ~= ENUM_UNIT_TYPE_CRAZY then
        		return
        	end
        end
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
    else
        --self:showInvncibleView()
    end
end

--对部件造成伤害
function cUnit:causeDamage( dmg, componentIdx )
end

-- ×Óµ¯³õÊ¼»¯Ê±µÄÉËº¦¼Ó³É
function cUnit:getHurt(isWingman)
    return self.gunHurtModifier, 1
end

-- Îü¸½µÀ¾ßµÄ¾àÀë
function cUnit:adsorptionDistance()
    return 0
end

-- ËÀÍöÐ§¹û
function cUnit:showDeadView( )
	if self.deadViewId > 0 then
		self:showEffectAnim( self.deadViewId )
	end
end

function cUnit:showEffectAnim( effectId )
	local x,y = self:getPositionOnScreen()
	local specialView = CfgData.getCfg(CFG_SPECIAL_VIEW, effectId )
	if specialView ~= nil then
		for i, v in ipairs( specialView ) do
			local callFunc = CCCallFunc:create(
					function() 
						if self.world ~= nil then
							self.world:addEffectAnim(v.viewId, true, x + (v.offset.x or 0), y + (v.offset.y or 0), UZ_EFFECT_ANIM, v.scale or 1)
						end
					end)
			local delayTime = CCDelayTime:create( v.delayTime or 0)
			local sequence = CCSequence:createWithTwoActions( delayTime, callFunc )
			if self.world ~= nil then
				self.world.scene:runAction( sequence )
			end
		end
		return
	end
	self.world:addEffectAnim( effectId, true, x, y, UZ_EFFECT_ANIM)
end

-- Í¨¹ýµôÂäÁÐ±í²úÉú¶à¸öµÀ¾ß
function cUnit:dropItemes(dropIds, ownerDrops)
    
    if dropIds or ownerDrops then
        local itemIds = {}
        -- ±éÀúµôÂäÁÐ±í, Ã¿¸öµôÂäÁÐ±í¿ÉµôÂä¶à¸öÍ¬Ò»ÀàÐÍµÄµÀ¾ß
        if dropIds then
            for _, dropId in ipairs(dropIds) do

                local itemId, count = Factory.dropItemById(dropId)
                if itemId and count > 0 then
                    for _ = 1, count do
                        -- ½«µÀ¾ß´æÈëµ½Ò»¸öÊý×é
                        -- µÀ¾ßÊý¾ÝÃ¿Ïî´æÒ»¸öµÀ¾ß
                        table.insert(itemIds, itemId)
                    end --for _ = 1, count do
                end --if itemId and count > 0 then
            end --for _, dropId in ipairs(dropIds) do
        end --if dropIds then

        if ownerDrops then
            for _, dropId in ipairs(ownerDrops) do

                local itemId, count = Factory.dropItemById(dropId)
                if itemId and count > 0 then
                    for _ = 1, count do
                        -- ½«µÀ¾ß´æÈëµ½Ò»¸öÊý×é
                        -- µÀ¾ßÊý¾ÝÃ¿Ïî´æÒ»¸öµÀ¾ß
                        table.insert(itemIds, itemId)
                    end --for _ = 1, count do
                end --if itemId and count > 0 then
            end --for _, dropId in ipairs(ownerDrops) do
        end --if ownerDrops then

        -- Í¨¹ýµÀ¾ßÊý×é²úÉúµÀ¾ßUnitÏÔÊ¾ÔÚÊÀ½çÖÐ
        -- Í¨¹ýµÀ¾ßÊý×é¿ÉÒÔ¿ØÖÆµÀ¾ßµÄÎ»ÖÃ/½Ç¶È¼ä¸ô
        if #itemIds > 0 then
            local x,y = self:getPosition()
            self.world:addItemes(itemIds, x, y)
        end --if #itemIds > 0 then

    end --if dropIds or ownerDrops then
end

function cUnit:setSelfExplosionData( nTime, radius, dmg )
	self.selfExplosionTime = nTime
	self.explosionRadius = radius
	self.explosionDmg = dmg
end

--爆炸处理
function cUnit:doExplosion( bSelfExplosion )
	if self.world == nil then
		return
	end
	if (self.specialType ~= ENUM_UNIT_SPECIAL_TYPE_BOMB) and (self.specialType ~= ENUM_UNIT_SPECIAL_TYPE_BOMB_BULLET) then
		return
	end
	self:showDeadView()
	local x = self.x
	local y = self.y
	local explosionRadius = self.explosionRadius
	local distance = 0
	if bSelfExplosion ~= true then --如果是被玩家打爆炸的,则范围伤害
		local units = self.world.units
		local damageUnits = {}
		if units ~= nil then
			local enemyUnits = units[UG_ENEMY]
			if enemyUnits ~= nil then
				for i, v in ipairs( enemyUnits ) do
					if v.specialType ~= self.specialType then
						distance = MathAngle_distance( x, y, v.x, v.y )
						if distance <= (explosionRadius + v.boundCircleRadius) then
							tinsert( damageUnits, v )
						end
					end
				end
				for i, v in ipairs( damageUnits ) do
					v:getDamage( self.explosionDmg )
				end
			end
		end
	elseif self.world.plane ~= nil then	--如果是自爆的，则对玩家飞机造成伤害
		local plane = self.world.plane
		distance = MathAngle_distance( x,y, plane.x, plane.y ) --中心点
		if distance <= (self.explosionRadius + plane.boundCircleRadius) then
			plane:getDamage( self.explosionDmg )
		end
	end
end

-- »÷ÖÐÄ¿±êÊ±µÄÐ§¹û
function cUnit:showHitView( defUnit )
	if self.hitViewId > 0 then
		local x,y = self:getPositionOnScreen()
		if defUnit then
			local x1,y1 = defUnit:getPositionOnScreen()
            x = x + ( x1 - x ) * math.random(0, 0.5)
            y = y + ( y1 - y ) * math.random(0, 0.5)
        end
		self.world:addEffectAnim(self.hitViewId, true, x, y, UZ_EFFECT_ANIM)
	end
end

-- ½øÈëÎÞµÐÄ£Ê½
function cUnit:enterInvncible(duration, force, props)
    self.invncibleTime = duration
    return true
end

-- ÎÞµÐÄ£Ê½µÄÏû¼õÂß¼­
function cUnit:updateInvncible(dt)
    local invncibleTime = self.invncibleTime
    if invncibleTime > 0 then
        invncibleTime = invncibleTime - dt
        self.invncibleTime = invncibleTime
    end
end

-- ¸½¼ÓÒ»¸ö¶¯»­
function cUnit:attachAnimate(animateId, duration, x, y)
	if animateId > 0 and self.view then
        if not self.animates then
            self.animates = {}
        end

        local animate = self.animates[animateId]
        if animate then
            if animate.life < duration then
                animate.life = duration
            end
        else
            local sp, cfg = Factory.createAnim(animateId, false, false, nil, 0)
            if not cfg or not sp then
                return
            end
            local scale = 1
            if cfg.scale > 0 then scale = cfg.scale end
            local my_scale = self.viewCfg.scale
            if my_scale > 0 then scale = scale / my_scale end

            sp:setScale(scale)
            sp:pos(x,y)
            self.view:addChild(sp, UZ_EFFECT_ANIM + 999)

            self.animates[animateId] = {target=sp, life=duration}
        end
	end
end

-- ¸½¼ÓÒ»¸ö¶¯»­
function cUnit:updateAnimates(dt)

    local animates = self.animates
	if animates then
        local dellist = {}

        for id, animate in pairs(animates) do
            local life = animate.life - dt
            if life < 0 then
                animate.target:removeFromParentAndCleanup(true)
                table.insert(dellist, id)
            else
                animate.life = life
            end
        end

        for _, id in ipairs(dellist) do
            animates[id] = nil
        end
	end

end


-- É¾³ýÖ¸¶¨¶¯»­
function cUnit:removeAnimate(id)

    local animates = self.animates
	if animates then

        local animate = animates[id]
        if animate then
            animate.target:removeFromParentAndCleanup(true)
            animates[id] = nil
        end

	end

end

function cUnit:onEntrance()
end

-------------------------------------------------------------------------------------------------
if DEBUG_BOUND_BOX == true or DEBUG_UNIT_INFO_LABEL == true then
	require("app.model.cDebugUnit")
end
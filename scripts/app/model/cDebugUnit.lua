if DEBUG_BOUND_BOX ~= true and DEBUG_UNIT_INFO_LABEL ~= true then
	return
end
local tinsert = table.insert
local _mathfloor = math.floor
local _mathPow = math.pow
local _mathSqrt = math.sqrt


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

    if self.lifeBar then
        self.lifeBar:removeFromParentAndCleanup(true)
        self.lifeBar:release()
        self.lifeBar = nil
    end
    if self.view then
        self.view:removeFromParentAndCleanup(true)
        self.view:release()
        self.view = nil
    end
    if self.debug_box then
        self.debug_box:removeFromParentAndCleanup(true)
        self.debug_box = nil
    end
    if self.specialType > 1000 then
    	for i, v in ipairs( self.components ) do
    		if v.lifeBar ~= nil then
    			v.lifeBar:removeFromParentAndCleanup(true)
    		end
    	end
    	if self.debugInfoLabel then
	    	self.debugInfoLabel:removeFromParentAndCleanup(true)
	    	self.debugInfoLabel:release()
	    	self.debugInfoLabel = nil
	    end
    end
end

function cUnit:remove( )
	self.needDel = true
	self:clearAI()
    local animates = self.animates
	if animates then
        for _, animate in pairs(animates) do
            animate.target:removeFromParentAndCleanup(true)
        end
        self.animates = nil
	end
    if self.debug_box then
        self.debug_box:removeFromParentAndCleanup(true)
        self.debug_box = nil
    end
    if self.specialType > 1000 then
    	for i, v in ipairs( self.components ) do
    		if v.lifeBar ~= nil then
    			v.lifeBar:removeFromParentAndCleanup(false)
    		end
    	end
    end
    if self.debugInfoLabel then
    	self.debugInfoLabel:removeFromParentAndCleanup(false)
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
    self.specialType 	= cfg.specialType

    if self.specialType ~= 0 then
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
    	self:initComponents()
    	if DEBUG_UNIT_INFO_LABEL == true then
			self.debugInfoLabel = CCLabelTTF:create( "", "", 26 )
			self.debugInfoLabel:setColor( cc.c3b(255, 0, 0) )
			self.debugInfoLabel:retain()
		end
		self.params1 = cfg.params1
		self.params2 = cfg.params2
		if self.specialType == ENUM_UNIT_SPECIAL_TYPE_BOMB_BULLET then
			self:setSelfExplosionData( nil, tonumber(self.params1[1]), tonumber(self.params1[2]) )
		end
	end
	return true
end

function cUnit:onExit()
    self.scene = nil
    self.world = nil
	self.AI = nil
    self.team = nil
	self.guns = nil
    self.animates = nil

    if self.view then
        self.view:removeFromParentAndCleanup(false)
    end
    if self.debug_box then
        self.debug_box:removeFromParentAndCleanup(true)
        self.debug_box = nil
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
    if self.debugInfoLabel then
    	self.debugInfoLabel:removeFromParentAndCleanup(false)
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
        local lifeBar = self.lifeBar
        if lifeBar then
            lifeBar:pos(x + self.lifePosition.x, y + self.lifePosition.y)
        end
        if DEBUG_UNIT_INFO_LABEL == true and self.specialType ~= 0 then
        	local debugInfoLabel = self.debugInfoLabel
	       	if debugInfoLabel ~= nil then
	       		debugInfoLabel:pos( x + 50, y + 50 )
	       		if self.specialType ~= 1 then
	       			debugInfoLabel:setString( string.format( "%.1f/%.1f", self.hp, self.maxHP ) )
	       		else
	       			debugInfoLabel:setString( string.format( "%.1f/%.1f(%.1f)", self.hp, self.maxHP, self.selfExplosionTime or 0 ) )
	       		end
	       	end
	    end
        if self.specialType > 1000 then
        	for i, v in ipairs( self.components ) do
        		if v.lifeBar ~= nil then
        			v.lifeBar:pos( x + v.bloodBarOffset.x + v.boundOffsetX, y + v.bloodBarOffset.y + v.boundOffsetY )
        		end
        	end
        end
	else
		self.view:pos(x, y)
	end
	self.rect = nil
	if DEBUG_BOUND_BOX == true then
		self:refreshRect()
	end
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
    -- ÏÔÊ¾µ÷ÊÔÓÃµÄ°üÎ§ºÐ
    if DEBUG_BOUND_BOX == true then
    	self:showDebugBox( w, h )
    end
	return rect
end

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
	local fillColor = cc.c4f(1,0,1,0.09)
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
		fillColor = cc.c4f(0,1,0,0.09) --对敌方，爆炸的显示不一样
	elseif self.world.plane ~= nil then	--如果是自爆的，则对玩家飞机造成伤害
		local plane = self.world.plane
		distance = MathAngle_distance( x,y, plane.x, plane.y ) --中心点
		if distance <= (self.explosionRadius + plane.boundCircleRadius) then
			plane:getDamage( self.explosionDmg )
		end
	end
	if DEBUG_BOUND_BOX == true then
		local scene = self.world.scene
		local world = self.world
		if scene ~= nil and world ~= nil then
			local drawNode = cc.DrawNode:create()
	        if drawNode ~= nil then
	        	local fadeOut = CCFadeOut:create(1.5)
	        	local removeSelf = CCRemoveSelf:create()
	            local sequence = CCSequence:createWithTwoActions( fadeOut, removeSelf )
	            local segments = 32
				local startRadian = 0
				local endRadian = math.pi*2
				local borderWidth = 0
				local radius = self.explosionRadius
	        	local radianPerSegm = 2 * math.pi/segments
	            local points = {}
				for i=1, segments do
					local radii = startRadian+i*radianPerSegm
					if radii > endRadian then break end
					table.insert( points,{radius * math.cos(radii),radius * math.sin(radii)} )
				end
				drawNode:drawPolygon( points, {fillColor =fillColor, borderColor = cc.c4f(1,0,0,0.3), borderWidth = 2 } )
	            self.scene:addChild( drawNode, 999 )
	            local x, y = world:convertToScreen(self.x, self.y, self.zvalue)
	            drawNode:pos( x, y )
	            drawNode:runAction( sequence )
	        end
	    end
	end
end

function cUnit:showDebugBox( w, h )
	if self.scene ~= nil and self.view ~= nil then
        if not self.debug_box and self.group ~= UG_BG then
        	if self.collisionType ~= 0 then
        		local offsetX = self.boundOffsetX
        		local offsetY = self.boundOffsetY
	            self.debug_box = cc.DrawNode:create()
	            self.debug_box:drawRect( { -1, -1, 3, 3 }, {fillColor =cc.c4f(1,0,0,0.3), borderColor = cc.c4f(1,0,0,1), borderWidth = 1 } );
	            self.debug_box:drawRect( { offsetX-1, -offsetY-1, 3, 3 }, {fillColor =cc.c4f(0,1,0,0.3), borderColor = cc.c4f(0,1,0,1), borderWidth = 1 } );
	            if self.collisionType == 1 then		--Åö×²ÀàÐÍÎª²»Ðý×ª¾ØÐÎ
	            	self.debug_box:drawRect( {offsetX-w, -offsetY-h, w * 2, h * 2 }, {fillColor =cc.c4f(0,1,0,0.3), borderColor = cc.c4f(0,1,0,1), borderWidth = 1 } )
	            elseif self.collisionType == 2 then	--Åö×²ÀàÐÍÎªÔ²ÐÎ
	            	local segments = 32
					local startRadian = 0
					local endRadian = math.pi*2
					local borderWidth = 0
					local radius = self.boundCircleRadius
	            	local radianPerSegm = 2 * math.pi/segments
	            	self.debug_box:drawRect( {offsetX-w, -offsetY-h, w * 2, h * 2 }, {fillColor =cc.c4f(1,1,0,0.13), borderColor = cc.c4f(1,1,0,0.3), borderWidth = 1} )
					local points = {}
					for i=1,segments do
						local radii = startRadian+i*radianPerSegm
						if radii > endRadian then break end
						table.insert( points,{offsetX + radius * math.cos(radii), -offsetY + radius * math.sin(radii)} )
					end
					self.debug_box:drawPolygon( points, {fillColor =cc.c4f(0,1,1,0.18), borderColor = cc.c4f(0,1,1,0.7), borderWidth = 1 } )
	            elseif self.collisionType == 3 then	  --Åö×²ÀàÐÍÎªÐý×ª¾ØÐÎ
	            	local segments = 32
					local startRadian = 0
					local endRadian = math.pi*2
					local radius = self.boundCircleRadius
	            	local radianPerSegm = 2 * math.pi/segments
	            	self.debug_box:drawRect( {offsetX-w, -offsetY-h, w * 2, h * 2 }, {fillColor =cc.c4f(0,1,1,0.18), borderColor = cc.c4f(0,1,1,0.7), borderWidth = 1 } )
					local points = {}
					for i=1,segments do
						local radii = startRadian+i*radianPerSegm
						if radii > endRadian then break end
						table.insert( points,{offsetX + radius * math.cos(radii), -offsetY + radius * math.sin(radii)} )
					end
					self.debug_box:drawPolygon( points, {fillColor =cc.c4f(1,1,0,0.13), borderColor = cc.c4f(1,1,0,0.3), borderWidth = 1} )
	            end
	            self.scene:addChild(self.debug_box, UZ_PLANE + 2000 )
	        end
        end
        local debug_box = self.debug_box
        if debug_box ~= nil then
        	if self.specialType == ENUM_UNIT_SPECIAL_TYPE_COMP_BOSS then
            	self:showComponentDebugBox( debug_box )
            end
            local world = self.world
            local x, y = world:convertToScreen(self.x, self.y, self.zvalue)
            debug_box:pos( x, y )
            if self.collisionType == 3 then
            	debug_box:setRotation( 180 - self.rotation )
            end
        end
    end
end

function cUnit:showComponentDebugBox( debug_box )
	if self.scene ~= nil and self.view ~= nil then
        if self.group ~= UG_BG then
        	for i, v in ipairs( self.components ) do
        		local x, y, w, h = unpack(v:getRectCfg())
        		debug_box:drawRect( { x, y, w, h }, {fillColor =cc.c4f(0,0,0,0.0), borderColor = cc.c4f(1,0,0,0.7), borderWidth = 1 } )
        	end
        end
    end
end

function cUnit:getDamage( dmg )
	if self.hp <= 0 then
		return
	end

    if self.invncibleTime <= 0 then
    	if self.specialType == ENUM_UNIT_SPECIAL_TYPE_PENETRATE_BULLET then
        	self.cantDmgTime = tonumber(self.params1[1])
        	return
        end
	    local hp = self.hp - dmg
	    if self.specialType == ENUM_UNIT_SPECIAL_TYPE_PENETRATE_BULLET then
        	self.cantDmgTime = tonumber(self.params1[1]) or 0.1
        	return
        elseif self.specialType == ENUM_UNIT_SPECIAL_TYPE_COMP_BOSS then
        	if self:isAllComponentDestoryed() == false and self.state ~= ENUM_UNIT_TYPE_CRAZY then
        		return
        	end
        end
	    if self.specialType > 1000 then
	        local lifeBar = self.lifeBar
	        if lifeBar then
	            local progress_ui = ccuiloader_seekNodeEx(lifeBar, "progress")
	            progress_ui:setPercent(hp * 100 / self.maxHP)
	        end
	    end
       	if DEBUG_UNIT_INFO_LABEL == true and self.specialType ~= 0 then
        	local debugInfoLabel = self.debugInfoLabel
	       	if debugInfoLabel ~= nil then
	       		if self.specialType ~= 1 then
	       			debugInfoLabel:setString( string.format( "%.1f/%.1f", self.hp, self.maxHP ) )
	       		else
	       			debugInfoLabel:setString( string.format( "%.1f/%.1f(%.1f)", self.hp, self.maxHP, self.selfExplosionTime or 0 ) )
	       		end
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
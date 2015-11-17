cComponent = class("cComponent")

function cComponent:ctor( tConfig )
	self.masterUnit = nil
	local x, y, w, h = unpack( tConfig.Rect )
    self.halfBoundWidth = w * 0.5
    self.halfBoundHeight = h * 0.5
    self.boundCircleRadius = math.sqrt( self.halfBoundWidth * self.halfBoundWidth + self.halfBoundHeight * self.halfBoundHeight )
    self.checkSectorRadius = math.ceil(self.boundCircleRadius / 80)
	self.boundOffsetX = x
    self.boundOffsetY = y
    self.sectorXIdx		= -99
    self.sectorYIdx		= -99
    self.Config			= tConfig
    self.bloodBarOffset = tConfig.BloodBarOffset
    self.compName		= tConfig.CompName
    self.HpFactor 		= tConfig.HpFactor
    self.guns 			= tConfig.Guns
    self.atkFactor 		= tConfig.AtkFactor
    self.allDestoryComps= tConfig.AllDestoryComps
    self.allDestoryGuns = tConfig.AllDestoryGuns
    self.rect 			= { -999, -999, 0, 0, 0, 0 }
    self.rectCfg 		= { x - w/2, y - h/2, w, h }
    self.cfgData 		= tConfig
    self.destoryed		= false
	local lifeBar, width, height = cc.uiloader:load("res/ui/bloodBar.json")
    lifeBar = ccuiloader_seekNodeEx(lifeBar, "component" )
    if lifeBar then
        lifeBar:retain()
        lifeBar:setVisible(true)
        lifeBar:removeFromParentAndCleanup(false)
        self.lifeBar = lifeBar
    end
end

function cComponent:getRect()
	if self.masterUnit ~= nil then
		local posX, posY = self.masterUnit.x, self.masterUnit.y
		local x = posX + self.boundOffsetX
		local y = posY + self.boundOffsetY
		local w = self.halfBoundWidth
		local h = self.halfBoundHeight
		self.rect = { x - w, y - h, x + w, y + h, w, h  }
	end
	return self.rect
end

function cComponent:getRectCfg()
	return self.rectCfg
end

function cComponent:setMasterUnit( masterUnit )
	self.masterUnit = masterUnit
end

function cComponent:resetData()
	self.destoryed = false
	if self.masterUnit ~= nil then
		self.maxHP = self.masterUnit.maxHP * self.HpFactor
		self.hp = self.masterUnit.maxHP * self.HpFactor
		if self.lifeBar ~= nil then
			self.lifeBar:setVisible( true )
		end
	end
end

function cComponent:isDestoryed()
	return self.destoryed
end

function cComponent:getDamage( dmg )
	if self.hp <= 0 then
		return
	end

	local hp = self.hp - dmg
	local lifeBar = self.lifeBar
    if lifeBar then
        local progress_ui = ccuiloader_seekNodeEx(lifeBar, "progress")
        progress_ui:setPercent(hp * 100 / self.maxHP)
    end
    self.hp = hp
	if hp <= 0 then
		--删除部件
		if self.masterUnit ~= nil then
			if self.masterUnit.view ~= nil then
				for i, boneName in ipairs( self.compName ) do
					local bone = self.masterUnit.view:getBone( boneName)
					if bone ~= nil then
						bone:getDisplayRenderNode():setVisible( false )
					end
				end
			end
			self:showDeadView()
			self.hp = 0
			self.destoryed = true
			if self.lifeBar ~= nil then
				self.lifeBar:setVisible( false )
			end
			--检验是否都destory了，如果是，变换枪组,如果不是，则移除组件带的枪,再移除一些组件
			if self.masterUnit:isAllComponentDestoryed() == true then
				for i, boneName in ipairs( self.allDestoryComps ) do
					local bone = self.masterUnit.view:getBone( boneName)
					if bone ~= nil then
						bone:getDisplayRenderNode():setVisible( false )
					end
				end
				self.masterUnit:resetGuns()
				self.masterUnit:addGuns( self.allDestoryGuns )
				if self.masterUnit.lifeBar ~= nil then
					self.masterUnit.lifeBar:setVisible( true )
				end
			else
				self.masterUnit:removeGuns( self.guns )
			end
		end
	end
end

function cComponent:showDeadView()

end

function cComponent:updateLifeBar()
	local lifeBar = self.lifeBar
    if lifeBar then
        local progress_ui = ccuiloader_seekNodeEx(lifeBar, "progress")
        progress_ui:setPercent( self.hp * 100 / self.maxHP)
    end
end

function cComponent:showLifeBar( visible )
	local lifeBar = self.lifeBar
    if lifeBar ~= nil then
        self.lifeBar:setVisible( visible and self.hp > 0 )
    end
end

function cComponent:getGunsId()
	return self.guns
end

return cComponent
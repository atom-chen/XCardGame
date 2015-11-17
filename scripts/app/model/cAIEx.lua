
cAIEx = class("cAIEx")

function cAIEx:ctor( id )
	self.states = {}
	self.curState = nil
	self.curAI = nil
	self.initState = nil
end

function cAIEx:nextCmd( unit )
	--初始化状态以及枪组
	if self.curState == nil then
		local initStateData = self.states[ self.initState ]
		if initStateData ~= nil then
			unit:removeGuns( initStateData.removeGuns )
			unit:addGuns( initStateData.addGuns )
			self:setCurAI( initStateData.aiId )
			self:doStateSwitchStatu( initStateData, unit )
			self.curState = { stateId = initStateData.stateId, time = initStateData.time }
		end
	end
end

function cAIEx:setCurAI( aiId )
	self.curAI = Factory.createAI( aiId, self.xMirror, self.yMirror )
end

function cAIEx:initByCfg( cfg, xMirror, yMirror  )
	self.xMirror = xMirror
	self.yMirror = yMirror
	self.states = {}
	for i,v in ipairs(cfg) do
		local stateId = v.stateId
		self.states[stateId] = v
		if self.initState == nil then
			self.initState = v.stateId
		end
	end
end

function cAIEx:doTransState( unit )
	local transData = self:getTransData( unit )
	if transData ~= nil then
		local randomVal = math.random(1, 10000 )
		local beginVal = 0
		local endVal = 0
		for i, v in ipairs( transData ) do
			endVal = beginVal + v[1] * 10000
			if randomVal > beginVal and randomVal <= endVal then
				--进行转换,枪组，动画等控制
				local nextState = self.states[ v[2] ]
				local curState = self.states[ self.curState.stateId ]
				if nextState ~= nil and curState ~= nil then
					--各种情况处理
					unit:removeGuns( self.curState.removeGuns )
					unit:removeGuns( nextState.removeGuns )
					unit:addGuns( nextState.addGuns )
					if tonumber( nextState.transEffect ) ~= nil then
						unit:showEffectAnim( nextState.transEffect )
					end
					if tonumber(nextState.transAnim) ~= nil then
						local function movementEventCallback( armature, movementEvetType, movementId )
					        if movementEvetType == 1 then
					            if tonumber(nextState.normalAnim) ~= nil and unit:setView(nextState.normalAnim ) then
								    unit.scene:addChild(unit.view, unit.zvalue)
							    end
					        end
					    end
						if unit:setView(nextState.transAnim, movementEventCallback ) then
						    unit.scene:addChild(unit.view, unit.zvalue)
					    end
					end
					self:setCurAI( nextState.aiId )
					self:doStateSwitchStatu( nextState, unit )
					self.curState = { stateId = nextState.stateId, time = nextState.time }
					return
				end
			end
			beginVal = endVal
		end
	end
end

function cAIEx:getTransData( unit )
	--策划附加转换规则，全毁之后不能改变形态为暴走
	local allCompDestoryed = unit:isAllComponentDestoryed()
	local tTransData = {}
	local curStateId = self.curState.stateId
	if curStateId ~= nil then
		local curStateData = self.states[ curStateId ]
		if curStateData ~= nil then
			if curStateData.stateType == ENUM_UNIT_TYPE_PRE_CRAZY and allCompDestoryed == true then
				table.insert( tTransData, { 1, curStateData.allDestroyTrans } )
				return tTransData
			end
			for i = 1, 5 do
				local chance = curStateData[string.format( "chance%s", i )]
				local transStateId = curStateData[string.format( "trans%s", i )]
				if chance ~= nil and transStateId ~= nil then
					table.insert( tTransData, { chance, transStateId } )
				end
			end
		end
	end
	return tTransData
end

function cAIEx:update( unit, dt )
	if self.curState == nil then
		return
	end
	if self.curAI ~= nil then
		self.curAI:update( unit, dt )
	end
	local time = self.curState.time - dt 
	if time <= 0 then
		self:doTransState( unit )
		return
	end
	self.curState.time = time
	if unit.specialType == ENUM_UNIT_SPECIAL_TYPE_COMP_BOSS then
    	local uiManager = app.uiManager
    	if uiManager ~= nil then
    		local uiMainGame = uiManager:getUIByName( "UIMainGame" )
    		if uiMainGame ~= nil then
	    		local bossFullPowLabel = uiMainGame:seekNodeByPath( "ref/bossFullPowLabel" )
	    		if bossFullPowLabel ~= nil then
	    			if unit.state == ENUM_UNIT_TYPE_PRE_CRAZY and unit:isAllComponentDestoryed() ~= true then
	    				bossFullPowLabel:setVisible( true )
	    				bossFullPowLabel:setString( string.format( "暴走剩余时间:%d", time ) )
	    			else
	    				bossFullPowLabel:setVisible( false )
	    			end
	    		end
	    	end
    	end
	end
end

function cAIEx:doStateSwitchStatu( stateData, unit )
	if stateData == nil or unit == nil then
		return
	end
	if stateData.stateType == ENUM_UNIT_TYPE_ENTRANCE then
		unit.cantDmgTime = stateData.time
		unit:setComponentsVisible( false )
		unit:stopGuns()
		unit:setLifeBarVisible( false )
		self.curAI:stopFire()
	elseif stateData.stateType == ENUM_UNIT_TYPE_NORMAL then
		unit.cantDmgTime = 0
		if unit:isAllComponentDestoryed() then
			unit:setComponentsVisible( false )
			unit:setLifeBarVisible( true )
		else
			unit:setComponentsVisible( true )
			unit:setLifeBarVisible( false )
		end
		unit:openGuns()
		self.curAI:openFire()
	elseif stateData.stateType == ENUM_UNIT_TYPE_PRE_CRAZY then
		unit.cantDmgTime = 0
		if unit:isAllComponentDestoryed() then
			unit:setComponentsVisible( false )
			unit:setLifeBarVisible( true )
		else
			unit:setComponentsVisible( true )
			unit:setLifeBarVisible( false )
		end
		unit:openGuns()
		self.curAI:openFire()
	elseif stateData.stateType == ENUM_UNIT_TYPE_CRAZY then
		unit.cantDmgTime = 0
		unit:setComponentsVisible( false )
		unit:setLifeBarVisible( true )
	elseif stateData.stateType == ENUM_UNIT_TYPE_INVNCIBLE then
		unit.cantDmgTime = stateData.time
		unit:setComponentsVisible( false )
		unit:setLifeBarVisible( false )
	elseif stateData.stateType == ENUM_UNIT_TYPE_DYING then
		unit.cantDmgTime = stateData.time
		unit:setComponentsVisible( false )
		unit:setLifeBarVisible( false )
		unit:stopGuns()
		self.curAI:stopFire()
	end
	unit.state = stateData.stateType
end

return cAIEx
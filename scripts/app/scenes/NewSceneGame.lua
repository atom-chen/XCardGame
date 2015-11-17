require("app/model/cWorld")

local scheduler = require(cc.PACKAGE_NAME .. ".scheduler") --加载定时器
local GuideHelper = import("app/ui/GuideHelper")

local CHANGE_GUNS_INTERVAL = 3.0

local SceneBaseClass = import("app/scenes/SceneBaseClass")

local NewSceneGame = class("NewSceneGame", SceneBaseClass)


function NewSceneGame:onCreate( playMissionId, missData )
    self.paused = false
    self.remain_revive_time = 0
    self.handle_RemainReviveTime = nil
    self.missData = missData
    self.playMissionId = playMissionId
    -- 创建游戏世界对象
    local world = cWorld.new(self, nil, playMissionId)
    self.world = world
end

function NewSceneGame:onEnter()
	Factory.clearUnitPool()
    -- 游戏世界的调用
    local world = self.world
    world:onEnter(app.planeId)
    local plane = world.plane

    world.missionResult = function(missionId, passed) 
        self:onMissionResult(missionId, passed) 
    end

    local uiManager = app.uiManager
    if uiManager ~= nil then
    	local function callback()
    		local uiMainGame = uiManager:getUIByName( "UIMainGame" )
    		if uiMainGame ~= nil then
    			uiMainGame:setGameScene( self )
    			uiMainGame:setMissData( self.missData )
    		end
    	end
    	uiManager:showUI( "UIMainGame", true, callback )
    end

    local planeData = app.planeDatas[app.planeId]
    if not planeData then
        planeData = cPlaneData.new(app.planeId)
    end
    plane:setPlaneData(planeData)

    world:createProtectBall(planeData)

    -- 启动帧侦听
    self:scheduleUpdate()  
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function( dt ) self:update(dt) end)    

    audio.playSound(GAME_SFX.missionStart);
    audio.playMusic(GAME_MUSIC.enterMission, true);
end

function NewSceneGame:onExit()

end

function NewSceneGame:update( dt )
	if self.paused == true then
		return
	end
	if dt > 0.02 then dt = 0.02 end
    self.world:update(dt * DEBUG_TIME_SPEED)
    if app.uiManager ~= nil and app.uiManager.update ~= nil then
    	app.uiManager:update( dt )
    end
end

function NewSceneGame:pauseGame( bIsPause )
	if bIsPause == true then
	   self.paused = true
	   self.world.activeFlags = {}
	else
		self.paused = false
    	self.world.activeFlags = {true, true, true, true, true, true, true, true}
	end
end

function NewSceneGame:onMissionResult(missionId, passed)
	local uiManager = app.uiManager
	if uiManager == nil then
		return
	end
    if passed == true then
    	self:pauseGame( true )
		self:showMissionPassed()
	else
		local function showedCallback()
			self:pauseGame( true )
		end
		local function choiceDieCallback()
			self:showMissionFailed()
		end
		local function choiceReviveCallback()
		    self.world.plane:onRevive()
		    local uiMainGame = uiManager:getUIByName( "UIMainGame" )
		    if uiMainGame ~= nil then
		    	uiMainGame:onUseProps(PROPS_TYPE_INVINCIBLE)
		    end
		    self:pauseGame( false )
		end
		local function closeBtnCallback()
			self:showMissionFailed()
		end
		local tData = 
		{ 
			Title = "选择复活",
			Desc = "就快打倒他们了，复活起来继续战斗吧？",
			Btn1Label = "我选择死亡",
			Btn1Callback = choiceDieCallback,
			Btn2Label = "继续战斗", 
			Btn2Callback = choiceReviveCallback,
			CloseCallback = closeBtnCallback,
		}
		uiManager:showConfirmDialog( tData, showedCallback )
	end
end

function NewSceneGame:showMissionFailed()
	local uiManager = app.uiManager
	if uiManager == nil then
		return
	end
	local function callback()
		local uiMissionResult = uiManager:getUIByName( "UIMissionResult" )
		if uiMissionResult ~= nil then
			uiMissionResult:setShowMode( 0 )
		end
	end
	audio.playSound(GAME_SFX.missionFailed);
	uiManager:showUI( "UIMissionResult", true, callback )
end

function NewSceneGame:showMissionPassed()
	local uiManager = app.uiManager
	local bag = app.bag
	if uiManager == nil or bag == nil then
		return
	end
	local function callback()
		local uiMissionResult = uiManager:getUIByName( "UIMissionResult" )
		if uiMissionResult ~= nil then
			local rewardTable = self:generateMissionReward( self.missData )
			if rewardTable ~= nil then
				--给奖励
				for i, v in ipairs( rewardTable ) do
					bag:addItemById( v.ItemId, v.ItemNum )
				end
				app:saveItemsData()
			end
			--给奖励相关
	        local missBonus = self:getMissBonus( self.missData, false )
	        if missBonus ~= nil then
	            --给金币和经验
	            app:modifyProps( PROPS_TYPE_EXP, missBonus.addExp )
	            app:modifyProps( PROPS_TYPE_GOLD, missBonus.addGold )
	        end
			app:missionCompleted( app.missionViewData )
			uiMissionResult:setShowMode( 1, rewardTable, missBonus )
		end
	end
	audio.playSound(GAME_SFX.missionCompleted);
	uiManager:showUI( "UIMissionResult", true, callback )
end

function NewSceneGame:generateMissionReward( missData )
	local rewardTable = {}
	if missData ~= nil then
		for i = 1, 5 do
			local itemId = missData.items[i]
			local minNum = missData.itemMinNum[i]
			local maxNum = missData.itemMaxNum[i]
			local rate   = missData.itemRate[i]
			if itemId ~= nil and minNum ~= nil and maxNum ~= nil and rate ~= nil then
				local randomVal = math.random( 1, 10000 )
				if randomVal < rate then
					local itemNum = math.random( minNum, maxNum )
					if itemNum > 0 then
						table.insert( rewardTable, { ItemId = itemId, ItemNum = itemNum } )
					end
				end
			end
		end
	end
	return rewardTable
end

function NewSceneGame:getMissBonus( missData, bSweep )
    local tMissBonusData = { addGold = 0, addExp = 0 }
    if missData ~= nil then
        tMissBonusData.addGold = missData.addGold
        tMissBonusData.addExp  = missData.addExp
        if bSweep == true then
            local minSweepGold = missData.sweepAddGold - sweepAddGold * 0.2
            local maxSweepGold = missData.sweepAddGold + sweepAddGold * 0.2
            local sweepGold = math.random( minSweepGold, maxSweepGold )
            if sweepGold > 0 then
                tMissBonusData.addGold = missData.addGold + sweepGold
            end
        end
    end
    return tMissBonusData
end

return NewSceneGame
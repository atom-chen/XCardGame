require("app/model/Factory")
require("app/model/cPlaneData")
require("app/model/cWingmanData")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

local UISelectPlane = class("UISelectPlane", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UISelectPlane:initConfig()
	self.jsonFilePath = "res/ui/newSelectPlane.json"
end

function UISelectPlane:onInitEventsHandler()
	--顶上的功能按钮
	self:registerEventsHandlers( "ref/titleLayer/storeBtn", 		   "OnClicked", self.onClickedStoreBtn )			--【商城】
	self:registerEventsHandlers( "ref/titleLayer/achivementBtn", 	   "OnClicked", self.onClickedAchivementBtnBtn )	--【成就】
	self:registerEventsHandlers( "ref/titleLayer/Button_17", 	   		"OnClicked", self.onClickedSignInBtnBtn )		--【签到】
	self:registerEventsHandlers( "ref/titleLayer/settingBtn", 		   "OnClicked", self.onClickedSettingBtn )			--【设置】
	self:registerEventsHandlers( "ref/titleLayer/Button_19", 		   "OnClicked", self.onClickedLotteryBtn )			--【抽奖】

	--功能界面1,僚机功能
	self:registerEventsHandlers( "funcLayer1/bottomLayer/bagBtn", 	   "OnClicked", self.onClickedFuncLayer1BagBtn )	--【背包】
	self:registerEventsHandlers( "funcLayer1/bottomLayer/backBtn", 	   "OnClicked", self.onClickedFuncLayer1BackBtn )	--【返回】
	self:registerEventsHandlers( "funcLayer1/preWingmanBtn",			"OnClicked",self.onClickedFuncLayer1PreWingmanBtn)  --【左切换僚机】
	self:registerEventsHandlers( "funcLayer1/nextWingmanBtn",			"OnClicked",self.onClickedFuncLayer1NextWingmanBtn)--【右切换僚机】
	self:registerEventsHandlers( "funcLayer1/enhBtn", 					"OnClicked",self.onClickedFuncLayer1EnhBtn )		--【僚机强化】
	self:registerEventsHandlers( "funcLayer1/bottomLayer/maxLvOrUnlockBtn","OnClicked", self.onClickedFuncLayer1MaxLvOrUnlockBtnBtn ) --【一键满级/解锁】
	--阵型slot相关
	for i = 1, 3 do
		self:registerItemSlot( "slot_"..i, "funcLayer1/formationLayer/pos_"..i, "funcLayer1/formationLayer/icon_"..i, nil, false, self.onClickedFuncLayer1FormationBtn )
	end

	--功能界面2, 飞机展示主功能界面
	self:registerEventsHandlers( "funcLayer2/bottomLayer/bossModeBtn",  "OnClicked", self.onClickedFuncLayer2BossModeBtn )		--【boss挑战模式】
	self:registerEventsHandlers( "funcLayer2/prePlaneBtn", 				"OnClicked", self.onClickedFuncLayer2PrePlaneBtn )		--【左切换】 
	self:registerEventsHandlers( "funcLayer2/nextPlaneBtn", 			"OnClicked", self.onClickedFuncLayer2NextPlaneBtn )		--【右切换】
	self:registerEventsHandlers( "funcLayer2/wingmanBtn",   			"OnClicked", self.onClickedFuncLayer2WingmanBtn )		--【僚机】
	self:registerEventsHandlers( "funcLayer2/planeBtn",     			"OnClicked", self.onClickedFuncLayer2PlaneBtn )			--【飞机】
	self:registerEventsHandlers( "funcLayer2/bottomLayer/missionBtn",   "OnClicked", self.onClickedFuncLayer2MissionBtn )		--【任务】
	self:registerEventsHandlers( "funcLayer2/techBtn", 					"OnClicked", self.onClickedFuncLayer2TechBtn )			--【科技】

	--功能界面3,战机界面
	self:registerEventsHandlers( "funcLayer3/bottomLayer/bagBtn", 		"OnClicked", self.onClickedFuncLayer3BagBtn )	--【背包】
	self:registerEventsHandlers( "funcLayer3/prePlaneBtn", 				"OnClicked", self.onClickedFuncLayer3PrePlaneBtn ) --【前一飞机】
	self:registerEventsHandlers( "funcLayer3/nextPlaneBtn", 			"OnClicked", self.onClickedFuncLayer3NextPlaneBtn )--【后一飞机】
	self:registerEventsHandlers( "funcLayer3/enhBtn",					"OnClicked", self.onClickedFuncLayer3EnhBtn)	--【升级】
	self:registerEventsHandlers( "funcLayer3/bottomLayer/backBtn",	  	"OnClicked", self.onClickedFuncLayer3BackBtn )	--【返回】
	self:registerEventsHandlers( "funcLayer3/bottomLayer/maxLvOrUnlockBtn","OnClicked", self.onClickedFuncLayer3MaxLvOrUnlockBtnBtn ) --【一键满级/解锁】
	self:registerEventsHandlers( "funcLayer3/mechcoreBtn", 				"OnClicked", self.onClickedMechCoreBtn )		--【机甲核心】

	self.handle_PROPS_NUMBER_CHANGED = app:addEventListener("PROPS_NUMBER_CHANGED", function(event) return self:updatePropsCount() end)
	self.tPlaneWingmanMap = 
	{
		[20001] = 20101,
		[20002] = 20102,
		[20003] = 20103,
	};
end

function UISelectPlane:initData()
	self.wingmanIdx = 1
	self.planeLv = 1
	self.curSelFormationIdx = 1
	self.curShowFuncLayerIdx = 1
	self.curFormationTypes = { 1, 2, 3 }
	app.curWingmanPlaneId = 20101
end

function UISelectPlane:onShowUI()
	self:showFuncLayer( 2 )
	self:updatePropsCount()
    self:updateFuncLayer2UI()
    local img13 = self:seekNodeByPath( "ref/bgLayer/Image_26" )
    if img13 ~= nil then
    	local tintBy = CCTintBy:create(4, 255, 0, 0)
    	if tintBy ~= nil then
    		img13:runAction( tintBy )
    	end
    end
end

function UISelectPlane:onCloseUI()
	app:removeEventListener(self.handle_PROPS_NUMBER_CHANGED)
end
---------------------------------------------------------------------------------------------------------
function UISelectPlane:updatePropsCount()
	local goldLabel = self:seekNodeByPath( "ref/titleLayer/goldLabel" )
    local crystalLabel = self:seekNodeByPath( "ref/titleLayer/diamondLabel" )
    if goldLabel ~= nil and crystalLabel ~= nil then
    	goldLabel:setString( app:getPropCount( PROPS_TYPE_GOLD ) )
    	crystalLabel:setString( app:getPropCount(PROPS_TYPE_DIAMAND) )
    end
end

function UISelectPlane:onClickedStoreBtn()
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		uiManager:showUI( "UIStore" )
	end
end	

function UISelectPlane:onClickedAchivementBtnBtn()
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		uiManager:showUI( "UIAchive" )
	end
end	

function UISelectPlane:onClickedSignInBtnBtn()
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		uiManager:showUI( "UILoginGift" )
	end
end	

function UISelectPlane:onClickedLotteryBtn()
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		uiManager:showUI( "UILotteryEnter" )
	end
end

function UISelectPlane:onClickedSettingBtn()
	self:showSystemTips( "该功能暂未开放" )
end	

function UISelectPlane:onClickedFuncLayer1BagBtn()
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		uiManager:showUI( "UIBag" )
	end
end

function UISelectPlane:showFuncLayer( idx )
	for i = 1, 3 do
		local layerNode = self:seekNodeByPath( string.format( "funcLayer%s", i ) )
		if layerNode ~= nil then
			layerNode:setVisible( i ==idx )
		end
	end
	self.curShowFuncLayerIdx = idx
end

function UISelectPlane:onClickedFuncLayer1BackBtn()
	local curScene = MyApp.sceneManager:getCurScene()
	if curScene ~= nil then
		self:showFuncLayer( 2 )
		local world = curScene.world
		if world ~= nil then
			world:setPlaneVisible( true )
			world:resetWingmanPos()
			self:setBgVisible( true, false )
			self:updateFuncLayer2UI()
		end
	end
end

function UISelectPlane:onClickedFuncLayer1PreWingmanBtn()
	local curScene = MyApp.sceneManager:getCurScene()
	if curScene ~= nil then
		local world = curScene.world
		if world ~= nil then
			self.wingmanIdx = self.wingmanIdx - 1
			if self.wingmanIdx == 0 then
				self.wingmanIdx = #world.wingmanIds
			end
			world:removeAllWingman()
			app.curWingmanPlaneId = world.wingmanIds[self.wingmanIdx]
			world:createWingman( app.curWingmanPlaneId )
			self:updateFuncLayer1UI()
			self:updateWingmanInfo()
		end
	end
end

function UISelectPlane:onClickedFuncLayer1NextWingmanBtn()
	local curScene = MyApp.sceneManager:getCurScene()
	if curScene == nil then
		return
	end
	local world = curScene.world
	if world ~= nil then
		self.wingmanIdx = self.wingmanIdx + 1
		if self.wingmanIdx > #world.wingmanIds then
			self.wingmanIdx = 1
		end
		world:removeAllWingman()
		app.curWingmanPlaneId = world.wingmanIds[self.wingmanIdx]
		world:createWingman(app.curWingmanPlaneId)
		self:updateFuncLayer1UI()
		self:updateWingmanInfo()
	end
end

function UISelectPlane:updateWingmanInfo()
	local bag = app.bag
	local curScene = MyApp.sceneManager:getCurScene()
	if curScene == nil or bag == nil then
		return
	end
	local world = curScene.world
	local unitCfg = CfgData.getCfg(CFG_UNIT, world.wingmanIds[self.wingmanIdx] )
	if unitCfg ~= nil and unitCfg.params1 ~= nil and unitCfg.params2 ~= nil then
		if #unitCfg.params1 ~= 3 and #unitCfg.params1 ~= 3 then
			return
		end
		for i, v in ipairs( unitCfg.params1 ) do
			local formationCfg = CfgData.getCfg( CFG_WINGMAN_POS, v )
			if formationCfg ~= nil then
				self:setItemSlotInfo( string.format("slot_%s", i),  bag:createNewItem(formationCfg.cardId) )
			end
		end
		self.curFormationTypes = unitCfg.params1
		world:resetWingmanPos()
		self.curSelFormationIdx = 1
		MyApp.curSelFormation = self.curFormationTypes[ self.curSelFormationIdx ]
	end
end

function UISelectPlane:updateFuncLayer1UI()
	local wingmanPlane = app.wingmanDatas[app.curWingmanPlaneId]
	local atkProgressBar = self:seekNodeByPath( "funcLayer1/atkProgressBar" )
	local atkLabel = self:seekNodeByPath( "funcLayer1/atkLabel" )
	local levelLabel = self:seekNodeByPath( "funcLayer1/levelLabel" )
	local enhBtnLabel = self:seekNodeByPath( "funcLayer1/enhBtn/enhBtnLabel" )
	local enhBtn = self:seekNodeByPath( "funcLayer1/enhBtn" )
	local maxLvOrUnlockLabel = self:seekNodeByPath( "funcLayer1/bottomLayer/maxLvOrUnlockBtn/maxLvOrUnlockLabel" )
	if atkProgressBar == nil or atkLabel == nil or levelLabel == nil or maxLvOrUnlockLabel == nil or 
	   enhBtnLabel == nil or enhBtn == nil then
		return
	end
	local showPlaneData = nil
	local lvUpNeedGold = 0
	local unlocked = false
	if wingmanPlane ~= nil then
		showPlaneData = wingmanPlane
		unlocked = true
	else
		showPlaneData = cWingmanData.new(app.curWingmanPlaneId)
	end
	if showPlaneData ~= nil then
		levelLabel:setString( string.format("%s/%s", showPlaneData.level, showPlaneData.maxLevel ) )
		atkLabel:setString( showPlaneData.showHurt or 0 )
		atkProgressBar:setPercent( (showPlaneData.showHurt / showPlaneData.maxHurt) * 100 )
		if unlocked == true then
			maxLvOrUnlockLabel:setString( "一键满级" )
		else 
			maxLvOrUnlockLabel:setString( "解锁" )
		end
		lvUpNeedGold = showPlaneData:lvUpNeedExp()
	end
	if showPlaneData:isMaxLevel() and showPlaneData:isMaxQuality() then
		enhBtn:setButtonEnabled( false )
		enhBtnLabel:setString( "MAX" )
	else
		enhBtn:setButtonEnabled( unlocked )
		enhBtnLabel:setString( "强化" )
	end
end

function UISelectPlane:onClickedFuncLayer1FormationBtn( sSlotName, control, event )
	if sSlotName == "slot_1" then
		self:OnClickedFormationBtn(1)
	elseif sSlotName == "slot_2" then
		self:OnClickedFormationBtn(2)
	elseif sSlotName == "slot_3" then
		self:OnClickedFormationBtn(3)
	end
end

function UISelectPlane:OnClickedFormationBtn( idx )
	local wingmanPlane = app.wingmanDatas[app.curWingmanPlaneId]
	local curScene = MyApp.sceneManager:getCurScene()
	local bag = app.bag
	if wingmanPlane == nil then
		self:showSystemTips( "请先对该僚机进行解锁" )
		return
	end
	if curScene == nil or bag == nil then
		return
	end
	local world = curScene.world
	if world == nil then
		return
	end
	if wingmanPlane.formationOpen[ idx ] ~= 1 then
		--进行物品检验，如果可以，扣除物品开启阵型
		local unitCfg = CfgData.getCfg(CFG_UNIT, world.wingmanIds[self.wingmanIdx] )
		if unitCfg ~= nil and unitCfg.params1 ~= nil then
			if #unitCfg.params1 ~= 3 and #unitCfg.params1 ~= 3 then
				return
			end
			local formationCfg = CfgData.getCfg( CFG_WINGMAN_POS, unitCfg.params1[idx] )
			if formationCfg ~= nil then
				local curCount =  bag:getItemCount( formationCfg.cardId )
				local needCount = formationCfg.needCount
				if curCount < needCount then
					self:showSystemTips( "集齐阵型卡才能开启该阵型" )
					return
				else
					bag:removeItemById( formationCfg.cardId, needCount )
					wingmanPlane.formationOpen[ idx ] = 1
					self:showSystemTips( "成功解锁阵型" )
					world:removeAllWingman()
					world:createWingman( app.curWingmanPlaneId )	
				end
			end
		end
	end
	local world = curScene.world
	if world ~= nil then
		self.curSelFormationIdx = idx
		world:resetWingmanPos()
		MyApp.curSelFormation = self.curFormationTypes[ self.curSelFormationIdx ] 
	end
end

function UISelectPlane:onClickedFuncLayer1EnhBtn()
	local wingmanPlane = app.wingmanDatas[app.curWingmanPlaneId]
	if wingmanPlane == nil then
		return
	end
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		local function callback()
			local uiEnhPlanePanel = uiManager:getUIByName( "UIEnhPlanePanel" )
			if uiEnhPlanePanel ~= nil then
				uiEnhPlanePanel:setShowType( 1 )
				uiEnhPlanePanel:setData( wingmanPlane )
				uiEnhPlanePanel:setCloseCallback(
													function()
														self:updateFuncLayer1UI() 	
													end 
												)
			end
		end
		uiManager:showUI( "UIEnhPlanePanel", true, callback )
	end
end

function UISelectPlane:onClickedFuncLayer1MaxLvOrUnlockBtnBtn()
	local wingmanPlaneId = app.curWingmanPlaneId
    if wingmanPlaneId ~= nil then
        local data = app.wingmanDatas[wingmanPlaneId]
        if data == nil then
        	app:buyWingman(wingmanPlaneId)
        	app:saveWingmanData()
        	self:updateFuncLayer1UI()
        	self:showSystemTips( "解锁僚机" )
        end
    end
end

function UISelectPlane:onClickedFuncLayer2BossModeBtn()
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		uiManager:showUI( "UIBossChallenge" )
	end
end

function UISelectPlane:onClickedFuncLayer2PrePlaneBtn()
    assert( MyApp.sceneManager ~= nil )
   	local curScene = MyApp.sceneManager:getCurScene()
   	if curScene ~= nil and curScene.world ~= nil then
   		local world = curScene.world
   		if world ~= nil then
		    world:showPrePlane()
		    if app.planeId ~= nil then
		    	local wingmanId = self.tPlaneWingmanMap[app.planeId]
		    	if wingmanId ~= app.curWingmanPlaneId then
			    	world:removeAllWingman()
					app.curWingmanPlaneId = wingmanId
					world:createWingman( app.curWingmanPlaneId )
				end
		    end
		    world:resetWingmanPos()
		    self.curSelFormationIdx = 1
			app.curSelFormation = self.curFormationTypes[ self.curSelFormationIdx ]
		    self:updateFuncLayer2UI()
		end
	end
end

function UISelectPlane:onClickedFuncLayer2NextPlaneBtn()
    assert( MyApp.sceneManager ~= nil )
   	local curScene = MyApp.sceneManager:getCurScene()
   	if curScene ~= nil and curScene.world ~= nil then
   		local world = curScene.world
   		if world ~= nil then
		    world:showNextPlane()
		    if app.planeId ~= nil then
		    	local wingmanId = self.tPlaneWingmanMap[app.planeId]
		    	if wingmanId ~= app.curWingmanPlaneId then
			    	world:removeAllWingman()
					app.curWingmanPlaneId = wingmanId
					world:createWingman( app.curWingmanPlaneId )
				end
		    end
		    world:resetWingmanPos()
		    self.curSelFormationIdx = 1
			app.curSelFormation = self.curFormationTypes[ self.curSelFormationIdx ]
		    self:updateFuncLayer2UI()
		end
	end
end

function UISelectPlane:onClickedFuncLayer2WingmanBtn()
	local curScene = MyApp.sceneManager:getCurScene()
	if curScene ~= nil then
		self:showFuncLayer( 1 )
		local world = curScene.world
		if world ~= nil then
			world:setWingManVisible( true )
			world:setPlaneVisible( false )
			world:resetWingmanPos()
			self:setBgVisible( false, true )
			self:updateFuncLayer1UI()
			self:updateWingmanInfo()
		end
	end
end

function UISelectPlane:onClickedFuncLayer2PlaneBtn()
	local curScene = MyApp.sceneManager:getCurScene()
	if curScene ~= nil then
		self:showFuncLayer( 3 )
		local world = curScene.world
		if world ~= nil then
			world:setPlaneVisible( true )
			world:setWingManVisible( false )
			world:resetWingmanPos()
			self:setBgVisible( true, false )
			self:updateFuncLayer3UI()
		end
	end
end

function UISelectPlane:onClickedFuncLayer2MissionBtn()
	local plane = app.planeDatas[app.planeId]
	if plane ~= nil then
		app:enterChoiceMission(app.planeId)
	else
		self:showSystemTips( "需要先解锁该飞机!" )
	end
end

function UISelectPlane:onClickedFuncLayer2TechBtn()
	local uiManager = self:getUIManager()
	if uiManager == nil then
		return
	end
	uiManager:showUI( "UITechPanel", true )
end

function UISelectPlane:updateFuncLayer2UI()
	local plane = app.planeDatas[app.planeId]
	local atkLabel = self:seekNodeByPath( "funcLayer2/atkLabel" )
	local defLabel = self:seekNodeByPath( "funcLayer2/defLabel" )
	local levelLabel = self:seekNodeByPath( "funcLayer2/levelLabel" )
	local atkProgressBar = self:seekNodeByPath( "funcLayer2/atkProgressBar" )
	local defProgressBar = self:seekNodeByPath( "funcLayer2/defProgressBar" )
	if atkLabel == nil or defLabel == nil or atkProgressBar == nil or defProgressBar == nil or levelLabel == nil then
		return
	end
	local showPlaneData = nil
	if plane ~= nil then
		showPlaneData = plane
	else
		showPlaneData = cPlaneData.new(app.planeId)
	end
	if showPlaneData ~= nil then
		levelLabel:setString( string.format("%s/%s", showPlaneData.level, showPlaneData.maxLevel ) )
		atkProgressBar:setPercent( (showPlaneData.showHurt / showPlaneData.maxHurt) * 100 )
		defProgressBar:setPercent( (showPlaneData.hp / showPlaneData.maxHP) * 100 )
		atkLabel:setString( showPlaneData.showHurt or 0 )
		defLabel:setString( showPlaneData.hp or 0 )
	end
end

function UISelectPlane:onClickedFuncLayer3BagBtn()
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		uiManager:showUI( "UIBag" )
	end
end

function UISelectPlane:onClickedFuncLayer3PrePlaneBtn()
	assert( MyApp.sceneManager ~= nil )
   	local curScene = MyApp.sceneManager:getCurScene()
   	if curScene ~= nil and curScene.world ~= nil then
	    curScene.world:showPrePlane()
	    curScene.world:resetWingmanPos()
	    self:updateFuncLayer3UI()
	end
end

function UISelectPlane:onClickedFuncLayer3NextPlaneBtn()
	assert( MyApp.sceneManager ~= nil )
   	local curScene = MyApp.sceneManager:getCurScene()
   	if curScene ~= nil and curScene.world ~= nil then
	    curScene.world:showNextPlane()
	    curScene.world:resetWingmanPos()
	    local planeId = app.planeId
	    self:updateFuncLayer3UI()
	end
end


function UISelectPlane:onClickedFuncLayer3EnhBtn()
	local plane = app.planeDatas[app.planeId]
	if plane == nil then
		return
	end
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		local function callback()
			local uiEnhPlanePanel = uiManager:getUIByName( "UIEnhPlanePanel" )
			if uiEnhPlanePanel ~= nil then
				uiEnhPlanePanel:setShowType( 0 )
				uiEnhPlanePanel:setData( plane )
				uiEnhPlanePanel:setCloseCallback(
													function()
														self:updateFuncLayer3UI() 	
													end 
												)
			end
		end
		uiManager:showUI( "UIEnhPlanePanel", true, callback )
	end
end

function UISelectPlane:updateFuncLayer3UI()
	local plane = app.planeDatas[app.planeId]
	local levelLabel = self:seekNodeByPath( "funcLayer3/levelLabel" )
	local atkLabel = self:seekNodeByPath( "funcLayer3/atkLabel" )
	local defLabel = self:seekNodeByPath( "funcLayer3/defLabel" )
	local atkProgressBar = self:seekNodeByPath( "funcLayer3/atkProgressBar" )
	local defProgressBar = self:seekNodeByPath( "funcLayer3/defProgressBar" )
	local enhBtn = self:seekNodeByPath( "funcLayer3/enhBtn" )
	local enhBtnLabel = self:seekNodeByPath( "funcLayer3/enhBtn/enhBtnLabel" )
	local maxLvOrUnlockLabel = self:seekNodeByPath( "funcLayer3/bottomLayer/maxLvOrUnlockBtn/maxLvOrUnlockLabel" )
	if levelLabel == nil or atkLabel == nil or defLabel == nil or 
	   atkProgressBar == nil or defProgressBar == nil or enhBtn == nil or enhBtnLabel == nil then
		return
	end
	local showPlaneData = nil
	local unlocked = false
	if plane ~= nil then
		showPlaneData = plane
		unlocked = true
	else
		showPlaneData = cPlaneData.new( app.planeId )
	end
	if showPlaneData ~= nil then
		levelLabel:setString( string.format("%s/%s", showPlaneData.level, showPlaneData.maxLevel ) )
		atkProgressBar:setPercent( (showPlaneData.showHurt / showPlaneData.maxHurt) * 100 )
		defProgressBar:setPercent( (showPlaneData.hp / showPlaneData.maxHP) * 100 )
		atkLabel:setString( showPlaneData.showHurt or 0 )
		defLabel:setString( showPlaneData.hp or 0 )
		if unlocked == true then
			maxLvOrUnlockLabel:setString( "一键满级" )
		else
			maxLvOrUnlockLabel:setString( "解锁" )
		end
		if showPlaneData:isMaxLevel() and showPlaneData:isMaxQuality() then
			enhBtn:setButtonEnabled( false )
			enhBtnLabel:setString( "MAX" )
		else
			enhBtn:setButtonEnabled( unlocked )
			enhBtnLabel:setString( "强化" )
		end
	end
end

function UISelectPlane:onClickedFuncLayer3BackBtn()
	local curScene = MyApp.sceneManager:getCurScene()
	if curScene ~= nil then
		self:showFuncLayer( 2 )
		local world = curScene.world
		if world ~= nil then
			world:setPlaneVisible( true )
			world:setWingManVisible( true )
			world:resetWingmanPos()
			self:updateFuncLayer2UI()
		end
	end
end

function UISelectPlane:onClickedFuncLayer3MaxLvOrUnlockBtnBtn()
	local planeId = app.planeId
    if planeId ~= nil then
        local data = app.planeDatas[planeId]
        if data == nil then
        	app:buyPlane(planeId)
        	app:savePlaneData()
        	self:updateFuncLayer3UI()
        	self:showSystemTips( "解锁战机" )
        end
    end
end

function UISelectPlane:onClickedMechCoreBtn()
	local uiManager = self:getUIManager()
	if uiManager == nil then
		return
	end
	local planeId = app.planeId
    if planeId == nil then
    	return
    end
    local planeData = app.planeDatas[planeId]
    if planeData == nil then
    	self:showSystemTips( "请先对该战机进行解锁" )
    	return
    end
	local function callback()
		local uiMechCorePanel = uiManager:getUIByName( "UIMechCorePanel" )
		if uiMechCorePanel ~= nil then
			local tMechSlotData = planeData:getMechCoreSlotData()
			uiMechCorePanel:setMechCorePlaneData( planeData )
		end
	end
	uiManager:showUI( "UIMechCorePanel", true, callback )
end

function UISelectPlane:setBgVisible( bigBgVisible , smallBgVisible )
	local showPlaneNode = self:seekNodeByPath( "showPlaneNode" )
	if showPlaneNode ~= nil then
		if smallBgVisible == true then
			showPlaneNode:setPosition( CCPoint( 0, 260 ) )
		else
			showPlaneNode:setPosition( CCPoint( 0, 150 ) )
		end
	end
end
---------------------------------------------------------------------------------------------------------
return UISelectPlane
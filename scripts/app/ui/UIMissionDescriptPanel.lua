require("app/model/Factory")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

local UIMissionDescriptPanel = class("UIMissionDescriptPanel", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UIMissionDescriptPanel:initConfig()
	self.jsonFilePath = "res/ui/missionDescript.json"
end

function UIMissionDescriptPanel:onInitEventsHandler()
	self:registerEventsHandlers( "ref/bossMissionLayer/closeBtn",   "OnClicked", self.onClickedCloseBtn )				--【关闭】
	self:registerEventsHandlers( "ref/normalMissionLayer/closeBtn", "OnClicked", self.onClickedCloseBtn )				--【关闭】
	self:registerEventsHandlers( "ref/sweepBtn", 					"OnClicked", self.onClickedSweepBtn )				--【扫荡】
	self:registerEventsHandlers( "ref/enterGameBtn", "OnClicked", self.onClickedEnterGameBtn )		--【进入游戏】
	self:registerEventsHandlers( "ref/" )
	for i = 1, 5 do
		self:registerItemSlot( "slot_" .. i, "ref/iconsLayer/itemBtn_" .. i, "ref/iconsLayer/img_" .. i, "",true )
	end
end

function UIMissionDescriptPanel:initData()
	self.missionViewData = nil
end

function UIMissionDescriptPanel:onShowUI()
	self.showNotEnoughPowTips = {}
	local normalMissionLayer = self:seekNodeByPath( "ref/normalMissionLayer" )
	local bossMissionLayer   = self:seekNodeByPath( "ref/bossMissionLayer" )
	local bossViewBg = self:seekNodeByPath( "ref/bossViewBg" )
	local normalViewBg = self:seekNodeByPath( "ref/normalViewBg" )
	if normalMissionLayer ~= nil and bossMissionLayer ~= nil and bossViewBg ~= nil and normalViewBg ~= nil then
		bossMissionLayer:setVisible( false )
		normalMissionLayer:setVisible( false )
		bossViewBg:setVisible( false )
		normalViewBg:setVisible( false )
	end	
end

function UIMissionDescriptPanel:onCloseUI()
	self.showNotEnoughPowTips = {}
end
---------------------------------------------------------------------------------------------------------
function UIMissionDescriptPanel:onClickedCloseBtn()
	self:close()
end

function UIMissionDescriptPanel:onClickedSweepBtn()
	local mybag = MyApp.bag
	if mybag == nil then
		return
	end
	local sweepCardNum = mybag:getItemCount( SPECIAL_ITEM_ID_SWEEP_CARD )
	if sweepCardNum == 0 then
		self:showSystemTips( "没有扫荡卡,不能进行扫荡" )
		return
	end
	mybag:removeItemById( SPECIAL_ITEM_ID_SWEEP_CARD, 1 )
	--扫荡完成
end

function UIMissionDescriptPanel:onClickedEnterGameBtn()
	local uiManager = self:getUIManager()
	if self.missionViewData == nil or uiManager == nil then
		return
	end
	if self.missionViewData.challengeTime > 0 then
		local missStatu = app:getMissStatu( self.missionViewData.id )
		if missStatu ~= nil then
			if missStatu.todayFinishTime >= self.missionViewData.challengeTime then
				self:showSystemTips( "当日挑战次数用完,请购买次数之后再挑战!" )
				return
			end
		end
	end
	local missionId = self.missionViewData.id
	local curCombatPow = app:getCombatPow()
	if curCombatPow < self.missionViewData.recommendPowPoint then
		if self.showNotEnoughPowTips[missionId] ~= true then
			self.showNotEnoughPowTips[missionId] = true
			local function confrimBtnCallback()
				--跳转回到战机强化界面
				app:enterSelectPlane()
			end
			local function cancelCallback()
				app:playMissionByIndex(self.missionViewData.missionId, self.missionViewData )
				app.missionViewData = self.missionViewData
			end
			local tData = 
			{ 
				Title = "战力不足",
				Desc = "您的战力稍微有点不够哦,是否要提升一下来挑战呢?",
				Btn1Label = app:GET_STR( "STR_OK" ),
				Btn1Callback = confrimBtnCallback,
				Btn2Label = app:GET_STR( "STR_CANCEL" ), 
				Btn2Callback = cancelCallback,
				CloseCallback = nil,
			}
			uiManager:showConfirmDialog( tData )	
			return
		end
	end
	app:playMissionByIndex(self.missionViewData.missionId, self.missionViewData )
	app.missionViewData = self.missionViewData
end

function UIMissionDescriptPanel:setShowMission( missionViewData )
	self.missionViewData = missionViewData
	self:updateUI()
end

function UIMissionDescriptPanel:updateUI()
	local missionViewData = self.missionViewData
	local mybag = MyApp.bag
	if missionViewData == nil or mybag == nil then
		return
	end
	local sShowLayerName = "normalMissionLayer"
	local sShowBgName = "normalViewBg"
	local bChallengeBtnEnable = false
	if missionViewData.bossViewId ~= nil and missionViewData.bossViewId > 0 then
		sShowLayerName = "bossMissionLayer"
		sShowBgName = "bossViewBg"
		bChallengeBtnEnable = true
	end
	local descLabel = self:seekNodeByPath( "ref/descLabel" )
	local sweepCardNumLabel = self:seekNodeByPath( "ref/sweepCardNumLabel" )
	local sweepBtn = self:seekNodeByPath( "ref/sweepBtn" )
	local showBg = self:seekNodeByPath( string.format( "ref/%s", sShowBgName ) )
	local showLayer = self:seekNodeByPath( string.format( "ref/%s", sShowLayerName ) )
	local leftCount = self:seekNodeByPath( string.format( "ref/%s/leftCount", sShowLayerName ) )
	local missionTitleLabel = self:seekNodeByPath( string.format( "ref/%s/missionTitleLabel", sShowLayerName) )
	local addChallengeTimeBtn = self:seekNodeByPath( string.format( "ref/%s/addChallengeTimeBtn", sShowLayerName ) )
	local recommendPowPoint = self:seekNodeByPath( string.format( "ref/%s/recommendPowPoint", sShowLayerName) )
	if missionTitleLabel == nil or missionViewData == nil or descLabel == nil or recommendPowPoint == nil or leftCount == nil or 
	   showBg == nil or sweepCardNumLabel == nil and showLayer ~= nil  or sweepBtn == nil then
		return
	end
	if missionViewData.bossViewId > 0 then
		local bossAnim = Factory.createAnim( missionViewData.bossViewId )
		if bossAnim ~= nil then
			local bossViewNode = self:seekNodeByPath( "ref/bossMissionLayer/bossViewNode" )
			if bossViewNode ~= nil then
				bossViewNode:removeAllChildren()
				bossAnim:setScale( missionViewData.viewScale or 0.4 )
				bossViewNode:addChild( bossAnim, 10 )
			end
		end
	end
	sweepCardNumLabel:setString( string.format( "扫荡卡:x%d", mybag:getItemCount( SPECIAL_ITEM_ID_SWEEP_CARD ) ) )
	addChallengeTimeBtn:setButtonEnabled( bChallengeBtnEnable )
	showBg:setVisible( true )
	showLayer:setVisible( true )
	missionTitleLabel:setString( string.format( "第%s关·%s", missionViewData.id, missionViewData.name) )
	descLabel:setString( missionViewData.desc or "" )
	recommendPowPoint:setString( missionViewData.recommendPowPoint or 0 )
	local curCombatPow = app:getCombatPow()
	if curCombatPow > missionViewData.recommendPowPoint then
		recommendPowPoint:setColor( cc.c3b(0, 255, 0) )
	else
		recommendPowPoint:setColor( cc.c3b(255, 0, 0) )
	end
	local missStatu = app:getMissStatu( missionViewData.id )
	if missionViewData.challengeTime == 0 then
		leftCount:setString( "不限" )
	else
		local todayLeftTime = missionViewData.challengeTime
		local totalTime = missionViewData.challengeTime
		if missStatu == nil then
			todayLeftTime = 3
		else
			todayLeftTime = totalTime - missStatu.todayFinishTime
			if todayLeftTime <= 0 then
				todayLeftTime = 0
			end
		end
		leftCount:setString( string.format( "%s/%s", todayLeftTime, totalTime ) )
	end
	if missStatu == nil then
		sweepBtn:setButtonEnabled( false )	--没有进行管卡通关的不能进行扫荡
	else
		if missStatu.passed == true then
			sweepBtn:setButtonEnabled( true )
		else
			sweepBtn:setButtonEnabled( false )
		end
	end
	descLabel:setDimensions( CCSize( 450, 140 ) )
  	descLabel:setContentSize( CCSize( 450, 140) )
	local bag = MyApp.bag
	if bag ~= nil then
		for i = 1, 5 do
			local slotName = string.format( "slot_%s", i)
			local itemId = missionViewData.items[i]
			if itemId == nil or itemId == 0 then
				self:setItemSlotVisible( slotName, false )
			else
				self:setItemSlotVisible( slotName, true )
				self:setItemSlotInfo( slotName, bag:createNewItem( itemId ) )
			end
		end
	end
end

return UIMissionDescriptPanel
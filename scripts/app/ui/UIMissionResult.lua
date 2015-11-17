require("app/model/Factory")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

local UIMissionResult = class("UIMissionResult", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UIMissionResult:initConfig()
	self.jsonFilePath = "res/ui/missionResult.json"
end

function UIMissionResult:onInitEventsHandler()
	self:registerEventsHandlers( "ref/winPanel/backBtn", "OnClicked", self.onClickedWinPanelBackBtn )				--【返回】
	self:registerEventsHandlers( "ref/winPanel/nextLevelBtn", "OnClicked", self.onClickedWinPanelNextLevelBtn )		--【下一关】

	self:registerEventsHandlers( "ref/failedPanel/backBtn", 		"OnClicked", self.onClickedFailedPanelBackBtn )		--【返回】
	self:registerEventsHandlers( "ref/failedPanel/restartBtn", 		"OnClicked", self.onClickedFailedPanelRestartBtn )	--【重新开始】
	self:registerEventsHandlers( "ref/failedPanel/updatePlaneBtn", 	"OnClicked", self.onClickedUpatePlaneBtn )			--【战机升级】
	self:registerEventsHandlers( "ref/failedPanel/updateWingmanBtn", "OnClicked", self.onClickedUpateWingmanBtn )		--【僚机升级】

	for i = 1, 5 do
		self:registerItemSlot( "slot_" .. i, "ref/winPanel/itemLayer/itemBtn_" .. i, 
											 "ref/winPanel/itemLayer/icon_" .. i, 
											 "ref/winPanel/itemLayer/num_" .. i, true )
	end
end

function UIMissionResult:initData()
	self.showMode = 0
	self.rewardItemData = nil
	self.missBonus = nil
end

function UIMissionResult:onShowUI()
	self:setShowMode( 0 )
end

function UIMissionResult:onCloseUI()
end
---------------------------------------------------------------------------------------------------------
function UIMissionResult:setShowMode( showMode, rewardItemData, missBonus )
	self.showMode = showMode
	local uiManager = self:getUIManager()
	local winPanel = self:seekNodeByPath( "ref/winPanel" )
	local failedPanel = self:seekNodeByPath( "ref/failedPanel" )
	local star = self:seekNodeByPath( "ref/star/starProgressBar" )
	local failedText = self:seekNodeByPath( "ref/failedPanel/failedText" )
	local upFrameSprite = self:seekNodeByPath( "ref/bgLayer/upFrameSprite" )
	local downFrameSprite = self:seekNodeByPath( "ref/bgLayer/downFrameSprite" )
	local strideBg = self:seekNodeByPath( "ref/bgLayer/strideBg" )
	local starBg = self:seekNodeByPath( "ref/star/starBg" )
	if winPanel == nil or failedPanel == nil or star == nil or failedText == nil or downFrameSprite == nil or 
		uiManager == nil or strideBg == nil or starBg == nil then
		return
	end
	if self.showMode == 0 then
		winPanel:setVisible( false )
		failedPanel:setVisible( true )
		star:setPercent(0)
		failedText:setString( "    好可惜，差一点点就成功了呢，尝试以下提高战斗力吧" )
		failedText:setDimensions( CCSize( 600, 90 ) )
		failedText:setContentSize( CCSize( 600, 90 ) )
		uiManager:setSpriteGray( upFrameSprite, true )
		uiManager:setSpriteGray( downFrameSprite, true )
		uiManager:setSpriteGray( strideBg, true )
		uiManager:setSpriteGray( starBg, true )
		self.rewardItemData = nil
	elseif self.showMode == 1 then
		star:setPercent(100)
		winPanel:setVisible( true )
		failedPanel:setVisible( false )
		self.rewardItemData = rewardItemData
		self.missBonus = missBonus
		self:UpdateView()
	end
end

function UIMissionResult:onClickedWinPanelBackBtn()
	app:enterChoiceMission(app.planeId)
end


function UIMissionResult:onClickedWinPanelNextLevelBtn()
	app:enterChoiceMission(app.planeId)
end

function UIMissionResult:onClickedFailedPanelBackBtn()
	app:enterChoiceMission(app.planeId)
	self:UpdateView()
end

function UIMissionResult:UpdateView()
	local bag = MyApp.bag
	if self.rewardItemData ~= nil and bag ~= nil then
		for i = 1, 5 do
			local slotName = string.format( "slot_%s", i )
			local rewardData = self.rewardItemData[i]
			if rewardData ~= nil then
				local itemId = rewardData.ItemId
				if itemId ~= nil and itemId > 0 then
					self:setItemSlotVisible( slotName, true )
					local newItem = bag:createNewItem( itemId )
					if newItem ~= nil then
						newItem.count = rewardData.ItemNum
						self:setItemSlotInfo( slotName, newItem )
					end
				else
					self:setItemSlotVisible( slotName, false )
				end
			else
				self:setItemSlotVisible( slotName, false )
			end
		end
		if self.missBonus ~= nil then
			local addGoldLabel = self:seekNodeByPath( "ref/winPanel/addGold" )
			local addExpLabel = self:seekNodeByPath( "ref/winPanel/addExp" )
			if addGoldLabel ~= nil and addExpLabel ~= nil then
				addGoldLabel:setString( self.missBonus.addGold or 0 )
				addExpLabel:setString( self.missBonus.addExp or 0 )
			end
		end
	end
end

function UIMissionResult:onClickedFailedPanelRestartBtn()
	local sceneManager = app.sceneManager
	if sceneManager ~= nil then
		local gameScene = sceneManager:getCurScene()
		if gameScene ~= nil then
			app:playMissionByIndex( gameScene.playMissionId, app.missionViewData )
		end
	end
end


function UIMissionResult:onClickedUpatePlaneBtn()
	app:enterSelectPlane()
end

function UIMissionResult:onClickedUpateWingmanBtn()
	app:enterSelectPlane()
end

return UIMissionResult
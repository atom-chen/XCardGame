require("app/model/Factory")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

local UIEnhPanelPanel = class("UIEnhPanelPanel", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UIEnhPanelPanel:initConfig()
	self.jsonFilePath = "res/ui/enhPlanePanel.json"
end

function UIEnhPanelPanel:onInitEventsHandler()
	self:registerEventsHandlers( "ref/closeBtn", 		   "OnClicked", self.onClickedCloseBtn )			--【关闭】
	self:registerEventsHandlers( "ref/contentPanel/lvUpBtn","OnClicked", self.onClickedLvUpBtn )			--【升级】
	self:registerEventsHandlers( "ref/contentPanel/qualityUpBtn", "OnClicked", self.onClickedQualityUpBtn ) --【进阶】
	for i = 1, 3 do
		self:registerItemSlot( "slot_" .. i, "ref/needItemLayer/itemBtn_" .. i , "ref/needItemLayer/itemIcon_" .. i, "",true )
	end
end

function UIEnhPanelPanel:initData()
	self.showType = 0 --mode: 0 飞机 1 僚机
	self.planeData = nil
end

function UIEnhPanelPanel:onShowUI()
	self.planeData = nil
end

function UIEnhPanelPanel:onCloseUI()
end
---------------------------------------------------------------------------------------------------------
function UIEnhPanelPanel:onClickedCloseBtn()
	self:close()
end

function UIEnhPanelPanel:onClickedLvUpBtn()
	local planeData = self.planeData
	if planeData == nil then
		return
	end
	--检验经验是否足够
	local curExp = 0
	local curGold= 0
	local props = app.propsData[PROPS_TYPE_EXP]
    if props ~= nil then
        curExp = props.count
    end
    local props = app.propsData[PROPS_TYPE_GOLD]
    if props ~= nil then
        curGold = props.count
    end
	if planeData:lvUpNeedExp() > curExp then
		self:showSystemTips( "经验不足" )
		return
	end
	if planeData:lvUpNeedGold() > curGold then
		self:showSystemTips( "金币不足" )
		return
	end
	local result = app:modifyExp( -planeData:lvUpNeedExp() )
	if result ~= true then
		return
	end
	local result = app:modifyGold( -planeData:lvUpNeedGold() )
	if result ~= true then
		return
	end
	if planeData:addLevel() then
		self:updateUIByData()
		if self.showType == 0 then
			app:savePlaneData()
		else
			app:saveWingmanData()
		end
	end
end

function UIEnhPanelPanel:onClickedQualityUpBtn()
	local planeData = self.planeData
	local bag = app.bag
	if planeData == nil or bag == nil then
		return
	end
	--物品数量检验和扣除
	local itemsId, itemsCount = planeData:getQualityUpMaterial()
	if itemsId == nil or itemsCount == nil then
		return
	end
	for i, v in ipairs( itemsId ) do
		local curCount = bag:getItemCount( v )
		local needCount = itemsCount[i]
		if curCount < needCount then
			self:showSystemTips( "缺少进阶所需材料" )
			return
		end
	end
	--材料齐备，扣除进阶
	for i, v in ipairs( itemsId ) do
		bag:removeItemById( v, itemsCount[i] )
	end
	if planeData:addQuality() then
		planeData:addLevel()
		self:updateUIByData()
		if self.showType == 0 then
			app:savePlaneData()
		else
			app:saveWingmanData()
		end
	end
end

function UIEnhPanelPanel:setShowType( type )
	self.showType = type
end

function UIEnhPanelPanel:setData( planeData )
	self.planeData = planeData
	self:updateUIByData()
end

function UIEnhPanelPanel:updateUIByData()
	local bag = app.bag
	local lvUpLabelName = "ref/contentPanel/planeAttri/lvUpLabel"
	local atkUpLabelName = "ref/contentPanel/planeAttri/atkUpLabel"
	local hpUpLabelName = "ref/contentPanel/planeAttri/hpUpLabel"
	if self.showType == 1 then
		lvUpLabelName = "ref/contentPanel/wingmanAttri/lvUpLabel"
		atkUpLabelName = "ref/contentPanel/wingmanAttri/atkUpLabel"
		hpUpLabelName = ""
	end
	local lvUpLabel = self:seekNodeByPath( lvUpLabelName )
	local atkUpLabel = self:seekNodeByPath( atkUpLabelName )
	local hpUpLabel = self:seekNodeByPath( hpUpLabelName )
	local titleLabel = self:seekNodeByPath( "ref/titleLabel" )
	local curExpLabel = self:seekNodeByPath( "ref/contentPanel/curExpLabel" )
	local needExpLabel = self:seekNodeByPath( "ref/contentPanel/needExpLabel" )
	local needGoldLabel = self:seekNodeByPath( "ref/contentPanel/lvUpBtn/needGoldLabel" )
	local lvUpBtn = self:seekNodeByPath( "ref/contentPanel/lvUpBtn" )
	local qualityUpBtn = self:seekNodeByPath( "ref/contentPanel/qualityUpBtn" )
	local lvUpIconPanel = self:seekNodeByPath( "ref/lvUpIconPanel" )
	local qualityUpPanel = self:seekNodeByPath( "ref/qualityUpPanel" )
	local planeAttriLayer = self:seekNodeByPath( "ref/contentPanel/planeAttri" )
	local wingmanAttriLayer = self:seekNodeByPath( "ref/contentPanel/wingmanAttri" )
	local tipsLabel = self:seekNodeByPath( "ref/contentPanel/tipsLabel" )
	if bag == nil or self.planeData == nil or lvUpLabel == nil or atkUpLabel == nil or curExpLabel == nil or needGoldLabel == nil or
		planeAttriLayer == nil or tipsLabel == nil or  wingmanAttriLayer == nil or needExpLabel == nil or lvUpBtn == nil or 
		qualityUpBtn == nil or lvUpIconPanel == nil or qualityUpPanel == nil or titleLabel == nil then
		return
	end
	if self.showType == 0 then
		planeAttriLayer:setVisible( true )
		wingmanAttriLayer:setVisible( false )
		titleLabel:setString( "飞机升级" )
	else
		planeAttriLayer:setVisible( false )
		wingmanAttriLayer:setVisible( true )
		titleLabel:setString( "僚机升级" )
	end
	local planeData = self.planeData
	atkUpLabel:setString( string.format( "%s->%s", planeData.showHurt, planeData.nextHurt ) )
	if hpUpLabel ~= nil then
		hpUpLabel:setString( string.format( "%s->%s", planeData.hp, planeData.nextHP ) )
	end
	local curExp = 0
	local props = app.propsData[PROPS_TYPE_EXP]
    if props ~= nil then
        curExp = props.count
    end
	local needExp = planeData:lvUpNeedExp()
	local needGold = planeData:lvUpNeedGold()
	curExpLabel:setString( string.format( "%s",curExp) )
	needExpLabel:setString( string.format( "%s", needExp) )
	needGoldLabel:setString( string.format( "%s", needGold ) )
	local itemsId, needItemsCount = planeData:getQualityUpMaterial()
	if itemsId ~= nil and needItemsCount ~= nil then
		for i = 1, 3 do
			self:setItemSlotInfo( string.format( "slot_%s", i ), bag:createNewItem( itemsId[i] ) )
			local curHaveNum = bag:getItemCount( itemsId[i] )
			local needNumLabel = self:seekNodeByPath( string.format( "ref/needItemLayer/needNum_%s", i ) )
			if needNumLabel ~= nil then
				needNumLabel:setString( string.format( "%s/%s", curHaveNum, needItemsCount[i] ) )
			end
		end
	end
	if planeData:isMaxLevel() ~= true then
		lvUpLabel:setString( string.format( ":%s->%s", planeData.level, planeData.level + 1 ) )
		lvUpIconPanel:setVisible( true )
		qualityUpPanel:setVisible( false )
		qualityUpBtn:setButtonEnabled( false )
		lvUpBtn:setButtonEnabled( true )
		tipsLabel:setString( "< 升级该品质满级可进阶 >" )
	else--等级不变，品质改变
		lvUpLabel:setString( string.format( ":%s->%s", planeData.level, planeData.level + 1) )
		lvUpIconPanel:setVisible( false )
		qualityUpPanel:setVisible( true )
		qualityUpBtn:setButtonEnabled( true )
		lvUpBtn:setButtonEnabled( false )
		tipsLabel:setString( "< 进阶之后可以继续升级哦 >" )
		if planeData:isMaxQuality() == true then
			qualityUpBtn:setButtonEnabled( false )
			curExpLabel:setString( "" )
			tipsLabel:setString( "< 已达最大等级和品质 >" )
		end
	end
end

return UIEnhPanelPanel
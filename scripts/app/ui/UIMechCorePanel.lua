require("app/model/Factory")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

local UIMechCorePanel = class("UIMechCorePanel", UIBaseClass )
local MERGE_SLOT_COUNT = 5
local MECH_SLOT_COUNT = 4
---------------------------------------------------------------------------------------------------------
function UIMechCorePanel:initConfig()
	self.jsonFilePath = "res/ui/mechCorePanel.json"
end

function UIMechCorePanel:onInitEventsHandler()
	--mainPanel
	self:registerEventsHandlers( "mainPanel/mergeBtn", 		"OnClicked",	self.onClickedMainPanelMergeBtn)	--【合成】按钮
	self:registerEventsHandlers( "mainPanel/closeBtn", 		"OnClicked",	self.onClickedMainPanelCloseBtn)	--关闭按钮
	for i = 1, MECH_SLOT_COUNT do
		self:registerItemSlot( "slot_" .. i, "mainPanel/slots/slotBtn_" .. i , "mainPanel/slots/slotIcon_" .. i, "",true ) --注册物品slot
		local slotBtn = self:seekNodeByPath( "mainPanel/slotOpBtn" .. i )
		if slotBtn ~= nil then
			slotBtn.tUserData = i
		end
		self:registerEventsHandlers( "mainPanel/slotOpBtn" .. i, "OnClicked", self.onClickedMainPanelSlotOpBtn ) --点击到了卸下/开启按钮
	end
	--mergePanel
	self:registerEventsHandlers( "mergePanel/closeBtn", 	"OnClicked", 	self.onClickedMergePanelCloseBtn )	--关闭按钮
	self:registerEventsHandlers( "mergePanel/qualityBtn1", 	"OnClicked", 	self.onClickedMergePanelQualityBtn1 )--品质按钮1(蓝)
	self:registerEventsHandlers( "mergePanel/qualityBtn2", 	"OnClicked", 	self.onClickedMergePanelQualityBtn2 )--品质按钮2(紫)
	self:registerEventsHandlers( "mergePanel/mergeBtn", 	"OnClicked", 	self.onClickedMergePanelMergeBtn )	--合成按钮
	for i = 1, 6 do
		if i ~= 6 then
			self:registerItemSlot( "mergeSlot_" .. i, "mergePanel/slotsLayer/slotBtn_" .. i , "mergePanel/slotsLayer/slotIcon_" .. i, "",true, self.onClickMergeSlot )
		else
			self:registerItemSlot( "mergeSlot_" .. i, "mergePanel/slotsLayer/slotBtn_" .. i , "mergePanel/slotsLayer/slotIcon_" .. i, "",true )
		end
	end

	--selectItemPanel
	self:registerEventsHandlers( "selectItemPanel/closeBtn",	"OnClicked", 	self.onClickedSelectItemPanelCloseBtn ) 	--关闭按钮
	self:registerEventsHandlers( "selectItemPanel/confirmBtn",  "OnClicked", 	self.onClickedSelectItemPanelConfirmBtn ) 	--【确认】按钮
	self:registerEventsHandlers( "selectItemPanel/cancelBtn", 	"OnClicked",	self.onClickedSelectItemPanelCancelBtn )	--【取消】按钮
end

function UIMechCorePanel:initData()
	self.selecetItemMode = 1 --1:select single  2:select multiple 
	self.itemShowQuality = ENUM_ITEM_QUALITY_BLUE
	self.tCheckboxGroup = {}
	self.tSelectedCheckBox = {}
end

function UIMechCorePanel:onShowUI()
	self:showSelectItemPanel( false )
	self:showMergePanel( false )
	local mainPanel = self:seekNodeByPath( "mainPanel" )
	local selectItemPanel = self:seekNodeByPath( "selectItemPanel" )
	local mergePanel = self:seekNodeByPath( "mergePanel" )
	if mainPanel ~= nil and selectItemPanel ~= nil and mergePanel ~= nil then
		mainPanel:setTouchEnabled(true)
		mainPanel:setTouchSwallowEnabled(true)
		selectItemPanel:setTouchEnabled(true)
		selectItemPanel:setTouchSwallowEnabled(true)
		mergePanel:setTouchEnabled(true)
		mergePanel:setTouchSwallowEnabled(true)
	end
end

function UIMechCorePanel:onCloseUI()
end
---------------------------------------------------------------------------------------------------------
function UIMechCorePanel:showSelectItemPanel( bVisible )
	local selectItemPanel = self:seekNodeByPath( "selectItemPanel" )
	if selectItemPanel == nil then
		return
	end
	selectItemPanel:setVisible( bVisible )
end

function UIMechCorePanel:showMergePanel( bVisible )
	local mergePanel = self:seekNodeByPath( "mergePanel" )
	if mergePanel == nil then
		return
	end
	mergePanel:setVisible( bVisible )
	local mergeBtn = self:seekNodeByPath( "mergePanel/mergeBtn" )
	if mergeBtn ~= nil then
		mergeBtn:setButtonEnabled( false )
	end
end

function UIMechCorePanel:onClickedMainPanelSlotOpBtn( oControl )
	local tUserData = oControl.tUserData
	local planeData = self.planeData
	local uiManager = self:getUIManager()
	local myBag = app.bag
	if tUserData == nil or uiManager == nil or planeData == nil or myBag == nil then
		return
	end
	local mechCoreSlotData = planeData:getMechCoreSlotData()
	local selIdx = tonumber( tUserData )
	if selIdx == nil or mechCoreSlotData == nil then
		return
	end
	local mechItemId = mechCoreSlotData[ selIdx ]
	if mechItemId == -1 then	
		local slotCount = planeData:getOpenMechCoreSlotCount()
		local needGold = slotCount * 50000
		local function confrimBtnCallback()
			local curGold = 0
			local props = app.propsData[PROPS_TYPE_GOLD]
		    if props ~= nil then
		        curGold = props.count
		    end
		    if curGold < needGold then
		    	self:showSystemTipsEx( "TIP_NOT_ENOUGH_GOLD" )
		    	return
		    end
		    local ret = app:modifyGold( -needGold )
		    if ret ~= true then
		    	return
		    end
			planeData:openAMechCoreSlot()
			app:savePlaneData()
			self:updateMainPanelView()
		end
		local tData = 
		{ 
			Title = "开启核心机甲",
			Desc = string.format( "是否花费%s金币开启核心机甲?", needGold ),
			Btn1Label = app:GET_STR( "STR_CANCEL" ),
			Btn1Callback = nil,
			Btn2Label = app:GET_STR( "STR_OK" ), 
			Btn2Callback = confrimBtnCallback,
			CloseCallback = nil,
		}
		uiManager:showConfirmDialog( tData )	
	elseif mechItemId == 0 then
		self:showSelectItemPanel( true )
		self:updateSelectItemPanelView()
	elseif mechItemId > 0 then
		local mechCoreItemId = planeData.mechCoreSlot[ selIdx ]
		if mechCoreItemId ~= nil then
			myBag:addItemById( mechCoreItemId, 1 )
			planeData:unEquipMechCore( mechCoreItemId )
			app:savePlaneData()
		end
		self:updateMainPanelView()
		self:showSystemTips( "卸下核心机甲" )
	else
		assert( false )
	end
end

function UIMechCorePanel:onClickedMainPanelMergeBtn()
	self:showMergePanel( true )
end

function UIMechCorePanel:onClickedMainPanelCloseBtn()
	self:close()
end

function UIMechCorePanel:onClickedMergePanelCloseBtn()
	self:showMergePanel( false )
end

function UIMechCorePanel:onClickedMergePanelQualityBtn1()
	for i = 1, MERGE_SLOT_COUNT do
		self:setItemSlotInfo( "mergeSlot_" .. i, nil )	
	end
	self.itemShowQuality = ENUM_ITEM_QUALITY_BLUE
	self.selecetItemMode = 2
	self:showSelectItemPanel( true )
	self:updateSelectItemPanelView()
end

function UIMechCorePanel:onClickedMergePanelQualityBtn2()
	for i = 1, MERGE_SLOT_COUNT do
		self:setItemSlotInfo( "mergeSlot_" .. i, nil )
	end
	self.itemShowQuality = ENUM_ITEM_QUALITY_PURPLE
	self.selecetItemMode = 2
	self:showSelectItemPanel( true )
	self:updateSelectItemPanelView()
end

function UIMechCorePanel:onClickedMergePanelMergeBtn()
	local myBag = app.bag
	if myBag == nil then
		return
	end
	--确定合成按钮
	for i = 1, MERGE_SLOT_COUNT do
		local mergeSlot = self:getItemSlotInfoByName( "mergeSlot_" .. i  )
		if mergeSlot ~= nil then
			if mergeSlot.ItemInfo == nil then
				return
			end		
		else
			return
		end
	end
	for i = 1, MERGE_SLOT_COUNT do
		local mergeSlot = self:getItemSlotInfoByName( "mergeSlot_" .. i )
		if mergeSlot ~= nil and mergeSlot.ItemInfo ~= nil then
			myBag:removeItem( mergeSlot.ItemInfo )
		end
	end
	for i = 1, MERGE_SLOT_COUNT do
		self:setItemSlotInfo( "mergeSlot_" .. i, nil )
	end
	local newItemId = 75003 + math.random( 0, 5 ) * 3
	local newItem = myBag:createNewItem( newItemId )
	if newItem ~= nil then
		myBag:addItem( newItem )
		self:setItemSlotInfo( "mergeSlot_6", newItem )
	end
end

function UIMechCorePanel:onClickedSelectItemPanelCloseBtn()
	self:showSelectItemPanel( false )
end

function UIMechCorePanel:onClickedSelectItemPanelConfirmBtn()
	local myBag = MyApp.bag
	local planeData = self.planeData
	if myBag == nil or planeData == nil then
		return
	end
	if self.selecetItemMode == 1 then
		for i, v in ipairs( self.tCheckboxGroup ) do
			if v:isButtonSelected() == true then
				local checkSame = planeData:checkHaveSameTypeMechCore( v.mapedItemData.id )
				if checkSame == true then
					self:showSystemTips( "不能安装相同类型的机甲核心!" )
					return
				end
				myBag:removeItem( v.mapedItemData )
				planeData:equipMechCore( v.mapedItemData.id )
				app:savePlaneData()
				break
			end
		end
		self:updateMainPanelView()
	elseif self.selecetItemMode == 2 then
		--检查是否5个
		if #self.tSelectedCheckBox < 5 then
			self:showSystemTips( "必须5个同种品质的核心机甲才能进行合成!" )
			return
		end
		for i, v in ipairs( self.tSelectedCheckBox ) do
			local mapedItemData = v.mapedItemData
			if mapedItemData ~= nil then
				self:setItemSlotInfo( "mergeSlot_" .. i, mapedItemData )
			end
		end
		local mergeBtn = self:seekNodeByPath( "mergePanel/mergeBtn" )
		if mergeBtn ~= nil then
			mergeBtn:setButtonEnabled( true )
		end
	end
	self:showSelectItemPanel( false )
end

function UIMechCorePanel:checkSelectedBox()
	if self.selecetItemMode == 1 then
		for i, v in ipairs( self.tCheckboxGroup ) do
			if v:isButtonSelected() == true then
				return true
			end
		end 
	elseif self.selecetItemMode == 2 then
		return #self.tSelectedCheckBox >= 1
	end
	return false
end

function UIMechCorePanel:onClickedSelectItemPanelCancelBtn()
	self:showSelectItemPanel( false )
end

function UIMechCorePanel:setMechCorePlaneData( planeData )
	self.planeData = planeData
	self:updateMainPanelView()
end

function UIMechCorePanel:updateMainPanelView()
	local myBag = app.bag
	if myBag == nil then
		return
	end
	local mechCoreSlotData = self.planeData:getMechCoreSlotData()
	if mechCoreSlotData == nil then
		return
	end
	for i = 1, MECH_SLOT_COUNT do
		local slotOpBtn = self:seekNodeByPath( string.format("mainPanel/slotOpBtn%s", i)  )
		local slotOpBtnLabel = self:seekNodeByPath( string.format("mainPanel/slotOpBtn%s/Label", i ) )
		if slotOpBtn ~= nil and slotOpBtnLabel ~= nil then
			local mechItemId = mechCoreSlotData[i]
			if mechItemId == 0 then
				self:setItemSlotInfo( "slot_" .. i, nil )
				slotOpBtnLabel:setString( app:GET_STR( "STR_CHOICE" ) )
			elseif mechItemId == -1 then
				self:setItemSlotInfo( "slot_" .. i, nil )
				slotOpBtnLabel:setString( app:GET_STR( "STR_OPEN" ) )
			else
				slotOpBtnLabel:setString( app:GET_STR( "STR_UNEQUIP" ) )
				self:setItemSlotInfo( "slot_" .. i, myBag:createNewItem( mechItemId ) )
			end
		end
	end
end

function UIMechCorePanel:onClickedCheckboxBtn( event )
	local uiManager = self:getUIManager()
	local target = event.target
	if target == nil or uiManager == nil then
		return
	end
	local isSelected = target:isButtonSelected()
	if isSelected == nil then
		return
	end
	for idx, val in ipairs( self.tCheckboxGroup ) do
		val:setButtonSelected( false )
	end
	if self.selecetItemMode == 1 then
		target:setButtonSelected( isSelected )
	elseif self.selecetItemMode == 2 then
		if isSelected == true then
			table.insert( self.tSelectedCheckBox, target )
			for i, v in ipairs( self.tSelectedCheckBox ) do
				v:setButtonSelected( true )
			end
		else
			for i, v in ipairs( self.tSelectedCheckBox ) do
				if v == target then
					v:setButtonSelected( false )
					table.remove( self.tSelectedCheckBox, i )
					break
				end
			end
		end
		if #self.tSelectedCheckBox == 5 then
			for i, v in ipairs( self.tCheckboxGroup ) do
				if v:isButtonSelected() == true then
					v:setButtonSelected( true )
					v:setVisible( true )
				else
					v:setButtonSelected( false )
					v:setVisible( false )
				end
			end
		else
			for i, v in ipairs( self.tCheckboxGroup ) do
				v:setVisible( true )
			end
			for i, v in ipairs( self.tSelectedCheckBox ) do
				v:setButtonSelected( true )
			end
		end
	end
	local confirmBtn = self:seekNodeByPath( "selectItemPanel/confirmBtn" )
	if confirmBtn ~= nil then
		confirmBtn:setButtonEnabled( self:checkSelectedBox() )
	end
end

function UIMechCorePanel:updateSelectItemPanelView()
	local myBag = MyApp.bag
	local uiManager = self:getUIManager()
	local oListView = self:seekNodeByPath( "selectItemPanel/listLayer/itemListView" )
	if oListView ~= nil and myBag ~= nil and uiManager ~= nil then
		oListView:removeAllItems()
		oListView:setBounceable(true)
		local itemWidth = 450
		local itemHeight = 180
		local tAllItems = myBag:getAllItems()
		if tAllItems ~= nil then
			self.tCheckboxGroup = {}
			self.tSelectedCheckBox = {}
			for i, v in pairs( tAllItems ) do
				if v.type == ENUM_ITEM_TYPE_MECH_CORE then
					if self.selecetItemMode == 1 or (v.quality == self.itemShowQuality and self.selecetItemMode == 2) then
						local bagListItemRootNode, width, height = uiManager:loadUIFromFilePath("res/ui/bagListItem.json")
				    	local bagListItem = ccuiloader_seekNodeEx(bagListItemRootNode, "ref_small")
				        if bagListItem then
				            bagListItem:retain()
				            bagListItem:setVisible(true)
				            bagListItem:removeFromParentAndCleanup(false)
				        end 
				        local selectCheckBox = ccuiloader_seekNodeEx(bagListItem, "selectCheckBox")
				        local nameLabel = ccuiloader_seekNodeEx(bagListItem, "nameLabel" )
				        local slotBtn = ccuiloader_seekNodeEx(bagListItem,"slotBtn")
				        local slotIcon = ccuiloader_seekNodeEx(bagListItem, "slotIcon")
				        if nameLabel ~= nil and slotIcon ~= nil and slotBtn ~= nil and selectCheckBox ~= nil then
				        	nameLabel:setString( v.name or "" )
				        	local slotName = string.format( "bagItemSlot_%s", i)
				        	self:registerDynamicItemSlot( slotName, slotBtn, slotIcon, nil, true )
				        	self:setItemSlotInfo( slotName, v )
				        	selectCheckBox.mapedItemData = v
				        	selectCheckBox.Idx = i
					        table.insert( self.tCheckboxGroup, selectCheckBox )
							selectCheckBox:onButtonClicked( function( event )
																self:onClickedCheckboxBtn( event )
															end)
				        end
				        bagListItem:setContentSize( CCSize(itemWidth,itemHeight) )
				        local oNewItem = oListView:newItem( bagListItem );
						if oNewItem ~= nil then
							oNewItem:setContentSize( CCSize(itemWidth,itemHeight) )
							oNewItem:setItemSize( itemWidth, itemHeight );
							oListView:addItem( oNewItem )
						end
					end
				end
			end
		end
		oListView:reload()
	end
	local confirmBtn = self:seekNodeByPath( "selectItemPanel/confirmBtn" )
	if confirmBtn ~= nil then
		confirmBtn:setButtonEnabled( self:checkSelectedBox() )
	end
end

function UIMechCorePanel:onClickMergeSlot( sSlotName )
	local uiManager = self:getUIManager()
	local itemSlotInfo = self:getItemSlotInfoByName( sSlotName )
	if itemSlotInfo == nil or uiManager == nil then
		return
	end
	if itemSlotInfo.ItemInfo == nil then
		self.selecetItemMode = 2
		self:showSelectItemPanel( true )
		self:updateSelectItemPanelView()
	end
end

return UIMechCorePanel
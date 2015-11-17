require("app/model/Factory")
require("bdlib/tools/util")

local UIBaseClass = class("UIBaseClass" )

function UIBaseClass:ctor()
	self.uiRootNode = nil
	self.width = 0
	self.height = 0
	self.uiManager = nil
	self.TouchSwallowEnabled = true
	self.TouchEnabled = true
	self.closeCallback = nil
	self.TouchMode = cc.TOUCH_MODE_ONE_BY_ONE
	self.itemSlotMap = {}
end

function UIBaseClass:registerEventsHandlers( name, eventName, handler )
	assert( self.uiManager ~= nil )
	self.uiManager:registerEventsHandlers( name, eventName, handler, self )
end

function UIBaseClass:setUIRootNode( oUIRoot )
	assert( oUIRoot ~= nil )
	oUIRoot:retain()
	self.uiRootNode = oUIRoot
end

function UIBaseClass:setUIManager( uiManager )
	self.uiManager = uiManager
end

function UIBaseClass:setCloseCallback( closeCallback )
	self.closeCallback = closeCallback
end

function UIBaseClass:getUIManager()
	return self.uiManager
end

function UIBaseClass:getUIRootNode()
	return self.uiRootNode
end

function UIBaseClass:seekNodeByPath( childNodePath )
	assert( self.uiRootNode ~= nil )
	if childNodePath == nil or childNodePath == "" then
		return
	end
	return ccuiloader_seekNodeEx( self.uiRootNode, childNodePath )
end

function UIBaseClass:close()
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		uiManager:closeUI( self.uiName )
		if self.closeCallback ~= nil then
			self:closeCallback()
		end
	end
end

function UIBaseClass:showSystemTips( sTips )
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		uiManager:showSystemTips( sTips )
	end
end

function UIBaseClass:showSystemTipsEx( sStrId )
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		uiManager:showSystemTips( app:GET_STR( sStrId ) )
	end
end

function UIBaseClass:registerItemSlot( sItemSlotName, sItemBtn, sItemIconName, sNumLabelName,showPanel, clickedHandler )
	assert(self.uiManager)
	self.itemSlotMap[ sItemSlotName ] = { BtnName = sItemBtn, SpriteName = sItemIconName, NumLabelName = sNumLabelName }
	self.uiManager:registerItemSlotClickedHandler( sItemSlotName, showPanel, clickedHandler, self )
	self:updateSlotView( sItemSlotName )
end

function UIBaseClass:registerDynamicItemSlot( sItemSlotName, slotBtn, slotIcon, slotNumLabel, showPanel, clickedHandler )
	assert(self.uiManager)
	self.itemSlotMap[ sItemSlotName ] = { SlotBtn = slotBtn, SlotSprite = slotIcon, SlotNumLabel = slotNumLabel }
	self.uiManager:registerDynamicItemSlotClickedHandler( sItemSlotName, showPanel, clickedHandler, self )
	self:updateSlotView( sItemSlotName )
end

function UIBaseClass:getItemSlotInfoByName( sItemSlotName )
	return self.itemSlotMap[ sItemSlotName ]
end

function UIBaseClass:setItemSlotInfo( sItemSlotName, itemInfo )
	if self.itemSlotMap[ sItemSlotName ] ~= nil then
		self.itemSlotMap[ sItemSlotName ].ItemInfo = itemInfo
	end
	self:updateSlotView( sItemSlotName )
end

function UIBaseClass:setItemSlotVisible( sItemSlotName, visible )
	local tItemSlotInfo = self.itemSlotMap[ sItemSlotName ]
	if tItemSlotInfo ~= nil then
		local slotBtn = nil
		local slotSprite = nil
		local itemNumLabel = nil
		if tItemSlotInfo.BtnName ~= nil then
			slotBtn = self:seekNodeByPath( tItemSlotInfo.BtnName )
			slotSprite = self:seekNodeByPath( tItemSlotInfo.SpriteName )
			itemNumLabel = self:seekNodeByPath( tItemSlotInfo.NumLabelName )
		else
			slotBtn = tItemSlotInfo.SlotBtn
			slotSprite = tItemSlotInfo.SlotSprite
			itemNumLabel = tItemSlotInfo.SlotNumLabel
		end
		if slotBtn ~= nil then
			slotBtn:setVisible( visible )
		end
		if slotSprite ~= nil then
			slotSprite:setVisible( visible )
		end
		if itemNumLabel ~= nil then
			itemNumLabel:setVisible( visible )
		end
	end
end

function UIBaseClass:updateSlotView( sItemSlotName )
	local tItemSlotInfo = self.itemSlotMap[ sItemSlotName ]
	if tItemSlotInfo ~= nil then
		local itemIconSprite = nil
		local itemNumLabel = nil
		if tItemSlotInfo.SpriteName ~= nil then
			itemIconSprite = self:seekNodeByPath( tItemSlotInfo.SpriteName )
			itemNumLabel = self:seekNodeByPath( tItemSlotInfo.NumLabelName )
		else
			itemIconSprite = tItemSlotInfo.SlotSprite
			itemNumLabel = tItemSlotInfo.SlotNumLabel
		end	
		local itemInfo = tItemSlotInfo.ItemInfo
		if itemInfo ~= nil then
			if itemIconSprite ~= nil then
				itemIconSprite:setVisible( true )
				self.uiManager:replaceSpriteIcon( itemIconSprite, itemInfo.plistFile, itemInfo.iconName, false )
			end
			if itemNumLabel ~= nil then
				itemNumLabel:setVisible( true )
				itemNumLabel:setString( itemInfo.count )
			end
		else
			if itemIconSprite ~= nil then
				itemIconSprite:setVisible( false )
			end
			if itemNumLabel ~= nil then
				itemNumLabel:setVisible( false )
			end
		end
	end
end

return UIBaseClass;
require("app/model/Factory")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

local UIItemInfoPanel = class("UIItemInfoPanel", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UIItemInfoPanel:initConfig()
	self.jsonFilePath = "res/ui/itemInfoPanel.json"
end

function UIItemInfoPanel:onInitEventsHandler()
	self:registerEventsHandlers( "ref/closeBtn", "OnClicked", self.onClickedCloseBtn )
	self:registerItemSlot( "itemSlot", "ref/content/itemBtn", "ref/content/itemIcon", "", false )
end

function UIItemInfoPanel:initData()
	self.itemInfo = nil
end

function UIItemInfoPanel:onShowUI()
end

function UIItemInfoPanel:onCloseUI()
end
---------------------------------------------------------------------------------------------------------
function UIItemInfoPanel:onClickedCloseBtn()
	self:close()
end

function UIItemInfoPanel:setItemInfo( itemInfo )
	self.itemInfo = itemInfo
	self:updateView()
end

function UIItemInfoPanel:updateView()
	if self.itemInfo ~= nil then
		self:setItemSlotInfo( "itemSlot", self.itemInfo )
		local nameLabel = self:seekNodeByPath( "ref/nameLabel" )
		local descLabel = self:seekNodeByPath( "ref/descLabel" )
		if nameLabel ~= nil and descLabel ~= nil then
			nameLabel:setString( self.itemInfo.name or "" )
			descLabel:setString( self.itemInfo.desc or "" )
			descLabel:setDimensions( CCSize( 440, 250 ) )
			descLabel:setContentSize( CCSize( 440, 250 ) )
		end
	end
end

return UIItemInfoPanel
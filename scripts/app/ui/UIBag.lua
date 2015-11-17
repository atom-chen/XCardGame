require("app/model/Factory")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

local UIBag = class("UIBag", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UIBag:initConfig()
	self.jsonFilePath = "res/ui/bag.json"
end

function UIBag:onInitEventsHandler()
	self:registerEventsHandlers( "ref/closeBtn", 	  "OnClicked", self.onClickedCloseBtn )		--【关闭】
	self:registerEventsHandlers( "ref/backBtn", 	  "OnClicked", self.onClickedBackBtn )		--【返回按钮】
end

function UIBag:initData()
end

function UIBag:onShowUI()
	local myBag = MyApp.bag
	local uiManager = self:getUIManager()
	local oListView = self:seekNodeByPath( "ref/itemListLayer/itemListView" )
	if oListView ~= nil and myBag ~= nil and uiManager ~= nil then
		oListView:removeAllItems()
		oListView:setBounceable(true)
		local itemWidth = 620
		local itemHeight = 180
		local tAllItems = myBag:getAllItems()
		if tAllItems ~= nil then
			for i, v in pairs( tAllItems ) do
				local bagListItemRootNode, width, height = uiManager:loadUIFromFilePath("res/ui/bagListItem.json")
		    	local bagListItem = ccuiloader_seekNodeEx(bagListItemRootNode, "ref")
		        if bagListItem then
		            bagListItem:retain()
		            bagListItem:setVisible(true)
		            bagListItem:removeFromParentAndCleanup(false)
		        end 
		        local button = ccuiloader_seekNodeEx(bagListItem, "opBtn")
		        local label = ccuiloader_seekNodeEx(bagListItem, "nameLabel" )
		        local descLabel = ccuiloader_seekNodeEx(bagListItem, "descLabel")
		        local stackNumLabel = ccuiloader_seekNodeEx(bagListItem, "stackNumLabel")
		        local slotBtn = ccuiloader_seekNodeEx(bagListItem,"slotBtn")
		        local iconImg = ccuiloader_seekNodeEx(bagListItem, "iconImg")
		        if button ~= nil and label ~= nil and descLabel ~= nil and stackNumLabel ~= nil and iconImg ~= nil and slotBtn ~= nil then
		        	label:setString( v.name or "" );
		        	descLabel:setString( v.desc or "" )
		        	descLabel:setDimensions( CCSize( 360, 140 ) )
		        	descLabel:setContentSize( CCSize(360, 140) )
		        	local slotName = string.format( "slot_%s", i)
		        	self:registerDynamicItemSlot( slotName, slotBtn, iconImg, nil, true )
		        	self:setItemSlotInfo( slotName, v )
		        	if v.maxStackCount <= 1 then
		        		stackNumLabel:setString( "" )
		        	else
		        		stackNumLabel:setString( string.format( "%s/%s", v.count, v.maxStackCount) )
		        	end
		        	button.Index = i
		        	button:onButtonClicked( function(event)

		        							end
		        		)
		        end
		        bagListItem:setContentSize( CCSize(itemWidth,itemHeight) )
		        local oNewItem = oListView:newItem( bagListItem );
				if oNewItem ~= nil then
					oNewItem:setContentSize( CCSize(itemWidth,itemHeight) )
					oNewItem:setItemSize( itemWidth, itemHeight );
					oListView:addItem( oNewItem );
				end
			end
		end
		oListView:reload()
	end
end

function UIBag:onCloseUI()
	local listView = self:seekNodeByPath( "ref/itemListLayer/itemListView" )
	if listView ~= nil then
		listView:removeAllItems()
	end
end
---------------------------------------------------------------------------------------------------------
function UIBag:onClickedCloseBtn()
	self:close()
end

function UIBag:onClickedBackBtn()
	self:close()
end

return UIBag
require("app/model/Factory")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

--[[
	ENUM_TECH_TYPE_FULL_POW_TIME	
	ENUM_TECH_TYPE_SHEILD_TIME		
	ENUM_TECH_TYPE_ADD_GOLD			
	ENUM_TECH_TYPE_ADD_EXP			
	ENUM_TECH_TYPE_BOSS_WEEK		
	ENUM_TECH_TYPE_ENH_POW		
]]--


local UITechPanel = class("UITechPanel", UIBaseClass )
UITechPanel.TechTypes = 
{
	{"fullPowTime",	"STR_FULL_POW_TIME"},
	{"sheildTime",	"STR_SHEILD_TIME"},
	{"goldAdd",		"STR_ADD_GOLD"},
	{"expAdd",		"STR_ADD_EXP"},
	{"bossWeek",	"STR_BOSS_WEEK"},
	{"enhPow",		"STR_ENH_POW"},
}
---------------------------------------------------------------------------------------------------------
function UITechPanel:initConfig()
	self.jsonFilePath = "res/ui/techPanel.json"
	self.TouchSwallowEnabled = false
	self.TouchEnabled = true
end

function UITechPanel:onInitEventsHandler()
	self:registerEventsHandlers( "ref/closeBtn", 		   "OnClicked", self.onClickedCloseBtn )
end

function UITechPanel:initData()
	self.initUI = false
	self.techItemList = {}
end

function UITechPanel:onShowUI()
	if self.initUI == true then
		return
	end
	local techMgr = app.techMgr
	local uiManager = self:getUIManager()
	local oListView = self:seekNodeByPath( "ref/techListLayer/techListView" )
	if oListView ~= nil and uiManager ~= nil and techMgr ~= nil then
		oListView:removeAllItems()
		self.techItemList = {}
		oListView:setBounceable(true)
		oListView:setTouchEnabled(false)
		oListView.onTouch_ = function() end
		local itemWidth = 630
		local itemHeight = 100
		for techType,v in ipairs( UITechPanel.TechTypes ) do
			local techListItemRootNode, width, height = uiManager:loadUIFromFilePath("res/ui/techItem.json")
	    	local techListItem = ccuiloader_seekNodeEx(techListItemRootNode, "ref")
	        if techListItem then
	            techListItem:retain()
	            techListItem:setVisible(true)
	            techListItem:removeFromParentAndCleanup(false)
	        end
	        table.insert( self.techItemList, techListItem )
	        local button = ccuiloader_seekNodeEx( techListItem, "lvUpBtn")
	        if button ~= nil then
	        	button:onButtonClicked( function(event)
	        								self:onClickedLvUpBtn( techType )
		        							end
		        					  )
	        end
	        techListItem:setContentSize( CCSize(itemWidth,itemHeight) )
	        local oNewItem = oListView:newItem( techListItem )
			if oNewItem ~= nil then
				oNewItem:setTouchEnabled(false)
				oNewItem:setContentSize( CCSize(itemWidth,itemHeight) )
				oNewItem:setItemSize( itemWidth, itemHeight )
				oListView:addItem( oNewItem )
			end
		end
		oListView:reload()
		self:updateView()
	end
end

function UITechPanel:onCloseUI()
end
---------------------------------------------------------------------------------------------------------
function UITechPanel:onClickedCloseBtn()
	self:close()
end

function UITechPanel:onClickedLvUpBtn( techType )
	local techMgr = app.techMgr
	if techMgr == nil then
		return
	end
	if techMgr:isTechMaxLv( techType ) == true then
		return
	end
	local curTechLevel, addAttriVal, lvNeedGold = techMgr:getTechInfo( techType )
	local nextLvLevel, nextLvAddAttriVal, nextLvNeedGold = techMgr:getTechLvInfo( techType, curTechLevel + 1 )
	if addAttriVal ~= nil and nextLvAddAttriVal ~= nil and lvNeedGold ~= nil and nextLvNeedGold ~= nil and curTechLevel ~= nil then
		local gold = app:countOfGold()
		if gold ~= nil then
			if gold < lvNeedGold then
				self:showSystemTipsEx( "TIP_NOT_ENOUGH_GOLD" )
				return
			else
				local modifyOk = app:modifyGold( -lvNeedGold )
				if modifyOk == true then
					techMgr:doTechLvUp( techType )
					self:updateView()
				end
			end
		end
	end
	app:saveTechData()
end

function UITechPanel:updateView()
	local techMgr = app.techMgr
	if techMgr == nil then
		return
	end
	for techType, techListItem in ipairs( self.techItemList ) do
		local nameLabel = ccuiloader_seekNodeEx(techListItem, "nameLabel")
	    local button = ccuiloader_seekNodeEx(techListItem, "lvUpBtn" )
	    local costLabel = ccuiloader_seekNodeEx(techListItem, "lvUpBtn/costLabel" )
	    local maxLabel = ccuiloader_seekNodeEx(techListItem, "lvUpBtn/maxLabel")
	    local lvUpLabel = ccuiloader_seekNodeEx(techListItem, "lvUpBtn/lvUpLabel")
	    local costIconImg = ccuiloader_seekNodeEx(techListItem, "lvUpBtn/costIconImg")
	    local attriInfoLabel = ccuiloader_seekNodeEx(techListItem, "attriInfoLabel" )
	    local curLevelLabel = ccuiloader_seekNodeEx(techListItem, "curLevelLabel")
	    local progressBar = ccuiloader_seekNodeEx(techListItem, "progressBar")
	    local nextLevelInfoLabel = ccuiloader_seekNodeEx(techListItem, "nextLevelInfoLabel")
	    if nameLabel ~= nil and costLabel ~= nil and button ~= nil and attriInfoLabel ~= nil and curLevelLabel ~= nil and progressBar ~= nil and 
	    	nextLevelInfoLabel ~= nil and maxLabel ~= nil and lvUpLabel ~= nil and costIconImg ~= nil then
	    	nameLabel:setString( app:GET_STR( self.TechTypes[techType][2] ) )
	    	if techMgr:isTechMaxLv( techType ) == true then
	    		local curTechLevel, addAttriVal, lvNeedGold = techMgr:getTechInfo( techType )
	    		local maxLvLevel, maxLvAddAttriVal, maxLvNeedGold = techMgr:getTechLvInfo( techType, FUNC_CONST_MAX_TECH_LEVEL )
	    		if addAttriVal ~= nil and lvNeedGold ~= nil and curTechLevel ~= nil and
	        	   maxLvLevel ~= nil and maxLvAddAttriVal ~= nil and maxLvNeedGold ~= nil then
	        	   local attriStr = techMgr:getTechAtrriShowStr(techType,addAttriVal)
	        	   local maxAttriStr = techMgr:getTechAtrriShowStr(techType,maxLvAddAttriVal)
	        	   attriInfoLabel:setString( string.format("%s/%s", attriStr, maxAttriStr ) )
	        		curLevelLabel:setString( string.format("Lv.%s/%s",curTechLevel, FUNC_CONST_MAX_TECH_LEVEL) )
	        		progressBar:setPercent( 100 * (curTechLevel / FUNC_CONST_MAX_TECH_LEVEL) )
	        		nextLevelInfoLabel:setString( "" )
	        	end
	    		costLabel:setVisible( false )
	    		lvUpLabel:setVisible( false )
	    		costIconImg:setVisible( false )
	    		maxLabel:setVisible( true )
	    		button:setButtonEnabled( false )
	    	else
	        	local curTechLevel, addAttriVal, lvNeedGold = techMgr:getTechInfo( techType )
	        	local nextLvLevel, nextLvAddAttriVal, nextLvNeedGold = techMgr:getTechLvInfo( techType, curTechLevel + 1 )
	        	local maxLvLevel, maxLvAddAttriVal, maxLvNeedGold = techMgr:getTechLvInfo( techType, FUNC_CONST_MAX_TECH_LEVEL )
	        	if addAttriVal ~= nil and nextLvAddAttriVal ~= nil and lvNeedGold ~= nil and nextLvNeedGold ~= nil and curTechLevel ~= nil and
	        	   maxLvLevel ~= nil and maxLvAddAttriVal ~= nil and maxLvNeedGold ~= nil then
	        		local attriStr = techMgr:getTechAtrriShowStr(techType,addAttriVal)
	        		local nextAttriStr = techMgr:getTechAtrriShowStr(techType,nextLvAddAttriVal)
	        		local maxAttriStr = techMgr:getTechAtrriShowStr(techType,maxLvAddAttriVal)
	        		attriInfoLabel:setString( string.format("%s/%s", attriStr, maxAttriStr ) )
	        		curLevelLabel:setString( string.format("Lv.%s/%s",curTechLevel, FUNC_CONST_MAX_TECH_LEVEL) )
	        		progressBar:setPercent( 100 * (curTechLevel / FUNC_CONST_MAX_TECH_LEVEL) )
	        		nextLevelInfoLabel:setString( nextAttriStr )
	        		costLabel:setString( lvNeedGold )
	        	end
	        	costLabel:setVisible( true )
	    		lvUpLabel:setVisible( true )
	    		costIconImg:setVisible( true )
	    		maxLabel:setVisible( false )	
	    		button:setButtonEnabled( true )
	        end
	    end
    end
end

return UITechPanel
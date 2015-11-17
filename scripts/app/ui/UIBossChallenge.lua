require("app/model/Factory")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

local UIBossChallenge = class("UIBossChallenge", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UIBossChallenge:initConfig()
	self.jsonFilePath = "res/ui/bossChallenge.json"
end

function UIBossChallenge:onInitEventsHandler()
	self:registerEventsHandlers( "ref/titlePanel/closeBtn", 	"OnClicked", self.onClickedcloseBtn )
	self:registerEventsHandlers( "ref/left", 		   			"OnClicked", self.onClickedleftBtn )
	self:registerEventsHandlers( "ref/right", 		   			"OnClicked", self.onClickedrightBtn )
end

function UIBossChallenge:initData()
end

function UIBossChallenge:onShowUI()
	local listView = self:seekNodeByPath( "ref/listPanel/bossModeListView" )
	local difficulty = self:seekNodeByPath("ref/difficulty")
	difficulty:setString(app:GET_STR("STR_EASY"))
	local uiManager = self:getUIManager()
	if listView == nil or uiManager == nil then
		return
	end
	listView:removeAllItems()
	listView:setBounceable(true)
	local tModule = CfgData.getCfgTable(CFG_BOSSCHALLENGE)
	for i,v in ipairs(tModule)  do
		local bossModeListItemRootNode, width, height = uiManager:loadUIFromFilePath("res/ui/bossListItem.json")
		local bossModeListItem = ccuiloader_seekNodeEx(bossModeListItemRootNode, "ref")
	    if bossModeListItem then
	        bossModeListItem:retain()
	        bossModeListItem:setVisible(true)
	        bossModeListItem:removeFromParentAndCleanup(false)
	    end
	    local challengeButton = ccuiloader_seekNodeEx(bossModeListItem, "challengeBtn" )
	    local bg = ccuiloader_seekNodeEx(bossModeListItem, "bg")
	    uiManager:replaceSpriteIcon( bg, v.plistFile, v.iconName)
	    local conditionLabel = ccuiloader_seekNodeEx(bossModeListItem, "condition")
	    conditionLabel:setString(v.condition)
	   	local scoreLabel = ccuiloader_seekNodeEx(bossModeListItem, "score")
	   	scoreLabel:setString(v.score)
        if challengeButton ~= nil then
        	challengeButton:onButtonClicked( 
        		function()
        			--app:playMissionByIndex( 104 )
        			print("enter")
        		end)
        end
	    bossModeListItem:setContentSize( CCSize(600,250) )
        local oNewItem = listView:newItem( bossModeListItem )
		if oNewItem ~= nil then
			oNewItem:setContentSize( CCSize(600,250) )
			oNewItem:addContent( content )
			oNewItem:setItemSize( 600, 250 )
			listView:addItem( oNewItem )
		end
	end
	listView:reload()
end
---------------------------------------------------------------------------------------------------------
function UIBossChallenge:onClickedcloseBtn()
	self:close()
end

function UIBossChallenge:onClickedleftBtn()
	app.bosschallenge:decDifficult()
	local difficulty = self:seekNodeByPath("ref/difficulty")
	difficulty:setString(app.bosschallenge:getDifficult())
end

function UIBossChallenge:onClickedrightBtn()
	app.bosschallenge:addDifficult()
	local difficulty = self:seekNodeByPath("ref/difficulty")
	difficulty:setString(app.bosschallenge:getDifficult())
end

return UIBossChallenge
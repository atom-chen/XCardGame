require("app/model/Factory")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

local UIChoiceMission = class("UIChoiceMission", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UIChoiceMission:initConfig()
	self.jsonFilePath = "res/ui/choiceMission.json"
end

function UIChoiceMission:onInitEventsHandler()
	self:registerEventsHandlers( "ref/backBtn", "OnClicked", self.onClickedBackBtn )
end

function UIChoiceMission:initData()
end

function UIChoiceMission:onShowUI()
	local missionView = CfgData.getCfgTable( CFG_MISSION_VIEW )
	local scroll = self:seekNodeByPath( "ref/missScroll" )
    local contentPanel = cc.uiloader:seekNodeByName(scroll, "contentPanel")
	if contentPanel ~= nil then
		for i, v in ipairs( missionView ) do
			local missStatuData = app:getMissStatu( v.id )
			local missPointItem, width, height = cc.uiloader:load("res/ui/missPointItem.json")
			local nodeName = "normalPoint"
			if v.bossViewId ~= nil and v.bossViewId ~= 0 then
				nodeName = "bossPoint"
			end
	    	local missionPointItem = ccuiloader_seekNodeEx(missPointItem, nodeName )
	        if missionPointItem ~= nil then
	            missionPointItem:retain()
	            missionPointItem:setVisible(true)
	            missionPointItem:removeFromParentAndCleanup(false)
	            contentPanel:addChild( missionPointItem )
	            missionPointItem:setPosition( CCPoint( v.pos.x, v.pos.y ) )
	            local missBtn = ccuiloader_seekNodeEx(missionPointItem,"missBtn")
	            local numLabel = ccuiloader_seekNodeEx(missionPointItem, "numLabel")
	            local frameBg = ccuiloader_seekNodeEx(missionPointItem,"frameBg")
	            local starBg = ccuiloader_seekNodeEx(missionPointItem,"starBg")
	            local starProgressBar = ccuiloader_seekNodeEx(missionPointItem, "starProgressBar")
	            if missBtn ~= nil and numLabel ~= nil and frameBg ~= nil and starBg ~= nil and starProgressBar ~= nil then
	            	missBtn:setGrayStateUseNormalSprite( cc.ui.UIPushButton.DISABLED )
	            	if missStatuData == nil then
	            		missBtn:setButtonEnabled( false )
	            		frameBg:setVisible( false )
	            		starBg:setVisible( false )
	            		starProgressBar:setVisible( false )
	            	else
	            		missBtn:setButtonEnabled( true )
	            		frameBg:setVisible( true )
	            		starBg:setVisible( true )
	            		starProgressBar:setVisible( true )
	            	end
	            	numLabel:setString( i )
	            	missBtn:onButtonClicked(function(event)
                        self:onTouchMission(i)
                    end)
	            end
	        end
		end
	end
end

function UIChoiceMission:onCloseUI()
	
end
---------------------------------------------------------------------------------------------------------
function UIChoiceMission:onTouchMission( idx )
    self:showDescriptUI(idx)
end

function UIChoiceMission:showDescriptUI( idx )
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		local function callback()
			local uiMissionDescriptPanel = uiManager:getUIByName( "UIMissionDescriptPanel" )
			if uiMissionDescriptPanel ~= nil then
				local missionViewCfg = CfgData.getCfg(CFG_MISSION_VIEW, idx )
				if missionViewCfg ~= nil then
					uiMissionDescriptPanel:setShowMission( missionViewCfg )
				end
			end
		end
		uiManager:showUI( "UIMissionDescriptPanel", true, callback )
	end
end

function UIChoiceMission:onClickedBackBtn()
	app:enterSelectPlane()
end

return UIChoiceMission
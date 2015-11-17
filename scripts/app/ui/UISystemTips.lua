require("app/model/Factory")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

local UISystemTips = class("UISystemTips", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UISystemTips:initConfig()
	self.jsonFilePath = "res/ui/systemTip.json"
	self.TouchSwallowEnabled = false
	self.TouchEnabled = false
end

function UISystemTips:onInitEventsHandler()
end

function UISystemTips:initData()
	self.sTips = ""
end

function UISystemTips:onShowUI()
	local uiRootNode = self:getUIRootNode()
	if uiRootNode ~= nil then
		uiRootNode:schedule( function()
								self:close()
							 end, 1.2 )
	end
end

function UISystemTips:onCloseUI()
end
---------------------------------------------------------------------------------------------------------
function UISystemTips:setTips( sTips )
	self.sTips = sTips
	local tipsLabel = self:seekNodeByPath( "ref/tipsLabel" )
	if tipsLabel ~= nil then
		tipsLabel:setString( sTips or "" )
	end
end

return UISystemTips
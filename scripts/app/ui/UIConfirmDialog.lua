require("app/model/Factory")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

local UIConfirmDialog = class("UIConfirmDialog", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UIConfirmDialog:initConfig()
	self.jsonFilePath = "res/ui/confirmDialog.json"
end

function UIConfirmDialog:onInitEventsHandler()
	self:registerEventsHandlers( "ref/closeBtn", "OnClicked", self.onClickedCloseBtn )
	self:registerEventsHandlers( "ref/btn1", 	 "OnClicked", self.onClickedBtn1 )
	self:registerEventsHandlers( "ref/btn2", 	 "OnClicked", self.onClickedBtn2 )
end

function UIConfirmDialog:initData()
	self:resetData()
end

function UIConfirmDialog:onShowUI()
end

function UIConfirmDialog:onCloseUI()
	self:resetData()
end

function UIConfirmDialog:resetData()
	self.Type = 0
	self.Title = ""
	self.Desc = ""
	self.Btn1Label = ""
	self.Btn2Label = ""
	self.Btn1Callback = nil
	self.Btn1CallbackData = nil 
	self.Btn2Callback = nil
	self.Btn2CallbackData = nil
	self.CloseCallback = nil
end
---------------------------------------------------------------------------------------------------------
function UIConfirmDialog:setDialogData( tDialogData )
	self.Type = tDialogData.Type
	self.Title = tDialogData.Title
	self.Desc = tDialogData.Desc
	self.Btn1Label = tDialogData.Btn1Label
	self.Btn2Label = tDialogData.Btn2Label
	self.Btn1Callback = tDialogData.Btn1Callback
	self.Btn1CallbackData = tDialogData.Btn1CallbackData
	self.Btn2Callback = tDialogData.Btn2Callback
	self.Btn2CallbackData = tDialogData.Btn2CallbackData
	self.CloseCallback = tDialogData.CloseCallback
	local titleLabel = self:seekNodeByPath( "ref/titleLabel" )
	local descLabel = self:seekNodeByPath( "ref/descLabel" )
	local btn1Label = self:seekNodeByPath( "ref/btn1/btn1Label" )
	local btn2Label = self:seekNodeByPath( "ref/btn2/btn2Label" )
	if titleLabel == nil or descLabel == nil or btn1Label == nil or btn2Label == nil then
		return
	end
	titleLabel:setString( self.Title or "" )
	descLabel:setString( self.Desc or "" )
	descLabel:setDimensions( CCSize( 600, 340 ) )
	descLabel:setContentSize( CCSize(600, 340) )
	btn1Label:setString( self.Btn1Label or "" )
	btn2Label:setString( self.Btn2Label or "" )
end

function UIConfirmDialog:onClickedCloseBtn()
	if self.CloseCallback ~= nil then
		self.CloseCallback()
	end
	self:close()
end

function UIConfirmDialog:onClickedBtn1()
	if self.Btn1Callback ~= nil then
		self.Btn1Callback( self.Btn1CallbackData )
	end
	self:close()
end

function UIConfirmDialog:onClickedBtn2()
	if self.Btn2Callback ~= nil then
		self.Btn2Callback( self.Btn2CallbackData )
	end
	self:close()
end

return UIConfirmDialog
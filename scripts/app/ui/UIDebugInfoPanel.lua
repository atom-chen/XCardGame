require("app/model/Factory")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

local UIDebugInfoPanel = class("UIDebugInfoPanel", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UIDebugInfoPanel:initConfig()
	self.jsonFilePath = "res/ui/debugInfoPanel.json"
	self.TouchSwallowEnabled = false
	self.TouchEnabled = false
end

function UIDebugInfoPanel:onInitEventsHandler()
	self:registerEventsHandlers( "panelSwitchBtn", 		   "OnClicked", self.onClickedPanelSwitchBtn )		
	self:registerEventsHandlers( "ref/addGoldBtn1", 	   "OnClicked", self.onClickedAddGoldBtn1 )
	self:registerEventsHandlers( "ref/addDiamondBtn1", 	   "OnClicked", self.onClickedAddDiamondBtn1 )
	self:registerEventsHandlers( "ref/addExpBtn1", 	   		"OnClicked", self.onClickedAddExpBtn1 )
	self:registerEventsHandlers( "ref/addAllBtn1", 	   		"OnClicked", self.onClickedAddAllBtn1 )
	self:registerEventsHandlers( "ref/addGoldBtn2", 	   "OnClicked", self.onClickedAddGoldBtn2 )
	self:registerEventsHandlers( "ref/addDiamondBtn2", 	   "OnClicked", self.onClickedAddDiamondBtn2 )
	self:registerEventsHandlers( "ref/addExpBtn2", 	   		"OnClicked", self.onClickedAddExpBtn2 )
	self:registerEventsHandlers( "ref/addAllBtn2", 	   		"OnClicked", self.onClickedAddAllBtn2 )
	self:registerEventsHandlers( "ref/addItemBtn", 		   "OnClicked", self.onClickedAddItemBtn )
	self:registerEventsHandlers( "ref/goWinBtn", 			"OnClicked",self.onClickedGoWinBtn )
	self:registerEventsHandlers( "ref/gunViewBtn", 			"OnClicked",self.onClickedGunViewBtn )
	--self:registerEventsHandlers( "ref/confirmBtn", 		   "OnClicked", self.onClickedConfirmBtn )
end

function UIDebugInfoPanel:initData()
end

function UIDebugInfoPanel:onShowUI()
	local refPanel = self:seekNodeByPath( "ref" )
	if refPanel ~= nil then
		refPanel:setVisible( false )
	end
end

function UIDebugInfoPanel:onCloseUI()
end
---------------------------------------------------------------------------------------------------------
function UIDebugInfoPanel:onClickedPanelSwitchBtn()
	local refPanel = self:seekNodeByPath( "ref" )
	if refPanel ~= nil then
		refPanel:setVisible( not refPanel:isVisible() )
	end
end

function UIDebugInfoPanel:onClickedConfirmBtn()
	local cmdTextField = self:seekNodeByPath( "ref/cmdTextField" )
	if cmdTextField ~= nil then
		local inputCommand = cmdTextField:getText()
		cmdTextField:setText( "" )
		if inputCommand == nil or inputCommand == "" then
			return
		end
		local head = string.sub( inputCommand, 1, 1 )
		if head ~= '!' then
			MyApp.uiManager:showSystemTips( "input string is not gm command" )
			return
		end
		inputCommand = string.sub( inputCommand, 2, -1 )
		local tCommand = string.split(inputCommand, ' ' )
		if #tCommand == 0 then
			return
		end
		if tCommand[1] == "additem" then
			local bag = MyApp.bag
			if bag ~= nil then
				bag:addItemById( tonumber(tCommand[2]), tonumber(tCommand[3]) ) 
			end
		end
		app:saveItemsData()
		self:showSystemTips( "添加物品" )
	end
end

function UIDebugInfoPanel:onClickedAddItemBtn()
	local bag = MyApp.bag
	if bag ~= nil then
		local bagItemsCfg = CfgData.getCfgTable(CFG_BAG_ITEM )
  		if bagItemsCfg ~= nil then
			for i, v in pairs( bagItemsCfg ) do
				bag:addItemById( tonumber(v.id), 1 )
			end
			app:saveItemsData()
			self:showSystemTips( "添加物品" )
		end
	end
end

function UIDebugInfoPanel:onClickedGoWinBtn()
	local sceneManager = app.sceneManager
	if sceneManager == nil then
		return
	end
	local curScene = sceneManager:getCurScene()
	if curScene == nil or curScene.name ~= "NewSceneGame" then
		return
	end
	curScene:pauseGame( true )
	curScene:showMissionPassed()
end

function UIDebugInfoPanel:onClickedGunViewBtn()
	local sceneManager = app.sceneManager
	if sceneManager == nil then
		return
	end
	--跳转到枪组查看界面
	sceneManager:enterScene("NewSceneGunView", nil, nil, 0.6, display.COLOR_BLACK)
end

function UIDebugInfoPanel:onClickedAddGoldBtn1()
	self:addProp( 10000, 0, 0 )
end

function UIDebugInfoPanel:onClickedAddGoldBtn2()
	self:addProp( 100000, 0, 0 )
end


function UIDebugInfoPanel:onClickedAddDiamondBtn1()
	self:addProp( 0, 10000, 0 )
end

function UIDebugInfoPanel:onClickedAddDiamondBtn2()
	self:addProp( 0, 100000, 0 )
end


function UIDebugInfoPanel:onClickedAddExpBtn1()
	self:addProp( 0, 0, 10000 )
end

function UIDebugInfoPanel:onClickedAddExpBtn2()
	self:addProp( 0, 0, 100000 )
end

function UIDebugInfoPanel:onClickedAddExpBtn2()
	self:addProp( 0, 0, 100000 )
end

function UIDebugInfoPanel:onClickedAddAllBtn1()
	self:addProp( 10000, 10000, 10000 )
end

function UIDebugInfoPanel:onClickedAddAllBtn2()
	self:addProp( 100000, 100000, 100000 )
end

function UIDebugInfoPanel:addProp( gold, diamond, exp )
	if exp > 0 then
		app:modifyProps( PROPS_TYPE_EXP, exp )
	end
	if gold > 0 then
		app:modifyProps( PROPS_TYPE_GOLD, gold )
	end
	if diamond > 0 then
		app:modifyProps( PROPS_TYPE_DIAMAND, diamond )
	end
	self:showSystemTips( string.format( "经验=%s,金币=%s,钻石=%s", app:getPropCount(PROPS_TYPE_EXP), app:getPropCount(PROPS_TYPE_GOLD), app:getPropCount(PROPS_TYPE_DIAMAND) ) )
end

return UIDebugInfoPanel
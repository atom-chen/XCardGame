require("app/model/Factory")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

local UIGunView = class("UIGunView", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UIGunView:initConfig()
	self.jsonFilePath = "res/ui/gunView.json"
end

function UIGunView:onInitEventsHandler()
	self:registerEventsHandlers( "ref/backBtn", "OnClicked", self.onClickedBackBtn )
	self:registerEventsHandlers( "ref/enemyConfirmBtn", "OnClicked", self.onClickedEnemyConfirmBtnBtn )
	self:registerEventsHandlers( "ref/gunConfirmBtn", "OnClicked", self.onClickedGunConfirmBtn )
end

function UIGunView:initData()
end

function UIGunView:onShowUI()
end

function UIGunView:onCloseUI()
end
---------------------------------------------------------------------------------------------------------
function UIGunView:onClickedBackBtn()
	app:enterSelectPlane()
end

function UIGunView:onClickedEnemyConfirmBtnBtn()
	local sceneManager = app.sceneManager
	local enemyIdTextField = self:seekNodeByPath( "ref/enemyIdTextField" )
	if enemyIdTextField ~= nil and sceneManager ~= nil then
		local curScene = sceneManager:getCurScene()
		local enemyId = enemyIdTextField:getText()
		if enemyId ~= nil and curScene ~= nil and tonumber(enemyId) ~= nil then
			curScene:changeEnemy( tonumber(enemyId) )
		end
	end
end

function UIGunView:onClickedGunConfirmBtn()
	local sceneManager = app.sceneManager
	local gunIdTextField = self:seekNodeByPath( "ref/gunIdTextField" )
	if gunIdTextField ~= nil and sceneManager ~= nil then
		local curScene = sceneManager:getCurScene()
		local gunId = gunIdTextField:getText()
		if gunId ~= nil and curScene ~= nil and tonumber(gunId) ~= nil then
			curScene:changeGuns( curScene.enemy, tonumber(gunId) )
		end
	end
end

return UIGunView
require("app/model/Factory")
require("bdlib/tools/util")
local UIBaseClass = import("app/ui/UIBaseClass")

local UIMainGame = class("UIMainGame", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UIMainGame:initConfig()
	self.jsonFilePath = "res/ui/mainGame.json"
	self.TouchMode = cc.TOUCH_MODE_ALL_AT_ONCE
	self.TouchSwallowEnabled = false
	self.missionType = 0
	self.missCountDownTime = 0
	self.leftTimeLabel = nil
end

function UIMainGame:onInitEventsHandler()
	local refLayer = self:seekNodeByPath( "ref" )
	if refLayer ~= nil then
		refLayer:setTouchEnabled(true)
		refLayer:setTouchSwallowEnabled(false)
    	refLayer:setTouchMode(cc.TOUCH_MODE_ALL_AT_ONCE)
	end
	self:registerEventsHandlers( "ref", 		   								"TouchEvent", self.onTouchEvent )			--
	self:registerEventsHandlers( "ref/title/pauseBtn", 	   						"OnClicked",  self.onClickedPauseBtn )		--【暂停按钮】
	self:registerEventsHandlers( "ref/title/bombBtn", 	   						"OnClicked",  self.onClickedBombBtn )		--【炸弹按钮】
	self:registerEventsHandlers( "ref/title/sheildBtn", 	   					"OnClicked",  self.onClickedSheildBtn )		--【护盾按钮】
	self:registerEventsHandlers( "ref/title/formationBtn", 						"OnClicked", self.onClickedFormationBtn )	--【队形游戏】
	self:registerEventsHandlers( "pauseGameLayer/funcLayer/continueBtn", 		"OnClicked", self.onClickedContinueBtn )	--【继续游戏】
	self:registerEventsHandlers( "pauseGameLayer/funcLayer/quitMissionBtn", 	"OnClicked", self.onClickedQuitMissionBtn ) --【退出关卡】
end

function UIMainGame:initData()
	self.paused = false
end

function UIMainGame:onShowUI()
	self:showPauseGame( false )
	local leftTimeLabel = self:seekNodeByPath( "ref/leftTimeLabel" )
	local bossFullPowLabel = self:seekNodeByPath( "ref/bossFullPowLabel" )
	if leftTimeLabel ~= nil and bossFullPowLabel ~= nil then
		leftTimeLabel:setVisible( false )
		bossFullPowLabel:setVisible( false )
	end
	if DEBUG_BOUND_BOX == true then
        local refNode = self:seekNodeByPath( "ref" )
        if refNode ~= nil then
            local drawNode = cc.DrawNode:create()
            if drawNode ~= nil then
                for i = 0, 20 do
                    drawNode:drawLine( { i * 40, 0 }, { i * 40, 1280 }, 1, cc.c4f(0,1,1,0.1) )
                end
                for i = 0, 33 do
                    drawNode:drawLine( { 0, i * 40 }, { 720, i * 40 }, 1, cc.c4f(0,1,1,0.1) )
                end
                refNode:addChild( drawNode, 999 )
            end
        end
    end
    self.plane_life_ui = self:seekNodeByPath( "ref/title/bloodProgressBar" )
    self.checkMultiClickButtons = {}
    self.checkMultiClickButtons[1] = self:seekNodeByPath( "ref/title/bombBtn" )
    self.checkMultiClickButtons[2] = self:seekNodeByPath( "ref/title/sheildBtn" )
    self.checkMultiClickButtons[3] = self:seekNodeByPath( "ref/title/formationBtn" )
    self.checkMultiClickButtons[4] = self:seekNodeByPath( "ref/title/pauseBtn" )
end

function UIMainGame:onCloseUI()
end

function UIMainGame:onUpdateUI( dt )
	if self.plane_life_ui then
        local plane = self.world.plane
        if plane then
            local life = (plane.hp / plane.maxHP) * 100
            self.plane_life_ui:setPercent(life)
        end
    end
    if self.missionType == ENUM_MISSION_TYPE_TIME_LIMIT or self.missionType == ENUM_MISSION_TYPE_TIME_SURVIVE then
    	if self.missCountDownTime > 0 then
	    	local time = self.missCountDownTime - dt
	    	if time <= 0 then
	    		if self.missionType == ENUM_MISSION_TYPE_TIME_LIMIT then
	    			self.gameScene:pauseGame( true )
	    			self:onClickedQuitMissionBtn()
	    		elseif self.missionType == ENUM_MISSION_TYPE_TIME_SURVIVE and self.gameScene ~= nil then
	    			self.gameScene:pauseGame( true )
	    			self.gameScene:showMissionPassed()
	    		end
	    	end
	    	self.missCountDownTime = time
	    end
	    if self.leftTimeLabel ~= nil then
	    	self.leftTimeLabel:setString( string.format( "剩余时间:%d", tonumber(self.missCountDownTime) ) )
	    end
    end
end
---------------------------------------------------------------------------------------------------------
function UIMainGame:setGameScene( gameScene )
	if gameScene ~= nil then
		self.gameScene = gameScene
		self.world = gameScene.world
	end
end

function UIMainGame:onTouchEvent( event )
	if self.gameScene == nil then
		return
	end
	if not self.gameScene.paused then
		if event.name == "added" or event.name == "removed" then
			local _, point = next( event.points )
			if point ~= nil then
				local btnEvent = { name = "began", x = point.x, y = point.y }
				if event.name == "removed" then
					btnEvent.name = "ended"
				end
				for i, btn in ipairs( self.checkMultiClickButtons ) do
					if btn:onTouch_( btnEvent ) == true then
						break
					end
				end
			end
		else
			local fakeEvent = { name = event.name }
			local point = event.points["0"]
			if point ~= nil then
				for i, v in pairs( point ) do
					fakeEvent[i] = v
				end
			end
			self.gameScene.world:onTouch(fakeEvent)
		end
        return true
    end
    return true
end

function UIMainGame:onClickedPauseBtn()
	self:showPauseGame( true )
end


function UIMainGame:showPauseGame( bShow )
	local pauseGameLayer = self:seekNodeByPath( "pauseGameLayer" )
	local bgLayer = self:seekNodeByPath( "bgLayer.FILL_SCREEN" )
	if pauseGameLayer ~= nil and bgLayer ~= nil then
		bgLayer:setVisible(bShow)
		pauseGameLayer:setVisible( bShow )
		if self.gameScene ~= nil then
			self.gameScene:pauseGame( bShow )
		end
	end
end

function UIMainGame:onClickedQuitMissionBtn()
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		local function callback()
			local uiMissionResult = uiManager:getUIByName( "UIMissionResult" )
			if uiMissionResult ~= nil then
				uiMissionResult:setShowMode( 0 )
			end
		end
		uiManager:showUI( "UIMissionResult", true, callback )
	end
end

function UIMainGame:onClickedContinueBtn()
	self:showPauseGame( false )
end

function UIMainGame:onClickedBombBtn()
	self:onUseProps(PROPS_TYPE_BOMB)
end

function UIMainGame:onClickedSheildBtn()
	self:onUseProps(PROPS_TYPE_INVINCIBLE)
end

function UIMainGame:onClickedFormationBtn()
	local wingmanPlane = app.wingmanDatas[app.curWingmanPlaneId]
	if wingmanPlane == nil then
		return
	end
	local formationOpenInfo = wingmanPlane:getFormationOpenInfo()
	if formationOpenInfo == nil then
		return
	end
	if #formationOpenInfo == 1 then --没有开启其他的阵型，不能切换
		return
	end
	local found = false
	for i, v in ipairs( formationOpenInfo ) do
		if MyApp.curSelFormation == v then
			found = true
			if i == #formationOpenInfo then
				MyApp.curSelFormation = formationOpenInfo[1]
				break
			end
		else
			if found == true then
				MyApp.curSelFormation = v
				break
			end
		end
	end
	if found == false then
		MyApp.curSelFormation = formationOpenInfo[1]
	end
    self.world:updateWingManPos();
end

function UIMainGame:onUseProps(classify)
    local props = app.propsData[classify]
    if props and props.funUse then
        -- 现有道具,直接使用
        if props.count > 0 then
            props.funUse(props, self.world)
        else
        	props.count = props.count + 1
            props.funUse(props, self.world)
        end
    end
end

function UIMainGame:setMissData( tMissData )
	if tMissData == nil then
		return
	end
	self.missData = tMissData
	self.missionType = tMissData.type
	if tMissData.type == ENUM_MISSION_TYPE_TIME_LIMIT or tMissData.type == ENUM_MISSION_TYPE_TIME_SURVIVE then
		self.missCountDownTime = tonumber(tMissData.param1)
		local leftTimeLabel = self:seekNodeByPath( "ref/leftTimeLabel" )
		if leftTimeLabel ~= nil then
			self.leftTimeLabel = leftTimeLabel
			leftTimeLabel:setVisible( true )
			leftTimeLabel:setString( "" )
		end
	end
end

return UIMainGame
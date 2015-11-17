require("app/model/Factory")
local UIBaseClass = import("app/ui/UIBaseClass")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler") --加载定时器
local UILotteryEnter = class("UILotteryEnter", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UILotteryEnter:initConfig()
	self.jsonFilePath = "res/ui/lotteryEnter.json"
end

function UILotteryEnter:onInitEventsHandler()
	self:registerEventsHandlers( "ref/titlePanel/closeBtn", 		"OnClicked", self.onClickedCloseBtn )	
	self:registerEventsHandlers( "ref/goldPanel/goldBtn1", 			"OnClicked", self.onClickedgoldBtn1 )
	self:registerEventsHandlers( "ref/goldPanel/goldBtn10", 		"OnClicked", self.onClickedgoldBtn10 )
	self:registerEventsHandlers( "ref/diamPanel/diamondBtn1", 		"OnClicked", self.onClickeddiamondBtn1 )
	self:registerEventsHandlers( "ref/diamPanel/diamondBtn10", 		"OnClicked", self.onClickeddiamondBtn10 )		
end

function UILotteryEnter:initData()
end

function UILotteryEnter:onShowUI()
	local goldnum = self:seekNodeByPath("ref/titlePanel/goldnum")
	local diamnum = self:seekNodeByPath("ref/titlePanel/diamnum")
	goldnum:setString(app:countOfGold())
	diamnum:setString(app:countOfDiamond())
	self:scheduGoldHandle()
	self:scheduDiamHandle()
end
---------------------------------------------------------------------------------------------------------
function UILotteryEnter:scheduGoldHandle()
	local lotteryEnter = app.lotteryEnter
	local goldText = self:seekNodeByPath("ref/goldPanel/goldBtn1/gold1/goldText")
	local goldfreetitle = self:seekNodeByPath("ref/goldPanel/goldBtn1/goldfreetitle")
	local goldFree = self:seekNodeByPath("ref/goldPanel/goldBtn1/free")
	local gold1 = self:seekNodeByPath("ref/goldPanel/goldBtn1/gold1")
	local function dispGoldLabel()
		local cacuGoldFreeTime = lotteryEnter:cacuGoldFreeTime()
		if cacuGoldFreeTime <= 0 then
			lotteryEnter:setGoldFree(1)
		else
			app.lotteryEnter:setGoldFree(0)
		end
		self:disptime(goldText,cacuGoldFreeTime)
		if lotteryEnter:getGoldFree() == 0 then
			goldFree:setVisible(false)
			gold1:setVisible(true)
		else
			goldFree:setVisible(true)
			gold1:setVisible(false)
		end 
	end
	dispGoldLabel()
	self.goldhandle = scheduler.scheduleGlobal(function(dt)
		local cacuGoldFreeTime = lotteryEnter:cacuGoldFreeTime()
		self:disptime(goldText,cacuGoldFreeTime)
		if cacuGoldFreeTime <= 0 then 
			lotteryEnter:setGoldFree(1)
			dispGoldLabel()
			scheduler.unscheduleGlobal(self.goldhandle)
		end
	end,1)
end

function UILotteryEnter:scheduDiamHandle()
	local lotteryEnter = app.lotteryEnter
	local diamText = self:seekNodeByPath("ref/diamPanel/diamondBtn1/diamond1/diamondText")
	local diamFree = self:seekNodeByPath("ref/diamPanel/diamondBtn1/free")
	local diam1 = self:seekNodeByPath("ref/diamPanel/diamondBtn1/diamond1")
	local function dispDiamLabel()
		local cacuDiamFreeTime = lotteryEnter:cacuDiamFreeTime()
		if cacuDiamFreeTime <= 0 then
			app.lotteryEnter:setDiamFree(1)
		else
			app.lotteryEnter:setDiamFree(0)
		end 
		self:disptime(diamText,cacuDiamFreeTime)
		if lotteryEnter:getDiamFree() == 0 then
			diamFree:setVisible(false)
			diam1:setVisible(true)
		else
			diamFree:setVisible(true)
			diam1:setVisible(false)
		end
	end
	dispDiamLabel()
	self.diamhandle = scheduler.scheduleGlobal(function(dt)
		local cacuDiamFreeTime = lotteryEnter:cacuDiamFreeTime()
		self:disptime(diamText,cacuDiamFreeTime)
		if cacuDiamFreeTime <= 0 then 
			lotteryEnter:setDiamFree(1)
			dispDiamLabel()
			scheduler.unscheduleGlobal(self.diamhandle)
		end
	end,1) 
end

function UILotteryEnter:closeSchedule()
	scheduler.unscheduleGlobal(self.goldhandle)
	scheduler.unscheduleGlobal(self.diamhandle)
end

function UILotteryEnter:onClickedCloseBtn()
	self:closeSchedule()
	self:close()
end

function UILotteryEnter:onClickedgoldBtn1()
	app.lotteryMain:setLottype(1)
	if app.lotteryMain:check(100) or app.lotteryEnter:getGoldFree() == 1 then
		if app.lotteryEnter:getGoldFree() == 1 then
			app.lotteryEnter:setGoldFree(0)
			app.lotteryEnter:saveGoldFreeDate()
			app:saveFreeLottery()
		else
			app.lotteryMain:charge(100)
		end
		app.lotteryMain:setTimes(1)
		local uiManager = self:getUIManager()
		if uiManager ~= nil then
			self:onClickedCloseBtn()
			uiManager:showUI("UILotteryMain")
		end
	else
		self:showSystemTips("余额不足")
	end
end

function UILotteryEnter:onClickedgoldBtn10()
	app.lotteryMain:setLottype(1)
	if app.lotteryMain:check(900) then
		app.lotteryMain:charge(900)
		app.lotteryMain:setTimes(10)
		local uiManager = self:getUIManager()
		if uiManager ~= nil then
			self:onClickedCloseBtn()
			uiManager:showUI("UILotteryMain")
		end
	else
		self:showSystemTips("余额不足")
	end
end

function UILotteryEnter:onClickeddiamondBtn1()
	app.lotteryMain:setLottype(2)
	if app.lotteryMain:check(100) or app.lotteryEnter:getDiamFree() == 1 then
		if app.lotteryEnter:getDiamFree() == 1 then
			app.lotteryEnter:setDiamFree(0)
			app.lotteryEnter:saveDiamFreeDate()
			app:saveFreeLottery()
		else
			app.lotteryMain:charge(100)
		end
		app.lotteryMain:setTimes(1)
		local uiManager = self:getUIManager()
		if uiManager ~= nil then
			self:onClickedCloseBtn()
			uiManager:showUI("UILotteryMain")
		end
	else
		self:showSystemTips("余额不足")
	end
end

function UILotteryEnter:onClickeddiamondBtn10()
	app.lotteryMain:setLottype(2)
	if app.lotteryMain:check(900) then
		app.lotteryMain:charge(900)
		app.lotteryMain:setTimes(10)
		local uiManager = self:getUIManager()
		if uiManager ~= nil then
			self:onClickedCloseBtn()
			uiManager:showUI("UILotteryMain")
		end
	else
		self:showSystemTips("余额不足")
	end
end

function UILotteryEnter:disptime( text,time )
	local timeH = string.format("%02d",math.floor(time / 60))
	local timeM = string.format("%02d",time % 60)
	text:setString(timeH..":"..timeM)
end

return UILotteryEnter
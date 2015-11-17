require("app/model/Factory")
local UIBaseClass = import("app/ui/UIBaseClass")
local UILotteryMain = class("UILotteryMain", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UILotteryMain:initConfig()
	self.jsonFilePath = "res/ui/lotteryMain.json"
end

function UILotteryMain:onInitEventsHandler()
	self:registerEventsHandlers( "ref/titlePanel/closeBtn", "OnClicked", self.onClickedCloseBtn )	
	--self:registerEventsHandlers( "ref/backBtn", 		   	"OnClicked", self.onClickedbackBtn )
	self:registerEventsHandlers( "ref/oneBtn", 		   		"OnClicked", self.onClickedoneBtn )
	self:registerEventsHandlers( "ref/tenBtn", 		   		"OnClicked", self.onClickedtenBtn )		
end

function UILotteryMain:initData()
end

function UILotteryMain:onShowUI()
	local disptable = app.lotteryMain:getDisptable()
	local goldnum = self:seekNodeByPath("ref/titlePanel/goldnum")
	local diamnum = self:seekNodeByPath("ref/titlePanel/diamnum")
	goldnum:setString(app:countOfGold())
	diamnum:setString(app:countOfDiamond())
	local cost1 = self:seekNodeByPath("ref/oneBtn/cost1")
	local cost10 = self:seekNodeByPath("ref/tenBtn/cost10")
	if app.lotteryMain:getLottype() == 1 then
		cost1:setString(app:GET_STR("STR_GOLD_COST1"))
		cost10:setString(app:GET_STR("STR_GOLD_COST10"))
	else
		cost1:setString(app:GET_STR("STR_DIAM_COST1"))
		cost10:setString(app:GET_STR("STR_DIAM_COST10"))
	end
	self:disp(disptable)
	app.lotteryMain:getReward()
end
---------------------------------------------------------------------------------------------------------
function UILotteryMain:disp(disptable)
	local uiManager = self:getUIManager()
	local lotItemPanel = self:seekNodeByPath("ref/lotteryItem")
	lotItemPanel:removeAllChildren()
	for i, v in ipairs(disptable) do
		local lotRootNode, width, height = uiManager:loadUIFromFilePath("res/ui/lotteryItem.json")
		local lotitem = ccuiloader_seekNodeEx(lotRootNode, "ref")
		local itemImage = ccuiloader_seekNodeEx(lotitem, "itemImage")
		local itemNum = ccuiloader_seekNodeEx(lotitem, "itemNum")
		uiManager:replaceSpriteIcon(itemImage, v.plistFile, v.iconName)
		itemNum:setString("x"..v.counts)
		if lotitem then
	        lotitem:retain()
	        lotitem:setVisible(true)
	        lotitem:removeFromParentAndCleanup(false)
    	end
    	if #disptable == 1 then
    		lotitem:setScale(2)
    		lotitem:setPosition(200,50)
    	else
	    	if i <= 5 then
	    		lotitem:setPosition(i* 120 - 90, 30)
	    	else
	    		lotitem:setPosition((i - 5) * 120 - 90, 200)
	    	end
	    end
		lotItemPanel:addChild( lotitem )
	end
end

function UILotteryMain:onClickedoneBtn()
	if app.lotteryMain:check(100) then
		app.lotteryMain:charge(100)
		local goldnum = self:seekNodeByPath("ref/titlePanel/goldnum")
		local diamnum = self:seekNodeByPath("ref/titlePanel/diamnum")
		goldnum:setString(app:countOfGold())
		diamnum:setString(app:countOfDiamond())
		app.lotteryMain:setTimes(1)
		local disptable = app.lotteryMain:getDisptable()
		self:disp(disptable)
		app.lotteryMain:getReward()
	else
		self:showSystemTips("余额不足")
	end
end

function UILotteryMain:onClickedtenBtn()
	if app.lotteryMain:check(900) then
		app.lotteryMain:charge(900)
		local goldnum = self:seekNodeByPath("ref/titlePanel/goldnum")
		local diamnum = self:seekNodeByPath("ref/titlePanel/diamnum")
		goldnum:setString(app:countOfGold())
		diamnum:setString(app:countOfDiamond())
		app.lotteryMain:setTimes(10)
		local disptable = app.lotteryMain:getDisptable()
		self:disp(disptable)
		app.lotteryMain:getReward()
	else
		self:showSystemTips("余额不足")
	end
end

function UILotteryMain:onClickedCloseBtn()
	self:close()
end

--[[function UILotteryMain:onClickedbackBtn()
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		self:close()
		uiManager:showUI("UILotteryEnter")
	end
end]]

return UILotteryMain
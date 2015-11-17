require("app/model/Factory")
local UIBaseClass = import("app/ui/UIBaseClass")
local UILoginGift = class("UILoginGift", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UILoginGift:initConfig()
	self.jsonFilePath = "res/ui/loginGift.json"
end

function UILoginGift:initData()
end

function UILoginGift:onInitEventsHandler()
	self:registerEventsHandlers( "ref/closeBtn", 	  	"OnClicked", self.onClickedCloseBtn )		--【关闭】
	self:registerEventsHandlers( "ref/loginBtn",		  	"OnClicked", self.onClicedLoginBtn )			--【签到按钮】
end

function UILoginGift:initData()
end

function UILoginGift:onShowUI()
	local logingift = app.logingift
	local days = logingift:getLogindays()
	local goldPanel = self:seekNodeByPath("ref/goldPanel")
	local wingmanPanel = self:seekNodeByPath("ref/wingmanPanel")
	local loginBtn = self:seekNodeByPath("ref/loginBtn")
	local loginBtnText = self:seekNodeByPath("ref/loginBtn/loginBtn_Text")

	local curday = tonumber(os.date("%j"))
	if curday == logingift:getLoginDay() then
		loginBtn:setButtonEnabled(false)
		loginBtnText:setString(app:GET_STR("STR_HADLOGIN"))
	else
		loginBtn:setButtonEnabled(true)
		loginBtnText:setString(app:GET_STR("STR_LOGIN"))
		if self:checkLogin(days) == false then
			logingift:initDays()
		end
		if days == 7 then
			logingift:initDays()
			logingift:setFirstLogall(1)	
		end
	end
	self:checkFirstAll(logingift,wingmanPanel,goldPanel)
	self:showEveryDay()
	
end

function UILoginGift:onClickedCloseBtn()
	self:close()
end

function UILoginGift:onClicedLoginBtn()
	local logingift = app.logingift
	local days = logingift:getLogindays()
	local btn = self:seekNodeByPath("ref/loginBtn")
	local curday = tonumber(os.date("%j"))
	local allLogin = CfgData.getCfgTable(CFG_LOGINGIFT_ITEM)
	if self:checkLogin(days) then 
		logingift:addDays()
		local reward = allLogin[days + 1]
		self:giveReward(reward)
	else
		logingift:backToFirstDays()
		local reward = allLogin[1] 
		self:giveReward(reward)
	end
	logingift:saveLoginDate()
	btn:setButtonEnabled(false)
	self:initUILogin()
	app:saveLoginData()
end

function UILoginGift:checkLogin(days)
	local logingift = app.logingift
	local loginDay = logingift:getLoginDay()
	local curday = tonumber(os.date("%j"))
	if days < 7 and ( (curday == loginDay + 1) or 
		((loginDay == 365 or loginDay == 366) and curday == 1) )then					--连续签到
			return true
	else
		return false
	end
end

function UILoginGift:initUILogin()
	self:showEveryDay()
end

function UILoginGift:giveReward(v)
	if v.type[2] == nil then
		if v.type[1] == "gold" then
			app:modifyGold( v.counts )
		elseif v.type[1] == "property" then
			app.bag:addItemById(v.items,v.counts)
			app:saveItemsData()
		end
	elseif app.logingift:getFirstLogall() == 0 then
		    app:buyWingman(20102)
    		app:saveWingmanData()
    else
    	app:modifyGold(v.counts)
	end
end

function UILoginGift:checkFirstAll(logingift,wingmanPanel,goldPanel)
	if logingift:getFirstLogall() == 0 then
		goldPanel:setVisible(false)
		wingmanPanel:setVisible(true)
	else
		goldPanel:setVisible(true)
		wingmanPanel:setVisible(false)
	end
end

function UILoginGift:showEveryDay()
	local days = app.logingift:getLogindays()
	local itemLayer = self:seekNodeByPath("ref/itemLayer")
	local allLogin = CfgData.getCfgTable(CFG_LOGINGIFT_ITEM)
	local uiManager = self:getUIManager()
	for i, v in ipairs(allLogin) do
		if i <= 7 then
			local giftRootNode, width, height = uiManager:loadUIFromFilePath("res/ui/giftItem.json")
			local giftitem = ccuiloader_seekNodeEx(giftRootNode, "ref")
			local itemImage = ccuiloader_seekNodeEx(giftitem, "giftItem/itemImage")
			local hadLogin = ccuiloader_seekNodeEx(giftitem, "hadlogin")
			local dayDisp = ccuiloader_seekNodeEx(giftitem, "day")
			uiManager:replaceSpriteIcon(itemImage, v.plistFile, v.iconName)
			dayDisp:setString(i)
			if giftitem then
		        giftitem:retain()
		        giftitem:setVisible(true)
		        giftitem:removeFromParentAndCleanup(false)
		    end
		    if i <= days then
				hadLogin:setVisible(true)
			else
				hadLogin:setVisible(false)
			end
			if i > 4 and i <= 7 then
				giftitem:setPosition((i - 5)* 140 + 90, 0)
			else
				giftitem:setPosition((i - 1) * 140 + 30, 160)
			end
			itemLayer:addChild( giftitem )
		end
	end
end
---------------------------------------------------------------------------------------------------------
return UILoginGift
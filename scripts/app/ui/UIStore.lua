require("app/model/Factory")
local UIBaseClass = import("app/ui/UIBaseClass")

local UIStore = class("UIStore", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UIStore:initConfig()
	self.jsonFilePath = "res/ui/store.json"
end

function UIStore:onInitEventsHandler()
	self:registerEventsHandlers( "ref/closeBtn", 		   	"OnClicked", self.onClickedCloseBtn )	
	self:registerEventsHandlers( "ref/recommendBtn", 		"OnClicked", self.onClickedrecommendBtn )
	self:registerEventsHandlers( "ref/goldBtn", 		   	"OnClicked", self.onClickedgoldBtn )
	self:registerEventsHandlers( "ref/propertyBtn", 		"OnClicked", self.onClickedpropertyBtn )
	self:registerEventsHandlers( "ref/planeBtn", 		   	"OnClicked", self.onClickedplaneBtn )
	self:registerEventsHandlers( "ref/wingmanBtn", 		   	"OnClicked", self.onClickedwingmanBtn )		
	self:registerEventsHandlers( "ref/left", 		   		"OnClicked", self.onClickedleft )
	self:registerEventsHandlers( "ref/right", 		  	 	"OnClicked", self.onClickedright )
end

function UIStore:initData()
end

function UIStore:onShowUI()
	self.x1 = 0
	self.x2 = 0
	self.y = 0
	local layerEvent = self:seekNodeByPath("ref/itemLayer")
    layerEvent:setTouchEnabled(true) 
    layerEvent:addNodeEventListener(cc.NODE_TOUCH_EVENT,function(event)  
        	return self:OnTouch(event) 
        end)  
	self:disp()
end
---------------------------------------------------------------------------------------------------------
function UIStore:OnTouch( event,storeListView )
 	if event.name == "began" then
 		self.x1 = event.x
 		self.y = event.y
 		return true
 	elseif event.name == "ended" then
 		if math.abs(event.y - self.y) < 80 then
	 		self.x2 = event.x
	 		self:dealTouch(self.x1,self.x2)
	 	end
 	end
 end 

function UIStore:dealTouch(x1,x2)
	if x2 - x1 > 100 then
		self:onClickedright()
	elseif x1 - x2 > 100 then
		self:onClickedleft()
	end
end

function UIStore:onClickedCloseBtn()
	self:close()
end

function UIStore:onClickedrecommendBtn()
	app.store:setType("recommend")
	self:disp()
end

function UIStore:onClickedgoldBtn()
	app.store:setType("gold")
	self:disp()
end

function UIStore:onClickedpropertyBtn()
	app.store:setType("property")
	self:disp()
end

function UIStore:onClickedplaneBtn()
	app.store:setType("plane")
	self:disp()
end

function UIStore:onClickedwingmanBtn()
	app.store:setType("wingman")
	self:disp()
end

function UIStore:onClickedleft()
	local typetable = app.store:getTypetable()
	local curpos = self:getButtonPos()
	if curpos == 1 then
		nextpos = 5
	else
		nextpos = curpos - 1
	end
	app.store:setType(typetable[nextpos])
	self:disp()
end

function UIStore:onClickedright()
	local typetable = app.store:getTypetable()
	local curpos = self:getButtonPos()
	if curpos == 5 then
		nextpos = 1
	else
		nextpos = curpos + 1
	end
	app.store:setType(typetable[nextpos])
	self:disp()
end

function UIStore:initShow()
	self:close()
	local uiManager = self:getUIManager()
	if uiManager ~= nil then
		uiManager:showUI("UIStore")
	end
end

function UIStore:setButtonDisp()
	local recommendBtn = self:seekNodeByPath("ref/recommendBtn")
	local goldBtn = self:seekNodeByPath("ref/goldBtn")
	local propertyBtn = self:seekNodeByPath("ref/propertyBtn")
	local planeBtn = self:seekNodeByPath("ref/planeBtn")
	local wingmanBtn = self:seekNodeByPath("ref/wingmanBtn")
	local allBtn = {recommendBtn,goldBtn,propertyBtn,planeBtn,wingmanBtn}
	for i = 1, #allBtn do
		if i == self:getButtonPos() then
			allBtn[i]:setButtonEnabled(false)
		else 
			allBtn[i]:setButtonEnabled(true)
		end
	end
end

function UIStore:checkDiamond( buyBtn,price )
	if app:countOfDiamond() < price then
	buyBtn:setButtonEnabled(false)
	end
end

function UIStore:getButtonPos()
	return table.indexOf(app.store:getTypetable(),app.store:getType())
end

function UIStore:disp()
	local store = app.store
	local uiManager = self:getUIManager()
	local storeListView = self:seekNodeByPath("ref/itemLayer/listView")
	if uiManager ~= nil and storeListView ~= nil then
		storeListView:removeAllItems()
		storeListView:setBounceable(true)
		storeListView:reload()
	end
	self:setButtonDisp()
	store:loadStoreItem()
	local storeItem = store:getStoreItem()
	local storeWidth = 600
	local storeHeight = 180
	for i, v in ipairs(storeItem) do
		local storeListRootNode, width, height = uiManager:loadUIFromFilePath("res/ui/storeItem.json")
		local storelist = ccuiloader_seekNodeEx(storeListRootNode, "ref")
		if storelist then
	        storelist:retain()
	        storelist:setVisible(true)
	        storelist:removeFromParentAndCleanup(false)
	    end

		local iconImage = ccuiloader_seekNodeEx(storelist, "iconImage")
		local nameLabel = ccuiloader_seekNodeEx(storelist, "nameLabel")
		local descLabel = ccuiloader_seekNodeEx(storelist, "descLabel")
		local preCut = ccuiloader_seekNodeEx(storelist, "preCut")
		local oldprice = ccuiloader_seekNodeEx(storelist,"preCut/price")
		local costNum = ccuiloader_seekNodeEx(storelist, "buy/costNum")
		local buyBtn = ccuiloader_seekNodeEx(storelist, "buy/buyBtn")
		local bg = ccuiloader_seekNodeEx(storelist, "bg")
		bg:setTouchEnabled(true) 
		bg:setTouchSwallowEnabled(false)
		bg:addNodeEventListener(cc.NODE_TOUCH_EVENT,function(event)  
        	return self:OnTouch(event,storeListView) 
        end)
		if v.cut == 0 then 
			preCut:setVisible(false)
		else
			preCut:setVisible(true)
			oldprice:setString(v.price / v.cut * 10)
		end
		costNum:setString(v.price)
		uiManager:replaceSpriteIcon(iconImage, v.plistFile, v.iconName)
		nameLabel:setString(v.name)
		descLabel:setString(v.desc)
		descLabel:setDimensions( CCSize( 250, 90 ) )
		descLabel:setContentSize( CCSize( 250, 90 ) )

		self:checkDiamond(buyBtn,v.price)
        buyBtn.Index = i
		buyBtn:onButtonClicked( function(event)
			app:modifyDiamond( -v.price )
			if v.type == "recommend" then
				app:modifyGold( v.counts[1] )
				app.bag:addItemById(v.items[2],v.counts[2])
				app.bag:addItemById(v.items[3],v.counts[3])
				app:saveItemsData()
			elseif v.type == "gold" then
				app:modifyGold( v.counts[1] )
			elseif v.type == "property" then
				app.bag:addItemById(v.id)
				app:saveItemsData()
			elseif v.type == "plane" then
        		app:buyPlane(i+20001)
        		app:savePlaneData()
	        elseif v.type == "wingman" then
        		app:buyWingman(i+20101)
    			app:saveWingmanData()
			end
			local uiSelectPlane = uiManager:getUIByName( "UISelectPlane" )
			if uiSelectPlane ~= nil then
				uiSelectPlane:updatePropsCount()
			end
			self:checkDiamond(buyBtn,v.price)
			self:disp()
		end)

		if v.type == "plane" and app.planeDatas[i+20001] ~= nil then
			if app.planeDatas[i+20001].id ~= nil then
				buyBtn:setButtonEnabled(false)
				costNum:setString(app:GET_STR("STR_HAD"))
			else
				buyBtn:setButtonEnabled(true)
			end
		elseif v.type == "wingman" and app.wingmanDatas[i+20101] ~= nil then
			if app.wingmanDatas[i+20101] ~= nil then
				buyBtn:setButtonEnabled(false)
				costNum:setString(app:GET_STR("STR_HAD"))
			end
		end

		storelist:setContentSize(CCSize(storeWidth, storeHeight))
		local onestore = storeListView:newItem( storelist )
		if onestore ~= nil then
			onestore:setContentSize( CCSize(storeWidth,storeHeight) )
			onestore:setItemSize( storeWidth, storeHeight )
			storeListView:addItem(onestore)
		end
		storeListView:reload()
	end
end

return UIStore
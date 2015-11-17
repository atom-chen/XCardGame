require("app/model/Factory")
local UIBaseClass = import("app/ui/UIBaseClass")

local UIAchive = class("UIAchive", UIBaseClass )
---------------------------------------------------------------------------------------------------------
function UIAchive:initConfig()
	self.jsonFilePath = "res/ui/achive.json"
end

function UIAchive:initData()
end

function UIAchive:onInitEventsHandler()
	self:registerEventsHandlers( "ref/closeBtn", 	  "OnClicked", self.onClickedCloseBtn )		--【关闭】
end

function UIAchive:onShowUI()
	local myAchive = app.achive
	local uiManager = self:getUIManager()
	local achiveListView = self:seekNodeByPath("ref/itemLayer/achiveListView")
	local finishtable = {}
	local unfinishtable = {}
	local isgettable = {}
	if uiManager ~= nil and achiveListView ~= nil then
		achiveListView:removeAllItems()
		achiveListView:setBounceable(true)
		achiveListView:reload()
	end
	local tAllAchive = myAchive:getAllAchive()
	for i, v in pairs(tAllAchive) do
		local typeNum										--完成度实时更新
		if v.isFinish == "FALSE" then						
			if v.type == "level" then
				local curMaxLevel = 1
				for _, plane in pairs(app.planeDatas) do
					if plane.level > curMaxLevel then
						curMaxLevel = plane.level
					end
				end
			 	typeNum = curMaxLevel
			elseif v.type == "mission" then
				typeNum = app.missionData.curLockMissId - 1
			else
				typeNum =  MyApp:getPropCount(PROPS_TYPE_GOLD)
			end
			v.achivingNum = typeNum / v.param1 * 100
			if v.achivingNum >= 100 then
				v.achivingNum = 100
			end
		else
			v.achivingNum = 100
		end

		if v.isFinish == "TRUE" and v.isGet == "FALSE" then
			table.insert(finishtable,v)
		elseif v.isGet == "TRUE" then
			table.insert(isgettable,v)
		else
			table.insert(unfinishtable,v)
		end
	end
	self:itemDisplay(finishtable,uiManager,achiveListView)
	self:itemDisplay(unfinishtable,uiManager,achiveListView)
	self:itemDisplay(isgettable,uiManager,achiveListView)
	achiveListView:reload()
end

function UIAchive:onClickedCloseBtn()
	app:saveAchiveData()
	self:close()
end

function UIAchive:itemDisplay(itemtable,uiManager,achiveListView)
	if itemtable == nil or uiManager == nil or achiveListView == nil then
		return
	end
	local achiveWidth = 650
	local achiveHeight = 180
	for i, v in pairs(itemtable) do
		local findAchive = app.achive:findAchiveById(v.param2)
		if v.param2 <= 0 or findAchive.isGet == "TRUE" then
			local achiveListRootNode, width, height = uiManager:loadUIFromFilePath("res/ui/achivelist.json")
			local achivelist = ccuiloader_seekNodeEx(achiveListRootNode, "ref")
			if achivelist then
		        achivelist:retain()
		        achivelist:setVisible(true)
		        achivelist:removeFromParentAndCleanup(false)
		    end

			local achivedBtn = ccuiloader_seekNodeEx(achivelist, "achivedBtn")
			local achivedText = ccuiloader_seekNodeEx(achivelist, "achivedText")
			local iconImage = ccuiloader_seekNodeEx(achivelist, "iconImage")
			local nameLabel = ccuiloader_seekNodeEx(achivelist, "nameLabel")
			local descLabel = ccuiloader_seekNodeEx(achivelist, "descLabel")
			local achiving = ccuiloader_seekNodeEx(achivelist, "achiving")
			local reward = ccuiloader_seekNodeEx(achivelist, "reward")
			achiving:setString(math.floor(v.achivingNum) .. "%")

			nameLabel:setString( v.name or "" )
			descLabel:setString( v.desc or "" )
			descLabel:setDimensions( CCSize( 260, 90 ) )
			descLabel:setContentSize( CCSize( 260, 90 ) )
	    	uiManager:replaceSpriteIcon(iconImage, v.plistFile, v.iconName)
			reward:setString( v.reward..app:GET_STR("STR_GOLD") or "" )
			reward:setContentSize( CCSize( 250, 30 ) )
			achivedText:setString(app:GET_STR("STR_ACHIVED"))
			achivedText:setVisible(false)

			if v.isFinish == "FALSE" or v.isGet == "TRUE" then
				achivedBtn:setVisible(false)
			else
				achivedBtn:setVisible(true)
				achivedText:setVisible(true)
			end
			if v.isGet == "TRUE" then
				achivedText:setString(app:GET_STR("STR_GOT"))
				achivedText:setVisible(true)
			end

	        achivedBtn.Index = i
			achivedBtn:onButtonClicked( function(event)
				app:getReward( "gold",nil,v.reward )											--【奖励】
				local uiSelectPlane = uiManager:getUIByName( "UISelectPlane" )
				if uiSelectPlane ~= nil then
					v.isGet = "TRUE"
				end
					achivedBtn:setVisible(false)
					app:saveAchiveData()
					if v.param2 ~= 0 then
						self:close()
						uiManager:showUI( "UIAchive" )
					end
			end)

			achivelist:setContentSize(CCSize(achiveWidth, achiveHeight))
			local oneachive = achiveListView:newItem( achivelist )
			if oneachive ~= nil then
				oneachive:setContentSize( CCSize(achiveWidth,achiveHeight) )
				oneachive:setItemSize( achiveWidth, achiveHeight )
				achiveListView:addItem(oneachive)
			end
		end
	end
end

return UIAchive
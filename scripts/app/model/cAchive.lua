cAchive = class("cAchive")
local cAchiveItem = require("app/model/cAchiveItem")

function cAchive:ctor()
	self.tAchive = {}
	self.tAchiveData = {}
end

function cAchive:getInstance()
	if _G.__achiveInstance == nil then
		_G.__achiveInstance = cAchive:new()
	end
	return _G.__achiveInstance
end

function cAchive:findAchiveById(achiveId)
	for i, v in ipairs( self.tAchive ) do
		if v.id == achiveId then 
			return v
		end
	end
end

function cAchive:saveGet(achiveItem)
	table.insert( self.tAchiveData, achiveItem )
end

function cAchive:initAchive()
	local allAchive = CfgData.getCfgTable(CFG_ACHIVE_ITEM)
	if allAchive ~= nil then
		for i, v in pairs( allAchive ) do
			self:addAchiveById( tonumber(v.id) )
		end
	end
end

function cAchive:addAchiveById(achiveId)
	local achiveItem = self:creatAchiveById(achiveId)
	table.insert( self.tAchive, achiveItem )

end

function cAchive:creatAchiveById(achiveId)
	local achiveCfg = CfgData.getCfg(CFG_ACHIVE_ITEM, achiveId )
	if achiveCfg ~= nil then
		local achiveItem = cAchiveItem:new()
		if achiveItem ~= nil then
			achiveItem:initByCfg( achiveCfg )
			return achiveItem
		end
	end
end

function cAchive:getDoc(document)
	self.tAchive = document
end

function cAchive:getAllAchive()
	return self.tAchive
end

function cAchive:getAchiveData()
	return self.tAchiveData
end

function cAchive:checkAchive(classify, num)
    for i, v in ipairs(self.tAchive) do
    	if v.isFinish == "FALSE" then
        	if classify == v.type and num >= v.param1 then
        		self:isFinish(v)
        	end
       	end
    end
end

function cAchive:isFinish(item)
    item.isFinish = "TRUE"
    self:saveGet(item)
end

return cAchive
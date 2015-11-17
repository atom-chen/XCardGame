cStore = class("cStore")

function cStore:ctor()
	self.store = {}
	self.type = "recommend"
	self.typetable = {"recommend","gold","property","plane","wingman"}
end

function cStore:getInstance()
	if _G.__storeInstance == nil then
		_G.__storeInstance = cStore:new()
	end
	return _G.__storeInstance
end

function cStore:loadStoreItem()
	local allItem = CfgData.getCfgTable(CFG_STORE_ITEM)
	self.store = {}
	for i, v in pairs(allItem) do
		if self.type == v.type then
			table.insert(self.store,v)
		end
	end
end

function cStore:getStoreItem()
	return self.store
end

function cStore:setType( typename )
	self.type = typename
end

function cStore:getType()
	return self.type
end

function cStore:getTypetable()
	return self.typetable
end

return cStore
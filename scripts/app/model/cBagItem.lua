cBagItem = class("cBagItem")

function cBagItem:ctor()
	self.id = 0
	self.type = 0
	self.name = ""
	self.enhExp = 0
	self.level = 0
	self.count = 1
	self.maxStackCount = 1
	self.quality = 0
	self.maxQuality = 3
	self.sellPrice = 100
	self.plistFile = ""
	self.iconName = ""
end

function cBagItem:initByCfg( itemCfg )
	self.id = itemCfg.id
	self.type = itemCfg.type
	self.name = itemCfg.name
	self.enhExp = 0
	self.count = 1
	self.level = itemCfg.level
	self.maxStackCount = itemCfg.maxStackCount
	self.quality = itemCfg.quality
	self.desc = itemCfg.desc
	self.plistFile = itemCfg.plistFile
	self.iconName = itemCfg.iconName
end

function cBagItem:getType()
	return self.type
end

function cBagItem:getLevel()
	return self.level
end

function cBagItem:getMaxLv()
	return self.maxStackCount
end

function cBagItem:getEnhExp()
	return self.enhExp
end

function cBagItem:getQuality()
	return self.quality
end

function cBagItem:getMaxQuality()
	return self.maxQuality
end

function cBagItem:getSellPrice()
	return self.sellPrice
end

function cBagItem:addCount( count )
	self.count = self.count + count
	if self.count > self.maxStackCount then
		self.count = self.maxStackCount
	end
end

function cBagItem:getItemSaveData()
	return { ItemId = self.id, ItemCount = self.count }
end

function cBagItem:addEnhExp( enhExp )

end

return cBagItem
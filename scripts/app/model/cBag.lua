cBag = class("cBag")
local cBagItem = require("app/model/cBagItem")

function cBag:ctor()
	self.tBagItems = {}
	self.bagSize = 50
end

function cBag:getInstance()
	if _G.__bagInstance == nil then
		_G.__bagInstance = cBag:new()
	end
	return _G.__bagInstance
end

function cBag:getBagSize()
	return self.bagSize
end

function cBag:addItem( item )
	if self:isBagFull() ~= true then
		table.insert( self.tBagItems, item )
	end
end

function cBag:removeItem( item )
	for i, v in ipairs( self.tBagItems ) do
		if v == item then
			table.remove( self.tBagItems, i )
			break
		end
	end
end

--这里物品的堆叠规则代码还有问题，需要之后再来进行处理
function cBag:addItemById( itemId, count )
	count = count or 1
	local tItems = self:findItemsById( itemId )
	if tItems ~= nil and #tItems > 0 then
		local countTemp = count
		for i, v in ipairs( tItems ) do
			if v.count < v.maxStackCount then
				if v.count + countTemp <= v.maxStackCount then
					v.count = v.count + countTemp
					countTemp = 0
				else
					v.count = v.count + ( v.maxStackCount - v.count )
					countTemp = countTemp - (v.maxStackCount - v.count)
				end
				if countTemp == 0 then
					break
				end
			end
		end
		if countTemp > 0 then
			local newItem = self:createNewItem( itemId )
			if newItem ~= nil then
				self:addItem( newItem )
				if countTemp > 1 then
					self:addItemById( itemId, (countTemp - 1) )
				end
			end
		end
	else --没找到，重新加
		local newItem = self:createNewItem( itemId )
		if newItem ~= nil then
			self:addItem( newItem )
			if count > 1 then
				self:addItemById( itemId, (count - 1) )
			end
		end
	end
end

function cBag:removeItemById( itemId, count )
	count = count or 1
	local totalCount = self:getItemCount( itemId )
	if totalCount < count then
		return
	end
	local tItems = self:findItemsById( itemId )
	if tItems ~= nil and #tItems > 0 then
		local tDeleteTable = {}
		local countTemp = count
		for i, v in ipairs( tItems ) do
			if v.count >= countTemp then
				v.count = v.count - countTemp
				countTemp = 0
			else
				countTemp = countTemp - v.count
				v.count = 0
			end
			if countTemp == 0 then
				break
			end
			if v.count == 0 then
				table.insert( tDeleteTable, v)
			end
		end
		for i, v in ipairs( tDeleteTable ) do
			self:removeItem( v )
		end
	end
end

function cBag:findItemsById( itemId )
	local tItems = {}
	for i, v in ipairs( self.tBagItems ) do
		if v.id == itemId then 
			table.insert( tItems, v )
		end
	end
	return tItems
end

function cBag:getItemCount( itemId )
	local itemCount = 0
	for i, v in ipairs( self.tBagItems ) do
		if v.id == itemId then
			itemCount = itemCount + v.count
		end
	end
	return itemCount
end

function cBag:createNewItem( itemId )
	local bagItemsCfg = CfgData.getCfg(CFG_BAG_ITEM, itemId )
	if bagItemsCfg ~= nil then
		local bagItem = cBagItem:new()
		if bagItem ~= nil then
			bagItem:initByCfg( bagItemsCfg )
			return bagItem
		end
	end
end

function cBag:getItemByPos( pos )
	return self.tBagItems[pos]
end

function cBag:getAllItems()
	return self.tBagItems
end

function cBag:isBagFull()
	return (#self.tBagItems >= self.bagSize)
end

function cBag:removeItem( item )
	for i, v in ipairs( self.tBagItems ) do
		if item == v then
			table.remove( self.tBagItems, i )
		end
	end
end

function cBag:removeItemByPos( pos )
	local item = self.tBagItems[pos];
	if item ~= nil then
		table.remove( self.tBagItems, pos )
	end
end

function cBag:removeItemsByPosTable( tPos )
	local tRemoveItems = {}
	for i, v in ipairs( tPos ) do
		table.insert( tRemoveItems, self.tBagItems[i] )
	end
	self:removeItemsByTable( tRemoveItems )
end

function cBag:removeItemsByTable( tItemTable )
	for i, v in ipairs( tItemTable ) do
		self:removeItem( v )
	end
end

return cBag
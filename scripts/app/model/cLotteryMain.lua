cLotteryMain = class("cLotteryMain")

function cLotteryMain:ctor()
	self.lottype = 0
	self.lottable = {}
	self.times = 0
end

function cLotteryMain:getInstance()
	if _G.__lotteryMainInstance == nil then
		_G.__lotteryMainInstance = cLotteryMain:new()
	end
	return _G.__lotteryMainInstance
end

function cLotteryMain:getDisptable()
	self.lottable = {}
	local item = CfgData.getCfgTable(CFG_LOTTERY_ITEM)
	for j = 1, self.times do
		local rand = math.random(1,10000)
		local beganNum = 0
		local endNum = 0
		for i, v in ipairs(item) do
			if v.tableid == self.lottype then
				endNum = beganNum + v.rand * 10000
	 			if rand > beganNum and rand < endNum then
					table.insert(self.lottable,v)
				end
			end
			beganNum = endNum
		end
	end
	return self.lottable
end

function cLotteryMain:check( price )
	if self.lottype == 1 then
		if app:countOfGold() < price then
			return false
		else
			return true
		end
	else
		if app:countOfDiamond() < price then
			return false
		else
			return true
		end
	end
end

function cLotteryMain:charge( price )
	if self.lottype == 1 then
		app:modifyGold(-price)
	else
		app:modifyDiamond(-price)
	end
end

function cLotteryMain:setLottype( num )
	self.lottype = num
end

function cLotteryMain:setTimes( num )
	self.times = num
end

function cLotteryMain:getReward()
	for i, v in ipairs(self.lottable) do
		app:getReward(v.type,v.items,v.counts)
	end
end

function cLotteryMain:getLottype()
	return self.lottype
end

function cLotteryMain:getLottable()
	return self.lottable
end

function cLotteryMain:getTimes()
	return self.times
end

return cLotteryMain
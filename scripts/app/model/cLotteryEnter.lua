cLotteryEnter = class("cLotteryEnter")

function cLotteryEnter:ctor()
	self.goldFreeTime = {0,0,0}
	self.goldFree = 1
	self.diamFreeTime = {0,0,0}
	self.diamFree = 1
end

function cLotteryEnter:getInstance()
	if _G.__lotteryEnterInstance == nil then
		_G.__lotteryEnterInstance = cLotteryEnter:new()
	end
	return _G.__lotteryEnterInstance
end

function cLotteryEnter:cacuGoldFreeTime()
	local curDay = tonumber(os.date("%j"))
	local curHou = tonumber(os.date("%H"))
	local curMin = tonumber(os.date("%M"))
	local cacuDay = curDay - self.goldFreeTime[1]
	local cacuHou = curHou - self.goldFreeTime[2]
	local cacuMin = curMin - self.goldFreeTime[3]
	local restTime = (20 - cacuDay * 24 - cacuHou) * 60 - cacuMin
	if restTime < 0 then
		return 0
	else
		return restTime
	end
end

function cLotteryEnter:cacuDiamFreeTime()
	local curDay = tonumber(os.date("%j"))
	local curHou = tonumber(os.date("%H"))
	local curMin = tonumber(os.date("%M"))
	local cacuDay = curDay - self.diamFreeTime[1]
	local cacuHou = curHou - self.diamFreeTime[2]
	local cacuMin = curMin - self.diamFreeTime[3]
	local restTime = (20 - cacuDay * 24 - cacuHou) * 60 - cacuMin
	if restTime < 0 then
		return 0
	else
		return restTime
	end
end

function cLotteryEnter:saveGoldFreeDate()
	self.goldFreeTime[1] = tonumber(os.date("%j"))
	self.goldFreeTime[2] = tonumber(os.date("%H"))
	self.goldFreeTime[3] = tonumber(os.date("%M"))
end

function cLotteryEnter:saveDiamFreeDate()
	self.diamFreeTime[1] = tonumber(os.date("%j"))
	self.diamFreeTime[2] = tonumber(os.date("%H"))
	self.diamFreeTime[3] = tonumber(os.date("%M"))
end

function cLotteryEnter:getGoldFreeTime()
	return self.goldFreeTime
end

function cLotteryEnter:setGoldFreeTime(FreeTimetable)
	self.goldFreeTime = FreeTimetable
end

function cLotteryEnter:getGoldFree()
	return self.goldFree
end

function cLotteryEnter:setGoldFree(num)
	self.goldFree = num
end

function cLotteryEnter:getDiamFreeTime()
	return self.diamFreeTime
end

function cLotteryEnter:setDiamFreeTime(FreeTimetable)
	self.diamFreeTime = FreeTimetable
end

function cLotteryEnter:getDiamFree()
	return self.diamFree
end

function cLotteryEnter:setDiamFree(num)
	self.diamFree = num
end

return cLotteryEnter
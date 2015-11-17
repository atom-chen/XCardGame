cLoginGift = class("cLoginGift")

function cLoginGift:ctor()
	self.days = 0
	self.loginday = 0
	self.firstlogall = 0
end

function cLoginGift:getInstance()
	if _G.__logingiftInstance == nil then
		_G.__logingiftInstance = cLoginGift:new()
	end
	return _G.__logingiftInstance
end

function cLoginGift:addDays()
	self.days = self.days + 1
end

function cLoginGift:saveLoginDate()
	self.loginday = tonumber(os.date("%j"))
end

function cLoginGift:backToFirstDays()
	self.days = 1
end

function cLoginGift:initDays()
	self.days = 0
end

function cLoginGift:getLogindays()
	return self.days
end

function cLoginGift:getFirstLogall()
	return self.firstlogall
end

function cLoginGift:getLoginDay()
	return self.loginday
end

function cLoginGift:setLogindays(num)
	self.days = num
end

function cLoginGift:setFirstLogall(num)
	self.firstlogall = num
end

function cLoginGift:setLoginDay(num)
	self.loginday = num
end

return cLoginGift
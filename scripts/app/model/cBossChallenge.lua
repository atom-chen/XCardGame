cBossChallenge = class("cBossChallenge")

function cBossChallenge:ctor()
	self.difficulty = 1
end

function cBossChallenge:getInstance()
	if _G.__BossChallengeInstance == nil then
		_G.__BossChallengeInstance = cBossChallenge:new()
	end
	return _G.__BossChallengeInstance
end

function cBossChallenge:addDifficult()
	if self.difficulty == 3 then
		self.difficulty = 1
	else
		self.difficulty = self.difficulty + 1
	end
end

function cBossChallenge:decDifficult()
	if self.difficulty == 1 then
		self.difficulty = 3
	else
		self.difficulty = self.difficulty - 1
	end
end

function cBossChallenge:getDifficult()
	local DifString
	if self.difficulty == 1 then
		DifString = app:GET_STR("STR_EASY")
	elseif self.difficulty == 2 then
		DifString = app:GET_STR("STR_NORMAL")	
	elseif self.difficulty == 3 then
		DifString = app:GET_STR("STR_DIFFICULT")
	end
	return DifString
end

return cBossChallenge
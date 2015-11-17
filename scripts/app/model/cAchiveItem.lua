cAchiveItem = class("cAchiveItem")

function cAchiveItem:ctor()
	self.id = 0
	self.type = 0
	self.name = ""
	self.desc = ""
	self.plistFile = ""
	self.iconName = ""
	self.isFinish = "FALSE"
	self.isGet = "FALSE"
	self.param1 = 0
	self.param2 = 0
	self.reward = 0
end

function cAchiveItem:initByCfg( itemCfg )
	self.id = itemCfg.id
	self.type = itemCfg.type
	self.name = itemCfg.name
	self.desc = itemCfg.desc
	self.plistFile = itemCfg.plistFile
	self.iconName = itemCfg.iconName
	self.param1 = itemCfg.param1
	self.param2 = itemCfg.param2
	self.reward = itemCfg.reward
end

function cAchiveItem:getSaveData()
	return { id = self.id, isFinish = self.isFinish, isGet = self.isGet }
end

return cAchiveItem

cTechMgr = class("cTechMgr")

--[[
	ENUM_TECH_TYPE_FULL_POW_TIME	暴走时间
	ENUM_TECH_TYPE_SHEILD_TIME		护盾时间
	ENUM_TECH_TYPE_ADD_GOLD			金币加成
	ENUM_TECH_TYPE_ADD_EXP			经验加成
	ENUM_TECH_TYPE_BOSS_WEEK		Boss削弱
	ENUM_TECH_TYPE_ENH_POW			火力加成
]]--

function cTechMgr:ctor()
	self.curTechLevel = { 1, 1, 1, 1, 1, 1 }
end

function cTechMgr:init()
	self.TECH_TYPE_STR_MAP = 
	{
		[ENUM_TECH_TYPE_FULL_POW_TIME] 	= "fullPowTime",
		[ENUM_TECH_TYPE_SHEILD_TIME] 	= "sheildTime",
		[ENUM_TECH_TYPE_ADD_GOLD] 		= "goldAdd",
		[ENUM_TECH_TYPE_ADD_EXP] 		= "expAdd",
		[ENUM_TECH_TYPE_BOSS_WEEK] 		= "bossWeek",
		[ENUM_TECH_TYPE_ENH_POW] 		= "enhPow",
	}
end

function cTechMgr:getInstance()
	if _G.__techMgr == nil then
		_G.__techMgr = cTechMgr:new()
	end
	return _G.__techMgr
end

function cTechMgr:getTechInfo( techType )
	local curLevel = self.curTechLevel[ techType ]
	local techName = self.TECH_TYPE_STR_MAP[ techType ]
	if curLevel == nil or techName == nil then
		return
	end
	local techCfg = CfgData.getCfg( CFG_TECH_LEVELS, curLevel )
	if techCfg == nil then
		return
	end
	local needGoldName = string.format( "%s_gold", techName )
	return curLevel, techCfg[ techName ], techCfg[needGoldName]
end

function cTechMgr:getTechLvInfo( techType, lv )
	local techName = self.TECH_TYPE_STR_MAP[ techType ]
	if techName == nil then
		return
	end
	local techCfg = CfgData.getCfg( CFG_TECH_LEVELS, lv )
	if techCfg == nil then
		return
	end
	local needGoldName = string.format( "%s_gold", techName )
	return lv, techCfg[ techName ], techCfg[needGoldName]
end

function cTechMgr:doTechLvUp( techType )
	local curLevel = self:getTechCurLevel( techType )
	self.curTechLevel[ techType ] = curLevel + 1
end

function cTechMgr:isTechMaxLv( techType )
	return (self:getTechCurLevel( techType ) == FUNC_CONST_MAX_TECH_LEVEL)
end

function cTechMgr:getTechCurLevel( techType )
	return self.curTechLevel[ techType ]
end

function cTechMgr:getTechAtrriShowStr( techType, attriVal )
	if techType == ENUM_TECH_TYPE_FULL_POW_TIME or techType == ENUM_TECH_TYPE_SHEILD_TIME then
		return string.format( "%ss", attriVal )
	else
		return string.format( "%s%%", attriVal * 100 )
	end
end

function cTechMgr:loadData( document )
	self.curTechLevel = {1,1,1,1,1,1}
	for i, v in ipairs( document ) do
		self.curTechLevel[i] = v
	end
end

function cTechMgr:getSaveData()
	return self.curTechLevel
end

return cTechMgr
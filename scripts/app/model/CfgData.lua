require("bdlib/lang/string")
local strFmt = string.format

require("bdlib/tools/Json")
require("bdlib/tools/JsonParser")

CfgData = {}
local allCfgDatas = nil
local batchNodeKeyMap = {}
local batchNodeIdx = 1001
local CFG_ROOT_PATH = "res/config/"

-- 配置名称常数表
CFG_ANIMATION 	= "Animations" 		-- 动画
CFG_UNIT 		= "Units"			-- 单元
CFG_UNIT_AI 	= "UnitAI"			-- 单元AI
CFG_BULLETS_GROUP = "BulletsGroup" 	-- 子弹群组
CFG_GUN 		= "Guns"			-- 枪
CFG_MISSION		= "Missions"
CFG_ENEMYS		= "Enemys"
CFG_DROP        = "Drop"            -- 掉落
CFG_ITEM        = "Item"            -- 道具单元
CFG_PROPS       = "Props"           -- 道具数据
CFG_GUN_LEVLES  = "GunLevels"       -- 枪升级的数组
CFG_PLANE_LEVLES  = "PlaneLevels"   -- 飞机升级的数组
CFG_ENHANCE_LEVLES  = "EnhanceLevels"   -- 飞机升级的数组
CFG_LOGIN_GIFT  = "LoginGift"       -- 登录礼包
CFG_WINGMAN_POS = "WingmanPos"		-- 僚机编队位置相关
CFG_BAG_ITEM 	= "BagItem"			-- 背包物品
CFG_MISSION_VIEW= "MissionView"		-- 普通任务外观
CFG_BOSS_COMPONENT="BossComponent"	-- boss组件
CFG_ACHIVE_ITEM = "AchiveItem"		-- 成就
CFG_LOGINGIFT_ITEM = "LoginGift"	-- 签到
CFG_STORE_ITEM     = "StoreItem"    -- 商城
CFG_LOTTERY_ITEM = "Lottery"		-- 抽奖
CFG_BOSSCHALLENGE = "BossChallenge" -- BOSS挑战
CFG_SPECIAL_VIEW= "SpecialView"		-- 组合特效
CFG_GAME_STRING = "GameString"		-- 游戏字符串
CFG_CONTROL_STRING = "ControlStringMap" --控件字符串相关
CFG_TECH_LEVELS = "TechLevels"		--科技
CFG_UNIT_AI_EX  = "UnitAIEx"		-- 单位扩展AI


-- 所有配置文件的索引
local __cfgs__ = {
	{CFG_ANIMATION,		"Animations.json", 		{{JsonParser.FMT_TYPE_TABLE, "id"}} },

	{CFG_UNIT,			"Units.json", 			{{JsonParser.FMT_TYPE_TABLE, "id"}} },

	{CFG_UNIT_AI,		"UnitAI.json", 			{{JsonParser.FMT_TYPE_TABLE, "id"}, {JsonParser.FMT_TYPE_ARRAY} } },

	{CFG_BULLETS_GROUP,	"BulletsGroup.json", 	{{JsonParser.FMT_TYPE_TABLE, "id"}} },

	{CFG_GUN,			"Guns.json", 			{{JsonParser.FMT_TYPE_TABLE, "id"}} },

	{CFG_MISSION,		"Missions.json", 		{{JsonParser.FMT_TYPE_TABLE, "id"}} },

	{CFG_ENEMYS,		"EnemyGroup.json", 		{{JsonParser.FMT_TYPE_TABLE, "id"},  {JsonParser.FMT_TYPE_ARRAY}} },

    {CFG_DROP,		    "Drops.json", 		    {{JsonParser.FMT_TYPE_TABLE, "id"},  {JsonParser.FMT_TYPE_ARRAY}} },
	{CFG_PROPS,			"Props.json", 			{{JsonParser.FMT_TYPE_TABLE, "id"}} },
	{CFG_ITEM,			"Items.json", 			{{JsonParser.FMT_TYPE_TABLE, "id"}} },
	{CFG_LOGIN_GIFT,	"LoginGift.json", 		{{JsonParser.FMT_TYPE_TABLE, "id"}} },

    {CFG_GUN_LEVLES,	"GunLevels.json", 		{{JsonParser.FMT_TYPE_TABLE, "id"},  {JsonParser.FMT_TYPE_ARRAY}} },

    {CFG_PLANE_LEVLES,	"PlaneLevels.json", 	{{JsonParser.FMT_TYPE_TABLE, "id"},  {JsonParser.FMT_TYPE_ARRAY}} },

    {CFG_ENHANCE_LEVLES,"EnhanceLevels.json", 	{{JsonParser.FMT_TYPE_TABLE, "id"},  {JsonParser.FMT_TYPE_ARRAY}} },
    {CFG_WINGMAN_POS,	"WingmanPos.json", 		{{JsonParser.FMT_TYPE_TABLE, "id"},} },
    {CFG_WINGMAN_POS,	"WingmanPos.json", 		{{JsonParser.FMT_TYPE_TABLE, "id"},} },
    {CFG_BAG_ITEM,		"BagItems.json", 		{{JsonParser.FMT_TYPE_TABLE, "id"},} },
    {CFG_MISSION_VIEW,  "MissionViews.json",	{{JsonParser.FMT_TYPE_TABLE, "id"},} },
    {CFG_BOSS_COMPONENT,"BossComponent.json",   {{JsonParser.FMT_TYPE_TABLE, "id"},} },
    {CFG_ACHIVE_ITEM,	"AchiveItem.json",   	{{JsonParser.FMT_TYPE_TABLE, "id"},} },
    {CFG_LOGINGIFT_ITEM,"LoginGift.json",   	{{JsonParser.FMT_TYPE_TABLE, "id"},} },
    {CFG_STORE_ITEM,	"StoreItem.json",   	{{JsonParser.FMT_TYPE_TABLE, "id"},} },
    {CFG_LOTTERY_ITEM,	"Lottery.json",   		{{JsonParser.FMT_TYPE_TABLE, "id"},} },
    {CFG_BOSSCHALLENGE,	"BossChallenge.json",   {{JsonParser.FMT_TYPE_TABLE, "id"},} },
    {CFG_SPECIAL_VIEW,	"SpecialView.json", 	{{JsonParser.FMT_TYPE_TABLE, "id"},  {JsonParser.FMT_TYPE_ARRAY}} },
    {CFG_GAME_STRING,	"GameString.json",   	{{JsonParser.FMT_TYPE_TABLE, "id"},} },
    {CFG_CONTROL_STRING,"ControlStringMap.json",{{JsonParser.FMT_TYPE_TABLE, "id"},  {JsonParser.FMT_TYPE_ARRAY}} },
    {CFG_TECH_LEVELS,	"TechLevels.json",   	{{JsonParser.FMT_TYPE_TABLE, "id"},} },
    {CFG_UNIT_AI_EX,	"UnitAIEx.json",		{{JsonParser.FMT_TYPE_TABLE, "id"},  {JsonParser.FMT_TYPE_ARRAY}} },
}

function CfgData.load()
    local index = 1
    while CfgData.stepLoad(index) do
        index = index + 1
    end
end

function CfgData.stepLoad(index)

    if index == 1 then
	    JsonParser.setVECTOR_SEP( "|" )

	    local path = CFG_ROOT_PATH
	    local fileName, vars
	    local cfgName, fileNameBase, parseFmt

	    -- 读取Const数据并处理
	    CfgData.loadConst(path)

	    -- 解析配置文件表,装入内存中
	    allCfgDatas = {}

        return false
    elseif index <= #__cfgs__ + 1 then

        local v = __cfgs__[index - 1]
		cfgName = v[1]		-- 配置表名称
		fileNameBase = v[2]	-- 对应的文件名
		parseFmt = v[3]		-- 解析格式

		fileName = strFmt("%s%s", CFG_ROOT_PATH, fileNameBase)

        --local vars = CCFileUtils:sharedFileUtils():loadCfg(fileName)
		local vars = {}
		JsonParser.parseFile( vars, fileName , false, parseFmt)
		allCfgDatas[cfgName] = vars

		--print("fileName", fileName, #vars)
		--Logger.printTable(vars)

        return false

    else
	    -- 组织batchNodeKey以备用
	    local animCfgs = allCfgDatas[CFG_ANIMATION]
	    for _, cfg in pairs(animCfgs) do
		    if cfg.type == 2 then
			    -- 使用plist格式的图片, 需要组织一下batchNodeKey
			    cfg.batchNodeKey = cfg.skeleton .. "" .. cfg.texture
		    else
			    cfg.batchNodeKey = nil
		    end
	    end
	    for _, cfg in pairs(animCfgs) do
	    	if cfg.type == 2 and cfg.batchNodeKey ~= nil then
	    		if batchNodeKeyMap[cfg.batchNodeKey] == nil then
	    			batchNodeKeyMap[cfg.batchNodeKey] = batchNodeIdx * 100000
	    			batchNodeIdx = batchNodeIdx + 1
	    		end
	    		cfg.batchNodeKeyVal = batchNodeKeyMap[cfg.batchNodeKey]
	    	end
	    end
        -- 组织Drops以备用
        local dropCfgs = allCfgDatas[CFG_DROP]
        for _,drop in pairs(dropCfgs) do
            local totalWeight = 0;
            for _, item in pairs(drop) do
                totalWeight = totalWeight + item.weight 
                item.weight = totalWeight
            end
        end

	    -- Logger.printTable(CfgData.getCfgTable( CFG_MISSION ))
    end

    return true

end

-- 获取指定配置的所有配置数据
function CfgData.getCfgTable( cfgName )
	return cfgName and allCfgDatas[ cfgName ]
end

-- 获取指定配置的单条配置数据
function CfgData.getCfg( cfgName, id )
	local vars = cfgName and allCfgDatas[ cfgName ]
	return vars and id and vars[id]
end


-- 读取Const数据并处理
function CfgData.loadConst(cfgRoot)
	local fileName = strFmt("%s%s", cfgRoot, "Const.json")
	local vars = JsonParser.ToStructList( fileName , false)

	for i,v in ipairs(vars) do
		_G[v.name] = JsonParser.Value( v.type, v.value)
	end

	fileName = strFmt("%s%s", cfgRoot, "ConstMapping.json")
	local vars = JsonParser.ToStructList( fileName , false)
	local t, k, vv
	for i,v in ipairs(vars) do
		t = _G[v.name]
		if not t then
			t = {}
			_G[v.name] = t
		end

		k = JsonParser.Value( v.key_type, v.key_value)
		vv = JsonParser.Value( v.value_type, v.value_value)
		t[k] = vv
	end	
end

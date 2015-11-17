--cProps 道具数据，在战斗外存在的数据
--cItem 道具单元，在战斗中屏幕上的一个表现单位

PROPS_TYPE_GOLD = 1             -- 金币:游戏内掉落道具，玩家获得后可直接获得对应金币
PROPS_TYPE_POWER = 2            -- 火力:游戏内掉落道具，玩家获得后可提升战斗内角色等级
PROPS_TYPE_FULL_POWER = 3       -- 爆走:
PROPS_TYPE_BOMB = 4             -- 原子弹:游戏内使用道具，玩家使用后摧毁屏幕内所有地方子弹，并对敌方目标造成5000点伤害
PROPS_TYPE_INVINCIBLE = 5       -- 核子护盾:游戏内使用道具，玩家使用后不受到伤害持续一段时间
PROPS_TYPE_ADSORPTION = 6       -- 吸附:
PROPS_TYPE_DEBRIS = 7           -- 碎片:最终集齐飞机碎片后可花费对应RMB来获得该飞机
PROPS_TYPE_EXP = 8              -- 经验
PROPS_TYPE_DIAMAND = 9          -- 钻石
PROPS_TYPE_MAX__ = 9

PROPS_NEED_PICKED = {PROPS_TYPE_GOLD, PROPS_TYPE_DEBRIS}

local super = nil
cProps = class("cProps")

function cProps:ctor(classify)

    self.classify = classify      -- 分类，参见 'PROPS_TYPE_XXX'
    self.count = 0                -- 个数
    self.icon = 0                 -- 界面上的图标，在Animations.csv里配置
    self.duration = 0             -- 道具效果持续时间，主要用于'爆走'和'核子护盾'
    self.power = 0                -- 道具的威力
    self.soundPick = nil
    self.soundUse = nil
    self.viewPlane = 0            -- 使用时飞机上的表现
    self.offsetX = 0              -- 相对飞机的偏移
    self.offsetY = 0              -- 相对飞机的偏移
    self.viewFullscreen = 0       -- 使用时全屏的表现
    self.screenX = 0              -- 相对屏幕的偏移
    self.screenY = 0              -- 相对屏幕的偏移
    self.funUse = nil             -- 使用函数，如果为nil，则不可使用
    self.funPick = nil            -- 拾取函数

    if classify then
        init(classify)
    end
end

function cProps:useBomb(world)
    if self.count > 0 then
        self.count = self.count - 1
        world:useBomb(self)
        world.plane:showAnimate(self)
        world.plane:propsChanged(self, -1)
        app:propsChanged()

        if self.soundUse then audio.playSound(self.soundUse) end
    end
end

function cProps:useInvncible(world)
    if self.count > 0 then
        self.count = self.count - 1
        local addDuationTime = 0
        local techMgr = app.techMgr
        if techMgr ~= nil then
            local level, addTime = techMgr:getTechInfo( ENUM_TECH_TYPE_SHEILD_TIME )
            if addTime ~= nil and addTime > 0 then
                addDuationTime = addTime
            end
        end
        world.plane:enterInvncible(self.duration + addDuationTime, true, self)
        world.plane:propsChanged(self, -1)
        app:propsChanged()

        if self.soundUse then audio.playSound(self.soundUse) end
    end
end

function cProps:pickMerge(world, classify, count)
    if self.classify == classify then
        self.count = self.count + count
        world.plane:propsChanged(self, count)

        if self.soundPick then audio.playSound(self.soundPick) end
    end
end

function cProps:pickPower(world, classify, count)
    if self.classify == classify then
        world.plane:upgradePower(self.duration, count, self)
        if self.soundPick then audio.playSound(self.soundPick) end
    end
end

function cProps:pickFullPower(world, classify, count)
    if self.classify == classify then
        world.plane:enterFullPower(self.duration, false, self)
        if self.soundPick then audio.playSound(self.soundPick) end
    end
end

function cProps:pickInvncible(world, classify, count)
    if self.classify == classify then
        local addDuationTime = 0
        local techMgr = app.techMgr
        if techMgr ~= nil then
            local level, addTime = techMgr:getTechInfo( ENUM_TECH_TYPE_SHEILD_TIME )
            if addTime ~= nil and addTime > 0 then
                addDuationTime = addTime
            end
        end
        world.plane:enterInvncible(self.duration + addDuationTime, false, self)
        if self.soundPick then audio.playSound(self.soundPick) end
    end
end

function cProps:pickAdsorption(world, classify, count)
    if self.classify == classify then
        world.plane:enterAdsorption(self.duration, false, self)
        if self.soundPick then audio.playSound(self.soundPick) end
    end
end

function cProps:pickBomb(world, classify, count)
    if self.classify == classify then
        world:useBomb(self)
        world.plane:showAnimate(self)
        if self.soundPick then audio.playSound(self.soundPick) end
    end
end

PROPS_USE_METHOD = 
{
    [PROPS_TYPE_BOMB]         =   cProps.useBomb,
    [PROPS_TYPE_INVINCIBLE]   =   cProps.useInvncible,
}

PROPS_PICK_METHOD = 
{
    [PROPS_TYPE_GOLD]         =   cProps.pickMerge,
    [PROPS_TYPE_POWER]        =   cProps.pickPower,
    [PROPS_TYPE_FULL_POWER]   =   cProps.pickFullPower,
    [PROPS_TYPE_BOMB]         =   cProps.pickMerge,
    [PROPS_TYPE_INVINCIBLE]   =   cProps.pickMerge,
    [PROPS_TYPE_ADSORPTION]   =   cProps.pickAdsorption,
    [PROPS_TYPE_DEBRIS]       =   cProps.pickMerge,
    [PROPS_TYPE_EXP]          =   cProps.pickMerge,
    [PROPS_TYPE_DIAMAND]      =   cProps.pickMerge,
}

function cProps:init(classify)

	local cfg = CfgData.getCfg(CFG_PROPS, classify)
	if not cfg then
		return false
	end

    self.classify = classify
    self.count = cfg.initCount
    self.icon = cfg.icon
    self.duration = cfg.duration
    self.power = cfg.power
    self.soundPick = cfg.soundPick
    self.soundUse = cfg.soundUse

    self.viewPlane = cfg.viewPlane
    if cfg.offsetPlane and #cfg.offsetPlane >= 2 then
        self.offsetX = cfg.offsetPlane[1]
        self.offsetY = cfg.offsetPlane[2]
    end

    self.viewFullscreen = cfg.viewFullscreen
    if cfg.offsetScreen and #cfg.offsetScreen >= 2 then
        self.screenX = cfg.offsetScreen[1]
        self.screenY = cfg.offsetScreen[2]
    end

    self.funUse = PROPS_USE_METHOD[classify]
    self.funPick = PROPS_PICK_METHOD[classify]

    return true

end

function cProps:merge(other)

    if self.classify ~= other.classify then
        return false
    end

    self.count = self.count + other.count
    other.count = 0
    return true

end

function cProps:loadData(document)

    if not document then
        return false
    end

    if not self:init(tonumber(document.classify)) then
        return false
    end

    self.count = tonumber(document.count)
    return true

end

function cProps:saveData()
    return {classify = self.classify, count = self.count}
end

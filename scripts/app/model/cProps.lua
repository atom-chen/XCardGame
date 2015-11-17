--cProps �������ݣ���ս������ڵ�����
--cItem ���ߵ�Ԫ����ս������Ļ�ϵ�һ�����ֵ�λ

PROPS_TYPE_GOLD = 1             -- ���:��Ϸ�ڵ�����ߣ���һ�ú��ֱ�ӻ�ö�Ӧ���
PROPS_TYPE_POWER = 2            -- ����:��Ϸ�ڵ�����ߣ���һ�ú������ս���ڽ�ɫ�ȼ�
PROPS_TYPE_FULL_POWER = 3       -- ����:
PROPS_TYPE_BOMB = 4             -- ԭ�ӵ�:��Ϸ��ʹ�õ��ߣ����ʹ�ú�ݻ���Ļ�����еط��ӵ������Եз�Ŀ�����5000���˺�
PROPS_TYPE_INVINCIBLE = 5       -- ���ӻ���:��Ϸ��ʹ�õ��ߣ����ʹ�ú��ܵ��˺�����һ��ʱ��
PROPS_TYPE_ADSORPTION = 6       -- ����:
PROPS_TYPE_DEBRIS = 7           -- ��Ƭ:���ռ���ɻ���Ƭ��ɻ��Ѷ�ӦRMB����ø÷ɻ�
PROPS_TYPE_EXP = 8              -- ����
PROPS_TYPE_DIAMAND = 9          -- ��ʯ
PROPS_TYPE_MAX__ = 9

PROPS_NEED_PICKED = {PROPS_TYPE_GOLD, PROPS_TYPE_DEBRIS}

local super = nil
cProps = class("cProps")

function cProps:ctor(classify)

    self.classify = classify      -- ���࣬�μ� 'PROPS_TYPE_XXX'
    self.count = 0                -- ����
    self.icon = 0                 -- �����ϵ�ͼ�꣬��Animations.csv������
    self.duration = 0             -- ����Ч������ʱ�䣬��Ҫ����'����'��'���ӻ���'
    self.power = 0                -- ���ߵ�����
    self.soundPick = nil
    self.soundUse = nil
    self.viewPlane = 0            -- ʹ��ʱ�ɻ��ϵı���
    self.offsetX = 0              -- ��Էɻ���ƫ��
    self.offsetY = 0              -- ��Էɻ���ƫ��
    self.viewFullscreen = 0       -- ʹ��ʱȫ���ı���
    self.screenX = 0              -- �����Ļ��ƫ��
    self.screenY = 0              -- �����Ļ��ƫ��
    self.funUse = nil             -- ʹ�ú��������Ϊnil���򲻿�ʹ��
    self.funPick = nil            -- ʰȡ����

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

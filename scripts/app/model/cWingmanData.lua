
cWingmanData = class("cWingmanData")

function cWingmanData:ctor(planeId)
	self.id = 0                 --僚机ID
    self.level = 1              --初始等级
    self.maxLevel = 1           --最高等级
    self.nextHurt = 0			--下一级的攻击力
    self.showHurt = 0           --显示的主机攻击力
    self.maxHurt = 0            --飞机升级到顶的攻击力
    self.quality = 1			--僚机品质
    self.formationOpen = {1,0,0}--开启的阵型
    self:initById( planeId )
end

function cWingmanData:initById( planeId, conf )
	local levels = CfgData.getCfg(CFG_PLANE_LEVLES, planeId)
    if not levels then
        return false
    end

    local lvl
    if conf ~= nil then
        lvl = tonumber(conf.level) or 1
        if lvl > #levels then
            lvl = #levels
        end
        self.quality = tonumber(conf.quality) or 1
        self.formationOpen = conf.formationOpen
    else
        lvl = 1
        self.quality = 1
        self.formationOpen = {1,0,0}
    end
    self.levelCfg = levels
    self.id = planeId
    self.level = lvl
    local qualityMaxLv = PLANE_QUALITY_LEVEL[self.quality]
    self.maxLevel = qualityMaxLv

    local data = levels[lvl]
    local nextData = levels[lvl + 1]
    if not nextData then nextData = data end

    self.hp = data.hp or 0
    self.nextHP = nextData.hp or 0
    self.hurt = data.hurt or {x = 0, y = 0}
    self.showHurt = data.showHurt or 0
    self.nextHurt = nextData.showHurt or 0

    local maxData = levels[self.maxLevel]
    self.maxHP = maxData.hp or 0
    self.maxHurt = maxData.showHurt or 0

    return true
end

function cWingmanData:addLevel()
	local levels = self.levelCfg
    local lvl = self.level
    if not levels or lvl >= self.maxLevel then
        return false
    end

    lvl = lvl + 1
    self.level = lvl

    local data = levels[lvl]
    local nextData = levels[lvl + 1]
    if not nextData then nextData = data end

    self.hp = data.hp or 0
    self.nextHP = nextData.hp or 0
    self.hurt = data.hurt or {x = 0, y = 0}
    self.showHurt = data.showHurt or 0
    self.nextHurt = nextData.showHurt or 0
    self.wingmanHurt = data.wingmanHurt or {x = 0, y = 0}

    return true
end

function cWingmanData:isMaxLevel()
    local levels = self.levelCfg
    return not levels or self.level >= self.maxLevel
end

function cWingmanData:getWingmanNum()
    local wingmanNum = 0
    for i, v in ipairs( self.formationOpen ) do
        if v == 1 then
            wingmanNum = wingmanNum + 2
        end
    end
    return wingmanNum
end

function cWingmanData:getFormationOpenInfo()
    local tOpenedFormations = {}
    local unitCfg = CfgData.getCfg(CFG_UNIT, self.id )
    if unitCfg ~= nil and unitCfg.params1 ~= nil and unitCfg.params2 ~= nil then
        for i, v in ipairs( self.formationOpen ) do
            if v == 1 then
                table.insert( tOpenedFormations, unitCfg.params1[i] )
            end
        end
    end
    return tOpenedFormations
end

function cWingmanData:addQuality( quality )
	if self.quality < #PLANE_QUALITY_LEVEL then
        self.quality = self.quality + 1
        local qualityMaxLv = PLANE_QUALITY_LEVEL[self.quality]
        self.maxLevel = qualityMaxLv
        local levels = self.levelCfg
        if levels ~= nil then
	       	local maxData = levels[self.maxLevel]
	    	self.maxHP = maxData.hp or 0
	    	self.maxHurt = maxData.showHurt or 0
	    end
        return true
    end
    return false
end

function cWingmanData:getQuality()
	return self.quality
end

function cWingmanData:isMaxQuality()
	return (self.quality == #PLANE_QUALITY_LEVEL)
end

function cWingmanData:saveData()
    return {id = self.id, level = self.level, quality = self.quality, formationOpen = self.formationOpen }
end

function cWingmanData:loadData(document)
    if not document then
        return false
    end

    if not self:initById(tonumber(document.id), document ) then
        return false
    end
    return true
end

function cWingmanData:lvUpNeedExp()
    local levels = self.levelCfg
    local lvl = self.level
    if not levels or lvl >= #levels then
        return 0
    end

    local data = levels[lvl + 1]
    return data.needExp
end

function cWingmanData:lvUpNeedGold()
    local levels = self.levelCfg
    local lvl = self.level
    if not levels or lvl >= #levels then
        return 0
    end

    local data = levels[lvl + 1]
    return data.needGold
end

function cWingmanData:getQualityUpMaterial()
    local levels = self.levelCfg
    local lvl = PLANE_QUALITY_LEVEL[self.quality]
    local data = levels[lvl + 1]
    if data ~= nil then
        return data.lvUpItems, data.lvUpItemCount
    end
end

return cWingmanData
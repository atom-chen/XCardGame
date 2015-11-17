
cPlaneData = class("cPlaneData")

function cPlaneData:ctor(planeId)

    self.id = 0                 --·É»úID
    self.level = 1              --³õÊ¼µÈ¼¶
    self.quality = 1            --³õÊ¼Æ·ÖÊ
    self.maxLevel = 1           --×î¸ßµÈ¼¶

    self.hp = 0                 --·É»úµÄÉúÃüÖµ
    self.nextHP = 0
    self.maxHP = 0              --·É»úÉý¼¶µ½¶¥µÄÉúÃüÖµ
    self.hurt = {x = 0, y = 0}  --Ö÷»úµÄ¹¥»÷Á¦
    self.nextHurt = 0
    self.showHurt = 0           --ÏÔÊ¾µÄÖ÷»ú¹¥»÷Á¦
    self.maxHurt = 0            --·É»úÉý¼¶µ½¶¥µÄ¹¥»÷Á¦
    self.wingmanHurt = {x = 0, y = 0}        --ÁÅ»úµÄ¹¥»÷Á¦
    self.showWingmanHurt = 0    --ÏÔÊ¾µÄÁÅ»ú¹¥»÷Á¦
    self.nextWingmanHurt = 0
    self.maxWingmanHurt = 0     --·É»úÉý¼¶µ½¶¥Ê±ÁÅ»úµÄ¹¥»÷Á¦

    self.enhanceLevel =         --Ç¿»¯µÄµÈ¼¶
    {
        hurt = 0,               --»ðÁ¦ÌáÉý£ºÊÇÖ¸±©×ß×´Ì¬ÏÂµÄ×Óµ¯ÉËº¦¼Ó³É
        duration = 0,           --±©×ßÊ±³¤£ºÊÇÖ¸±©×ßÊ±¼ä¼Ó³¤
        gun = 0,                --×ÛºÏ±©×ß£ºÊÇÖ¸¸ü»»Ç¹Ö§
        gold = 0                --½ð±Ò¼Ó³É£ºÊÇÖ¸±©×ß×´Ì¬ÏÂ»ñµÃµÄ½ð±Ò¼Ó³É
    }
    self.enhancePower =         --Ç¿»¯µÄÊýÖµ
    {
        hurt = {x = 0, y = 0},               --»ðÁ¦ÌáÉý£ºÊÇÖ¸±©×ß×´Ì¬ÏÂµÄ×Óµ¯ÉËº¦¼Ó³É
        duration = {x = 0, y = 0},           --±©×ßÊ±³¤£ºÊÇÖ¸±©×ßÊ±¼ä¼Ó³¤
        gun = {x = 0, y = 0},                --×ÛºÏ±©×ß£ºÊÇÖ¸¸ü»»Ç¹Ö§
        gold = {x = 0, y = 0}                --½ð±Ò¼Ó³É£ºÊÇÖ¸±©×ß×´Ì¬ÏÂ»ñµÃµÄ½ð±Ò¼Ó³É
    }

    self.levelCfg = nil
    self.enhanceCfg = nil
    self.mechCoreSlot = { 0, -1, -1, -1 }  --»ú¼×ºËÐÄ
    if planeId then
        self:initById(planeId, nil)
    end
end

function cPlaneData:initById(planeId, conf )
    local levels = CfgData.getCfg(CFG_PLANE_LEVLES, planeId)
    if not levels then
        return false
    end

    local lvl
    if conf then
        lvl = tonumber(conf.level) or 1
        if lvl > #levels then
            lvl = #levels
        end
        self.quality = tonumber(conf.quality) or 1
        self.mechCoreSlot = conf.mechCoreSlot or { 0, -1, -1, -1 }
    else
        lvl = 1
        self.quality = 1
        self.mechCoreSlot = { 0, -1, -1, -1 }
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
    self.wingmanHurt = data.wingmanHurt or {x = 0, y = 0}
    self.showWingmanHurt = data.showWingmanHurt or 0
    self.nextWingmanHurt = nextData.showWingmanHurt or 0
    local maxData = levels[self.maxLevel]
    self.maxHP = maxData.hp or 0
    self.maxHurt = maxData.showHurt or 0
    self.maxWingmanHurt = maxData.showWingmanHurt or 0

    self.enhanceCfg = CfgData.getCfg(CFG_ENHANCE_LEVLES, planeId)
    self:updateEnhance()

    return true
end

function cPlaneData:addLevel()
    local levels = self.levelCfg
    local lvl = self.level
    if not levels or lvl >= self.maxLevel then
        return false
    end

    lvl = lvl + 1
    self.level = lvl

    app.achive:checkAchive("level", self.level)                           ---------¡¾³É¾Í¡¿

    local data = levels[lvl]
    local nextData = levels[lvl + 1]
    if not nextData then nextData = data end

    self.hp = data.hp or 0
    self.nextHP = nextData.hp or 0
    self.hurt = data.hurt or {x = 0, y = 0}
    self.showHurt = data.showHurt or 0
    self.nextHurt = nextData.showHurt or 0
    self.wingmanHurt = data.wingmanHurt or {x = 0, y = 0}
    self.showWingmanHurt = data.showWingmanHurt or 0
    self.nextWingmanHurt = nextData.showWingmanHurt or 0

    return true
end

function cPlaneData:isMaxLevel()
    local levels = self.levelCfg
    return not levels or self.level >= self.maxLevel
end

function cPlaneData:addQuality()
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

function cPlaneData:isMaxQuality()
    return self.quality == #PLANE_QUALITY_LEVEL
end

function cPlaneData:getMechCoreSlotData()
    return self.mechCoreSlot
end

function cPlaneData:openAMechCoreSlot()
    for i, v in ipairs( self.mechCoreSlot ) do
        if v == -1 then
            self.mechCoreSlot[i] = 0
            return
        end
    end
end

function cPlaneData:getOpenMechCoreSlotCount()
    local count = 0
    for i, v in ipairs( self.mechCoreSlot ) do
        if v ~= -1 then
            count = count + 1
        end
    end
    return count
end

function cPlaneData:checkHaveSameTypeMechCore( itemId )
    local addItemConf = CfgData.getCfg( CFG_BAG_ITEM, itemId )
    if addItemConf == nil then
        return
    end
    for i, v in ipairs( self.mechCoreSlot ) do
        if v > 0 then
            local mechCoreItem = CfgData.getCfg( CFG_BAG_ITEM, v )
            if mechCoreItem ~= nil then
                if mechCoreItem.subType == addItemConf.subType then
                    return true
                end
            end
        end
    end
    return false
end

function cPlaneData:equipMechCore( itemId )
    for i, v in ipairs( self.mechCoreSlot ) do
        if v == 0 then
            self.mechCoreSlot[i] = itemId
            return
        end
    end
end

function cPlaneData:unEquipMechCore( itemId )
    local tKeepedCoreSlot = {}
    for i, v in ipairs( self.mechCoreSlot ) do
        if v ~= itemId and v ~= -1 then
            table.insert( tKeepedCoreSlot, v )
        end
    end
    for i = 1, 4 do
        if self.mechCoreSlot[i] ~= -1 then
            self.mechCoreSlot[i] = tKeepedCoreSlot[i] or 0
        end
    end
end

function cPlaneData:lvUpNeedExp()
    local levels = self.levelCfg
    local lvl = self.level
    if not levels or lvl >= #levels then
        return 0
    end

    local data = levels[lvl + 1]
    return data.needExp
end

function cPlaneData:lvUpNeedGold()
    local levels = self.levelCfg
    local lvl = self.level
    if not levels or lvl >= #levels then
        return 0
    end

    local data = levels[lvl + 1]
    return data.needGold
end

function cPlaneData:getQualityUpMaterial()
    local levels = self.levelCfg
    local lvl = PLANE_QUALITY_LEVEL[self.quality]
    local data = levels[lvl + 1]
    if data ~= nil then
        return data.lvUpItems, data.lvUpItemCount
    end
end


function cPlaneData:updateEnhance()

    local cfg = self.enhanceCfg
    if not cfg then
        return false
    end

    local enhanceLevel = self.enhanceLevel
    local power = self.enhancePower
    local lvl

    lvl = cfg[enhanceLevel.hurt + 1]
    power.hurt = lvl.en_hurt

    lvl = cfg[enhanceLevel.duration + 1]
    power.duration = lvl.en_duration

    lvl = cfg[enhanceLevel.gun + 1]
    power.gun = lvl.en_gun

    lvl = cfg[enhanceLevel.gold + 1]
    power.gold = lvl.en_gold
end

function cPlaneData:getEnhanceData(name)
    local cfg = self.enhanceCfg
    if not cfg then
        return nil
    end
    local level = self.enhanceLevel[name]
    if not level then
        return nil
    end
    local enhance = cfg[level + 1]
    if not enhance then
        return nil
    end

    local power = enhance["en_" .. name]
    local cost = enhance["cost_" .. name]
    local descript = enhance["desc_" .. name]
    
    return {level = level, power = power, cost = cost, descript = descript}
end

function cPlaneData:enhanceByName(name)
    local level = self.enhanceLevel[name]
    if not level or level >= 5 then
        return false
    end

    self.enhanceLevel[name] = level + 1
    self:updateEnhance()
    
    return true
end

function cPlaneData:saveData()
    return {id = self.id, level = self.level, enhance = self.enhanceLevel, quality = self.quality, mechCoreSlot = self.mechCoreSlot }
end

function cPlaneData:loadData(document)
    if not document then
        return false
    end

    -- Logger.printTable(document)

    local enhance = document.enhance
    if not enhance then
        return false
    end

    if not self:initById(tonumber(document.id), document ) then
        return false
    end

    local target = self.enhanceLevel

    target.hurt = tonumber(enhance.hurt)
    target.duration = tonumber(enhance.duration)
    target.gun = tonumber(enhance.gun)
    target.gold = tonumber(enhance.gold)

    self:updateEnhance()

    return true
end

return cPlaneData

require("config")
require("publish_config")
require("framework.init")
require("app.myuiloader")
require("app.myaudio")

require("app.TestTools")
require("app._GVars")
require("app.model.cProps")
require("app.model.CfgData")
require("app.model.cPlaneData")
require("app.model.cWingmanData")

require("app.ui.UIBaseClass")
require("app.ui.UIManager")

require("app.scenes.SceneBaseClass")
require("app.scenes.SceneManager")

local userDefault = CCUserDefault:sharedUserDefault()
local MyApp = class("MyApp", cc.mvc.AppBase)

local PaymengDefense = import("app/ui/PaymengDefense")
local ConfirmStore = import("app/ui/confirmStore")
local UIManager = import("app/ui/UIManager")
local SceneManager = import("app/scenes/SceneManager")
local cBag = import( "app/model/cBag" )
local cAchive = import( "app/model/cAchive")
local cStore = import( "app/model/cStore")
local cLoginGift = import( "app/model/cLoginGift")
local cLotteryEnter = import("app/model/cLotteryEnter")
local cLotteryMain = import("app/model/cLotteryMain")
local cBossChallenge = import("app/model/cBossChallenge")
local cTechMgr = import("app/model/cTechMgr")

local SAVE_FILE_PROPS = "props.json"
local SAVE_FILE_PLANES = "planes.json"
local SAVE_FILE_WINGMANS = "wingmans.json"
local SAVE_FILE_GUIDES = "guide.json"
local SAVE_FILE_MISSIONS = "missions.json"
local SAVE_FILE_ITEMS = "items.json"
local SAVE_FILE_ACHIVE = "achive.json"
local SAVE_FILE_LOGIN = "loginday.json"
local SAVE_FILE_LOTTERY = "lottery.json"
local SAVE_FILE_TECH = "tech.json"

function MyApp:ctor()
    MyApp.super.ctor(self)

    MyApp.packageRoot = "app"
    MyApp.planeId = 20001
    MyApp.missionIndex = userDefault:getIntegerForKey("MissionIndex", 1)
    MyApp.showLoginGift = true

    MyApp.curWingmanPlaneId = 20101

    MyApp.gameLanguage = "CH"

    MyApp.planesIds = { 20001, 20002, 20003, 20004 }

    MyApp.wingmanIds = { 20101, 20102, 20103, 20104 }

    MyApp.curSelFormation = 1

    MyApp.propsData = {}

    MyApp.planeDatas = {}

    MyApp.wingmanDatas = {}

    MyApp.guideDatas = {}

    MyApp.missionData = {}

    MyApp.uiManager = UIManager:getInstance()
    MyApp.sceneManager = SceneManager:getInstance()
    MyApp.bag = cBag:getInstance()
    MyApp.achive = cAchive:getInstance()
    MyApp.store = cStore:getInstance()
    MyApp.logingift = cLoginGift:getInstance()
    MyApp.lotteryEnter = cLotteryEnter:getInstance()
    MyApp.lotteryMain = cLotteryMain:getInstance()
    MyApp.bosschallenge = cBossChallenge:getInstance()
    MyApp.techMgr = cTechMgr:getInstance()
end

function MyApp:run()
    local sharedFileUtils = CCFileUtils:sharedFileUtils()
    sharedFileUtils:addSearchPath("res/")

    self.sceneManager:enterScene("SceneSplash")
end

function MyApp:enterMainMenu()
    return self.sceneManager:enterScene("SceneMainMenu", nil, nil, 0.6, display.COLOR_BLACK)
end

function MyApp:enterChoiceMission(planeId)
    local data = self.planeDatas[planeId]
    if not data then
        return nil
    end

    self.planeId = planeId
    return self.sceneManager:enterScene("NewSceneChoiceMission", nil, nil, 0.6, display.COLOR_BLACK)
end

function MyApp:enterSelectPlane()
    return self.sceneManager:enterScene("NewSceneSelectPlane", nil, nil, 0.6, display.COLOR_BLACK)
end

function MyApp:enterSceneGunEffect()
    return self.sceneManager:enterScene("SceneGunEffect", nil, nil, 0.6, display.COLOR_BLACK);
end

function MyApp:playMissionByIndex(missionIndex, missData)
    return self.sceneManager:enterScene("NewSceneGame", {missionIndex,missData}, nil, 0.6, display.COLOR_BLACK)
end

function MyApp:enterLoginGift()
    -- 如果已经显示过登录礼包界面,不再显示
    if not self.showLoginGift then
        return false
    end

    local plane = self.planeDatas[20004]
    if plane then
        return false
    end

    -- 检查上一次登录的天数
    local lastDays = userDefault:getIntegerForKey("LastLoginDays", 0)
    local currentDays = math.floor(os.time() / 86400)
    if currentDays <= lastDays then
        return false
    end

    -- 检查已经领取过几天了
    local days = userDefault:getIntegerForKey("LoginedDays", 0)
    days = days + 1
    if days <= 0 or days > 7 then
        return false
    end

    -- 每次启动只显示一次
    self.showLoginGift = false

    if not scene then
        scene = display.getRunningScene()
    end

    self.sceneManager:enterScene("SceneLoginGift", {days}, "fade", 0.6, display.COLOR_BLACK)

    return true
end

function MyApp:receiveLoginGift(days)

    local giftCfg = CfgData.getCfg(CFG_LOGIN_GIFT, days)
    if giftCfg then
        -- 检查上一次登录的天数
        local lastDays = userDefault:getIntegerForKey("LastLoginDays", 0)
        local currentDays = math.floor(os.time() / 86400)
        if currentDays <= lastDays then
            return 
        end

        userDefault:setIntegerForKey("LastLoginDays", currentDays)
        userDefault:setIntegerForKey("LoginedDays", days)

        local gift_props, gift_counts
        if app.planeDatas[20004] ~= nil then
            gift_props = giftCfg.props_gold
            gift_counts = giftCfg.counts_gold
        else
            gift_props = giftCfg.props
            gift_counts = giftCfg.counts
        end

        for index, classify in ipairs(gift_props) do

            local props = self.propsData[classify]
            local count = gift_counts[index] or 0
            if props and count > 0 then
                props.count = props.count + count
            end

        end -- for index, classify in ipairs(giftCfg.props) do

        self:propsChanged()

    end -- if giftCfg then

end

function MyApp:openStoreBomb(scene)
    self:rechargeById(3)
end

function MyApp:openStoreInvincible(scene)
    self:rechargeById(4)
end

function MyApp:showConfirmStore(store, callback, scene)
    if not scene then
        scene = display.getRunningScene()
    end

    local msgLayer = ConfirmStore.new(store, callback)
    scene:addChild(msgLayer, UZ_UI_1 + 99999)
    return msgLayer
end

function MyApp:loadCCSJsonFile(scene, jsonFile , point)
    local node, width, height = cc.uiloader:load(jsonFile)
    if node then
        node:setPosition(point)
        scene:addChild(node)

        -- dumpUITree(node)
        -- drawUIRegion(node, scene, 6)
        return node
    end

    return nil
end


function MyApp:loadProps()

    local document = CCFileUtils:sharedFileUtils():loadXml(SAVE_FILE_PROPS)
    if not document then
        return false
    end

    local count = 0
    for _, item in pairs(document) do
        local i = cProps.new(nil)
        if i:loadData(item) then
            self.propsData[i.classify] = i
            count = count + 1
        end
    end

    return count > 0
end

function MyApp:saveProps()
    local document = {}
    for _, i in pairs(self.propsData) do
        table.insert(document, i:saveData())
    end
    return CCFileUtils:sharedFileUtils():saveXml(SAVE_FILE_PROPS, document)
end

function MyApp:initProps()
    for classify=1, PROPS_TYPE_MAX__ do
        local i = cProps.new(nil)
        if i:init(classify) then
            self.propsData[classify] = i
        end
    end
end


function MyApp:loadGuide()
    local document = CCFileUtils:sharedFileUtils():loadXml(SAVE_FILE_GUIDES)
    if not document then
        document = {}
    end
    self.guideDatas = document
end

function MyApp:saveGuide()
    CCFileUtils:sharedFileUtils():saveXml(SAVE_FILE_GUIDES, self.guideDatas)
end

function MyApp:countOfGold()
    local gold = self.propsData[PROPS_TYPE_GOLD]
    if not gold then return 0 end
    return gold.count or 0
end

function MyApp:modifyGold(count)
    return self:modifyProps(PROPS_TYPE_GOLD, count)
end

function MyApp:countOfDiamond()
    local dimond = self.propsData[PROPS_TYPE_DIAMAND]
    if not dimond then return 0 end
    return dimond.count or 0
end

function MyApp:modifyDiamond(count)
    return self:modifyProps(PROPS_TYPE_DIAMAND, count)
end

function MyApp:countOfExp()
    local exp = self.propsData[PROPS_TYPE_EXP]
    if not exp then return 0 end
    return exp.count or 0
end

function MyApp:modifyExp(count)
    return self:modifyProps(PROPS_TYPE_EXP, count)
end

function MyApp:modifyProps(classify, count)
    local gold = self.propsData[classify]
    if not gold then return false end

    local total_count = gold.count + count
    if total_count < 0 then return false end
    
    gold.count = total_count
    self.achive:checkAchive("gold", gold.count)                          ----------【成就】
    self:propsChanged()
    return true
end

function MyApp:getPropCount( classify )
    local props = self.propsData[classify]
    if props ~= nil then
        return props.count
    end
    return 0
end


function MyApp:propsChanged()
    self:saveProps()
    self:dispatchEvent({name="PROPS_NUMBER_CHANGED"})
end


function MyApp:loadPlaneData()
    self.planeDatas = {}

    local document = CCFileUtils:sharedFileUtils():loadXml(SAVE_FILE_PLANES)
    if not document then
        return false
    end

    local count = 0
    for _, item in pairs(document) do
        local plane = cPlaneData.new(nil)
        if plane:loadData(item) then
            self.planeDatas[plane.id] = plane
            count = count + 1
        end
    end

    return count > 0
end

function MyApp:savePlaneData()

    local document = {}
    for _, plane in pairs(self.planeDatas) do
        table.insert(document, plane:saveData())
    end

    return CCFileUtils:sharedFileUtils():saveXml(SAVE_FILE_PLANES, document)
end

function MyApp:initPlaneData()
    self.planeDatas = {}

    for i, id in ipairs( self.planesIds ) do
        local levels = CfgData.getCfg(CFG_PLANE_LEVLES, id)
        if levels ~= nil then
            local lv1Data = levels[1] 
            if lv1Data ~= nil and lv1Data.initOpen == 1 then
                local planeData = cPlaneData.new(id)
                self.planeDatas[id] = planeData
            end
        end
    end 
end

function MyApp:buyPlane(planeId)
    local plane = cPlaneData.new(nil)
    if plane:initById(planeId, nil) then
        self.planeDatas[planeId] = plane
    else
        plane = nil
    end

    return plane
end

function MyApp:loadWingmanData()
    self.wingmanDatas = {}
    local document = CCFileUtils:sharedFileUtils():loadXml(SAVE_FILE_WINGMANS)
    if not document then
        return false
    end

    local count = 0
    for _, item in pairs(document) do
        local wingmanPlane = cWingmanData.new(nil)
        if wingmanPlane:loadData(item) then
            self.wingmanDatas[wingmanPlane.id] = wingmanPlane
            count = count + 1
        end
    end

    return count > 0
end

function MyApp:saveWingmanData()
    local document = {}
    for _, wingmanPlane in pairs(self.wingmanDatas) do
        table.insert(document, wingmanPlane:saveData())
    end
    return CCFileUtils:sharedFileUtils():saveXml(SAVE_FILE_WINGMANS, document)
end

function MyApp:initWingmanData()
    self.wingmanDatas = {}
    for i, id in ipairs( self.wingmanIds ) do
        local levels = CfgData.getCfg(CFG_PLANE_LEVLES, id)
        if levels ~= nil then
            local lv1Data = levels[1] 
            if lv1Data ~= nil and lv1Data.initOpen == 1 then
                local planeData = cWingmanData.new(id)
                self.wingmanDatas[id] = planeData
            end
        end
    end 
end

function MyApp:buyWingman( winmanPlaneId )
    local wingManPlane = cWingmanData.new(nil)
    if wingManPlane:initById( winmanPlaneId, nil ) then
        self.wingmanDatas[ winmanPlaneId ] = wingManPlane
    else
        wingManPlane = nil
    end
    return wingManPlane
end

function MyApp:loadMissionData()
    self.missionData = { missStatuData = {}, curLockMissId = 1 }
    local statuData = self.missionData.missStatuData
    local document = CCFileUtils:sharedFileUtils():loadXml(SAVE_FILE_MISSIONS)
    if document ~= nil then
        if document.missStatuData ~= nil then
            for i, v in ipairs( document.missStatuData ) do
                self.missionData.missStatuData[i] = v
            end
        end
        self.missionData.curLockMissId = document.curLockMissId or 1
    end
    if statuData[1] == nil then
        statuData[1] = { maxScrore = 0, todayFinishTime = 0, passed = false }
    end
end

--获得战斗力(策划暂定规则  攻击*生命/100*  ((1 -（当前飞机等级+僚机等级）/2) %）)
function MyApp:getCombatPow()
    local powVal = 0
    local planeData = app.planeDatas[app.planeId]
    local wingmanData = app.wingmanDatas[app.curWingmanPlaneId]
    if planeData ~= nil and wingmanData ~= nil then
        local planeHurt = planeData.hurt
        local planeLevel = planeData.level
        local planeHp = planeData.hp
        local wingmanLevel = wingmanData.level
        powVal = ((planeHurt * planeHp) ) * (1 - (((planeLevel + wingmanLevel)/2)/ 100) )
    end
    return powVal
end

function MyApp:saveMissionData()
    return CCFileUtils:sharedFileUtils():saveXml(SAVE_FILE_MISSIONS, self.missionData )
end

function MyApp:getCurLockMissId()
    return self.missionData.curLockMissId
end

function MyApp:loadTechData()
    local document = CCFileUtils:sharedFileUtils():loadXml(SAVE_FILE_TECH)
    if document ~= nil then
        self.techMgr:loadData( document )
    end
end

function MyApp:saveTechData()
    return CCFileUtils:sharedFileUtils():saveXml(SAVE_FILE_TECH, self.techMgr:getSaveData() )
end

function MyApp:missionCompleted( missionViewData )
    if missionViewData == nil then
        return
    end
    local missionId = missionViewData.id
    local statuData = self.missionData.missStatuData
    if statuData ~= nil then
        local tMissData = statuData[missionId]
        if tMissData ~= nil then
            tMissData.todayFinishTime = tMissData.todayFinishTime + 1 
            tMissData.passed = true
        else
            statuData[missionId] = { maxScrore = 0, todayFinishTime = 1, passed = true  }
        end
    end
    if missionId == self.missionData.curLockMissId then --解锁关卡
        self.achive:checkAchive("mission", missionId)               ---------------【成就】
        self.missionData.curLockMissId = missionId + 1
        statuData[missionId+1] = { maxScrore = 0, todayFinishTime = 0, passed = false  }
    end
    self:saveMissionData()
end

function MyApp:getMissStatu( missionId )
    local statuData = self.missionData.missStatuData
    if statuData ~= nil then
        return statuData[missionId]
    end
end

function MyApp:loadItemsData()
    local document = CCFileUtils:sharedFileUtils():loadXml(SAVE_FILE_ITEMS)
    if document ~= nil then
        for i, v in ipairs( document ) do
             self.bag:addItemById( v.ItemId, v.ItemCount )
        end
    end
end

function MyApp:saveItemsData()
    local document = {}
    local tAllItems = self.bag:getAllItems()
    if tAllItems ~= nil then
        for _, itemData in ipairs(tAllItems) do
            table.insert(document, itemData:getItemSaveData())
        end
    end
    return CCFileUtils:sharedFileUtils():saveXml(SAVE_FILE_ITEMS, document)
end

function MyApp:loadLoginData()
    local document = CCFileUtils:sharedFileUtils():loadXml(SAVE_FILE_LOGIN)
    if document ~= nil then
        self.logingift:setLogindays(document[1])
        self.logingift:setLoginDay(document[2])
        self.logingift:setFirstLogall(document[3])
    end
end

function MyApp:saveLoginData()
    local document = {}
    local idays = self.logingift:getLogindays()
    local ilastDay = self.logingift:getLoginDay()
    local ifirstlogall = self.logingift:getFirstLogall()
    if idays ~= nil then
        table.insert(document,idays)
        table.insert(document,ilastDay)
        table.insert(document,ifirstlogall)
    end
    return CCFileUtils:sharedFileUtils():saveXml(SAVE_FILE_LOGIN, document)
end

function MyApp:loadAchiveData()
    local document = CCFileUtils:sharedFileUtils():loadXml(SAVE_FILE_ACHIVE)
    self.achive:initAchive()
    if document ~= nil then
        for i, v in ipairs( document ) do
            local docAchive = self.achive:creatAchiveById(v.id)
            docAchive.isFinish = "TRUE"
            docAchive.isGet = "TRUE"
            table.insert(self.achive.tAchiveData, docAchive)
            local change = self.achive:findAchiveById(v.id)
            change.isFinish = v.isFinish
            change.isGet = v.isGet
        end
    end
end

function MyApp:saveAchiveData()
    local document = {}
    local tAchiveData = self.achive:getAchiveData()
    if tAchiveData ~= nil then
        for _, itemData in ipairs(tAchiveData) do
            table.insert(document, itemData:getSaveData())
        end
    end
    return CCFileUtils:sharedFileUtils():saveXml(SAVE_FILE_ACHIVE, document)
end

function MyApp:loadIFreeLottery()
    local document = CCFileUtils:sharedFileUtils():loadXml(SAVE_FILE_LOTTERY)
    if document ~= nil then
        self.lotteryEnter:setGoldFreeTime(document[1])
        self.lotteryEnter:setDiamFreeTime(document[2])
    end
end

function MyApp:saveFreeLottery()
    local document = {}
    table.insert(document,self.lotteryEnter:getGoldFreeTime())
    table.insert(document,self.lotteryEnter:getDiamFreeTime())
    return CCFileUtils:sharedFileUtils():saveXml(SAVE_FILE_LOTTERY, document)
end

function MyApp:getReward( Itemtype,Itemid,counts )
    if Itemtype == "gold" then
        self:modifyGold( counts )
    elseif Itemtype == "diamond" then
        self:modifyDiamond( counts )
    elseif Itemtype == "property" then
        self.bag:addItemById(Itemid,counts)
        self:saveItemsData()
    elseif Itemtype == "plane" then
        self:buyPlane(vItemid)
        self:savePlaneData()
    elseif Itemtype == "wingman" then
        self:buyWingman(Itemid)
        self:saveWingmanData()
    end
    local uiSelectPlane = app.uiManager:getUIByName( "UISelectPlane" )
    if uiSelectPlane ~= nil then
        uiSelectPlane:updatePropsCount()
    end
end

function MyApp:rechargeMainstay(callback)
    local id = 15

    local debris_count = 0
    local debris_props = self.propsData[PROPS_TYPE_DEBRIS]
    if debris_props then
        debris_count = debris_props.count
    end

    if debris_count < 7 then
        id = id + 7 - debris_count
    end

    local stores = CfgData.getCfg(CFG_STORES, id)
    if not stores then
        self:showMessage("未知的商品编号("..id..")")
        return
    end

    self:rechargeCallback(id, function(result, remain) 
        if result == 0 then
            if self:buyPlane(20004) then

                if debris_props then
                    debris_props.count = 0
                end
                app:savePlaneData()

                if callback then
                    callback()
                end

            end
        elseif result < 0 then
            self:showMessage(remain)
        end
    end)

end

function MyApp:rechargeById(id)
    local stores = CfgData.getCfg(CFG_STORES, id)
    if not stores then
        self:showMessage("未知的商品编号("..id..")")
        return
    end

    self:rechargeCallback(id, function(r, remain) self:onRechargeResult(id, r, remain) end)
end

function MyApp:rechargeCallback(id, callback)

    if true then
        local pdLayer = PaymengDefense.new()

        local scene = display.getRunningScene()
        scene:addChild(pdLayer,UZ_UI_1 + 999)

        pdLayer:pay(id, callback)
    else
        local stores = CfgData.getCfg(CFG_STORES, id)
        if not stores then
            self:showMessage("未知的商品编号("..id..")")
            return
        end

        if not _1sdk then

            self:showConfirmStore(stores, function(ok) 
                if ok then
                    callback(0, "")
                else
                    callback(1, "用户取消了支付")
                end
            end)

            return 
        end

        _1sdk.getInstance():pay(id, callback)
    end

end

function MyApp:onRechargeResult(id, result, remain)
    --self:showMessage("MyApp:onRechargeResult: id = " .. id .. ", result = " .. result)

    if result == 0 then

        if id == 1 then
            --新手礼包购买完成
            userDefault:setBoolForKey("RechargedGiftNew", true)
        end

        local stores = CfgData.getCfg(CFG_STORES, id)
        if stores then
            local items_count = #stores.items

            for index = 1, items_count do
                local props_classify = stores.items[index]
                local props_count = stores.counts[index] or 1

                local probes = self.propsData[props_classify]
                if probes then
                    probes.count = probes.count + props_count
                end
            end

            self:propsChanged()
        end
    elseif result < 0 then
        self:showMessage(remain)
    end 
end

function MyApp:buttonClickedEffect(event)
    audio.playSound(GAME_SFX.tapButton)
    local target = event.target
    if target ~= nil then
        local scaleX = target:getScaleX()
        local scaleY = target:getScaleY()
        event.target:runAction(CCSequence:createWithTwoActions(CCScaleTo:create(0.15, scaleX * 1.3, scaleY * 1.3 ), CCScaleTo:create(0.2, scaleX, scaleY)))
    end
end

function MyApp:setLanguage( sLanguage )
    self.gameLanguage = sLanguage
end

function MyApp:GET_STR( sId )
    local cfg = CfgData.getCfg(CFG_GAME_STRING, sId)
    if cfg == nil then
        return "Unknown"
    end
    return cfg[self.gameLanguage] or "Unknown"
end

return MyApp

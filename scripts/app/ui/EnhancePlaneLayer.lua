--强化界面
local GuideHelper = import("app/ui/GuideHelper")

local EnhancePlaneLayer = class("EnhancePlaneLayer", function()
    return CCLayer:create()
end)

function EnhancePlaneLayer:ctor(planeData)
    self.plane = planeData

	local layer, ui = ccuiloader_layer("res/ui/enhancePlane.json")
    if not ui then
        return false
    end
    layer:setTouchSwallowEnabled(true)
    layer:setTouchEnabled(true)
    layer:setKeypadEnabled(true)  
    layer:addNodeEventListener(cc.KEYPAD_EVENT, function(event) 
        if event.key == "back" then
            self:removeFromParent()
            return true
        end
        return false
    end)

    self.UI = layer
    self:addChild(layer, 0)

    self.enhance_ui = {}
    local enhanceLevel = planeData.enhanceLevel
    for name, value in pairs(enhanceLevel) do
        local progress_ui = ccuiloader_seekNodeEx(ui, "front/" .. name .. "/progress")
        local gold_count_ui = ccuiloader_seekNodeEx(ui, "front/" .. name .. "/count")
        local descript_ui = ccuiloader_seekNodeEx(ui, "front/" .. name .. "/descript")
        local buy_btn_ui = ccuiloader_seekNodeEx(ui, "front/" .. name .. "/buy_btn")

        self.enhance_ui[name] = {progress = progress_ui, gold = gold_count_ui, descript = descript_ui}
        buy_btn_ui:onButtonClicked(function(event) 
            app:buttonClickedEffect(event)
            self:enhanceHandler(name) 
        end)
    end

    local button
    button = ccuiloader_seekNodeEx(ui, "down/btn_center")
    if button then
        button:onButtonClicked(function(event) 
            app:buttonClickedEffect(event)
            app:enterChoiceMission(app.planeId) 
        end)
    end
    button = ccuiloader_seekNodeEx(ui, "down/btn_right")
    if button then
        button:onButtonClicked(function(event) 
            app:buttonClickedEffect(event)
            self:removeFromParent() 
        end)
    end
    
    self:updateUI()

    self.guide = GuideHelper.new()
    self.guide:forceGuide(self.UI, self, display.getRunningScene())
end

function EnhancePlaneLayer:updateUI()

    for name, ui in pairs(self.enhance_ui) do
        local enhance = self.plane:getEnhanceData(name)

        if enhance then
            ui.progress:setPercent(enhance.level / 5 * 100)
            if enhance.level >= 5 then
                ui.gold:setString("MAX")
            else
                ui.gold:setString(tostring(enhance.cost))
            end
            ui.descript:setString(enhance.descript)
        end
    end

end


function EnhancePlaneLayer:enhanceHandler(name)
    local enhance = self.plane:getEnhanceData(name)
    local cost_gold = enhance.cost
    local gold_count = app:countOfGold()
    if gold_count < cost_gold then
        MyApp:showMessage("金币不足,您是否要购买金币?", function(ok) 
            if ok then app:openStoreGold(nil) end
        end)
        return 
    end

    if self.plane:enhanceByName(name) then
        app:modifyGold(-cost_gold)
        app:savePlaneData()
        self:updateUI()
    end
end

return EnhancePlaneLayer
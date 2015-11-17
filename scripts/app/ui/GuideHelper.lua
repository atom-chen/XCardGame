require("app/model/cWorld")
local StepLoading = import("app/ui/StepLoading")

local GuideHelper = class("GuideHelper")

function GuideHelper:ctor()
    self.guide_ui = nil         --附加的强制引导界面
    self.opt_guide_ui = nil     --附加的可选引导界面
    self.target = nil           --目标界面
    self.scene = nil            --当前场景
    self.step = 0               --当前步骤

    self.current_page = nil
    self.current_result = nil
    self.current_action = nil
    self.current_steps = nil

    self.current_final = nil
    self.current_finger = nil
    self.current_press = nil
end

function GuideHelper:dtor()
    --TODO("GuideHelper:dtor()")
    if self.guide_ui then
        self.guide_ui:setVisible(false)
    end
    self.guide_ui = nil         --附加的引导界面
    self.target = nil           --目标界面
    self.scene = nil            --当前场景

    self.current_page = nil
    self.current_result = nil
    self.current_action = nil
    self.current_steps = nil

    self.current_final = nil
    self.current_finger = nil
    self.current_press = nil
end

function GuideHelper:checkGuide(ui, target, scene, force, delay)
    if not ui then return false end

    --Logger.printTable(app.guideDatas)

    local guide_ui = ccuiloader_seekNodeEx(ui, "root/guide")
    if not guide_ui then
        guide_ui = ccuiloader_seekNodeEx(ui, "guide")
    end
    local opt_guide_ui = ccuiloader_seekNodeEx(ui, "root/optguide")
    if not opt_guide_ui then
        opt_guide_ui = ccuiloader_seekNodeEx(ui, "optguide")
    end
    if not guide_ui and not opt_guide_ui then 
        return false 
    end

    if force and guide_ui then
        local layer = display.newLayer()
        layer:pos(0,0)
        layer:setContentSize(CCSize(display.width, display.height))
        layer:setTouchSwallowEnabled(true)
        layer:setTouchEnabled(true)
        layer:setTouchMode(cc.TOUCH_MODE_ONE_BY_ONE)

        guide_ui:addChild(layer, 0)
    end

    self.guide_ui = guide_ui
    self.opt_guide_ui = opt_guide_ui
    self.target = target
    self.scene = scene

    if delay then
        guide_ui:setVisible(false)
        target:runAction(
            CCSequence:createWithTwoActions(
                CCDelayTime:create(delay), 
                CCCallFunc:create(function() 
                    self:nextGuide()
                end)
            )
        )
    else
        self:nextGuide()
    end

    return true
end

function GuideHelper:forceGuide(ui, target, scene, delay)
    return self:checkGuide(ui, target, scene, true, delay)
end

function GuideHelper:optionalGuide(ui, target, scene, delay)
    return self:checkGuide(ui, target, scene, false, delay)
end

function GuideHelper:nextGuide()
    if not self:internalNextGuide(self.guide_ui) then
        self:internalNextGuide(self.opt_guide_ui)
    end
end

function GuideHelper:clearFinger()
    if self.current_finger then
        for _, ui in pairs(self.current_finger) do
            --ui:removeFromParent()
        end
    end
    self.current_finger = {}
end

function GuideHelper:addFinger(final_ui, name)

    local finger_ui = ccuiloader_seekNodeEx(final_ui, name)
    if finger_ui then
        finger_ui:setVisible(false)

        local location_ui = ccuiloader_seekNodeEx(final_ui, name .. "_location")
        if not location_ui then
            location_ui = finger_ui
        else
            location_ui:setVisible(false)
        end

        local anchor = CCPoint(0.5,0.5)
        local plist_file = finger_ui:getString()
        if plist_file == "" or plist_file == "+" then
            local sp = StepLoading.createArmature("png/arrow/arrow.ExportJson", "arrow")
            if sp then
                --sp:setScale(1.2)
                local animation = sp:getAnimation()
                animation:play("Animation1", -1, -1, -1)

                local x, y = location_ui:getPosition()
                sp:pos(x, y)
                final_ui:addChild(sp, 999)

                table.insert(self.current_finger, sp)
            end
        else
            local png_file = string.gsub(plist_file, ".plist", ".png")
            local sp = StepLoading.createSprite(plist_file, png_file, 8)
            if sp then
                local x, y = location_ui:getPosition()
                sp:setAnchorPoint(anchor)
                sp:pos(x, y)
                final_ui:addChild(sp, 999)

                table.insert(self.current_finger, sp)
            end
        end
    end

end

function GuideHelper:internalNextGuide(guide_ui)
    if not guide_ui then 
        return false 
    end

    self.current_page = nil

    local page_ui = nil
    local index = 1
    repeat
        page_ui = ccuiloader_seekNodeEx(guide_ui, tostring(index))

        if page_ui then
            local condition_ui = ccuiloader_seekNodeEx(page_ui, "condition")
            if self:testCondition(condition_ui) then
                page_ui:setVisible(true)
                self.current_page = page_ui
            else
                page_ui:setVisible(false)
            end
        end

        index = index + 1
    until page_ui == nil

    page_ui = self.current_page
    if page_ui then
        local start_action_ui = ccuiloader_seekNodeEx(page_ui, "start_action")
        if start_action_ui then
            start_action_ui:setVisible(false)
            local start_script = start_action_ui:getString()
            self:executeScript(start_script)

            if not self.current_page then   --cancel guide
                guide_ui:setVisible(false)
                return false
            end
        end

        guide_ui:setVisible(true)

        local steps_ui = ccuiloader_seekNodeEx(page_ui, "steps")
        local final_ui = ccuiloader_seekNodeEx(page_ui, "final")

        self.current_result = ccuiloader_seekNodeEx(page_ui, "result")
        self.current_action = ccuiloader_seekNodeEx(page_ui, "action")
        self.current_steps = steps_ui
        self.current_final = final_ui

        if steps_ui then
            steps_ui:setVisible(true)
            self.step = 1
            self:nextStep()
        end

        if final_ui then
            final_ui:setVisible(steps_ui == nil)
            self:clearFinger()
            self:addFinger(final_ui, "anitips")
            self:addFinger(final_ui, "finger")

            self.current_press = cc.uiloader:seekNodeByName(final_ui, "press")
            if self.current_press then
                self.current_press:onButtonClicked(function(event) 
                    self:onFinalClick()
                end)
            end
        end
    else
        guide_ui:setVisible(false)
    end

    return page_ui ~= nil
end

function GuideHelper:nextStep()
    local steps_ui = self.current_steps
    if not steps_ui then return end

    local curstep_ui = ccuiloader_seekNodeEx(steps_ui, tostring(self.step))
    self.step = self.step + 1

    local allstep = steps_ui:allChildren()
    for _, step in ipairs(allstep) do
        step:setVisible(step == curstep_ui)
    end

    if not curstep_ui then
        local final_ui = self.current_final
        if final_ui then
            final_ui:setVisible(true)
        end
    else
        local script, delay_script = nil, nil
        local action_ui = cc.uiloader:seekNodeByName(curstep_ui, "action")
        if action_ui then
            action_ui:setVisible(false)
            script = action_ui:getString()
        end
        local delay_action_ui = cc.uiloader:seekNodeByName(curstep_ui, "delay_action")
        if delay_action_ui then
            delay_action_ui:setVisible(false)
            delay_script = delay_action_ui:getString()
        end

        local press_ui = cc.uiloader:seekNodeByName(curstep_ui, "press")
        if press_ui then
            self:clearFinger()
            self:addFinger(curstep_ui, "anitips")
            self:addFinger(curstep_ui, "finger")

            press_ui:onButtonClicked(function(event) 
                --TODO("onPressGuideHelper");
                if script then
                    self:executeScript(script)
                end
                if delay_script then
                    self:executeDelayScript(delay_script)
                end
                self:nextStep()
            end)
        end
    end
end

function GuideHelper:cancelGuide()
    self.current_page = nil
end

function GuideHelper:executeDelayScript(script)

    local target = self.target
    if not target then return end

    local scene = self.scene
    local s, e = string.find(script, ',')
    local delay_time = string.sub(script, 0, s)
    script = string.sub(script, e)
    
    script = 'return function(self, guide, scene, helper)' .. script ..' end'
    local method = loadstring(script)()

    target:runAction(
        CCSequence:createWithTwoActions(
            CCDelayTime:create(tonumber(delay_time)), 
            CCCallFunc:create(function() 
                method(target, app.guideDatas, scene)
            end)
        )
    )

end

function GuideHelper:executeScript(script)

    script = 'return function(self, guide, scene, helper)' .. script ..' end'
    local method = loadstring(script)()
    return method(self.target, app.guideDatas, self.scene, self)

end

function GuideHelper:testCondition(condition_ui)
    if not condition_ui then return false end
    local script = condition_ui:getString()
    return self:executeScript('return (' .. script ..')')
end

function GuideHelper:onFinalClick()
    audio.playSound(GAME_SFX.tapButton);

    local result_ui = self.current_result
    if result_ui then
        local script = result_ui:getString()
        self:executeScript(script)
    end

    local action_ui = self.current_action
    if action_ui then
        local script = action_ui:getString()
        self:executeScript(script)
    end

    app:saveGuide()
    self:nextGuide()

end

return GuideHelper

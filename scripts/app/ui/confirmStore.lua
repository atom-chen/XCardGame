require("app/model/cWorld")

local ConfirmStore = class("ConfirmStore", function() return display.newLayer() end)

function ConfirmStore:ctor(store, callback)
    self.ui = nil                   --显示的界面
    self.callback = callback        --回调 callback(ok)

	local layer, ui = ccuiloader_layer("res/ui/confirmStore.json")
    if not ui then
        return false
    end
    layer:setTouchSwallowEnabled(true)
    layer:setTouchEnabled(true)
    layer:setKeypadEnabled(true)  
    layer:addNodeEventListener(cc.KEYPAD_EVENT, function(event) 
        if event.key == "back" then
            self:onButtonClick(false)
            return true
        end
        return false
    end)

    self:addChild(layer)
    self.ui = layer

    if store then
        local icon_ui = ccuiloader_seekNodeEx(ui, "ref/icon")
        if icon_ui then
            local frame = display.newSpriteFrame(store.icon)
            icon_ui:setDisplayFrame(frame)
        end
        local name_ui = ccuiloader_seekNodeEx(ui, "ref/name")
        if name_ui then
            name_ui:setString(store.name)
        end
        local price_ui = ccuiloader_seekNodeEx(ui, "ref/price")
        if price_ui then
            price_ui:setString(string.format("%.1f",store.price))
        end
    end

    local button
    button = ccuiloader_seekNodeEx(ui, "ref/btn_OK")
    if button then
        button:onButtonClicked(function(event) 
            app:buttonClickedEffect(event)
            self:onButtonClick(true)
        end)
    end
    button = ccuiloader_seekNodeEx(ui, "ref/btn_Close")
    if button then
        button:onButtonClicked(function(event) 
            app:buttonClickedEffect(event)
            self:onButtonClick(false)
        end)
    end
end

function ConfirmStore:onButtonClick(ok)
    local callback = self.callback

    self:removeFromParent()
    self.ui = nil
    self.callback = nil

    if callback then
        callback(ok)
    end

end

return ConfirmStore

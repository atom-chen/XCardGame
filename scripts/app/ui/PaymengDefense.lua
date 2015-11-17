--require("app/model/cWorld")

local PaymengDefense = class("PaymengDefense", function() return display.newLayer() end)

function PaymengDefense:ctor()
    
    self.id         = nil
    self.callback   = nil

    self:pos(0, 0)
    self:setContentSize(CCSize(display.width, display.height))

    self:setTouchSwallowEnabled(true)
    self:setTouchEnabled(true)
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event) 
        self:onPaymentResult(1, "用户取消了支付")
        return true
    end)

    self:setKeypadEnabled(true)  
    self:addNodeEventListener(cc.KEYPAD_EVENT, function(event) 
        if event.key == "back" then
            self:onPaymentResult(1, "用户取消了支付")
            return true
        end
        return false
    end)

end

function PaymengDefense:pay(id, callback)
    self.id         = id
    self.callback   = callback

    local stores = CfgData.getCfg(CFG_STORES, id)
    if not stores then
        local msg = "未知的商品编号("..id..")"
        self:onPaymentResult(-1, msg)
        return
    end

    if not _1sdk then

        app:showConfirmStore(stores, function(ok) 
            if ok then
                self:onPaymentResult(0, "")
            else
                self:onPaymentResult(1, "用户取消了支付")
            end
        end)

    else
        _1sdk.getInstance():pay(id, function(r, remain) 
             self:onPaymentResult(r, remain)
        end)
    end
end

function PaymengDefense:onPaymentResult(result, remain)
    if self.callback then
        self.callback(result, remain)
    end

    self:removeFromParent()
end

return PaymengDefense

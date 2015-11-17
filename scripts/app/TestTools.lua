


function testCreateHelloWorld( scene, text, deltaX, deltaY )

	--Example : how to load xml file to lua talbe
	--local xml = CCFileUtils:sharedFileUtils():loadXml("strings.xml");
	--print("xml.name1.value1 = " .. xml.name1.value1);
	--CCFileUtils:sharedFileUtils():saveXml("saved.xml", xml);

	--[[
    _1sdk.getInstance():recharge(100, "desc", "sign",
        function(r, remain)
            print(remain)
        end)
	]]

	local paras = {
			text = text or "Hello, World", 
			size = 16, 
			align = ui.TEXT_ALIGN_CENTER
		}
	-- local label = ui.newTTFLabel({
	--     text = "Hello, World\n您好，世界",
	--     font = "Arial",
	--     size = 64,
	--     color = cc.c3b(255, 0, 0), -- 使用纯红色
	--     align = ui.TEXT_ALIGN_LEFT,
	--     valign = ui.TEXT_VALIGN_TOP,
	--     dimensions = cc.size(400, 200)
	-- }
			
		

    local ttfLabel = ui.newTTFLabel(paras)
	ttfLabel:pos(display.cx + (deltaX or 0), display.height - 30 + (deltaY or 0))
	ttfLabel:addTo(scene)
    return ttfLabel
end

function ccuiloader_seekNodeEx_(parent, names, index)
    --if debugshow then
    --    print("ccuiloader_seekNodeEx_ : index, name =", index, parent.name)
    --end

    if index > #names then
        return parent
    end

	local children = parent:getChildren()
	local childCount = parent:getChildrenCount()
	if childCount < 1 then
		return nil
	end

    local name = names[index]

	if "table" == type(children) then
	    for i=1, childCount do
		    parent = children[i]
		    if parent and parent.name == name then
                return ccuiloader_seekNodeEx_(parent, names, index + 1)
		    end
	    end
    else
	    for i=1, childCount do
		    parent = children:objectAtIndex(i - 1)
		    if parent and parent.name == name then
                return ccuiloader_seekNodeEx_(parent, names, index + 1)
		    end
	    end
    end

	return nil
end

function ccuiloader_seekNodeEx(parent, names)
    if not parent or not parent.getChildren then
        return nil
    end

    local tnames = names:split("/", nil)
    return ccuiloader_seekNodeEx_(parent, tnames, 1)
end

function ccuiloader_layer(filename)
	local ui, width, height = cc.uiloader:load(filename)
    if not ui then
        return nil, nil
    end

    local layer = display.newLayer()
    layer:pos(0,0)
    layer:setContentSize(CCSize(width, height))
    layer:addChild(ui, 0)
    --layer:setTouchSwallowEnabled(true)
    --layer:setTouchEnabled(true)
    --layer:setKeypadEnabled(true) 
    
    return layer, ui
end

local c = CCNode

function c:allChildren()

	local children = CCNode.getChildren(self)
	local childCount = CCNode.getChildrenCount(self)
	if childCount < 1 then
		return nil
	end

    local t
	if "table" == type(children) then
        t = children
    else
        t = {}
	    for i=1, childCount do
		    local n = children:objectAtIndex(i - 1)
            table.insert(t, n)
	    end
    end

    return t
end

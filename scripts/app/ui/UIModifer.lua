local sharedSpriteFrameCache = CCSpriteFrameCache:sharedSpriteFrameCache()

local UIPanel = cc.ui.UIPanel

function UIPanel:ctor(options)
	self.subControl = {}
end

function UIPanel:autoAdaptSize( parentSize )
	local options = self.options
	local jsonNode = self.jsonNode
	if options == nil or jsonNode == nil then
		return
	end
	local sizeChange = false
	local sName = options.name
	local fillMode = string.sub( sName, -12, -1 )
	local width = parentSize.width
	local height = parentSize.height
	if fillMode == ".FILL_SCREEN" then
		width = CONFIG_SCREEN_WIDTH
		height = CONFIG_SCREEN_HEIGHT
		sizeChange = true
	elseif fillMode == ".FILL_PARENT" then
		width = parentSize.width
		height = parentSize.height
		sizeChange = true
	end
	if sizeChange == true then
		self:setSize( width, height )
		self:setPosition( CCPoint( 0, 0 ) )
		--如果是普通的控件，则进行相应的位置处理
		self:modifyPanelChildPos_( "Panel", true, self:getContentSize(), jsonNode.children)
	end
	for i, v in ipairs( jsonNode.children ) do
		local childNode = ccuiloader_seekNodeEx( self, v.options.name )
		if childNode ~= nil then
			if v.classname ~= "ScrollView" then
				if v.classname ~= "Panel" then
					self:updatePosByOptions( childNode, v )
				else
					childNode:autoAdaptSize( self:getContentSize() )
				end
			end
		end
	end
end

function UIPanel:updatePosByOptions( uiNode, jsonNode )
	local options = jsonNode.options
	if options ~= nil then
		uiNode:setPositionX(options.x or 0)
		uiNode:setPositionY(options.y or 0)
		uiNode:setAnchorPoint( cc.p(options.anchorPointX or 0.5, options.anchorPointY or 0.5))
	end
end

local uiloader = cc.uiloader

-- private
function uiloader:loadAndParseFile(jsonFile)
	local fileUtil = cc.FileUtils:getInstance()
	local fullPath = fileUtil:fullPathForFilename(jsonFile)
	local jsonStr = fileUtil:getStringFromFile(fullPath)
	local jsonVal = json.decode(jsonStr)

	local root = jsonVal.nodeTree
	if not root then
		root = jsonVal.widgetTree
	end
	if not root then
		printInfo("CCSUILoader - parserJson havn't found root node")
		return
	end
	self:prettyJson(root)

	return root
end

function uiloader:prettyJson(json)
	local setZOrder
	setZOrder = function(node, isParentScale)
		if isParentScale then
        	node.options.ZOrder = node.options.ZOrder or 0 + 3
		end

		if not node.children then
			print("CCSUILoader children is nil")
			return
		end
		if 0 == #node.children then
			return
		end

        for i,v in ipairs(node.children) do
			setZOrder(v, node.options.scale9Enable)
        end
	end

	setZOrder(json)
end


function UIPanel:modifyPanelChildPos_(clsType, bAdaptScreen, parentSize, children)
	if "Panel" ~= clsType
		or not bAdaptScreen
		or not children then
		return
	end

	self:modifyLayoutChildPos_(parentSize, children)
end

function UIPanel:modifyLayoutChildPos_(parentSize, children)
	for _,v in ipairs(children) do
		self:calcChildPosByName_(children, v.options.name, parentSize)
	end
end

function UIPanel:calcChildPosByName_(children, name, parentSize)
	local child = self:getPanelChild_(children, name)
	if not child then
		return
	end
	if child.posFixed_ then
		return
	end

	local layoutParameter
	local options
	local x, y
	local bUseOrigin = false

	options = child.options
	layoutParameter = options.layoutParameter

	if not layoutParameter then
		return
	end

	if 1 == layoutParameter.type then
		if 1 == layoutParameter.gravity then
			-- left
			x = options.width * 0.5
		elseif 2 == layoutParameter.gravity then
			-- top
			y = parentSize.height - options.height * 0.5
		elseif 3 == layoutParameter.gravity then
			-- right
			x = parentSize.width - options.width * 0.5
		elseif 4 == layoutParameter.gravity then
			-- bottom
			y = options.height * 0.5
		elseif 5 == layoutParameter.gravity then
			-- center vertical
			y = parentSize.height * 0.5
		elseif 6 == layoutParameter.gravity then
			-- center horizontal
			x = parentSize.width * 0.5
		else
			-- use origin pos
			x = options.x
			y = options.y
			bUseOrigin = true
			print("CCSUILoader - modifyLayoutChildPos_ not support gravity:" .. layoutParameter.type)
		end

		if 1 == layoutParameter.gravity
			or 3 == layoutParameter.gravity
			or 6 == layoutParameter.gravity then
			x = ((options.anchorPointX or 0.5) - 0.5)*options.width + x
			y = options.y
		else
			x = options.x
			y = ((options.anchorPointY or 0.5) - 0.5)*options.height + y
		end
	elseif 2 == layoutParameter.type then
		local relativeChild = self:getPanelChild_(children, layoutParameter.relativeToName)
		local relativeRect
		if relativeChild then
			self:calcChildPosByName_(children, layoutParameter.relativeToName, parentSize)
			relativeRect = cc.rect(
				(relativeChild.options.x - (relativeChild.options.anchorPointX or 0.5) * relativeChild.options.width) or 0,
				(relativeChild.options.y - (relativeChild.options.anchorPointY or 0.5) * relativeChild.options.height) or 0,
				relativeChild.options.width or 0,
				relativeChild.options.height or 0)
		end

		-- calc pos on center anchor point (0.5, 0.5)
		if 1 == layoutParameter.align then
			-- top left
			x = options.width * 0.5
			y = parentSize.height - options.height * 0.5

			x = x + (layoutParameter.marginLeft or 0)
			y = y - (layoutParameter.marginTop or 0)
		elseif 2 == layoutParameter.align then
			-- top center
			x = parentSize.width * 0.5
			y = parentSize.height - options.height * 0.5

			y = y - (layoutParameter.marginTop or 0)
		elseif 3 == layoutParameter.align then
			-- top right
			x = parentSize.width - options.width * 0.5
			y = parentSize.height - options.height * 0.5

			x = x - (layoutParameter.marginRight or 0)
			y = y - (layoutParameter.marginTop or 0)
		elseif 4 == layoutParameter.align then
			-- left center
			x = options.width * 0.5
			y = parentSize.height*0.5

			x = x + (layoutParameter.marginLeft or 0)
		elseif 5 == layoutParameter.align then
			-- center
			x = parentSize.width * 0.5
			y = parentSize.height*0.5
		elseif 6 == layoutParameter.align then
			-- right center
			x = parentSize.width - options.width * 0.5
			y = parentSize.height*0.5

			x = x - (layoutParameter.marginRight or 0)
		elseif 7 == layoutParameter.align then
			-- left bottom
			x = options.width * 0.5
			y = options.height * 0.5

			x = x + (layoutParameter.marginLeft or 0)
			y = y + (layoutParameter.marginDown or 0)
		elseif 8 == layoutParameter.align then
			-- bottom center
			x = parentSize.width * 0.5
			y = options.height * 0.5

			y = y + (layoutParameter.marginDown or 0)
		elseif 9 == layoutParameter.align then
			-- right bottom
			x = parentSize.width - options.width * 0.5
			y = options.height * 0.5

			x = x - (layoutParameter.marginRight or 0)
			y = y + (layoutParameter.marginDown or 0)
		elseif 10 == layoutParameter.align then
			-- location above left
			x = relativeRect.x + options.width * 0.5
			y = relativeRect.y + relativeRect.height + options.height * 0.5

			x = x + (layoutParameter.marginLeft or 0)
			y = y + (layoutParameter.marginDown or 0)
		elseif 11 == layoutParameter.align then
			-- location above center
			x = relativeRect.x + relativeRect.width * 0.5
			y = relativeRect.y + relativeRect.height + options.height * 0.5

			y = y + (layoutParameter.marginDown or 0)
		elseif 12 == layoutParameter.align then
			-- location above right
			x = relativeRect.x + relativeRect.width - options.width * 0.5
			y = relativeRect.y + relativeRect.height + options.height * 0.5

			x = x - (layoutParameter.marginRight or 0)
			y = y + (layoutParameter.marginDown or 0)
		elseif 13 == layoutParameter.align then
			-- location left top
			x = relativeRect.x - options.width * 0.5
			y = relativeRect.y + relativeRect.height - options.height * 0.5

			x = x - (layoutParameter.marginRight or 0)
			y = y - (layoutParameter.marginTop or 0)
		elseif 14 == layoutParameter.align then
			-- location left center
			x = relativeRect.x - options.width * 0.5
			y = relativeRect.y + relativeRect.height * 0.5

			x = x - (layoutParameter.marginRight or 0)
		elseif 15 == layoutParameter.align then
			-- location left bottom
			x = relativeRect.x - options.width * 0.5
			y = relativeRect.y + options.height * 0.5

			x = x - (layoutParameter.marginRight or 0)
			y = y + (layoutParameter.marginDown or 0)
		elseif 16 == layoutParameter.align then
			-- location right top
			x = relativeRect.x + relativeRect.width + options.width * 0.5
			y = relativeRect.y + relativeRect.height - options.height * 0.5

			x = x + (layoutParameter.marginLeft or 0)
			y = y + (layoutParameter.marginTop or 0)
		elseif 17 == layoutParameter.align then
			-- location right center
			x = relativeRect.x + relativeRect.width + options.width * 0.5
			y = relativeRect.y + relativeRect.height * 0.5

			x = x + (layoutParameter.marginLeft or 0)
		elseif 18 == layoutParameter.align then
			-- location right bottom
			x = relativeRect.x + relativeRect.width + options.width * 0.5
			y = relativeRect.y + options.height * 0.5

			x = x + (layoutParameter.marginLeft or 0)
			y = y + (layoutParameter.marginDown or 0)
		elseif 19 == layoutParameter.align then
			-- location below left
			x = relativeRect.x + options.width * 0.5
			y = relativeRect.y - options.height * 0.5

			x = x + (layoutParameter.marginLeft or 0)
			y = y - (layoutParameter.marginTop or 0)
		elseif 20 == layoutParameter.align then
			-- location below center
			x = relativeRect.x + relativeRect.width * 0.5
			y = relativeRect.y - options.height * 0.5

			y = y - (layoutParameter.marginTop or 0)
		elseif 21 == layoutParameter.align then
			-- location below right
			x = relativeRect.x + relativeRect.width - options.width * 0.5
			y = relativeRect.y - options.height * 0.5

			x = x - (layoutParameter.marginRight or 0)
			y = y - (layoutParameter.marginTop or 0)
		else
			-- use origin pos
			x = options.x
			y = options.y
			bUseOrigin = true
			print("CCSUILoader - modifyLayoutChildPos_ not support align:" .. layoutParameter.align)
		end

		-- change pos on real anchor point
		x = ((options.anchorPointX or 0.5) - 0.5)*options.width + x
		y = ((options.anchorPointY or 0.5) - 0.5)*options.height + y
	elseif 0 == layoutParameter.type then
		x = options.x
		y = options.y
	else
		print("CCSUILoader - modifyLayoutChildPos_ not support type:" .. layoutParameter.type)
	end
	options.x = x
	options.y = y
	child.posFixed_ = true

end

function UIPanel:getPanelChild_(children, name)
	for _, v in ipairs(children) do
		if v.options.name == name then
			return v
		end
	end

	return
end
---------------------------------------------------------------------------------------------
local UIPushButton = cc.ui.UIPushButton

function UIPushButton:getButtonImage(state)
    return self.images_[state]
end

function UIPushButton:addButtonImageGray( state )
	local uiManager = app.uiManager
	local filename = self:getButtonImage( state )
	if filename ~= nil and uiManager ~= nil then
		uiManager:createGraySpriteFrame( string.sub( filename, 2 ) )
	end
end

function UIPushButton:setButtonImage(state, image, ignoreEmpty)
    assert(state == UIPushButton.NORMAL
        or state == UIPushButton.PRESSED
        or state == UIPushButton.DISABLED,
        string.format("UIPushButton:setButtonImage() - invalid state %s", tostring(state)))
    UIPushButton.super.setButtonImage(self, state, image, ignoreEmpty)

    if state == UIPushButton.NORMAL then
        if not self.images_[UIPushButton.PRESSED] then
            self.images_[UIPushButton.PRESSED] = image
        end
        self:setGrayStateUseNormalSprite( UIPushButton.DISABLED )
    end

    return self
end

function UIPushButton:setGrayStateUseNormalSprite( state )
    assert(state == UIPushButton.NORMAL
    or state == UIPushButton.PRESSED
    or state == UIPushButton.DISABLED,
    string.format("UIPushButton:setGrayStateUseNormalSprite() - invalid state %s", tostring(state)))
	self:addButtonImageGray( cc.ui.UIPushButton.NORMAL )
    local sImgName = self:getButtonImage( cc.ui.UIPushButton.NORMAL )
    if sImgName ~= nil then    	
    	local sGrayImgName = string.gsub( sImgName, ".png", "___gray.png" )
    	self:setButtonImage( state, sGrayImgName )
    end
end
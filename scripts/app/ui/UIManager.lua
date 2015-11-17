local sharedSpriteFrameCache = CCSpriteFrameCache:sharedSpriteFrameCache()

require("app/model/Factory")
require("bdlib/tools/util")
require("app/ui/UIModifer")

local UIManager = class("UIManager")

function UIManager:ctor()
	self.m_tUILoaded = {}
	self.m_tUIOpened = {}
	self.tControlStrMap = {}
end

function UIManager:getInstance()
	if _G.__uiManager == nil then
		_G.__uiManager = UIManager:new()
	end
	return _G.__uiManager
end

function UIManager:showUI( uiName, resetData, callback, callbackData )
	resetData = resetData or true
	assert( MyApp ~= nil )
	assert( MyApp.sceneManager ~= nil )
	local curScene = MyApp.sceneManager:getCurScene()
	assert(curScene ~= nil )
	local sceneUILayer = curScene:getUILayer()
	assert(sceneUILayer ~= nil )
	local uiModule = self:getUIByName( uiName );
	if uiModule == nil then
		return
	end
	if self:isShowUI( uiName ) == true then
		if resetData == true then
			uiModule:initData()
		end
		if uiModule.onShowUI ~= nil then
			uiModule:onShowUI()
		end
		local uiRootNode = uiModule:getUIRootNode()
		if uiRootNode ~= nil then
			uiRootNode:setTouchSwallowEnabled(uiModule.TouchSwallowEnabled)
    		uiRootNode:setTouchEnabled(uiModule.TouchEnabled)
    		uiRootNode:setTouchMode(uiModule.TouchMode)
			if uiRootNode:getParent() == nil then
				if uiModule.onInitEventsHandler ~= nil then
					uiModule:onInitEventsHandler()
				end
				sceneUILayer:addChild( uiRootNode )
			end
			if uiRootNode:isVisible() == false then
				uiRootNode:setVisible( true )
			end
		end
		if callback ~= nil then
			callback( callbackData )
		end
		return
	end
	local uiRootNode = uiModule:getUIRootNode()
	if uiRootNode ~= nil then
		uiRootNode:setTouchSwallowEnabled(uiModule.TouchSwallowEnabled)
		uiRootNode:setTouchEnabled(uiModule.TouchEnabled)
		uiRootNode:setTouchMode(uiModule.TouchMode)
		uiRootNode:setVisible( true )
		if uiModule.onInitEventsHandler ~= nil then
			uiModule:onInitEventsHandler()
		end
		sceneUILayer:addChild( uiRootNode )
	end
	if resetData == true then
		uiModule:initData();
	end
	if uiModule.onShowUI ~= nil then
		uiModule:onShowUI();
	end
	self.m_tUIOpened[uiName] = uiModule;
	if callback ~= nil then
		callback( callbackData )
	end
end

function UIManager:isShowUI( uiName )
	return (self.m_tUIOpened[uiName] ~= nil)
end

function UIManager:closeUI( uiName )
	if self.m_tUIOpened[uiName] == nil then
		return
	end
	assert( MyApp ~= nil )
	assert( MyApp.sceneManager ~= nil )
	local curScene = MyApp.sceneManager:getCurScene()
	assert(curScene ~= nil )
	local sceneUILayer = curScene:getUILayer()
	assert(sceneUILayer ~= nil )
	local uiModule = self:getUIByName( uiName )
	assert(uiModule ~= nil )
	local uiRootNode = uiModule:getUIRootNode()
	if uiRootNode ~= nil then
		uiRootNode:setVisible(false)
		uiRootNode:removeFromParent()
	end
	if uiModule.onCloseUI ~= nil then
		uiModule:onCloseUI();
	end
	self.m_tUIOpened[uiName] = nil;
end

function UIManager:setNodeJsonAndOptions( uiNode, jsonNode )
	uiNode.jsonNode = jsonNode
	uiNode.options = jsonNode.options
	for i, v in ipairs( jsonNode.children ) do
		local childNode = ccuiloader_seekNodeEx( uiNode, v.options.name )
		if childNode ~= nil then
			self:setNodeJsonAndOptions( childNode, v )
		end
	end
end

function UIManager:getUIByName( uiName )
	if self.m_tUILoaded[uiName] == nil then
		local UIClass = import(string.format("app/ui/%s", uiName))
		if UIClass == nil then
			return
		end
		local uiModule = UIClass:new()
		assert( uiModule ~= nil )
		uiModule:setUIManager(self)
		uiModule:initConfig()
		assert(uiModule.jsonFilePath ~= nil and uiModule.jsonFilePath ~= "")
		local uiRootNode, width, height = self:loadUIFromFilePath( uiModule.jsonFilePath )
		if uiRootNode ~= nil and width ~= nil and height ~= nil then
			uiModule.uiName = uiName
			uiRootNode:setContentSize( CCSize( width, height ) );
			uiModule:setUIRootNode( uiRootNode )
			self.m_tUILoaded[uiName] = uiModule
		end
	end
	return self.m_tUILoaded[uiName]
end

function UIManager:initControlStrMap()
	self.tControlStrMap = {}
	local controlStrMap = CfgData.getCfgTable(CFG_CONTROL_STRING)
	if controlStrMap ~= nil then
		for i, uiControlMap in pairs( controlStrMap ) do
			local sName = string.format( "res/ui/%s", i )
			if self.tControlStrMap[sName] == nil then
				self.tControlStrMap[sName] = {}
			end
			local tempMap = self.tControlStrMap[sName]
			for idx, val in ipairs( uiControlMap ) do
				tempMap[ val.controlName ] = val.strID
			end
		end
	end
end

function UIManager:replaceUIControlStr( sFilePath, uiRootNode )
	local tStrMap = self.tControlStrMap[ sFilePath ]
	if tStrMap ~= nil then
		for i, v in pairs( tStrMap ) do
			local childNode = ccuiloader_seekNodeEx( uiRootNode, i )
			if childNode ~= nil then
				childNode:setString( app:GET_STR(v) )
			end
		end
	end
end

function UIManager:loadUIFromFilePath( sFilePath )
	local uiRootNode, width, height = cc.uiloader:load( sFilePath  )
	local jsonNode = cc.uiloader:loadAndParseFile( sFilePath )
	if uiRootNode ~= nil and jsonNode ~= nil then
		for i, v in ipairs( jsonNode.children ) do
			self:setNodeJsonAndOptions( uiRootNode, jsonNode )
			if v.classname == "Panel" and v.options ~= nil and v.options.name ~= nil then
				local childNode = ccuiloader_seekNodeEx( uiRootNode, v.options.name )
				if childNode ~= nil then
					childNode:autoAdaptSize( uiRootNode:getContentSize() )
				end
			end
		end
		self:replaceUIControlStr( sFilePath, uiRootNode )
	end
	return uiRootNode, width, height
end

function UIManager:closeAllUI( tIgnoreList )
	local closedUIList = {};
	tIgnoreList = tIgnoreList or {}
	for i, v in pairs( self.m_tUIOpened ) do
		if tIgnoreList[i] ~= true then
			local uiRootNode = v:getUIRootNode()
			if uiRootNode ~= nil then
				uiRootNode:removeFromParent();
				if v.onCloseUI ~= nil then
					v:onCloseUI();
				end
				closedUIList[#closedUIList+1] = i;
			end
		end
	end
	for i, v in ipairs( closedUIList ) do
		self.m_tUIOpened[v] = nil;
	end
end

function UIManager:destoryAllUI()
	for i, v in pairs( self.m_tUILoaded ) do
		if v ~= nil then
			if v.onDestory ~= nil then
				v.onDestory();
			end
			local uiRootNode = v:getUIRootNode();
			if uiRootNode ~= nil then
				self.m_tUILoaded[ i ] = nil;
				self.m_tUIOpened[ i ] = nil;
			end
			uiRootNode:autorelease()
		end
	end
end

function UIManager:update( dt )
	for i, v in pairs( self.m_tUIOpened ) do
		if v.onUpdateUI ~= nil then
			v:onUpdateUI( dt )
		end
	end
end

function UIManager:showSystemTips( sTips )
	local function callbackFuc( tCallbackData )
		local uiSystemTips = self:getUIByName( "UISystemTips" )
		if uiSystemTips ~= nil then
			uiSystemTips:setTips( tCallbackData or "" )
		end
	end
	self:showUI( "UISystemTips", true, callbackFuc, sTips  )
end

--[[
	Type 类型(目前暂时只有一种对话框类型)
	Title 标题
	Desc 显示提示文字
	Btn1Label 按钮1文字
	Btn2Label 按钮2文字
	Btn1Callback 按钮1回调
	Btn1CallbackData 按钮1回调函数
	Btn2Callback 按钮2回调
	Btn2CallbackData 按钮2回调函数
--]]
function UIManager:showConfirmDialog( tShowData, tShowCallback )
	local function callbackFuc( tCallbackData )
		local uiConfirmDialog = self:getUIByName( "UIConfirmDialog" )
		if uiConfirmDialog ~= nil then
			uiConfirmDialog:setDialogData( tCallbackData )
			if tShowCallback ~= nil then
				tShowCallback()
			end
		end
	end
	self:showUI( "UIConfirmDialog", true, callbackFuc, tShowData )
end

function UIManager:registerEventsHandlers( controlPath, eventName, handler, uiModule )
	assert( uiModule ~= nil )
	if eventName ~= "OnClicked" and eventName ~= "OnPressed" and eventName ~= "OnReleased" and eventName ~= "TouchEvent" then
		return
	end
	local control = uiModule:seekNodeByPath( controlPath );
	if control ~= nil then
		if iskindof(control, "UIButton") then	--button才有点击事件的注册
			if eventName == "OnClicked" then
				control:onButtonClicked( 
					function( event )
						audio.playSound(GAME_SFX.tapButton)
						if control.scaleOnClicked == true then
						    local target = event.target
						    if target ~= nil then
						        local scaleX = target:getScaleX()
						        local scaleY = target:getScaleY()
						        event.target:runAction(CCSequence:createWithTwoActions(CCScaleTo:create(0.15, scaleX * 1.3, scaleY * 1.3 ), CCScaleTo:create(0.2, scaleX, scaleY)))
						    end
						end
						if handler ~= nil then
							handler( uiModule, control, event )
						end
					end
					);
			elseif eventName == "OnPressed" then
				control:onButtonPressed( function(event) handler( uiModule, event ) end )
			elseif eventName == "OnReleased" then
				control:onButtonRelease( function(event) handler( uiModule, event ) end )
			end
		elseif iskindof(control, "UIPanel") then --panel控件才会有ontouch这种事件存在
			if eventName == "TouchEvent" then
	    		control:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event) 
	    															return handler( uiModule, event )
	    														  end)
	    	end
		end
	end
end

function UIManager:registerItemSlotClickedHandler( sSlotName, showPanel, handler, uiModule )
	assert( uiModule ~= nil )
	local tItemSlotInfo = uiModule:getItemSlotInfoByName( sSlotName )
	if tItemSlotInfo == nil then
		return
	end
	local control = uiModule:seekNodeByPath( tItemSlotInfo.BtnName )
	if control == nil then
		return
	end
	local function showItemInfoPanelCallback()
		if tItemSlotInfo.ItemInfo == nil then
			return
		end
		local function callback( tCallbackData )
			local uiItemInfoPanel = self:getUIByName( "UIItemInfoPanel" )
			if uiItemInfoPanel ~= nil then
				uiItemInfoPanel:setItemInfo( tItemSlotInfo.ItemInfo )
			end
		end
		self:showUI( "UIItemInfoPanel", true, callback, tItemSlotInfo.ItemInfo )
	end
	control:onButtonClicked(
					function( event ) 
						audio.playSound(GAME_SFX.tapButton)
						if showPanel == true then
							showItemInfoPanelCallback()
						end
						if handler ~= nil then
							handler( uiModule, sSlotName, control, event )
						end
					end
				)
end

function UIManager:registerDynamicItemSlotClickedHandler( sSlotName, showPanel, clickedHandler, uiModule )
	assert( uiModule ~= nil )
	local tItemSlotInfo = uiModule:getItemSlotInfoByName( sSlotName )
	if tItemSlotInfo == nil then
		return
	end
	local control = tItemSlotInfo.SlotBtn
	if control == nil then
		return
	end
	local function showItemInfoPanelCallback()
		if tItemSlotInfo == nil then
			return
		end
		local function callback( tCallbackData )
			local uiItemInfoPanel = self:getUIByName( "UIItemInfoPanel" )
			if uiItemInfoPanel ~= nil then
				uiItemInfoPanel:setItemInfo( tItemSlotInfo.ItemInfo )
			end
		end
		self:showUI( "UIItemInfoPanel", true, callback, tItemSlotInfo.ItemInfo )
	end
	control:onButtonClicked(
					function( event ) 
						audio.playSound(GAME_SFX.tapButton)
						if showPanel == true then
							showItemInfoPanelCallback()
						end
						if handler ~= nil then
							handler( uiModule, sSlotName, control, event )
						end
					end
				)
end

function UIManager.loadTexture(plist, png)
	if UIManager.isNil(plist) then
		return
	end

	local fileUtil
	fileUtil = cc.FileUtils:getInstance()
	local fullPath = fileUtil:fullPathForFilename(plist)
	UIManager.addSearchPathIf(io.pathinfo(fullPath).dirname, fileUtil)
	local spCache
	spCache = cc.SpriteFrameCache:getInstance()
	-- print("UILoaderUtilitys - loadTexture plist:" .. plist)
	if png then
		spCache:addSpriteFrames(plist, png)
	else
		spCache:addSpriteFrames(plist)
	end
end

function UIManager.isNil(str)
	if not str or 0 == string.utf8len(str) then
		return true
	else
		return false
	end
end

function UIManager.addSearchPathIf(dir, fileUtil)
	if not UIManager.searchDirs then
		UIManager.searchDirs = {}
	end

	if not UIManager.isSearchExist(dir) then
		table.insert(UIManager.searchDirs, dir)
		if not fileUtil then
			fileUtil = cc.FileUtils:getInstance()
		end
		fileUtil:addSearchPath(dir)
	end
end

function UIManager.isSearchExist(dir)
	local bExist = false
	for i,v in ipairs(UIManager.searchDirs) do
		if v == dir then
			bExist = true
			break
		end
	end

	return bExist
end

function UIManager:transResName(fileData)
	if not fileData then
		return
	end

	local name = fileData.path
	if not name then
		return name
	end

	UIManager.loadTexture(fileData.plistFile)
	if 1 == fileData.resourceType then
		return "#" .. name
	else
		return name
	end
end

function UIManager:replaceSpriteIcon( sprite, plistFile, filePath, isGray )
	if sprite == nil then
		return
	end
	local options = sprite.options
	local jsonNode = sprite.jsonNode
	if options == nil or  options.fileNameData == nil or jsonNode == nil then
		return
	end
	if isGray ~= true then
		if (plistFile == options.fileNameData.plistFile and filePath == options.fileNameData.path) then
			return
		end
	end
	local parent = sprite:getParent()
	if parent == nil then
		return
	end
	local clsName = jsonNode.classname
	if clsName == nil then
		return
	end
	options.fileNameData.plistFile = plistFile
	options.fileNameData.path = filePath
	options.x = options.x or 0
	options.y = options.y or 0
	local uiNode = self:createSpriteIcon( options, sprite.jsonNode, isGray )
	if uiNode == nil then
		return
	end
	uiNode.name = options.name or "unknow node"

	sprite:removeFromParentAndCleanup(true)
	parent:addChild(uiNode)

	if options.flipX then
		if uiNode.setFlipX then
			uiNode:setFlipX(options.flipX)
		end
	end
	if options.flipY then
		if uiNode.setFlipY then
			uiNode:setFlipY(options.flipY)
		end
	end
	uiNode:setRotation(options.rotation or 0)

	uiNode:setScaleX((options.scaleX or 1) * uiNode:getScaleX())
	uiNode:setScaleY((options.scaleY or 1) * uiNode:getScaleY())
	uiNode:setVisible(options.visible)
	uiNode:setLocalZOrder(options.ZOrder or 0)
	-- uiNode:setGlobalZOrder(options.ZOrder or 0)
	uiNode:setTag(options.tag or 0)
end

function UIManager:setSpriteGray( sprite, bIsGray )
	if sprite == nil then
		return
	end
	local options = sprite.options
	local jsonNode = sprite.jsonNode
	if options == nil or  options.fileNameData == nil or jsonNode == nil then
		return
	end
	self:replaceSpriteIcon( sprite, options.fileNameData.plistFile, options.fileNameData.path, bIsGray )
end

function UIManager:createSpriteIcon( options, jsonNode, isGray )
	local params = {}
	params.scale9 = options.scale9Enable
	if params.scale9 then
		params.capInsets = cc.rect(options.capInsetsX, options.capInsetsY,options.capInsetsWidth, options.capInsetsHeight)
	end
    local sResName = self:transResName(options.fileNameData)
    if sResName == nil then
    	return
    end
    if isGray == true then
    	if string.sub( sResName, 1, 1 ) == '#' then
    		self:createGraySpriteFrame( string.sub( sResName, 2 ) )
    	end
    	if string.find( sResName, ".png" )  ~= nil then
			sResName = string.gsub( sResName, ".png", "___gray.png" )
		end
    end
    local node = cc.ui.UIImage.new(sResName, params)
	if not options.scale9Enable then
		local originSize = node:getContentSize()
		if options.width then
			options.scaleX = (options.scaleX or 1) * options.width/originSize.width
		end
		if options.height then
			options.scaleY = (options.scaleY or 1) * options.height/originSize.height
		end
	end
	if not options.ignoreSize then
		node:setLayoutSize(options.width, options.height)

		-- setLayoutSize have scaled
		options.scaleX = 1
		options.scaleY = 1
	end
	node:setPositionX(options.x or 0)
	node:setPositionY(options.y or 0)
	node:setAnchorPoint(cc.p(options.anchorPointX or 0.5, options.anchorPointY or 0.5))

	if options.touchAble then
		node:setTouchEnabled(true)
		node:setTouchSwallowEnabled(true)
	end
	if options.opacity then
		node:setOpacity(options.opacity)
	end
	node.options = options
	node.jsonNode = jsonNode
	return node
end

function UIManager:createGraySpriteFrame( filename )
	if filename == nil then
		return
	end
	local graySpriteName = filename
	if string.find( filename, ".png" ) ~= nil then
		graySpriteName = string.gsub( filename, ".png", "___gray.png" )
	end
	local grayFrame = sharedSpriteFrameCache:spriteFrameByName(graySpriteName)
	if grayFrame ~= nil then
		return
	end
	local frame = display.newSpriteFrame( filename )
	if frame ~= nil then
		local __graySprite = CCGraySprite:createWithSpriteFrame( frame )
		if __graySprite ~= nil then
			local contentSize = __graySprite:getContentSize()
			local __canva = CCRenderTexture:create( contentSize.width, contentSize.height )
			if __canva ~= nil then
				__graySprite:setLocalZOrder( 10 )
				__graySprite:setFlipY(true)
				__graySprite:setAnchorPoint( CCPoint( 0, 0) )
				__graySprite:setPosition( CCPoint(0,0) )
				__canva:begin()
				__graySprite:visit()
				__canva:endToLua()
				local spriteFrame = CCSpriteFrame:createWithTexture( __canva:getSprite():getTexture(), cc.rect( 0, 0, contentSize.width, contentSize.height )  )
				if spriteFrame ~= nil then
					sharedSpriteFrameCache:addSpriteFrame( spriteFrame, graySpriteName )
				end
			end
		end
	end
end

return UIManager
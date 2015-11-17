require("bdlib/tools/util")
require("app/model/Factory")

-- 游戏世界管理器
cMenu = class("cMenu")

function cMenu:ctor( scene, cfg )
	self.scene = scene
    self.cfg = cfg

    local bg,animCfg = Factory.createAnim(UZ_MENU_BG_ANIM)

	bg:pos(CONFIG_SCREEN_WIDTH / 2,CONFIG_SCREEN_HEIGHT / 2)

    self.scene:addChild(bg)

    local logo = Factory.createNormalSprite("ui_logo.png",CONFIG_SCREEN_WIDTH / 2,CONFIG_SCREEN_HEIGHT/2 + 150)

    self.scene:addChild(logo)

    local beginBtn = Factory.createMenuItemImage("ui_begin.png","ui_begin.png",CONFIG_SCREEN_WIDTH / 2,CONFIG_SCREEN_HEIGHT / 2 - 150,self.onBeginGame)

    local upgradeBtn = Factory.createMenuItemImage("ui_upgrade_btn.png","ui_upgrade_btn.png",display.width/2 + 120,display.height/2 - 250,self.onUpgradeHandler)

    local menu = ui.newMenu({beginBtn,upgradeBtn})
    menu:pos(0,0)
    self.scene:addChild(menu)

end


function cMenu:onEnter()

end


function cMenu:onExit()

end


function cMenu:onBeginGame()
	app:enterChoiceMission(app.planeId)
end

function cMenu:onUpgradeHandler()
   app:enterSelectPlane()
end
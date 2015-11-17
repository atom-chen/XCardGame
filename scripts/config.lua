
-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 0

-- display FPS stats on screen
DEBUG_FPS = false

-- dump memory info every 10 seconds
DEBUG_MEM = false

--调试信息面板
DEBUG_INFO_PANEL = false

--zb studio远程调试
DEBUG_MOB_OPEN = false

-- 调试包围盒
DEBUG_BOUND_BOX = false

--Debug单位信息显示
DEBUG_UNIT_INFO_LABEL = false

-- 改变时间流速,便于察看包围盒的碰撞情况
DEBUG_TIME_SPEED = 1

-- load deprecated API
LOAD_DEPRECATED_API = false

-- load shortcodes API
LOAD_SHORTCODES_API = true

-- screen orientation
CONFIG_SCREEN_ORIENTATION = "portrait"

-- design resolution
CONFIG_SCREEN_WIDTH  = 720
CONFIG_SCREEN_HEIGHT = 1280

-- auto scale mode
CONFIG_SCREEN_AUTOSCALE = "FIXED_HEIGHT"


-------------------------------------------------------------------
-- 工具相关初始化
-------------------------------------------------------------------
-- string = require "bdlib/lang/string"
-- table = require "bdlib/lang/table"
-- Logger = require "bdlib/tools/Logger"
-- require "bdlib/tools/MathAngle"


-- -- 替换掉string中的fromfile函数
-- string.fromfile = function( filePath )
-- 	return cc.FileUtils:getInstance():getStringFromFile(filePath) or ""
-- end

-- -- 随机数种子
-- math.randomseed(os.time())

-- -- 屏蔽掉dump函数
-- dump = function ( ... )
-- 	-- body
-- end



-- sounds
GAME_SFX = {
    tapButton           = "sfx_new/button_pressed.mp3",
    shootBullet         = "sfx/shootBullet.mp3",
    continueGame        = "sfx/continueGame.mp3",
    bossEntrance        = "sfx/bosswaring.wav",
    planeExplosion      = "sfx_new/plane_bomb.mp3",
    --backButton          = "sfx/BackButtonSound.mp3",
    --flipCoin            = "sfx/ConFlipSound.mp3",
    missionCompleted    = "sfx_new/game_win.mp3",
    missionFailed       = "sfx/missionFailed.mp3",
    missionStart        = "sfx/missionStart.mp3",
    pickProps           = "sfx_new/gold.mp3",
    fullPower           = "sfx/fullPower.mp3",
    useBomb             = "sfx_new/plane_bomb.mp3",
}

GAME_MUSIC = {
    outMission          = "sfx_new/BGM/battle_bgm_01.mp3",
    enterMission        = "sfx_new/BGM/battle_normal.mp3",
}
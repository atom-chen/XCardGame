

_G.MyApp = nil

string = require "bdlib/lang/string"
table = require "bdlib/lang/table"
Logger = require "bdlib/tools/Logger"
require "bdlib/tools/MathAngle"


-- 替换掉string中的fromfile函数
string.fromfile = function( filePath )
	return cc.FileUtils:getInstance():getStringFromFile(filePath) or ""
end

-- 随机数种子
math.randomseed(os.time())

-- 屏蔽掉dump函数
dump = function ( ... )
	-- body
end




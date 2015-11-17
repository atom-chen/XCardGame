function TODO( ... )
	print("[TODO]", ...)
end

local __require = _G["require"]

function __myRequire( path )
    return __require( string.gsub( path, '/', '.' ) )
end

_G["require"] = __myRequire

function __G__TRACKBACK__(errorMessage)
    print("----------------------------------------")
    print("LUA ERROR: " .. tostring(errorMessage) .. "\n")
    print(debug.traceback("", 2))
    print("----------------------------------------")
end

--local initconnection = require("debugger") 
--initconnection('127.0.0.1', 10000, 'luaidekey')
collectgarbage("setpause", 100)
collectgarbage("setstepmul", 5000)

_G.MyApp = require("app.MyApp")

if DEBUG_MOB_OPEN == true then
	require("mobdebug").start()
end

MyApp.new():run()

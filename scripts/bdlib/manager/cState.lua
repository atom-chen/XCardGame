local class 		= require("bdlib/lang/class")
local stateManager 	= require("bdlib/manager/StateManager")

--[[
	状态机对象基类
]]

cState = class( nil )

function cState:init()

	self.name = ""
	self.isLoading = false

end

function cState:onCreate( )
end

function cState:onLoading( )
end

function cState:onEnter( )
end

function cState:onUpdate( dt )
end

function cState:onLeave( )
end

function cState:onDestroy( )
end

function cState:onPause( )
end

function cState:onResume( )
end



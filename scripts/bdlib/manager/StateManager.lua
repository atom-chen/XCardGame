--[[
	状态机管理类
]]

StateManager = {}

local curStateName = nil 	-- 当前状态的名称
local curStateObj = nil 	-- 当前状态对象
local transitioning = false	-- 是否正在进行状态转换的标记




-- 进入状态
function StateManager.openState( stateName, stateObj, params )
	transitioning = true

	if curStateObj then
		curStateObj:onLeave()
		curStateObj:onDestroy()
	end

	if stateObj then
		stateObj.name = stateName
		stateObj:onCreate( params )
		stateObj:onEnter()
		transitioning = false
	end

	curStateObj = stateObj
end

-- 切换状态
function StateManager.openNextState( stateName, stateObj, params )
	return StateManager.openState( stateName, stateObj, params )
end

-- 每帧更新
function StateManager.onUpdate( dt )
	local curStateObj = curStateObj

	if not transitioning and curStateObj then
		if curStateObj.isLoading then
			curStateObj:onLoading()
		else
			curStateObj:onUpdate( dt )
		end
	end
end



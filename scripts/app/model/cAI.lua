
local tinsert = table.insert

local super = nil
cAI = class("cAI")

local _AIGroupDataMap = {}

function cAI:ctor( id, xMirror, yMirror )

	self.groups = {}

	-- 水平/垂直翻转标记
	self.xMirror = false
	self.yMirror = false

	self.loopCnt = 0 -- 本组AI命令的剩余循环次数
	self.curGroupIdx = nil -- 当前正在执行的组别
	self.curCmdIdx = nil -- 当前正在执行的命令序号( 在组中的需要 )
	self.aiTime = 0 -- 当前AI命令的剩余执行时间

	self.fireTime = 0

	-- 跟踪ai相关
	self.following = false
	self.followOnce = false
	self.followGroups = nil
	self.followUnit = nil
end


local function _createCmd( command, time, speed, angle, glist, rotSpeed, params )
	return {
			command = command,
			time = time,
			speed = speed,
			angle = angle,
			glist = glist,
			rotSpeed = rotSpeed,
			params = params
		}
end

function cAI:reset()
	self.loopCnt = 0 
	self.curGroupIdx = nil 
	self.curCmdIdx = nil
	self.aiTime = 0

	self.fireTime = 0

	self.following = false
	self.followOnce = false
	self.followGroups = nil
	self.followUnit = nil
end

function cAI:initByCfg( cfg, xMirror, yMirror )
	if not cfg then
		return false
	end
	local groupIdName = string.format( "%s_%s_%s", tostring(self.id), tostring(xMirror), tostring(yMirror) )
	if _AIGroupDataMap[groupIdName] == nil then
		_AIGroupDataMap[groupIdName] = self:creteAIGroupByCfg( cfg, xMirror, yMirror )
	end
	self.groups = _AIGroupDataMap[ groupIdName ]
end

function cAI:creteAIGroupByCfg( cfg, xMirror, yMirror )
	local group
	local groups = {}
	local cmdList = cfg
	local loopCnt

	local cmd

	local x1, y1, x2, y2
	local distance
	local command, time, speed, angle, glist, rotSpeed

	for i,v in ipairs(cmdList) do
		if v.cmd1 == "GROUP" then

			-- 添加一个新的AI组
			loopCnt = v.i1 -- 本组AI的重复次数
			group = {
				loopCnt = loopCnt,
				list = {},
			}
			tinsert(groups, group)
		elseif v.cmd1 == "CMD" then
			command = v.cmd2
			if command == "moveTo" then
				-- 移动到指定的相对位置
				if xMirror then
					x2 = -v.i2
				else
					x2 = v.i2
				end

				if yMirror then
					y2 = -v.i3
				else
					y2 = v.i3
				end

				angle = MathAngle_pointAngle( 0, 0, x2, y2 ) - 90-- 角度
				speed = v.i1 	-- 速度				
				distance = MathAngle_distance( 0, 0, x2, y2 )
				time = distance / speed -- 持续时间

				glist = nil
				tinsert( group.list , _createCmd( command, time, speed, angle, glist ))
			elseif command == "setColorTo" then
				time = 0
				speed = 0
				glist = nil
				tinsert( group.list , _createCmd( command, time, speed, angle, glist, nil, { {v.i1, v.i2, v.i3} } ))
			elseif command == "moveToPoint" then
				time = 0
				x2 = v.i2
				y2 = v.i3
				speed = v.i1
				glist = nil
				tinsert( group.list , _createCmd( command, time, speed, angle, glist, nil, { x2, y2 } ))
			elseif command == "circleBy" or command == "circleHead" then --飞机
				local circleAngle = v.i4
				if xMirror then
					x2 = -v.i2
					circleAngle = -v.i4
				else
					x2 = v.i2
				end

				if yMirror then
					y2 = -v.i3
					circleAngle = -v.i4
				else
					y2 = v.i3
				end
				local startRadian = MathAngle_pointAngle( x2, y2, 0, 0 )
				local segments = math.floor( math.abs( circleAngle / 5) )
				local radius = MathAngle_distance( 0, 0, x2, y2 )
            	local radianPerSegm = math.pi / 180
            	local destX = 0
            	local destY = 0
            	local beginX = 0
            	local beginY = 0
            	speed = v.i1 	-- 速度		
            	local sign = circleAngle / math.abs( circleAngle )
				for i = 1, segments do
					local radii = (startRadian - i * 5 * sign) * radianPerSegm
					destX = x2 + radius * math.cos(radii)
					destY = y2 + radius * math.sin(radii)

					angle = MathAngle_pointAngle( beginX, beginY, destX, destY ) - 90
					distance = MathAngle_distance( beginX, beginY, destX, destY )
					time = distance / speed -- 持续时间

					glist = nil
					tinsert( group.list , _createCmd( command, time, speed, angle, glist ))
					beginX = destX
					beginY = destY
				end
			elseif command == "stopFire" then
				-- 开火时间
				time = v.i1
				speed = 0
				angle = 0
				glist = nil
				tinsert( group.list , _createCmd( command, time, speed, angle, glist ))
			elseif command == "scaleTo" then
				time = v.i1
				speed = 0
				angle = 0
				glist = nil
				tinsert( group.list , _createCmd( command, time, speed, angle, glist, nil, { v.i2 } ))
			elseif command == "changeAnimView" then
				time = v.i1
				speed = 0
				angle = 0
				glist = nil
				tinsert( group.list , _createCmd( command, time, speed, angle, glist, nil, { v.i2, v.i3 } ))
			elseif command == "fireGunsNow" then
				time = v.i1
				speed = 0
				angle = 0
				glist = nil
				tinsert( group.list , _createCmd( command, time, speed, angle, glist, nil, { {v.i2,v.i3,v.i4,v.i5,v.i6}  } ))
			elseif command == "headBy" then --飞机头朝向一个点，开过去
				if xMirror then
					x2 = -v.i2
				else
					x2 = v.i2
				end

				if yMirror then
					y2 = -v.i3
				else
					y2 = v.i3
				end

				angle = MathAngle_pointAngle( 0, 0, x2, y2 ) - 90-- 角度
				speed = v.i1 	-- 速度				

				distance = MathAngle_distance( 0, 0, x2, y2 )
				time = distance / speed -- 持续时间

				glist = nil
				tinsert( group.list , _createCmd( command, time, speed, angle, glist, angle ))
			elseif command == "move" then
				-- 按指定方式移动
				speed = v.i1
				angle = v.i2
				time = v.i3

				if xMirror then
					angle = - angle
				end

				if yMirror then
					angle = 180 - angle
				end

				glist = nil
				tinsert( group.list , _createCmd( command, time, speed, angle - 90, glist ))
			elseif command == "rotateBy" then
				time = v.i1
				speed = v.i2
				if xMirror then
					speed = - speed
				end
				angle = 0 
				glist = nil
				local segments = math.floor( math.abs(speed) / 5)
				local sign = -v.i2 / math.abs(v.i2)
				speed = 0
				for i = 1, segments do
					tinsert( group.list , _createCmd( command, (time / segments), speed, sign * 5, glist ))
				end
			elseif command == "rotateSpeed" then
				time = 0
				speed = 0
				rotSpeed = -v.i1
				if xMirror then
					rotSpeed = rotSpeed
				end
				angle = 0
				glist = nil
				tinsert( group.list , _createCmd( command, time, speed, angle, glist, rotSpeed ))
			elseif command == "stop" then
				-- 悬停
				time = v.i1
				speed = 0
				angle = 0

				glist = nil
				tinsert( group.list , _createCmd( command, time, speed, angle, glist ))

			elseif command == "fire" then
				-- 开始开火
				time = v.i1
				speed = 0
				angle = 0

				glist = nil
				tinsert( group.list , _createCmd( command, time, speed, angle, glist ))

			elseif command == "hold" then
				-- 保持当前移动方式
				time = v.i1
				speed = 0
				angle = 0

				glist = nil
				tinsert( group.list , _createCmd( command, time, speed, angle, glist ))

			elseif command == "follow" or command == "followOnce" then
				-- 跟踪目标
				time = v.i1
				speed = 0
				angle = 0

				glist = {}
				local gid
				for i=2,6 do
					gid = v["i"..i]
					if gid ~= 0 then
						tinsert(glist, gid)
					end
				end

				tinsert( group.list , _createCmd( command, time, speed, angle, glist ))


			else
				Logger.warn("unknow cmd name:", command)
			end
		end
	end
	return groups
end

-- 执行下一步命令
function cAI:nextCmd( unit, timeModify )
	local group
	local curGroupIdx, curCmdIdx, loopCnt

	curGroupIdx = self.curGroupIdx
	curCmdIdx = self.curCmdIdx
	loopCnt = self.loopCnt

	local groupChanged = false -- 标记是否发生的ai组变化
	if not curGroupIdx or not curCmdIdx then
		curGroupIdx = 1
		curCmdIdx = 1
		groupChanged = true
	else
		curCmdIdx = curCmdIdx + 1 -- 本组下一条命令的序号
		group = self.groups[ curGroupIdx ]

		if curCmdIdx > #group.list then -- 本组命令已经执行完毕, 继续开始下一组命令
			loopCnt = loopCnt - 1
			curCmdIdx = 1 -- 重置cmd序号
			if loopCnt <= 0 then
				-- 循环计数已经完毕, 转到下一组命令
				curGroupIdx = curGroupIdx + 1
				groupChanged = true
			end
		end
	end

	group = self.groups[ curGroupIdx ]
	if not group then
		return false -- 没有下一组命令了
	end

	if groupChanged then
		loopCnt = group.loopCnt -- ai组发生了变化,需要重置循环次数
	end

	local cmd = group.list[ curCmdIdx ]
	if not cmd then
		return false
	end

	self.loopCnt = loopCnt
	self.aiTime = cmd.time
	self.curGroupIdx = curGroupIdx
	self.curCmdIdx = curCmdIdx

	self.following = false
	self.followOnce = false
	self.followGroups = nil
	self.followUnit = nil	

	local command = cmd.command
	if command == "fire" then
		self.fireTime = cmd.time
		unit:openGunsEx()
		return self:nextCmd(unit, timeModify)
	elseif command == "stopFire" then
		self.fireTime = 0
		unit:stopGunsEx()
		return self:nextCmd(unit, timeModify)
	elseif command == "scaleTo" then
		if unit.view ~= nil then
			unit.view:runAction( CCScaleTo:create( cmd.time, tonumber(cmd.params[1]) or 1, tonumber(cmd.params[1]) or 1 ) )
		end
	elseif command == "changeAnimView" then
		if cmd.params ~= nil then
			unit:changeAnimView( tonumber(cmd.params[1]), tonumber(cmd.params[2]))
		end
	elseif command == "fireGunsNow" then
		self.fireTime = cmd.time
		if cmd.params ~= nil then
			unit:openGuns()
			unit:fireGunsNow( cmd.params[1] )
		end
	elseif command == "moveToPoint" then
		cmd.angle = MathAngle_pointAngle( unit.x, unit.y, cmd.params[1], cmd.params[2] ) - 90		
		local distance = MathAngle_distance( unit.x, unit.y, cmd.params[1], cmd.params[2] )
		self.aiTime = (distance / cmd.speed )
		unit:setSAR(cmd.speed, cmd.angle, nil)
	elseif command == "setColorTo" then
		unit:setColor( unpack(cmd.params[1]) )
	elseif command == "stop" then
		unit:setSAR(0, nil, nil)
		local x, y = unit:getPosition()
	elseif command == "hold" then
	elseif command == "rotateBy" then
		unit:setSAR( nil, nil, unit.rotation + cmd.angle )
	elseif command == "rotateSpeed" then
		unit.rotSpeed = cmd.rotSpeed
	elseif command == "follow" then
		self.following = true
		self.followOnce = false
		self.followGroups = cmd.glist
	elseif command == "headBy" then
		unit:setSAR(cmd.speed, cmd.angle, cmd.angle)
	elseif command == "circleBy" then
		unit:setSAR(cmd.speed, cmd.angle, nil )
	elseif command == "circleHead" then
		unit:setSAR(cmd.speed, cmd.angle, cmd.angle)
	elseif command == "followOnce" then
		self.following = true
		self.followOnce = true
		self.followGroups = cmd.glist
	else
		unit:setSAR(cmd.speed, cmd.angle, nil )
	end	
	return true
end


function cAI:updateFollow( unit , dt )
	if self.following then -- 当前处于跟踪状态
		if self.followOnce and not self.followGroups then
			-- 单次跟踪,并且已经进行过跟踪了
			if unit:checkOutOfRange() then
				unit:remove()
				return true
			end
			return
		end

		local followUnit = self.followUnit
		local x, y = unit:getPosition()

		if followUnit then
			if not followUnit:isValid() then
				followUnit = nil
			end
		end

		if not followUnit then
			-- 寻找新的跟踪目标
			followUnit = unit.world:getRandomUnit(x, y, self.followGroups)
		end

		self.followUnit = followUnit

		-- 存在跟踪目标
		if followUnit then
			local tarX, tarY = followUnit:getPosition()
			local angle = MathAngle_pointAngle( tarX, tarY, x, y )
			unit:setSAR(nil, angle + 90, angle - 90)
		end

		if unit:checkOutOfRange() then
			unit:remove()
			return true
		end

		if self.followOnce then
			self.followGroups = nil
		end
	end
	return false
end

function cAI:update( unit, dt )
	local aiTime = self.aiTime - dt
	local realDt = dt

	if self:updateFollow( unit ,realDt) then
		return 
	end

	unit:move( realDt )

	if self.stopFire ~= true and self.fireTime > 0 and unit.fireDelayTime == 0 then
		unit:updateGuns( realDt )
		self.fireTime = self.fireTime - dt
	end

	local selfExplosionTime = unit.selfExplosionTime
	if selfExplosionTime ~= nil and selfExplosionTime > 0 then
		selfExplosionTime = selfExplosionTime - dt
		unit.selfExplosionTime = selfExplosionTime
		if selfExplosionTime <= 0 then
			unit:doExplosion( true )
			unit.needDel = true
			return
		end
	end

	if aiTime <= 0 then
		if not self:nextCmd( unit, -aiTime ) then
			unit:remove()
			return 
		end
	else
		self.aiTime = aiTime
	end
end

function cAI:stopFire()
	self.stopFire = true
end

function cAI:openFire()
	self.stopFire = false
end
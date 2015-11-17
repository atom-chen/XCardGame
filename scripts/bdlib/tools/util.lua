local _tinsert 		= table.insert

local _strSub 		= string.sub
local _strFind 		= string.find
local _strFmt 		= string.format

local _mathFloor 	= math.floor

local class = require("bdlib/lang/class")

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--
-- Ipp 一个简易的模拟数字自增的类
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--
Ipp = class( nil )
function Ipp:init( i )
	self.i = i or 0
end

function Ipp:next( i )
	if not i then
		i = self.i + 1
	end
	self.i = i
	return i
end
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--
-- Ipp end
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--



--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--
-- quick sort begin
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--

--- key值快速排序基础函数,不应对外开放
local function _quickSortBase(p)
    if p == nil or p.h >= p.t then return end

    local head,tail
    head = p.h
    tail = p.t

    local ka = p.ka
    local a = p.a
    local f = p.f

    local key = ka[head]

    local left,right
    
    left,right = head,tail
    
    while left < right do
        while (left <right) and f(a[ka[right]],a[key]) >= 0 do
            right = right - 1
        end
        ka[left] = ka[right]
        
    
        while (left < right) and f(a[ka[left]] ,a[key]) < 0 do
            left = left + 1
        end
        ka[right] = ka[left]
    end
    ka[left] = key


    p.h = head
    p.t = left - 1
    _quickSortBase(p)
    p.h = left + 1
    p.t = tail
    _quickSortBase(p)
end 

--- 快速排序算法
-- 本算法适用于key为连续整数的table排序,会【直接修改】原table中的元素位置
-- @param a 需要排序的表
-- @param head 表中需要排序的下标起始位置
-- @param tail 表中需要排序的下标终止位置
-- @param 比较函数 比较函数,格式为 function(v1,v2)的形式,返回值 <0 v1排在v2前; >0 v1排在v2后; =0 v1,v2相等
function gfQuickSort( a, head, tail, f )
    if head >= tail then
        return
    end
    local qsfunc = gfQuickSort
    local key = a[head]
    local left,right
    
    left,right = head,tail
    
    while left < right do
        while (left <right) and f(a[right],key) >= 0 do
            right = right - 1
        end
        a[left] = a[right]
        
    
        while (left < right) and f(a[left] ,key) < 0 do
            left = left + 1
        end
        a[right] = a[left]
    end
    a[left] = key

    qsfunc( a, head, left - 1, f )
    qsfunc( a, left + 1,tail, f )
end 

--- 快速排序算法
-- 本算法适用key为任意值的table的排序,返回值为原table的key的序列table,不会直接操作原table
-- @param a 需要排序的表
-- @param f 比较函数,格式为 function(v1,v2)的形式,返回值 <0 v1排在v2前; >0 v1排在v2后; =0 v1,v2相等
function gfQuickSort2(a,f)
    local ka = {}
    for k, v in pairs( a ) do
        _tinsert( ka, k )
    end
    local p = {}
    p.a = a
    p.ka = ka
    p.h = 1
    p.t = table.getn(ka)
    p.f = f
    _quickSortBase(p)
    return ka
end


function gfSplite( str, sep, f)
	if not str or not sep then
		return nil
	end

	local posBegin ,subStr
	local ret = {}
	while str ~= "" do

		posBegin 	= _strFind(str, sep)  	
		if posBegin == nil then
			subStr 	= str
			str 	= ""
		else
			subStr 	= _strSub(str, 0, posBegin - 1)
			str 	= _strSub(str, posBegin + 1, -1)
		end

		if f then
			subStr = f(subStr)
		end
		_tinsert(ret, subStr)
	end 

	return ret
end
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--
-- quick sort end
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--

local S_MINUTE 	= 60
local S_HOUR 	= 60 * S_MINUTE
local S_DAY 	= 24 * S_HOUR

function gfTime2Str( time, lang )
	local ret = {}

	time = time or 1
	if time <= 0 then
		time = 1
	end

	lang = lang or LANG_DEFAULT

	local day, hour, minute, second
	local size = 0
	local TXT = TextMgr._TXT

	day = _mathFloor( time / S_DAY )
	if day > 0 then
		_tinsert(ret, _strFmt("%d%s", day, TXT(1, lang)))
		size = 1 + size
		time = time % S_DAY
	end

	if time > 0 then
		hour = _mathFloor( time / S_HOUR )
		if size > 0 or hour > 0 then
			_tinsert(ret, _strFmt("%d%s", hour, TXT(2, lang)))
			size = 1 + size		
			time = time % S_HOUR
		end
	end

	if time > 0 then
		minute 	= _mathFloor( time / S_MINUTE )
		if size > 0 or minute > 0 then
			_tinsert(ret, _strFmt("%d%s", minute, TXT(3, lang)))
			size = 1 + size		
			time = time % S_MINUTE
		end
	end

	if time > 0 then
		second 	= time
		if size > 0 or second > 0 then
			_tinsert(ret, _strFmt("%d%s", second, TXT(4, lang)))
			size = 1 + size		
		end	
	end

	return table.concat(ret)
end

function gfQuickDistance( x1, y1, x2, y2 )
	if not x1 or not y1 or not x2 or not y2 then
		Logger.error("gfQuickDistance ", x1, y1, x2, y2 )
		return 0
	end
	
	local dx = x1 - x2
	local dy = y1 - y2
	if dx < 0 then dx = -dx end
	if dy < 0 then dy = -dy end
	if dx > dy then		return dx	end
	return dy
end

local g_strIdCount = 0 -- 用于产生一个全局id
function gfCreateStrId( preStr , time )
	local ret = _strFmt("%s_%d_%d", preStr or "", time or os.time(), g_strIdCount)
	g_strIdCount = g_strIdCount + 1
	if g_strIdCount > 9999999 then
		g_strIdCount = 0
	end
	return ret
end


-- require "_conf"

local _sysLogWriteCount = nil -- LOGGER_SYS_LOG_WRITE_COUNT    -- sysLog记录的写入次数
local _consoleWriteCount = 1 --LOGGER_CONSOLE_WRITE_COUNT   -- 控制台日志的写入次数


local _strFmt = string.format
local _tinsert = table.insert
local _tconcat = table.concat

-- local print = print
local tconcat = _tconcat
local tinsert = _tinsert
local srep = string.rep
local type = type
local pairs = pairs
local tostring = tostring
local next = next

local logging
if _sysLogWriteCount then
    logging = require "_logging"
    require "lsyslog"
end

-- syslog 相关初始化
local _logger
if _sysLogWriteCount then
    local convert =
    {
        [logging.DEBUG] = lsyslog.LOG_DEBUG,
        [logging.INFO]  = lsyslog.LOG_INFO,
        [logging.WARN]  = lsyslog.LOG_WARNING,
        [logging.ERROR] = lsyslog.LOG_ERR,
        [logging.FATAL] = lsyslog.LOG_ALERT,
    }

    local FACILITY_KERN     = 0
    local FACILITY_USER     = 8
    local FACILITY_MAIL     = 16
    local FACILITY_DAEMON   = 24
    local FACILITY_AUTH     = 32
    local FACILITY_SYSLOG   = 40
    local FACILITY_LPR      = 48
    local FACILITY_NEWS     = 56
    local FACILITY_UUCP     = 64
    local FACILITY_CRON     = 72
    local FACILITY_AUTHPRIV = 80
    local FACILITY_FTP      = 88
    local FACILITY_LOCAL0   = 128
    local FACILITY_LOCAL1   = 136
    local FACILITY_LOCAL2   = 144
    local FACILITY_LOCAL3   = 152
    local FACILITY_LOCAL4   = 160
    local FACILITY_LOCAL5   = 168
    local FACILITY_LOCAL6   = 176
    local FACILITY_LOCAL7   = 184

    local _lsyslog_log = lsyslog.log
    local function _logger_append (self, level, message)
        _lsyslog_log(convert[level] or lsyslog.LOG_INFO, message)
        return true
    end
    _logger = logging.new(_logger_append)        
end

--------------------------------------------------------------------------------
-- This class is for log output.
--
-- @class table
-- @name Logger
--------------------------------------------------------------------------------
-- local CL_WHITE      =   "\033[1;37m"
-- local CL_BLUE       =   "\033[1;34m"
-- local CL_YELLOW     =   "\033[1;33m"
-- local CL_RED        =   "\033[1;31m"
local CL_WHITE      =   0
local CL_BLUE       =   1
local CL_YELLOW     =   2
local CL_RED        =   3
local CL_GRAY       =   "\033[1;30m"
local CL_GREEN      =   "\033[1;32m"
local CL_MAGENTA    =   "\033[1;35m"
local CL_CYAN       =   "\033[1;36m"

local CL_RESET      =   CL_WHITE
local M = {}

-- Constraints
local LOG_LEVEL_NONE = 0
local LOG_LEVEL_INFO = 1
local LOG_LEVEL_WARN = 2
local LOG_LEVEL_ERROR = 3
local LOG_LEVEL_DEBUG = 4
local LOG_LEVEL_LOG = 5

--------------------------------------------------------------------------------
-- A table to select whether to output the log.
--------------------------------------------------------------------------------
local selector = {
    [LOG_LEVEL_INFO]  = true,
    [LOG_LEVEL_WARN]  = true,
    [LOG_LEVEL_ERROR] = true,
    [LOG_LEVEL_DEBUG] = true,
    [LOG_LEVEL_LOG]   = true,
    }

-- Make print message objs to one string
local function _makeMessageStr(...)

    local value
    local t = {...}
    if #t > 0 then
        local tt = {}
        for i,v in ipairs(t) do
            _tinsert(tt, tostring(v))
            _tinsert(tt, " ")
        end
        value = _tconcat(tt)
    else
        value = ""
    end
    return value
end    
--------------------------------------------------------------------------------
-- This is the log target.
-- Is the target output to the console.
--------------------------------------------------------------------------------
local LOG_CONSOLE_TARGET_NORMAL
-- local LOG_CONSOLE_TARGET
-- if not _sysLogWriteCount then
--     LOG_CONSOLE_TARGET = function ( str )
--         return str
--     end
-- else
--     LOG_CONSOLE_TARGET = 
-- end

--------------------------------------------------------------------------------
-- This is the log target.
--------------------------------------------------------------------------------
local logTarget = LOG_CONSOLE_TARGET

local tstr = function (str)
 return _strFmt("%s[%s]",str or "",os.date("%m-%d %H:%M:%S"))
end

--------------------------------------------------------------------------------
-- The normal log output.
--------------------------------------------------------------------------------
function M.info(...)
    if _sysLogWriteCount then
        _logger:info(_makeMessageStr("[info] ",...))
    end

    if _consoleWriteCount > 0 then
        if selector[LOG_LEVEL_INFO] then
            -- if CppCommon then CppCommon.PrintColor(CL_WHITE) end
            print(tstr("[info] "),...)
            -- if CppCommon then CppCommon.PrintColor(CL_RESET) end
        end        
    end
end

function M.fInfo( fmtStr , ...)
    local message = _strFmt(fmtStr , ...)
    if _sysLogWriteCount then
       message = _strFmt("[info] %s", message)
        for i=1,_sysLogWriteCount do
           _logger:info(message)
        end
    end

    if _consoleWriteCount > 0 then
        if selector[LOG_LEVEL_INFO] then
            message = _strFmt(tstr("[info] %s"), message)
            -- if CppCommon then CppCommon.PrintColor(CL_WHITE) end
            print(message)
            -- if CppCommon then CppCommon.PrintColor(CL_RESET) end
        end          
    end
end

--------------------------------------------------------------------------------
-- The warning log output.
--------------------------------------------------------------------------------
function M.warn(...)
    if _sysLogWriteCount then
        for i=1,_sysLogWriteCount do
        _logger:warn(_makeMessageStr("[warn] ",...))
        end
    end

    if _consoleWriteCount > 0 then
        if selector[LOG_LEVEL_WARN] then
            if CppCommon then CppCommon.PrintColor(CL_YELLOW) end
            print(tstr("[warn] "),...)
            if CppCommon then CppCommon.PrintColor(CL_RESET) end
        end        
    end
end

function M.fWarn( fmtStr , ...)
    local message = _strFmt(fmtStr , ...)
    if _sysLogWriteCount then
        for i=1,_sysLogWriteCount do
           _logger:warn(_strFmt("[warn] %s", message))
        end
    end

    if _consoleWriteCount > 0 then
        if selector[LOG_LEVEL_WARN] then
            if CppCommon then CppCommon.PrintColor(CL_YELLOW) end
            print(_strFmt(tstr("[warn] %s"), message))
            if CppCommon then CppCommon.PrintColor(CL_RESET) end
        end          
    end
end

--------------------------------------------------------------------------------
-- The error log output.
--------------------------------------------------------------------------------
function M.error(...)
    if _sysLogWriteCount then
        for i=1,_sysLogWriteCount do
        _logger:error(_makeMessageStr("[error] ",...))
        end
    end

    if _consoleWriteCount > 0 then
        if selector[LOG_LEVEL_ERROR] then
            if CppCommon then CppCommon.PrintColor(CL_RED) end
            print(tstr("[error] "),...)
            print(debug.traceback())
            if CppCommon then CppCommon.PrintColor(CL_RESET) end
        end        
    end
end

function M.fError( fmtStr , ...)
    local message = _strFmt(fmtStr , ...)
    if _sysLogWriteCount then
        for i=1,_sysLogWriteCount do
           _logger:error(_strFmt("[error] %s", message))
        end
    end

    if _consoleWriteCount > 0 then
         if selector[LOG_LEVEL_ERROR] then
            if CppCommon then CppCommon.PrintColor(CL_RED) end
            print(_strFmt(tstr("[error] %s"), message))
            print(debug.traceback())
            if CppCommon then CppCommon.PrintColor(CL_RESET) end
        end          
    end
end

--------------------------------------------------------------------------------
-- The debug log output.
--------------------------------------------------------------------------------
function M.debug(...)
    local message = _makeMessageStr(...)
    if _sysLogWriteCount then
        for i=1,_sysLogWriteCount do
        _logger:debug(_makeMessageStr("[debug] ",message))
        end
    end

    if _consoleWriteCount > 0 then
        if selector[LOG_LEVEL_DEBUG] then
            if CppCommon then CppCommon.PrintColor(CL_BLUE) end
            print(tstr("[debug] "),...)
            if CppCommon then CppCommon.PrintColor(CL_RESET) end
        end        
    end
end

function M.fDebug( fmtStr , ...)
    local message = _strFmt(fmtStr , ...)
    if _sysLogWriteCount then
        for i=1,_sysLogWriteCount do
           _logger:debug(_strFmt("[debug] %s", message))
        end
    end

    if _consoleWriteCount > 0 then
        if selector[LOG_LEVEL_DEBUG] then
            if CppCommon then CppCommon.PrintColor(CL_BLUE) end
            print( _strFmt(tstr("[debug] %s"), message))
            if CppCommon then CppCommon.PrintColor(CL_RESET) end
        end        
    end
end


--------------------------------------------------------------------------------
-- print whole table
--------------------------------------------------------------------------------

local function _stab(numTab)
    local str = ""
    for i = 1, numTab do
        str = str .. "    "
    end
    return str
end

local function _getTableStr( tb )
    local tabNum = 0
    local outStrs = {}
    local function _printTable( t )
        _tinsert(outStrs, _stab(tabNum) .. "{\n")
        tabNum = tabNum + 1
        for k, v in pairs( t ) do
            local kk
            if type(k) == "string" then
                kk = "['" .. k .. "']"
            else
                kk = "[" .. k .. "]"
            end
            if type(v) == "table" then
                if type(k) == "string" or type(k) == "number" then
                    _tinsert(outStrs, _stab(tabNum) .. kk .. " = \n")
                end
                _printTable( v )
            else
                local vv = ""
                if type(v) == "string" then
                    vv = "'" .. v .. "'"
                elseif type(v) == "number" then
                    vv = tostring(v)
                else
                    vv = "[" .. type(v) .. "]"
                end
                
                if type(k) == "string" or type(k) == "number" then
                    _tinsert(outStrs, _stab(tabNum) .. kk .. "\t= " .. vv .. ",\n")
                else
                    _tinsert(outStrs, _stab(tabNum) .. vv .. ",\n")
                end
            end
        end
        tabNum = tabNum - 1

        if tabNum == 0 then
            _tinsert(outStrs, _stab(tabNum) .. "}\n")
        else
            _tinsert(outStrs, _stab(tabNum) .. "},\n")
        end
    end
    
    _tinsert(outStrs, "\n----------begin[")
    _tinsert(outStrs, tostring(tb))
    _tinsert(outStrs, "]----------\n")
    if not tb then
        _tinsert(outStrs, "nil")
    else
        _printTable( tb )
    end
    _tinsert(outStrs, "----------end  [")
    _tinsert(outStrs, tostring(tb))
    _tinsert(outStrs,"]----------\n")

    return _tconcat(outStrs)
end

function M.printTable( tb )
    if _sysLogWriteCount then
        for i=1,_sysLogWriteCount do
            _logger:debug(_getTableStr(tb))
        end
    end

    if _consoleWriteCount > 0 then
        if CppCommon then CppCommon.PrintColor(CL_BLUE) end
        print(_getTableStr(tb))
        if CppCommon then CppCommon.PrintColor(CL_RESET) end
    end
end


---[[
function M.print_r(root)
    local cache = {  [root] = "." }
    local function _dump(t,space,name)
        local temp = {}
        for k,v in pairs(t) do
            local key = tostring(k)
            if cache[v] then
                tinsert(temp,"+" .. key .. " {" .. cache[v].."}")
            elseif type(v) == "table" then
                local new_key = name .. "." .. key
                cache[v] = new_key
                tinsert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. srep(" ",#key),new_key))
            else
                tinsert(temp,"+" .. key .. " [" .. tostring(v).."]")
            end
        end
        return tconcat(temp,"\n"..space)
    end
    print(_dump(root, "",""))
end
--]]


--------------------------------------------------------------------------------
-- The normal log log.
--------------------------------------------------------------------------------
function M.log(...)
    if _sysLogWriteCount then
            for i=1,_sysLogWriteCount do
            _logger:info(_makeMessageStr("[log] ",...))
            end
    end
    if _consoleWriteCount > 0 then
        if selector[LOG_LEVEL_LOG] then
            -- if CppCommon then CppCommon.PrintColor(CL_WHITE) end
            print(tstr("[log] "),...)
            -- if CppCommon then CppCommon.PrintColor(CL_RESET) end
        end     
    end

  
end

function M.fLog( fmtStr , ...)
    local message = _strFmt(fmtStr , ...)
    if _sysLogWriteCount then
       message = _strFmt("[log] %s", message)
        for i=1,_sysLogWriteCount do
           _logger:info(message)
        end
    end

    if _consoleWriteCount > 0 then
        if selector[LOG_LEVEL_LOG] then
            message = _strFmt(tstr("[log] %s"), message)
            -- if CppCommon then CppCommon.PrintColor(CL_WHITE) end
            print(message)
            -- if CppCommon then CppCommon.PrintColor(CL_RESET) end
        end        
    end

end


function M.setWriteCount( syslogWriteCount, consoleWriteCount )
    -- TODO("Logger.setWriteCount", syslogWriteCount, consoleWriteCount)
    if type(syslogWriteCount) ~= "number" then
        syslogWriteCount = 0
    end

    if type(consoleWriteCount) ~= "number" then
        consoleWriteCount = 0
    else
        if consoleWriteCount > 1 then
            consoleWriteCount = 1 -- 控制台输出最多允许一次
        end
    end

    _sysLogWriteCount = syslogWriteCount
    _consoleWriteCount = consoleWriteCount
end

function M.getWriteCount(  )
    -- TODO("Logger.setWriteCount", syslogWriteCount, consoleWriteCount)
    return _sysLogWriteCount, _consoleWriteCount
end


return M

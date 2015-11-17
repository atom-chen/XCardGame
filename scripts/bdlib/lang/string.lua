local debugMode = false
--------------------------------------------------------------------------------
-- modules that extend functionality of the string.
--------------------------------------------------------------------------------
local M = {}
setmetatable(M, {__index = string})
local string = M

--------------------------------------------------------------------------------
-- Converts the string to number, or returns string if fail.
--------------------------------------------------------------------------------
function string.toNumber( self )
    local ret = tonumber( self )
    if type( ret ) =="number" then
        return ret
    else
        return self
    end
end

--------------------------------------------------------------------------------
--  Converts number to string, filling in zeros at beginning.
--  Technically, this shouldn't really extend string class
--  because it doesn't operate on string (doesn't have a "self" )
--  Usage:  print( string.fromNumbersWithZeros( 421, 6 ) )
--          000421
--------------------------------------------------------------------------------
function string.fromNumberWithZeros( n, l )
    local s = tostring ( n )
    local sl = string.len ( s )
    if sl < l then
        -- add zeros before
        for i=1, l - sl do
            s = "0"..s
        end
    end
    return s
end

--------------------------------------------------------------------------------
--  Converts hex number to rgb (format: #FF00FF)
--------------------------------------------------------------------------------
function string.hexToRGB( s, returnAsTable )
    if returnAsTable then
        return  { tonumber ( string.sub( s, 2, 3 ),16 )/255.0,
                tonumber ( string.sub( s, 4, 5 ),16 )/255.0,
                tonumber ( string.sub( s, 6, 7 ),16 )/255.0 }
    else
        return  tonumber ( string.sub( s, 2, 3 ),16 )/255.0,
                tonumber ( string.sub( s, 4, 5 ),16 )/255.0,
                tonumber ( string.sub( s, 6, 7 ),16 )/255.0
    end
end


--------------------------------------------------------------------------------
-- Splits string into N lines, using default ("#") or custom delimiter
-- Routine separate words by spaces so make sure you have them.
-- USAGE:   For a string "width:150 height:150", or "width:150_height:150"
--          returns a table { width=150, height=150 }
--------------------------------------------------------------------------------
function string.toTable( self, delimiter )

    local t = {}

    if not delimiter then delimiter = " " end
    local kvPairs = self:split( delimiter )

    local k, v, kvPair

    for i=1, #kvPairs do
        kvPair = kvPairs[i]:split( ":" )

        if #kvPair == 2 then
            t[ kvPair[1] ] = string.toNumber( kvPair[2] )
        end

    end


    return t
end

--------------------------------------------------------------------------------
-- Splits string into a table of strings using delimiter.<br>
-- Usage: local table = a:split( ",", false )<br>
-- TODO:  Does not correspond to multi-byte.<br>
-- @param self string.
-- @param delim Delimiter.
-- @param toNumber If set to true or to be converted to a numeric value.
-- @return Split the resulting table
--------------------------------------------------------------------------------
function string.split( self, delim, toNumber )
    
    local start = 1
    local t = {}  -- results table
    local newElement
    -- find each instance of a string followed by the delimiter
    while true do
        local pos = string.find (self, delim, start, true) -- plain find
        if not pos then
            break
        end
        -- force to number
        newElement = string.sub (self, start, pos - 1)
        if toNumber then
            newElement = string.toNumber(newElement) --newElement:toNumber()
        end
        table.insert (t, newElement)
        start = pos + string.len (delim)
    end -- while

    -- insert final one (after last delimiter)
    local value =  string.sub (self, start)
    if toNumber then
        value = string.toNumber(value) --value:toNumber()
    end
    table.insert (t,value )
    return t
end

-- 字符串分割， 当多个分割符连在一起时，会被当成一个分割符
-- 例如: "a|b|||c||d" 用 "|" 来进行分割时，会被分割为 { "a", "b", "c", "d" }
function string.split2( self, delim, toNumber )
    
    if type(self) ~= "string" then
        return {}
    end

    local length = #self
    local sepLen = #delim

    local start = 1
    local t = {}  -- results table
    local newElement
    -- find each instance of a string followed by the delimiter
    local pos, strTemp
    while true do
        pos = string.find (self, delim, start, true) -- plain find
        if not pos then
            break
        end

        -- force to number
        newElement = string.sub (self, start, pos - 1)
        if toNumber then
            newElement = string.toNumber(newElement) --newElement:toNumber()
        end
        table.insert (t, newElement)
        start = pos + sepLen
        while true do
            if start > length then
                break
            end
            strTemp = string.sub( self, start, start + sepLen - 1)
            if strTemp ~= delim then
                break
            end
            start = start + sepLen
        end
    end -- while

    -- insert final one (after last delimiter)
    local value =  string.sub (self, start)
    if toNumber then
        value = string.toNumber(value) --value:toNumber()
    end
    table.insert (t,value )
    return t
end

--------------------------------------------------------------------------------
-- Splits string into N lines, using default ("#") or custom delimiter
-- Routine separate words by spaces so make sure you have them.
-- Usage: local string = s:splitIntoLines( 3, "\n" )
--------------------------------------------------------------------------------
function string.splitToLines( self, numLines, delim )
    
    local result = ""
    delim = delim or "#"    -- Default delimiter used for display.newText

    numLines = numLines or 2
    -- break into all words.
    local allWords = self:split( " " )
    if #allWords < numLines then
        numLines = #allWords
    end

    -- Words per line
    local wordsPerLine = math.ceil( #allWords/numLines )
    local counter = wordsPerLine

    for i=1, #allWords do
        result = result..allWords[i]
        counter = counter - 1
        if counter == 0 and i<#allWords then
            counter = wordsPerLine
            result = result..delim
        else
            result = result.." "
        end
    end

    return result
end

------------------------------------------------------------------------------
--  String encryption
--------------------------------------------------------------------------------
function string.encrypt( str, code )
    code = code or math.random(3,8)
    local newString = string.char( 65 + code )
    local newChar
    for i=1, str:len() do
        newChar = str:byte(i) + code
        newString = newString..string.char(newChar)
    end
    return newString
end

------------------------------------------------------------------------------
--  String encryption
--------------------------------------------------------------------------------
function string.decrypt( str )
    local newString = ""
    local code = str:byte(1) - 65
    for i = 2, str:len() do
        newChar = str:byte(i) - code
        newString = newString..string.char(newChar)
    end
    return newString
end

--cdsc add start
function string.u8foreach(str, callback)
    if not str or not callback then
        return
    end
    local i = 1
    local multiLen = #str
    while( i <= multiLen ) do
        local s = string.sub(str, i, i)
        local b = string.byte(s)
        local skip = 0
        if b>=0xf0 and b<=0xf7 then
            skip = 3
        elseif b>=0xe0 then
            skip = 2
        elseif b>=0xc0 then
            skip = 1
        end
        local i2 = i + skip
        if ( callback(string.sub(str, i, i2 ), i, i2) ) then
            break
        end
        i = i2 + 1
  end
end

function string.u8len(str)
    local len = 0
        string.u8foreach(str, function() len = len + 1 end)
    return len
end

function string.u8sub(str, idx1, idx2)
    if not str or not idx1 then
        return nil
    end
    idx2 = idx2 or 0xffffffff
    if idx1 > idx2 then
        return nil
    end
    local loc = 1
    local st, ed = 1,1
    local function _each(ch, starti, endi )
        if loc == idx1 then
            st = starti
        end
        if loc <= idx2 then
            ed = endi
        else
          return true
        end
        loc = loc + 1
    end
    string.u8foreach(str, _each)
    return string.sub(str, st, ed)
end

function string.trim (s) 
  return (string.gsub(s, "^%s*(.-)%s*$", "%1")) 
end 

function string.a2u(aStr)
    local uStr = lc.gbk2u8(aStr) or ""
    return uStr
end

function string.u2a(uStr)
    local aStr = lc.u82gbk(uStr) or ""
    return aStr
end

function string.toHex(s)
    if(s == nil) then
        return nil
    end
    s = string.gsub(s, "(.)", function (x) return string.format("%02X",string.byte(x)) end)
    return s
end

function string.dumpbuffer(s)
    if(s == nil) then
        return nil
    end

    local idx = 0
    local count = 0
    local result = {}
    table_insert = table.insert
    string_sub = string.sub
    string_format = string.format
    for idx = 1,#s do

        table_insert(result,string_format("%02X ",string.byte(string_sub(s,idx,idx+1))))

        count = count + 1
        if count == 8 then
            table_insert(result,"   ")
        elseif count ==16 then
            table_insert(result,"\n")
            count = 0
        end
    end
    if count>0 then
        table_insert(result,"\n")
    end
    s = table.concat(result)
    return s
end
function string.lsub(str, locStr)
	if not str or not locStr then
		return nil
	end
	
	local idx = string.find(str, locStr)
	if not idx then
		return nil
	end
	
	return string.sub(str, 0, idx - 1)
	
end

function string.md5(s)
	local hashWriter = MOAIHashWriter.new()
	hashWriter:openMD5 ()
    hashWriter:write ( s )
    hashWriter:close ()
    return hashWriter:getHashHex ()
end




function string.fromfile(filename)
    if type(filename) ~= "string" then
        print("string.fromfile got invalid filename", filename)
        print(debug.traceback())
        return nil
    end
    local file = io.open(filename,"rb")     
    if not file then
        if debugMode then
            print("===================>>>>>string.fromfile failed", filename)
            print(debug.traceback())
        end
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end--cdsc add end

return M

local t_insert = table.insert
local s_fmt = string.format
local bRecFunc = false
function Declare(nameStr,initVal)
	if true then
		rawset(_G,nameStr,initVal)
	else
		rawset(_G,nameStr,initVal or false)
	end
end

local GlobalVarRecord = {
--[[
	["varname" = {
		["index"] = {"info1","info2","info3"}
		["newindex"] = {"info1","info2","info3"}
		},
]]
}
setmetatable(_G, {
    __newindex = function (_, n,v)
    	Declare(n,v)
    	if type(v)=="function" and (not bRecFunc)  then
    		return
    	end
    	local rec = GlobalVarRecord[n]
    	if rec == nil then
    		rec = {
    			["index"] = {}
    			,["newindex"] = {}
    			}
    		GlobalVarRecord[n] = rec
    	end
    	t_insert(rec["newindex"],debug.traceback())
    end,
    __index = function (_, n)
     	local rec = GlobalVarRecord[n]
    	if rec == nil then
    		rec = {
    			["index"] = {}
    			,["newindex"] = {}
    			}
    		GlobalVarRecord[n] = rec
    	end
    	t_insert(rec["index"],debug.traceback())      
    end,
})

local function _GlobalVarsToStream(filestream)
	local f_write = filestream.write
	for varName,rec in pairs(GlobalVarRecord) do
		f_write(filestream,s_fmt("<<<< ACCESS GLOBAL VARS '%s' WITHOUT Declare(nameStr,value) >>>>\n",varName))
		for _,v in ipairs(rec["index"]) do
			f_write(filestream,varName,"\t",v,"\n")
		end
		f_write(filestream,s_fmt("<<<< CREATE GLOBAL VARS '%s' WITHOUT Declare(nameStr,value) >>>>\n",varName))
		for _,v in ipairs(rec["newindex"]) do
			f_write(filestream,varName,"\t",v,"\n")
		end
	end
end

Declare("GlobalVarsPrint",
	function()
		_GlobalVarsToStream(io.stdout)
	end
)

Declare("GlobalVarsToFile",
	function(filename)
		local f_out = io.open(filename,"wb")
		f_out:write("GlobalVarsToFile Begin\n")
		_GlobalVarsToStream(f_out)
		f_out:write("GlobalVarsToFile End\n")
		f_out:flush()
		f_out:close()
	end
	)

if false then
	GlobalVarsPrint()
	GlobalVarsToFile("tempRecord.txt")
end




package.path = "common/?.lua;utils/?.lua;"..package.path
package.cpath = "luaclib/?.so;"..package.cpath

local json = require "json"

local sampleJson = [[
    {"
        "file":9223372036854775805
    }
]];
local status, err, retval = xpcall(json.decode, debug.traceback, sampleJson);
local jdata = json.encode(retval)
print(type(jdata), jdata)
print(type(data["file"]), data["file"]);

--package.path = "/Users/caobo/Documents/llsrv/?.lua;"..package.path

--local int64=require"int64"

function hell()
	local a = 9223372036854775805
	local t = {}
	for i = 1, 10 do
		a = a + 1
		t[a] = a
		
	end
	local len = #t
	for k,v in pairs(t) do
		print(k, t[k])
	end
	
end
hell()





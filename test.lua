package.path = "common/?.lua;utils/?.lua;"..package.path
package.cpath = "luaclib/?.so;"..package.cpath

local json = require "json"

local sampleJson = [[
    {
        "file":9223372036854775805
    }
]];
local status, data, retval = xpcall(json.decode, debug.traceback, sampleJson);
local jdata = json.encode(data)
print(type(jdata), jdata)
print(type(data["file"]), data["file"]);








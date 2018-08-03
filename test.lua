package.path = "common/?.lua;utils/?.lua;"..package.path
package.cpath = "luaclib/?.so;"..package.cpath

require "functions"

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


-- local function tohex(b)
-- 	local x = ""
-- 	local len = #b
-- 	for i = 1, len do
-- 		x = x .. string.format("%.2x", string.byte(b, i)) 
-- 	-- digest 11 -- "dss1"
-- 	end
-- 	return x
-- end

local ossl = require "ossl"
-- local md5 = require"md5"
-- local des56 = require 'des56'


-- local key = "hellohello"
-- local a = des56.crypt('12范德萨7890', key)
-- local b = des56.decrypt(a, key)
-- print(a)
-- print(b)

-- local tp = "AES-128-CBC"
-- local key, iv = "abcdabcdabcdabcd", "abcdabcdabcdabcc"
local res = ossl.encrypt("在dsf范德萨dsaf范德萨")
local res2 = ossl.decrypt(res)
print(res)
print(res2)

local mr = ossl.md5("ewq2")
print(mr)
local mr = ossl.md5("ewq")
print(mr)
-- hc = require('httpclient').new()
-- res = hc:get('http://www.baidu.com')
-- if res.body then
--   print(res.body)
-- else
--   print(res.err)
-- end






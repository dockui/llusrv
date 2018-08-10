package.path = "common/?.lua;utils/?.lua;"..package.path
package.cpath = "luaclib/?.so;"..package.cpath

require "functions"

local socket = require "socket"
local json = require "json"

-- local sampleJson = [[
--     {
--         "file":9223372036854775805
--     }
-- ]];
-- local status, data, retval = xpcall(json.decode, debug.traceback, sampleJson);
-- local jdata = json.encode(data)
-- print(type(jdata), jdata)
-- print(type(data["file"]), data["file"]);

local t = {}
t[1] = 1
t[3] = 3
for k,v in pairs(t) do
print(k, v)
end
local jdata = json.encode(t)
print(type(jdata), jdata)
local sdata = json.decode(jdata)
print(type(sdata), sdata)

for k,v in pairs(sdata) do
print(k, v)
end

-- local cache = require "cache"
-- cache.init()
-- cache.del("uid:1")
-- cache.hmset("uid:1", {name = "caocaos", uid = 1})
-- -- cache.hset("uid:1", "uid", 1)

-- dump((cache.hgetall("uid:1")), "hellO:")


-- local ossl = require "ossl"

-- print("here's a new uuid: ",ossl.md5(ossl.uuid()))
-- print("here's a new uuid: ",ossl.md5(ossl.uuid()))

-- local res = ossl.encrypt("在dsf范德萨dsaf范德萨")
-- local res2 = ossl.decrypt(res)
-- print(res)
-- print(res2)

-- local mr = ossl.md5("ewq2")
-- print(mr)
-- local mr = ossl.md5("ewq")
-- print(mr)

-- hc = require('httpclient').new()
-- hc:set_default("timeout", 5)
-- res = hc:get('http://localhost:9090/api?params={%22action%22:%22login%22,%22sid%22:%22798c1d9e2793f9a7522723b921b01186%22}')

-- if res.body then
--   print(res.body)
-- else
--   print(res.err)
-- end

-- local db = require "db"
-- db.init()
-- db.test()

-- print(socket.gettime())

-- print(os.time())


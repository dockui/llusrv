package.path = "common/?.lua;utils/?.lua;"..package.path
package.cpath = "luaclib/?.so;"..package.cpath

require "functions"

local socket = require "socket"
-- local json = require "json"

-- local sampleJson = [[
--     {
--         "file":9223372036854775805
--     }
-- ]];
-- local status, data, retval = xpcall(json.decode, debug.traceback, sampleJson);
-- local jdata = json.encode(data)
-- print(type(jdata), jdata)
-- print(type(data["file"]), data["file"]);



local cache = require "cache"
cache.init()
cache.del("uid:1")
cache.hmset("uid:1", {name = "caocaos", uid = 1})
-- cache.hset("uid:1", "uid", 1)

dump((cache.hgetall("uid:1")), "hellO:")


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
-- res = hc:get('http://www.baidu.com')
-- hc:set_default("timeout", 5)
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


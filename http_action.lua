
local log = require "log"
local json = require "json"
local ECODE = require "errorcode"

local ossl = require "ossl"

local db = require "db"
local cache = require "cache"
cache.init()
db.init()
local nick = require "nickname"

local _M = {
	
}

local _M = {}
_M.__index = _M

function _M.new()
  local M = {}

  return setmetatable(M, self)
end

_M.config = function(response, params)
	local msg = {
            
            ip = "123456",
            port = "8800"
     }
     _M.output(response, msg)
 end
-- {type=confirm  game conn confirm 
-- }
--http://localhost:9090/api?params={"action":"login","sid":"798c1d9e2793f9a7522723b921b01186"}
_M.login = function(response, params)

	local msg = {
            name = "null"
     }

    repeat
		local sid = params.sid or "0"
		local uid = cache.get("sid:"..sid)
		if not uid then
			if params.type == "confirm" then break end

			local name = nick.new()
			uid = db.insert("T_USER", {
				name = name
				})
			sid = ossl.md5(ossl.uuid())

			cache.set("sid:"..sid, uid)

			local key_uid = "uid:"..uid
			cache.hmset(key_uid, {uid=uid, sid=sid, gold=6, name=name})
		end

		msg = cache.hgetall("uid:"..uid) or {}
		if msg.sid ~= sid then break end

		_M.output(response, msg)
		return
	until(true)

	_M.output_fail(response, ECODE.ERR_VERIFY_FAILURE)
end

_M.output = function(response, data)
	response:statusCode(200)
	response:addHeader('Content-Type', 'text/plain')

	local ret = {
            error = 0,
            data = data
     }

    local ostr = json.encode(ret)
    log.info("http response => "..ostr)
	response:write(ostr)
end

_M.output_fail = function(response, code)
	response:statusCode(200)
	response:addHeader('Content-Type', 'text/plain')

	local ret = {
            error = code,
            data = ECODE.ErrDesc(code)
     }

	response:write(json.encode(ret))
end

return _M
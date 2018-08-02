
local log = require "log"
local json = require "json"
local ECODE = require "errorcode"

local _M = {
	
}

local _M = {}
_M.__index = _M

function _M.new()
  local M = {}

  return setmetatable(M, self)
end

_M.login = function(response, params)
	local msg = {
            name = "hello"
     }

	_M.output(response, msg)
end

_M.output = function(response, data)
	response:statusCode(200)
	response:addHeader('Content-Type', 'text/plain')

	local ret = {
            error = 0,
            data = data
     }

	response:write(json.encode(ret))
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
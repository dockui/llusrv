local CONF = require "conf"
local CMD = require "cmd"
local BASE = require "base"
local json = require "json"

local _M = {
	
}

local _M = {
	_store = {}
}
_M.__index = _M

function _M.new()
  local M = {}

  return setmetatable(M, self)
end

_M.get = function(key, cb)
	BASE:PostMessageIPC(CONF.LVM_MODULE.CACHE, 
            CMD.LVM_CMD_CACHE_GET, 
            json.encode({key=key}), 
            cb)
end

_M.set = function(key, val)
    BASE:PostMessageIPC(CONF.LVM_MODULE.CACHE, 
        CMD.LVM_CMD_CACHE_SET, 
        json.encode({key=key, val=val}))
end

_M.l_get = function(key, cb)
	return _M._store[key]
end

_M.l_set = function(key, val)
    _M._store[key] = val
end

return _M
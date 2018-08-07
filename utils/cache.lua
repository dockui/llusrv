local CONF = require "conf"
local CMD = require "cmd"
local BASE = require "base"
local json = require "json"

-- /usr/local/Cellar/lua/5.3.4_3/share/lua/5.3/redis.lua
local redis = require 'redis' --luarocks install redis-lua


local _M = {
	_store = {}
}
_M.__index = _M

function _M.new()
  local M = {}

  return setmetatable(M, self)
end

_M.init = function(ip, port)
  _M._client = redis.connect(ip or '127.0.0.1', port or 6379)
end

_M.get = function(key)
  assert(_M._client, " cache is not connect")
  return _M._client:get(key)
end

_M.set = function(key, val)
  assert(_M._client, " cache is not connect")
  return _M._client:set(key, val)
end

_M.del = function(key)
  assert(_M._client, " cache is not connect")
  return _M._client:del(key)
end

_M.hget = function(hash, key)
  assert(_M._client, " cache is not connect")
  return _M._client:hget(hash, key)
end

_M.hmget = function(hash, ...)
  assert(_M._client, " cache is not connect")
  return _M._client:hmget(hash, ...)
end

_M.hset = function(hash, key, val)
  assert(_M._client, " cache is not connect")
  return _M._client:hset(hash, key, val)
end

_M.hmset = function(hash, ...)
  assert(_M._client, " cache is not connect")
  return _M._client:hmset(hash, ...)
end

_M.hgetall = function(hash)
  assert(_M._client, " cache is not connect")
  return _M._client:hgetall(hash)
end

_M.hdel = function(hash, ...)
  assert(_M._client, " cache is not connect")
  return _M._client:hdel(hash, ...)
end



_M.c_get = function(key, cb)
	BASE:PostMessageIPC(CONF.LVM_MODULE.CACHE, 
            CMD.LVM_CMD_CACHE_GET, 
            json.encode({key=key}), 
            cb)
end

_M.c_set = function(key, val)
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

package.path = "?.lua;utils/?.lua;common/?.lua;game/?.lua;"..package.path
package.cpath = "luaclib/?.so;"..package.cpath

require "functions"

package.cpath = "/usr/local/lib/lua/5.3/?.so;"..package.cpath
package.path = "/usr/local/Cellar/lua/5.3.4_3/share/lua/5.3/?.lua;"..package.path

local uv    = require "lluv"
local zmq   = require "lzmq"
uv.poll_zmq = require "lluv.poll_zmq"
-- local Pegasus  = require 'lluv.pegasus'

local CONF = require "conf"
local CMD = require "cmd"
local BASE = require "base"

local log = require "log"
local json = require "json"

local Cache = require "m_cache"

local ep = CONF.LVM_IPC_NAME[CONF.LVM_MODULE.CACHE]
-- local ep = arg[1] or "tcp://127.0.0.1:5555"

--################
local ctx = zmq.context()
local srv = ctx:socket{"PAIR", linger = 0,sndtimeo = 0, rcvtimeo = 0, 
   bind = CONF.LVM_IPC_NAME[CONF.LVM_MODULE.CACHE] }

print("cache server start")
print("ZMQ   version:", zmq.version(true))
print("Test endpoint:", ep)

BASE:RegIPCSendCB(CONF.LVM_MODULE.CACHE, function(msg) 
	srv:send(msg)
end)
uv.poll_zmq(srv):start(BASE:GetIPCReadCB())

--###############
local cache = Cache:new()

uv.run()



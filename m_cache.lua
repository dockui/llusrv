package.path = "script/?.lua;script/utils/?.lua;script/common/?.lua;"..package.path
package.cpath = "luaclib/?.so;"..package.cpath

require "functions"
local CONF = require "conf"
local CMD = require "cmd"
local BASE = require "base"
local log = require "log"
local json = require "json"
local ECODE = require "errorcode"

local redis = require 'redis'

local Cache = class("Cache")
function Cache:ctor(obj,data)
    log.info("Cache:ctor()")

    -- self.BASE = CONF.BASE.MODE_LUA_MAIN and BASE:new() or BASE
    self.BASE = BASE
    assert(self.Base ~= BASE)
    if self.init then self:init(data) end
end
function Cache:init(data)
    log.info("Cache:init()")

    self.BASE:RegCmdCB(CMD.LVM_CMD_CACHE_GET, handler(self, self.OnGet))
    self.BASE:RegCmdCB(CMD.LVM_CMD_CACHE_SET, handler(self, self.OnSet))

    self.client = redis.connect('127.0.0.1', 6379)

    if not self.client then
        log.error("redis can not connect")
    end
end
function Cache:OnGet(msg, fid, sid)
    log.info("Cache:OnGet:"..msg)
    local msg = json.decode(msg)
    local key = msg.key
    local val = nil
    local ret = nil
    if self.client then
        val = self.client:get(key)
    else
        log.error("redis is disconnect")
    end

    ret = val or ""

    log.info("Cache:OnGet val="..json.encode(ret))

    if CONF.BASE.MODE_LUA_MAIN then
        self.BASE:RetMessageIPC(CONF.LVM_MODULE.CACHE, 
            json.encode(ret), sid)
        return
    end
    self.BASE:RetMessage(fid, json.encode(ret), sid)
end

function Cache:OnSet(msg, fid, sid)
    log.info("Cache:OnSet:"..msg)
    local msg = json.decode(msg)
    local key = msg.key
    local val = msg.val

    if self.client then
        val = self.client:set(key, val)
    else
        log.error("redis is disconnect")
    end

    -- local ret = ""
    -- if CONF.BASE.MODE_LUA_MAIN then
    --     self.BASE:RetMessageIPC(CONF.LVM_MODULE.CACHE, 
    --         json.encode(ret), sid)
    --     return
    -- end
    -- self.BASE:RetMessage(fid, json.encode(ret), sid)   
end

-- objCache = Cache:new()
return Cache
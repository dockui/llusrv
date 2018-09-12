
require "functions"
local CONF = require "conf"
local CMD = require "cmd"
local BASE = require "base"
local log = require "log"
local json = require "json"

local Tebl = class("Tebl")
function Tebl:ctor(obj,data)
    log.info("Tebl:ctor()")
    
    self.BASE = CONF.BASE.MODE_LUA_MAIN and BASE:new() or BASE

    if self.init then self:init(data) end
end

function Tebl:init(data)

end

function Tebl:start( ... )
	log.info("Tebl:start()")

end

return Tebl

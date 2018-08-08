

package.path = "?.lua;utils/?.lua;common/?.lua;game/?.lua;"..package.path
package.cpath = "luaclib/?.so;"..package.cpath
-- print (package.cpath)

-- package.cpath = "/usr/local/lib/lua/5.3/?.so;"..package.cpath
-- package.path = "/usr/local/Cellar/lua/5.3.4_3/share/lua/5.3/?.lua;"..package.path

-- local uv  = require"lluv"
-- local ws  = require"lluv.websocket"
-- local ut     = require "lluv.utils"
-- local socket = require "lluv.luasocket"

require "functions"

local CONF = require "conf"
local CMD = require "cmd"
local BASE = require "base"


local log = require "log"
local json = require "json"

local uvloop = CONF.BASE.MODE_WS and require "uvloop_ws" or require "uvloop"


local connmgr = require "connmgr"
local roommgr = require "roommgr"
local Room = require "room"
local Login = require "m_login"

local Main = class("Main")
Main.cc = 4
function Main:ctor(obj,data)
    log.info("Main:ctor()")
    if self.init then self:init(data) end
end
function Main:init(data)
    log.info("Main:init()")

    self.loginServerId = CONF.LVM_MODULE.LOGIN
    --BASE:CreateLvm(CONF.LVM_MODULE.LOGIN, Login:new())
    self.roomMgr = roommgr:new()

    self.connMgr = connmgr:new({
        loginServerId=self.loginServerId,
        roomMgr = self.roomMgr
        }
    )

end

function Main:Run(data)
  log.info("Main:loop()")
  self.cc = 5
end

AppMain = Main:new("main")
-- AppMain1 = Main:new("main1")
-- print(AppMain.cc, AppMain1.cc)


uvloop:new():Run()


print("end")

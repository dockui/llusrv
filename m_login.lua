package.path = "script/?.lua;script/utils/?.lua;script/common/?.lua;"..package.path
package.cpath = "luaclib/?.so;"..package.cpath

require "functions"
local CONF = require "conf"
local CMD = require "cmd"
local BASE = require "base"
local log = require "log"
local json = require "json"
local ECODE = require "errorcode"


local Login = class("Login")
function Login:ctor(obj,data)
    log.info("Login:ctor()")

    -- self.BASE = CONF.BASE.MODE_LUA_MAIN and BASE:new() or BASE
    self.BASE = BASE
    assert(self.Base ~= BASE)
    if self.init then self:init(data) end
end
function Login:init(data)
    log.info("Login:init()")

    self.BASE:RegCmdCB(CMD.REQ_LOGIN, handler(self, self.OnLogin))

end
function Login:OnLogin(msg, fid, sid)
    log.info("Login:OnLogin:"..msg)

    local T_USER = {
        zhaosan = 1,
        lisi = 2,
        wangwu = 3,
        zhaoliu = 4
    }
    local msg = json.decode(msg)

    local username = msg.data.username
    local uid = T_USER[username]
    local ret 
    if uid ~= nil then
        ret = {
            cmd = CMD.RES_LOGIN,
            error = 0,
            data = {
                uid = uid
            }
        }
    else
        ret = {
            cmd = CMD.RES_LOGIN,
            error = ECODE.ERR_NOT_EXIST_USER,
            data = "user not found"
        }
    end

    if CONF.BASE.MODE_LUA_MAIN then
        self.BASE:RetMessageIPC(CONF.LVM_MODULE.LOGIN, 
            json.encode(ret), sid)
        return
    end
    self.BASE:RetMessage(fid, json.encode(ret), sid)
end


-- objLogin = Login:new()
return Login
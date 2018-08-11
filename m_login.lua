package.path = "script/?.lua;script/utils/?.lua;script/common/?.lua;"..package.path
package.cpath = "luaclib/?.so;"..package.cpath

require "functions"
local CONF = require "conf"
local CMD = require "cmd"
local BASE = require "base"
local log = require "log"
local json = require "json"
local ECODE = require "errorcode"

local hc = require('httpclient').new()

hc:set_default("timeout", 5)

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

    self.BASE:RegCmdCB(CMD.REQ_EXIT, handler(self, self.OnExit))


end
function Login:OnLogin(msg, fid, sid)
    log.info("Login:OnLogin:"..msg)

    local msg = json.decode(msg)

    -- local T_USER = {
    --     zhaosan = 1,
    --     lisi = 2,
    --     wangwu = 3,
    --     zhaoliu = 4
    -- }
    

    -- local username = msg.data.username
    -- local uid = T_USER[username]
    -- local ret 
    -- if uid ~= nil then
    --     ret = {
    --         cmd = CMD.RES_LOGIN,
    --         error = 0,
    --         data = {
    --             uid = uid
    --         }
    --     }
    -- else
    --     ret = {
    --         cmd = CMD.RES_LOGIN,
    --         error = ECODE.ERR_NOT_EXIST_USER,
    --         data = "user not found"
    --     }
    -- end

    local params = {
        action = "login",
        cmd = msg.cmd
    }
    table.merge(params, msg.data)
    params = json.encode(params)
    params = string.urlencode(params)

    local ret 

    res = hc:get('http://localhost:9090/api?params='..params)
    if res.body then
       ret = res.body
    else
        log.error("request login api failure:"..res.err)
        ret = json.encode({
            cmd = CMD.RES_LOGIN,
            error = ECODE.CODE_UNKNOW,
            data = ECODE.ErrDesc(ECODE.CODE_UNKNOW)
        })
    end

    log.info("request login api:".. ret)
    
    if CONF.BASE.MODE_LUA_MAIN then
        self.BASE:RetMessageIPC(CONF.LVM_MODULE.LOGIN, 
            (ret), sid)
        return
    end
    self.BASE:RetMessage(fid, (ret), sid)
end

function Login:OnExit(msg, fid, sid)
    log.info("Login:OnExit:"..msg)

    local msg = json.decode(msg)

    local params = {
        action = "exit_room"
    }
    table.merge(params, msg.data)
    params = json.encode(params)
    params = string.urlencode(params)

    local ret 

    res = hc:get('http://localhost:9090/api?params='..params)
    if res.body then
       ret = res.body
    else
        log.error("request exit_room api failure:"..res.err)
        ret = json.encode({
            cmd = 0,
            error = ECODE.CODE_UNKNOW,
            data = ECODE.ErrDesc(ECODE.CODE_UNKNOW)
        })
    end

    log.info("request exit_room api:".. ret)
    
    if CONF.BASE.MODE_LUA_MAIN then
        self.BASE:RetMessageIPC(CONF.LVM_MODULE.LOGIN, 
            (ret), sid)
        return
    end
    self.BASE:RetMessage(fid, (ret), sid)
end

-- objLogin = Login:new()
return Login
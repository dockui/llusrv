-- package.path = "script/game/?.lua;script/?.lua;script/utils/?.lua;script/common/?.lua;"..package.path
-- package.cpath = "luaclib/?.so;"..package.cpath
--/Applications/ZeroBraneStudio.app/Contents/ZeroBraneStudio/lualibs/mobdebug
--/Applications/ZeroBraneStudio.app/Contents/ZeroBraneStudio/bin/clibs53
-- package.path = "/Applications/ZeroBraneStudio.app/Contents/ZeroBraneStudio/lualibs/mobdebug/?.lua;"..package.path
-- package.path = "/Applications/ZeroBraneStudio.app/Contents/ZeroBraneStudio/lualibs/?.lua;"..package.path
-- package.cpath = "/Applications/ZeroBraneStudio.app/Contents/ZeroBraneStudio/bin/clibs53/?.dylib;"..package.cpath
-- package.cpath = "/Applications/ZeroBraneStudio.app/Contents/ZeroBraneStudio/bin/clibs53/?/?.dylib;"..package.cpath
-- require("mobdebug").start()

require "functions"
local CMD = require "cmd"
local BASE = require "base"
local log = require "log"
local json = require "json"

local mjlib = require "cs.mjlib"

local Room = class("Room")
function Room:ctor(obj,data)
    log.info("Room:ctor()")
    
    self.BASE = CONF.BASE.MODE_LUA_MAIN and BASE:new() or BASE

    if self.init then self:init(data) end
end
function Room:init(data)
    log.info("Room:init()")
    self._lst_user = {}

    self.BASE:RegCmdCB(CMD.REQ_ENTERTABLE, handler(self, self.OnEnterTable))

    self.BASE:RegCmdCB(CMD.LVM_CMD_UPDATE_USER_INFO, handler(self, self.OnUpdateUserInfo))

    self.BASE:RegCmdCB(CMD.REQ_EXIT, handler(self, self.OnUserExit))

end

function Room:GetUser(uid)
    for i, v in ipairs(self._lst_user) do
        if v.uid == uid then
            return v
        end
    end
    return nil
end

function Room:OnUserExit(msg)
    log.info("Room:OnUserExit() "..msg)
    local msg = json.decode(msg)
    -- local userinfo = self:GetUser(msg.uid)

    -- table.merge(userinfo, msg)
    -- room_info
    self:BuildUserSeatid(msg)
end

function Room:OnUpdateUserInfo(msg)
    log.info("Room:OnUpdateUserInfo() "..msg)
    local msg = json.decode(msg)
    local userinfo = self:GetUser(msg.uid)

    table.merge(userinfo, msg)
end

function Room:BuildUserSeatid(data)
    local lst_user_tmp = {}
    for i=1, data.num do
        local mem = "member_"..i
        if data[mem] then
            local uid = tonumber(data[mem])
            local userinfo = self:GetUser(uid)
            userinfo.seatid = i
            self.lst_user_tmp[userinfo.fid] = userinfo
        end
    end
    self._lst_user = lst_user_tmp
end

function Room:OnEnterTable(msg)
    log.info("Room:OnEnterTable() "..msg)
    local msg = json.decode(msg)
    local room_info = msg.inroom_info or {}

    -- self._lst_user[msg.fid] = msg
    
    -- local userinfo = self:GetUser(msg.uid)
    -- if userinfo then
    --     userinfo.fid = msg.fid
    -- else
    --     self._lst_user[#self._lst_user+1] = msg
    --     if #self._lst_user == 1 then
    --         msg.zhu = 1
    --         msg.zhuang = 1
    --     end
    -- end

    local userinfo = self:GetUser(msg.uid)
    if userinfo then
        table.merge(userinfo, msg)
    end

    self:BuildUserSeatid(room_info)

    self:StartGame()
end

function Room:StartGame()

    self.cardsAll = mjlib.create()
    local num_tbl = mjlib.getNumTable(self.cardsAll)
    log.info(mjlib.getNumTableStr(num_tbl))
end


-- objRoom = Room:new()
return Room
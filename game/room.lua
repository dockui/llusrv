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
local CONF = require "conf"
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
    self._desk_cards = {}
    self._room_info = {    }

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

function Room:GetUserBySeatid(id)
    for i, v in ipairs(self._lst_user) do
        if v.seatid == id then
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
        -- repeat
        local mem = "member_"..i
        if data[mem] then
            local uid = tonumber(data[mem])
            local userinfo = self:GetUser(uid)
            if not userinfo then
                log.error("build seatid not found:"..uid)
                goto continue
            end

            userinfo.seatid = i
            lst_user_tmp[userinfo.uid] = userinfo
        end
        ::continue::
        -- until true
    end
    self._lst_user = lst_user_tmp
end

function Room:OnEnterTable(msg)
    log.info("Room:OnEnterTable() "..msg)
    local msg = json.decode(msg)
    self._room_info = msg.inroom_info or {}

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
    else
        self._lst_user[msg.uid] = msg
    end

    self:BuildUserSeatid(self._room_info)

    self:StartGame()
end

function Room:TestSetUser(lst_user)
    self._lst_user = lst_user
end

function Room:TestSetRoomInfo(room_info)
    self._room_info = room_info
end

function Room:StartGame()
    self._room_info.player_round = self._room_info.player_round and self._room_info.player_round + 1 or 1

    self._desk_cards = mjlib.create()
    mjlib.shuffle(self._desk_cards)

    for i=1, self._room_info.num do
        local user_info = self:GetUserBySeatid(i)
        user_info.cards = {}
        for j=1,13 do
            table.insert(user_info.cards, table.remove(self._desk_cards))
        end

        if self._room_info.banker_seatid == i then
            table.insert(user_info.cards, table.remove(self._desk_cards))
        end

        table.sort(user_info.cards)
    end

    -- local num_tbl = mjlib.getNumTable(self._desk_cards)
    -- log.info(mjlib.getNumTableStr(num_tbl))
    log.info(json.encode(self._room_info))
    log.info(json.encode(self._desk_cards))
    log.info(json.encode(self._lst_user))

    self:SendMsgStartGame()
end

function Room:SendMsgStartGame()
    
    local msg = {
        cmd = 4017,
        banker_seatid = self._room_info.banker_seatid,
        decks_count = #self._desk_cards,
        player_round = self._room_info.player_round
    }

    for i=1, self._room_info.num do
        local player_cards = {}
        local user_info = self:GetUserBySeatid(i)

        for j=1, self._room_info.num do
            local or_user_info = self:GetUserBySeatid(j)
            local cards_info = {}
            cards_info.seatid = or_user_info.seatid
            cards_info.cards = mjlib.getHandDefineTable(or_user_info.cards, i , j)
            table.insert(player_cards, cards_info)
        end

        msg.player_cards = player_cards

        local backMsg = json.encode(msg)
        BASE:SendToClient(user_info.fid, backMsg, #backMsg)

        log.info("send message to fid="..user_info.fid)
        log.info(backMsg) 
    end
end

-- objRoom = Room:new()
return Room
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
    return self._lst_user[uid]
    -- for i, v in pairs(self._lst_user) do
    --     if v.uid == uid then
    --         return v
    --     end
    -- end
    -- return nil
end

function Room:GetUserBySeatid(id)
    for i, v in pairs(self._lst_user) do
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

    self:outDirection(self._room_info.banker_seatid)
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

        -- log.info("send message to fid="..user_info.fid)
        -- log.info(backMsg) 
    end
end

function Room:OnOutCard(msg)
    log.info("Room:OnOutCard()")
    dump(msg)
    local msg = type(msg) == "string" and json.decode(msg) or msg
    local card_idx = mjlib.CardIndex[msg.card]

    if not card_idx then
        log.error("invalid card")
        return
    end

    local user_info = self:GetUser(msg.uid)

    if self._room_info.myseatid ~= userinfo.seatid then
        log.debug("not current user to out")
        return
    end

    local find_pos = table.keyof(user_info.cards, card_idx)
    if not find_pos then
        log.error("not find card")
        return
    end

    table.remove(user_info.cards, find_pos)
    
    self:SendMsgOutCard(msg.card, user_info.seatid)

    -- for cpgh
    self:JudgeCPGH(card_idx, user_info.seatid)

end

function Room:SendMsgOutCard(card, byseatid)
    
    local outCard = {
        cmd = 29,
        card = card,
        seatid = byseatid
    }

    for i=1, self._room_info.num do
        local user_info = self:GetUserBySeatid(i)

        outCard.hands = mjlib.getHandDefineTable(user_info.cards, byseatid , i)
      
        local backMsg = json.encode(outCard)
        BASE:SendToClient(user_info.fid, backMsg, #backMsg)

        -- log.info("send message to fid="..user_info.fid)
        -- log.info(backMsg)
    end
end

function Room:ClearActions( ... )
    -- body
    for i, v in pairs(self._lst_user) do
        v.actions = nil
    end
end


function Room:SendCard(byseatid, fore_seatid)
    -- local next_seatid = (fore_seatid + 1) % self._room_info.num

    if #self._desk_cards == 0 then
        log.info("card over")

        return
    end

    local card_idx = table.remove(self._desk_cards)

    local user_info = self:GetUserBySeatid(byseatid)
    table.insert(user_info.cards, card_idx)

    self:SendMsgSendCard(mjlib.CardDefine[card_idx], byseatid)

    self:outDirection(byseatid)
end

function Room:SendMsgSendCard(card, byseatid)
    local sendcard = {
        cmd = 4022,
        decks_count = #self._desk_cards,
        seatid = byseatid
    }

    for i=1, self._room_info.num do
        local user_info = self:GetUserBySeatid(i)

        sendcard.card = byseatid == i and card or -1

        local backMsg = json.encode(sendcard)
        BASE:SendToClient(user_info.fid, backMsg, #backMsg)
    end
end

function Room:outDirection(seatid)
    self._room_info.myseatid = seatid

    local outdirection = {
        cmd = 4019,
        seatid = seatid
    }

    local backMsg = json.encode(outdirection)
    
    for i=1, self._room_info.num do
        local user_info = self:GetUserBySeatid(i)

        BASE:SendToClient(user_info.fid, backMsg, #backMsg)
    end
end

function Room:OnReqAction(msg)
    log.info("Room:OnReqAction()")
    dump(msg)
    local msg = type(msg) == "string" and json.decode(msg) or msg
    -- local card_idx = mjlib.CardIndex[msg.card]

    local req_type = msg.type
    local user_info = self:GetUser(msg.uid)

    if not user_info then
        log.error("invalid user")
        return
    end

    if not user_info.actions then
        log.error("not exist actions")
        return
    end

    for k,v in pairs(user_info.actions) do
        if v.type == req_type then
            v.ack = true
        end
    end

    self:TryHandleCPGH()
end

function Room:TryHandleCPGH()

    -- -- hu 8
    -- local ret,seatid,op_type = self:GetFirstCPGH(8)
    -- if ret then
    --     HandleCPGH(seatid, op_type)
    --     return
    -- end

    -- -- gang 7
    -- ret,seatid,op_type = self:GetFirstCPGH(7)
    -- if ret then
    --     HandleCPGH(seatid, op_type)
    --     return
    -- end

    for i=8,1,-1 do
        local ret,seatid,op_type = self:GetFirstCPGH(i)
        if ret then
            self:HandleCPGH(seatid, op_type)
            return
        end
    end

end

function Room:HandleCPGH(seatid, op_type)
    if mjlib.ACTION_HU == op_type then

    end

    if mjlib.ACTION_GANG == op_type then

    end

    if mjlib.ACTION_PENG == op_type then

    end
    
    if mjlib.ACTION_CHI == op_type then

    end

    if mjlib.ACTION_GUO == op_type then

    end
end

function Room:GetFirstCPGH(op_type)
    local beg_seatid = self._room_info.waitop_seatid
    local next_seatid = (beg_seatid + 1) % self._room_info.num
    for pos=1, self._room_info.num - 1 do

        local user_info = self:GetUserBySeatid(next_seatid)

        if #user_info.actions > 0 then
            --todo
            for i=1,#user_info.actions do
                if op_type == mjlib.ACTION_GUO then
                    if op_type == user_info.actions[i].type and not user_info.actions[i].ack then
                        return false
                    end
                else
                    if op_type == user_info.actions[i].type and user_info.actions[i].ack then
                        return true,next_seatid,user_info.actions[i].type
                    end    
                end
            end
        end

        next_seatid = (next_seatid + 1) % self._room_info.num
    end
    if op_type == mjlib.ACTION_GUO then
        return true
    end
    return false
end

function Room:JudgeCPGH(card_idx, from_seatid)
    -- body
    self:ClearActions()

    local next_seatid = (from_seatid + 1) % self._room_info.num
    for pos=1, self._room_info.num - 1 do
        local user_info = self:GetUserBySeatid(next_seatid)

        local num_tbl = mjlib.getNumTable(user_info.cards)
        -- num_tbl[card_idx] = num_tbl[card_idx] + 1

        local actions = {}

        --hu
        num_tbl[card_idx] = num_tbl[card_idx] + 1
        local bHu = mjlib.check_hu(num_tbl)
        if bHu then
            table.insert(actions, {
                type = 8
                })
        end
        num_tbl[card_idx] = num_tbl[card_idx] - 1

        --gang type 6, 7
        local bGang = mjlib.can_diangang(num_tbl, card_idx)
        if bGang then
            table.insert(actions, {
                type = 7
                })
        end

        --peng
        local bPeng = mjlib.can_peng(num_tbl, card_idx)
        if bPeng then
            table.insert(actions, {
                type = 5
                })
        end

        --chi
        if 1 == pos then
            local options = {}
            local bchi = mjlib.can_left_chi(num_tbl, card_idx)
            if bchi then
                table.insert(options, {
                        cards = {
                            mjlib.CardDefine[card_idx + 1],
                            mjlib.CardDefine[card_idx + 2],
                        }})
            end
            bchi = mjlib.can_middle_chi(num_tbl, card_idx)
            if bchi then
                table.insert(options, {
                        cards = {
                            mjlib.CardDefine[card_idx - 1],
                            mjlib.CardDefine[card_idx + 1],
                        }})
            end
            bchi = mjlib.can_right_chi(num_tbl, card_idx)
            if bchi then
                table.insert(options, {
                        cards = {
                            mjlib.CardDefine[card_idx - 2],
                            mjlib.CardDefine[card_idx - 1],
                        }})
            end

            if #options > 0 then
                table.insert(actions, {
                    type = 4,
                    options = options
                    })
            end
        end

        if #actions > 0 then
            -- guo
            table.insert(actions, {type = 1})
            
            --save tmp
            user_info.actions = actions

            --save current from seatid
            self._room_info.waitop_seatid = from_seatid

            local backMsg = json.encode(outCard)
            BASE:SendToClient(user_info.fid, backMsg, #backMsg)
        end

        next_seatid = (next_seatid + 1) % self._room_info.num
    end
end



-- objRoom = Room:new()
return Room
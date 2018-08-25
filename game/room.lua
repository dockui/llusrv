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
    self._room_info = {}

    self.BASE:RegCmdCB(CMD.REQ_ENTERTABLE, handler(self, self.OnEnterTable))
    
    self.BASE:RegCmdCB(CMD.LVM_CMD_UPDATE_USER_INFO, handler(self, self.OnUpdateUserInfo))
    
    self.BASE:RegCmdCB(CMD.REQ_EXIT, handler(self, self.OnUserExit))

    self.BASE:RegCmdCB(CMD.REQ_READY, handler(self, self.OnReady))

    self.BASE:RegCmdCB(CMD.REQ_OUTCARD, handler(self, self.OnOutCard))

    self.BASE:RegCmdCB(CMD.REQ_ACTION, handler(self, self.OnReqAction))

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

function Room:GetUserfidBySeatid(id)
    for i, v in pairs(self._lst_user) do
        if v.seatid == id then
            return v.fid
        end
    end
    return nil
end

function Room:OnUserExit(msg)
    log.info("Room:OnUserExit")
    local msg = type(msg) == "string" and json.decode(msg) or msg
    if CONF.BASE.DEBUG then dump(msg) end

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

function Room:OnReady(msg)
    log.info("Room:OnReady()")
    local msg = type(msg) == "string" and json.decode(msg) or msg
    if CONF.BASE.DEBUG then dump(msg) end

    local user_info = self:GetUser(msg.uid)
    if not user_info then 
        log.error("OnReady not found user =>")
    end

    user_info.ready = msg.ready

    if self:IsUserFull() and self:IsAllReady() then
        -- nerver begin , so first init
        if not self.player_round then
            self:InitTableInfo()
        end
        
        self:StartGame()
    end 
end

function Room:IsUserFull()
    if self._room_info.num > 0 and  self._room_info.num == table.nums(self._lst_user) then
        return true
    end
    return false
end

function Room:IsAllReady()
    for i, v in pairs(self._lst_user) do
        if not v.ready then
            return false
        end
    end
    return true
end

function Room:OnEnterTable(msg)
    log.info("Room:OnEnterTable() "..msg)
    local msg = json.decode(msg)
    table.merge(self._room_info , msg.inroom_info or {})

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

    self:SendMsgEnterTable(msg.uid)

    self:SendTableInfo(msg.uid)
end

function Room:SendMsgEnterTable( byuid )
    local msg_entertable = {
        cmd = CMD.RES_ENTERTABLE,
        player = {}
    }
    table.insert(msg_entertable.player , self:GetUser(byuid))

    for i=1, self._room_info.num do
        local to_fid = self:GetUserfidBySeatid(i)

        local backMsg = json.encode(msg_entertable)
        BASE:SendToClient(to_fid, backMsg, #backMsg)
    end 
end


function Room:InitTableInfo()
    table.merge(self._room_info, {
        create_mode = 0,
        daikai_mode = 0, 

        gamestate = 0,
        gametype = 1, -- n ren wan fa
        owner_seatid = self:GetUser(self._room_info.uid).seatid,
        piao = 0,
        play_round = 1,

        roomtype =  self._room_info.num, -- m_typeGm

        tid = self._room_info.roomid,

        total_round = 8, 
        zhaniao_count = 1,

        tid = self._room_info.roomid,
    })
end

function Room:SendTableInfo(uid_for)

    local user_info_for = self:GetUser(uid_for)


    local msg_tableinfo = clone(self._room_info)
    table.merge(msg_tableinfo, {
        cmd = CMD.RES_TBALEINFO,
        
        decks_count = #self._desk_cards,
        -- putcard_card = -1, -- chu pai
        -- putcard_seatid = 2, --chu seatid

        -- sendcard_card = , zi ji chu pai
        
        myseatid = user_info_for.seatid,

        players = {},
    })


    for i=1, self._room_info.num do
        local player_cards = {}
        local user_info = self:GetUserBySeatid(i)
        user_info = clone(user_info)
        user_info.hands = mjlib.getHandDefineTable(user_info.hands, user_info_for.seatid , j)

        table.insert(msg_tableinfo.players, user_info)
    end


    local backMsg = json.encode(msg_tableinfo)
    BASE:SendToClient(user_info_for.fid, backMsg, #backMsg)
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

    local lastcatch_card_idx = nil
    for i=1, self._room_info.num do
        local user_info = self:GetUserBySeatid(i)
        user_info.hands = {}
        for j=1,13 do
            table.insert(user_info.hands, table.remove(self._desk_cards))
        end

        if self._room_info.banker_seatid == i then
            lastcatch_card_idx = table.remove(self._desk_cards)
            table.insert(user_info.hands, lastcatch_card_idx)
        end

        table.sort(user_info.hands)

        user_info.outcards = {}
        user_info.eats = {}
    end

    -- local num_tbl = mjlib.getNumTable(self._desk_cards)
    -- log.info(mjlib.getNumTableStr(num_tbl))
    log.info(json.encode(self._room_info))
    log.info(json.encode(self._desk_cards))
    log.info(json.encode(self._lst_user))

    self:SendMsgStartGame()

    self:JudgeSelfAction(self._room_info.banker_seatid, lastcatch_card_idx, true)

    self:outDirection(self._room_info.banker_seatid)
end

function Room:SendMsgStartGame()
    
    local msg = {
        cmd = CMD.RES_STARTGAME,
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
            cards_info.cards = mjlib.getHandDefineTable(or_user_info.hands, i , j)
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
    local msg = type(msg) == "string" and json.decode(msg) or msg
    if CONF.BASE.DEBUG then dump(msg) end

    local card_idx = mjlib.CardIndex[msg.card]

    if not card_idx then
        log.error("invalid card")
        return
    end

    local user_info = self:GetUser(msg.uid)

    if self._room_info.putcard_seatid ~= userinfo.seatid then
        log.debug("not current user to out")
        return
    end

    local find_pos = table.keyof(user_info.hands, card_idx)
    if not find_pos then
        log.error("not find card")
        return
    end

    table.remove(user_info.hands, find_pos)

    self._room_info.sendcard_card = msg.card

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

        outCard.hands = mjlib.getHandDefineTable(user_info.hands, byseatid , i)
      
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

function Room:JudgeSelfAction(byseatid, card_idx, qishou)
    self:ClearActions()

    local user_info = self:GetUserBySeatid(byseatid)

    local num_tbl = mjlib.getNumTable(user_info.hands)

    local actions = {}

    --hu

    local bHu = mjlib.check_hu(num_tbl)
    if bHu then
        table.insert(actions, {
            type = mjlib.ACTION_HU,
            qishou = qishou,
            })

        -- guo
        table.insert(actions, {type = mjlib.ACTION_GUO})
        
        --save tmp
        user_info.actions = actions

        --save current from seatid
        self._room_info.putcard_seatid = byseatid
        self._room_info.putcard_card = mjlib.CardDefine[card_idx]

        local backMsg = json.encode(outCard)
        BASE:SendToClient(user_info.fid, backMsg, #backMsg)

    end
end

function Room:SendCard(byseatid)
    -- local next_seatid = (fore_seatid + 1) % self._room_info.num

    if #self._desk_cards == 0 then
        log.info("card over")
        self:GameOver()
        return
    end

    local card_idx = table.remove(self._desk_cards)

    local user_info = self:GetUserBySeatid(byseatid)
    table.insert(user_info.hands, card_idx)

    self:SendMsgSendCard(mjlib.CardDefine[card_idx], byseatid)

    self:JudgeSelfAction(byseatid, card_idx)

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
    self._room_info.putcard_seatid = seatid

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
            v.cards = msg.cards
        end
    end

    self:TryHandleCPGH()
end


function Room:JudgeCPGH(card_idx, from_seatid)
    -- body
    self:ClearActions()

    local next_seatid = (from_seatid + 1) % self._room_info.num
    for pos=1, self._room_info.num - 1 do
        local user_info = self:GetUserBySeatid(next_seatid)

        local num_tbl = mjlib.getNumTable(user_info.hands)
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
            self._room_info.putcard_seatid = from_seatid
            self._room_info.putcard_card = mjlib.CardDefine[card_idx]

            local backMsg = json.encode(outCard)
            BASE:SendToClient(user_info.fid, backMsg, #backMsg)
        end

        next_seatid = (next_seatid + 1) % self._room_info.num
    end
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

function Room:GetFirstCPGH(op_type)
    local beg_seatid = self._room_info.putcard_seatid
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


function Room:HandleCPGH(seatid, op_type)
    local putcard_cardidx = mjlib.CardIndex[self._room_info.putcard_card]
    local putcard_seatid = self._room_info.putcard_seatid
    local from_card = self._room_info.putcard_card --mjlib.CardDefine[putcard_card]

    --guo and send cards
    if mjlib.ACTION_GUO == op_type then
        -- send card to next
        local next_seatid = (putcard_seatid + 1) % self._room_info.num

        self:ClearActions()
        self:SendCard(next_seatid)
        return
    end


   local user_info = self:GetUserBySeatid(seatid)
   local user_info_from = self:GetUserBySeatid(putcard_seatid)

   -- del from outcard
    table.removebyvalue_r(user_info_from.outcards, putcard_cardidx)

    if mjlib.ACTION_HU == op_type then

        self:GameOver(seatid, op_type)
        return
    end
    -- add to eats
    local to_eatcard_add = {
        eat = from_card,
        first = from_card,
        type = op_type
    }

    if mjlib.ACTION_GANG == op_type then
        -- delete self hands
        table.remove(user_info.hands, putcard_cardidx)
        table.remove(user_info.hands, putcard_cardidx)
        table.remove(user_info.hands, putcard_cardidx)
        to_eatcard_add.bu = 1

        -- add a card from tails
        if #self._desk_cards == 0 then
            log.info("card over then game over")
            self:GameOver()
            return
        end

        local card_idx = table.remove(self._desk_cards)
        table.insert(user_info.hands, card_idx)
    end
    
    if mjlib.ACTION_PENG == op_type then
        table.remove(user_info.hands, putcard_cardidx)
        table.remove(user_info.hands, putcard_cardidx)
    end

    if mjlib.ACTION_CHI == op_type then
        for i=1,#user_info.actions do    
            if op_type == user_info.actions[i].type then
                -- 17 18 chi 19 
                local cards = user_info.actions[i]
                if #cards ~= 2 then
                    log.error("cards num error")
                    break
                end
                to_eatcard_add.first = math.min(from_card, cards[1], cards[2])
            end
        end
    end

    table.insert(user_info.eats, to_eatcard_add)

    local to_eatcard_del = {
        eat = -1,
        first = -1,
        type = -1
    }

    --send to client msg        
    for i=1, self._room_info.num do
        local to_fid = self:GetUserfidBySeatid(i)

        local action_over = {
            cmd = CMD.RES_ACTIONOVER,
            from_card = from_card,
            from_seatid = putcard_seatid,
            to_seatid = seatid,
            to_eatcard_add = to_eatcard_add,
            to_eatcard_del = to_eatcard_del,
            to_hands = mjlib.getHandDefineTable(user_info.hands, seatid , i, 14),
        }

        local backMsg = json.encode(action_over)
        BASE:SendToClient(to_fid, backMsg, #backMsg)
    end

    --direction to seatid
    self:outDirection(seatid)

    self:ClearActions()
end

function Room:GetHuTypes(user_info)
    return {2, 10}
end

function Room:HuAction(huseatid )

    if huseatid then
        -- local putcard_cardidx = mjlib.CardIndex[self._room_info.putcard_card]
        local putcard_seatid = self._room_info.putcard_seatid
        -- local from_card = self._room_info.putcard_card --mjlib.CardDefine[putcard_card]

        local msg_hu = {
            cmd = CMD.RES_HU,
            fromcard = fromcard,
            huseatid = {huseatid},
            iszimo = putcard_seatid == huseatid,
            cards = {},
        }

        for i=1, self._room_info.num do
            local user_info = self:GetUserBySeatid(i)
        
            local huinfo = {}
            huinfo.eats = user_info.eats
            huinfo.hands = mjlib.getHandDefineTable(user_info.hands, i , i, huseatid == i and 14 or 13)
            huinfo.seatid = user_info.seatid

            if huseatid == i then
                huinfo.types = self:GetHuTypes(user_info)
            end

            table.insert(msg_hu.cards, huinfo)

        end

        for i=1, self._room_info.num do
            local to_fid = self:GetUserfidBySeatid(i)
            local backMsg = json.encode(msg_hu)
        
            BASE:SendToClient(to_fid, backMsg, #backMsg)
        end
    end

end

function Room:GameOver(huseatid , fromcard)
    log.info("game over => ")

    self:HuAction(huseatid)

    -- if huseatid then
    --     return
    -- end
    local msg_gameover = {
        cmd = CMD.RES_GAMEOVER,
        banker_seatid = self._room_info.banker_seatid,
        fromcard = {fromcard},  --unkown
        fromseatid = huseatid,
        scores = {}
    }

    for i=1, self._room_info.num do
        local user_info = self:GetUserBySeatid(i)

        local balanceinfo = {
            incsore = 1,
            score = 12,
            seatid = i
        }

        if balanceinfo == i then
            balanceinfo.types = {1} -- pinghu
        end

        table.insert(msg_gameover.scores, balanceinfo)
    end 

    for i=1, self._room_info.num do
        local to_fid = self:GetUserfidBySeatid(i)
        local backMsg = json.encode(msg_gameover)
        BASE:SendToClient(to_fid, backMsg, #backMsg)
    end
end

function Room:BigGameOver(huseatid )
    log.info("BigGameOver => ")

    local msg_biggameover = {
        cmd = CMD.RES_BIGGAMEOVER,
        scores = {}
    }

    for i=1, self._room_info.num do
        local user_info = self:GetUserBySeatid(i)

        local bigbalanceinfo = {
            owner_seatid = self._room_info.banker_seatid, -- unkown
            score = 12,
            seatid = i
        }

        bigbalanceinfo.paocount = {}

        -- unkown dahuzimo xiaohuzimo jipao dianpao
        table.insert(bigbalanceinfo.paocount, {
            count = 1,
            paotype = 1
            })

        table.insert(msg_gameover.scores, bigbalanceinfo)
    end 

    for i=1, self._room_info.num do
        local to_fid = self:GetUserfidBySeatid(i)
        local backMsg = json.encode(msg_biggameover)
        BASE:SendToClient(to_fid, backMsg, #backMsg)
    end
end

-- objRoom = Room:new()
return Room
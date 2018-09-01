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

    self.BASE:RegCmdCB(CMD.REQ_DISSOLUTIONROOM, handler(self, self.OnReqDissolution))
   
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
                -- goto continue
                userinfo = {ready = false, uid = uid, avatar = "null"}

            end

            userinfo.seatid = i
            lst_user_tmp[userinfo.uid] = userinfo
        end
        ::continue::
        -- until true
    end
    self._lst_user = lst_user_tmp
end

function Room:ResetGame(huseatid)
    for i, v in pairs(self._lst_user) do
        v.ready = false
    end

    self._room_info.play_round = self._room_info.play_round and self._room_info.play_round + 1 or 1

    if huseatid then
        self._room_info.banker_seatid = huseatid
    end
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
        msg.ready = false
    end

    self:BuildUserSeatid(self._room_info)

    -- nerver begin , so first init
    if not self._room_info.play_round then
        self:InitTableInfo()
    end   


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
        local user_info = self:GetUserBySeatid(i)

        if user_info and user_info.uid ~= byuid then
            local backMsg = json.encode(msg_entertable)
            BASE:SendToClient(user_info.fid, backMsg, #backMsg)
        end
    end 
end


function Room:InitTableInfo()
    table.merge(self._room_info, {
        create_mode = 0,
        daikai_mode = 0, 

        gamestate = 0,
        gametype = 1, -- n ren wan fa
        owner_seatid = self:GetUser(self._room_info.uid).seatid,
        banker_seatid = self:GetUser(self._room_info.uid).seatid,

        piao = 0,
        play_round = 1,

        roomtype =  self._room_info.num, -- m_typeGm

        tid = self._room_info.roomid,

        total_round = 2, 
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
        if user_info then
            user_info = clone(user_info)
            user_info.hands = user_info.hands and mjlib.getHandDefineTable(user_info.hands, user_info_for.seatid , j) or {}

            table.insert(msg_tableinfo.players, user_info)
        end
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

function Room:CreateDeskCards()
    local card_ori = mjlib.create()
    mjlib.shuffle(card_ori)
    local card_ap = card_ori

    -- zuo pai
    card_ap = {}
    local hands1 = {16,16,16, 17,17,17, 26,26,26, 28,28,28, 29, 28}
    table.sort(hands1)
    for i=1,#hands1 do
        hands1[i] = mjlib.CardIndex[hands1[i]]
        table.removebyvalue(card_ori, hands1[i])

        table.insert(card_ap, hands1[i])
    end
    local hands2 = {31,31,31, 32,32,32, 33,33,33, 34,34,34, 35}
    table.sort(hands2)
    for i=1,#hands2 do
        hands2[i] = mjlib.CardIndex[hands2[i]]
        table.removebyvalue(card_ori, hands2[i])

        table.insert(card_ap, hands2[i])
    end

    local rest = {16}

    for i=1,#rest do
        local tmp_idx = mjlib.CardIndex[rest[i]]
        table.removebyvalue(card_ori, tmp_idx)

        table.insert(card_ap, tmp_idx)
    end

    for i=1,#card_ori do
        table.insert(card_ap, card_ori[i])
    end

    card_ap = table.reverse(card_ap)
    --end

    self._desk_cards = card_ap
end

function Room:StartGame()

    self:CreateDeskCards()

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
        play_round = self._room_info.play_round
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

    if self._room_info.putcard_seatid ~= user_info.seatid then
        log.debug("not current user to out")
        return
    end

    if user_info.actions then
        log.debug("current user wait to actions")
        return
    end

    local find_pos = table.keyof(user_info.hands, card_idx)
    if not find_pos then
        log.error("not find card")
        return
    end

    table.remove(user_info.hands, find_pos)
    table.sort(user_info.hands)
    -- self._room_info.sendcard_card = msg.card

    self:SendMsgOutCard(msg.card, user_info.seatid)

    -- for cpgh
    local bWaitCPGH = self:JudgeCPGH(card_idx, user_info.seatid)

    if not bWaitCPGH then
        local next_seatid = (user_info.seatid) % self._room_info.num + 1
        self:SendCard(next_seatid)
    end
end

function Room:SendMsgOutCard(card, byseatid)
    
    local outCard = {
        cmd = CMD.RES_OUTCARD,
        card = card,
        seatid = byseatid
    }

    local by_user_info = self:GetUserBySeatid(byseatid)

    for i=1, self._room_info.num do
        local user_info = self:GetUserBySeatid(i)

        outCard.hands = mjlib.getHandDefineTable(by_user_info.hands, byseatid , i)
      
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

    local huinfo, score, pao_type = mjlib.check_hu(num_tbl, true)
    if huinfo then
        table.insert(actions, {
            type = mjlib.ACTION_HU,
            qishou = qishou,
            })
        table.insert(huinfo, mjlib.HU_TYPE_ZM)
        user_info.tmp_huinfo = huinfo
        user_info.tmp_huscore = score
        user_info.tmp_pao_type = pao_type

    else
        local lstgang = mjlib.check_gang(num_tbl)
        if lstgang then
            local options = {}

            for i=1, #lstgang do
                table.insert(options, {
                            cards = {
                                mjlib.CardDefine[lstgang[i]]
                            }})
            end

            table.insert(actions, {
                type = mjlib.ACTION_GANG,
                options = options
            })
        end

        lstgang = mjlib.check_gang_eats(user_info.eats, card_idx)
        if lstgang then
            local options = {}

            for i=1, #lstgang do
                table.insert(options, {
                            cards = {
                                mjlib.CardDefine[lstgang[i]]
                            }})
            end

            table.insert(actions, {
                type = mjlib.ACTION_GANG,
                options = options
            })
        end
    end

    if #actions > 0 then
          -- guo
        table.insert(actions, {type = mjlib.ACTION_GUO})
        
        --save tmp
        user_info.actions = actions

        --save current from seatid
        self._room_info.putcard_seatid = byseatid
        self._room_info.putcard_card = mjlib.CardDefine[card_idx]

        local msg_actions = {
                cmd = CMD.RES_ACTIONS,
                actions = actions
        }

        local backMsg = json.encode(msg_actions)
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
        cmd = CMD.RES_SENDCARD,
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
        cmd = CMD.RES_OUTDICRECTION,
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

    local bWaitCPGH = false
    local next_seatid = (from_seatid ) % self._room_info.num + 1
    for pos=1, self._room_info.num - 1 do
        local user_info = self:GetUserBySeatid(next_seatid)

        local num_tbl = mjlib.getNumTable(user_info.hands)
        -- num_tbl[card_idx] = num_tbl[card_idx] + 1

        local actions = {}

        --hu
        num_tbl[card_idx] = num_tbl[card_idx] + 1
        local huinfo, score, pao_type = mjlib.check_hu(num_tbl)
        if huinfo then
            table.insert(actions, {
                type = mjlib.ACTION_HU
                })
            user_info.tmp_huinfo = huinfo
            user_info.tmp_huscore = score
            user_info.tmp_pao_type = pao_type
        end
        num_tbl[card_idx] = num_tbl[card_idx] - 1

        --gang type 6-bu, 7-gang
        local bGang = mjlib.can_diangang(num_tbl, card_idx)
        if bGang then
            local options = {}
            table.insert(options, {
                        cards = {
                            mjlib.CardDefine[card_idx]
                        }})

            table.insert(actions, {
                type = 7,
                options = options
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

            local msg_actions = {
                cmd = CMD.RES_ACTIONS,
                actions = actions
            }
            --save current from seatid
            self._room_info.putcard_seatid = from_seatid
            self._room_info.putcard_card = mjlib.CardDefine[card_idx]

            local backMsg = json.encode(msg_actions)
            BASE:SendToClient(user_info.fid, backMsg, #backMsg)

            bWaitCPGH = true
        end

        next_seatid = (next_seatid ) % self._room_info.num + 1
    end

    return bWaitCPGH
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
        local ret,seatid = self:GetFirstCPGH(i)
        if ret then
            self:HandleCPGH(seatid, i)

            --jixugang
            if mjlib.ACTION_GANG == i then
                self:JudgeSelfAction(seatid, card_idx)
            end
            return
        end
    end

end

function Room:GetFirstCPGH(op_type)
    local beg_seatid = self._room_info.putcard_seatid
    local seatid_guo = nil
    local next_seatid = (beg_seatid ) % self._room_info.num + 1
    for pos=1, self._room_info.num  do

        local user_info = self:GetUserBySeatid(next_seatid)

        if user_info.actions and #user_info.actions > 0 then
            --todo
            for i=1,#user_info.actions do
                if op_type == mjlib.ACTION_GUO then
                    if op_type == user_info.actions[i].type then
                        if not user_info.actions[i].ack then
                            return false
                        end
                        seatid_guo = next_seatid
                    end
                else
                    if op_type == user_info.actions[i].type and user_info.actions[i].ack then
                        return true,next_seatid
                    end    
                end
            end
        end

        next_seatid = (next_seatid ) % self._room_info.num + 1
    end
    if op_type == mjlib.ACTION_GUO then
        return true,seatid_guo
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
        self:ClearActions()
        if seatid == putcard_seatid then
            return
        end

        local next_seatid = (putcard_seatid ) % self._room_info.num + 1
        self:SendCard(next_seatid)
        return
    end


   local user_info = self:GetUserBySeatid(seatid)
   local user_info_from = self:GetUserBySeatid(putcard_seatid)

   -- del from outcard
    table.removebyvalue_r(user_info_from.outcards, putcard_cardidx)

    if mjlib.ACTION_HU == op_type then

        self:GameOver(seatid, from_card)
        return
    end
    -- add to eats
    local to_eatcard_add = {
        eat = from_card,
        first = from_card,
        -- type = op_type
    }
    local to_eatcard_del = {
        eat = -1,
        first = -1,
        type = -1
    }

    if mjlib.ACTION_GANG == op_type then
        -- delete self hands
        local findSelf = false
        for i=1,#user_info.actions do    
            if op_type == user_info.actions[i].type then
                -- 17 18 chi 19 
                local cards = user_info.actions[i].cards
                local card_gang = putcard_cardidx
                if cards and cards[1] then
                    local card_req = mjlib.CardIndex[cards[1]]
                    if card_req ~= putcard_cardidx then
                        log.error("req action cards error")
                    end
                    card_gang = card_req
                end

                if user_info.eats then
                    for k,v in pairs(user_info.eats) do
                        if mjlib.EAT_PENG == v.type then
                            local eat_idx = mjlib.CardIndex[v.eat]
                            if eat_idx == card_gang then
                                to_eatcard_del = v

                                to_eatcard_add = {
                                        eat = mjlib.CardDefine[card_gang],
                                        first = mjlib.CardDefine[card_gang],
                                        -- type = op_type
                                        -- bu = 1,
                                        type = mjlib.EAT_GANG
                                }


                                findSelf = true

                                table.remove(user_info.eats, k)
                            end
                            break
                        end
                    end
                end

                if not findSelf and user_info.hands then
                    local cnt = table.count_of(user_info.hands, card_gang)
                    if 4 == cnt then

                        table.removebyvalue(user_info.hands, card_gang)
                        table.removebyvalue(user_info.hands, card_gang)
                        table.removebyvalue(user_info.hands, card_gang)
                        table.removebyvalue(user_info.hands, card_gang)

                        to_eatcard_add = {
                                        eat = mjlib.CardDefine[card_gang],
                                        first = mjlib.CardDefine[card_gang],
                                        -- type = op_type
                                        -- bu = 1,
                                        type = mjlib.EAT_GANG
                        }

                        findSelf = true
                    end
                end
            end
        end

        if not findSelf then
            table.removebyvalue(user_info.hands, putcard_cardidx)
            table.removebyvalue(user_info.hands, putcard_cardidx)
            table.removebyvalue(user_info.hands, putcard_cardidx)
            -- to_eatcard_add.bu = 1
            to_eatcard_add.type = mjlib.EAT_GANG
        end

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
        table.removebyvalue(user_info.hands, putcard_cardidx)
        table.removebyvalue(user_info.hands, putcard_cardidx)

        to_eatcard_add.type = 2
    end

    if mjlib.ACTION_CHI == op_type then
        for i=1,#user_info.actions do    
            if op_type == user_info.actions[i].type then
                -- 17 18 chi 19 
                local cards = user_info.actions[i].cards
                if #cards ~= 2 then
                    log.error("cards num error")
                    break
                end
                to_eatcard_add.first = math.min(from_card, cards[1], cards[2])

                table.removebyvalue(user_info.hands, mjlib.CardIndex[cards[1]])
                table.removebyvalue(user_info.hands, mjlib.CardIndex[cards[2]])
            end
        end
        to_eatcard_add.type = 1
    end

    table.insert(user_info.eats, to_eatcard_add)

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
    return user_info.tmp_huinfo or {1}
end

function Room:StatScore(huseatid , fromcard)
    local putcard_seatid = self._room_info.putcard_seatid

    local iszimo = putcard_seatid == huseatid

    local hu_user_info = self:GetUserBySeatid(huseatid)
    if huseatid then
        if iszimo then
            hu_user_info.incsore = (self._room_info.num - 1) * hu_user_info.tmp_huscore
        else
            hu_user_info.incsore = hu_user_info.tmp_huscore
        end

        hu_user_info.score = hu_user_info.score or 0
        hu_user_info.score = hu_user_info.score + hu_user_info.incsore

        for i=1, self._room_info.num do
            local user_info = self:GetUserBySeatid(i)
            if huseatid ~= i then
                if iszimo or putcard_seatid == i then
                    user_info.incsore = -hu_user_info.tmp_huscore
                else
                    user_info.incsore = 0
                end
                user_info.score = user_info.score or 0
                user_info.score = user_info.score + user_info.incsore
            end
        end   
    else
        for i=1, self._room_info.num do
            local user_info = self:GetUserBySeatid(i)
            user_info.incsore = 0
            user_info.score = user_info.score or 0
        end       
    end

    -- CalcScore
    -- table.insert(paocount, {
    --         count = 1,
    --         paotype = 1
    --         })
    if huseatid then
        if hu_user_info.tmp_pao_type then
            hu_user_info.paocount = hu_user_info.paocount or {}

            local findpao = false
            for k,v in pairs(hu_user_info.paocount) do
                if v.paotype == hu_user_info.tmp_pao_type then
                    v.count = v.count + 1
                    findpao = true
                    break
                end
            end

            if not findpao then
                table.insert(hu_user_info.paocount,{
                    count = 1,
                    paotype = hu_user_info.tmp_pao_type
                })
            end
        end
    end
end

function Room:HuAction(huseatid , fromcard)

    -- if huseatid then
        -- local putcard_cardidx = mjlib.CardIndex[self._room_info.putcard_card]
        local putcard_seatid = self._room_info.putcard_seatid
        -- local from_card = self._room_info.putcard_card --mjlib.CardDefine[putcard_card]

        local msg_hu = {
            cmd = CMD.RES_HU,
            fromcard = fromcard,
            huseatid = {huseatid},
            iszimo = putcard_seatid == huseatid,
            cards = {},
            isWksJieSan = not huseatid and 1 or nil
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
    -- end

end

function Room:GameOver(huseatid , fromcard)
    log.info("game over => ")

    self:HuAction(huseatid, fromcard)
    self:StatScore(huseatid, fromcard)

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
            incsore = user_info.incsore,
            score = user_info.score,
            seatid = i
        }

        if huseatid == i then
            balanceinfo.types = self:GetHuTypes(user_info)
        end

        table.insert(msg_gameover.scores, balanceinfo)
    end 

    for i=1, self._room_info.num do
        local to_fid = self:GetUserfidBySeatid(i)
        local backMsg = json.encode(msg_gameover)
        BASE:SendToClient(to_fid, backMsg, #backMsg)
    end

    if self._room_info.play_round == self._room_info.total_round then
        self:BigGameOver()
    end

    self:ResetGame(huseatid)
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
            score = user_info.score,
            seatid = i
        }

        bigbalanceinfo.paocount = user_info.paocount or {}

        -- unkown dahuzimo xiaohuzimo jipao dianpao
        -- table.insert(bigbalanceinfo.paocount, {
        --     count = 1,
        --     paotype = 1
        --     })

        table.insert(msg_biggameover.scores, bigbalanceinfo)
    end 

    for i=1, self._room_info.num do
        local to_fid = self:GetUserfidBySeatid(i)
        local backMsg = json.encode(msg_biggameover)
        BASE:SendToClient(to_fid, backMsg, #backMsg)
    end
end

function Room:OnReqDissolution(msg)
    log.info("Room:OnReqDissolution")
    local msg = type(msg) == "string" and json.decode(msg) or msg
    if CONF.BASE.DEBUG then dump(msg) end

    -- 
    local msg_diss = {
        roomid = self._room_info.roomid,
        uid = msg.uid
    }

    BASE:Dispatch(0, 0, CMD.LVM_CMD_DISSOLUTION, json.encode(msg_diss))

    for i=1, self._room_info.num do
        local to_fid = self:GetUserfidBySeatid(i)

        local backMsg = json.encode({
            cmd = CMD.RES_RESULTDISSOVEROOM,
            result = 1
        })
        BASE:SendToClient(to_fid, backMsg, #backMsg)
    end

    self:HuAction()
    self:BigGameOver()
end

-- objRoom = Room:new()
return Room
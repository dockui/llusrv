local CONF = require "conf"
local CMD = require "cmd"
local BASE = require "base"
local log = require "log"
local json = require "json"
local EVENT = require "LuaEvent"
local ECODE = require "errorcode"
local cache = require "cache"

local ConnMgr = class("connmgr")
function ConnMgr:ctor(obj,data)
    log.info("ConnMgr:ctor()")
    if self.init then self:init(data) end
end
function ConnMgr:init(data)
    log.info("ConnMgr:init()")

    -- login status
    self.mapLoginFidToUid = {}
    

    self.loginServerId = data.loginServerId
    self.roomMgr = data.roomMgr

    BASE:RegCmdCB(CMD.LVM_CMD_CLIENT_CONN, handler(self, self.OnConnect))
    BASE:RegCmdCB(CMD.LVM_CMD_CLIENT_DISCONN, handler(self, self.OnDisConnect))
    BASE:RegCmdCB(CMD.LVM_CMD_CLIENT_MSG, handler(self, self.OnMessage))
    BASE:RegCmdCB(CMD.LVM_CMD_DISSOLUTION, handler(self, self.OnDiss))
    
    self.lst_reg_event = {
        [1] = self.OnHeart1,
        [CMD.REQ_HEART] = self.OnHeart,
        [CMD.REQ_LOGIN] = self.OnLogin,
        [CMD.REQ_EXIT] = self.OnExitRoom
        -- [CMD.REQ_CREATE_TABLE] = self.OnCreateTable,
        -- [CMD.REQ_ENTERTABLE] = self.OnEnterTable,       
    }
    for i,v in pairs(self.lst_reg_event) do
        EVENT:addEventListener(i, self, v)
    end

    -- EVENT:addEventListener(CMD.REQ_HEART, self, self.OnHeart)
    -- EVENT:addEventListener(CMD.REQ_LOGIN, self, self.OnLogin)
    -- EVENT:addEventListener(CMD.REQ_CREATE_TABLE, self, self.OnCreateTable)
    -- EVENT:addEventListener(CMD.REQ_ENTERTABLE, self, self.OnEnterTable)
end

function ConnMgr:OnConnect(msg, fid, sid)
    log.info("ConnMgr:OnConnect:"..fid)

end

function ConnMgr:OnDisConnect(msg, fid, sid)
    log.info("ConnMgr:OnDisConnect:"..fid)

end

function ConnMgr:OnHeart1(msg)
    log.info("ConnMgr:OnHeart:"..msg.fid)
    local backMsg = json.encode(
        {
            cmd = 1,
            code = ECODE.CODE_SUCCESS,
            desc = ECODE.ErrDesc(ECODE.CODE_SUCCESS)
        }
    )
    BASE:SendToClient(msg.fid, backMsg, #backMsg)
end

function ConnMgr:OnHeart(msg)
    log.info("ConnMgr:OnHeart:"..msg.fid)
    local backMsg = json.encode(
        {
            cmd = CMD.REQ_HEART,
            code = ECODE.CODE_SUCCESS,
            desc = ECODE.ErrDesc(ECODE.CODE_SUCCESS)
        }
    )
    BASE:SendToClient(msg.fid, backMsg, #backMsg)
end
function ConnMgr:OnLogin(msg)
    log.info("ConnMgr:OnLogin:"..msg.fid)
    local logincb = function(msg_ret)
        log.info("ConnMgr:OnLogin ret:"..msg_ret)
        local type_ret = type(msg_ret)
        local l_msg = type_ret == "string" and json.decode(msg_ret) or msg_ret
        -- local type_ret2 = type(l_msg)
        -- for k, v in pairs(l_msg) do
        --     print(k, v)
        -- end
        
        -- local e = l_msg.error
        -- local c = l_msg.cmd
        -- local d = l_msg.data
        dump(l_msg, "l_msg")
        
        repeat
            if l_msg.code ~= 0 then
                break
            end

    --  1) "uid"
    --  2) "41"
    --  3) "num"
    --  4) "4"
    --  5) "roomid"
    --  6) "626123"
    --  7) "vid"
    --  8) "1001"
    --  9) "member_1"
    -- 10) "41"
            local inroom_info = l_msg.inroom_info or {}
            -- local num = room_info.num or 4

            if not l_msg.inroomid then
                log.error("connect to login failue: not in room")

                l_msg.code = ECODE.ERR_NOT_IN_ROOM
                l_msg.desc = ECODE.ErrDesc(ECODE.ERR_NOT_IN_ROOM)
                break
            end

            local find_index = nil
            for i=1, inroom_info.num do
                local mem = "member_"..i
                if inroom_info[mem] == l_msg.uid then
                    find_index = i
                    break
                end
            end
            if not find_index then
                log.error("connect to login failue: not join room")
                l_msg.code = ECODE.ERR_NOT_IN_ROOM
                l_msg.desc = ECODE.ErrDesc(ECODE.ERR_NOT_IN_ROOM)
                break
            end

            local inroomid = tonumber(inroom_info.roomid)
            local bExistRoom = self.roomMgr:IsExistRoom(inroomid)
            if not bExistRoom then
                self.roomMgr:CreateRoom(inroom_info)
            else
                self.roomMgr:UpdateRoom(inroom_info)
            end

            l_msg.fid = msg.fid

            self:SetLogin(msg.fid, {
                uid = tonumber(l_msg.uid),
                sid = l_msg.sid
                })

            local backMsg = json.encode(l_msg)
            BASE:SendToClient(msg.fid, backMsg, #backMsg)

            self.roomMgr:JoinRoomEx(inroomid, l_msg)
        until true
    end

    if CONF.BASE.MODE_LUA_MAIN then
        BASE:PostMessageIPC(self.loginServerId, 
            CMD.REQ_LOGIN, 
            json.encode(msg), 
            logincb)

       --  BASE:PostMessageIPC(CONF.LVM_MODULE.CACHE, 
       --      CMD.LVM_CMD_CACHE_SET, 
       --      json.encode({key="myname", val="heiei"}))
       -- BASE:PostMessageIPC(CONF.LVM_MODULE.CACHE, 
       --      CMD.LVM_CMD_CACHE_GET, 
       --      json.encode({key="myname"}), 
       --      function(msg_ret)
       --          log.info("ConnMgr:OnLogin get myname:"..msg_ret)
       --      end)
        -- cache.set("myname","nimmm")

        -- cache.get("myname", 
        --     function(msg_ret)
        --         log.info("ConnMgr:OnLogin get myname:"..msg_ret)
        --     end
        --     )

        return
    end

    BASE:PostMessage(self.loginServerId, CMD.REQ_LOGIN, json.encode(msg), logincb)
end

function ConnMgr:SetLogin(fid, uid)
    log.info("ConnMgr:SetLogin: fid="..fid)
    if CONF.BASE.DEBUG then dump(uid) end

    self.mapLoginFidToUid[fid] = uid
end

function ConnMgr:UnLogin(fid, uid)
    log.info("ConnMgr:UnLogin:"..fid)
    self.mapLoginFidToUid[fid] = nil
end

function ConnMgr:GetLogin(fid, uid)
    local uid = self.mapLoginFidToUid[fid]
    log.info("ConnMgr:GetLogin: fid="..fid)
    if CONF.BASE.DEBUG then dump(uid) end

    return uid
end

function ConnMgr:GetSidByUid(uid)
    for k,v in pairs(self.mapLoginFidToUid) do
        if v.uid == uid then
            return v.sid
        end
    end
end

function ConnMgr:OnExitRoom(msg)
    local msg = type(msg) == "string" and json.decode(msg) or msg
    if CONF.BASE.DEBUG then dump(msg) end

    log.info("ConnMgr:OnExitRoom:"..msg.fid)

   local login_info = self:GetLogin(msg.fid)
   msg.sid = login_info.sid

   local exit_cb = function(msg_ret)
        log.info("ConnMgr:OnExitRoom ret:"..msg_ret)
        local l_msg = json.decode(msg_ret)

        repeat
            if l_msg.code ~= 0 then
                break
            end

            local inroom_info = l_msg
            -- local num = room_info.num or 4

            -- if not inroom_info.roomid then
            --     log.error("connect to login failue: room not exist")

            --     l_msg.error = ECODE.ERR_NOT_EXIST
            --     l_msg.data = ECODE.ErrDesc(ECODE.ERR_NOT_EXIST)
            --     break
            -- end

            local inroomid = tonumber(inroom_info.roomid)
            local bExistRoom = self.roomMgr:IsExistRoom(inroomid)
            if bExistRoom then
                self.roomMgr:UpdateRoom(inroom_info)
            end

            --update room
            -- self.roomMgr:UpdateUserInfo(inroomid, )
            self.roomMgr:ExitUser(inroomid, {uid=login_info.uid, inroom_info = inroom_info})
            --broadcast

            self:UnLogin(msg.fid, nil)
        until true
    end

   if CONF.BASE.MODE_LUA_MAIN then
        BASE:PostMessageIPC(self.loginServerId, 
            CMD.REQ_EXIT, 
            json.encode(msg), 
            exit_cb)

    end
end

-- function ConnMgr:OnCreateTable(msg)
--     log.info("LVM_CMD_CLIENT_OnCreateTable:"..msg.fid)
    
--     local uid = self:GetLogin(msg.fid)
--     if uid == nil then
--         local backMsg = json.encode(
--             {
--                 cmd = CMD.REQ_CREATE_TABLE,
--                 error = ECODE.ERR_VERIFY_FAILURE,
--                 data = ECODE.ErrDesc(ECODE.ERR_VERIFY_FAILURE)
--             }
--         )
--         BASE:SendToClient(msg.fid, backMsg, #backMsg)
--         return
--     end

--     local roomid = self.roomMgr:CreateRoom(1001, 4)

--     local ret 
--     ret = {
--         cmd = CMD.REQ_CREATE_TABLE,
--         error = 0,
--         data = {
--             roomid = roomid
--         }
--     }
--     local backMsg = json.encode(ret)
--     BASE:SendToClient(msg.fid, backMsg, #backMsg)
-- end

-- function ConnMgr:OnEnterTable(msg)
--     log.info("LVM_CMD_CLIENT_OnEnterTable:"..msg.fid)
--     -- roomid 
--     local uid = self:GetLogin(msg.fid)
--     if uid == nil then
--         local backMsg = json.encode(
--             {
--                 cmd = CMD.REQ_ENTERTABLE,
--                 error = ECODE.ERR_VERIFY_FAILURE,
--                 data = ECODE.ErrDesc(ECODE.ERR_VERIFY_FAILURE)
--             }
--         )
--         BASE:SendToClient(msg.fid, backMsg, #backMsg)
--         return
--     end

--     local code, roomid = self.roomMgr:AddUser(msg.data.roomid, uid)
    
--     if code == ECODE.CODE_SUCCESS then
--         self.roomMgr:JoinRoom(roomid, msg.fid, uid)

--         local backMsg = json.encode(
--             {
--                 cmd = CMD.REQ_ENTERTABLE,
--                 error = 0,
--                 data = {
--                     roomid = roomid
--                 }
--             }
--         )
--         BASE:SendToClient(msg.fid, backMsg, #backMsg)
--     else
--         local backMsg = json.encode(
--             {
--                 cmd = CMD.REQ_ENTERTABLE,
--                 error = code,
--                 data = ECODE.ErrDesc(code)
--             }
--         )
--         BASE:SendToClient(msg.fid, backMsg, #backMsg)
--     end


-- end

function ConnMgr:OnDiss(msg, fid, sid)
    log.info("ConnMgr:OnDiss")
    local msg = type(msg) == "string" and json.decode(msg) or msg
    if CONF.BASE.DEBUG then dump(msg) end

    -- local login_info = self:GetLogin(msg.fid)

    self.roomMgr:RemoveRoom(msg.roomid)

    msg.sid = self:GetSidByUid(msg.uid)

    if CONF.BASE.MODE_LUA_MAIN then
        BASE:PostMessageIPC(self.loginServerId, 
                CMD.REQ_DISSOLUTIONROOM, 
                json.encode(msg))
    end
end

function ConnMgr:OnMessage(strmsg, fid, sid)
    log.info("ConnMgr:OnMessage:"..fid..";msg:"..strmsg)
    if strmsg == "quit" then
        BASE:CloseClient(fid)
        return
    end
    --REQEST: {cmd=1, data={} }
    --RESPONSE: {cmd=2, error=0, data={}}
    local status,msg,err = pcall(json.decode,strmsg)
    if status and msg and msg.cmd then

        local login_info = self:GetLogin(fid)
        local uid = login_info and login_info.uid

        if msg.cmd ~= CMD.REQ_LOGIN then
            if uid == nil then
                local backMsg = json.encode(
                    {
                        cmd = 0,
                        code = ECODE.ERR_VERIFY_FAILURE,
                        desc = ECODE.ErrDesc(ECODE.ERR_VERIFY_FAILURE)
                    }
                )
                log.warn("Response:"..backMsg)
                BASE:SendToClient(fid, backMsg, #backMsg)
                return
            end
        end

        msg.fid = fid
        msg.uid = uid

        EVENT:dispatchEvent(msg.cmd, msg)

        -- translate to room which not process
        local isProcess = self.lst_reg_event[msg.cmd]
        if not isProcess then
            local roominfo = self.roomMgr:FindUser(uid)
            if roominfo then
                BASE:GetLvm(roominfo.lvm_roomid).BASE:PostMessage(roominfo.lvm_roomid, msg.cmd, json.encode(msg))
            else
                log.error("user not found in room")
            end
        end
    else
        local backMsg = "echo from server:"..strmsg
        BASE:SendToClient(fid, backMsg, #backMsg)
    end
end

return ConnMgr
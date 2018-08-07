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

    self.lst_reg_event = {
        [CMD.REQ_HEART] = self.OnHeart,
        [CMD.REQ_LOGIN] = self.OnLogin,
        [CMD.REQ_CREATE_TABLE] = self.OnCreateTable,
        [CMD.REQ_ENTERTABLE] = self.OnEnterTable,       
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
function ConnMgr:OnHeart(msg)
    log.info("ConnMgr:OnHeart:"..msg.fid)
    local backMsg = json.encode(
        {
            cmd = CMD.REQ_HEART,
            error = ECODE.CODE_SUCCESS,
            data = ECODE.ErrDesc(ECODE.CODE_SUCCESS)
        }
    )
    BASE:SendToClient(msg.fid, backMsg, #backMsg)
end
function ConnMgr:OnLogin(msg)
    log.info("ConnMgr:OnLogin:"..msg.fid)
    local logincb = function(msg_ret)
        log.info("ConnMgr:OnLogin ret:"..msg_ret)
        local l_msg = json.decode(msg_ret)

        local backMsg = msg_ret

        if l_msg.error == 0 then
            self:SetLogin(msg.fid, l_msg.data.uid)
        end

        BASE:SendToClient(msg.fid, backMsg, #backMsg)
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
    log.info("ConnMgr:SetLogin: fid="..fid..";uid"..uid)
    self.mapLoginFidToUid[fid] = uid
end

function ConnMgr:UnLogin(fid, uid)
    log.info("ConnMgr:UnLogin:")
    self.mapLoginFidToUid[fid] = nil
end

function ConnMgr:GetLogin(fid, uid)
    log.info("ConnMgr:GetLogin: fid="..fid..";uid")
    return self.mapLoginFidToUid[fid]
end

function ConnMgr:OnCreateTable(msg)
    log.info("LVM_CMD_CLIENT_OnCreateTable:"..msg.fid)
    
    local uid = self:GetLogin(msg.fid)
    if uid == nil then
        local backMsg = json.encode(
            {
                cmd = CMD.REQ_CREATE_TABLE,
                error = ECODE.ERR_VERIFY_FAILURE,
                data = ECODE.ErrDesc(ECODE.ERR_VERIFY_FAILURE)
            }
        )
        BASE:SendToClient(msg.fid, backMsg, #backMsg)
        return
    end

    local roomid = self.roomMgr:CreateRoom(1001, 4)

    local ret 
    ret = {
        cmd = CMD.REQ_CREATE_TABLE,
        error = 0,
        data = {
            roomid = roomid
        }
    }
    local backMsg = json.encode(ret)
    BASE:SendToClient(msg.fid, backMsg, #backMsg)
end

function ConnMgr:OnEnterTable(msg)
    log.info("LVM_CMD_CLIENT_OnEnterTable:"..msg.fid)
    -- roomid 
    local uid = self:GetLogin(msg.fid)
    if uid == nil then
        local backMsg = json.encode(
            {
                cmd = CMD.REQ_ENTERTABLE,
                error = ECODE.ERR_VERIFY_FAILURE,
                data = ECODE.ErrDesc(ECODE.ERR_VERIFY_FAILURE)
            }
        )
        BASE:SendToClient(msg.fid, backMsg, #backMsg)
        return
    end

    local code, roomid = self.roomMgr:AddUser(msg.data.roomid, uid)
    
    if code == ECODE.CODE_SUCCESS then
        self.roomMgr:JoinRoom(roomid, msg.fid, uid)

        local backMsg = json.encode(
            {
                cmd = CMD.REQ_ENTERTABLE,
                error = 0,
                data = {
                    roomid = roomid
                }
            }
        )
        BASE:SendToClient(msg.fid, backMsg, #backMsg)
    else
        local backMsg = json.encode(
            {
                cmd = CMD.REQ_ENTERTABLE,
                error = code,
                data = ECODE.ErrDesc(code)
            }
        )
        BASE:SendToClient(msg.fid, backMsg, #backMsg)
    end


end

function ConnMgr:OnMessage(strmsg, fid, sid)
    log.info("LVM_CMD_CLIENT_MSG:"..fid..";msg:"..strmsg)
    if strmsg == "quit" then
        BASE:CloseClient(fid)
        return
    end
    --REQEST: {cmd=1, data={} }
    --RESPONSE: {cmd=2, error=0, data={}}
    local status,msg,err = pcall(json.decode,strmsg)
    if status and msg and msg.cmd then
        msg.fid = fid
        EVENT:dispatchEvent(msg.cmd, msg)

        -- translate to room which not process
        local isProcess = self.lst_reg_event[msg.cmd]
        if not isProcess then
            local uid = self:GetLogin(msg.fid)
            if uid then
                local roominfo = self.roomMgr:FindUser(uid)
                if roominfo then
                    BASE:GetLvm(roominfo.lvm_roomid).Base:PostMessage(roominfo.lvm_roomid, msg.cmd, strmsg)
                end
            end
        end
    else
        local backMsg = "echo from server:"..strmsg
        BASE:SendToClient(fid, backMsg, #backMsg)
    end
end

return ConnMgr
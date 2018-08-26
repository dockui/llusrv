local CMD = require "cmd"
local log = require "log"
local CONF = require "conf"
local json = require "json"

local Base = class("Base")

local m_instance = nil

function Base.getInstance()
    if m_instance == nil then
        m_instance = Base:new()
    end
    return m_instance
end

function Base:ctor()
    self.SESSION_ID = 0
    self.SessionCB={}
    self.TIMER_CB={}
    self.REG_CMD_CB={}
    self.MSG_CB=nil

    self.GEN_LVM_ID = 0
    self._mapLvm = {}
    self._cb_ipc_send = {}
end

function Base:NewSID()

    repeat  
        self.SESSION_ID = self.SESSION_ID + 1
        return self.SESSION_ID
        -- if self.SessionCB[self.SESSION_ID] == nil then
        --     return self.SESSION_ID
        -- end
    until (false)
    -- error
end

function Base:NewLvmID()
    self.GEN_LVM_ID = 0
    repeat  
        self.GEN_LVM_ID = self.GEN_LVM_ID + 1
        return self.GEN_LVM_ID
    until (false)
    -- error
end

function Base:Reg(sid, cb)  
    self.SessionCB[sid] = cb
end

function Base:RegTM(tid, once, cb)  
    self.TIMER_CB[tid] = {cb=cb, once=once}
end
function Base:UnRegTM(tid)
    self.TIMER_CB[tid] = nil
end

function Base:RegCmdCB(cmd, cb)  
    self.REG_CMD_CB[cmd] = cb
end
function Base:UnCmdCB(cmd)
    self.REG_CMD_CB[cmd] = nil
end

function Base:_Dispatch(cmd, msg, fid, sid)  
    local cb = self.SessionCB[sid]
    if cb then
        cb(msg, fid, sid)
        self.SessionCB[sid] = nil
    elseif self.MSG_CB then
         self.MSG_CB(cmd, msg, fid, sid)
    end
end

function Base:DPTM(tid)  
    log.debug("self.DPTM:"..tid)
    local dt = self.TIMER_CB[tid]
    if dt and dt.cb then
        dt.cb(tid)
        if dt.once ~= 0 then
            self.TIMER_CB[tid] = nil
        end
    end
end

function Base:External(...)
    EXTERNAL(...)
end

function Base:Dispatch(fid, sid, cmd, msg)  
    log.debug("dispatch fid="..fid..";sid="..sid.. ";cmd="..cmd..";msg="..(msg or ""))

    local cmd_cb = self.REG_CMD_CB[cmd]
    if cmd_cb then
        cmd_cb(msg, fid, sid)
        return
    end

    if cmd == CMD.LVM_CMD_ONTIMER then
        -- local tid = (string.unpack("i",msg))
        self:DPTM(sid)
    else 
        self:_Dispatch(cmd, msg, fid, sid)        
    end
end

function Base:Time(tid, elapse, once, cb) 
    log.info("M.Time:"..tid)
    self:RegTM(tid, once, cb)
    self:External(CMD.LVM_CMD_SETTIMER, 0, tid, elapse, once)
    return true
end

function Base:KillTime(tid) 
    log.info("M.KillTime:"..tid)
    self:UnRegTM(tid)
    self:External(CMD.LVM_CMD_KILLTIMER, 0, tid)
    return true
end


function Base:RegMsgCB(cb)
    self.MSG_CB = cb
end

--method, host, path, param
function Base:HttpReq(method, host, path, param, cb)

    local sid = self:NewSID()  
    self:Reg(sid, cb)
    
    self:External(CMD.LVM_CMD_HTTP_REQ, sid, method, host, path, param)
    return true
end


function Base:CreateLvm(file, obj)   
    log.info("CreateLvm beg:"..file)
    if CONF.BASE.MODE_LUA_MAIN then
        local newId = self:NewLvmID()
        self._mapLvm[newId] = obj
        return newId
    end

    local id = self:External(CMD.LVM_CMD_CREATLVM, 0, file)
    log.info("CreateLvm end:"..file.."; id:"..id)
    return id
end

function Base:GetLvm(vid)
    if CONF.BASE.MODE_LUA_MAIN then
        return self._mapLvm[vid]
    end
end

function Base:DelLvm(vid)   
    log.info("LVM_CMD_DELLVM beg:"..vid)

    if CONF.BASE.MODE_LUA_MAIN then
        self._mapLvm[vid] = nil
        return
    end

    local ret = self:External(CMD.LVM_CMD_DELLVM, 0, vid)
    return ret
end

function Base:RegSendToClientCB(cb)
    self.cb_send = cb
end

function Base:SendToClient(wid, msg, len)   
    if not wid then
        log.warn("SendToClient wid is null")
        return
    end

    log.debug("SendToClient wid:"..wid..", msg:"..msg..";len:"..len)

    if CONF.BASE.MODE_LUA_MAIN then
        if self.cb_send then
            self.cb_send(wid, msg, len)
        end
        return
    end

    self:External(CMD.LVM_CMD_CLIENT_MSG_BACK, 0, wid, msg, len)
end

function Base:RegCloseClientCB(cb)
    self.cb_closeclt = cb
end

function Base:CloseClient(wid)   
    log.debug("CloseClient beg:"..wid)

    if CONF.BASE.MODE_LUA_MAIN then
        if self.cb_closeclt then
            self.cb_closeclt(wid)
        end
        return
    end

    self:External(CMD.LVM_CMD_CLIENT_CLOSE, 0, wid)
end

-- CMD.LVM_CMD_MSG
function Base:PostMessage(dest, cmd, msg, cb)  
    local sid = 0
    if cb then
        sid = self:NewSID()  
        self:Reg(sid, cb)
    end

    if CONF.BASE.MODE_LUA_MAIN then
        self:Dispatch(0, sid, cmd, msg)
        return
    end

    self:External(CMD.LVM_CMD_MSG, sid, cmd, dest, msg, #msg)
end

-- CMD.LVM_CMD_MSG_RET
function Base:RetMessage(dest, msg, sid)  
    sid = sid or 0

    if CONF.BASE.MODE_LUA_MAIN then
        self:Dispatch(0, sid, CMD.LVM_CMD_MSG_RET, msg)
        return
    end

    self:External(CMD.LVM_CMD_MSG_RET, sid, CMD.LVM_CMD_MSG_RET, dest, msg, #msg)
end

-- CMD.LVM_CMD_MSG
function Base:PostMessageIPC(dest, cmd, msg, cb)  
    local sid = 0
    if cb then
        sid = self:NewSID()  
        self:Reg(sid, cb)
    end

    if CONF.BASE.MODE_LUA_MAIN then
        local msg_ipc = {
            sid = sid,
            cmd = cmd,
            msg = msg
        }
        if self._cb_ipc_send[dest] then
            self._cb_ipc_send[dest](json.encode(msg_ipc))
        end
        return
    end
end

-- CMD.LVM_CMD_MSG_RET
function Base:RetMessageIPC(dest, msg, sid)  
    sid = sid or 0

    if CONF.BASE.MODE_LUA_MAIN then
        local msg_ipc = {
            sid = sid,
            cmd = CMD.LVM_CMD_MSG_RET,
            msg = msg
        }
        if self._cb_ipc_send[dest] then
            self._cb_ipc_send[dest](json.encode(msg_ipc))
        end
        return
    end

end

function Base:RegIPCSendCB(dest,cb)
    self._cb_ipc_send[dest] = cb
    -- self.cb_ipc_send = cb
end

function Base:GetIPCReadCB()
    return function(handle, err, sock)

      local msgret, err = sock:recvx()
      -- print("msg from cli="..msg, err)
      if err then
        log.error("ipc read err="..tostring(err))
        return
      end

      local status,msg,err = pcall(json.decode,msgret)
      if status and msg and msg.cmd and msg.sid and msg.msg then
          self:Dispatch(0, msg.sid, msg.cmd, msg.msg)
      end
    end
end



_G.Dispatch = function(from_id, sid, cmd, msg)  
    -- local m = (string.unpack("i",msg))
    return Base.getInstance():Dispatch(from_id, sid, cmd, msg)
end

return Base.getInstance()

package.cpath = "/usr/local/lib/lua/5.3/?.so;"..package.cpath
package.path = "/usr/local/Cellar/lua/5.3.4_3/share/lua/5.3/?.lua;"..package.path

local uv  = require"lluv"
local ws  = require"lluv.websocket"
local ut     = require "lluv.utils"
local socket = require "socket"

local zmq   = require "lzmq"
uv.poll_zmq = require "lluv.poll_zmq"

require "functions"

local CONF = require "conf"
local CMD = require "cmd"
local BASE = require "base"

local log = require "log"
local json = require "json"

local ep = arg[1] or "ipc://llusrv"

local ip = (socket.dns.toip(socket.dns.gethostname()))
local wsurl, sprot = "ws://"..ip..":8800", "gm"

local UVLoop = class("UVLoop")
function UVLoop:ctor(obj,data)
    log.info("UVLoop:ctor()")
    if self.init then self:init(data) end
end
function UVLoop:init(data)
    log.info("UVLoop:init()")
    self.SESSION_ID = 0
    self._MapConn = {}
end

function UVLoop:NewSID()
    repeat  
        self.SESSION_ID = self.SESSION_ID + 1
        return self.SESSION_ID
        -- if self.SessionCB[self.SESSION_ID] == nil then
        --     return self.SESSION_ID
        -- end
    until (false)
    -- error
end

function UVLoop:Run()
    log.info("UVLoop:init()")

    --###login
    local ctx = zmq.context()
    local cli_login = ctx:socket{"PAIR", linger = 0, sndtimeo = 0, rcvtimeo = 0, 
        connect = CONF.LVM_IPC_NAME[CONF.LVM_MODULE.LOGIN] }

    BASE:RegIPCSendCB(CONF.LVM_MODULE.LOGIN, function(msg) 
        cli_login:send(msg)
    end)
    uv.poll_zmq(cli_login):start(BASE:GetIPCReadCB())

    --##cache
    local cli_cache = ctx:socket{"PAIR", linger = 0, sndtimeo = 0, rcvtimeo = 0, 
        connect = CONF.LVM_IPC_NAME[CONF.LVM_MODULE.CACHE] }

    BASE:RegIPCSendCB(CONF.LVM_MODULE.CACHE, function(msg) 
        cli_cache:send(msg)
    end)
    uv.poll_zmq(cli_cache):start(BASE:GetIPCReadCB())


    BASE:RegSendToClientCB(handler(self, self.SendToClient))
    BASE:RegCloseClientCB(handler(self, self.CloseClient))

    
    local server = ws.new()
    server:bind(wsurl, sprot, function(server, err)
        if err then
            log.error("Server error:", err)
            return server:close()
        end

        server:listen(
            handler(self, self.on_connection) )
    end)


    uv.run()
end


function UVLoop:SendToClient(id, msg, len) 
    local conn = self:GetConn(id)
    if conn then
  -- CONTINUATION  = 0,
  -- TEXT          = 1,
  -- BINARY        = 2,
  -- CLOSE         = 8,
  -- PING          = 9,
  -- PONG          = 10
        conn:write(msg, 1)
    end
end

function UVLoop:CloseClient(id)
    -- self._mapClose[id] = os.time()

    self:CloseConn(id)
    self:OnDisconn(id)
end

function UVLoop:on_read(cli, err, data)
    local id = cli.data.id
    if err then 
        log.error ("onread err=", err, ";cli=", type(cli), cli)
        local id = cli.data.id
        if id then
            self:CloseConn(id)
            self:OnDisconn(id)
        end
        return
    end
    log.info("cli="..cli.data.id..";onread="..data)

    BASE:Dispatch(id, 0, CMD.LVM_CMD_CLIENT_MSG, data)
end

function UVLoop:on_connection(server, err)
    -- if err then 
    --     log.error("on_connection err:", err)
    --     return server:close() 
    -- end
    -- local conn = server:accept()
    -- self:AddConn(conn)
    -- conn:start_read(handler(self, self.on_read))
    -- server:close()

    if err then
      log.error("Server listen:", err)
      return server:close()
    end

    local cli = server:accept()
    cli:handshake(function(conn, err, protocol)
        if err then
            log.error("Server handshake error:", err)
            return cli:close()
        end
        log.info("New server connection:", protocol)

        self:AddConn(conn)

        conn:start_read( handler(self, self.on_read) )
    end)

end

function UVLoop:AddConn(conn)
    local newId = self:NewSID()
    self._MapConn[newId] = conn
    conn.data = {
        id = newId,
        buffer = ut.Buffer.new("\r\n")
    }
    BASE:Dispatch(newId, 0, CMD.LVM_CMD_CLIENT_CONN)
end

function UVLoop:OnDisconn(id)
    BASE:Dispatch(id, 0, CMD.LVM_CMD_CLIENT_DISCONN)   
end

function UVLoop:FindConn(conn)
    for i,c in pairs(self._MapConn) do
        if c == conn then
            return i
        end
    end
    return nil
end

function UVLoop:CloseConn(id)
    local conn = self._MapConn[id]
    if conn then
        conn.data.buffer:reset()
        conn.data = nil
        conn:close()
        self._MapConn[id] = nil
    end    
end

function UVLoop:GetConn(id)
    return self._MapConn[id]
end

function UVLoop:RemoveConn(id)
    self._MapConn[id] = nil
end

  
return UVLoop


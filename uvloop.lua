
package.cpath = "/usr/local/lib/lua/5.3/?.so;"..package.cpath
package.path = "/usr/local/Cellar/lua/5.3.4_3/share/lua/5.3/?.lua;"..package.path

local uv  = require"lluv"
local ws  = require"lluv.websocket"
local ut     = require "lluv.utils"
local socket = require "lluv.luasocket"

require "functions"

local CMD = require "cmd"
local BASE = require "base"

local log = require "log"
local json = require "json"


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

    self._mapClose = {}
    self.t_close = uv.timer():start(1, 2000, handler(self, self.OnTimeClose))

    BASE:RegSendToClientCB(handler(self, self.SendToClient))
    BASE:RegCloseClientCB(handler(self, self.CloseClient))

    uv.tcp():bind("127.0.0.1", 5556, handler(self, self.on_bind))
    -- uv.pipe():bind([[\\.\pipe\sock.echo]], on_bind)

    uv.run()
end

function UVLoop:OnTimeClose()
    
    local t_cur = os.time()
    while true do
        local find_id
        for i,t in pairs(self._mapClose) do
            if os.difftime(t_cur, t) > 6 then
                find_id = i
                break
            end
        end
        if not find_id then
            break
        end

        self._mapClose[find_id] = nil
        self:CloseConn(find_id)
        self:OnDisconn(find_id)

    end

end

function UVLoop:SendToClient(id, msg, len) 
    local conn = self:GetConn(id)
    if conn then
        local packstr = string.pack(">s2",msg)
        conn:write(packstr)
    end
end

function UVLoop:CloseClient(id)
    self._mapClose[id] = os.time()

    -- self:CloseConn(id)
    -- self:OnDisconn(id)
end

function UVLoop:on_write(cli, err)
    if err then 
        print ("on_write err=", err)
        local id = cli.data.id
        if id then
            self:CloseConn(id)
            self:OnDisconn(id)
        end
        return
    end
    -- print ("on_write")
  end
  
function UVLoop:on_read(cli, err, data)
    local id = cli.data.id
    if err then 
        print ("onread err=", err, ";cli=", type(cli), cli)
        local id = cli.data.id
        if id then
            self:CloseConn(id)
            self:OnDisconn(id)
        end
        return
    end
    print ("cli=", cli.data.id,";onread="..data)
   

    local buffer = cli.data.buffer
    buffer:append(data)

    while true do
        if buffer:size() < 2 then
            break
        end

        local size = string.unpack(">H", buffer:read_n(2))
        if buffer:size() < size then
            buffer:prepend(string.pack(">H",size))
            break
        end

        local line = buffer:read_n(size)
        log.info("read from client:"..line)
        

        BASE:Dispatch(id, 0, CMD.LVM_CMD_CLIENT_MSG, line)

        -- local packstr = string.pack(">s2",line)
        -- local wt = cli:write(packstr)
        
    end

    -- local wt = cli:write(data, handler(self, self.on_write))
    -- print (wt)
end

function UVLoop:on_connection(server, err)
    if err then 
        log.info("on_connection err:", err)
        return server:close() 
    end
    local conn = server:accept()
    self:AddConn(conn)
    conn:start_read(handler(self, self.on_read))
    -- server:close()
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

function UVLoop:on_bind(server, err, host, port)
    if err then
        print("Bind fail:" .. tostring(err))
        return server:close()
    end

    if port then host = host .. ":" .. port end
    print("Bind on: " .. host)

    server:listen(handler(self, self.on_connection))
end
  
return UVLoop


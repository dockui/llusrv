
package.path = "?.lua;utils/?.lua;common/?.lua;game/?.lua;"..package.path
package.cpath = "luaclib/?.so;"..package.cpath

local uv  = require"lluv"
local ws  = require"lluv.websocket"
local socket = require "socket"


local json = require "json"
local CONF = require "conf"
local CMD = require "cmd"


print(socket.dns.gethostname())
local ip = (socket.dns.toip(socket.dns.gethostname()))
local wsurl, sprot = "ws://"..ip..":8800", "gm"

-- local server = ws.new()
-- server:bind(wsurl, sprot, function(self, err)
--   if err then
--     print("Server error:", err)
--     return server:close()
--   end

--   server:listen(function(self, err)
--     if err then
--       print("Server listen:", err)
--       return server:close()
--     end

--     local cli = server:accept()
--     cli:handshake(function(self, err, protocol)
--       if err then
--         print("Server handshake error:", err)
--         return cli:close()
--       end
--       print("New server connection:", protocol)

--       cli:start_read(function(self, err, message, opcode)
--         if err then
--           print("Server read error:", err)
--           return cli:close()
--         end

--         cli:write(message, opcode)
--       end)
--     end)
--   end)
-- end)

function on_send(cli, str)
    
    cli:write(str, 1)
    print("on send:"..str)
end

function on_quit(cli)
  

  uv.timer():start(30000, function() 
    -- local packstr = string.pack(">s2","quit")
    -- cli:write(packstr)
    on_send(cli, "quit")
    -- cli:close() 
  end)
end

function on_write2(cli)
    local str = json.encode({
          cmd=CMD.REQ_HEART,
          -- data = {
            msg = "req heart"
          -- }
        })
    
    on_send(cli, str)

local str = json.encode({
          cmd=CMD.REQ_LOGIN,
          -- data = {
            username = "lisi"
          -- }
        })
    on_send(cli, str)

on_quit(cli)
end


local cli = ws.new()
cli:connect(wsurl, sprot, function(self, err)
  if err then
    print("Client connect error:", err)
    return cli:close()
  end

  local counter = 1
  cli:start_read(function(self, err, message, opcode)
    if err then
      print("Client read error:", err)
      return cli:close()
    end
    print("Client recv:", message)

  end)

  on_write2(cli)
end)

uv.run()

-- read input stream line by line
package.path = "?.lua;utils/?.lua;common/?.lua;game/?.lua;"..package.path
package.cpath = "luaclib/?.so;"..package.cpath

package.cpath = "/usr/local/lib/lua/5.3/?.so;"..package.cpath
package.path = "/usr/local/Cellar/lua/5.3.4_3/share/lua/5.3/?.lua;"..package.path

require "functions"
local uv = require "lluv"
local ut = require "lluv.utils"
local socket = require "socket"

local json = require "json"
local CONF = require "conf"
local CMD = require "cmd"

-- local host, port = "127.0.0.1", 5556
local host, port = (socket.dns.toip(socket.dns.gethostname())), 5556

local counter = 0
local function on_write(cli, err)
  if err then
    cli:close()
    if err:name() ~= "EOF" then
      print("************************************")
      print("ERROR: ", err)
      print("************************************")
    end
    return 
  end

  counter = counter + 1
  if counter > 10 then

    return
  end

  if counter == 10 then
    -- wait all repspnses
    -- uv.timer():start(1000, function() cli:close() end)
      local packstr = string.pack("<s4","quit")
  	  cli:write(packstr, on_write)
    return
  end

  local str = json.encode({
  	-- cmd=CMD.REQ_HEART,
  	msg="line",
  	counter=counter
  	})
  local packstr = string.pack("<s4",str)
  cli:write(packstr, on_write)

  -- cli:write(string.sub(packstr, 1, 4), on_write)
  -- cli:write(string.sub(packstr, 5), on_write)
end

function on_send(cli, str)
    local packstr = string.xor(str)
    packstr = string.pack("<s4",packstr)
    cli:write(packstr)
    print("on send:"..str)
end

function on_quit(cli)
  

  uv.timer():start(30000, function() 
    -- local packstr = string.pack(">s2","quit")
    -- cli:write(packstr)
    str = "quit"
    
    on_send(cli, str)
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

local buffer = ut.Buffer.new("\r\n")

local function read_data(cli, err, data)
  if err then
    cli:close()
      
      print("ERROR: ", err)
      print("************************************")
    return 
  end

  buffer:append(data)
  while true do
  	if buffer:size() < 4 then
  		break
  	end

  	local size = string.unpack("<I4", buffer:read_n(4))
  	if buffer:size() < size then
  		buffer.prepend(string.pack("<I4",size))
  		break
  	end

    local line = buffer:read_n(size)
    line = string.xor(line)
    print("read_data="..line)
  end
end

uv.tcp():connect(host, port, function(cli, err)
  if err then return cli:close() end

  cli:start_read(read_data)
  on_write2(cli)
end)

uv.run(debug.traceback)

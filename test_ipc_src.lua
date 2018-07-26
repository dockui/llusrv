package.path = "..\\src\\lua\\?.lua;" .. package.path

local uv    = require "lluv"
local zmq   = require "lzmq"
uv.poll_zmq = require "lluv.poll_zmq"

local ep = arg[1] or "ipc://llusrv"
-- local ep = arg[1] or "tcp://127.0.0.1:5555"

local ctx = zmq.context()

local srv = ctx:socket{"PAIR", 
   linger = 0,
   sndtimeo = 0, rcvtimeo = 0, 
   bind = ep }

print("ZMQ   version:", zmq.version(true))
print("Test endpoint:", ep)

local counter = 0
local called = 0

-- local t = uv.timer():start(1000, 1000, function(self)
--   counter = counter + 1
--   srv:send(tostring(counter))
--   if counter == 5 then
--     self:close()
--     ctx:shutdown()
--   end
-- end)

uv.poll_zmq(srv):start(function(handle, err, sock)

  local msg, err = sock:recvx()
  print("msg from cli="..msg, err)

  srv:send(msg)

end)

uv.run()



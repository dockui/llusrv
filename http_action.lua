
local log = require "log"
local json = require "json"
local ECODE = require "errorcode"
local CMD = require "cmd"

local ossl = require "ossl"

local db = require "db"
local cache = require "cache"
cache.init()
cache = cache._client

db.init()
local nick = require "nickname"

local _M = {
	
}

local _M = {}
_M.__index = _M

function _M.new()
  local M = {}

  return setmetatable(M, self)
end


_M._output = function(response, cmd, data)
	response:statusCode(200)
	response:addHeader('Content-Type', 'text/plain')

	if not data then 
		data = cmd 
		cmd = nil
	end

	local ret = {
			ret = 0,
            error = 0,
            code = 0,
            data = data
    }

    if cmd then ret.cmd = cmd end

    local ostr = json.encode(ret)
    log.info("http response => "..ostr)
	response:write(ostr)
end

_M._output_fail = function(response, cmd, data)
	response:statusCode(200)
	response:addHeader('Content-Type', 'text/plain')

	if not data then 
		data = cmd 
		cmd = nil
	end

	local ret = {
			ret = data,
			code = data,
			desc = ECODE.ErrDesc(data),
            error = data,
            data = ECODE.ErrDesc(data)
    }
    if cmd then ret.cmd = cmd end

    local ostr = json.encode(ret)
    log.info("http response => "..ostr)
	response:write(ostr)
end

_M.config = function(response, params)
	local msg = {
            
            ip = "123456",
            port = "8800"
     }
     _M._output(response, msg)
 end
-- {type=confirm  game conn confirm 
-- }
--http://localhost:9090/api?params={"action":"login","sid":"798c1d9e2793f9a7522723b921b01186"}
_M.login = function(response, params)

	local msg = {
            name = "null"
     }

    repeat
		local sid = params.sid or "0"
		local uid = cache:get(sid..":sid")
		if not uid then
			if params.cmd == CMD.REQ_LOGIN then 
				log.error("login not find user")
				break 
			end

			local name = nick.new()
			uid = db.insert("T_USER", {
				name = name
				})
			sid = ossl.md5(ossl.uuid())

			cache:set(sid..":sid", uid)

			local key_uid = uid..":uid"
			cache:hmset(key_uid, {uid=uid, sid=sid, gold=6, name=name})
		end

		-- local key_uid = uid..":uid"
		msg = _M._get_user_info(uid) or {}
		if msg.sid ~= sid then 
			log.error("login sid error ")
			break 
		end

		--clear rooms info
		if msg.inroomid then
			local inroom_info = _M._get_room_info(msg.inroomid)
			if table.empty(inroom_info) then
				cache:hdel(key_uid, "inroomid")
				msg.inroomid = nil
			end

			if params.cmd == CMD.REQ_LOGIN then
				msg.inroom_info = inroom_info
				-- msg.cmd = CMD.RES_LOGIN
			end
		end

		_M._output(response, CMD.RES_LOGIN, msg)
		return
	until(true)

	_M._output_fail(response, CMD.RES_LOGIN, ECODE.ERR_VERIFY_FAILURE)
end

_M._is_logined = function(sid)
	local sid = sid or "0"
	local uid = cache:get(sid..":sid")

	if not uid then
		return false
	end

	local l_sid = cache:hget(uid..":uid", "sid")
	if l_sid ~= sid then 
		return false 
	end

	return true
end

_M._get_room_info = function(roomid)
	local room_info = cache:hgetall(roomid..":roomid")

--  1) "uid"
--  2) "41"
--  3) "vid"
--  4) "1001"
--  5) "num"
--  6) "4"
--  7) "roomid"
--  8) "626122"
--  9) "member_1"
-- 10) "41"

	room_info.uid = room_info.uid and tonumber(room_info.uid)
	room_info.roomid = room_info.roomid and tonumber(room_info.roomid)
	room_info.vid = room_info.vid and tonumber(room_info.vid)
	
	room_info.num = room_info.num and tonumber(room_info.num) or 4

	for i=1, room_info.num do
		local mem = "member_"..i
		if room_info[mem] then
			room_info[mem] = room_info[mem] and tonumber(room_info[mem])
		end
	end

	return room_info
end

_M._get_user_info_bysid = function(sid)
	local sid = sid or "0"
	local uid = cache:get(sid..":sid")

	if not uid then
		return {}
	end

	return _M._get_user_info(uid)
end

_M._get_user_info = function(uid)

--  1) "sid"
--  2) "25cb9e6933fa744017db030d2390fcb4"
--  3) "name"
--  4) "\xe6\xad\xa2\xe5\xae\xa0"
--  5) "uid"
--  6) "41"
--  7) "gold"
--  8) "12"
--  9) "inroomid"
-- 10) "626122"

	local info = cache:hgetall(uid..":uid")
	info.uid = info.uid and tonumber(info.uid)
	info.gold = info.gold and tonumber(info.gold) or 0
	info.inroomid = info.inroomid and tonumber(info.inroomid)

	return info
end

_M._set_user_info = function(sid, info, reset)
	local sid = sid or "0"
	local uid = cache:get(sid..":sid")

	if not uid then
		return nil
	end
	

	local key_uid = uid..":uid"
	
	if reset then
		cache:del(key_uid)
	end

	cache:hmset(key_uid, info)
end

_M._AllocNewRoomId = function()
    local ROOM_BEG = 626121
    repeat  
        ROOM_BEG = ROOM_BEG + 1

        if not cache:exists(ROOM_BEG..":roomid") then
            return ROOM_BEG
        end
    until (false)
    --unreachable
    return ROOM_BEG
end

-- {"sid":"", "vid":1001, "num":4 }
_M.CreateRoom = function(response, params)
	if not _M._is_logined(params.sid) then
		_M._output_fail(response, ECODE.ERR_VERIFY_FAILURE)
		return
	end

	local info = _M._get_user_info_bysid(params.sid)
	-- info.gold = info.gold and tonumber(info.gold) or 0
	
	-- gold
	local gold_need = 2
	if info.gold == nil or info.gold < gold_need then
		_M._output_fail(response, ECODE.ERR_GOLD_NOT_ENOUGH)
		return
	end

	info.gold = info.gold - gold_need
	-- _M._set_user_info(params.sid, info)
	local key_uid = info.uid..":uid"
	cache:hset(key_uid, "gold", info.gold)

	-- create_room
	local roomid = _M._AllocNewRoomId()
	local key_room = roomid..":roomid"

	local room_info = {
		uid=info.uid, 
		vid=params.vid, 
		num=params.num, 
		roomid=roomid
	}

	cache:hmset(key_room, room_info)
	cache:expire(key_room, 24*3600) -- one day

	-- local msg = {
 --            roomid = roomid
 --     }
     _M._output(response, room_info)
 end

-- {"sid":"", "roomid":1001}
_M.join_room = function(response, params)
	if not params.roomid then
		_M._output_fail(response, ECODE.ERR_PARAMS)
		return
	end

	if not _M._is_logined(params.sid) then
		_M._output_fail(response, ECODE.ERR_VERIFY_FAILURE)
		return
	end

	local info = _M._get_user_info_bysid(params.sid)
	-- info.inroomid = info.inroomid and tonumber(info.inroomid) or nil

	if info.inroomid and info.inroomid ~= params.roomid then
		_M._output_fail(response, ECODE.ERR_ALREADY_IN_ROOM)
		return
	end

	local roomid = params.roomid or info.inroomid or "0"

	-- local key_room = params.roomid
	local room_info = _M._get_room_info(roomid)
	-- local num = room_info.num or 4

	if table.empty(room_info) then
		--clear in room
		if info.inroomid then
			info.inroomid = nil
			local key_uid = info.uid..":uid"
			cache:hdel(key_uid, "inroomid")
		end

		_M._output_fail(response, ECODE.ERR_NOT_EXIST)
		return
	end

	local isExist = false
	local null_index = nil
	for i=1, room_info.num do
		local mem = "member_"..i
		if not null_index and not room_info[mem] then
			null_index = i
		end

		if room_info[mem] == info.uid then
			isExist = true
			break
		end
	end

	if not isExist  then
		if not null_index then
			_M._output_fail(response, ECODE.ERR_ROOM_FULL)
			return
		end

		local mem = "member_"..null_index
		room_info[mem] = info.uid

		local key_room = roomid..":roomid"
		cache:hset(key_room, mem, info.uid)
		cache:expire(key_room, 24*3600) -- one day
	end

	--set in room
	info.inroomid = room_info.roomid
	local key_uid = info.uid..":uid"
	cache:hset(key_uid, "inroomid", room_info.roomid)

	_M._output(response, room_info)
end

-- {"sid":"", "roomid":1001}
_M.exit_room = function(response, params)
	if not _M._is_logined(params.sid) then
		_M._output_fail(response, ECODE.ERR_VERIFY_FAILURE)
		return
	end

	local info = _M._get_user_info_bysid(params.sid)
	local roomid = params.roomid or info.inroomid or "0"
	
	local room_info = _M._get_room_info(roomid)
	local num = room_info.num or 4

	if table.empty(room_info) then
		--clear in room
		if info.inroomid then
			info.inroomid = nil
			local key_uid = info.uid..":uid"
			cache:hdel(key_uid, "inroomid")
		end

		_M._output_fail(response, ECODE.ERR_NOT_EXIST)
		return
	end

	local find_index = nil
	local null_index = nil
	for i=1, num do
		local mem = "member_"..i
		if not null_index and not room_info[mem] then
			null_index = i
		end

		if room_info[mem] == info.uid then
			find_index = i
			break
		end
	end

	if find_index then
		local mem = "member_"..find_index
		room_info[mem] = nil

		local key_room = roomid..":roomid"
		cache:hdel(key_room, mem)
		cache:expire(key_room, 24*3600) -- one day
	end

	--clear in room
	if info.inroomid then
		info.inroomid = nil
		local key_uid = info.uid..":uid"
		cache:hdel(key_uid, "inroomid")
	end

	_M._output(response, room_info)
end

return _M
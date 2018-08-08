
local log = require "log"
local json = require "json"
local ECODE = require "errorcode"

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


_M.output = function(response, data)
	response:statusCode(200)
	response:addHeader('Content-Type', 'text/plain')

	local ret = {
            error = 0,
            data = data
     }

    local ostr = json.encode(ret)
    log.info("http response => "..ostr)
	response:write(ostr)
end

_M.output_fail = function(response, code)
	response:statusCode(200)
	response:addHeader('Content-Type', 'text/plain')

	local ret = {
            error = code,
            data = ECODE.ErrDesc(code)
     }

	response:write(json.encode(ret))
end

_M.config = function(response, params)
	local msg = {
            
            ip = "123456",
            port = "8800"
     }
     _M.output(response, msg)
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
			if params.type == "confirm" then break end

			local name = nick.new()
			uid = db.insert("T_USER", {
				name = name
				})
			sid = ossl.md5(ossl.uuid())

			cache:set(sid..":sid", uid)

			local key_uid = uid..":uid"
			cache:hmset(key_uid, {uid=uid, sid=sid, gold=6, name=name})
		end

		msg = cache:hgetall(uid..":uid") or {}
		if msg.sid ~= sid then break end

		_M.output(response, msg)
		return
	until(true)

	_M.output_fail(response, ECODE.ERR_VERIFY_FAILURE)
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

_M._get_user_info = function(sid)
	local sid = sid or "0"
	local uid = cache:get(sid..":sid")

	if not uid then
		return nil
	end

	local info = cache:hgetall(uid..":uid")
	return info
end

_M._set_user_info = function(sid, info)
	local sid = sid or "0"
	local uid = cache:get(sid..":sid")

	if not uid then
		return nil
	end

	local key_uid = uid..":uid"
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
_M.create_room = function(response, params)
	if not _M._is_logined(params.sid) then
		_M.output_fail(response, ECODE.ERR_VERIFY_FAILURE)
		return
	end

	local info = _M._get_user_info(params.sid)
	info.gold = info.gold and tonumber(info.gold) or 0
	
	-- gold
	local gold_need = 2
	if info.gold == nil or info.gold < gold_need then
		_M.output_fail(response, ECODE.ERR_GOLD_NOT_ENOUGH)
		return
	end

	info.gold = info.gold - gold_need
	-- _M._set_user_info(params.sid, info)
	local key_uid = info.uid..":uid"
	cache:hset(key_uid, "gold", info.gold)

	-- create_room
	local roomid = _M._AllocNewRoomId()
	local key_room = roomid..":roomid"
	cache:hmset(key_room, {uid=info.uid, vid=params.vid, num=params.num, roomid=roomid})
	cache:expire(key_room, 24*3600) -- one day

	local msg = {
            roomid = roomid
     }
     _M.output(response, msg)
 end

-- {"sid":"", "roomid":1001}
_M.join_room = function(response, params)
	if not params.roomid then
		_M.output_fail(response, ECODE.ERR_PARAMS)
		return
	end

	if not _M._is_logined(params.sid) then
		_M.output_fail(response, ECODE.ERR_VERIFY_FAILURE)
		return
	end

	local info = _M._get_user_info(params.sid)
	info.inroomid = info.inroomid and tonumber(info.inroomid) or nil

	if info.inroomid and info.inroomid ~= params.roomid then
		_M.output_fail(response, ECODE.ERR_ALREADY_IN_ROOM)
		return
	end

	local roomid = params.roomid or info.inroomid or "0"

	local key_room = params.roomid..":roomid"
	local room_info = cache:hgetall(key_room)
	local num = room_info.num or 4

	if not room_info.uid or not room_info.vid or not room_info.roomid then
		_M.output_fail(response, ECODE.ERR_NOT_EXIST)
		return
	end

	local isExist = false
	local null_index = nil
	for i=1, num do
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
			_M.output_fail(response, ECODE.ERR_ROOM_FULL)
			return
		end

		local mem = "member_"..null_index
		-- room_info[mem] = info.uid

		cache:hset(key_room, mem, info.uid)
		cache:expire(key_room, 24*3600) -- one day

		--set in room
		info.inroomid = room_info.roomid
		local key_uid = info.uid..":uid"
		cache:hset(key_uid, "inroomid", room_info.roomid)
	end

	_M.output(response, room_info)
end

-- {"sid":"", "roomid":1001}
_M.exit_room = function(response, params)
	if not _M._is_logined(params.sid) then
		_M.output_fail(response, ECODE.ERR_VERIFY_FAILURE)
		return
	end

	local info = _M._get_user_info(params.sid)
	local roomid = params.roomid or info.inroomid or "0"
	
	local key_room = roomid..":roomid"
	local room_info = cache:hgetall(key_room)
	local num = room_info.num or 4

	if not room_info.uid or not room_info.vid or not room_info.roomid then
		_M.output_fail(response, ECODE.ERR_NOT_EXIST)
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

		cache:hdel(key_room, mem)
		cache:expire(key_room, 24*3600) -- one day
	end

	--clear in room
	if info.inroomid then
		info.inroomid = nil
		local key_uid = info.uid..":uid"
		cache:hdel(key_uid, "inroomid")
	end

	_M.output(response, room_info)
end

return _M
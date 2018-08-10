local CMD = require "cmd"
local ECODE = require "errorcode"
local BASE = require "base"
local log = require "log"
local json = require "json"

local CONF = require "conf"
local Room = require "room"
local Login = require "m_login"


local RoomMgr = class("RoomMgr")

function RoomMgr:ctor(obj,data)
    log.info("RoomMgr:ctor()")
    if self.init then self:init(data) end
end
function RoomMgr:init(data)
    log.info("RoomMgr:init()")

    self._list_room = {}
    self._map_user_to_room = {}
end

function RoomMgr:FindUser(userid)
    -- for _,v in pairs(self._list_room) do
    --     for i,u in pairs(v) do
    --         if u == userid then
    --             return v
    --         end
    --     end
    -- end
    -- return nil
    return self._map_user_to_room[userid]
end

-- function RoomMgr:AddUser(roomid, userid)
    
--     local room = self:FindUser(userid)
--     if room ~= nil then
--         return ECODE.CODE_SUCCESS, room.roomid
--     end

--     local room = self._list_room[roomid]
--     if room == nil then
--         return ECODE.ERR_NOT_EXIST
--     end

--     if #room.user >= room.count then
--         return ECODE.ERR_ROOM_FULL
--     end

--     room.user[#room.user + 1] = userid
--     return ECODE.CODE_SUCCESS, roomid
-- end

-- function RoomMgr:JoinRoom(roomid, fid, uid)
--     local roominfo = self._list_room[roomid]
--     if nil == roominfo then
--         -- (roominfo.lvm_roomid)
--         return ECODE.ERR_NOT_EXIST
--     end

--     BASE:PostMessage(roominfo.lvm_roomid, CMD.REQ_ENTERTABLE, json.encode({
--         fid = fid,
--         uid = uid
--     })) 
-- end

function RoomMgr:JoinRoomEx(roomid, data)
    local roominfo = self._list_room[roomid]
    if nil == roominfo then
        -- (roominfo.lvm_roomid)
        return ECODE.ERR_NOT_EXIST
    end

    BASE:PostMessage(roominfo.lvm_roomid, CMD.REQ_ENTERTABLE, json.encode(data)) 
end

function RoomMgr:ExitUser(roomid, data)
    local roominfo = self._list_room[roomid]
    if nil == roominfo then
        -- (roominfo.lvm_roomid)
        return ECODE.ERR_NOT_EXIST
    end

    BASE:PostMessage(roominfo.lvm_roomid, CMD.REQ_EXIT, json.encode(data)) 
end

function RoomMgr:UpdateUserInfo(roomid, data)
    local roominfo = self._list_room[roomid]
    if nil == roominfo then
        -- (roominfo.lvm_roomid)
        return ECODE.ERR_NOT_EXIST
    end

    BASE:PostMessage(roominfo.lvm_roomid, CMD.LVM_CMD_UPDATE_USER_INFO, json.encode(data)) 
end

function RoomMgr:IsExistRoom(roomid)
    return self._list_room[roomid] ~= nil
end

function RoomMgr:RemoveRoom(roomid)
    local roominfo = self._list_room[roomid]
    if roominfo then
        self:RemoveUserToRoom(roominfo)
        BASE:DelLvm(roominfo.lvm_roomid)
    end
    self._list_room[roomid] = nil
end

function RoomMgr:CreateRoom(data)
    log.info("RoomMgr:CreateRoom()")
    
    local lvm_roomid = BASE:CreateLvm(CONF.LVM_MODULE.ROOM, Room:new())

    -- local newid = self:AllocNewId()
    -- self._list_room[newid] = {
    --     lvm_roomid = lvm_roomid,
    --     roomid = newid,
    --     vid=vid,
    --     count=count,
    --     user={}
    -- }

    data.lvm_roomid = lvm_roomid
    
    -- data.user = {}
    -- for i=1, data.num do
    --     local mem = "member_"..i
    --     data.user[i] = tonumber(data[mem])
    -- end

    self._list_room[data.roomid] = data

    self:BuildUserToRoom(data)

    return data.roomid
end

function RoomMgr:UpdateRoom(data)
    local data_ori = self._list_room[data.roomid]
    
    if not data_ori then
        return
    end

    self:RemoveUserToRoom(data_ori)

    local lvm_roomid = data_ori.lvm_roomid
    data.lvm_roomid = lvm_roomid

    -- data.user = {}
    -- for i=1, data.num do
    --     local mem = "member_"..i
    --     data.user[i] = tonumber(data[mem])
    -- end

    self._list_room[data.roomid] = data

    self:BuildUserToRoom(data)
    return data.roomid
end

function RoomMgr:RemoveUserToRoom(data)
    for i=1, data.num do
        local mem = "member_"..i
        if data[mem] then
            self._map_user_to_room[tonumber(data[mem]] = nil
        end
    end
end

function RoomMgr:BuildUserToRoom(data)
    for i=1, data.num do
        local mem = "member_"..i
        if data[mem] then
            self._map_user_to_room[tonumber(data[mem]] = data
        end
    end
end


function RoomMgr:AllocNewId()
    local ROOM_BEG = 626121
    repeat  
        ROOM_BEG = ROOM_BEG + 1
        if self._list_room[ROOM_BEG] == nil then
            return ROOM_BEG
        end
    until (false)
    --unreachable
    return ROOM_BEG
end

return RoomMgr
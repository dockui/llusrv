local _M = {

}

_M.BASE = {
    MODE_LUA_MAIN = true
}

_M.LVM_MODULE = {
    LOGIN = 1,
    ROOM = 2
}

_M.LVM_MODULE_FILE = {
    LOGIN = "script/m_login.lua",
    ROOM = "script/game/room.lua"
}

return _M
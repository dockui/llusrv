local _M = {

}

_M.BASE = {
    MODE_LUA_MAIN = true,
    MODE_WS = false,
    HTTP_ADDR = "http://localhost:8888/api"
}

_M.LVM_MODULE = {
	CACHE = 1,
    LOGIN = 100,
    ROOM = 200
}

_M.LVM_MODULE_FILE = {
    [_M.LVM_MODULE.LOGIN] = "script/m_login.lua",
    [_M.LVM_MODULE.ROOM] = "script/game/room.lua"
}

_M.LVM_IPC_NAME = {
	[_M.LVM_MODULE.CACHE] = "ipc://llusrv_cache",
    [_M.LVM_MODULE.LOGIN] = "ipc://llusrv_login"
}

return _M
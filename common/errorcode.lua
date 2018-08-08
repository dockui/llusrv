local M = {
    CODE_SUCCESS = 0,
    ERR_PARAMS = 1000,
    ERR_NOT_EXIST = 1010,
    ERR_ROOM_FULL = 1020,
    ERR_NOT_EXIST_USER = 1030,
    ERR_VERIFY_FAILURE = 1040,
    ERR_GOLD_NOT_ENOUGH = 1050,
    ERR_ALREADY_IN_ROOM = 1060,
}
local Desc = {
    [M.CODE_SUCCESS] = "success",
    [M.ERR_PARAMS] = "params error",
    [M.ERR_NOT_EXIST] = "not exist",
    [M.ERR_ROOM_FULL] = "room is full",
    [M.ERR_NOT_EXIST_USER] = "user not exist",
    [M.ERR_VERIFY_FAILURE] = "user verify failure",  
    [M.ERR_GOLD_NOT_ENOUGH] = "gold not enough",
    [M.ERR_ALREADY_IN_ROOM] = "member already in room"
}
function M.ErrDesc(code)
    return Desc[code] or "not found"
end
return M
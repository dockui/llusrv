
local luasql = require "luasql.mysql" --luarocks install luasql-mysql MYSQL_INCDIR=/usr/local/Cellar/mysql/8.0.11/include/mysql

local LuaQuB = require "LuaQuB"


local nick = require "nickname"

--创建环境对象
local env = assert(luasql.mysql())

local _M = {
	_DB = "DB_TEST",
	_USER = "root",
	_PWD = "root"
}
_M.__index = _M

function _M.new(...)
  local M = {}

  M = setmetatable(M, self)
  M.init(...)
  return M
end

_M.init = function(ip, port)
	_M._conn = assert(env:connect(_M._DB, _M._USER, _M._PWD,
		ip or "127.0.0.1", port or 8889))
	-- _M._conn = assert(env:connect("DB_TEST","root","root","127.0.0.1",8889))

	_M._conn:execute"SET NAMES UTF8"

end

_M.test = function()

-- insert into T_USER(name) values("nihao");
-- select last_insert_id();

	-- local cur = assert (_M._conn:execute ("SELECT * from T_USER"))
	-- print(cur:numrows())
	-- local ret = _M.insert("T_USER", {
	-- 	name = "nihao_ya"
	-- 	})
	-- print(ret)

	for i=1,100 do
		print(nick.new())
	end

end

_M.uninit = function()
	_M._conn:close()  --关闭数据库连接
	env:close()   --关闭数据库环境
end

-- INSERT INTO `DB_TEST`.`T_USER`
-- (name)
-- VALUES
-- ('fddsada');
_M.insert = function(t_name, data)
	local Object, tInsert = LuaQuB.new(), data

	Object:insert( t_name , tInsert )

	local sqlstr = tostring(Object)

	local cur = assert (_M._conn:execute (sqlstr))
	
	if cur ~= 1 then
		return -1
	end

	sqlstr = "SELECT LAST_INSERT_ID()"
	cur = assert (_M._conn:execute (sqlstr))
	if cur == nil then
		return -1
	end

	local num = cur:fetch()
	
	return num	

end

return _M


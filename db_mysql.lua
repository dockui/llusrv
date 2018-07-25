-- -*- coding: UTF-8 -*-

package.cpath = "/Users/caobo/myroot/third/luasql/src/mysql.so;"..package.cpath


print (package.cpath)


local luasql = require "luasql.mysql"

--创建环境对象
env = assert(luasql.mysql())

--连接数据库
conn = assert(env:connect("DB_TEST","root","root","127.0.0.1",8889))

--操作数据数据库
conn:execute"SET NAMES UTF8"

--执行数据库操作
--下面这种方式有问题，貌似和lua库有关
--[[
cur = conn:execute("SELECT * from people")
row = cur:fetch({},"a")
while row do
    print(string.format("%s   %s",row.name,row.email))
    row = cur:fetch(row,"a")
end
--]]
--操作数据库文法2
-- function rows (connection, sql_statement)
--   local cursor = assert (connection:execute (sql_statement))
--   return function ()
--     return cursor:fetch()
--   end
-- end
-- print("范德萨")
-- for name,email in rows(conn ,"SELECT * from T_USER") do
--     print( type(name) , #email)
--     print(name, email)
-- end

io.write("hel")
local cur = assert (conn:execute ("SELECT * from T_USER"))
print(cur:numrows())

conn:close()  --关闭数据库连接
env:close()   --关闭数据库环境

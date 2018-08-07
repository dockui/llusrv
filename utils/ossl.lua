
-- local cipher = require "openssl.cipher"

-- local tp = "AES-128-CBC"
-- local key, iv = "abcdabcdabcdabcd", "abcdabcdabcdabcc"

local socket = require("socket") 
--  luarocks install uuid
local uuid = require("uuid")

-- luarocks install md5
local des56 = require 'des56'
local md5 = require"md5"

local key = '&3g4&gs*&3$$##'

local _M = {
	
}

local _M = {
	-- _cipher = cipher.new(tp)
}
_M.__index = _M

function _M.new()
  local M = {}

  return setmetatable(M, self)
end

_M.encrypt = function(text)
	-- local res = _M._cipher:encrypt(key, iv):final(text)
	-- res = string.encode.hex(res)
	-- return res
	local res = des56.crypt(text, key)
	res = string.encode.hex(res)
	return res
end

_M.decrypt = function(text)
	-- local res = string.decode.hex(text)
	-- res = _M._cipher:decrypt(key, iv):final(res)
	-- return res
	local res = string.decode.hex(text)
	res = des56.decrypt(res, key)
	return res
end

_M.md5 = function(text)
	local mr = md5.sumhexa(text)
	return mr
end

_M.uuid = function()
	uuid.seed()
	return uuid()
end


return _M

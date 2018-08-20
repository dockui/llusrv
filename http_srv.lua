package.path = "?.lua;utils/?.lua;common/?.lua;game/?.lua;"..package.path
package.cpath = "luaclib/?.so;"..package.cpath

local log = require "log"
local json = require "json"
local ECODE = require "errorcode"


require "functions"

local Action = require "http_action"

local pegasus = require 'pegasus'

local server = pegasus:new({
  port='9090',
  location='/../www'
})

server:start(function (request, response)

	local errcode = 404
	repeat

		--http://localhost:9090/api?
		--params={%22action%22:%22login%22,%22a%22:1}
		local path = request:path()
		if path == "/api" then
			local params = request:params()
			if not params or not params.params then
				errcode = ECODE.ERR_PARAMS
				break
			end


			-- dump(params, "params")
			params = string.urldecode(params.params)
			
			log.info("http request => "..params)

			local status,params = pcall(json.decode,params)
			if not status or not params then
				errcode = ECODE.ERR_PARAMS
				break
			end

			if params.action and Action[params.action] then
				Action[params.action](response, params)
			else
				break
			end
		elseif response.status ~= 200 then
			errcode = response.status
			break
		end
		return
	until true

	Action._output_fail(response, errcode)

	-- local params = request:params()
	-- params = string.urldecode(params.params or "{}")
	
	-- dump(request:headers(), "headers")
	-- dump(request:path(), "path")
	-- dump(params, "params")
	-- -- dump(request:method(), "method")
	-- -- dump(request:post(), "post")
	-- -- dump(request.ip, "ip")
	-- -- dump(request.port, "port")
	
	-- response:statusCode(200)
	-- response:addHeader('Content-Type', 'text/plain')
	-- response:write('Hello from Pegasus')
end)



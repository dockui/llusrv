

package.path = "?.lua;utils/?.lua;common/?.lua;game/?.lua;"..package.path
package.cpath = "luaclib/?.so;"..package.cpath

require "functions"

local CONF = require "conf"
local CMD = require "cmd"
local BASE = require "base"

local log = require "log"
local json = require "json"

local Room = require "room"

local mjlib = require "cs.mjlib"

log.configure(4)

local objRoom = Room:new()

local room_info = {
	num = 4,
	banker_seatid = 1
}
objRoom:TestSetRoomInfo(room_info)

local lst_user = {}
lst_user[1] = {
	fid = 11,
	seatid = 1,
	name = "test1"
} 
lst_user[2] = {
fid = 12,
	seatid = 2,
	name = "test2"
} 
lst_user[3] = {
fid = 13,
	seatid = 3,
	name = "test3"
} 
lst_user[4] = {
fid = 14,
	seatid = 4,
	name = "test4"
} 

-- objRoom:TestSetUser(lst_user)
-- objRoom:StartGame()

-- objRoom:OnOutCard({card=6, uid=1})

-- objRoom:SendMsgSendCard(23, 1)
-- objRoom:outDirection(2)

-- local hands = {16,16,16,17,21,23,25,26,26,28,28,29,17, 21}
local hands = {16,16,16,17,17,17}
for i=1,#hands do
	hands[i] = mjlib.CardIndex[hands[i]]
end
local num_tbl = mjlib.getNumTable(hands)

local bhu = mjlib.check_hu(num_tbl)
print(bhu)



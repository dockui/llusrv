

package.path = "./lib/?.lua;../../?.lua;../../utils/?.lua;../../common/?.lua;../../game/?.lua;"..package.path package.cpath = "../../luaclib/?.so;"..package.cpath
require "functions"local CONF = require "conf"local CMD = require "cmd"local BASE = require "base" local log = require "log"local json = require "json"local Tebl = require "Tebl"log.configure(4)local tebl = Tebl:new()
require "bitExtend"

function math.mod(x,y)
	return x % y
end

local CardFind = require("CardFind")
local Card = require("Card")
local CardStatistics = require("CardStatistics")
local CardAnalysis = require("CardAnalysis")
local CardFunc = require("CardFunc")

tebl:start()

print("begin")

local date = os.date("[%y-%m-%d %H:%M:%S]")
print(date)

---local val = 0x0A | 0xF0
--print(string.format("%2x", val))

local m_find = CardFind.new()

local cards_define = {0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,
0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x01B,0x1C, 0x1D,
0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B, 0x2C, 0x2D,
0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B, 0x3C, 0x3D,}

-- local play_cards = {0x01,0x11}
-- local hole_cards = {0x02,0x12}

-- local card_stat0 = CardStatistics.new()
-- card_stat0:statistics(play_cards)
-- dump(card_stat0,"card_stat0", 20)
-- local card_ana0 = CardAnalysis.new()
-- card_ana0:analysis(card_stat0,fourdaithree)
-- dump(card_ana0, "card_ana0", 20)
-- local card_stat1 = CardStatistics.new()
-- card_stat1:statistics(hole_cards)
-- dump(card_stat1,"card_stat1", 20)
-- m_find:find_bomb(card_ana0, card_stat0, card_stat1)

-- local play_cards = {0x01,0x11}
-- local hole_cards = {0x02,0x12}

local play_cards = {0x03,0x04,0x05,0x06,0x07, 0x37, 0x37, 0x38, 0x38, 0x38, 0x38}
dump(play_cards)
local b = CardFunc.new().getBaseValue(play_cards)

dump(play_cards)




			
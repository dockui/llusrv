package.path = "../?.lua;"..package.path

-- local utils = require "utils"

local jiang = {
    [2] = true,
    [5] = true,
    [8] = true,
    [11]= true,
    [14]= true,
    [17]= true,
    [20]= true,
    [23]= true,
    [26]= true
}

local M = {}

M.CardType = {
    [1] = {min = 1, max = 9, chi = true},
    [2] = {min = 10, max = 18, chi = true},
    [3] = {min = 19, max = 27, chi = true},
    [4] = {min = 28, max = 34, chi = false},
}

M.CardDefine = {
    11, 12, 13, 14, 15, 16, 17, 18, 19, -- wan
    21, 22, 23, 24, 25, 26, 27, 28, 29, -- tong
    31, 32, 33, 34, 35, 36, 37, 38, 39, --suo
    41, 42, 43, 44, 45, 46, 47,
    -- 东、南、西、北、中、发、白
}

M.CardIndex = { 
[11] =  1,
[12] =  2,
[13] =  3,
[14] =  4,
[15] =  5,
[16] =  6,
[17] =  7,
[18] =  8,
[19] =  9,
[21] = 10,
[22] = 11,
[23] = 12,
[24] = 13,
[25] = 14,
[26] = 15,
[27] = 16,
[28] = 17,
[29] = 18,
[31] = 19,
[32] = 20,
[33] = 21,
[34] = 22,
[35] = 23,
[36] = 24,
[37] = 25,
[38] = 26,
[39] = 27,
[41] = 28,
[42] = 29,
[43] = 30,
[44] = 31,
[45] = 32,
[46] = 33,
[47] = 34,
}

M.COLOR_WAN = 1
M.COLOR_TONG = 2
M.COLOR_TIAO = 3
M.COLOR_ZI = 4
M.COLOR_HUA = 5

M.ACTION_HU = 8
M.ACTION_GANG = 7
M.ACTION_PENG = 5
M.ACTION_CHI = 4
M.ACTION_GUO = 1

M.EAT_BUGANG = 5
M.EAT_ANGANG = 4
M.EAT_GANG = 3
M.EAT_PENG = 2
M.EAT_CHI = 1


local COLORS = {"万","筒","条"}

function M.get_color(card)
    return math.floor((card-1)/9) + 1
end

function M.get_color_str(card)
    local color = M.get_color(card)
    return COLORS[color]
end

function M.get_card_str(index)
    if index >= 1 and index <= 9 then
        return index .. "万"
    elseif index >= 10 and index <= 18 then
        return (index - 9) .. "筒"
    elseif index >= 19 and index <= 27 then
        return (index - 18) .. "条"
    end

    local t = {"东","西","南","北","中","发","白"}
    return t[index - 27]
end

function M.getNumTable(tbl, zi)
    local t = {}
    
    local num = 3*9

    if zi then
        num = num + 7
    end

    for i=1,num do
        table.insert(t, 0)
    end

    for i=1,#tbl do
        t[tbl[i]] = t[tbl[i]] + 1
    end
    return t
end

function M.getDefineTable(tbl)
    local t = {}
    for i=1,#tbl do
        t[i] = M.CardDefine[tbl[i]]
    end
    return t
end

function M.getHandDefineTable(tbl, curseatid, orseatid, total)
    local t = {}
    for i=1,#tbl do
        if curseatid ~= orseatid then
            t[i] = -1
        else
            t[i] = M.CardDefine[tbl[i]]
        end
    end

    total = total or 13
    local len = #t
    if len < total then
        for i=1,total-len do
            table.insert(t, 1, 0)
        end
    end
    len = #t
    if len < 14 then
        table.insert(t, 0)
    end
    return t
end

function M.getNumTableStr(tbl,zi)
    local str = ""
    local card_str
    local num = 3*9
    if zi then
        num = num + 7
    end

    for i=1,num do
        if tbl[i] > 0 then
            card_str = M.get_card_str(i)
        end

        if tbl[i] == 1 then
            str = str .. card_str
        elseif tbl[i] == 2 then
            str = str .. card_str .. card_str
        elseif tbl[i] == 3 then
            str = str .. card_str .. card_str .. card_str
        elseif tbl[i] == 4 then
            str = str .. card_str .. card_str .. card_str .. card_str
        end
    end

    return str
end

-- 创建一幅牌,牌里存的不是牌本身，而是牌的序号
function M.create(zi)
    local t = {}

    local num = 3*9

    if zi then
        num = num + 7
    end

    for i=1,num do
        for _=1,4 do
            table.insert(t, i)
        end
    end

    return t
end

-- 洗牌
function M.shuffle(t)
    for i=#t,2,-1 do
        local tmp = t[i]
        local index = math.random(1, i - 1)
        t[i] = t[index]
        t[index] = tmp
    end
end

-- 检查平胡
function M._check_normal(cards)
    -- 找出能做将的牌
    local eye_tbl = {}

    M._find_eye(cards, eye_tbl, 1,   9)
    M._find_eye(cards, eye_tbl, 10, 18)
    M._find_eye(cards, eye_tbl, 19, 27)

    local hu = false
    for i,_ in pairs(eye_tbl) do
        repeat
            cards[i] = cards[i] - 2
            if not M._check_color(cards, 1, 9) then
                break
            end
            if not M._check_color(cards, 10, 18) then
                break
            end
            if not M._check_color(cards, 19, 27) then
                break
            end

            hu = true
        until(true)
        if hu then
            return true
        end
        cards[i] = cards[i] + 2
    end
    return hu
end

function M._find_eye(cards, eye_tbl, from, to)
    local key = 0
    local t = {}
    for i=from,to do
        local c = cards[i]
        if c > 0 then
            key = key * 10 + c
            if c >= 2 then
                t[i] = true
            end
        end

        if c == 0 or i == to then
            if (key%3) == 2 then
                for k,_ in pairs(t) do
                    eye_tbl[k] = true
                end
            end
            if key > 0 and next(t) then
                t = {}
            end
        end
    end
end

-- 检查单一花色
function M._check_color(cards, min, max)
    local t = {}
    for i=min,max do
        --table.insert(t, cards[i])
        t[i] = cards[i]
    end
    for i=min,max do
        local n
        if t[i] == 1 or t[i] == 4 then
            n = 1
        elseif t[i] == 2 then
            n = 2
        end

        if n then
            if i + 2 > max or t[i+1] < n or t[i+2] < n then
                return false
            end

            t[i] = t[i] - n
            t[i+1] = t[i+1] - n
            t[i+2] = t[i+2] - n
        end
    end

    return true
end

-- 大四喜
function M.check_dasixi(cards)
    for _,v in ipairs(cards) do
        if v == 4 then
            return true
        end
    end
    return false
end

-- 板板胡
function M.check_banbanhu(cards)
    for i,_ in pairs(jiang) do
        if cards[i] > 0 then
            return false
        end
    end
    return true
end

-- 缺一色
function M.check_queyise(cards)
    local n1 = 0
    local n2 = 0
    local n3 = 0
    for i=1,9 do
        n1 = n1 + cards[i]
        n2 = n2 + cards[i+9]
        n3 = n3 + cards[i+18]
    end
    return n1 == 0 or n2 == 0 or n3 == 0
end

-- 六六顺
function M.check_liuliushun(cards)
    local n = 0
    for _,v in ipairs(cards) do
        if v == 3 then
            n = n + 1
        end
    end

    return n >= 2
end

-- 碰碰胡
function M.check_pengpeng(cards, waves)
    local eye = false
    for _,n in ipairs(cards) do
        if n == 1 or n == 4 then
            return false
        end

        if n == 2 then
            if eye then
                return false
            end
            eye = true
        end
    end

    -- 有吃的牌则不算
end

-- 清一色
function M.check_qingyise()
    local n1 = 0
    local n2 = 0
    local n3 = 0
    for i=1,9 do
        n1 = n1 + cards[i]
        n2 = n2 + cards[i+9]
        n3 = n3 + cards[i+18]
    end

    -- 检查底下牌的颜色
end

-- 将将胡
function M.check_jiangjianghu(cards, waves)
    for i,v in ipairs(cards) do
        if v > 0 and not jiang[i] then
            return false
        end
    end

    return true
end

-- 七小对
function M.check_7dui(cards)
    local n = 0
    local haohua = 0
    for i,v in ipairs(cards) do
        if v==1 or v==3 then
            return false, false
        end

        if v == 4 then
            haohua = haohua + 1
        end
        n = n + v
    end

    if n < 14 then
        return false
    end

    return true, haohua
end

-- 全求人
function M.check_quanqiuren()
    local n = 0
    for i,v in ipairs(cards) do
        if v > 0 and v ~= 2 then
            return false
        end
        n = n + v
    end

    return n == 2
end

-- 检查碰
-- function M.check_peng(cards, card)
--     return cards[card] >= 2
-- end

-- function M.check_angang(cards, card)
--     return cards[card] == 4
-- end

-- function M.check_diangang(cards, card)
--     return cards[card] == 3
-- end

-- function M.check_jiagang(waves, card)

-- end

function M.can_peng(hand_cards, card)
    return hand_cards[card] >= 2
end

function M.can_angang(hand_cards, card)
    return hand_cards[card] == 4
end

function M.can_diangang(hand_cards, card)
    return hand_cards[card] == 3
end

function M.can_chi(hand_cards, card1, card2)
    if not hand_cards[card1] or not hand_cards[card2] then
        return false
    end

    if hand_cards[card1] == 0 or  hand_cards[card2] == 0 then
        return false
    end

    local color1 = M.get_color(card1)
    local color2 = M.get_color(card2)

    if color1 ~= color2 then
        return false
    end

    -- 本种花色不能吃
    if not M.CardType[color1].chi then
        return false
    end

    return true
end

function M.can_left_chi(hand_cards, card)
    return M.can_chi(hand_cards, card + 1, card + 2)
end

function M.can_middle_chi(hand_cards, card)
    return M.can_chi(hand_cards, card - 1, card + 1)
end

function M.can_right_chi(hand_cards, card)
    return M.can_chi(hand_cards, card - 2, card - 1)
end

function M.check_hu(cards)
    return M._check_normal(cards)
end

function M.check_gang(hands)
    if not hands then return nil end

    local lstgang = nil
    for i=1,#hands do
        if hands[i] == 4 then
            if lstgang then lstgang = {} end
            table.insert(lstgang, i)
        end
    end
    return lstgang
end

function M.check_gang_eats(eats, card_idx)
    if not eats then return nil end
    
    local lstgang = nil
    for k,v in pairs(eats) do
        if v.type == M.EAT_PENG and v.eat == M.CardDefine[card_idx] then
            if lstgang then lstgang = {} end
            table.insert(lstgang, card_idx)
        end
    end
    return lstgang
end

return M

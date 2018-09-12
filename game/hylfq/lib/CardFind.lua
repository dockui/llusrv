local CardStatistics = require("CardStatistics")
local CardAnalysis = require("CardAnalysis")
local Card = require("Card")

CardTypeNew = {
    CARD_TYPE_ERROR = 0,            -- error type
    CARD_TYPE_ONE = 1,              -- single
    CARD_TYPE_ONELINE = 2,          -- straight 顺子
    CARD_TYPE_TWO = 3,              -- double   对子
    CARD_TYPE_TWOLINE = 4,          -- double straight 连对
    CARD_TYPE_THREE = 5,            -- triple 三张
    CARD_TYPE_THREELINE = 6,        -- 三顺：点数相连的2个及以上的牌，可以从3连到A。
    CARD_TYPE_THREEWITHONE = 7,     -- 最后一手没多余牌的情况下可以出三带一   
    CARD_TYPE_THREEWITHTWO = 8,     -- 3同张必须带2张其他牌，带的牌不要求同点数
    CARD_TYPE_PLANEWITHONE = 9,     -- 飞机带羿，多个三带一,牌不够时出
    CARD_TYPE_PLANEWITHWING = 10,   -- 飞机带翅，多个三带二
    CARD_TYPE_PLANWHITHLACK=11,     -- 最后一手牌不够时允许三带一张或不带
    CARD_TYPE_FOURWITHONE = 12,     -- 4个带一（牌不够时可以少带，带1-2张）
    CARD_TYPE_FOURWITHTWO = 13,     -- 4个带二（牌不够时可以少带，带1-2张）
    CARD_TYPE_FOURWITHTHREE=14,     -- 4张牌也可以带3张其他牌，这时不算炸弹
    CARD_TYPE_BOMB = 15,            -- 4个炸弹
}

local CardFind = class("CardFind")
    CardFind.results = {}
    CardFind.light_cards_c = {}
    CardFind.light_cards_i = {}

    function CardFind:clear()
        self.results = {}
        self.light_cards_c = {}
        self.light_cards_i = {}
    end

    function CardFind:ctor(obj)
        self:clear()
    end

    function CardFind:get_results_size()
        return #self.results
    end
    

    function CardFind:results_clear()
        self.results = {}
    end

    function CardFind:results_add(cardi)
        local cards = {}
        for i,v in ipairs(cardi) do
            table.insert(cards, Card.new(v))
        end
        table.insert(self.results, cards)
    end

    function CardFind:results_get(id)
        if id > 0 and id <= #self.results then
            return self.results[id]
        end
    end

    function CardFind:__find_one_line(card_stat1, card_ana0)
        for i=0, #card_stat1.line1-1 do
            if card_stat1.line1[i+1].face ~= 15 then --2 不成顺子
                local flag, len = card_ana0:__find_arr_is_line_len(card_stat1.line1, 1, i, #card_stat1.line1)
                if flag then
                    local cards = {}
                    local j = i
                    for k=1, len do
                        table.insert(cards, card_stat1.line1[j+1])
                        j = j + 1
                    end
                    table.insert(self.results, cards)
                    return
                end
            end
        end
    end    

    function CardFind:__find_two_line(card_stat1, card_ana0)
        for i=0, #card_stat1.line2-1 do
            if card_stat1.line2[i+1].face ~= 15 then --2 不成对
                local flag, len = card_ana0:__find_arr_is_line_len(card_stat1.line2, 2, i, #card_stat1.line2)
                if flag then
                    local cards = {}
                    local j = i
                    for k=1, len*2 do
                        table.insert(cards, card_stat1.line2[j+1])
                        j = j + 1
                    end
                    table.insert(self.results, cards)
                    return
                end
            end
        end
    end

    function CardFind:__find_three_with_two(card_stat1, card_ana0)
        if card_stat1.len >= 5 then
            for i,v in ipairs(card_stat1.card3) do
                if (i-1)%3 == 0 then
                    local cards = {}
                    table.insert(cards, card_stat1.card3[i])
                    table.insert(cards, card_stat1.card3[i+1])
                    table.insert(cards, card_stat1.card3[i+2])
                    if #card_stat1.card1 > 1 then
                        table.insert(cards, card_stat1.card1[1])
                        table.insert(cards, card_stat1.card1[2])
                    elseif #card_stat1.card2 > 0 then
                        table.insert(cards, card_stat1.card2[1])
                        table.insert(cards, card_stat1.card2[2])
                    else
                        for i,v in ipairs(card_stat1.line2) do
                            if v.face ~= cards[1].face then
                                table.insert(cards, card_stat1.line2[i])
                                table.insert(cards, card_stat1.line2[i+1])
                                break
                            end
                        end
                    end
                    table.insert(self.results, cards)
                end
            end
        end
    end

    function CardFind:__find_plane_with_wing(card_stat1, card_ana0)
        for i=0, #card_stat1.line3-1 do
            if i%3 == 0 then
                local __end = #card_stat1.line3
                local flag, len = card_ana0:__find_arr_is_line_len(card_stat1.line3, 3, i, __end)
                if  flag == true then
                    local with_wing_len = len*3 + len*2
                    local cards = {}
                    local j = i
                    for k=1, len*3 do
                        table.insert(cards, card_stat1.line3[j+1])
                        j = j + 1
                    end
                    --到单牌里找要的翅膀
                    for i,v in ipairs(card_stat1.card1) do 
                        if #cards >= with_wing_len then
                            break
                        end
                        table.insert(cards, v)  
                    end
                    --在对子了里找要的翅膀
                    for i,v in ipairs(card_stat1.card2) do 
                        if (i-1)%2==0 then
                            if #cards >= with_wing_len then
                                break
                            end
                            table.insert(cards, card_stat1.card2[i])
                            if #cards >= with_wing_len then
                                break
                            end
                            table.insert(cards, card_stat1.card2[i+1])   
                        end
                    end
                    if #cards >= with_wing_len then
                        table.insert(self.results, cards)
                    else
                        local flag = 0
                        for i,v in ipairs(card_stat1.line2) do
                            if (i-1)%2==0 then
                                flag = 0
                                for k,m in ipairs(cards) do
                                    if v.face == m.face then
                                        flag = 1
                                        break
                                    end
                                end
                                if flag == 1 then
                                else
                                    if #cards >= with_wing_len then
                                        break
                                    end
                                    table.insert(cards, card_stat1.line2[i])
                                    if #cards >= with_wing_len then
                                        break
                                    end                                    
                                    table.insert(cards, card_stat1.line2[i+1])
                                end
                            end
                        end

                        if #cards >= with_wing_len then
                            table.insert(self.results, cards)
                        else
                            if #cards >= card_ana0.len then --能一手出完
                                table.insert(self.results, cards)
                            end
                            
                        end                   
                    end
                end
            end
        end
    end

    --电脑IA先手出牌，尽可能的多出牌
    function CardFind:tipAI(cur)  
        if #cur == 0 then
            return -1
        end
        self:clear()
        local card_stat1 = CardStatistics.new()
        card_stat1:statistics(cur)
        local card_ana0 = CardAnalysis.new()
        card_ana0:analysis(card_stat1,self.fourdaithree)
        
        self:__find_plane_with_wing(card_stat1, card_ana0)
        self:__find_one_line(card_stat1, card_ana0)
        self:__find_three_with_two(card_stat1, card_ana0)
        self:__find_two_line(card_stat1, card_ana0)
        for i,v in ipairs(card_stat1.card2) do
            if (i-1)%2==0 then
                local cards = {}
                table.insert(cards, card_stat1.card2[i])
                table.insert(cards, card_stat1.card2[i+1])
                table.insert(self.results, cards)
            end  
        end 
        for i,v in ipairs(card_stat1.card1) do
            local cards = {}
            table.insert(cards, v)
            table.insert(self.results, cards)
        end
        function sortByLen( a, b )
            return #a > #b
        end
    end

    -- 分析牌, A->13 2->14
    function CardFind:analyzeCards(cards)
        local cards2 = {}
        for i,v in ipairs(cards) do
            local face = math.mod(v, 16)
            if face < 3 then
                face = face + 13
            end
            local suit = math.floor((v - face) / 16)
            table.insert(cards2, {face = face, suit = suit, value = v})
        end
        -- 将牌值排序
        table.sort(cards2, function(a, b)
                if a.face == b.face then
                    return a.suit > b.suit
                end
                return a.face < b.face
            end)
        return cards2
    end

    --查找顺子
    function CardFind:pro_oneline(cur)
        local list = {}
        if #cur == 0 then
            return list
        end

        local cards = self:analyzeCards(cur)

        -- -- 检测是否存在炸弹，并且将炸弹放到表中
        -- local face
        -- local n
        -- local delCards = {}
        -- for i, v in ipairs(cards) do
        --     repeat
        --         if face and face == v.face then
        --             n = n + 1
        --             if n == 4 then-- 表示遇到炸弹
        --                 delCards["" .. face] = 1
        --             end
        --             break
        --         end
        --         face = v.face
        --         n = 1
        --     until true
        -- end
        -- -- 将炸弹干掉
        -- for i = #cards, 1, -1 do
        --     if delCards["" .. cards[i].face] == 1 then
        --         table.remove(cards, i)
        --     end
        -- end

        -- 找顺子
        -- 将2干掉
        local list
        local nextCard
        local lists = {}
        for i,v in ipairs(cards) do
            repeat
                -- 2的话，不能连顺
                if nextCard and v.face ~= 15 then
                    -- 牌值间距为1，就表示连续
                    local off = v.face - nextCard 
                    if off == 1 or off == 0 then
                        -- 因为牌已经从小到大排序 
                        -- 如果0表示一样的，只取一个
                        if off == 1 then
                            table.insert(list, v.value)
                        end
                        nextCard = v.face
                        break
                    end
                end
                nextCard = v.face
                if list and #list > 4 then
                    table.insert(lists, list)
                end
                list = {v.value}
            until true 
        end
        if list and #list > 4 then
            table.insert(lists, list)
        end
        table.sort(lists, function(a, b)
            return #a > #b
        end)
        -- 长度超过4才认为是顺子
        return lists[1] and lists[1] or {} 
    end

    --[[
        传入一手牌，将ex指定的牌排除
    ]]
    function CardFind:exclude(all, ex)
        for i=#all,1,-1 do
            local v = all[i].value
            for i,v2 in ipairs(ex) do
                if v == v2.value then
                    table.remove(all, i)
                    break
                end
            end
        end
    end

    function CardFind:analyzeCards2(cur)
        if #cur == 0 then
            return
        end
        local cards = self:analyzeCards(cur)

        -- 将牌分组拆好,将牌值一样的放一起
        local t = {}


        for i,v in ipairs(cards) do
            local key = "" .. v.face
            if not t[key] then
                t[key] = {clone(v)}
            else
                table.insert(t[key], clone(v))
            end
        end

        -- 统计个数

        local total = {
            danpai = {},
            duizi = {},
            sange = {},
            zhadan = {}
        }

        for i=3,15 do
            repeat
                local v = t["" .. i]
                if not v then
                    break
                end
                local n = #v
                if n == 4 then
                    table.insert(total.zhadan, clone(v))
                elseif n == 3 then
                    table.insert(total.sange, clone(v))
                elseif n == 2 then
                    table.insert(total.duizi, clone(v))
                elseif n == 1 then
                    table.insert(total.danpai, clone(v))
                end
            until true
        end
        return t, total, cards
    end

    --玩家提示出牌， 弱弱地提示一下
    function CardFind:tipMe(cur)
        local t, total, cards = self:analyzeCards2(cur)
        if t == nil or total == nil or cards == nil then
            return
        end
        local length = #cards
        self.results = {}
        -- 首先将单牌都拆出来。。加入
        for i,v in ipairs(cards) do
            table.insert(self.results, {clone(v)})
        end

        -- 再考虑对子
        for i,v in ipairs(total.duizi) do
            table.insert(self.results, {clone(v[1]), clone(v[2])})
        end

        -- 再考虑顺子
        -- 从头往后遍历，如果连续的超过4，就表示顺子
        local tt
        for i=3,14 do
            repeat
                local v = t["" .. i]
                
                if v == nil then
                    break
                end

                if not tt then
                    if #v < 4 then
                        tt = {clone(v[1])}
                    end
                else
                    if #v < 4 and v[1].face < 15 and v[1].face - tt[#tt].face == 1 then
                        table.insert(tt, clone(v[1]))
                    else
                        if #tt > 4 then
                            table.insert(self.results, tt)
                        end
                        -- 避免拆炸弹
                        if #v < 4 then
                            tt = {clone(v[1])}
                        else
                            tt = nil
                        end
                    end
                end
            until true
        end
        if tt and #tt > 4 then
            table.insert(self.results, tt)
        end

        -- 再考虑连对
        local tt
        for i=3,14 do
            repeat
                local v = t["" .. i]
                
                if v == nil then
                    break
                end

                if not tt then
                    if #v > 1 and #v < 4 then
                        tt = clone({v[1], v[2]})
                    end
                else
                    if #v > 1 and #v < 4 and v[1].face < 15 and v[1].face - tt[#tt].face == 1 then
                        table.insert(tt, clone(v[1]))
                        table.insert(tt, clone(v[2]))
                    else
                        if #tt > 2 then
                            table.insert(self.results, tt)
                        end
                        if #v > 1 and #v < 4 then
                            tt = clone({v[1], v[2]})
                        else
                            tt = nil
                        end
                    end
                end
            until true
        end
        if tt and #tt > 2 then
            table.insert(self.results, tt)
        end

        -- 考虑三带2 或 三带1 或 三带0
        for i,v in ipairs(total.sange) do
            local tt = {}
            repeat
                for i,v2 in ipairs(v) do
                    table.insert(tt, clone(v2))
                end
                -- 只有3张牌的话，就终止寻找
                local nc = math.min(length, 5) - 3
                if nc < 0 then
                    break
                end
                -- 所有牌都能带出去
                local danpaiIdx = 0
                local duiziIdx = 0
                while danpaiIdx < #total.danpai and nc > 0 do
                    table.insert(tt, clone(total.danpai[danpaiIdx + 1][1]))
                    danpaiIdx = danpaiIdx + 1
                    nc = nc - 1
                end
                while duiziIdx < #total.duizi * 2 and nc > 0 do
                    local idx1 = math.floor(duiziIdx / 2)
                    local idx2 = math.mod(duiziIdx, 2)

                    table.insert(tt, clone(total.duizi[idx1 + 1][idx2 + 1]))
                    duiziIdx = duiziIdx + 1
                    nc = nc - 1
                end
            until true
            table.insert(self.results, tt)
        end

        -- 考虑飞机
        tt = nil
        for i,v in ipairs(total.sange) do
            if not tt then
                tt = clone({clone(v[1]), clone(v[2]), clone(v[3])})
            else
                -- 都是三个，才能往里面插入
                if v[1].face - tt[#tt].face == 1 and v[1].face < 15 then
                    table.insert(tt, clone(v[1]))
                    table.insert(tt, clone(v[2]))
                    table.insert(tt, clone(v[3]))
                else
                    local nn = math.floor(#tt / 3)
                    if nn > 1 then-- 有两三连就ok了
                        local nc = math.min(length, nn * 5) - nn * 3
                        -- 需要带的牌数
                        repeat
                            if nc < 0 then
                                break
                            end
                            -- 所有牌都能带出去
                            local danpaiIdx = 0
                            local duiziIdx = 0
                            local sangeIdx = 0
                            while danpaiIdx < #total.danpai and nc > 0 do
                                table.insert(tt, clone(total.danpai[danpaiIdx + 1][1]))
                                danpaiIdx = danpaiIdx + 1
                                nc = nc - 1
                            end
                            while duiziIdx < #total.duizi * 2 and nc > 0 do
                                local idx1 = math.floor(duiziIdx / 2)
                                local idx2 = math.mod(duiziIdx, 2)

                                table.insert(tt, clone(total.duizi[idx1 + 1][idx2 + 1]))
                                duiziIdx = duiziIdx + 1
                                nc = nc - 1
                            end
                            
                            dump(nc,"nc")
                            dump(sangeIdx, "sangeIdx")
                            while sangeIdx < #total.sange * 3 and nc > 0 do
                                repeat
                                    local idx1 = math.floor(sangeIdx / 3)
                                    local idx2 = math.mod(sangeIdx, 3)

                                    local find = false
                                    local card33 = total.sange[idx1 + 1][idx2 + 1]
                                    for _,v8 in ipairs(tt) do
                                        if v8.face == card33.face then
                                            find = true
                                            break
                                        end
                                    end
                                    if find then
                                        -- 直接无视这3个 找下个。。
                                        sangeIdx = sangeIdx + 3
                                        break
                                    end
                                    table.insert(tt, clone(card33))
                                    sangeIdx = sangeIdx + 1
                                    nc = nc - 1
                                until true
                            end
                        until true
                        table.insert(self.results, tt)
                    end
                    tt = clone({clone(v[1]), clone(v[2]), clone(v[3])})
                end
            end
        end
        if tt then
            local nn = math.floor(#tt / 3)
            if nn > 1 then-- 有两三连就ok了
                local nc = math.min(length, nn * 5) - nn * 3
                -- 需要带的牌数
                repeat
                    if nc < 0 then
                        break
                    end
                    -- 所有牌都能带出去
                    local danpaiIdx = 0
                    local duiziIdx = 0
                    local sangeIdx = 0
                    while danpaiIdx < #total.danpai and nc > 0 do
                        table.insert(tt, clone(total.danpai[danpaiIdx + 1][1]))
                        danpaiIdx = danpaiIdx + 1
                        nc = nc - 1
                    end
                    while duiziIdx < #total.duizi * 2 and nc > 0 do
                        local idx1 = math.floor(duiziIdx / 2)
                        local idx2 = math.mod(duiziIdx, 2)

                        table.insert(tt, clone(total.duizi[idx1 + 1][idx2 + 1]))
                        duiziIdx = duiziIdx + 1
                        nc = nc - 1
                    end

                    dump(nc,"nc")
                    dump(sangeIdx, "sangeIdx")
                    while sangeIdx < #total.sange * 3 and nc > 0 do
                        repeat
                            local idx1 = math.floor(sangeIdx / 3)
                            local idx2 = math.mod(sangeIdx, 3)

                            local find = false
                            local card33 = total.sange[idx1 + 1][idx2 + 1]
                            for _,v8 in ipairs(tt) do
                                if v8.face == card33.face then
                                    find = true
                                    break
                                end
                            end
                            if find then
                                -- 直接无视这3个 找下个。。
                                sangeIdx = sangeIdx + 3
                                break
                            end
                            table.insert(tt, clone(card33))
                            sangeIdx = sangeIdx + 1
                            nc = nc - 1
                        until true
                    end
                until true
                table.insert(self.results, tt)
            end
        end

        -- 考虑炸弹
        for i,v in ipairs(total.zhadan) do
            table.insert(self.results, clone(v))
        end
    end

    function CardFind:tip(last, cur)
        if #last == 0 then
            return -1
        end

        if #cur == 0 then
            return -2
        end
        
        local card_stat0 = CardStatistics.new()
        card_stat0:statistics(last)
        local card_ana0 = CardAnalysis.new()
        card_ana0:analysis(card_stat0,self.fourdaithree)

        if card_ana0.type == 0 then
            return -1
        end

        local card_stat1 = CardStatistics.new()
        card_stat1:statistics(cur)

        self:find(card_ana0, card_stat0, card_stat1)
    end

    function CardFind:find(card_ana, card_stat, target_card_stat)
        self:clear()
        if (card_ana.type ~= CardTypeNew.CARD_TYPE_ERROR) then   
            if (card_ana.type == CardTypeNew.CARD_TYPE_ONE) then
                self:find_one(card_ana, card_stat, target_card_stat)
                self:find_two(card_ana, card_stat, target_card_stat)
                self:find_three(card_ana, card_stat, target_card_stat)
            elseif (card_ana.type == CardTypeNew.CARD_TYPE_TWO)  then
                self:find_two(card_ana, card_stat, target_card_stat)
                self:find_three(card_ana, card_stat, target_card_stat)
            elseif (card_ana.type == CardTypeNew.CARD_TYPE_THREE) then
                self:find_three(card_ana, card_stat, target_card_stat)
            elseif (card_ana.type == CardTypeNew.CARD_TYPE_ONELINE) then
                self:find_one_line(card_ana, card_stat, target_card_stat)
            elseif (card_ana.type == CardTypeNew.CARD_TYPE_TWOLINE) then
                self:find_two_line(card_ana, card_stat, target_card_stat)
            elseif (card_ana.type == CardTypeNew.CARD_TYPE_THREEWITHONE) then
                self:find_three_with_one(card_ana, card_stat, target_card_stat)
            elseif (card_ana.type == CardTypeNew.CARD_TYPE_THREEWITHTWO)then
                self:find_three_with_two(card_ana, card_stat, target_card_stat)
            elseif (card_ana.type == CardTypeNew.CARD_TYPE_PLANEWITHONE)then
                self:find_plane_with_one(card_ana, card_stat, target_card_stat)
            elseif (card_ana.type == CardTypeNew.CARD_TYPE_PLANEWITHWING)then
                self:find_plane_with_wing(card_ana, card_stat, target_card_stat)
            elseif (card_ana.type == CardTypeNew.CARD_TYPE_FOURWITHONE) then
                self:find_four_with_one(card_ana, card_stat, target_card_stat)
            elseif (card_ana.type == CardTypeNew.CARD_TYPE_FOURWITHTWO)then
                self:find_four_with_two(card_ana, card_stat, target_card_stat)
            elseif (card_ana.type == CardTypeNew.CARD_TYPE_FOURWITHTHREE)then
                self:find_four_with_three(card_ana, card_stat, target_card_stat)
            end
            self:find_bomb(card_ana, card_stat, target_card_stat)
        end
    end

    function CardFind:find_one(card_ana, card_stat, my_card_stat)
        if (card_ana.type == CardTypeNew.CARD_TYPE_ONE)then
            for i,v in ipairs(my_card_stat.card1) do
                if v.face > card_ana.face then
                    local cards = {}
                    table.insert(cards, v)
                    table.insert(self.light_cards_c, v)
                    table.insert(self.results, cards)
                end
            end
        end
    end

    function CardFind:find_two(card_ana, card_stat, my_card_stat)
        if (card_ana.type == CardTypeNew.CARD_TYPE_ONE) then
            for i,v in ipairs(my_card_stat.card2) do
                if (i-1)%2==0 then
                    if v.face > card_ana.face then
                        local cards = {}
                        table.insert(cards, v)
                        table.insert(self.light_cards_c, my_card_stat.card2[i])
                        table.insert(self.light_cards_c, my_card_stat.card2[i+1])
                        table.insert(self.results, cards)
                    end
                end  
            end
        elseif (card_ana.type == CardTypeNew.CARD_TYPE_TWO) then
            for i,v in ipairs(my_card_stat.card2) do
                if (i-1)%2==0 then
                    if v.face > card_ana.face then
                        local cards = {}
                        table.insert(cards, my_card_stat.card2[i])
                        table.insert(cards, my_card_stat.card2[i+1])

                        table.insert(self.light_cards_c, my_card_stat.card2[i])
                        table.insert(self.light_cards_c, my_card_stat.card2[i+1])
                        table.insert(self.results, cards)
                    end
                end  
            end
        end
    end

    function CardFind:find_three(card_ana, card_stat, my_card_stat)
        if (card_ana.type == CardTypeNew.CARD_TYPE_ONE)then

            for i,v in ipairs(my_card_stat.card3) do
                if (i-1)%3==0 then
                    if v.face > card_ana.face then
                        local cards = {}
                        table.insert(cards, my_card_stat.card3[i])
                        table.insert(self.light_cards_c, my_card_stat.card3[i])
                        table.insert(self.light_cards_c, my_card_stat.card3[i+1])
                        table.insert(self.light_cards_c, my_card_stat.card3[i+2])
                        table.insert(self.results, cards)
                    end
                end  
            end
        elseif (card_ana.type == CardTypeNew.CARD_TYPE_TWO) then
            for i,v in ipairs(my_card_stat.card3) do
                if (i-1)%3==0 then
                    if v.face > card_ana.face then
                        local cards = {}
                        table.insert(cards, my_card_stat.card3[i])
                        table.insert(cards, my_card_stat.card3[i+1])

                        table.insert(self.light_cards_c, my_card_stat.card3[i])
                        table.insert(self.light_cards_c, my_card_stat.card3[i+1])
                        table.insert(self.light_cards_c, my_card_stat.card3[i+2])
                        table.insert(self.results, cards)
                    end
                end  
            end
        elseif (card_ana.type == CardTypeNew.CARD_TYPE_THREE)then
            for i,v in ipairs(my_card_stat.card3) do
                if (i-1)%3==0 then
                    if v.face > card_ana.face then
                        local cards = {}
                        table.insert(cards, my_card_stat.card3[i])
                        table.insert(cards, my_card_stat.card3[i+1])
                        table.insert(cards, my_card_stat.card3[i+2])
                        table.insert(self.light_cards_c, my_card_stat.card3[i])
                        table.insert(self.light_cards_c, my_card_stat.card3[i+1])
                        table.insert(self.light_cards_c, my_card_stat.card3[i+2])
                        table.insert(self.results, cards)
                    end
                end  
            end
        end
    end

    function CardFind:find_one_line(card_ana, card_stat, my_card_stat)
        local count = #my_card_stat.line1 - #card_stat.line1
        for i=0, count do
            if (my_card_stat.line1[i+1].face > card_ana.face) then
                if (my_card_stat.line1[i+1].face~=15) then           
                    local __end = i + card_ana.len
                    if (card_ana:__check_arr_is_line(my_card_stat.line1, 1, i, __end)) then
                        local cards = {}
                        for j=i, __end-1 do 
                            table.insert(cards, my_card_stat.line1[j+1])
                            table.insert(self.light_cards_c, my_card_stat.line1[j+1])

                            for i,v in ipairs(my_card_stat.card2) do
                                if (i-1)%2 == 0 then
                                    if v.face ==  my_card_stat.line1[j+1].face then
                                        table.insert(self.light_cards_c, my_card_stat.card2[i])
                                        table.insert(self.light_cards_c, my_card_stat.card2[i+1])
                                    end
                                end
                            end
                            for i,v in ipairs(my_card_stat.card3) do
                                if (i-1)%3 == 0 then
                                    if v.face ==  my_card_stat.line1[j+1].face then
                                        table.insert(self.light_cards_c, my_card_stat.card3[i])
                                        table.insert(self.light_cards_c, my_card_stat.card3[i+1])
                                        table.insert(self.light_cards_c, my_card_stat.card3[i+2])
                                    end
                                end
                            end
                        end
                        table.insert(self.results, cards)
                    end   
                end
            end
        end
    end

    function CardFind:find_two_line(card_ana, card_stat, my_card_stat) 
        local count = #my_card_stat.line2 - #card_stat.line2
        for i=0, count do
            if i%2 == 0 then
                if (my_card_stat.line2[i+1].face > card_ana.face) then
                    local __end = i + card_ana.len
                    if (card_ana:__check_arr_is_line(my_card_stat.line2, 2, i, __end)) then
                        local cards = {}
                        for j=i, __end-1 do
                            table.insert(cards, my_card_stat.line2[j+1])
                            table.insert(self.light_cards_c, my_card_stat.line2[j+1])
                            for i,v in ipairs(my_card_stat.card3) do
                                if (i-1)%3 == 0 then
                                    if v.face ==  my_card_stat.line2[j+1].face then
                                        table.insert(self.light_cards_c, my_card_stat.card3[i])
                                        table.insert(self.light_cards_c, my_card_stat.card3[i+1])
                                        table.insert(self.light_cards_c, my_card_stat.card3[i+2])
                                    end
                                end
                            end
                        end
                        table.insert(self.results, cards)
                    end   
                end
            end
        end
    end

    function CardFind:find_three_line(card_ana, card_stat, my_card_stat) 
        local count = #my_card_stat.line3 - #card_stat.line3
        for i=0, count do
            if i%3==0 then
                if (my_card_stat.line3[i+1].face > card_ana.face) then
                    local __end = i + card_ana.len
                    if (card_ana:__check_arr_is_line(my_card_stat.line3, 3, i, __end)) then
                        local cards = {}
                        for j=i, __end-1 do
                            table.insert(cards, my_card_stat.line3[j+1])
                            table.insert(self.light_cards_c, my_card_stat.line3[j+1])
                        end
                        table.insert(self.results, cards)
                    end   
                end
            end
        end
    end

    function CardFind:find_three_with_one(card_ana, card_stat, my_card_stat) 
        if (my_card_stat.len < 4) then
            return
        end
        for i,v in ipairs(my_card_stat.card3) do
            if (i-1)%3 == 0 then
                if my_card_stat.card3[i].face > card_ana.face then
                    local cards = {}
                    table.insert(cards, my_card_stat.card3[i])
                    table.insert(cards, my_card_stat.card3[i+1])
                    table.insert(cards, my_card_stat.card3[i+2])
                    if (#my_card_stat.card1 > 0) then
                        table.insert(cards, my_card_stat.card1[1])
                    else
                        for i,v in ipairs(my_card_stat.line1) do
                            if (v.face ~= cards[1].face) then
                                table.insert(cards, v)
                                break
                            end
                        end
                    end
                    table.insert(self.results, cards)
                end
            end
        end
        if (#self.results > 0) then
            for i,v in ipairs(my_card_stat.card1) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card2) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card3) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card4) do
                table.insert(self.light_cards_c, v)
            end      
        end
    end

    function CardFind:find_three_with_two(card_ana, card_stat, my_card_stat) 

        if (my_card_stat.len < 5) then
            dump("...................................1")
            return
        end
        
        for i,v in ipairs(my_card_stat.card3) do
            if (i-1)%3 == 0 then
                if my_card_stat.card3[i].face > card_ana.face then
                    local cards = {}
                    table.insert(cards, my_card_stat.card3[i])
                    table.insert(cards, my_card_stat.card3[i+1])
                    table.insert(cards, my_card_stat.card3[i+2])
                    if #my_card_stat.card1 > 1 then
                        table.insert(cards, my_card_stat.card1[1])
                        table.insert(cards, my_card_stat.card1[2])
                    elseif #my_card_stat.card2 > 0 then
                        table.insert(cards, my_card_stat.card2[1])
                        table.insert(cards, my_card_stat.card2[2])
                    else
                        for i,v in ipairs(my_card_stat.line2) do
                            if v.face ~= cards[1].face then
                                table.insert(cards, my_card_stat.line2[i])
                                table.insert(cards, my_card_stat.line2[i+1])
                                break
                            end
                        end
                    end
                    table.insert(self.results, cards)
                end
            end
        end

        
        if (#self.results > 0) then
            for i,v in ipairs(my_card_stat.card1) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card2) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card3) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card4) do
                table.insert(self.light_cards_c, v)
            end      
        end
    end

    function CardFind:find_plane_with_one(card_ana, card_stat, my_card_stat) 
        local count = #my_card_stat.line3 - #card_stat.line3
        for i=0, count do
            if i%3 == 0 then
                if (my_card_stat.line3[i+1].face > card_ana.face) then
                    local __end = i + #card_stat.card3
                    if card_ana:__check_arr_is_line(my_card_stat.line3, 3, i, __end) then
                        local cards = {}
                        for j=i, __end-1 do
                            table.insert(cards, my_card_stat.line3[j+1])
                            table.insert(self.light_cards_c, my_card_stat.line3[j+1])
                        end
                        if #cards == card_ana.len then --飞机✈️不带的牌的情况
                            table.insert(self.results, cards)
                        else
                            local flag = 0
                            for i,v in ipairs(my_card_stat.line1) do
                                flag = 0
                                for k,m in ipairs(cards) do
                                    if v.face == m.face then
                                        flag = 1
                                        break
                                    end
                                end
                                if flag == 1 then 
                                else
                                    table.insert(cards, v)
                                    if #cards == card_ana.len then
                                        break
                                    end
                                end
                            end

                            if #cards == card_ana.len then
                                table.insert(self.results, cards)
                            end
                        end
                        
                    end
                end
            end
        end
        if (#self.results > 0) then
            for i,v in ipairs(my_card_stat.card1) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card2) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card3) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card4) do
                table.insert(self.light_cards_c, v)
            end      
        end
    end

  function CardFind:find_lin3(cards, my_card_stat_line3, needCards)
        for i=0,#my_card_stat_line3-1 do
            if (i%3==0) then
                while true do
                    local flag = 0
                    for k=0,#cards-1 do
                        if cards[k+1].face == my_card_stat_line3[i+1].face then
                            flag = 1
                            break
                        end
                    end
                    if flag == 1 then
                        break
                    end
                    table.insert(cards, my_card_stat_line3[i+1])
                    needCards = needCards - 1
                    if needCards<=0 then
                        return
                    end
                    table.insert(cards, my_card_stat_line3[i+1+1])
                    needCards = needCards - 1
                    if needCards<=0 then
                        return
                    end
                    table.insert(cards, my_card_stat_line3[i+1+2])
                    needCards = needCards - 1
                    if needCards<=0 then
                        return
                    end
                    break
                end
            end
        end
    end

    function CardFind:find_card4(cards, my_card_stat_card4, needCards)
        for i,v in ipairs(my_card_stat_card4) do
            while true do
                local flag = 0
                for j,k in ipairs(cards) do
                    if k.value == v.value then
                        flag = 1
                        break
                    end
                end
                if flag == 1 then
                    break
                end
                table.insert(cards, v)
                needCards = needCards - 1
                if needCards<=0 then
                    return
                end 
                break
            end
        end
    end

    function CardFind:find_plane_with_wing(card_ana, card_stat, my_card_stat) 
        printInfo("----find_plane_with_wing---")
        local count = #my_card_stat.line3 - #card_stat.line3
        for i=0, count do
            if i%3 == 0 then
                while true do
                    if (my_card_stat.line3[i+1].face > card_ana.face) then
                        local __end = i + #card_stat.card3
                        if __end > #my_card_stat.line3 then
                            break
                        end
                        if card_ana:__check_arr_is_line(my_card_stat.line3, 3, i, __end) then
                            local cards = {}
                            for j=i, __end-1 do
                                table.insert(cards, my_card_stat.line3[j+1])
                            end
                            local numCard1 = #my_card_stat.card1
                            for i=0,numCard1-1-1 do
                                if i%2==0 then
                                    table.insert(cards, my_card_stat.card1[i+1])
                                    table.insert(cards, my_card_stat.card1[i+1+1])
                                    if #cards == card_ana.len then
                                        break
                                    end
                                end
                            end
                            if #cards == card_ana.len then
                                table.insert(self.results, cards)
                                break
                            end    

                            for i=0, #my_card_stat.card2-1 do
                                if i%2==0 then
                                    table.insert(cards, my_card_stat.card2[i+1])
                                    table.insert(cards, my_card_stat.card2[i+1+1])
                                    if #cards == card_ana.len then
                                        break
                                    end
                                end
                            end
                            if #cards == card_ana.len then
                                table.insert(self.results, cards)
                                break
                            end 

                            local needCards = card_ana.len - #cards
                            local bomb = #my_card_stat.card4
                            if bomb > count then
                                bomb = bomb - count
                            end
                            if (numCard1 % 2 + count + bomb) >= needCards then
                                if numCard1 % 2 == 1 then
                                    table.insert(cards, my_card_stat.card1[#my_card_stat.card1])
                                    needCards = needCards-1
                                    if #cards == card_ana.len then
                                        table.insert(self.results, cards)
                                        break
                                    end
                                end
          
                                self:find_lin3(cards, my_card_stat.line3, needCards)
                                
                                if #cards == card_ana.len then
                                    table.insert(self.results, cards)
                                    break
                                end
                            end
                            if (numCard1 % 2 + #my_card_stat.card4) >= needCards then
                                if numCard1 % 2 == 1 then
                                    table.insert(cards, my_card_stat.card1[#my_card_stat.card1])
                                    needCards = needCards - 1
                                    if #cards == card_ana.len then
                                        table.insert(self.results, cards)
                                        break
                                    end
                                end
                                
                                self:find_card4(cards, my_card_stat.card4, needCards)
                                if #cards == card_ana.len then
                                    table.insert(self.results, cards)
                                    break
                                end
                            end
                        end
                    end
                    break
                end
            end
        end
        if (#self.results > 0) then
            for i,v in ipairs(my_card_stat.card1) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card2) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card3) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card4) do
                table.insert(self.light_cards_c, v)
            end      
        end
    end

    function CardFind:find_four_with_one(card_ana, card_stat, my_card_stat) 
        if (my_card_stat.len < 6) then
            return
        end
        for i,v in ipairs(my_card_stat.card4) do
            if (i-1)%4==0 then
                if v.face > card_ana.face then
                    local cards = {}
                    table.insert(cards, my_card_stat.card4[i])
                    table.insert(cards, my_card_stat.card4[i+1])
                    table.insert(cards, my_card_stat.card4[i+2])
                    table.insert(cards, my_card_stat.card4[i+3])

                    for i,v in ipairs(my_card_stat.card1) do
                        table.insert(cards, v)
                        if #cards == card_ana.len then
                            break
                        end
                    end
                    if #cards == card_ana.len then
                        table.insert(self.results, cards)
                    else
                        local flag = 0
                        for i,v in ipairs(my_card_stat.line1) do
                            flag = 0
                            for k,m in ipairs(cards) do
                                if v.face == m.face then
                                    flag = 1
                                    break
                                end
                            end
                            if flag == 1 then
                            else
                                table.insert(cards, v)
                                if #cards == card_ana.len then
                                    break
                                end
                            end
                        end

                        if #cards == card_ana.len then
                            table.insert(self.results, cards)
                        end
                    end
                end
            end
        end
        if (#self.results > 0) then
            for i,v in ipairs(my_card_stat.card1) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card2) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card3) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card4) do
                table.insert(self.light_cards_c, v)
            end      
        end
    end

    function CardFind:find_four_with_two(card_ana, card_stat, my_card_stat) 
        if (my_card_stat.len < 8) then
            return
        end
        for i,v in ipairs(my_card_stat.card4) do
            if (i-1)%4==0 then
                if v.face > card_ana.face then
                    local cards = {}
                    table.insert(cards, my_card_stat.card4[i])
                    table.insert(cards, my_card_stat.card4[i+1])
                    table.insert(cards, my_card_stat.card4[i+2])
                    table.insert(cards, my_card_stat.card4[i+3])

                    for i,v in ipairs(my_card_stat.card2) do
                        if (i-1)%2==0 then
                            table.insert(cards, my_card_stat.card2[i])
                            table.insert(cards, my_card_stat.card2[i+1])
                            if #cards == card_ana.len then
                                break
                            end
                        end
                        
                    end
                    if #cards == card_ana.len then
                        table.insert(self.results, cards)
                    else
                        local flag = 0
                        for i,v in ipairs(my_card_stat.line2) do
                            if (i-1)%2==0 then
                                flag = 0
                                for k,m in ipairs(cards) do
                                    if v.face == m.face then
                                        flag = 1
                                        break
                                    end
                                end
                                if flag == 1 then
                                else
                                    table.insert(cards, my_card_stat.line2[i])
                                    table.insert(cards, my_card_stat.line2[i+1])
                                    if #cards == card_ana.len then
                                        break
                                    end
                                end
                            end
                        end

                        if #cards == card_ana.len then
                            table.insert(self.results, cards)
                        end
                    end
                end
            end
        end
        if (#self.results > 0) then
            for i,v in ipairs(my_card_stat.card1) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card2) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card3) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card4) do
                table.insert(self.light_cards_c, v)
            end      
        end
    end

    function CardFind:find_four_with_three(card_ana, card_stat, my_card_stat)
        if (my_card_stat.len < 8) then
            return
        end
        for i,v in ipairs(my_card_stat.card4) do
            if (i-1)%4==0 then
                if v.face > card_ana.face then
                    local cards = {}
                    table.insert(cards, my_card_stat.card4[i])
                    table.insert(cards, my_card_stat.card4[i+1])
                    table.insert(cards, my_card_stat.card4[i+2])
                    table.insert(cards, my_card_stat.card4[i+3])

                    for i,v in ipairs(my_card_stat.card3) do
                        if (i-1)%3==0 then
                            table.insert(cards, my_card_stat.card3[i])
                            table.insert(cards, my_card_stat.card3[i+1])
                            table.insert(cards, my_card_stat.card3[i+2])
                            if #cards == card_ana.len then
                                break
                            end
                        end
                        
                    end
                    if #cards == card_ana.len then
                        table.insert(self.results, cards)
                    else
                        local flag = 0
                        for i,v in ipairs(my_card_stat.line3) do
                            if (i-1)%3==0 then
                                flag = 0
                                for k,m in ipairs(cards) do
                                    if v.face == m.face then
                                        flag = 1
                                        break
                                    end
                                end
                                if flag == 1 then
                                else
                                    table.insert(cards, my_card_stat.line3[i])
                                    table.insert(cards, my_card_stat.line3[i+1])
                                    table.insert(cards, my_card_stat.line3[i+1])
                                    if #cards == card_ana.len then
                                        break
                                    end
                                end
                            end
                        end

                        if #cards == card_ana.len then
                            table.insert(self.results, cards)
                        end
                    end
                end
            end
        end
        if (#self.results > 0) then
            for i,v in ipairs(my_card_stat.card1) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card2) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card3) do
                table.insert(self.light_cards_c, v)
            end
            for i,v in ipairs(my_card_stat.card4) do
                table.insert(self.light_cards_c, v)
            end      
        end
    end

    function CardFind:find_bomb(card_ana, card_stat, my_card_stat) 
        if card_ana.type == CardTypeNew.CARD_TYPE_BOMB then
            if self.threeAbomb and self.threeAbomb == 1 and card_ana.face == 14 then
                return
            end
            for i,v in ipairs(my_card_stat.card4) do
                if (i-1)%4==0 then
                    if v.face > card_ana.face then
                        local cards = {}
                        table.insert(cards, my_card_stat.card4[i])
                        table.insert(cards, my_card_stat.card4[i+1])
                        table.insert(cards, my_card_stat.card4[i+2])
                        table.insert(cards, my_card_stat.card4[i+3])
                        table.insert(self.light_cards_c, my_card_stat.card4[i])
                        table.insert(self.light_cards_c, my_card_stat.card4[i+1])
                        table.insert(self.light_cards_c, my_card_stat.card4[i+2])
                        table.insert(self.light_cards_c, my_card_stat.card4[i+3])
                        table.insert(self.results, cards)
                    end
                end
            end
        else
            for i,v in ipairs(my_card_stat.card4) do
                if (i-1)%4==0 then
                    local cards = {}
                    table.insert(cards, my_card_stat.card4[i])
                    table.insert(cards, my_card_stat.card4[i+1])
                    table.insert(cards, my_card_stat.card4[i+2])
                    table.insert(cards, my_card_stat.card4[i+3])
                    table.insert(self.light_cards_c, my_card_stat.card4[i])
                    table.insert(self.light_cards_c, my_card_stat.card4[i+1])
                    table.insert(self.light_cards_c, my_card_stat.card4[i+2])
                    table.insert(self.light_cards_c, my_card_stat.card4[i+3])
                    table.insert(self.results, cards)
                end
            end
        end
        dump(self.threeAbomb ,"self.threeAbomb self.threeAbomb self.threeAbomb ")
        if self.threeAbomb and self.threeAbomb == 1 then--三A算炸
            for i,v in ipairs(my_card_stat.card3) do
                if (i-1)%3==0 then
                    if v.face == 14 then
                        local cards = {}
                        table.insert(cards, my_card_stat.card3[i])
                        table.insert(cards, my_card_stat.card3[i+1])
                        table.insert(cards, my_card_stat.card3[i+2])
                        table.insert(self.light_cards_c, my_card_stat.card3[i])
                        table.insert(self.light_cards_c, my_card_stat.card3[i+1])
                        table.insert(self.light_cards_c, my_card_stat.card3[i+2])
                        table.insert(self.results, cards)
                        return
                    end
                end
            end
        end
    end

return CardFind
























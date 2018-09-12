local CardStatistics = require("CardStatistics")
local Card = require("Card")
local CardFunc = class("CardFunc")
    function CardFunc.compare(a, b)
        if a.face > b.face then
            return 1
        elseif a.face < b.face then
            return -1
        elseif a.face == b.face then
            if a.suit > b.suit then
                return 1
            elseif a.suit < b.suit then 
                return -1
            end
        end
        return 0
    end

    function CardFunc.sort_by_ascending(v)
        table.sort(v, function(a, b)
            return CardFunc.compare(a, b) == -1
        end)
    end

    function CardFunc.sort_by_descending(v)
        table.sort(v, function(a, b)
            return CardFunc.compare(a, b) == 1
        end)
    end

    function CardFunc.findCardNum(cards, value)
        local num = 0
        local bcard = Card.new(value)
        for i,v in ipairs(cards) do
            if Card.new(v).face == bcard.face then
                num = num + 1
            end
        end
        return num
    end

    function CardFunc.getBaseValue(cards)
        local temp1 = {}
        local temp2 = {}
        local j = 1
        for i,v in ipairs(cards) do
            if CardFunc.findCardNum(cards, v) >= 3 then
                if CardFunc.findCardNum(cards, v) == 4 then
                    if j<4 then
                        table.insert(temp1, Card.new(v))    
                    else
                        table.insert(temp2, Card.new(v))
                        j = 1
                    end
                    j=j+1
                else
                    table.insert(temp1, Card.new(v))                
                end
            else
                table.insert(temp2, Card.new(v))
            end
        end
        if #temp1 > 0 then
            CardFunc.sort_by_ascending(temp1)
            CardFunc.sort_by_ascending(temp2)
            for i,v in ipairs(temp1) do
                cards[i] = v.value
            end
            for i,v in ipairs(temp2) do
                cards[#temp1+i] = v.value
            end
        end
    end

    function CardFunc.isOutCard(handcard)
        local size = #handcard
        if size<=0 then
            return -2
        end
        local card_stat0 = CardStatistics.new()
        card_stat0:statistics(handcard)
        local ad = require("CardAnalysis").new()
        local type = ad:analysis(card_stat0)
        return (0 == type or 12==type or 13==type or 14==type) and -2 or 1
    end

    function CardFunc.isGreater(last, cur)
        local lastNum = #last
        local hanNum = #cur
        if lastNum <= 0 then
            return -1
        end 
        if hanNum <= 0 then
            return -2
        end

        local card_stat0 = CardStatistics.new()
        card_stat0:statistics(last)
        local card_ana0 = require("CardAnalysis").new()
        card_ana0:analysis(card_stat0)
        if card_ana0.type == 0 then
            return -1
        end

        local card_stat1 = CardStatistics.new()
        card_stat1:statistics(cur)
        local card_ana1 = require("CardAnalysis").new()
        card_ana1:analysis(card_stat1)
        if card_ana1.type == 0 then
            return -2
        end

        local res = card_ana1:compare(card_ana0)
        return res == true and 1 or 0
    end
return CardFunc
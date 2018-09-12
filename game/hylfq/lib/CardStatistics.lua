local Card = require("Card")
-- local CardFunc = require("CardFunc")
local CardStatistics = class("CardStatistics")

    function CardStatistics:ctor(obj)
        self.card1 = {}
        self.card2 = {}
        self.card3 = {}
        self.card4 = {}
        self.line1 = {}
        self.line2 = {}
        self.line3 = {}
        self.len = 0
    end

    function CardStatistics:statistics(cardi)
        local cards = {}
        for i,v in ipairs(cardi) do
            local card = Card.new(v)
            table.insert(cards, card)
        end

        self.len = #cards

        require("CardFunc").sort_by_ascending(cards)

        local j = 0
        local temp = cards[1]
        for i=1, #cards-1 do
            -- 找出牌值连续的
            if temp.face == cards[i+1].face then
                j = j + 1
            else
                if j==0 then-- 表示没有相同的
                    table.insert(self.card1, cards[i+1 -1])
                    if temp.face ~= 15 then
                        table.insert(self.line1, cards[i+1 -1])
                    end
                elseif j == 1 then -- 一对
                    table.insert(self.card2, cards[i+1 -2])
                    table.insert(self.card2, cards[i+1 -1])
                    table.insert(self.line1, cards[i+1 -2])
                    table.insert(self.line2, cards[i+1 -2])
                    table.insert(self.line2, cards[i+1 -1])
                elseif j == 2 then-- 一
                    table.insert(self.card3, cards[i+1 -3])
                    table.insert(self.card3, cards[i+1 -2])
                    table.insert(self.card3, cards[i+1 -1])
                    table.insert(self.line1, cards[i+1 -3])
                    table.insert(self.line2, cards[i+1 -3])
                    table.insert(self.line2, cards[i+1 -2])
                    table.insert(self.line3, cards[i+1 -3])
                    table.insert(self.line3, cards[i+1 -2])
                    table.insert(self.line3, cards[i+1 -1])
                elseif j == 3 then
                    table.insert(self.card4, cards[i+1 -4])
                    table.insert(self.card4, cards[i+1 -3])
                    table.insert(self.card4, cards[i+1 -2])
                    table.insert(self.card4, cards[i+1 -1])
                    table.insert(self.line1, cards[i+1 -4])
                    table.insert(self.line2, cards[i+1 -4])
                    table.insert(self.line2, cards[i+1 -3])
                    table.insert(self.line3, cards[i+1 -4])
                    table.insert(self.line3, cards[i+1 -3])
                    table.insert(self.line3, cards[i+1 -2])
                end
                j = 0
            end
            temp = cards[i+1]
        end
        local i = #cards
        if j==0 then
            table.insert(self.card1, cards[i+1 -1])
            if temp.face ~= 15 then
                table.insert(self.line1, cards[i+1 -1])
            end
        elseif j == 1 then 
            table.insert(self.card2, cards[i+1 -2])
            table.insert(self.card2, cards[i+1 -1])
            table.insert(self.line1, cards[i+1 -2])
            table.insert(self.line2, cards[i+1 -2])
            table.insert(self.line2, cards[i+1 -1])
        elseif j == 2 then
            table.insert(self.card3, cards[i+1 -3])
            table.insert(self.card3, cards[i+1 -2])
            table.insert(self.card3, cards[i+1 -1])
            table.insert(self.line1, cards[i+1 -3])
            table.insert(self.line2, cards[i+1 -3])
            table.insert(self.line2, cards[i+1 -2])
            table.insert(self.line3, cards[i+1 -3])
            table.insert(self.line3, cards[i+1 -2])
            table.insert(self.line3, cards[i+1 -1])
        elseif j == 3 then
            table.insert(self.card4, cards[i+1 -4])
            table.insert(self.card4, cards[i+1 -3])
            table.insert(self.card4, cards[i+1 -2])
            table.insert(self.card4, cards[i+1 -1])
            table.insert(self.line1, cards[i+1 -4])
            table.insert(self.line2, cards[i+1 -4])
            table.insert(self.line2, cards[i+1 -3])
            table.insert(self.line3, cards[i+1 -4])
            table.insert(self.line3, cards[i+1 -3])
            table.insert(self.line3, cards[i+1 -2])
        end
        return 0
    end

return CardStatistics

























local CardAnalysis = class("CardAnalysis")
    function CardAnalysis:ctor(obj)
        self.type = 0
        self.len = 0
        self.face = 0
    end

    -- 开始分析
    function CardAnalysis:analysis(card_stat, fourdaithree)
        self.type = CardTypeNew.CARD_TYPE_ERROR
        self.len = card_stat.len
        if self.len == 0 then
            return self.type
        end

        if self.len == 1 then
            self.face = card_stat.card1[0+1].face
            self.type = CardTypeNew.CARD_TYPE_ONE --3
            return self.type
        end

        if self.len == 2 then
            if #card_stat.line1 == 1 and #card_stat.card2 == 2 then
                self.face = card_stat.card2[1+1].face
                self.type = CardTypeNew.CARD_TYPE_TWO --33
                return self.type
            end
        end

        if self.len == 3 then
            if #card_stat.card3 == 3 then
                self.face = card_stat.card3[2+1].face
                self.type = CardTypeNew.CARD_TYPE_THREE --333
                    if self.threeAbomb and self.threeAbomb == 1 then
                         self.type = CardTypeNew.CARD_TYPE_BOMB
                    end
                return self.type
            end
        end
        
        if self.len == 4 then
            if #card_stat.card4 == 4 then
                self.face = card_stat.card4[3+1].face
                self.type = CardTypeNew.CARD_TYPE_BOMB --3333
                return self.type
            elseif #card_stat.card1 == 1 and #card_stat.card3 == 3 then
                self.face = card_stat.card3[2+1].face
                self.type = CardTypeNew.CARD_TYPE_THREEWITHONE --333 4
                return self.type
            end
        end

        if self.len == 5 then
            if #card_stat.card2 == 2 and #card_stat.card3 == 3 then
                self.face = card_stat.card3[2+1].face
                self.type = CardTypeNew.CARD_TYPE_THREEWITHTWO --333 44
                return self.type
            elseif #card_stat.card4 == 4 and #card_stat.card1 == 1 then
                self.face = card_stat.card4[3+1].face
                self.type = CardTypeNew.CARD_TYPE_THREEWITHTWO --3333 4
                return self.type
            elseif #card_stat.card1 == 2 and #card_stat.card3 == 3 then
                self.face = card_stat.card3[2+1].face
                self.type = CardTypeNew.CARD_TYPE_THREEWITHTWO --333 4 5
                return self.type
            end
        end

        if fourdaithree then
            if self.len == 6 then
                if #card_stat.card1 == 2 and #card_stat.card4 == 4 then
                    self.face = card_stat.card4[3+1].face
                    self.type = CardTypeNew.CARD_TYPE_FOURWITHTWO --3333 4 5
                    return self.type
                elseif #card_stat.card2 == 2 and #card_stat.card4 == 4 then
                    self.face = card_stat.card4[3+1].face
                    self.type = CardTypeNew.CARD_TYPE_FOURWITHTWO --3333 44
                    return self.type
                end
            end   

            if self.len == 7 then
                if #card_stat.card4 == 4 and #card_stat.card1 == 3 then
                    self.face = card_stat.card4[3+1].face
                    self.type = CardTypeNew.CARD_TYPE_FOURWITHTHREE --3333 4 5 6
                    return self.type
                elseif #card_stat.card4 == 4 and #card_stat.card1 == 1 and #card_stat.card2 == 2 then
                    self.face = card_stat.card4[3+1].face
                    self.type = CardTypeNew.CARD_TYPE_FOURWITHTHREE --3333 4 55
                    return self.type
                elseif #card_stat.card4 == 4 and #card_stat.card3 == 3 then
                    self.face = card_stat.card4[3+1].face
                    self.type = CardTypeNew.CARD_TYPE_FOURWITHTHREE --3333 444
                    return self.type
                end
            end
        end

        if (#card_stat.card1 == #card_stat.line1 and #card_stat.card2==0 and #card_stat.card3 ==0) then
            if self:check_is_line(card_stat, 1) then
                self.face = card_stat.card1[0+1].face
                self.type = CardTypeNew.CARD_TYPE_ONELINE -- 3 4 5 6 7
                return self.type
            end
        end

        if (#card_stat.card2 == self.len and #card_stat.card2 == #card_stat.line2) then
            if self:check_is_line(card_stat, 2) then
                self.face = card_stat.card2[0+1].face
                self.type = CardTypeNew.CARD_TYPE_TWOLINE -- 33 44
                return self.type
            end
        end

        if self.len < 5 then
            return self.type
        end

        local left_card_len = 0
        if #card_stat.card3 == #card_stat.line3 and #card_stat.card4 == 0 and card_stat.card3 ~= 0 then
            if self:check_is_line(card_stat, 3) then
                left_card_len = #card_stat.card1 + #card_stat.card2
                if (left_card_len == 0) then
                    self.face = card_stat.card3[0+1].face
                    if self.len%5==0 then
                        self.type = CardTypeNew.CARD_TYPE_PLANEWITHWING --555 666
                        return self.type
                    end
                elseif (left_card_len * 3 == #card_stat.card3)then
                
                    self.face = card_stat.card3[0+1].face
                    self.type = CardTypeNew.CARD_TYPE_PLANEWITHONE --555 666 8 9
                    return self.type
                
                elseif ( left_card_len * 3 == #card_stat.card3 * 2) then
                
                    self.face = card_stat.card3[0+1].face
                    self.type = CardTypeNew.CARD_TYPE_PLANEWITHWING --555 666 88 99
                    return self.type
                end
            end
        end
        --20161024
        --拆炸弹需要同步line3
        --这里都是判断飞机牌型的.
        if #card_stat.card4 ~= 0 then
            local bob = #card_stat.card4/4
            for i=0,bob-1 do
                local idx = i*4
                table.insert(card_stat.card3, card_stat.card4[idx+1])
                table.insert(card_stat.card3, card_stat.card4[idx+2])
                table.insert(card_stat.card3, card_stat.card4[idx+3]) 
                table.insert(card_stat.card1, card_stat.card4[idx+4]) 
            end
            card_stat.card4 = {}
        end

        if #card_stat.card3 ~= 0 then
            if self:check_is_line(card_stat, 3) then
                
                
                left_card_len = #card_stat.card1 + #card_stat.card2 + #card_stat.card4
                if (left_card_len == 0) then
                    self.face = card_stat.card3[#card_stat.card3-1 +1].face
                    self.type = CardTypeNew.CARD_TYPE_PLANEWITHONE --333 444 555 666
                    return self.type
                elseif (left_card_len * 3 == #card_stat.card3*2)then
                
                    self.face = card_stat.card3[#card_stat.card3-1 +1].face
                    self.type = CardTypeNew.CARD_TYPE_PLANEWITHWING --333 444 99 99
                    return self.type
                
                elseif ( left_card_len * 3 < #card_stat.card3 * 2) then
                    if self.len%5==0 then
                        self.type = CardTypeNew.CARD_TYPE_PLANEWITHWING 
                        left_card_len = self.len/5
                        local card3 = #card_stat.card3/3
                        for i=left_card_len, card3-1 do
                            for i=1,3 do
                                local temp = card_stat.card3[1]
                                table.insert(card_stat.card1, temp)
                                self:removeByItem(card_stat.card3, temp)
                                self:removeByItem(card_stat.line3, temp)
                            end
                        end
                    else
                        self.type = CardTypeNew.CARD_TYPE_PLANWHITHLACK
                    end
                    self.face = card_stat.card3[#card_stat.card3-1 +1].face
                    return self.type
                end
            end
        end
        
        if #card_stat.line3 >= 6 then --444 555 666 888 739
            if self:check_is_line(card_stat, 3) then
                local cout3 = #card_stat.line3
                if self.len%5 == 0 and self.len - cout3 < cout3 then
                    self.face = card_stat.line3[#card_stat.line3].face
                    self.type = CardTypeNew.CARD_TYPE_PLANEWITHWING
                    return self.type
                end
            end            
            local straight_three_longest = {}
            local cnt = 0 -- 连续的长度
            local last_cnt = 0 -- 上一次连续的长度
            local index = 0 -- 记录最后一次不连续的坐标
            local temp = require("Card").new()   
            local flag = 0 -- 0连续,1不连续 
            local templine3 = {}
            for i,v in ipairs(card_stat.line3) do
                if (i-1)%3 == 0 then
                    if (v.face - temp.face)~= 1 then
                        if cnt > last_cnt then
                            index = i
                            last_cnt = cnt
                        end
                        flag = 1
                        cnt = 0
                    else
                        if v.face ~= 15 then
                            flag = 0
                        end
                    end
                    cnt = cnt + 3
                    temp = v
                end
            end
            if flag == 0 then
                if cnt > last_cnt then
                    index = #card_stat.line3
                    last_cnt = cnt
                end
            end
            for i=(index-last_cnt), index-1 do
                table.insert(straight_three_longest, card_stat.line3[i])
            end
            local len1 = #straight_three_longest
            
            if len1>=12 and self.len >=gln.MAXCARDNUM then
                self.face = straight_three_longest[len1-1 + 1].face
                self.type = CardTypeNew.CARD_TYPE_PLANEWITHWING
                return self.type
            end
            
            if len1>=6 and self.len-len1 < len1/3*2 then
                self.face = straight_three_longest[len1-1 + 1].face
                self.type = CardTypeNew.CARD_TYPE_PLANWHITHLACK
                return self.type
            end

            left_card_len = #card_stat.card1 + #card_stat.card2 + #card_stat.card3 + #card_stat.card4
            local len2 = left_card_len-len1
            
            if ((len1*2)==(len2*3)) then
                --20161012  bug 333 777 888 4,   手上没有三连顺是打不起的.
                --从出的牌中,将cardfind要用的line3修正.
                local new_line3 = {}
                for i,v in ipairs(card_stat.line3) do
                    table.insert(new_line3, v)
                end
                for i,v in ipairs(card_stat.line3) do
                    local del = true
                    for j=len1,1,-3 do
                        local temp = straight_three_longest[j] 
                        if temp.face == v.face then
                            del = false
                            break
                        end  
                    end

                    if del == true then
                        table.insert(card_stat.card1, v)
                        for k,m in ipairs(card_stat.card3) do
                            if m.face == v.face then
                                table.remove(card_stat.card3, k)
                            end
                        end
                        self:removeByItem(new_line3, v)
                    end
                end
                card_stat.line3 = new_line3
                self.face = straight_three_longest[len1-1 + 1].face
                self.type = CardTypeNew.CARD_TYPE_PLANEWITHWING
                return self.type
            end   
        end
        return self.type
    end

    function CardAnalysis:removeByItem(tab, item)
        for i,v in ipairs(tab) do
            if v == item then
                table.remove(tab, i)
                break
            end
        end
    end

    function CardAnalysis:compare(card_analysis)
        if card_analysis.type == CardTypeNew.CARD_TYPE_ERROR then
            return false
        end

        if self.type == card_analysis.type then
            if self.threeAbomb and self.threeAbomb == 1 then
                -- 这里 一旦是三个A，就无敌了
                if self.len == 3 and self.face == 14 then
                    return true
                end
            end
            if self.len == card_analysis.len and self.face > card_analysis.face then
                return true
            end
        else
            if self.type == CardTypeNew.CARD_TYPE_BOMB then
                return true
            end
        end
    end

    function CardAnalysis:check_is_line(card_stat, line_type)
        if line_type == 1 then
            return self:check_arr_is_line(card_stat.line1, 1)
        elseif line_type == 2 then
            return self:check_arr_is_line(card_stat.line2, 2)
        elseif line_type == 3 then
            return self:check_arr_is_line(card_stat.line3, 3)
        end
        return false
    end

    function CardAnalysis:check_arr_is_line(line, line_type)
        return self:__check_arr_is_line(line, line_type, 0, #line)
    end

    function CardAnalysis:__check_arr_is_line(line, line_type, begin, _end)
        local len = 1
        local card = line[begin+1]
        for i=(line_type + begin), _end-1 do
            if i%line_type == 0 then
                if (card.face + 1) == line[i+1].face and line[i+1].face ~= 15 then
                    len = len + 1
                    card = line[i+1]
                else
                    return false
                end
            end
        end
        if line_type == 1 and len > 4 then
            return true
        elseif line_type == 2 and len > 1 then
            return true
        elseif line_type == 3 and len > 1 then
            return true
        end
        return false
    end

    function CardAnalysis:__find_arr_is_line_len(line, line_type, begin, _end)
        local len = 1
        local card = line[begin+1]
        for i=(line_type + begin), _end-1 do
            if i%line_type == 0 then
                if (card.face + 1) == line[i+1].face and line[i+1].face ~= 15 then
                    len = len + 1
                    card = line[i+1]
                else
                    break
                end
            end
        end

        if line_type == 1 and len > 4 then
            return true, len
        elseif line_type == 2 and len > 1 then
            return true, len
        elseif line_type == 3 and len > 1 then
            return true, len
        end
        return false, len
    end

return CardAnalysis
























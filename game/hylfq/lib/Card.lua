local Card = class("Card")
    function Card:ctor(val)
        if val ~= nil then
            self.value = val
            self.face = bit.band(val, 0xF)
            self.suit = bit.rshift(val, 4) 
            if self.face < 3 then
                self.face = self.face + 13
            end
        else
            self.face = 0
            self.suit = 0
            self.value = 0
        end
    end

    function Card:getFace()
        return self.face
    end

    function Card:getSuit()
        return self.suit
    end

    function Card:getValue()
        return self.value
    end

return  Card


























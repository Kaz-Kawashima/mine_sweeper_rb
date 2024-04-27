module OpenState
    SAFE = :safe
    EXPLODE = :explode
end

class Panel
    include OpenState
    attr_reader :isOpen
    attr_reader :isFlagged
    @isOpen
    def flag()
        @isFlagged = !@isFlagged
    end
    def open()
        raise NotImprementedError, "aaa"
    end
end

class BlankPanel < Panel
    attr_accessor :bombValue 

    def initialize()
        @isFlagged = false
        @isOpen = false
        @bombValue = 0
    end

    def open()
        if @isFlagged
            return SAFE
        else
            @isOpen = true
            return SAFE
        end
    end

    def to_s()
        if @isFlagged
            return "F"
        elsif @isOpen
            if @bombValue == 0
                return " "
            else
                return "#{@bombValue}"
            end
        else
            return "#"
        end
    end
end

class BombPanel < Panel

    def initialize()
        @isFlagged = false
        @isOpen = false
    end

    def open()
        if @isFlagged
            return SAFE
        else
            @isOpen = true
            return EXPLODE
        end
    end

    def to_s()
        if @isFlagged
            return "F"
        elsif @isOpen
            return "B"
        else
            return "#"
        end
    end
end

class BorderPanel < Panel

    def initialize()
        @isFlagged = false
        @isOpen = true
    end

    def to_s()
        return "="
    end

end
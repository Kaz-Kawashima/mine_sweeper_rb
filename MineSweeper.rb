require "io/console"
require "tty-reader"
require './Panel.rb'

module GameState
    Uninitialized = :Uninitialized
    Playing = :Playing
    Win = :Win
    Lose = :Lose
end

class GameBoard
    include OpenState   
    include GameState
    @field
    @sizeX
    @sizeY
    @fieldSizeX
    @fieldSizeY
    @cursor_row
    @cursor_col
    @status

    def initialize(y, x, numBomb)
        @sizeX = x
        @sizeY = y
        @fieldSizeX = x + 2
        @fieldSizeY = y + 2
        @numBomb = numBomb
        @cursor_row = 1
        @cursor_col = 1
        initField()
        @status = Uninitialized
    end

    def initField()
        # FillPanel
        @field = []
        for row in 1 .. @fieldSizeY do
            panelRow = []
            for col in 1 .. @fieldSizeX do
                if (row == 1) || (row == @fieldSizeY) || (col == 1)  || (col == @fieldSizeX)
                    panelRow.push(BorderPanel.new)
                else
                    panelRow.push(BlankPanel.new)
                end
            end
            @field.push(panelRow)
        end
    end

    def setBomb(cursor_row, cursor_col)
        counter = 0
        while counter < @numBomb
            row = rand(1 .. @sizeY)
            col = rand(1 .. @sizeX)
            if (row == cursor_row) && (col == cursor_col)
                next
            end
            if @field[row][col].is_a?(BombPanel)
                next
            else
                flag = @field[row][col].isFlagged
                @field[row][col] = BombPanel.new
                @field[row][col].isFlagged = flag
                counter += 1
            end
        end
        calcFieldBombValue()
        @status = Playing
    end

    def calcFieldBombValue()
        for row in 1 .. @sizeY do
            for col in 1 .. @sizeX do
                if @field[row][col].is_a?(BlankPanel)
                    calcBombValue(row, col)
                end
            end
        end
    end

    def calcBombValue(y, x)
        counter = 0
        for row in (y - 1)..(y + 1) do
            for col in (x - 1)..(x + 1) do
                if @field[row][col].is_a?(BombPanel)
                    counter += 1
                end
            end
        end
        @field[y][x].bombValue = counter
    end

    def getStatus()
        if @status == GameState::Uninitialized
            return @status
        end
        @status = GameState::Win
        for row in 1 .. @sizeY
            for col in 1 .. @sizeX
                p = @field[row][col]
                if p.isOpen && p.is_a?(BombPanel)
                    @status = GameState::Lose
                    return @status
                end
                if !p.isOpen && p.is_a?(BlankPanel)
                    @status = GameState::Playing
                end
            end  
        end
        return @status
    end

    def print()
        board_string = ""
        row = 0
        @field.each do |panelRow|
            col = 0
            panelRow.each do |panel|
                panel_string = panel.to_s
                if row == 0 && col == @cursor_col
                    panel_string = "v"
                elsif row == (@sizeY + 1) && col == @cursor_col
                    panel_string = "^"
                elsif row == @cursor_row && col == 0
                    panel_string = ">"
                elsif row == @cursor_row && col == (@sizeX + 1)
                    panel_string = "<"
                elsif row == @cursor_row && col == @cursor_col
                    panel_string = "@"
                end
                board_string += panel_string
                board_string += " "
                col += 1
            end
            board_string += "\n"
            row += 1
        end
        board_string += "\ninput <- ^v -> / O open / F flag (#{countFlag})"
        STDOUT.clear_screen
        puts board_string
    end

    def up()
        @cursor_row -= 1
        if @cursor_row < 1
            @cursor_row = 1
        end
    end

    def down()
        @cursor_row += 1
        if @cursor_row > @sizeY
            @cursor_row = @sizeY
        end
    end

    def left()
        @cursor_col -= 1
        if @cursor_col < 1
            @cursor_col = 1
        end
    end

    def right()
        @cursor_col += 1
        if @cursor_col > @sizeX
            @cursor_col = @sizeX
        end
    end

    def open(cursor_row = @cursor_row, cursor_col = @cursor_col)
        if @status == GameState::Uninitialized
            setBomb(cursor_row, cursor_col)
        end
        result = @field[cursor_row][cursor_col].open
        if result == SAFE
            cascadeOpen
        end
        getStatus
    end

    def flag()
        @field[@cursor_row][@cursor_col].flag
    end

    def openAround(y, x)
        new_open = 0
        for row in (y - 1) .. (y + 1)
            for col in (x - 1) .. (x + 1)
                p = @field[row][col]
                if !p.isOpen and !p.isFlagged
                    p.open
                    new_open += 1
                end
            end
        end
        return new_open
    end

    def cascadeOpen()
        new_open = 1
        while new_open > 0
            new_open = 0
            for row in 1 .. @sizeY
                for col in 1 .. @sizeX
                    panel = @field[row][col]
                    if panel.isOpen && panel.bombValue == 0
                        new_open += openAround(row, col)
                    end
                end
            end
        end
    end

    def countFlag()
        count = 0
        @field.each do |panel_row| 
            panel_row.each do |panel| 
                if panel.isFlagged
                    count += 1
                end
            end
        end
        return count
    end
end

if __FILE__ == $0
    include OpenState
    gb = GameBoard.new(9, 9, 10)
    gb.print()
    reader = TTY::Reader.new
    status = GameState::Uninitialized
    while (status == GameState::Playing) || (status == GameState::Uninitialized)
        input = reader.read_keypress()
        case input
        when "àH"
            gb.up
        when "àM"
            gb.right
        when "àP"
            gb.down
        when "àK"
            gb.left
        when "o"
            status = gb.open()
        when "f"
            gb.flag
        when "q"
            exit
        end
        gb.print
    end
    if status == GameState::Win
        puts "\n You Win!"
    else
        puts "\n Game Over!"
    end
end


module Terminal
    export display, keyboard_controller!, any_key
    using REPL

    left = CartesianIndex(-1, 0)
    right = CartesianIndex(1, 0)
    up = CartesianIndex(0, -1)
    down = CartesianIndex(0, 1)

    keyDict = Dict(
        'Ϩ'=>left, 'ϩ'=>right, 'Ϫ'=>up, 'ϫ'=>down,
        'a'=>left, 'd'=>right, 'w'=>up, 's'=>down)

    quitKeys = ['\x03','\x04','q','\e']

    function inputchar()
        REPL.TerminalMenus.enableRawMode(REPL.TerminalMenus.terminal)
        char = Char(REPL.TerminalMenus.readKey(REPL.TerminalMenus.terminal.in_stream))
        REPL.TerminalMenus.disableRawMode(REPL.TerminalMenus.terminal)
        return char
    end

    function display(width, height, snake, fire, food)
        run(`clear`)
        board = CartesianIndices((width, height))
        lastRow = 1
        for i in board
            if i[2] > lastRow
                println()
                lastRow = i[2]
            end
            if i == snake[1]
                print("🐲")
            elseif i in snake
                print("🐍")
            elseif i in food
                print("🍍")
            elseif i in fire
                print("🔥")
            else
                print("  ")
            end
        end
        println()
    end

    function keyboard_controller!(direction, shouldStop)
        while true
            c = inputchar()
            if c in keys(keyDict)
                direction[1] = keyDict[c]
            elseif c in quitKeys
                shouldStop[1] = true
            end
        end
    end

    function any_key_task(should_quit)
        c = inputchar()
        if c in quitKeys
            should_quit[] = true
        end
    end

    function any_key(shouldStop)
        task = @async any_key_task(shouldStop)
        while !shouldStop[]
            if !shouldStop[] && istaskdone(task)
                return
            end
            sleep(0.1)
        end
    end
end

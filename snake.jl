include("game.jl")
include("terminal.jl")
include("gamepad.jl")

function main()
    speed = 0.3
    width = 10
    height = 7

    if Sys.iswindows()

        println("Select a controller 🎮")
        println("Press any key on your keyboard or gamepad to start")

        should_stop = Ref{Bool}(false)
        detect_gamepad = @async Gamepad.any_key(should_stop)
        detect_keyboard = @async Terminal.any_key(should_stop)
        choice = ""
        while choice == ""
            if istaskdone(detect_gamepad)
                choice = "Gamepad"
            elseif istaskdone(detect_keyboard)
                choice = "Keyboard"
            end
            sleep(0.5)
            if should_stop[]
                exit()
            end
        end
        should_stop[] = true
    else
        choice = "Keyboard"
    end

    println(choice)
    sleep(1)
    if choice == "Gamepad"
        game(speed, width, height, [Gamepad.controller!], [Terminal.display], [Gamepad.forcefeedback])
    else
        game(speed, width, height, [Terminal.keyboard_controller!], [Terminal.display], [])
    end
end

main()
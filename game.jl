using Random

rng = Random.GLOBAL_RNG

function step!(width, height, snake, fire, food, direction, points, events)
    # Add new head
    pushfirst!(snake, snake[1] + direction[1])
    # Remove tail
    tail = pop!(snake)

    # Wrap around
    if snake[1][1] < 1
        snake[1][1] = CartesianIndex(width, snake[1][2])
    end
    if snake[1][2] < 1
        snake[1][2] = CartesianIndex(snake[1][1], height)
    end
    if snake[1][1] > width
        snake[1] = CartesianIndex(1, snake[1][2])
    end
    if snake[1][2] > height
        snake[1][2] = CartesianIndex(snake[1][1], 1)
    end

    # Check new head
    if snake[1] in food
        points[] += 1
        # Reattach tail
        push!(snake, tail)
        # Remove food
        filter!(e -> e ≠ snake[1], food)
        for event in events
            @async event("ate")
        end
    elseif snake[1] in fire || snake[1] in snake[2:end]
    for event in events
        @async event("burned")
    end
        return false
    end

    # Add food
    if isempty(food)
        push!(food, rand(rng, setdiff(setdiff(CartesianIndices((width,height)),fire), snake)))
    end
    return true
end

function game(speed, width, height, controllers, displays, events)
    points = Ref{Int}(0)
    direction = [CartesianIndex(1,0)]
    shouldStop = [false]
    snake = [CartesianIndex(round(Int, width / 2), round(Int, height / 2))]
    food = []
    allindices = CartesianIndices((width,height))
    fire = append!(vec(allindices[ :, [1,end] ]), vec(allindices[[1,end],:]))

    for controller! in controllers
        @async controller!(direction, shouldStop)
    end
    start = time()
    while !shouldStop[1] && step!(width, height, snake, fire, food, direction, points, events)
        for display in displays
            @async display(width, height, snake, fire, food)
        end
        sleep(speed)
    end
    for display in displays
        @async display(width, height, snake, fire, food)
    end
    sleep(1)
    println("Game over 😖")
    println("💰 $(points[]) points")
    println("⏳ $(round(Int, time()-start)) seconds")
    sleep(1)
end

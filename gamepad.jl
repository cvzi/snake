module Gamepad
    @static if Sys.iswindows()
        export controller, forcefeedback, any_key
        using Libdl

        USER = 1

        # See specifications at https://docs.microsoft.com/en-us/windows/win32/api/xinput/ns-xinput-xinput_gamepad
        XInput = dlopen("XInput1_4.dll")
        XInputSetState = Libdl.dlsym(XInput, :XInputSetState)
        XInputGetState = Libdl.dlsym(XInput, :XInputGetState)
        xInputVibration = Vector{Cushort}(undef, 2)

        XINPUT_GAMEPAD_DPAD_UP = 0x0001
        XINPUT_GAMEPAD_DPAD_DOWN = 0x0002
        XINPUT_GAMEPAD_DPAD_LEFT = 0x0004
        XINPUT_GAMEPAD_DPAD_RIGHT = 0x0008
        XINPUT_GAMEPAD_START = 0x0010
        XINPUT_GAMEPAD_BACK = 0x0020
        XINPUT_GAMEPAD_LEFT_THUMB = 0x0040
        XINPUT_GAMEPAD_RIGHT_THUMB = 0x0080
        XINPUT_GAMEPAD_LEFT_SHOULDER = 0x0100
        XINPUT_GAMEPAD_RIGHT_SHOULDER = 0x0200
        XINPUT_GAMEPAD_A = 0x1000
        XINPUT_GAMEPAD_B = 0x2000
        XINPUT_GAMEPAD_X = 0x4000
        XINPUT_GAMEPAD_Y = 0x8000

        struct XInputGamepad
            wButtons::Cushort
            bLeftTrigger::Cuchar
            bRightTrigger::Cuchar
            sThumbLX::Cshort
            sThumbLY::Cshort
            sThumbRX::Cshort
            sThumbRY::Cshort
        end

        struct XInputState
            dwPacketNumber::Cuint
            gamepad::XInputGamepad
        end

        xInputState = Vector{XInputState}(undef, 1)

        function gamepad_vibrate(left, right)
            xInputVibration[1] = round(Cushort, 0xFFFF * left)
            xInputVibration[2] = round(Cushort, 0xFFFF * right)
            ccall(XInputSetState, Ptr{Cvoid}, (Cuint, Ptr{Cushort}), USER, xInputVibration)
        end

        function gamepad_vibrate_left(left)
            xInputVibration[1] = round(Cushort, 0xFFFF * left)
            ccall(XInputSetState, Ptr{Cvoid}, (Cuint, Ptr{Cushort}), USER, xInputVibration)
        end

        function gamepad_vibrate_right(right)
            xInputVibration[2] = round(Cushort, 0xFFFF * right)
            ccall(XInputSetState, Ptr{Cvoid}, (Cuint, Ptr{Cushort}), USER, xInputVibration)
        end

        function gamepad_get_state()
            ccall(XInputGetState, Ptr{Cvoid}, (Cuint, Ptr{XInputState}), USER, xInputState)
            return xInputState[1].gamepad
        end

        left = CartesianIndex(-1, 0)
        right = CartesianIndex(1, 0)
        up = CartesianIndex(0, -1)
        down = CartesianIndex(0, 1)
        keyDict = Dict(
            XINPUT_GAMEPAD_DPAD_LEFT=>left, XINPUT_GAMEPAD_DPAD_RIGHT=>right, XINPUT_GAMEPAD_DPAD_UP=>up, XINPUT_GAMEPAD_DPAD_DOWN=>down,
            XINPUT_GAMEPAD_X=>left, XINPUT_GAMEPAD_B=>right, XINPUT_GAMEPAD_Y=>up, XINPUT_GAMEPAD_A=>down)

        function controller!(direction, shouldStop)
            while true
                gamepad_vibrate_right(0)
                gamepad = gamepad_get_state()
                if gamepad.wButtons in keys(keyDict)
                    direction[1] = keyDict[gamepad.wButtons]
                    gamepad_vibrate_right(1)
                elseif gamepad.wButtons == XINPUT_GAMEPAD_BACK
                    shouldStop[1] = true
                elseif gamepad.sThumbLX < -20000 || gamepad.sThumbRX < -20000
                    direction[1] = left
                elseif gamepad.sThumbLX > 20000 || gamepad.sThumbRX > 20000
                    direction[1] = right
                elseif gamepad.sThumbLY > 20000 || gamepad.sThumbRY > 20000
                    direction[1] = up
                elseif gamepad.sThumbLY < -20000 || gamepad.sThumbRY < -20000
                    direction[1] = down
                end
                sleep(0.01)
            end
        end

        function forcefeedback(type)
            if type == "ate"
                gamepad_vibrate_left(1)
                sleep(0.3)
                gamepad_vibrate_left(0)
            elseif type == "burned"
                for i in 0.8:-0.1:0
                    gamepad_vibrate_left(i)
                    sleep(0.2)
                end
            end
        end

        function any_key(shouldStop)
            ccall(XInputGetState, Ptr{Cvoid}, (UInt32, Ptr{XInputState}), USER, xInputState)
            x = xInputState[1].dwPacketNumber
            while !shouldStop[]
                ccall(XInputGetState, Ptr{Cvoid}, (UInt32, Ptr{XInputState}), USER, xInputState)
                if xInputState[1].dwPacketNumber != x
                    return
                end
                sleep(0.01)
            end
        end

    end
end

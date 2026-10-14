rm dcv2.lua
edit dcv2.lua

-- Door Controller v2.1
---- [CONFIG] ----
-- toggle, timer
local mode = "timer"
-- Longer times are advisable for rolldoors
local timeout = 5
-- Set both to nil to enable claim system
local key_data = nil
local key_id = nil

---- [ROLLDOOR] ----
local speed = 1 -- 0.1 to 3


---- [KEYPAD] ----
local kp_vol = 0.2
local btnCol = {15, 15, 15, 15, 15, 15, 15, 15, 15, 14, 15, 10}
local btn = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"} 

---- [MAIN] ----
local component = require("component") -- Comment if using in EEPROM
local computer = require("computer") -- Comment if using in EEPROM
local reader = nil
local reader_light = false
local door = nil
local modem = nil

local keypad = nil
local kp_mode = nil
local kp_buffer = nil
local kp_pin = nil

local isRollDoor = false

computer.beep(200,0)
for address, ctype in component.list() do
    if ctype == "modem" then
        computer.beep(400,0)
        modem = component.proxy(address)
    end
    if ctype == "os_magreader" then
        computer.beep(400,0)
        reader = component.proxy(address)
    end
    if ctype == "os_doorcontroller" then
        computer.beep(400,0)
        door = component.proxy(address)
    end
    if ctype == "os_rolldoorcontroller" then
        computer.beep(400,0)
        door = component.proxy(address)
        isRollDoor = true
    end
    if ctype == "os_keypad" then
        computer.beep(400,0)
        keypad = component.proxy(address)
    end
end

-- post component scan --
computer.beep(800,0)
if modem then
    computer.beep(800,0)
    modem.open(3636)
    if modem.isWireless() then
        computer.beep(1200,0.1)
    end
end
if not reader and not keypad then
    error("MagReader or Keypad not found!")
elseif reader then
    if reader["swipeIndicator"] then
        reader_light = true
        reader.swipeIndicator(false)
    end
end
if not door then
    error("Door Controller not found!")
else
    door.close()
    if isRollDoor then
        door.setSpeed(speed)
    end
end
if keypad then
    keypad.setEventName("keypad")
    keypad.setKey(btn, btnCol)
    keypad.setDisplay("SET PIN", 14)
    keypad.setVolume(0.1)
    kp_mode = "setup" -- setup, lock, open
    kp_buffer = ""
    kp_pin = ""
end
computer.beep(1600,0)

-- [NOTIFIERS] --

local function safe_lightstate(int)
    if reader_light then reader.setLightState(int) end
end

local function notify_open()
    safe_lightstate(4)
    computer.beep(600,0.2)
    safe_lightstate(0)
end

local function notify_close()
    safe_lightstate(4)
    computer.beep(400,0.1)
    safe_lightstate(0)
end

local function notify_err()
    safe_lightstate(1)
    computer.beep(400,0)
    computer.beep(400,0)
    safe_lightstate(0)
end

local function notify_set()
    safe_lightstate(2)
    computer.beep(1200,0)
    safe_lightstate(0)
end

local function safe_keypad(txt,col)
    if keypad then
        if col then keypad.setDisplay(txt, col)
        else keypad.setDisplay(txt)
        end
    end
end

-- [MAIN] --

local remote_id = nil
local last_open = 0
local time_diff = 0
local old_time_diff = 0

local function check(manual)
    if manual == nil then manual = false end
    if mode == "toggle" then
        if old_time_diff > time_diff then
            door.toggle()
            notify_open()
            safe_keypad("GRANTED", 10)
        end
    elseif mode == "timer" then
        if computer.uptime() - last_open < timeout or manual then
            local con = door.isOpen()
            if isRollDoor then
                con = con or door.isMoving()
            end
            if not con then
                door.open()
                notify_open()
                safe_keypad("OPEN", 10)
            end
        else
            if door.isOpen() then
                door.close()
                notify_close()
                safe_keypad("CLOSE", 14)
            end
        end
    end
end

while true do
    old_time_diff = time_diff
    time_diff = computer.uptime() - last_open
    local event = {computer.pullSignal(1)}
    -- print(require("serialization").serialize(event,true))
    if event[1] == nil and (key_data == nil and (kp_mode == "setup" or kp_mode == nil)) then
        computer.beep(300,0)
    end
    if event[1] == "keypad" then
        if event[4] == "*" then
            kp_buffer = string.sub(kp_buffer, 1, -2)
            safe_keypad(kp_buffer,15)
        elseif event[4] == "#" then
            if kp_mode == "setup" then
                kp_pin = kp_buffer
                kp_mode = "lock"
                notify_set()
                safe_keypad("PIN SET", 10)
            elseif kp_mode == "lock" then
                if kp_buffer == kp_pin then
                    if not door.isOpen() then last_open = computer.uptime() end
                    check()
                    if mode == "toggle" then
                        kp_mode = "open"
                    end
                else
                    notify_err()
                    safe_keypad("DENIED", 12)
                end
            elseif kp_mode == "open" then
                if door.isOpen() then last_open = computer.uptime() end
                kp_mode = "lock"
                check()
            end
            kp_buffer = ""
        else
            kp_buffer = kp_buffer .. event[4]
            keypad.setDisplay(kp_buffer,15)
        end
    else
        safe_keypad("")
    end
    if event[1] == "magData" then
        -- Default mode
        if key_id ~= nil and key_data == event[4] then
            last_open = computer.uptime()
            check(true)
        elseif key_data ~= event[4] then
            notify_err()
        end
        if key_data == nil then
            key_data = event[4]
            notify_set()
            safe_keypad("CARD SET", 14)
        end
        if key_id == nil then
            key_id = event[5]
            notify_set()
            safe_keypad("CARD SET", 14)
        end
    end
    if modem and event[1] == "modem_message" then
        local sender = event[3]
        local port = event[4]
        local message = event[6]
        computer.beep(1600)
        if remote_id == nil and message == "sec-claim" then
            remote_id = sender
        elseif remote_id == sender then
            if message == "sec-shutdown" then
                door.close()
                computer.shutdown(false)
                computer.beep(400,0)
            end
            if message == "sec-reboot" then
                door.close()
                computer.shutdown(true)
            end
        end
    end
    check()
end
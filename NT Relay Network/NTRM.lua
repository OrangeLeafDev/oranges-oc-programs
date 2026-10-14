rm test.lua
edit test.lua
-- NeoTechnologies Relay Messenger
-- Version 1.4a

local component = require("component")
local keyboard = require("keyboard")
local event = require("event")
local thread = require("thread")
local unicode = require("unicode")
local text = require("text")
local term = require("term")
local computer = require("computer")
computer.beep(1600,0)

local modem = component.modem
local gpu = component.gpu
local beep = computer.beep
local isRunning = 1

width, height = gpu.getResolution()
local log_limit = 50
local log = {""}
local input = ""
local latest_touch = {}

local comm_port = 3600
modem.open(comm_port)
print("NTRM 1.4a - NeoTechnologies Relay Messenger")
print("NeoTechnologies ICT Department - Dr C.")
print("Input Alias")
local username = io.read()

gpu.fill(1,1,width,height," ")
modem.broadcast(comm_port,username.." joined the room")

local function beept(freq_table,dur_table)
  thread.create(function(freq_table_inner,dur_table_inner)
    if component.isAvailable("beep") then
      for _idx = 1, #freq_table_inner do
        local _temp = {}
        local startTime = computer.uptime()
        _temp[freq_table_inner[_idx]] = dur_table_inner[_idx]
        component.beep.beep(_temp)
        repeat os.sleep(dur_table_inner[_idx])
        until (computer.uptime() - startTime) >= dur_table_inner[_idx]
      end
    else
      for _idx = 1, #freq_table do
        beep(freq_table[_idx], dur_table[_idx]-0.05)
      end
    end
  end,freq_table,dur_table)
end
-- Limit Printable String In Text Display Bounds
-- classic "cvttsd2si" moment right here
local function lpsitdb(str, lb, rb, x)
  local idxg = x
  local buffer = ""
  for i = 1, unicode.len(str) do
    local letter = unicode.sub(str, i, i)
    if idxg > lb and idxg <= rb then
      buffer = buffer .. letter
    end
    idxg = idxg + 1
  end
  return buffer
end

local function displayAt(x,y,leftalign,contents)
  local print_x = x-math.floor(#contents*leftalign)
  gpu.set(print_x,y,lpsitdb(contents,0,width,print_x))
end

local function print_log(contents)
  table.insert(log, 1, tostring(contents))
end

local function chat_keyHandle(ev_address,ev_unicode,ev_keyboard,ev_username)
  local key = keyboard.keys[ev_keyboard]
  if key == "back" then
    input = input:sub(1, -2)
  elseif key == "f1" then
    isRunning = 0
    return false
  elseif key == "enter" then
    print_log(username.." > "..input)
    modem.broadcast(comm_port,username.." > "..input)
    input = ""
    beept({700,1050},{0.05,0.05})
  elseif key == "space" then
    input = input -- .. " "
  elseif key == nil and not (unicode.char(ev_unicode) == " ") then
    beept({1600},{0.05})
  elseif string.len(tostring(key)) and not (key == "lshift") and not (key == "rshift") then
    input = input .. unicode.char(ev_unicode)
  end
  return input
end

local function chat_incomingMessage(ev_rx,ev_tx,ev_port,ev_dist,ev_msg)
  if ev_port == comm_port then
    table.insert(log, 1, tostring(ev_msg))
    beept({1400,1050},{0.05,0.05})
  end
end

local function _renderLogs(log_table)
  log_index = 0
  while log_index < #log do
    if not (log_table[log_index] == nil) then
      gpu.set(1,height-log_index-1,text.padRight(log_table[log_index],width))
    end
    log_index=log_index+1
  end
  if #log > log_limit then table.remove(log) end
end

local function Button(x,y,text,touch_idx,show)
  local result = false
  local old_fg = gpu.getForeground()
  local old_bg = gpu.getBackground()
  local left_bounds = x
  local right_bounds = x + #text
  if latest_touch[4] == touch_idx then
    if latest_touch[2] > left_bounds and latest_touch[2] < right_bounds and latest_touch[3] == y then
      result = latest_touch[1]
    end
  end
  if not result then
    gpu.setBackground(old_fg)
    gpu.setForeground(old_bg)
  end
  if show then gpu.set(x,y,text) end
  if not result then
    gpu.setBackground(old_bg)
    gpu.setForeground(old_fg)
  end
  return result
end

beept({880,440,880},{0.1,0.05,0.1})
local cur_usr = nil
local mode = "inactive"
while (isRunning) do
  ev={event.pull()}
  -- event(a)        | b           | c           | d          | e         | f       | g | ...  |
  -- key_down        | address     | unicode     | keyboard   | username  | #       | # | #    |
  -- modem_message   | address(rx) | address(tx) | port       | distance  | message * limit(8) |
  -- touch/drag/drop | address     | terminal x  | terminal y | mouse idx | #       | # | #    |
  -- General touch event
  -- [type,x,y,button]
  latest_touch = {nil,nil,nil,nil}
  if ev[1] == "touch" or ev[1] == "drag" or ev[1] == "drop" then
    latest_touch = {ev[1],ev[3],ev[4],ev[5]}
    cur_usr = ev[6]
  end
  if ev[1] == "key_down" then
    cur_usr = ev[5]
    if not chat_keyHandle(ev[2],ev[3],ev[4],ev[5]) then break end
  elseif ev[1] == "modem_message" then chat_incomingMessage(ev[2],ev[3],ev[4],ev[5],ev[6])
  end
  local exit_gui = Button(1,1,"Press F1 to exit",0,true)
  if exit_gui == "drop" then break end
  _renderLogs(log)
  gpu.fill(1,height,width,height," ")
  gpu.set(1,height,"["..tostring(cur_usr).."]:"..username.." > "..input)
  gpu.set(1,2,tostring(latest_touch[1]))
end
gpu.fill(1,1,width,height," ")
modem.close(comm_port)
print("Quitting..")
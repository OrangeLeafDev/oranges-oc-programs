rm test.lua
edit test.lua
-- NeoTechnologies Wireless Relay Server
-- Version 1.0

function tableToString(tbl)
  local parts = {}

  for k, v in pairs(tbl) do
    table.insert(parts, tostring(k) .. "=" .. tostring(v))
  end

  return "{" .. table.concat(parts, ", ") .. "}"
end

local computer = require("computer")
local keyboard = require("keyboard")
local component = require("component")
local event = require("event")
local modem = component.modem
computer.beep(800,0)
local groundPort = nil
local airPort = nil
local relayMode = nil

function uuid_sweep(uuid_table, time)
  for key, value in pairs(uuid_table) do
    if computer.uptime()-value > time then
      uuid_table[key] = nil
    end
  end
  return uuid_table
end

print("Mode (E - Endpoint Mode | R - Relay Mode)")
while not (relayMode == "e" or relayMode == "r") do
  computer.beep(400,0)
  relayMode = string.lower(io.read())
end

print("Input network port")
while groundPort == nil do
  computer.beep(400,0)
  groundPort = tonumber(io.read())
end

print("Input wireless port")
while airPort == nil do
  computer.beep(400,0)
  airPort = tonumber(io.read())
end

computer.beep(800,0)
modem.open(groundPort)
computer.beep(800,0)
modem.open(airPort)
computer.beep(1600,0.1)

isRunning = true

local uuids = {}
local _temp = "nil"
if relayMode == "e" then _temp = "endpoint" end
if relayMode == "r" then _temp = "relay" end
print("Relay server running in ".._temp.." mode")
print("Press F1 to quit")
math.randomseed(os.time())
while(isRunning) do
  -- event(a)      | b           | c           | d        | e        | f       | g | ...  |
  -- key_down      | address     | unicode     | keyboard | username | #       | # | #    |
  -- modem_message | address(rx) | address(tx) | port     | distance | message * limit(8) |
  ev_id, ev_rx, ev_tx, ev_port, ev_dist, msg, msg_uuid, msg_org_sig, msg_2nd_last_seen, msg_last_seen = event.pull()
  print("==========|")
  uuids = uuid_sweep(uuids, 1)
  os.sleep(0.001)
  if ev_id == "modem_message" then
    print("UUID:LOCAL|"..tableToString(uuids))
    if msg_uuid == nil then
      if ev_port == groundPort then -- if data originates from ground
        if relayMode == "e" then
          print("TX:GND>AIR|")
          local _uuid = ev_rx.."-"..ev_port..tostring(math.random(1,0xffffff))
          uuids[_uuid] = computer.uptime()
          print("UUID:NEW  |".._uuid.." >>> "..computer.uptime())
          print("UUID:LOCAL|"..tableToString(uuids))
          modem.setStrength(400)
          modem.broadcast(airPort,msg,_uuid,ev_rx,ev_tx,ev_rx)
        end
      end
    elseif not uuids[msg_uuid] then
      local _isOrigin = msg_org_sig == ev_rx
      uuids[msg_uuid] = computer.uptime()
      print("UUID:LOG  |"..msg_uuid.." >>> "..computer.uptime())
      print("UUID:LOCAL|"..tableToString(uuids))
      print("RX!       |"..ev_rx.." <<< "..ev_tx.." VIA ".. ev_port)
      print("RX:MSG    |"..msg)
      print("RX:UUID   |"..tostring(msg_uuid))
      print("RX:ORIGIN |"..tostring(msg_org_sig).."("..(tostring(_isOrigin))..")")
      if ev_port == airPort and not (_isOrigin) and not (msg_2nd_last_seen == ev_rx) then -- if data originates from air and not from self
        if relayMode == "e" then
          print("TX:AIR>GND|")
          modem.setStrength(0)
          modem.broadcast(groundPort,msg)
        elseif relayMode == "r" then
          print("TX:AIR>AIR|")
          modem.broadcast(airPort,msg,msg_uuid,msg_org_sig,ev_tx,ev_rx)
        end
      end
    else
      print("UUID:SEEN |"..msg_uuid.." >>> "..uuids[msg_uuid])
      print("UUID:LOCAL|"..tableToString(uuids))
    end
  end
  if ev_id == "key_down" then
    local key = keyboard.keys[ev_port]
    if key == "f1" then
      isRunning = 0
      break
    end
  end
end

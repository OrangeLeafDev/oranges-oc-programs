rm test.lua
edit test.lua
-- CitrusRouter Basic Router
-- Version 1.0
local component = require("component")
local event = require("event")
local thread = require("thread")
local computer = require("computer")
local serialization = require("serialization")

local modems = component.modem
local modem_ids = {}
for address, type in component.list("modem") do
    table.insert(modems,   component.proxy(address))
    table.insert(modem_ids, address)
end
local gpu = component.gpu
local beep = computer.beep

local localPort = nil
local broadPort = nil

print("Input local port (NIC#1)")
while localPort == nil do
    computer.beep(400,0)
    localPort = tonumber(io.read())
end

print("Input broad port (NIC#2)")
while broadPort == nil do
    computer.beep(400,0)
    broadPort = tonumber(io.read())
end

computer.beep(800,0)
modems[1].open(localPort)
computer.beep(800,0)
modems[2].open(broadPort)
computer.beep(1600,0.1)

local isRunning = true

local uuids = {}
local domains = {}

while (isRunning) do
    ev={event.pull()}
    print(serialization.serialize(ev,true))
    local msg_rx = nil
    local msg_tx = nil
    local msg_port = nil
    local msg_dist = nil
    local msg_packet = nil
    local msg = {}
    if ev[1] == "modem_message" then
        msg_rx = ev[2]
        msg_tx = ev[3]
        msg_port = ev[4]
        msg_dist = ev[5]
        msg_packet = ev[6]
        msg = serialization.unserialize(msg_packet)
    end
    if msg.type == "uplink" then
        if msg_rx == modem_ids[1] then
            print("RECV CONN_REQ ["..msg_tx.."]")
            uuids[msg_tx] = "device"
            local rx_msg = {type="crouter-ack", contents=1, targ_addr=msg_tx}
            modems[1].send(msg_tx, msg_port, serialization.serialize(rx_msg))
        end
    end
    if msg.type == "sendto" then
        if msg_rx == modem_ids[1] then
            print("RECV SENDTO ["..msg_tx.."] TO ["..msg.targ_addr.."]")
            if uuids[msg.targ_addr] == nil then
                --
            else
                modems[1].send(msg.targ_addr, msg_port, msg_packet)
            end
        end
    end
    if msg.type == "regid" then
        if msg_rx == modem_ids[1] then
            print("RECV REGID ["..msg_tx.."]")
            if domains[msg.contents] == nil then
                domains[msg.contents] = msg_tx
                local rx_msg = {type="reply", contents=1, targ_addr=msg_tx}
                modems[1].send(msg_tx, msg_port, serialization.serialize(rx_msg))
            else
                local rx_msg = {type="reply", contents=0, targ_addr=msg_tx}
                modems[1].send(msg_tx, msg_port, serialization.serialize(rx_msg))
            end
        end
    end
    if msg.type == "getid" then
        if msg_rx == modem_ids[1] then
            print("RECV GETID ["..msg_tx.."]")
            local fetch_id = domains[msg.contents]
            if fetch_id == nil then
                fetch_id = 0
            end
            local rx_msg = {type="fetch-id", contents=fetch_id, targ_addr=msg_tx}
            modems[1].send(msg_tx, msg_port, serialization.serialize(rx_msg))
        end
    end
end
rm test.lua
edit test.lua
-- CitrusRouter Test Client
-- Version 1.0
local component = require("component")
local event = require("event")
local thread = require("thread")
local computer = require("computer")
local serialization = require("serialization")

local modem = component.modem
local gpu = component.gpu
local beep = computer.beep

local localPort = nil
local timeout = 5

local function splitString(inputstr, sep)
    local t = {}
    local safe_sep = sep:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    for str in string.gmatch(inputstr, "([^" .. safe_sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

local function connect(port)
    computer.beep(800,0)
    modem.open(port)
    computer.beep(1600,0.1)
    local conn_req = {type="uplink", contents=0, targ_addr=0}
    modem.broadcast(port,serialization.serialize(conn_req))
    computer.beep(1200,0)
    local noAck = true
    local id
    while noAck do
        ev={event.pull(timeout,"modem_message")}
        if ev[1] == nil then
            conn_req = {type="uplink", contents=0, targ_addr=0}
            modem.broadcast(port,serialization.serialize(conn_req))
            computer.beep(600,0)
        else
            --print(serialization.serialize(ev,true))
            local msg = serialization.unserialize(ev[6])
            if msg.type == "crouter-ack" and ev[4] == port then
                computer.beep(1200,0)
                noAck = false
                id = ev[3]
            end
        end
    end
    computer.beep(2000,0)
    return id
end

local function waitReply(address,port,typemsg)
    local nos = true
    local r_ev = {}
    while nos do
        ev={event.pull("modem_message")}
        --print(serialization.serialize(ev,true))
        computer.beep(1200,0)
        local msg = serialization.unserialize(ev[6])
        if (msg.type == typemsg or typemsg == nil) and ev[4] == port then
            if address == ev[3] then
                nos = false
                r_ev = {
                    rx=ev[2],
                    tx=ev[3],
                    port=ev[4],
                    dist=ev[5],
                    packet=ev[6]
                }
            end
        end
    end
    return r_ev
end

local function send(address,port,message,typemsg,trueAddr)
    if typemsg == nil then
        typemsg = "message"
    end
    if trueAddr == nil then
        trueAddr = address
    end
    local msg = {type=typemsg, contents=message, targ_addr=address}
    return modem.send(trueAddr,port,serialization.serialize(msg))
end


print("Input local port")
while localPort == nil do
  computer.beep(400,0)
  localPort = tonumber(io.read())
end
local router_id = connect(localPort)
print("Connection acknowledged by ["..router_id.."] !")

local isRunning = true

local uuids = {}
local namereg = false
while (not namereg) do
    print("Input domain to register")
    local input = io.read()
    send(router_id,localPort,input,"regid")
    local response = waitReply(router_id,localPort,"reply")
    local packet = serialization.unserialize(response.packet)
    if packet.contents == 1 then
        print("Domain registered!")
        namereg = true
    elseif packet.contents == 0 then
        print("Domain already exists!")
    else
        print("Response invalid")
    end
end
local domainFetch = false
local targ = nil
local targName = nil
while (not domainFetch) do
    print("Input domain to anticipate")
    local input = io.read()
    send(router_id,localPort,input,"getid")
    local response = waitReply(router_id,localPort,"fetch-id")
    local packet = serialization.unserialize(response.packet)
    if packet.contents == 0 then
        print("Domain not found!")
    else
        print("Domain "..input.." resolved as: ["..packet.contents.."]")
        domainFetch = true
        targName = input
        targ = packet.contents
    end
end

local sendfirst = nil
while (sendfirst ~= "n" and sendfirst ~= "y") do
    print("Send first? (y/n)")
    sendfirst = io.read()
end
if sendfirst == "y" then
    print("Input message")
    local input = io.read()
    local result = send(targ,localPort,input,"sendto",router_id)
    print(result)
    print("Sent! Receiving...")
    local response = waitReply(router_id,localPort,"sendto")
    local packet = serialization.unserialize(response.packet)
    print("["..targName.."]: "..packet.contents)
else
    print("Receiving...")
    local response = waitReply(router_id,localPort,"sendto")
    local packet = serialization.unserialize(response.packet)
    print("["..targName.."]: "..packet.contents)
    print("Input message")
    local input = io.read()
    local result = send(targ,localPort,input,"sendto",router_id)
    print(result)
    print("Sent!")
end


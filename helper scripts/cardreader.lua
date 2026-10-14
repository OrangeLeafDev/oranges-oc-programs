rm magread.lua
edit magread.lua

local reader = require("component").os_magreader
local event = require("event")
local serialization = require("serialization")
local isRunning = true
while (isRunning) do
    -- 1          2        3           4         5             6             7
    -- eventName, address, playerName, cardData, cardUniqueId, isCardLocked, side
    ev={event.pull()}
    if ev[1] == "interrupted" then
        isRunning = false
    end
    if ev[1] == "magData" then
        print(serialization.serialize(ev,true))
    end
end
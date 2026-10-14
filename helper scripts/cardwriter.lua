rm card.lua
edit card.lua

local writer = require("component").os_cardwriter
local computer = require("computer")
local args = {...}
local data = args[1]
local disp = args[2]
local col = tonumber(args[3])
computer.beep(400,0)
if data == nil then
    print("Write data string")
    data = io.read()
    computer.beep(400,0)
end
if disp == nil then
    print("Write display string")
    disp = io.read()
    computer.beep(400,0)
end
if col == nil then 
    print([[0  - none      | 1  - orange       | 2  - purple
3  - cyan      | 4  - yellow       | 5  - green
6  - pink      | 7  - gray         | 8  - light gray
9  - dark cyan | 10 - dark purple  | 11 - dark blue
12 - brown     | 13 - dark green   | 14 - red]])
end
while col == nil do
    print("Input color number")
    col = tonumber(io.read())
    computer.beep(400,0)
end
local ro = nil
while (ro ~= "n" and ro ~= "y") do
    print("Read-only? (y/n)")
    ro = io.read()
    computer.beep(400,0)
end
writer.write(data, disp, ro==y, col)
computer.beep(200,0)
computer.beep(800,0)
computer.beep(1600,0)
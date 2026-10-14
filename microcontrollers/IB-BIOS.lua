-- IdleBrain v1.5
local chunkloader = component.list("chunkloader")()
if chunkloader then
	component.invoke(chunkloader, "setActive", true)
end
local modem = nil
computer.beep(400,0)
for address, ctype in component.list() do
  if ctype == "modem" then
    computer.beep(400,0)
    modem = component.proxy(address)
    break
  end
end
computer.beep(800,0)
if modem then
  computer.beep(800,0)
  modem.open(3636)
  if modem.isWireless() then
    computer.beep(1200,0.1)
  end
end
computer.beep(1600,0)
while true do
  local event = {computer.pullSignal()}
  if modem and event[1] == "modem_message" then
    local sender = event[3]
    local port = event[4]
    local message = event[6]
    computer.beep(1600)
    if message == "shutdown" then
      computer.shutdown(false)
      computer.beep(400,0)
    end
    if message == "reboot" then computer.shutdown(true) end
  end
end
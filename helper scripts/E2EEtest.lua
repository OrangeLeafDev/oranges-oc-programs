-- rm test.lua
-- edit test.lua

local component = require("component")
local data = component.data
local event = require("event")
local m = component.modem

local pub, priv = data.generateKeyPair(256)
local other_pub = -1
m.open(64)
m.broadcast(64, pub.serialize(), "kpass")

print("Waiting...")
local receivedKey = false
while (not receivedKey) do
	local _, _, from, port, _, message, mid = event.pull("modem_message")
	if (mid == "kpass") then
		other_pub = data.deserializeKey(message,"ec-public")
		receivedKey = true
	end
end
print("Resending...")
m.broadcast(64, pub.serialize(), "kpass")
print("Waiting...")
local _, _, from, port, _, message, mid = event.pull("modem_message")
print("Generating...")
local shared = data.md5(data.ecdh(priv,other_pub))
print("Making IV...")
local iv = data.random(16)
print("Sending...")
m.broadcast(64, data.encrypt("hello from "..component.computer.address,shared,iv),iv)
print("Waiting...")
local _, _, from, port, _, message, mid = event.pull("modem_message")
print(data.decrypt(shared,message,mid))


```
Say i have a network...

Bedrock
- Granite
  - Sand
    - Glass
	- Furnace
  - Sandstone
    - Pickaxe
	- Kelp
- Diorite
  - Bricks
    - Clay
	- Furnace
  - Coal
    - Birch Log
	- Charcoal
Plutonium
- Redstone
  - Lamp
    - Glowstone
  - Switch
    - Stone Button
	- Wodden Button
- Oak Log
  - Oak Planks
	- Oak Sapling
	- Grass Block
  - Birch Planks
	- Birch Leaves
	- Dirt
	
If i want to send something to someone from the same layer:

In [Plutonium.Oak Log.Birch Planks], [Dirt] will send [message] to [Birch Leaves]
the [message] goes up to the [Plutonium.Oak Log.Birch Planks] router and checks its children for anyone with [Birch Leaves]
it finds the target and sends the [message]

In [Plutonium.Redstone.Lamp], [Glowstone] wants to send to [Switch.Stone Button]
it sends its [message] upwards, and [Plutonium.Redstone.Lamp] checks for any children with [Switch]
there's no one named [Switch] under [Plutonium.Redstone.Lamp] so it sends it upward to [Plutonium.Redstone]
it checks for anyone named [Switch] and it finds the router with that designation. It forwards it to [Switch]
[Switch] absorbs the first part of the address which is [Switch.Stone Button] because it itself is [Switch] and the remaining target address is [Stone Button]. it checks if there's anyone named [Stone Button] and it sees the target and fowards the message to them.

Say, we have [Bedrock.Diorite.Coal.Charcoal], who wants to send it to [Plutonium.Redstone.Switch.Glowstone]. It sends it up to [Bedrock.Diorite.Coal], who sends it up to [Bedrock.Diorite], to [Bedrock], to the core router, who knows a child named [Plutonium], absorbs the first part of the address which becomes [Redstone.Switch.Glowstone] which becomes absorbed by the child [Redstone] into [Switch.Glowstone], which becomes absorbed by the child [Switch] as [Glowstone]. But uh oh, there's no one named Glowstone so it sends a 404 or whatever back to [Bedrock.Diorite.Coal.Charcoal]

would this concept work for a from-scratch networking system for OpenComputers?
Assume the Minecraft item names are correspondants to UUIDs of each computer, which is a long ass string that i'm not bothered to type
```



install
y

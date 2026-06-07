# Shipify

Manages enderstorages and provides the Shipify API.

---

# Installation

## Install Shipify CLI (Also installs library)

```lua
wget run https://raw.githubusercontent.com/Kromify-rcc/shipify-client/main/installer.lua
```

## Install Library Only

```lua
wget run https://raw.githubusercontent.com/Kromify-rcc/shipify-client/main/libinstaller.lua
```

---

# Library Usage

The Shipify library wraps ecnet2  and provides a API for interacting with shipify.

---

## Dependencies

* ecnet2 (auto installed when using installer)
* ccryptolib (auto installed when using installer)
* Wireless modem 
* Optional: cryptographic accelerator (recommended when getting transfer event data)

---

## Initialization Example

```lua
local shipify = require("shipify")

shipify.setKey("your-api-key")
shipify.setAddress("primary@user")

local function main()
    -- your code here
end


parallel.waitForAny(shipify.run,main)
```

---


# Shipify Transfer Events

Shipify has transfer notifications through events.

## Enabling Transfer Events

Transfer events are **disabled by default**.

You MUST enable them manually:

```lua
shipify.listenTransfers = true
```

Without this, the library will NOT emit any transfer events.

---


## Event Format

The `shipify_transfer` event provides a table with transfer details.

### Structure
Some internal fields are excluded from examples.

```lua
{
  transfers = {
    {
      transferred = number,
      fromSlot = number,
      item = string
    },
    ...
  },
  to = string,
  from = string
}
```

---

## Example Event (Multiple transfers)

```lua
{
  transfers = {
    {
      transferred = 64,
      fromSlot = 1,
      item = "minecraft:coal",
    },
    {
      transferred = 64,
      fromSlot = 2,
      item = "minecraft:coal",
    },
    {
      transferred = 64,
      fromSlot = 3,
      item = "minecraft:coal",
    },
    {
      transferred = 64,
      fromSlot = 4,
      item = "minecraft:coal",
    },
    {
      transferred = 64,
      fromSlot = 5,
      item = "minecraft:coal",
    },
    {
      transferred = 16,
      fromSlot = 6,
      item = "minecraft:coal",
    },
  },
  to = "primary@HerrKatzeGaming",
  from = "primary@SethGamer1223",
}
```

---

## Example Event (Single Transfer)

```lua
{
  transfers = {
    {
      transferred = 10,
      fromSlot = 1,
      item = "minecraft:golden_carrot",
    },
  },
  to = "primary@HerrKatzeGaming",
  from = "primary@SethGamer1223",
}
```

---

## Listening for Events

Once enabled:

```lua
local shipify = require("shipify")

shipify.setKey("your-api-key")
shipify.setAddress("primary@user")

shipify.listenTransfers = true
local function main()
    while true do
      local event, data = os.pullEvent("shipify_transfer")
    
      print("got items from:", data.from)
    
      for _, t in ipairs(data.transfers) do
        print(t.item, t.transferred)
      end
    end
end
parallel.waitForAny(main,shipify.run)
```

---

# API Functions

## shipify.setKey(key)

Sets API authentication key.

```lua
shipify.setKey("my-secret-key")
```

---

## shipify.setAddress(address)

Sets default sender address.

```lua
shipify.setAddress("primary@user")
```

---

## shipify.getEnderstorages(id)

Fetch all enderstorages owned by a user.

```lua
local res = shipify.getEnderstorages("player123")
```

---

## shipify.send(from, to, slot)

Send items between enderstorages. A default sender address can be set using shipify.setAddress(). If a default address is set, the from parameter may be nil.

```lua
shipify.send("primary@user", "other@user", 1)
```

---

## shipify.run()

connects to the shipify server and starts the ecnet2 daemon and transfer handler. Blocks indefinitely

```lua
shipify.run()
```

This must be running otherwise the library **will not** work. including transfer events.

---



# Technical Protocol

**Connection**
* Server Address: c76qTSo54lzNaqVyizQlM_pbHdHinhUFKU2mnIe19WE
* Protocol: shipify

## Structure
```lua
{
  key = "key",
  route = "",
  data = {}
}
````

---

## Routes

### getEnderstorages

```lua id="r1k2lm"
{
  route = "getEnderstorages",
  key = "key",
  data = {
    id = ""
  }
}
```

**Fields**

* **id**: The user's name or UUID

**Response**

```lua id="w8n3qp"
-- Success
{ ok = true, result = {} }

-- Failure
{ ok = false, error = "This user doesnt exist!" }
```

---

### send

```lua id="t6bz91"
{
  key= "",
  route = "send",
  data = {
    fromAddress = "",
    toAddress = "",
    slots = {}
  }
}
```

**Fields**

* **fromAddress**: Address you are sending from (`name@user`)
* **toAddress**: Full destination address (e.g., `primary@sethgamer1223`)
* **slots**: Table of slots or table of slots with range, e.g.:

```lua
{
  {1, 5}, --first slot send 5 items
  {10, 12} --10th slot send 12 items
}
```
```lua
{1,2,3,4,5,6} --send all of items in slots 1-6
```

**Response**

```lua id="p0x4de"
-- Success
{ ok = true }

-- Failures
{ ok = false, error = "From address invalid!" }
{ ok = false, error = "To address invalid!" }
{ ok = false, error = "From address does not exist!" }
{ ok = false, error = "To address does not exist!" }
{ ok = false, error = "Receiving enderstorage full." }
```

**Notes**

* Transfers are processed per slot range.
* Partial transfers can occur; if any item fails to fully transfer, the request returns `ok = false`.

---

# Admin

### canAddEnderstorage

```lua id="z7mf42"
{
  route = "canAddEnderstorage",
  key = "key",
  data = {
    id = "",
    frequency = {},
    name = ""
  }
}
```

**Fields**

* **id**: The user's name or UUID
* **frequency**: `{color1, color2, color3}`
* **name**: Desired name (case-insensitive, stored lowercase)

**Response**

```lua id="n3q8la"
-- Success
{ ok = true }

-- Failures
{ ok = false, error = "You already have this frequency!" }
{ ok = false, error = "You already have a box with this name!" }
```

---

### addPlacementData

```lua id="c2v9hs"
{
  route = "addPlacementData",
  key = "key",
  data = {
    ownerUUID = "",
    user = "",
    frequency = {},
    name = ""
  }
}
```

**Fields**

* **ownerUUID**: UUID of the owner
* **user**: Username of the owner
* **frequency**: `{color1, color2, color3}`
* **name**: Name of the enderstorage (stored lowercase)

**Response**

```lua id="m5k1xr"
-- Success
{ ok = true }
```

---

## General Response Format

All routes return a table in this format:

```lua id="g8v2op"
-- Success
{ ok = true, result = any? }

-- Failure
{ ok = false, error = "error message" }
```


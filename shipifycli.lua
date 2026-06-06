local cmd = require("cmd")
local shipifyLib = require("shipifyLib")

local data = {}
local datafile = fs.open(".shipify", "r")
if datafile then
    data = textutils.unserialize(datafile.readAll())
    shipifyLib.setKey(data.key)
    if data.address then
        shipifyLib.setAddress(data.address)
    end
    datafile.close()
end


local function saveData()
    local file = fs.open(".shipify", "w")
    file.write(textutils.serialize(data))
    file.close()
end

local commands = {
    getenderstorage = {
        description = "Get a user's enderstorage addreses getenderstorage <user>",
        category = "general",
        aliases = { "find" },
        execute = function(args, context)
            local id = args[1]
            if not id then
                context.err("Usage: getenderstorage <user>")
                return
            end
            if not shipifyLib.key then
                context.err("API key not provided! use the setKey command")
                return
            end
            local result = shipifyLib.getEnderstorages(id)
            if result.error then
                context.err(result.err)
                return
            end
            local p = context.pager("Addresses")
            for _, data in ipairs(result.result) do
                p.print(data.boxName .. "@" .. data.ownerUser)
            end
            p.show()
        end
    },
    setkey = {
        description = "Set shipify API key",
        category = "general",
        execute = function(args, context)
            local key = args[1]
            if not key then
                context.err("Usage: setkey <apiKey>")
                return
            end
            if #key ~= 64 then
                context.err("Expected api key length of 64")
                return
            end
            shipifyLib.setKey(key)
            data.key = key
            saveData()
        end
    },
    setaddress = {
        description = "Set from address used in send.",
        category = "general",
        execute = function(args, context)
            local address = args[1]
            shipifyLib.setAddress(address)
            data.address = address
            saveData()
        end
    },
    send = {
        description = "Send items to another address! send <toaddress> <slot> <amount?>",
        category = "general",
        execute = function(args, context)
            if not shipifyLib.address then
                context.err("Please set from address with setaddress <address>")
                return
            end
            local toaddress = args[1]
            local slot = args[2]
            local amount = args[3]
            if not toaddress or not slot or not tonumber(slot) then
                context.err("Usage: send <toaddress> <slot> <amount?>")
                return
            end
            if amount and not tonumber(amount) then
                context.err("amount is not a number")
                return
            end
            local result = shipifyLib.send(nil, toaddress, { { slot, amount } })
            if result.error then
                context.err(result.error)
            else
                context.succ("Transfer complete!")
            end
        end,
    },
}

local function run()
    cmd("Shipify", "1.0.0", commands)
end

parallel.waitForAll(run, shipifyLib.run)

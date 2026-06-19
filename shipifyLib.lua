local ecnet2 = require("ecnet2")
local random = require("ccryptolib.random")
local ccryptolib = require("ccryptolib.ed25519")
local expect = require("cc.expect").expect
local postHandle = assert(http.get("https://www.uuidgenerator.net/api/version4"))
local data = postHandle.readAll()
local accelerator = peripheral.find("cryptographic_accelerator")
postHandle.close()
random.init(data)
local wirelessModem = peripheral.find("modem",function(name,wrapped)
    return wrapped.isWireless()
end)
local wirelessModemName = peripheral.getName(wirelessModem)
wirelessModem.open(3)

ecnet2.open(wirelessModemName)
local id = ecnet2.Identity("/.ecnet2")
local protocol = id:Protocol {
    -- Programs will only see packets sent on the same protocol.
    -- Only one active listener can exist at any time for a given protocol name.
    name = "shipify",

    -- Objects must be serialized before they are sent over.
    serialize = textutils.serialize,
    deserialize = textutils.unserialize,
}

local listener = protocol:listen()
local server = "c76qTSo54lzNaqVyizQlM_pbHdHinhUFKU2mnIe19WE="

local api = {
  listenTransfers = false,

}

local function verifyPacket(message)
    if not message.msg or not message.signature then  return false end
    if accelerator then
        local succ,result = pcall(function() return accelerator.verify(message.msg,message.signature,api.publicKey) end)
        if not succ or not result then return false end
    else
        local succ,result = pcall(function() return ccryptolib.verify(api.publicKey,message.msg,message.signature) end)
        if not succ or not result then return false end
    end
    return true
end

local function daemon()
    api.connection = protocol:connect(server, wirelessModemName)
    local greeting = select(2, api.connection:receive())
    api.publicKey = greeting.pubKey
    while true do
        if api.listenTransfers then
          local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
          if channel == 3 and side == wirelessModemName and message.msg then
              if verifyPacket(message) then
                  os.queueEvent("shipify_transfer",textutils.unserializeJSON(message.msg))
              end
          end
        else
          os.sleep(1)
        end
    end
end

function api.getEnderstorages(id)
    assert(api.key,"Set api key with .setKey(key)")
    expect(1,id,"string")
    api.connection:send({
        key = api.key,
        route = "getEnderstorages",
        data = {
            id=id
        }
    })
    return select(2, api.connection:receive())
end

function api.setType(name,type,frequency)
    assert(api.key,"Set api key with .setKey(key)")
    expect(1,name,"string")
    expect(2,type,"string")
    expect(3,frequency,"table")
    if #frequency ~= 3 then
        error("invalid frequency length")
    end
    local validTypes = {
            ["send"] = true,
            ["rec"] = true,
            ["rec/send"] = true
        }
        if not validTypes[type] then
            error("invalid type. send,rec,rec/send")
        end
    api.connection:send({
        key = api.key,
        route = "changeType",
        data = {
            name=name,
            frequency=frequency,
            type = type
        }
    })
    return select(2,api.connection:receive())
end

function api.send(from,to,slot)
    expect(1,from,"string","nil")
    expect(2,to,"string")
    expect(3,slot,"number","table")

    if not from then
        if not api.address then error("Please provide address as arg #1 or use .setAddress(address)") end
        from = api.address
    end

    local slots = {}
    if type(slot) == "number" then
        slots[1] = slot
    else
        slots = slot
    end

    api.connection:send({
        key = api.key,
        route = "send",
        data = {
            fromAddress = from,
            toAddress = to,
            slots = slots
        }
    })
    return select(2, api.connection:receive())
end

--set a default address to use
function api.setAddress(address)
    api.address = address
end

function api.setKey(key)
    api.key = key
end

function api.run()
    parallel.waitForAll(ecnet2.daemon,daemon)
end

return api
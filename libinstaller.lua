local function installFile(name, url, force)
    if force and fs.exists(name) then
        fs.delete(name)
    end

    if not fs.exists(name) then
        shell.run("wget", url, name)
    end
end

local function installScript(dir, url)
    if not fs.exists(dir) then
        shell.run("wget", "run", url)
    end
end


installFile("shipifyLib.lua",
    "https://raw.githubusercontent.com/Kromify-rcc/shipify-client/main/shipifyLib.lua",
    true)

installScript("ccryptolib",
    "https://github.com/migeyel/ccryptolib/releases/download/v1.2.2/install.lua")

installScript("ecnet2",
    "https://github.com/migeyel/ecnet/releases/download/v2.1.0/install.lua")

print("Shipify lib has been installed!")

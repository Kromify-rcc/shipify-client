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

installFile("shipifycli.lua",
    "https://raw.githubusercontent.com/Kromify-rcc/shipify-client/main/shipifycli.lua",
    true)

installFile("cmd.lua",
    "https://raw.githubusercontent.com/Twijn/cc-misc/main/util/cmd.lua")

installFile("pager.lua",
    "https://raw.githubusercontent.com/Twijn/cc-misc/main/util/pager.lua")

installScript("ccryptolib",
    "https://github.com/migeyel/ccryptolib/releases/download/v1.2.2/install.lua")

installScript("ecnet2",
    "https://github.com/migeyel/ecnet/releases/download/v2.1.0/install.lua")
print("Shipify CLI has been installed! run shipifycli.lua")

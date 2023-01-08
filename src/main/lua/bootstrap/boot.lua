-- Downloads, saves and boots a program from Github

if filesystem.initFileSystem("/dev") == false then
    computer.panic("Cannot initialize /dev")
end

drives = filesystem.childs("/dev")

for _, drive in pairs(drives) do
    if drive ~= "serial" then
        filesystem.mount("/dev/"..drive, "/")
        break
    end
    computer.panic("No drive found to mount")
end

-- get internet card
local card = computer.getPCIDevices(findClass("FINInternetCard"))[1]

local baseUrl = "https://raw.githubusercontent.com/nielsutrecht/ficsit-networks/master/src/main/lua/"

function save(file, name)
    local req = card:request(baseUrl .. file, "GET", "")
    local _, code = req:await()

    local file = filesystem.open(name, "w")
    file:write(code)
    file:close()
end

save("examples/require.lua", "program.lua")
save("examples/testlib.lua", "testlib.lua")

-- load the library from the file system and use it
filesystem.loadFile("testlib.lua")

filesystem.doFile("program.lua")

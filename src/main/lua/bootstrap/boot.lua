-- get internet card
local card = computer.getPCIDevices(findClass("FINInternetCard"))[1]

local baseUrl = "https://raw.githubusercontent.com/nielsutrecht/ficsit-networks/master/src/main/lua/"

-- get library from internet
local req = card:request(baseUrl .. "/examples/hello.lua", "GET", "")
local _, code = req:await()

setEEPROM(code)
reset()
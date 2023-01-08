


local card = computer.getPCIDevices(findClass("FINInternetCard"))[1]

local req = card:request("https://api.ipify.org/?format=text", "GET", "")
local _, ip = req:await()
print(ip)

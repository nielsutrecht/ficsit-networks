-- get first T1 GPU avialable from PCI-Interface
local gpu = computer.getPCIDevices(findClass("GPUT1"))[1]
if not gpu then
 error("No GPU T1 found!")
end

-- get first Screen-Driver available from PCI-Interface
local screen = computer.getPCIDevices(findClass("FINComputerScreen"))[1]
-- if no scren found, try to find large screen from component network
if not screen then
 local comp = component.findComponent(findClass("Screen"))[1]
 if not comp then
  error("No Screen found!")
 end
 screen = component.proxy(comp)
end

-- setup gpu
gpu:bindScreen(screen)
w,h = gpu:getSize()

-- clean screen
gpu:setBackground(0,0,0,0)
gpu:fill(0,0,w,h," ")

data = {0}

function getData(i)
 d = data[i]
 if not d then
  d = math.random(h)
  data[i] = d
 end
 return d
end

p = 0

function printScreen()
 gpu:setBackground(0, 0, 0, 0)
 gpu:fill(0, 0, w, h, " ")
 gpu:setBackground(1, 1, 1, 1)
 for i = 0, w - 1, 1 do
  x = (p + i) / 10.0
  x1 = math.floor(x)
  x2 = x1 + 1
  y1 = getData(math.floor(x1))
  y2 = getData(math.floor(x2))
  d = y1 + ((x - x1) * ((y2 - y1) / (x2 - x1)))
  d = math.floor(d)
  gpu:setText(i, d, " ")
 end
 gpu:flush()
end

while true do
 event.pull(0.05)
 printScreen()
 p = p + 1
end

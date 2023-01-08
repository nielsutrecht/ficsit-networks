local gpu = computer.getPCIDevices(findClass("GPUT1"))[1]
if not gpu then
    error("No GPU T1 found!")
end

local comp = component.findComponent(findClass("Screen"))[1]
if not comp then
    error("No Screen found!")
end
local screen = component.proxy(comp)

comp = component.findComponent("fuel panel")[1]
if not comp then
    error("No Panel found!")
end

local panel = component.proxy(comp)

function findBlenders()
    local blenders = component.proxy(component.findComponent("blender"))
    if not blenders then
        error("Could not reach blenders")
    end

    table.sort(blenders, function (b1, b2) return b1.nick < b2.nick end )

    return blenders
end

local blenders = findBlenders()

gpu:bindScreen(screen)
w,h = gpu:getSize()

-- clean screen
gpu:setBackground(0,0,0,0)
gpu:fill(0,0,w,h," ")

function update()
 gpu:setBackground(0, 0, 0, 0)
 gpu:fill(0, 0, w, h, " ")

 for i, blender in ipairs(blenders) do
      local state = blenderState(blender)
      printScreen(i, blender, state)
      updatePanel(i, blender, state)
  end

 gpu:flush()
end

function printScreen(i, b, state)
      if b.standby then
        gpu:setForeground(1, 0, 0, 1)
      else
        gpu:setForeground(0, 1, 0, 1)
      end

     gpu:setText(0, i, state["state"])
end

function updatePanel(i, b, state)
      local row = 10 - i + 1
      local button = panel:getModule(0, row)
      local gaugeOil = panel:getModule(1, row)
      local gaugeWater = panel:getModule(2, row)
      local gaugeFuel = panel:getModule(3, row)

      gaugeOil:setColor(0.8,0,1,0)
      gaugeOil:setBackgroundColor(1,1,1,0)
      gaugeOil.percent = state["heavy_oil"] / 50.0

      gaugeWater:setColor(0,0,1,0)
      gaugeWater:setBackgroundColor(1,1,1,0)
      gaugeWater.percent = state["water"] / 50.0

      gaugeFuel:setColor(1,0.4,0,0)
      gaugeFuel:setBackgroundColor(1,1,1,0)
      gaugeFuel.percent = state["fuel"] / 50.0

      if b.standby then
        button:setColor(1,0,0,0)
      else
        button:setColor(0,1,0,0)
      end
end


function blenderState(b)
    local state = {}
    state["number"] = string.sub(b.nick, 8)
    state["progress_percent"] = math.floor(b.progress * 100 + 0.5) .. "%"

    local inv = b:getInventories()

    state["heavy_oil"] = invContents(inv[1], 0)  / 1000.0
    state["water"] = invContents(inv[1], 1) / 1000.0
    state["fuel"] = invContents(inv[2], 0) / 1000.0

    state["state"] = string.format(
        "%s %4s %4.1f %4.1f %4.1f",
        state["number"],
        state["progress_percent"],
        state["heavy_oil"],
        state["water"],
        state["fuel"]
    )

  return state
end

function invContents(inv, stack)
    local stack = inv:getStack(stack)

    if stack.item.type then
        return stack.count
    end

    return 0
end

function printInv(b)
  local inv = b:getInventories()[1]

    for slotIndex = 0, inv.size - 1, 1 do
        local stack = inv:getStack(slotIndex)
        local type = stack.item.type

        if type then
          print(type.name .. ":" .. stack.count)
        end
    end
end

while true do
    event.pull(0.05)
    update()
end

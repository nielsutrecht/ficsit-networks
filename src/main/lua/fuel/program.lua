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

    table.sort(blenders, function(b1, b2)
        return b1.nick < b2.nick
    end)

    return blenders
end

blenderComponents = {}

function setupPanel(blenders)
    for _, blender in ipairs(blenders) do
        local state = blenderState(blender)

        blenderComponents[state["number"]] = {}
        blenderComponents[state["number"]]["blender"] = blender

        local button = panel:getModule(state["x"] + 0, state["y"])
        local gaugeOil = panel:getModule(state["x"] + 1, state["y"])
        local gaugeWater = panel:getModule(state["x"] + 2, state["y"])
        local gaugeFuel = panel:getModule(state["x"] + 3, state["y"])

        gaugeOil:setColor(0.8, 0, 1, 0)
        gaugeOil:setBackgroundColor(1, 1, 1, 0)
        gaugeWater:setColor(0, 0, 1, 0)
        gaugeWater:setBackgroundColor(1, 1, 1, 0)
        gaugeFuel:setColor(1, 0.4, 0, 0)
        gaugeFuel:setBackgroundColor(1, 1, 1, 0)

        blenderComponents[state["number"]]["button"] = button
        blenderComponents[state["number"]]["oil"] = gaugeOil
        blenderComponents[state["number"]]["water"] = gaugeWater
        blenderComponents[state["number"]]["fuel"] = gaugeFuel

        event.listen(button)
    end

    local bigGaugeOil = panel:getModule(0, 2)
    bigGaugeOil:setColor(0.8, 0, 1, 0)
    bigGaugeOil:setBackgroundColor(1, 1, 1, 0)

    local bigGaugeWater = panel:getModule(2, 2)

    bigGaugeWater:setColor(0, 0, 1, 0)
    bigGaugeWater:setBackgroundColor(1, 1, 1, 0)

    local bigGaugeFuel = panel:getModule(4, 2)
    bigGaugeFuel:setColor(1, 0.4, 0, 0)
    bigGaugeFuel:setBackgroundColor(1, 1, 1, 0)

end

local blenders = findBlenders()

gpu:bindScreen(screen)
gpu:setSize(50, 20)
w, h = gpu:getSize()

-- clean screen
gpu:setBackground(0, 0, 0, 0)
gpu:fill(0, 0, w, h, " ")

function update()
    gpu:setBackground(0, 0, 0, 0)
    gpu:fill(0, 0, w, h, " ")

    local header = string.format(
        "%2s %4s %4s %4s %4s %4s",
        "#",
        "Prog",
        "Prod",
        "Oil",
        "Water",
        "Fuel"
    )

    gpu:setForeground(1, 1, 1, 1)
    gpu:setText(0, 0, header)

    local c = 0
    local oil = 0
    local water = 0
    local fuel = 0

    for i, blender in ipairs(blenders) do
        local state = blenderState(blender)
        printScreen(i, blender, state)
        updatePanel(i, blender, state)

        c = c + 1
        oil = oil + state["heavy_oil"] / 50
        water = water + state["water"] / 50
        fuel = fuel + state["fuel"] / 50
    end

    updateBig(oil / c, water / c, fuel / c)

    gpu:flush()
end

function printScreen(i, b, state)
    if b.standby then
        gpu:setForeground(1, 0, 0, 1)
    elseif b.productivity < 0.95 then
        gpu:setForeground(1, 0.5, 0, 1)
    else
        gpu:setForeground(0, 1, 0, 1)
    end

    gpu:setText(0, i + 1, state["state"])
end

function updatePanel(i, b, state)

    local button = blenderComponents[state["number"]]["button"]
    local gaugeOil = blenderComponents[state["number"]]["oil"]
    local gaugeWater = blenderComponents[state["number"]]["water"]
    local gaugeFuel = blenderComponents[state["number"]]["fuel"]

    gaugeOil.percent = state["heavy_oil"] / 50.0
    gaugeWater.percent = state["water"] / 50.0
    gaugeFuel.percent = state["fuel"] / 50.0

    if b.standby then
        button:setColor(1, 0, 0, 0.1)
    elseif b.productivity < 0.95 then
        button:setColor(1, 0.5, 0, 0.1)
    else
        button:setColor(0, 1, 0, 0.1)
    end
end

function updateBig(oil, water, fuel)
    local bigGaugeOil = panel:getModule(0, 2)
    bigGaugeOil.percent = oil

    local bigGaugeWater = panel:getModule(2, 2)
    bigGaugeWater.percent = water

    local bigGaugeFuel = panel:getModule(4, 2)
    bigGaugeFuel.percent = fuel
end

function blenderState(b)
    local state = {}

    state["number"] = tonumber(string.sub(b.nick, 8))

    -- Panel component locations
    state["y"] = (10 - ((state["number"] - 1) % 6))
    if state["number"] > 6 then
        state["x"] = 7
    else
        state["x"] = 0
    end

    state["progress_percent"] = math.floor(b.progress * 100 + 0.5) .. "%"
    state["product_percent"] = math.floor(b.productivity * 100 + 0.5) .. "%"

    local inv = b:getInventories()

    state["heavy_oil"] = invContents(inv[1], 0) / 1000.0
    state["water"] = invContents(inv[1], 1) / 1000.0
    state["fuel"] = invContents(inv[2], 0) / 1000.0

    state["state"] = string.format(
        "%2s %4s %4s %4.1f %4.1f %4.1f",
        state["number"],
        state["progress_percent"],
        state["product_percent"],
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

function handleEvent(e, s)
    for _, c in ipairs(blenderComponents) do
        if s == c["button"] then
            c["blender"].standby = not c["blender"].standby
            local state = c["blender"].standby and "standby" or "on"
            print("Toggled '" .. c["blender"].nick .. "' to " .. state)
        end
    end
end

setupPanel(blenders)
event.clear()

while true do
    local e, s = event.pull(0.05)

    if e then
        handleEvent(e, s)
    end
    update()
end

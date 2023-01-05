local containerIDs = component.findComponent(findClass("FGBuildableStorage"))
local containers = component.proxy(containerIDs)

local sum = {}
local types = {}
for _, container in ipairs(containers) do
    local inventory = container:getInventories()[1]
    for slotIndex = 0, inventory.size - 1, 1 do
        local stack = inventory:getStack(slotIndex)
        local type = stack.item.type

        if type then
            local itemCount = sum[type.hash]
            itemCount = itemCount or 0
            itemCount = itemCount + stack.count
            sum[type.hash] = itemCount
            types[type.hash] = type
        end
    end
end

for typeHash, count in pairs(sum) do
    print("Item \"" .. types[typeHash].name .. "\" " .. count .. "x")
end

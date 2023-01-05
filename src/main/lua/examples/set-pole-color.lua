local poleIDs = component.findComponent(findClass("IndicatorPole"))

local poles = component.proxy(poleIDs)

for _, pole in ipairs(poles) do
    pole:setColor(1.0, 0.0, 0.0, 1.0)
end

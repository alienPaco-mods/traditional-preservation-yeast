-- Traditional Preservation (Yeast) B42: keeps the Fermenting Shelf at five cultures. Vanilla limits
-- adding by free output slots, but each culture here needs two of them.
require "Entity/ISUI/Components/Crafting/ISCraftLogicPanel"
require "Entity/ISUI/Components/Crafting/ISWidgetCraftLogicOutputProgress"

local SPRITE_PREFIX = "traditionalpreservationyeast_01_"
local ITEMS_PER_CULTURE = 2

local vanillaItemSlotAddItems = ISCraftLogicPanel.ItemSlotAddItems

local function isShelf(entity)
    local sprite = entity and entity:getSprite()
    return sprite and string.sub(sprite:getName(), 1, #SPRITE_PREFIX) == SPRITE_PREFIX
end

local function cultureRoom(component, resource)
    return math.floor(component:getFreeOutputSlotCount() / ITEMS_PER_CULTURE) - resource:storedSize()
end

-- Vanilla's ItemSlotAddItems with cultureRoom in place of its limit, because each queued action
-- has to re-check it when it runs. Compare this with vanilla after a game update.
local function addToShelf(player, entity, itemSlot, itemList, component)
    if #itemList == 0 or not ISEntityUI.WalkToEntity(player, entity) then return end

    local maxItems = math.min(itemSlot.resource:getFreeItemCapacity(), cultureRoom(component, itemSlot.resource))
    for index, item in ipairs(itemList) do
        if index <= maxItems then
            local action = ISItemSlotAddAction:new(player, entity, item, itemSlot.resource, itemSlot)
            action.component = component
            action.canAddItem = function(self) return cultureRoom(self.component, self.resource) > 0 end
            ISTimedActionQueue.add(action)
        end
    end
end

function ISCraftLogicPanel.ItemSlotAddItems(player, entity, itemSlot, itemList, component)
    if not isShelf(entity) then
        return vanillaItemSlotAddItems(player, entity, itemSlot, itemList, component)
    end

    if TraditionalPreservationYeastShelf then TraditionalPreservationYeastShelf.track(entity) end
    addToShelf(player, entity, itemSlot, itemList, component)
end

-- Vanilla's popup on a running culture goes by the recipe's time alone, so it gets the real time left at
-- the shelf's temperature instead. Other stations' slots are left to whatever was there before.
local vanillaProgressItems = ISWidgetCraftLogicOutputProgress.updateProgressItems
local TOOLTIP_PADDING = 5
local TOOLTIP_MIN_WIDTH = 150
local SLOW_RATE = 0.5
local PLACE_TEXT = { Open = "IGUI_TraditionalPreservationYeast_Open", Sheltered = "IGUI_TraditionalPreservationYeast_Roof", Basement = "IGUI_TraditionalPreservationYeast_Basement" }

-- The game's translator reads a finished line again as a format pattern, so numbers go in here.
local function say(key, ...)
    local values = { ... }
    local tokens = {}
    for index = 1, select("#", ...) do tokens[index] = "@" .. index .. "@" end
    return (string.gsub(getText(key, unpack(tokens)), "@(%d)@", function(index) return tostring(values[tonumber(index)]) end))
end

local function addLine(layout, label, value, r, g, b)
    local item = layout:addItem()
    item:setLabel(getText(label) .. ":", 1, 1, 0.8, 1)
    item:setValue(value, r or 1, g or 1, b or 1, 1)
end

local function drawCultureTooltip(slot, tooltip)
    local data = slot.craftRecipeData
    -- A culture that has just finished hands its data back to the engine's pool before the slot goes.
    local recipe = data and data:getRecipe()
    if not recipe then return end
    local status = TraditionalPreservationYeast.batchStatus(data:getModData(), recipe:getTime() / 3600, TraditionalPreservationYeast.getLedger())
    local title = getText("EC_CraftLogic_Progress")
    tooltip:DrawText(tooltip:getFont(), title, TOOLTIP_PADDING, TOOLTIP_PADDING, 1, 1, 0.8, 1)
    tooltip:adjustWidth(TOOLTIP_PADDING, title)
    local layout = tooltip:beginLayout()
    addLine(layout, "IGUI_TraditionalPreservationYeast_Progress", string.format("%.0f", status.progress * 100) .. "%")
    local whole = math.ceil(status.hoursLeft)
    addLine(layout, "IGUI_TraditionalPreservationYeast_TimeLeft", say("IGUI_TraditionalPreservationYeast_Time", math.floor(whole / 24), whole % 24))
    addLine(layout, "IGUI_TraditionalPreservationYeast_Temperature", say(PLACE_TEXT[status.place], string.format("%.0f", status.temperature)))
    local rate = string.format("%.0f", status.rate * 100) .. "%"
    if status.rate < SLOW_RATE then
        addLine(layout, "IGUI_TraditionalPreservationYeast_Rate", rate, 1, 0.7, 0.4)
    else
        addLine(layout, "IGUI_TraditionalPreservationYeast_Rate", rate)
    end
    local bottom = layout:render(TOOLTIP_PADDING, TOOLTIP_PADDING + tooltip:getLineSpacing(), tooltip)
    tooltip:endLayout(layout)
    tooltip:setHeight(bottom + TOOLTIP_PADDING)
    tooltip:setWidth(math.max(tooltip:getWidth(), TOOLTIP_MIN_WIDTH))
end

function ISWidgetCraftLogicOutputProgress:updateProgressItems()
    vanillaProgressItems(self)
    for _, slot in ipairs(self.progressItems:getItemSlots()) do
        local recipe = slot.craftRecipeData and slot.craftRecipeData:getRecipe()
        if recipe and string.gsub(recipe:getName(), "^.*%.", "") == "FermentCulture" then
            slot.drawTooltip = drawCultureTooltip
        end
    end
end

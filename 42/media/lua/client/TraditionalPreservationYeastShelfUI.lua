-- Traditional Preservation (Yeast) B42: keeps the Fermenting Shelf at five cultures. Vanilla limits
-- adding by free output slots, but each culture here needs two of them. Also the shelf's popups.
require "Entity/ISUI/Components/Crafting/ISCraftLogicPanel"
local UI = require "TraditionalPreservationYeast/Core/UI"
local Tiles = require "TraditionalPreservationYeast/Tiles"

local SPRITE_PREFIX = Tiles.PREFIX
local ITEMS_PER_CULTURE = 2

local function isShelf(entity)
    local sprite = entity and entity:getSprite()
    return sprite and string.sub(sprite:getName(), 1, #SPRITE_PREFIX) == SPRITE_PREFIX
end

local function cultureRoom(component, resource)
    return math.floor(component:getFreeOutputSlotCount() / ITEMS_PER_CULTURE) - resource:storedSize()
end

-- queued lists the cultures already on their way in.
local function refusal(slot, item, queued)
    if cultureRoom(slot.component, slot.resource) <= #queued or slot.resource:getFreeItemCapacity() <= #queued then
        return "IGUI_TraditionalPreservationYeast_Full"
    end
    return nil
end

UI.slotRules{
    station = function(entity)
        return isShelf(entity) and entity:getComponent(ComponentType.CraftLogic) or nil
    end,
    refusal = refusal,
    added = function(entity)
        if TraditionalPreservationYeastShelf then TraditionalPreservationYeastShelf.track(entity) end
    end,
}

-- Vanilla's popup on a running culture goes by the recipe's time alone, so it gets the real time left at
-- the shelf's temperature instead.
local PLACE_TEXT = { Open = "IGUI_TraditionalPreservationYeast_Open", Sheltered = "IGUI_TraditionalPreservationYeast_Roof", Basement = "IGUI_TraditionalPreservationYeast_Basement" }

local function drawCultureTooltip(slot, tooltip)
    local data = slot.craftRecipeData
    local Y = TraditionalPreservationYeast
    local status = Y.batchStatus(data:getModData(), data:getRecipe():getTime() / 3600, Y.getLedger())
    UI.drawTooltip(tooltip, function(layout)
        UI.addLine(layout, "IGUI_TraditionalPreservationYeast_Progress", UI.percent(status.progress))
        UI.addLine(layout, "IGUI_TraditionalPreservationYeast_TimeLeft", UI.timeText(status.hoursLeft, "IGUI_TraditionalPreservationYeast_Time"))
        UI.addLine(layout, "IGUI_TraditionalPreservationYeast_Temperature", UI.say(PLACE_TEXT[status.place], string.format("%.0f", status.temperature)))
        UI.addRateLine(layout, "IGUI_TraditionalPreservationYeast_Rate", status.rate)
    end)
end

UI.progressTooltips({ FermentCulture = drawCultureTooltip })

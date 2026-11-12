-- Traditional Preservation (Yeast) B42: keeps the Fermenting Shelf at five cultures. Vanilla limits
-- adding by free output slots, but each culture here needs two of them. Also the shelf's popups and the info block
-- in its crafting window (TP Core's StationInfo).
require "Entity/ISUI/Components/Crafting/ISCraftLogicPanel"
local UI = require "TraditionalPreservationCore/UI"
local Station = require "TraditionalPreservationCore/Station"
local StationInfo = require "TraditionalPreservationCore/StationInfo"
local Weather = require "TraditionalPreservationCore/Weather"
local Tiles = require "TraditionalPreservationYeast/Tiles"

local ITEMS_PER_CULTURE = 2

local isShelf = Station.kinds(Tiles.PREFIX, Tiles.FACE_COUNT, { shelf = 0 })

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
local function drawCultureTooltip(slot, tooltip)
    local data = slot.craftRecipeData
    local Y = TraditionalPreservationYeast
    local status = Y.batchStatus(data:getModData(), data:getRecipe():getTime() / 3600, Y.getLedger())
    UI.drawTooltip(tooltip, function(layout)
        UI.addLine(layout, "IGUI_TraditionalPreservationYeast_Progress", UI.percent(status.progress))
        UI.addLine(layout, "IGUI_TraditionalPreservationYeast_TimeLeft", UI.timeText(status.hoursLeft, "IGUI_TraditionalPreservationYeast_Time"))
        UI.addLine(layout, "IGUI_TraditionalPreservationYeast_Temperature", UI.placeText(status.place, status.temperature))
        UI.addRateLine(layout, "IGUI_TraditionalPreservationYeast_Rate", status.rate)
    end)
end

UI.progressTooltips({ FermentCulture = drawCultureTooltip })

-- The shelf's block: where it stands, the temperature and rate there, a bar for each running batch and what waits.
-- A finished culture is one Yeast and one Empty Jar, so the larger count is the cultures not yet taken.
local function shelfInfo(entity)
    if not isShelf(entity) then return nil end
    local contents = StationInfo.contents(entity)
    if not contents then return nil end
    local Y = TraditionalPreservationYeast
    local ledger = Y.getLedger()
    local place = Y.placeOf(entity)
    local temperature = Weather.placeTemperature(ledger, place)
    local batches = {}
    for _, batch in ipairs(contents.batches) do
        local status = Y.batchStatus(batch.data:getModData(), batch.data:getRecipe():getTime() / 3600, ledger)
        table.insert(batches, { name = UI.say("IGUI_TraditionalPreservationYeast_InfoCultures", tostring(batch.count)),
            progress = status.progress, hoursLeft = status.hoursLeft })
    end
    local yeast, jars = 0, 0
    for _, item in ipairs(contents.finished) do
        if item:getFullType() == "Base.Yeast" then yeast = yeast + 1 else jars = jars + 1 end
    end
    return StationInfo.block({ place = place, temperature = temperature, rate = Y.cultureRate(temperature),
        batches = batches, numbered = true, waiting = #contents.waiting, finished = math.max(yeast, jars) })
end

StationInfo.add(shelfInfo)

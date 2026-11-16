-- Traditional Preservation (Yeast) B42: shows one jar on each Fermenting Shelf per culture it holds, coloured
-- by that culture's own timer. SpriteOverlayConfig can only show one sprite for the
-- first batch, so this reads every batch and layers a sprite for each jar.
if isClient() then return end

TraditionalPreservationYeastShelf = TraditionalPreservationYeastShelf or {}
local Station = require "TraditionalPreservationCore/Station"
local Weather = require "TraditionalPreservationCore/Weather"
local Tiles = require "TraditionalPreservationYeast/Tiles"

local SPRITE_PREFIX = Tiles.PREFIX
local FACE_COUNT = Tiles.FACE_COUNT
local shelfKind = Station.kinds(Tiles.PREFIX, Tiles.FACE_COUNT, { shelf = 0 })
local MAX_JARS = Tiles.JAR_SLOTS

local LOOK_FRESH, LOOK_HALFWAY, LOOK_DONE = Tiles.JAR_LOOKS.fresh, Tiles.JAR_LOOKS.halfway, Tiles.JAR_LOOKS.done
local HALFWAY_PROGRESS = 0.5

-- Oldest first: finished jars, then running batches by progress, then ones not started.
function TraditionalPreservationYeastShelf.jarLooks(waiting, batches, finished)
    local looks = {}
    for _ = 1, finished do table.insert(looks, LOOK_DONE) end

    table.sort(batches, function(a, b) return a.progress > b.progress end)
    for _, batch in ipairs(batches) do
        local look = batch.progress >= HALFWAY_PROGRESS and LOOK_HALFWAY or LOOK_FRESH
        for _ = 1, batch.count do table.insert(looks, look) end
    end

    for _ = 1, waiting do table.insert(looks, LOOK_FRESH) end
    while #looks > MAX_JARS do table.remove(looks) end
    return looks
end

-- The finished cultures still on the shelf (TraditionalPreservationYeast.finishedCultures).
local function countFinished(resources, logic)
    local fullTypes = {}
    local outputs = Station.itemSlots(resources, logic:getOutputsGroupName(), ResourceIO.Output)
    for i = 0, outputs:size() - 1 do
        local stored = outputs:get(i):getStoredItems()
        for j = 0, stored:size() - 1 do table.insert(fullTypes, stored:get(j):getFullType()) end
    end
    return TraditionalPreservationYeast.finishedCultures(fullTypes)
end

-- Also tells each running culture where its shelf stands, for its temperature.
local function readBatches(logic, uiLogic, shelf)
    local batches = {}
    local now = getGameTime():getWorldAgeHours()
    for craftData, items in pairs(uiLogic:getItemsInProgress()) do
        TraditionalPreservationYeast.notePlace(craftData:getModData(), shelf, now)
        local count = 0
        for _, amount in pairs(items) do
            count = count + tonumber(tostring(amount))
        end
        table.insert(batches, { progress = logic:getProgress(craftData), count = count })
    end
    return batches
end

-- The same numbering as jar_index in tools/build_shelf_tileset.py.
local function jarSprite(faceIndex, slot, look)
    return SPRITE_PREFIX .. (Tiles.FIRST_JAR + (look * MAX_JARS + slot) * FACE_COUNT + faceIndex)
end

local function refresh(shelf, sessionState)
    local resources = shelf:getComponent(ComponentType.Resources)
    local logic = shelf:getComponent(ComponentType.CraftLogic)
    local _, faceIndex = shelfKind(shelf)
    if not resources or not logic or not faceIndex then return end

    local uiLogic = Station.uiLogic(shelf, sessionState, logic)
    if not uiLogic then return end

    local waiting = Station.countItems(resources, logic:getInputsGroupName(), ResourceIO.Input)
    local looks = TraditionalPreservationYeastShelf.jarLooks(waiting, readBatches(logic, uiLogic, shelf), countFinished(resources, logic))
    local names = {}
    for slot, look in ipairs(looks) do names[slot] = jarSprite(faceIndex, slot - 1, look) end
    Station.showSprites(shelf, sessionState, faceIndex .. ":" .. table.concat(looks, ","), names)
end

local tracker = Station.tracker({ sprites = Tiles.STATIONS, refresh = refresh })

TraditionalPreservationYeastShelf.track = tracker.track

Weather.onReading(function(now, climate)
    local Y = TraditionalPreservationYeast
    Y.advance(Y.getLedger(), now, climate:getTemperature())
end)

tracker.start()

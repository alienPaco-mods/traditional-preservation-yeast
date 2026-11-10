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

local STATE_FRESH, STATE_HALFWAY, STATE_DONE = Tiles.JAR_STATES.fresh, Tiles.JAR_STATES.halfway, Tiles.JAR_STATES.done
local HALFWAY_PROGRESS = 0.5

-- Oldest first: finished jars, then running batches by progress, then ones not started.
function TraditionalPreservationYeastShelf.jarStates(waiting, batches, finished)
    local states = {}
    for _ = 1, finished do table.insert(states, STATE_DONE) end

    table.sort(batches, function(a, b) return a.progress > b.progress end)
    for _, batch in ipairs(batches) do
        local state = batch.progress >= HALFWAY_PROGRESS and STATE_HALFWAY or STATE_FRESH
        for _ = 1, batch.count do table.insert(states, state) end
    end

    for _ = 1, waiting do table.insert(states, STATE_FRESH) end
    while #states > MAX_JARS do table.remove(states) end
    return states
end

-- A finished culture is on the shelf until both its yeast and its jar are taken.
local function countFinished(resources, logic)
    local yeast, jars = 0, 0
    local outputs = Station.itemSlots(resources, logic:getOutputsGroupName(), ResourceIO.Output)
    for i = 0, outputs:size() - 1 do
        local stored = outputs:get(i):getStoredItems()
        for j = 0, stored:size() - 1 do
            if stored:get(j):getFullType() == "Base.Yeast" then
                yeast = yeast + 1
            else
                jars = jars + 1
            end
        end
    end
    return math.max(yeast, jars)
end

-- Also tells each running culture where its shelf stands, for its temperature.
local function readBatches(logic, uiLogic, place)
    local batches = {}
    for craftData, items in pairs(uiLogic:getItemsInProgress()) do
        craftData:getModData().place = place
        local count = 0
        for _, amount in pairs(items) do
            count = count + tonumber(tostring(amount))
        end
        table.insert(batches, { progress = logic:getProgress(craftData), count = count })
    end
    return batches
end

-- The same numbering as jar_index in tools/build_shelf_tileset.py.
local function jarSprite(faceIndex, slot, state)
    return SPRITE_PREFIX .. (Tiles.FIRST_JAR + (state * MAX_JARS + slot) * FACE_COUNT + faceIndex)
end

local function refresh(shelf, entry)
    local resources = shelf:getComponent(ComponentType.Resources)
    local logic = shelf:getComponent(ComponentType.CraftLogic)
    local _, faceIndex = shelfKind(shelf)
    if not resources or not logic or not faceIndex then return end

    local uiLogic = Station.uiLogic(shelf, entry, logic)
    if not uiLogic then return end

    local waiting = Station.countItems(resources, logic:getInputsGroupName(), ResourceIO.Input)
    local states = TraditionalPreservationYeastShelf.jarStates(waiting, readBatches(logic, uiLogic, Weather.placeOf(shelf)), countFinished(resources, logic))
    -- Shelves from before 0.3.0 show their jars as a single overlay.
    if shelf:hasOverlaySprite() then shelf:setOverlaySprite(nil) end
    local names = {}
    for slot, state in ipairs(states) do names[slot] = jarSprite(faceIndex, slot - 1, state) end
    Station.showSprites(shelf, entry, faceIndex .. ":" .. table.concat(states, ","), names)
end

local tracker = Station.tracker({ sprites = Tiles.STATIONS, refresh = refresh })

TraditionalPreservationYeastShelf.track = tracker.track

Weather.record(function(now, climate)
    local Y = TraditionalPreservationYeast
    Y.advance(Y.getLedger(), now, climate:getTemperature())
end)

tracker.start()

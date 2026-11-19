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
local LOOK_FED_RISING, LOOK_FED_DONE = Tiles.JAR_LOOKS.fedRising, Tiles.JAR_LOOKS.fedDone
local LOOK_COUNT = 0
for _ in pairs(Tiles.JAR_LOOKS) do LOOK_COUNT = LOOK_COUNT + 1 end
local HALFWAY_PROGRESS = 0.5

-- The look of a culture's jar: Tiles.JAR_KINDS by the jar it is in.
local function kindOf(jarType)
    return Tiles.JAR_KINDS[TraditionalPreservationYeast.jarKind(jarType)]
end

-- Each jar on the shelf as { look, kind }, oldest first: finished jars, then running batches by progress, then ones not
-- started. waiting and finished are lists of { jar = its type, fed = a fed (hopped) culture }; a batch is
-- { progress, count, jars = its jar types, fed }. A fed culture rises in one look and is done in another.
function TraditionalPreservationYeastShelf.jarLooks(waiting, batches, finished)
    local looks = {}
    for _, entry in ipairs(finished) do table.insert(looks, { entry.fed and LOOK_FED_DONE or LOOK_DONE, kindOf(entry.jar) }) end

    table.sort(batches, function(a, b) return a.progress > b.progress end)
    for _, batch in ipairs(batches) do
        local look = batch.fed and LOOK_FED_RISING or batch.progress >= HALFWAY_PROGRESS and LOOK_HALFWAY or LOOK_FRESH
        for i = 1, batch.count do table.insert(looks, { look, kindOf(batch.jars[i]) }) end
    end

    for _, entry in ipairs(waiting) do table.insert(looks, { entry.fed and LOOK_FED_RISING or LOOK_FRESH, kindOf(entry.jar) }) end
    while #looks > MAX_JARS do table.remove(looks) end
    return looks
end

-- The cultures in a group's slots, in order: { jar, fed }.
local FED_TYPES = { ["TraditionalPreservationYeast.FedCulture"] = true, ["TraditionalPreservationYeast.ActiveCultureHopped"] = true }
local function jarsIn(resources, groupName, io)
    local jars = {}
    local slots = Station.itemSlots(resources, groupName, io)
    for i = 0, slots:size() - 1 do
        local stored = slots:get(i):getStoredItems()
        for j = 0, stored:size() - 1 do
            local item = stored:get(j)
            table.insert(jars, { jar = TraditionalPreservationYeast.jarOf(item), fed = FED_TYPES[item:getFullType()] == true })
        end
    end
    return jars
end

-- Also tells each running culture where its shelf stands, for its temperature.
local function readBatches(logic, uiLogic, shelf)
    local batches = {}
    local now = getGameTime():getWorldAgeHours()
    for craftData, items in pairs(uiLogic:getItemsInProgress()) do
        local modData = craftData:getModData()
        TraditionalPreservationYeast.notePlace(modData, shelf, now)
        local count = 0
        for _, amount in pairs(items) do
            count = count + tonumber(tostring(amount))
        end
        table.insert(batches, { progress = logic:getProgress(craftData), count = count, jars = modData.jars or {}, fed = modData.fed })
    end
    return batches
end

-- The same numbering as jar_index in tools/build_shelf_tileset.py.
local function jarSprite(faceIndex, slot, look, kind)
    return SPRITE_PREFIX .. (Tiles.FIRST_JAR + ((kind * LOOK_COUNT + look) * MAX_JARS + slot) * FACE_COUNT + faceIndex)
end

local function refresh(shelf, sessionState)
    local resources = shelf:getComponent(ComponentType.Resources)
    local logic = shelf:getComponent(ComponentType.CraftLogic)
    local _, faceIndex = shelfKind(shelf)
    if not resources or not logic or not faceIndex then return end

    local uiLogic = Station.uiLogic(shelf, sessionState, logic)
    if not uiLogic then return end

    local waiting = jarsIn(resources, logic:getInputsGroupName(), ResourceIO.Input)
    local finished = jarsIn(resources, logic:getOutputsGroupName(), ResourceIO.Output)
    local looks = TraditionalPreservationYeastShelf.jarLooks(waiting, readBatches(logic, uiLogic, shelf), finished)
    local names, keys = {}, {}
    for slot, look in ipairs(looks) do
        names[slot] = jarSprite(faceIndex, slot - 1, look[1], look[2])
        keys[slot] = look[1] .. "/" .. look[2]
    end
    Station.showSprites(shelf, sessionState, faceIndex .. ":" .. table.concat(keys, ","), names)
end

local tracker = Station.tracker({ sprites = Tiles.STATIONS, refresh = refresh })

TraditionalPreservationYeastShelf.track = tracker.track

Weather.onReading(function(now, climate)
    local Y = TraditionalPreservationYeast
    Y.advance(Y.getLedger(), now, climate:getTemperature())
    Y.CULTURE_KEEPER.recordWeather(now, climate:getTemperature())
end)

tracker.start()

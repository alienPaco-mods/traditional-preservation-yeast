-- Traditional Preservation (Yeast) B42: the Fermenting Shelf in the world. Records the weather into the culture's
-- ledgers, brings every loaded shelf's jars up to now (TraditionalPreservationYeastShelf.lua) and shows each jar in its
-- own look and jar (glass, ceramic or glazed), one overlay a jar in the order they went on.
if isClient() then return end

TraditionalPreservationYeastWorld = TraditionalPreservationYeastWorld or {}
local World = TraditionalPreservationYeastWorld
local Station = require "TraditionalPreservationCore/Station"
local Weather = require "TraditionalPreservationCore/Weather"
local Tiles = require "TraditionalPreservationYeast/Tiles"

local Y = TraditionalPreservationYeast
local shelfKind = Station.kinds(Tiles.PREFIX, Tiles.FACE_COUNT, { shelf = 0 })
-- The same numbering as jar_index in tools/build_shelf_tileset.py: every look but the starts in each kind of jar, the
-- starts in glass only (a clay jar hides them and shows fresh).
function World.jarSprite(faceIndex, slot, look, kind)
    if look >= Tiles.GRID_LOOKS then
        if kind == Tiles.JAR_KINDS.glass then
            return Tiles.PREFIX .. (Tiles.FIRST_START_JAR + ((look - Tiles.GRID_LOOKS) * Tiles.JAR_SLOTS + slot) * Tiles.FACE_COUNT + faceIndex)
        end
        look = Tiles.JAR_LOOKS.fresh
    end
    return Tiles.PREFIX .. (Tiles.FIRST_JAR + ((kind * Tiles.GRID_LOOKS + look) * Tiles.JAR_SLOTS + slot) * Tiles.FACE_COUNT + faceIndex)
end

-- The overlays for a record's jars, and a key that changes when they do.
function World.jarSprites(record, faceIndex)
    local names, keys = {}, {}
    for slot, jar in ipairs(record.jars) do
        local look = Tiles.JAR_LOOKS[Y.jarLook(jar, jar.done / Y.jarHours(jar))]
        local kind = Tiles.JAR_KINDS[Y.jarKind(jar.jar)]
        names[slot] = World.jarSprite(faceIndex, slot - 1, look, kind)
        keys[slot] = look .. "/" .. kind
    end
    return names, faceIndex .. ":" .. table.concat(keys, ",")
end

local function newSessionState(isoObject)
    return shelfKind(isoObject) and {} or nil
end

local function refresh(shelf, sessionState)
    local _, faceIndex = shelfKind(shelf)
    if not faceIndex then return end
    local record = Y.shelfNow(shelf)
    local names, key = World.jarSprites(record, faceIndex)
    Station.showSprites(shelf, sessionState, key, names)
end

local tracker = Station.tracker({ sprites = Tiles.STATIONS, newSessionState = newSessionState, refresh = refresh, scan = true })

-- Brings a shelf up to now and redraws it at once (after a put, a refresh or a take). Returns its record.
function World.refresh(shelf)
    local sessionState = tracker.track(shelf)
    if sessionState then refresh(shelf, sessionState) end
    return Y.shelfOf(shelf)
end

Weather.onReading(function(now, climate)
    Y.advance(Y.getLedger(), now, climate:getTemperature())
    Y.CULTURE_KEEPER.recordWeather(now, climate:getTemperature())
end)

tracker.start()

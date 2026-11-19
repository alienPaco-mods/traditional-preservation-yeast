-- Traditional Preservation (Yeast): the Fermenting Shelf's record, one jar a culture, each on its own clock (TP Core's
-- station rule: pieces put on a station; ROADMAP section 12). It holds SHELF_JARS jars, kept in the shelf's movableData
-- (SHELF_KEY); the World steps it, the menu and Shelf Info put on, refresh and take off. Required by
-- TraditionalPreservationYeast.lua, whose Y it adds to.
-- A jar's work is a FluidAgeing age on the culture's ledger: hours at full speed at the shelf's place (frozen it
-- waits). A Fermenting Culture wants feeding: HUNGRY_HOURS of work after it was made or last refreshed it stops
-- (hungry), and OFF_HOURS after it has gone off and is only good for pouring out. Refresh the Cultures feeds every one
-- on the shelf at once (a use of flour and REFRESH_WATER_L of water a jar). What it was started with sets how long it
-- takes (STARTS: plain flour and water, fruit, potato water). A Fed Culture rises in RAISE_HOURS and wants no refresh.
-- Done, a jar keeps by place as Active Culture does (CULTURE_KEEPER, from the moment it was done) and goes Spent on
-- the shelf as off it.
TraditionalPreservationYeast = TraditionalPreservationYeast or {}
local Y = TraditionalPreservationYeast
local Station = require "TraditionalPreservationCore/Station"
local Fire = require "TraditionalPreservationCore/Fire"
local Weather = require "TraditionalPreservationCore/Weather"
local FluidAgeing = require "TraditionalPreservationCore/FluidAgeing"
local Uses = require "TraditionalPreservationCore/Uses"
local Container = require "TraditionalPreservationCore/Container"
local Tiles = require "TraditionalPreservationYeast/Tiles"

-- Save key in the shelf's movableData: never rename it once the mod is out. { jars = { jar ... }, nextId }; a jar is
-- { id, kind ("culture" or "fed"), jar (the jar's full type), start (STARTS), work (a FluidAgeing age), fedAt (work
-- hours at its last feed), done (hours of progress), off, keep (a FluidAgeing age on the keeper's ledger),
-- keptAtDone (keep's hours when it was done) }.
Y.SHELF_KEY = "tpyShelf"
Y.SHELF_JARS = Tiles.JAR_SLOTS
Y.HUNGRY_HOURS = 24
Y.OFF_HOURS = 72
Y.REFRESH_FLOUR = 1
Y.REFRESH_WATER_L = 0.1
-- A start's share of the sandbox's ferment time: fruit carries wild yeast on its skin, potato water feeds it starch.
Y.STARTS = { plain = 1, fruit = 0.8, potato = 0.7 }
-- On a culture item: what it was started with, and a run taken off the shelf before it was done.
Y.START_KEY = "tpyStart"
Y.RUN_KEY = "tpyRun"
Y.WORK = { process = Y.PROCESS, rate = function(celsius) return Y.cultureRate(celsius) end }

-- The record, made on first use.
function Y.shelfOf(station)
    local movableData = Station.movableData(station)
    local record = movableData[Y.SHELF_KEY]
    if not record then
        record = { jars = {}, nextId = 1 }
        movableData[Y.SHELF_KEY] = record
    end
    return record
end

function Y.jarHours(jar)
    if jar.kind == "fed" then return Y.RAISE_HOURS end
    return Y.FERMENT_HOURS * (Y.STARTS[jar.start] or 1)
end

local function outputOf(jar)
    return jar.kind == "fed" and Y.HOPPED or Y.ACTIVE
end

-- Days the jar has kept since it was done.
function Y.jarKeptDays(jar)
    if not jar.keptAtDone then return 0 end
    return math.max(jar.keep.age - jar.keptAtDone, 0) / 24
end

function Y.jarDone(jar)
    return jar.keptAtDone ~= nil
end

-- "working", "hungry", "off", "done" or "spent".
function Y.jarState(jar)
    if jar.off then return "off" end
    if Y.jarDone(jar) then
        return Y.jarKeptDays(jar) >= Y.CULTURE_DAYS[outputOf(jar)][2] and "spent" or "done"
    end
    if jar.kind == "culture" and jar.work.age - jar.fedAt >= Y.HUNGRY_HOURS then return "hungry" end
    return "working"
end

-- Brings one jar up to now at place. Its progress counts only while it is fed; done part way through a stretch, its
-- keeping starts at that point of the stretch, so a long catch-up keeps it as short looks would.
function Y.advanceJar(jar, now, place, fire, station, ledger, keepLedger)
    local workWas, keptWas = jar.work.age, jar.keep.age
    FluidAgeing.advance(jar.work, Y.WORK, ledger, now, place)
    FluidAgeing.advance(jar.keep, Y.CULTURE_KEEPER.ageing, keepLedger, now, place)
    if station then
        FluidAgeing.noteFire(jar.work, fire, station, now)
        FluidAgeing.noteFire(jar.keep, fire, station, now)
    end
    if jar.off or Y.jarDone(jar) then return end
    local hours = Y.jarHours(jar)
    if jar.done >= hours then
        jar.keptAtDone = keptWas
        return
    end
    local fedUntil = jar.kind == "culture" and jar.fedAt + Y.HUNGRY_HOURS or math.huge
    local gain = math.max(math.min(jar.work.age, fedUntil) - workWas, 0)
    if jar.done + gain >= hours then
        local worked = jar.work.age - workWas
        local share = worked > 0 and (hours - jar.done) / worked or 1
        jar.done = hours
        jar.keptAtDone = keptWas + (jar.keep.age - keptWas) * share
        return
    end
    jar.done = jar.done + gain
    if jar.kind == "culture" and jar.work.age - jar.fedAt >= Y.OFF_HOURS then jar.off = true end
end

-- Where the shelf stands: by a fire, banked embers, or a Weather place; and the fire.
function Y.shelfPlace(station)
    return Fire.placeOf(station)
end

-- Brings every jar on the shelf up to now. Returns the record, the place and the fire.
function Y.shelfNow(station, now, place, fire)
    now = now or getGameTime():getWorldAgeHours()
    if not place then place, fire = Y.shelfPlace(station) end
    local record = Y.shelfOf(station)
    local ledger, keepLedger = Y.getLedger(), Y.CULTURE_KEEPER.ledger()
    for _, jar in ipairs(record.jars) do Y.advanceJar(jar, now, place, fire, station, ledger, keepLedger) end
    record.place = place
    return record, place, fire
end

function Y.shelfRoom(record)
    return Y.SHELF_JARS - #record.jars
end

-- The culture types the shelf takes.
Y.SHELF_TAKES = { [Y.FERMENTING] = true, [Y.FED] = true }

-- A Fermenting Culture's run off the shelf (RUN_KEY): { done, fedAt, work }. Its work goes on counting wherever it
-- is, so it goes hungry, and off, off the shelf too; only its progress waits for the shelf. Made at its recipe (Y.startRun)
-- or when it comes off part way.
function Y.startRun(item, now, place)
    item:getModData()[Y.RUN_KEY] = { done = 0, fedAt = 0, work = FluidAgeing.newFluidAge(Y.WORK, Y.getLedger(), now, place) }
end

-- The run brought up to now, at the place it was last seen in (where it was made or came off); a fed culture's has
-- no work. Nil for one never on the shelf and made before runs were kept.
local function runNow(item, now)
    local run = item:getModData()[Y.RUN_KEY]
    if run and run.work then FluidAgeing.advance(run.work, Y.WORK, Y.getLedger(), now, run.work.place) end
    return run
end

-- Puts a carried culture on the shelf, as it was if it came off part way. A culture left unfed too long off the shelf
-- goes on gone off. Returns the jar, or nil when full.
function Y.putJar(record, item, now, place)
    if Y.shelfRoom(record) <= 0 or not Y.SHELF_TAKES[item:getFullType()] then return nil end
    local modData = item:getModData()
    local run = runNow(item, now)
    local work = FluidAgeing.newFluidAge(Y.WORK, Y.getLedger(), now, place)
    local fedAt = 0
    if run and run.work then
        work.age, fedAt = run.work.age, run.fedAt
    end
    local jar = {
        id = record.nextId, kind = item:getFullType() == Y.FED and "fed" or "culture", jar = Y.jarOf(item),
        start = modData[Y.START_KEY] or "plain", work = work, fedAt = fedAt, done = run and run.done or 0,
        keep = FluidAgeing.newFluidAge(Y.CULTURE_KEEPER.ageing, Y.CULTURE_KEEPER.ledger(), now, place),
    }
    if jar.kind == "culture" and work.age - fedAt >= Y.OFF_HOURS then jar.off = true end
    record.nextId = record.nextId + 1
    table.insert(record.jars, jar)
    return jar
end

function Y.jarById(record, id)
    for _, jar in ipairs(record.jars) do
        if jar.id == id then return jar end
    end
end

-- Takes the jar off the record. Returns it, or nil.
function Y.takeJar(record, id)
    for index, jar in ipairs(record.jars) do
        if jar.id == id then return table.remove(record.jars, index) end
    end
end

-- The jars Refresh the Cultures feeds: Fermenting Cultures neither done nor gone off.
function Y.refreshable(record)
    local jars = {}
    for _, jar in ipairs(record.jars) do
        if jar.kind == "culture" and not jar.off and not Y.jarDone(jar) then table.insert(jars, jar) end
    end
    return jars
end

-- Feeds every refreshable jar now (the record brought up to now first). Returns how many.
function Y.refreshJars(record)
    local jars = Y.refreshable(record)
    for _, jar in ipairs(jars) do jar.fedAt = jar.work.age end
    return #jars
end

-- What a jar comes off as, a new item: Active (or Hopped) Culture as old as it has kept, done; the jar as it was part
-- way, its run noted; the empty jar, gone off. place is the shelf's, where a culture's keeping goes on from.
function Y.jarOutput(jar, now, place)
    local state = Y.jarState(jar)
    if state == "off" then return instanceItem(jar.jar) end
    if state == "done" or state == "spent" then
        local culture = instanceItem(outputOf(jar))
        Y.putInJar(culture, jar.jar)
        Y.keepCulture(culture, now, place)
        culture:getModData()[Y.CULTURE_KEEPER.keepingRules.modDataKey].base = Y.jarKeptDays(jar)
        Y.keepCulture(culture, now, place)
        return culture
    end
    local item = instanceItem(jar.kind == "fed" and Y.FED or Y.FERMENTING)
    Y.putInJar(item, jar.jar)
    local modData = item:getModData()
    modData[Y.START_KEY] = jar.start ~= "plain" and jar.start or nil
    modData[Y.RUN_KEY] = jar.kind == "culture" and { done = jar.done, fedAt = jar.fedAt, work = FluidAgeing.copy(jar.work) }
        or { done = jar.done }
    Y.nameStart(item)
    return item
end

-- How a jar is doing at placeC: { state, progress (0 to 1), rate, hoursLeft (to done, if it is fed until then),
-- hungryIn, offIn (hours, at this rate; nil when it waits), keptDays, spentIn (days to Spent here, done) }.
function Y.jarStatus(jar, placeC, place)
    local state = Y.jarState(jar)
    local hours = Y.jarHours(jar)
    local rate = Y.cultureRate(placeC)
    local status = { state = state, progress = math.min(jar.done / hours, 1), rate = rate }
    if state == "done" or state == "spent" then
        status.progress = 1
        status.keptDays = Y.jarKeptDays(jar)
        local keepRate = Y.CULTURE_KEEPER.rate(place) * Y.CULTURE_KEEPER.ageing.speed()
        local left = Y.CULTURE_DAYS[outputOf(jar)][2] - status.keptDays
        status.spentIn = keepRate > 0 and left > 0 and left / keepRate or nil
        return status
    end
    if state == "off" or rate <= 0 then return status end
    status.hoursLeft = (hours - jar.done) / rate
    if jar.kind == "culture" then
        local sinceFed = jar.work.age - jar.fedAt
        if state == "hungry" then
            status.offIn = (Y.OFF_HOURS - sinceFed) / rate
        else
            status.hungryIn = (Y.HUNGRY_HOURS - sinceFed) / rate
        end
    end
    return status
end

-- A jar's look on the shelf (Tiles.JAR_LOOKS).
function Y.jarLook(jar, progress)
    local state = Y.jarState(jar)
    if state == "off" or state == "spent" then return "off" end
    if state == "done" then return jar.kind == "fed" and "fedDone" or "done" end
    if state == "hungry" then return "hungry" end
    if jar.kind == "fed" then return "fedRising" end
    if progress >= 0.5 then return "halfway" end
    if jar.start == "fruit" or jar.start == "potato" then return jar.start end
    return "fresh"
end

-- A culture item's name by what it was started with: Fermenting Culture (Fruit).
function Y.nameStart(item)
    local start = item:getModData()[Y.START_KEY]
    if not start or start == "plain" then return end
    item:setName(getText("IGUI_TraditionalPreservationYeast_Start_" .. start, getItemNameFromFullType(item:getFullType())))
    item:setCustomName(true)
end

-- What a refresh takes, a jar: flour by the use from anything in reach (TP Core's Uses), water from what the character
-- carries holding nothing but Water.
local FLOUR = "Base.Flour2"

local function isWater(item)
    local container = item:getFluidContainer()
    return container ~= nil and Container.fluidIn(container) == "Water"
end

local function waterCarried(character)
    local found = character:getInventory():getAllEvalRecurse(isWater)
    local list, litres = {}, 0
    for i = 0, found:size() - 1 do
        local item = found:get(i)
        table.insert(list, item)
        litres = litres + item:getFluidContainer():getAmount()
    end
    return list, litres
end

-- How many jars the character has the flour and water to refresh, and why not all of count: nil, "flour" or "water".
function Y.refreshesCarried(character, count)
    local byFlour = math.floor(Uses.count(character, FLOUR, true) / Y.REFRESH_FLOUR)
    local _, litres = waterCarried(character)
    local byWater = math.floor(litres / Y.REFRESH_WATER_L + 1e-6)
    local can = math.min(count, byFlour, byWater)
    local short = nil
    if can < count then short = byFlour <= byWater and "flour" or "water" end
    return can, short
end

-- Takes the flour and water for count jars.
function Y.takeRefreshSupplies(character, count)
    Uses.take(character, FLOUR, count * Y.REFRESH_FLOUR, true)
    local owed = count * Y.REFRESH_WATER_L
    for _, item in ipairs((waterCarried(character))) do
        if owed <= 0 then break end
        local container = item:getFluidContainer()
        local taken = math.min(container:getAmount(), owed)
        container:removeFluid(taken)
        owed = owed - taken
    end
end

-- Refreshes as many jars as the supplies carried allow, the hungriest first, and takes the supplies. Returns how many.
function Y.refreshWith(record, character)
    local jars = Y.refreshable(record)
    table.sort(jars, function(a, b) return a.work.age - a.fedAt > b.work.age - b.fedAt end)
    local count = Y.refreshesCarried(character, #jars)
    for i = 1, count do jars[i].fedAt = jars[i].work.age end
    if count > 0 then Y.takeRefreshSupplies(character, count) end
    return count
end

-- Checks frost on the cultures (TP Core's Frost, at 0 C): a Fermenting Culture frozen through goes hungry, on the
-- shelf or carried; Active Culture, Hopped Culture, wet Yeast Cakes (in hand or on the Drying Cloth) and a done jar on
-- the shelf take 1/48 of their days to Spent an hour frozen; Dried Yeast Cakes and a Fed Culture rising take nothing;
-- a basement or a place by a fire never freezes; the sandbox's Starters freeze off does no harm. Run from the mod
-- folder: luajit tests/test_frost.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near = H.check, H.near
H.useModPaths()
H.installClock(10)
H.installModData()
H.installEvents()
H.installGetText()
ScriptManager = { instance = { getCraftRecipe = function() return { Load = function() end } end } }
dofile("42/media/lua/shared/TraditionalPreservationYeast.lua")
local Y = TraditionalPreservationYeast
local Frost = require "TraditionalPreservationCore/Frost"
local Fire = require "TraditionalPreservationCore/Fire"
local DryingCloth = require "TraditionalPreservationCore/DryingCloth"
function getItemNameFromFullType(fullType) return fullType end


local DAYS = { [Y.ACTIVE] = { 3, 5 }, [Y.HOPPED] = { 7, 10 }, [Y.CAKES] = { 5, 8 } }
local function item(fullType)
    local days = DAYS[fullType] or { 0, 0 }
    local self = { fullType = fullType, modData = {}, age = 0, offAge = days[1], offAgeMax = days[2] }
    function self:getFullType() return self.fullType end
    function self:getModData() return self.modData end
    function self:getAge() return self.age end
    function self:setAge(x) self.age = x end
    function self:getOffAge() return self.offAge end
    function self:getOffAgeMax() return self.offAgeMax end
    function self:setOffAge(x) self.offAge = x end
    function self:setOffAgeMax(x) self.offAgeMax = x end
    function self:getName() return self.name end
    function self:setName(x) self.name = x end
    function self:setCustomName() end
    function self:getOutermostContainer() return nil end
    function self:getWorldItem() return nil end
    function self:isCooked() return self.cooked == true end
    function self:isBurnt() return self.burnt == true end
    return self
end

-- hours of weather at celsius into every ledger: the culture's work, its keeping, the cloth's and the frost's (TP
-- Core records the frost ledger in game; a test does it itself).
local function weather(hours, celsius)
    for _ = 1, hours do
        H.setHours(H.hours + 1)
        Y.advance(Y.getLedger(), H.hours, celsius)
        Y.CULTURE_KEEPER.recordWeather(H.hours, celsius)
        DryingCloth.recordWeather(H.hours, celsius)
        Frost.recordWeather(H.hours, celsius)
    end
end
weather(1, 5)

-- The shelf's jars, each brought up to now at its own place.
local record = { jars = {}, nextId = 1 }
local placeOf = {}
local function put(fullType, place)
    local jar = Y.putJar(record, item(fullType), H.hours, place)
    placeOf[jar] = place
    return jar
end
local function look()
    for _, jar in ipairs(record.jars) do
        Y.advanceJar(jar, H.hours, placeOf[jar], nil, nil, Y.getLedger(), Y.CULTURE_KEEPER.ledger())
    end
end
local function withFrostOff(fn)
    SandboxVars = { TraditionalPreservationYeast = { FrostDamage = false } }
    fn()
    SandboxVars = nil
end

check("a culture freezes at 0 C, where its work pauses", Y.FROST.celsius == 0 and Y.cultureRate(0) == 0)
check("Dried Yeast Cakes are not kept, so frost never reaches them", Y.CULTURE_DAYS[Y.DRIED_CAKES] == nil)

-- A Fermenting Culture frozen through goes hungry: 5 hours at -5 C leave it working, the sixth makes it hungry.
local open, basement, byFire, offJar = put(Y.FERMENTING, "Open"), put(Y.FERMENTING, "Basement"), put(Y.FERMENTING, Fire.PLACE),
    put(Y.FERMENTING, "Open")
-- The jar with Starters freeze off is looked at on its own.
table.remove(record.jars)
local function lookOff()
    withFrostOff(function() Y.advanceJar(offJar, H.hours, "Open", nil, nil, Y.getLedger(), Y.CULTURE_KEEPER.ledger()) end)
end
weather(2, 22)
look()
lookOff()
weather(5, -5)
look()
lookOff()
check("frozen 5 hours: still working, its work paused", Y.jarState(open) == "working" and near(open.frost.age, 5)
    and near(open.work.age - open.fedAt, 2))
weather(1, -5)
look()
lookOff()
check("frozen through (6 hours in all): hungry", Y.jarState(open) == "hungry")
check("one refresh puts it right", Y.refreshJars({ jars = { open } }) == 1 and Y.jarState(open) == "working")
check("a basement never freezes", near(basement.frost.age, 0) and Y.jarState(basement) == "working")
check("nor a place by a fire", near(byFire.frost.age, 0) and Y.jarState(byFire) == "working")
check("Starters freeze off: no harm, but the record goes on", Y.jarState(offJar) == "working" and near(offJar.frost.age, 6))

-- Carried, a Fermenting Culture's run counts its frost too: frozen through it comes onto the shelf hungry.
record.jars = {}
local carried, brief = item(Y.FERMENTING), item(Y.FERMENTING)
Y.startRun(carried, H.hours, "Open")
Y.startRun(brief, H.hours, "Open")
weather(5, -5)
local briefJar = Y.putJar(record, brief, H.hours, "Open")
weather(1, -5)
local carriedJar = Y.putJar(record, carried, H.hours, "Open")
check("carried and frozen 5 hours, it goes on working", Y.jarState(briefJar) == "working" and near(briefJar.frost.age, 5))
check("carried and frozen through, it goes on hungry", Y.jarState(carriedJar) == "hungry" and near(carriedJar.frost.age, 6))
function instanceItem(fullType) return item(fullType) end
local takenOff = Y.jarOutput(briefJar, H.hours, "Open")
check("taken off part way, its frost goes with it", near(takenOff.modData[Y.FROST_KEY].age, 5))

-- A Fed Culture rising only waits; done, a jar takes 1/48 of its days to Spent an hour frozen (Hopped Culture: 10).
record.jars = {}
local rising, done = put(Y.FED, "Open"), put(Y.FED, "Open")
done.done, done.keptAtDone = Y.RAISE_HOURS, done.keep.age
weather(12, -5)
look()
check("a Fed Culture frozen 12 hours: still rising, nothing done", Y.jarState(rising) == "working" and rising.done == 0)
check("a done one 12 hours frozen: a quarter of its 10 days nearer Spent", near(Y.jarKeptDays(done), 2.5))
weather(48, -5)
look()
check("two days frozen: Spent, and no further", Y.jarState(done) == "spent" and near(Y.jarKeptDays(done), 10))

-- Kept cultures: 1/48 of their days to Spent an hour frozen, on top of their keeping (none at -5 C).
local active, hopped, cakes, cellar, spared = item(Y.ACTIVE), item(Y.HOPPED), item(Y.CAKES), item(Y.ACTIVE), item(Y.ACTIVE)
local cooked, burnt = item(Y.CAKES), item(Y.ACTIVE)
cooked.cooked, burnt.burnt = true, true
for _, culture in ipairs({ active, hopped, cakes, spared, cooked, burnt }) do Y.keepCulture(culture, H.hours, "Open") end
Y.keepCulture(cellar, H.hours, "Basement")
check("the first look starts a frost record", active.modData[Y.FROST_KEY] ~= nil and active.modData[Y.FROST_KEY].age == 0)
weather(3, -5)
for _, culture in ipairs({ active, hopped, cakes, cooked, burnt }) do Y.keepCulture(culture, H.hours, "Open") end
Y.keepCulture(cellar, H.hours, "Basement")
withFrostOff(function() Y.keepCulture(spared, H.hours, "Open") end)
check("3 hours frozen: Active Culture 3/48 of its 5 days", near(active.age, 3 / 48 * 5))
check("Hopped Culture of its 10", near(hopped.age, 3 / 48 * 10))
check("wet Yeast Cakes of their 8", near(cakes.age, 3 / 48 * 8))
check("in a basement no frost", near(cellar.modData[Y.FROST_KEY].age, 0) and cellar.age < 0.5)
check("cooked or burnt: never freezes, no record, no bite", cooked.modData[Y.FROST_KEY] == nil and burnt.modData[Y.FROST_KEY] == nil
    and near(cooked.age, 0) and near(burnt.age, 0))
check("Starters freeze off: no harm, but the record goes on", near(spared.age, 0) and near(spared.modData[Y.FROST_KEY].age, 3))
local clock = active.modData[Y.CULTURE_KEEPER.keepingRules.modDataKey]
check("the keeping clock carries the frost, so the next look keeps it", near(clock.base + clock.fluidAge.age / 24, active.age))
weather(48, -5)
Y.keepCulture(active, H.hours, "Open")
check("two days frozen: Spent, and no older than that", near(active.age, 5) and Y.isSpent(active))

-- Wet Yeast Cakes on the Drying Cloth take the same; dry ones none.
local function cloth()
    local self = { modData = {} }
    function self:getModData() return self.modData end
    return self
end
local wet, dried, cookedLot = cloth(), cloth(), cloth()
DryingCloth.lay(dried, { item(Y.CAKES) }, H.hours, "Open")
weather(24 * 8, 15)
local dryRecord = DryingCloth.update(dried, H.hours, "Open")
local dryAge = Y.cakeLotAge(dryRecord.lots[1])
DryingCloth.lay(wet, { item(Y.CAKES) }, H.hours, "Open")
local cookedCakes = item(Y.CAKES)
cookedCakes.cooked = true
DryingCloth.lay(cookedLot, { cookedCakes }, H.hours, "Open")
weather(1, -5)
DryingCloth.update(wet, H.hours, "Open")
weather(3, -5)
local wetRecord = DryingCloth.update(wet, H.hours, "Open")
dryRecord = DryingCloth.update(dried, H.hours, "Open")
check("wet on the cloth, 4 hours frozen: 4/48 of their 8 days", DryingCloth.state(wetRecord.lots[1]) == "wet"
    and near(Y.cakeLotAge(wetRecord.lots[1]), 4 / 48 * 8))
local cookedRecord = DryingCloth.update(cookedLot, H.hours, "Open")
check("cooked cakes on the cloth never freeze", cookedRecord.lots[1].data.frost == nil and near(Y.cakeLotAge(cookedRecord.lots[1]), 0))
check("dry ones take nothing", DryingCloth.state(dryRecord.lots[1]) == "dry" and near(Y.cakeLotAge(dryRecord.lots[1]), dryAge))
weather(48, -5)
wetRecord = DryingCloth.update(wet, H.hours, "Open")
check("two days frozen wet: gone off", DryingCloth.state(wetRecord.lots[1]) == "dead" and wetRecord.lots[1].spoiled)

check("the sandbox's Starters freeze is on by default", Y.frostDamage())
SandboxVars = { TraditionalPreservationYeast = { FrostDamage = false } }
check("and can be turned off", not Y.frostDamage())
SandboxVars = nil

H.done()

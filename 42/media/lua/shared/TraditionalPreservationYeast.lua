-- Traditional Preservation (Yeast) B42: how a Fermenting Culture works on the Fermenting Shelf.
-- Each press of Craft runs its own timer, so cultures added later finish later. A culture works by the
-- temperature where the shelf stands, like the other Traditional Preservation stations: running totals
-- of the weather in global ModData say how much each one has done, even while its area was unloaded.
TraditionalPreservationYeast = TraditionalPreservationYeast or {}
local Y = TraditionalPreservationYeast
local Weather = require "TraditionalPreservationCore/Weather"
local Fire = require "TraditionalPreservationCore/Fire"

Y.FERMENT_HOURS = 120  -- five 24-hour in-game days at the best temperature
Y.MOD_DATA_KEY = "TraditionalPreservationYeast"
Y.LOG_TAG = "TraditionalPreservationYeast"   -- names the mod in Core's log lines
Y.RECIPE_NAME = "TraditionalPreservationYeast.FermentCulture"
Y.YEAST = "Base.Yeast"
-- One kind of work: the ledger's totals are "cultureOpen", "cultureOpenRate" and so on.
Y.KIND = "culture"
local KIND = Y.KIND

-- A wild yeast culture is happiest in a warm kitchen, slows in the cold without dying, and suffers
-- in real heat. { temperature, share of full speed } points, joined by straight lines.
local CULTURE_CURVE = { { -5, 0.05 }, { 0, 0.1 }, { 5, 0.2 }, { 10, 0.4 }, { 18, 1 }, { 30, 1 }, { 35, 0.6 }, { 40, 0.1 } }
Y.SENSITIVITY = 1
Y.MIN_RATE = 0.02

-- Places and their temperatures are shared with the other Traditional Preservation mods; these are the
-- mod's public names for them, used by the Dev console and the tests. A shelf within reach of a lit fire is by a
-- fire (or by banked embers), as Dairy's stations are (TP Core's Fire); PLACES are the weather's, which the
-- ledger keeps totals for.
Y.PLACES = Weather.PLACES
Y.placeTemperature = Weather.placeTemperature
Y.placeOf = Fire.placeOf

-- How fast a culture works at a temperature, 0 to 1, after the sandbox's sensitivity. Frozen it pauses (TP Core's
-- Weather.frozen); the floor holds above freezing only.
function Y.cultureRate(celsius)
    return Weather.rate(CULTURE_CURVE, celsius, Y.SENSITIVITY, Y.MIN_RATE)
end

local KINDS = { [KIND] = Y.cultureRate }

-- One total per place ("cultureOpen", "cultureOpenRate").
function Y.newLedger(now)
    return Weather.newLedger(now, KINDS)
end

-- Adds one stretch of weather to the totals.
function Y.advance(ledger, now, temperature)
    Weather.advance(ledger, now, temperature, KINDS)
end

-- The ledger in global ModData, made on first use.
function Y.getLedger()
    return Weather.getLedger(Y.MOD_DATA_KEY, Y.newLedger)
end

-- A run's place, as the shelf's World last told it (Y.notePlace); the open air before then.
local function runPlace(modData)
    return modData.place or Weather.NEW_RUN_PLACE
end

-- The engine pools recipe data without clearing its ModData, so every run must set all of this.
function Y.onFermentStart(craftRecipeData)
    Weather.startRun(craftRecipeData:getModData(), Y.getLedger(), KIND)
end

-- Craft timers tick at a fixed speed whatever Day Length says, so this replaces their count with the
-- work done at the shelf's temperature. It goes by where the shelf stood when last looked at (Y.notePlace).
function Y.onFermentUpdate(craftRecipeData)
    local modData = craftRecipeData:getModData()
    if not modData.done then return end
    Fire.updateRun(craftRecipeData, Y.getLedger(), KIND, runPlace(modData), Y.cultureRate)
end

-- Brings a running culture up to now at the place it was last told.
local function catchUpRun(modData)
    Fire.catchUpRun(modData, Y.getLedger(), KIND, runPlace(modData), Y.cultureRate)
end

-- Tells a running culture where its shelf stands (the shelf's World, at each look): the place, and the fire's
-- fuel when it is by one. Returns the place.
function Y.notePlace(modData, shelf, now)
    return Fire.notePlace(modData, shelf, now, catchUpRun)
end

-- How a running culture is doing, for its popup. hoursLeft assumes the temperature holds.
function Y.batchStatus(modData, recipeHours, ledger)
    return Weather.batchStatus(modData.done or 0, recipeHours, ledger, runPlace(modData), Y.cultureRate)
end

-- A finished culture is one Yeast and one Empty Jar, and stays on the shelf until both are taken, so the larger
-- count is the cultures not yet taken. fullTypes is a list of the finished items' full types.
function Y.finishedCultures(fullTypes)
    local yeast, jars = 0, 0
    for _, fullType in ipairs(fullTypes) do
        if fullType == Y.YEAST then yeast = yeast + 1 else jars = jars + 1 end
    end
    return math.max(yeast, jars)
end

-- Reads the sandbox's ferment time and sensitivity.
function Y.applySandbox()
    local options = SandboxVars and SandboxVars.TraditionalPreservationYeast
    if not options then return end
    if options.FermentDays then Y.FERMENT_HOURS = options.FermentDays * 24 end
    if options.TemperatureSensitivity then Y.SENSITIVITY = Weather.sensitivity(options.TemperatureSensitivity) end
end

-- Sets the recipe's script time from the sandbox, so the crafting window shows the right length.
function Y.applyFermentTime()
    Y.applySandbox()
    Weather.setRecipeHours(Y.RECIPE_NAME, Y.FERMENT_HOURS, Y.LOG_TAG)
end

Events.OnInitGlobalModData.Add(Y.applyFermentTime)

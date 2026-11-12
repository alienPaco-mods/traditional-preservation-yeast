-- Traditional Preservation (Yeast) B42: how a Fermenting Culture works on the Fermenting Shelf.
-- Each press of Craft runs its own timer, so cultures added later finish later. A culture works by the
-- temperature where the shelf stands, like the other Traditional Preservation stations: running totals
-- of the weather in global ModData say how much each one has done, even while its area was unloaded.
TraditionalPreservationYeast = TraditionalPreservationYeast or {}
local Y = TraditionalPreservationYeast
local Weather = require "TraditionalPreservationCore/Weather"
local Hearth = require "TraditionalPreservationCore/Hearth"

Y.FERMENT_HOURS = 120  -- five 24-hour in-game days at the best temperature
Y.MOD_DATA_KEY = "TraditionalPreservationYeast"
local RECIPE_NAME = "TraditionalPreservationYeast.FermentCulture"
local SECONDS_PER_HOUR = 3600
-- One kind of work, so the ledger's totals are plain "Open", "OpenRate" and so on, as in saves from 0.3.
local KIND = ""

-- A wild yeast culture is happiest in a warm kitchen, slows in the cold without dying, and suffers
-- in real heat. { temperature, share of full speed } points, joined by straight lines.
local CULTURE_CURVE = { { -5, 0.05 }, { 0, 0.1 }, { 5, 0.2 }, { 10, 0.4 }, { 18, 1 }, { 30, 1 }, { 35, 0.6 }, { 40, 0.1 } }
Y.SENSITIVITY = 1
Y.MIN_RATE = 0.02

-- Places and their temperatures are shared with the other Traditional Preservation mods; these are the
-- mod's public names for them, used by the Dev console and the tests. A shelf within reach of a lit fire is by a
-- fire (or by banked embers), as Dairy's stations are (TP Core's Hearth); PLACES are the weather's, which the
-- ledger keeps totals for.
Y.PLACES = Weather.PLACES
Y.placeTemperature = Hearth.placeTemperature
Y.placeOf = Hearth.placeOf

-- How fast a culture works at a temperature, 0 to 1, after the sandbox's sensitivity.
function Y.cultureRate(celsius)
    return Weather.scaled(Weather.curve(CULTURE_CURVE, celsius), Y.SENSITIVITY, Y.MIN_RATE)
end

local KINDS = { [KIND] = function(celsius) return Y.cultureRate(celsius) end }

-- One total per place, under the plain place names ("Open", "OpenRate").
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

local function runPlace(modData)
    return modData.place or "Sheltered"
end

-- The engine pools recipe data without clearing its ModData, so every run must set all of this.
function Y.onFermentStart(craftRecipeData)
    local modData = craftRecipeData:getModData()
    Weather.startRun(modData, Y.getLedger(), KIND)
    modData.fermentStartHour = nil
end

-- Craft timers tick at a fixed speed whatever Day Length says, so this replaces their count with the
-- work done at the shelf's temperature. It goes by where the shelf stood when last looked at (Y.notePlace).
function Y.onFermentUpdate(craftRecipeData)
    local ledger = Y.getLedger()
    local modData = craftRecipeData:getModData()
    local now = getGameTime():getWorldAgeHours()
    -- A batch from before temperature counted every hour in full: carry its hours over as done.
    if not modData.done then
        local started = modData.fermentStartHour or (now - craftRecipeData:getElapsedTime() / SECONDS_PER_HOUR)
        modData.done = math.max(now - started, 0)
        modData.last = Weather.mark({}, ledger, KIND)
    end

    local place = runPlace(modData)
    modData.done = modData.done + Hearth.catchUp(modData, modData.last, ledger, KIND, place, Y.cultureRate)
    Weather.showProgress(craftRecipeData, ledger, KIND, place, 1, now, Y.cultureRate)
end

-- Brings a running culture up to now at the place it was last told.
local function catchUpRun(modData)
    if not (modData.done and modData.last) then return end
    modData.done = modData.done + Hearth.catchUp(modData, modData.last, Y.getLedger(), KIND, runPlace(modData), Y.cultureRate)
end

-- Tells a running culture where its shelf stands (the shelf's World, at each look): the place, and the fire's
-- fuel when it is by one. Returns the place.
function Y.notePlace(modData, shelf, now)
    return Hearth.notePlace(modData, shelf, now, catchUpRun)
end

-- How a running culture is doing, for its popup. hoursLeft assumes the temperature holds.
function Y.batchStatus(modData, recipeHours, ledger)
    return Weather.batchStatus(modData.done or 0, recipeHours, ledger, runPlace(modData), Y.cultureRate)
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
    Weather.setRecipeHours(RECIPE_NAME, Y.FERMENT_HOURS, "TraditionalPreservationYeast")
end

Events.OnInitGlobalModData.Add(Y.applyFermentTime)

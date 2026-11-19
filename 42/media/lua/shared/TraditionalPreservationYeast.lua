-- Traditional Preservation (Yeast) B42: how a culture works. It works by the temperature where it stands, like the
-- other Traditional Preservation stations: running totals of the weather in global ModData say how much each jar on
-- the Fermenting Shelf has done, even while its area was unloaded (the shelf's record: TraditionalPreservationYeastShelf.lua).
TraditionalPreservationYeast = TraditionalPreservationYeast or {}
local Y = TraditionalPreservationYeast
local Weather = require "TraditionalPreservationCore/Weather"
local Fire = require "TraditionalPreservationCore/Fire"

Y.FERMENT_HOURS = 120  -- five 24-hour in-game days at the best temperature
Y.MOD_DATA_KEY = "TraditionalPreservationYeast"
Y.LOG_TAG = "TraditionalPreservationYeast"   -- names the mod in Core's log lines
Y.RAISE_HOURS = 24  -- a fed culture rises in a day at the best temperature
-- One kind of work: the ledger's totals are "cultureOpen", "cultureOpenRate" and so on.
Y.PROCESS = "culture"
local PROCESS = Y.PROCESS

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

local PROCESSES = { [PROCESS] = Y.cultureRate }

-- One total per place ("cultureOpen", "cultureOpenRate").
function Y.newLedger(now)
    return Weather.newLedger(now, PROCESSES)
end

-- Adds one stretch of weather to the totals.
function Y.advance(ledger, now, temperature)
    Weather.advance(ledger, now, temperature, PROCESSES)
end

-- The ledger in global ModData, made on first use.
function Y.getLedger()
    return Weather.getLedger(Y.MOD_DATA_KEY, Y.newLedger)
end

-- Reads the sandbox's ferment time and sensitivity.
function Y.applySandbox()
    local options = SandboxVars and SandboxVars.TraditionalPreservationYeast
    if not options then return end
    if options.FermentDays then Y.FERMENT_HOURS = options.FermentDays * 24 end
    if options.TemperatureSensitivity then Y.SENSITIVITY = Weather.sensitivity(options.TemperatureSensitivity) end
end

Events.OnInitGlobalModData.Add(Y.applySandbox)

require "TraditionalPreservationYeastCulture"
require "TraditionalPreservationYeastShelf"

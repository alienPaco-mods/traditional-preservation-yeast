-- Checks the fermenting timer outside the game. Run from the mod folder: luajit tests/test_ferment.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local hours = 10
function getGameTime() return { getWorldAgeHours = function() return hours end } end
local store = {}
ModData = { getOrCreate = function() return store end }
local onInit
Events = { OnInitGlobalModData = { Add = function(handler) onInit = handler end } }
local loaded = {}
ScriptManager = { instance = {} }
function ScriptManager.instance:getCraftRecipe()
    return { Load = function(_, name, text) loaded[name] = text end }
end
H.useModPaths()
dofile("42/media/lua/shared/TraditionalPreservationYeast.lua")

local check = H.check

local function recipeData(time, elapsed)
    local data = { modData = {}, elapsed = elapsed or 0 }
    function data:getModData() return self.modData end
    function data:getElapsedTime() return self.elapsed end
    function data:setElapsedTime(value) self.elapsed = value end
    function data:getRecipe() return { getTime = function() return time end } end
    return data
end

local Y = TraditionalPreservationYeast
local TIME = 120 * 3600
local function weather(count, temperature)
    for _ = 1, count do
        hours = hours + 1
        Y.advance(Y.getLedger(), hours, temperature)
    end
end

-- Temperature
check("best from 18 to 30 C", Y.cultureRate(18) == 1 and Y.cultureRate(30) == 1)
check("slower in a cool room", math.abs(Y.cultureRate(10) - 0.4) < 1e-9)
check("and crawls near freezing without stopping", math.abs(Y.cultureRate(1) - 0.12) < 1e-9)
check("frozen it pauses", Y.cultureRate(0) == 0 and Y.cultureRate(-20) == 0)
check("heat hurts it too", Y.cultureRate(38) < 0.4)
Y.SENSITIVITY = 0
check("sensitivity off runs at full speed in any weather", Y.cultureRate(-20) == 1 and Y.cultureRate(40) == 1)
Y.SENSITIVITY = 1.5
check("harsh never stops it above freezing", Y.cultureRate(1) >= Y.MIN_RATE and Y.cultureRate(45) >= Y.MIN_RATE)
check("but frozen is frozen on harsh too", Y.cultureRate(-1) == 0)
Y.SENSITIVITY = 1
check("a basement swings two fifths as far as the ground", Y.placeTemperature({ temperature = -15, seasonTemperature = -5, groundTemperature = -10 }, "Basement") == 2)
check("a room is the season's mean, 2 C warmer in a cold one", Y.placeTemperature({ temperature = 0, seasonTemperature = 5 }, "Sheltered") == 7 and Y.placeTemperature({ temperature = 0, seasonTemperature = 25 }, "Sheltered") == 25)

-- Timers
local warm = recipeData(TIME)
Y.onFermentStart(warm)
warm.modData.place = "Open"
weather(60, 22)
Y.onFermentUpdate(warm)
check("60 warm hours are half of five days", math.abs(warm.elapsed - 60 * 3600) < 1)
weather(100, 22)
Y.onFermentUpdate(warm)
check("and it stops at done", warm.elapsed == TIME)

local cold = recipeData(TIME)
Y.onFermentStart(cold)
cold.modData.place = "Open"
weather(50, 10)
Y.onFermentUpdate(cold)
check("a cool shed works at 40%", math.abs(cold.elapsed - 50 * 0.4 * 3600) < 1)

local downstairs = recipeData(TIME)
Y.onFermentStart(downstairs)
downstairs.modData.place = "Basement"
weather(24, -10)
Y.onFermentUpdate(downstairs)
-- The season slips towards the frost hour by hour, the basement a third as far: no slower than its last hour's rate.
check("a basement shelf carries on through a frost", downstairs.elapsed >= 24 * Y.cultureRate(Y.placeTemperature(Y.getLedger(), "Basement")) * 3600 - 1
    and downstairs.elapsed > 2 * 24 * Y.cultureRate(-10) * 3600)

-- By a fire: 28 C, full speed, by the clock until the fire's noted fuel ran out, then the room under it.
local Hearth = require "TraditionalPreservationCore/Hearth"
local hearthside = recipeData(TIME)
Y.onFermentStart(hearthside)
hearthside.modData.place = Hearth.PLACE
hearthside.modData.fireUntil = hours + 10
hearthside.modData.under = "Open"
weather(20, -10)
Y.onFermentUpdate(hearthside)
check("by a fire in a frost: 10 hours at full speed, then 10 in the frost",
    math.abs(hearthside.elapsed - (10 + 10 * Y.cultureRate(-10)) * 3600) < 1)
check("banked embers (24 C) are full speed too", Y.cultureRate(Y.placeTemperature(Y.getLedger(), Hearth.EMBERS)) == 1)

local away = recipeData(TIME)
Y.onFermentStart(away)
away.modData.place = "Open"
hours = hours + 30
Y.advance(Y.getLedger(), hours, 22)
Y.onFermentUpdate(away)
check("time away from the shelf still counts", math.abs(away.elapsed - 30 * 3600) < 1)

local old = recipeData(TIME, 3600)
old.modData.fermentStartHour = hours - 20
Y.onFermentUpdate(old)
check("a culture from before temperature keeps its hours", math.abs(old.modData.done - 20) < 1e-6)
local olderStill = recipeData(TIME, 7200)
Y.onFermentUpdate(olderStill)
check("even one with no start hour carries on from its progress", math.abs(olderStill.modData.done - 2) < 1e-6)

local pooled = recipeData(TIME)
pooled.modData = { done = 50, place = "Basement", fermentStartHour = 3 }
Y.onFermentStart(pooled)
check("a reused recipe object starts clean", pooled.modData.done == 0 and pooled.modData.place == nil and pooled.modData.fermentStartHour == nil)

local status = Y.batchStatus({ done = 60, place = "Open" }, 120, { temperature = 10 })
check("the popup shows progress and the real time left", status.progress == 0.5 and math.abs(status.hoursLeft - 150) < 1e-6 and math.abs(status.rate - 0.4) < 1e-9)

onInit()
check("the default is five days", TraditionalPreservationYeast.FERMENT_HOURS == 120)
check("and sets the recipe's time", loaded["TraditionalPreservationYeast.FermentCulture"]:find("432000", 1, true) ~= nil)
SandboxVars = { TraditionalPreservationYeast = { FermentDays = 2.5 } }
onInit()
check("the sandbox option sets the time", TraditionalPreservationYeast.FERMENT_HOURS == 60 and loaded["TraditionalPreservationYeast.FermentCulture"]:find("216000", 1, true) ~= nil)
SandboxVars.TraditionalPreservationYeast.TemperatureSensitivity = 1
onInit()
check("and the sensitivity", TraditionalPreservationYeast.SENSITIVITY == 0)

H.done()

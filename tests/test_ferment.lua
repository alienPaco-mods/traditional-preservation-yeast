-- Checks the fermenting timer outside the game. Run from the mod folder: luajit tests/test_ferment.lua
local H = dofile((os.getenv("TPCORE") or "../_tpcore") .. "/tests/harness.lua")
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
check("and crawls near freezing without stopping", math.abs(Y.cultureRate(-20) - 0.05) < 1e-9)
check("heat hurts it too", Y.cultureRate(38) < 0.4)
Y.SENSITIVITY = 0
check("sensitivity off runs at full speed in any weather", Y.cultureRate(-20) == 1 and Y.cultureRate(40) == 1)
Y.SENSITIVITY = 1.5
check("harsh never stops it", Y.cultureRate(-20) >= Y.MIN_RATE)
Y.SENSITIVITY = 1
check("a basement is 15 C all year", Y.placeTemperature({ temperature = -15, seasonTemperature = -10 }, "Basement") == 15)
check("a roof follows the season, plus 10, up to 28", Y.placeTemperature({ temperature = 0, seasonTemperature = 5 }, "Sheltered") == 15 and Y.placeTemperature({ temperature = 0, seasonTemperature = 25 }, "Sheltered") == 28)

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
check("a basement shelf carries on through a frost", math.abs(downstairs.elapsed - 24 * Y.cultureRate(15) * 3600) < 1)

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

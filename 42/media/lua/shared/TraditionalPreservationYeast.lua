-- Traditional Preservation (Yeast) B42: how a Fermenting Culture works on the Fermenting Shelf.
-- Each press of Craft runs its own timer, so cultures added later finish later. A culture works by the
-- temperature where the shelf stands, like the other Traditional Preservation stations: running totals
-- of the weather in global ModData say how much each one has done, even while its area was unloaded.
TraditionalPreservationYeast = TraditionalPreservationYeast or {}
local Y = TraditionalPreservationYeast

Y.FERMENT_HOURS = 120  -- five 24-hour in-game days at the best temperature
Y.MOD_DATA_KEY = "TraditionalPreservationYeast"
local RECIPE_NAME = "TraditionalPreservationYeast.FermentCulture"
local SECONDS_PER_HOUR = 3600

-- A wild yeast culture is happiest in a warm kitchen, slows in the cold without dying, and suffers
-- in real heat. { temperature, share of full speed } points, joined by straight lines.
local CULTURE_CURVE = { { -5, 0.05 }, { 0, 0.1 }, { 5, 0.2 }, { 10, 0.4 }, { 18, 1 }, { 30, 1 }, { 35, 0.6 }, { 40, 0.1 } }
-- Off, Forgiving, Normal, Harsh: how much of a temperature's slowdown applies.
Y.SENSITIVITY_SCALES = { 0, 0.5, 1, 1.5 }
Y.SENSITIVITY = 1
Y.MIN_RATE = 0.02

-- Places, as in the other mods: outdoors goes by the day, a roof by the season (the mean of the last
-- ten days or so, a bit warmer, never hotter than thick walls allow), and a basement stays put.
Y.PLACES = { "Open", "Sheltered", "Basement" }
Y.SEASON_HOURS = 240
Y.SHELTER_WARMTH = 10
Y.SHELTER_MAX = 28
Y.BASEMENT_TEMPERATURE = 15

local function curve(points, celsius)
    if celsius <= points[1][1] then return points[1][2] end
    for index = 2, #points do
        local low, high = points[index - 1], points[index]
        if celsius <= high[1] then
            return low[2] + (high[2] - low[2]) * (celsius - low[1]) / (high[1] - low[1])
        end
    end
    return points[#points][2]
end

function Y.cultureRate(celsius)
    return math.max(1 - (1 - curve(CULTURE_CURVE, celsius)) * Y.SENSITIVITY, Y.MIN_RATE)
end

function Y.placeTemperature(ledger, place)
    if place == "Basement" then return Y.BASEMENT_TEMPERATURE end
    local temperature = ledger.temperature or 0
    if place == "Sheltered" then
        temperature = math.min((ledger.seasonTemperature or temperature) + Y.SHELTER_WARMTH, Y.SHELTER_MAX)
    end
    return temperature
end

function Y.placeOf(object)
    local square = object and object:getSquare()
    if square and square:getZ() < 0 then return "Basement" end
    if object and not object:isOutside() then return "Sheltered" end
    return "Open"
end

function Y.newLedger(now)
    local ledger = { lastHour = now }
    for _, place in ipairs(Y.PLACES) do ledger[place] = 0 end
    return ledger
end

-- Adds one stretch of weather to the totals.
function Y.advance(ledger, now, temperature)
    local hours = now - ledger.lastHour
    if hours <= 0 then return end
    ledger.lastHour = now
    local share = math.min(hours / Y.SEASON_HOURS, 1)
    ledger.seasonTemperature = (ledger.seasonTemperature or temperature) * (1 - share) + temperature * share
    ledger.temperature = temperature
    for _, place in ipairs(Y.PLACES) do
        local rate = Y.cultureRate(Y.placeTemperature(ledger, place))
        ledger[place .. "Rate"] = rate
        ledger[place] = (ledger[place] or 0) + rate * hours
    end
end

function Y.getLedger()
    local data = ModData.getOrCreate(Y.MOD_DATA_KEY)
    if not data.ledger then data.ledger = Y.newLedger(getGameTime():getWorldAgeHours()) end
    return data.ledger
end

local function runPlace(modData)
    return modData.place or "Sheltered"
end

-- The engine pools recipe data without clearing its ModData, so every run must set all of this.
function Y.onFermentStart(craftRecipeData)
    local ledger = Y.getLedger()
    local modData = craftRecipeData:getModData()
    modData.done = 0
    modData.last = {}
    for _, place in ipairs(Y.PLACES) do modData.last[place] = ledger[place] end
    modData.place = nil
    modData.fermentStartHour = nil
end

-- Craft timers tick at a fixed speed whatever Day Length says, so this replaces their count with the
-- work done at the shelf's temperature. It goes by where the shelf stands now.
function Y.onFermentUpdate(craftRecipeData)
    local ledger = Y.getLedger()
    local modData = craftRecipeData:getModData()
    local now = getGameTime():getWorldAgeHours()
    -- A batch from before temperature counted every hour in full: carry its hours over as done.
    if not modData.done then
        local started = modData.fermentStartHour or (now - craftRecipeData:getElapsedTime() / SECONDS_PER_HOUR)
        modData.done = math.max(now - started, 0)
        modData.last = {}
        for _, place in ipairs(Y.PLACES) do modData.last[place] = ledger[place] end
    end

    local place = runPlace(modData)
    modData.done = modData.done + ledger[place] - (modData.last[place] or ledger[place])
    for _, each in ipairs(Y.PLACES) do modData.last[each] = ledger[each] end

    -- Weather is only recorded every ten minutes, so the bar carries on at the last rate between
    -- records. That part is only shown, and the next record replaces it.
    local rate = ledger[place .. "Rate"] or 0
    local sinceRecord = math.max(now - ledger.lastHour, 0)
    local elapsed = (modData.done + sinceRecord * rate) * SECONDS_PER_HOUR
    craftRecipeData:setElapsedTime(math.min(elapsed, craftRecipeData:getRecipe():getTime()))
end

-- How a running culture is doing, for its popup. hoursLeft assumes the temperature holds.
function Y.batchStatus(modData, recipeHours, ledger)
    local place = runPlace(modData)
    local temperature = Y.placeTemperature(ledger, place)
    local rate = Y.cultureRate(temperature)
    local done = modData.done or 0
    return {
        progress = math.min(done / recipeHours, 1),
        hoursLeft = math.max(recipeHours - done, 0) / rate,
        temperature = temperature,
        place = place,
        rate = rate,
    }
end

function Y.applySandbox()
    local options = SandboxVars and SandboxVars.TraditionalPreservationYeast
    if not options then return end
    if options.FermentDays then Y.FERMENT_HOURS = options.FermentDays * 24 end
    if options.TemperatureSensitivity then Y.SENSITIVITY = Y.SENSITIVITY_SCALES[options.TemperatureSensitivity] or 1 end
end

function Y.applyFermentTime()
    Y.applySandbox()
    local recipe = ScriptManager.instance:getCraftRecipe(RECIPE_NAME)
    if not recipe then
        print("[TraditionalPreservationYeast] Could not find " .. RECIPE_NAME)
        return
    end
    local seconds = math.floor(Y.FERMENT_HOURS * SECONDS_PER_HOUR)
    recipe:Load(RECIPE_NAME, "{ time = " .. tostring(seconds) .. ", }")
end

Events.OnInitGlobalModData.Add(Y.applyFermentTime)

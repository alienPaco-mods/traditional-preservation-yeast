-- Traditional Preservation (Yeast): commands for the debug Lua console, loaded only in debug mode.
-- Type TPY.help() in the console for the list. See DEVHELP.md in the mod folder.
if not isDebugEnabled() then return end

local Y = TraditionalPreservationYeast
local Weather = require "TraditionalPreservationCore/Weather"
local Fire = require "TraditionalPreservationCore/Fire"
TPY = {}

local function say(text) print("[TPY] " .. text) end

function TPY.help()
    say("TPY.weather()        the temperature by place, and how fast a culture works there")
    say("TPY.cultures()       Active and Hopped Culture and wet Yeast Cakes on you or near: the jar, place and how long each keeps there")
    say("TPY.here()           which place you're standing in (open air, an open roof, indoors, a basement, by a fire)")
    say("TPY.age(hours)       give every shelf this many hours of perfect fermenting weather")
    say("TPY.fast(hours)      test timer: a culture takes this many hours. TPY.fast() goes back to the sandbox time")
    say("TPY.give(name, n)    spawn n of: culture (a Fermenting Culture), active (Active Culture), fed (Fed Culture), hopped (Hopped Culture), cakes (wet Yeast Cakes), dried (Dried Yeast Cakes), hops (Hops (Dried)), flour, or any full type. TPY.give() lists them")
    say("TPY.kit(kind)        the things a test needs: \"build\" (the Fermenting Shelf), \"culture\" (Make Fermenting Culture) or \"all\". TPY.kit() lists them")
end

function TPY.weather()
    local ledger = Y.getLedger()
    say(string.format("Temperature now %.1f C, season (10-day average) %.1f C. A culture takes %.1f hours at full speed.",
        ledger.temperature or 0, ledger.seasonTemperature or 0, Y.FERMENT_HOURS))
    for _, place in ipairs(Y.PLACES) do
        local rate = ledger[Y.PROCESS .. place .. "Rate"] or 0
        say(string.format("%-9s %.1f C: %.0f%% speed, about %.1f days a culture", place, Y.placeTemperature(ledger, place),
            rate * 100, rate > 0 and Y.FERMENT_HOURS / rate / 24 or 0))
    end
    for _, place in ipairs({ Fire.PLACE, Fire.EMBERS }) do
        local rate = Y.cultureRate(Fire.fireC(place))
        say(string.format("%-9s %.1f C: %.0f%% speed, about %.1f days a culture (by the clock: TPY.age skips it)", place,
            Fire.fireC(place), rate * 100, Y.FERMENT_HOURS / rate / 24))
    end
end

-- Cultures and wet cakes carried or within reach: the jar, place and how long each keeps there.
function TPY.cultures()
    local PlaceKeepingUI = require "TraditionalPreservationCore/PlaceKeepingUI"
    local found = PlaceKeepingUI.near(Y.CULTURE_DAYS)
    if #found == 0 then return say("No culture or wet cakes on you or within " .. PlaceKeepingUI.REACH .. " tiles.") end
    for _, item in ipairs(found) do say(Y.jarOf(item) .. ": " .. Y.CULTURE_KEEPER.describe(item)) end
end

function TPY.here()
    say("You're in: " .. tostring(Y.placeOf(getPlayer())))
end

function TPY.age(hours)
    hours = hours or 24
    local ledger = Y.getLedger()
    for _, place in ipairs(Y.PLACES) do ledger[Y.PROCESS .. place] = (ledger[Y.PROCESS .. place] or 0) + hours end
    say(string.format("Added %.0f hours of perfect weather. Shelves update within a few seconds.", hours))
end

function TPY.fast(hours)
    if not hours then
        Y.applyFermentTime()
        return say(string.format("Back to the sandbox time: %.1f hours.", Y.FERMENT_HOURS))
    end
    Y.FERMENT_HOURS = hours
    Weather.setRecipeHours(Y.RECIPE_NAME, hours, Y.LOG_TAG)
    say(string.format("Test timer on: a culture takes %s hours at full speed.", tostring(hours)))
end

local GIVES = { culture = Y.FERMENTING, active = Y.ACTIVE, fed = Y.FED, hopped = Y.HOPPED, cakes = Y.CAKES, dried = Y.DRIED_CAKES,
    hops = "Base.HopsDried", flour = "Base.Flour2" }

function TPY.give(name, count)
    if not name then return say("Things: culture (a Fermenting Culture), active (Active Culture), fed (Fed Culture), hopped (Hopped Culture), cakes (wet Yeast Cakes), dried (Dried Yeast Cakes), hops (Hops (Dried)), flour, plus any full type such as Base.Yeast") end
    local fullType = GIVES[name] or (name:find("%.") and name)
    if not fullType then return say("Not a thing: " .. tostring(name) .. ". TPY.give() lists them") end
    local inventory = getPlayer():getInventory()
    for _ = 1, count or 1 do inventory:AddItem(fullType) end
    say(string.format("Gave %d %s.", count or 1, fullType))
end

-- One kit per part of the chain, each enough on its own; "all" is every kit.
local KITS = {
    build = {
        about = "a hammer, 2 planks and 4 nails, to build the Fermenting Shelf (Woodwork 2)",
        items = { ["Base.Hammer"] = 1, ["Base.Plank"] = 2, ["Base.Nails"] = 4 },
    },
    culture = {
        about = "15 flour, a Jar, a Ceramic Jar, a Glazed Ceramic Jar and a bottle of water, for three Make Fermenting Culture, one in each jar",
        items = { ["Base.Flour2"] = 15, ["Base.EmptyJar"] = 1, ["Base.ClayJar"] = 1, ["Base.ClayJarGlazed"] = 1 },
        -- Vanilla's bottle may spawn with carbonated water.
        filled = { ["Base.WaterBottle"] = "Water" },
    },
}
KITS.cakes = {
    about = "2 Active Culture, 6 cornmeal, a Sheet and 2 Stones, for Shape Yeast Cakes and a Drying Cloth to dry them on",
    items = { [Y.ACTIVE] = 2, ["Base.Cornmeal2"] = 6, ["Base.Sheet"] = 1, ["Base.Stone2"] = 2 },
}
KITS.hops = {
    about = "an Active Culture, 2 Hops (Dried), a Saucepan of 1 L water, an empty Jar and 5 flour, for Steep Hops and Feed Culture",
    items = { [Y.ACTIVE] = 1, ["Base.HopsDried"] = 2, ["Base.EmptyJar"] = 1, ["Base.Flour2"] = 5 },
    litre = { ["Base.Saucepan"] = "Water" },
}
local KIT_NAMES = { "build", "culture", "cakes", "hops" }

function TPY.kit(kind)
    local names = kind == "all" and KIT_NAMES or { kind }
    if not KITS[names[1]] then
        for _, name in ipairs(KIT_NAMES) do say("TPY.kit(\"" .. name .. "\"): " .. KITS[name].about) end
        return say("TPY.kit(\"all\"): every kit above")
    end
    local inventory = getPlayer():getInventory()
    for _, name in ipairs(names) do
        local kit = KITS[name]
        for fullType, count in pairs(kit.items) do
            for _ = 1, count do inventory:AddItem(fullType) end
        end
        for fullType, fluid in pairs(kit.litre or {}) do
            local container = inventory:AddItem(fullType):getFluidContainer()
            container:Empty()
            container:addFluid(fluid, 1.0)
        end
        for fullType, fluid in pairs(kit.filled or {}) do
            local container = inventory:AddItem(fullType):getFluidContainer()
            container:Empty()
            container:addFluid(fluid, container:getCapacity())
        end
        say("Gave " .. KITS[name].about .. ".")
    end
end

say("Debug commands loaded. Type TPY.help() in the Lua console.")

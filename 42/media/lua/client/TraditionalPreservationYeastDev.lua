-- Traditional Preservation (Yeast): commands for the debug Lua console, loaded only in debug mode.
-- Type TPY.help() in the console for the list. See DEVHELP.md in the mod folder.
if not isDebugEnabled() then return end

local Y = TraditionalPreservationYeast
local Weather = require "TraditionalPreservationCore/Weather"
TPY = {}

local RECIPE_NAME = "TraditionalPreservationYeast.FermentCulture"

local function say(text) print("[TPY] " .. text) end

function TPY.help()
    say("TPY.weather()        the temperature by place, and how fast a culture works there")
    say("TPY.here()           which place you're standing in (outdoors, under a roof or a basement)")
    say("TPY.age(hours)       give every shelf this many hours of perfect fermenting weather")
    say("TPY.fast(hours)      test timer: a culture takes this many hours. TPY.fast() goes back to the sandbox time")
    say("TPY.cultures(n)      spawn n Fermenting Cultures")
    say("TPY.flour(n)         spawn n bags of flour")
end

function TPY.weather()
    local ledger = Y.getLedger()
    say(string.format("Temperature now %.1f C, season (10-day average) %.1f C. A culture takes %.1f hours at full speed.",
        ledger.temperature or 0, ledger.seasonTemperature or 0, Y.FERMENT_HOURS))
    for _, place in ipairs(Y.PLACES) do
        local rate = ledger[place .. "Rate"] or 0
        say(string.format("%-9s %.1f C: %.0f%% speed, about %.1f days a culture", place, Y.placeTemperature(ledger, place),
            rate * 100, rate > 0 and Y.FERMENT_HOURS / rate / 24 or 0))
    end
end

function TPY.here()
    say("You're in: " .. tostring(Y.placeOf(getPlayer())))
end

function TPY.age(hours)
    hours = hours or 24
    local ledger = Y.getLedger()
    for _, place in ipairs(Y.PLACES) do ledger[place] = (ledger[place] or 0) + hours end
    say(string.format("Added %.0f hours of perfect weather. Shelves update within a few seconds.", hours))
end

function TPY.fast(hours)
    if not hours then
        Y.applyFermentTime()
        return say(string.format("Back to the sandbox time: %.1f hours.", Y.FERMENT_HOURS))
    end
    Y.FERMENT_HOURS = hours
    Weather.setRecipeHours(RECIPE_NAME, hours, "TraditionalPreservationYeast")
    say(string.format("Test timer on: a culture takes %s hours at full speed.", tostring(hours)))
end

function TPY.cultures(count)
    local inventory = getPlayer():getInventory()
    for _ = 1, count or 1 do inventory:AddItem("TraditionalPreservationYeast.FermentingYeastJar") end
    say("Gave " .. (count or 1) .. " Fermenting Culture(s).")
end

function TPY.flour(count)
    local inventory = getPlayer():getInventory()
    for _ = 1, count or 1 do inventory:AddItem("Base.Flour2") end
    say("Gave " .. (count or 1) .. " flour.")
end

say("Debug commands loaded. Type TPY.help() in the Lua console.")

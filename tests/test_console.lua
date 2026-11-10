-- Checks the debug console (TPY) loads and its commands run. Run from the mod folder: luajit tests/test_console.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check = H.check
H.useModPaths()
H.installClock(100)
H.installModData()
H.installEvents()

-- Engine stand-ins
function getClimateManager()
    return { getTemperature = function() return 22 end, getHumidity = function() return 50 end }
end
local loaded = {}
ScriptManager = { instance = {} }
function ScriptManager.instance:getCraftRecipe()
    return { Load = function(_, name, text) loaded[name] = text end }
end
SandboxVars = { TraditionalPreservationYeast = { FermentDays = 5 } }
local player = H.player({ z = -1 })
function getPlayer() return player end

dofile("42/media/lua/shared/TraditionalPreservationYeast.lua")
local Y = TraditionalPreservationYeast
local TPY, run = H.checkConsole("42/media/lua/client/TraditionalPreservationYeastDev.lua", "TPY")

check("weather names every place", (function()
    local text = run("weather")
    for _, place in ipairs(Y.PLACES) do
        if not text:find(place, 1, true) then return false end
    end
    return true
end)())
check("here says where the player stands, not where nobody does", run("here"):find("Basement", 1, true) ~= nil)

local before = Y.getLedger()[Y.PLACES[1]] or 0
run("age", 12)
check("age adds its hours to every place", Y.getLedger()[Y.PLACES[1]] == before + 12)
run("age")
check("and a day with no number", Y.getLedger()[Y.PLACES[1]] == before + 36)

local sandbox = Y.FERMENT_HOURS
run("fast", 2)
check("fast sets the test timer and reloads the recipe", Y.FERMENT_HOURS == 2 and next(loaded) ~= nil)
run("fast")
check("fast with no number goes back to the sandbox time", Y.FERMENT_HOURS == sandbox)

run("cultures", 3)
run("flour")
check("cultures and flour land in the inventory", #player.given == 4
    and player.given[1] == "TraditionalPreservationYeast.FermentingYeastJar" and player.given[4] == "Base.Flour2")

H.done()

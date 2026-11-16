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
function getCell() return { getGridSquare = function() return nil end } end
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

local key = Y.PROCESS .. Y.PLACES[1]
local before = Y.getLedger()[key] or 0
run("age", 12)
check("age adds its hours to every place", Y.getLedger()[key] == before + 12)
run("age")
check("and a day with no number", Y.getLedger()[key] == before + 36)

local sandbox = Y.FERMENT_HOURS
run("fast", 2)
check("fast sets the test timer and reloads the recipe", Y.FERMENT_HOURS == 2 and next(loaded) ~= nil)
run("fast")
check("fast with no number goes back to the sandbox time", Y.FERMENT_HOURS == sandbox)

run("give", "culture", 3)
run("give", "flour")
check("give with no name lists the things", run("give"):find("culture", 1, true) ~= nil and #player.given == 4)
check("cultures and flour land in the inventory", #player.given == 4
    and player.given[1] == "TraditionalPreservationYeast.FermentingYeastJar" and player.given[4] == "Base.Flour2")
run("give", "Base.Yeast")
run("give", "nothing")
check("give takes a full type too, and refuses an unknown name", #player.given == 5 and player.given[5] == "Base.Yeast")

-- The bottle comes with a fluid container the kit fills.
local filled = {}
function player:getInventory()
    return { AddItem = function(_, fullType)
        table.insert(player.given, fullType)
        return { getFluidContainer = function()
            return { Empty = function() end, getCapacity = function() return 1 end,
                addFluid = function(_, fluid, litres) filled[fluid] = (filled[fluid] or 0) + litres end }
        end }
    end }
end
local function counted(fullType)
    local count = 0
    for _, given in ipairs(player.given) do if given == fullType then count = count + 1 end end
    return count
end
player.given = {}
check("kit with no kind lists every kit", run("kit"):find("TPY.kit(\"all\")", 1, true) ~= nil
    and run("kit"):find("TPY.kit(\"culture\")", 1, true) ~= nil and #player.given == 0)
run("kit", "build")
check("the build kit has the shelf's hammer, planks and nails", counted("Base.Hammer") == 1 and counted("Base.Plank") == 2
    and counted("Base.Nails") == 4)
player.given = {}
run("kit", "culture")
check("the culture kit has the recipe's flour, jar and water", counted("Base.Flour2") == 5 and counted("Base.EmptyJar") == 1
    and filled.Water == 1)
player.given = {}
run("kit", "all")
check("all gives every kit", counted("Base.Plank") == 2 and counted("Base.Flour2") == 5 and filled.Water == 2)

H.done()

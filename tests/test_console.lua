-- Checks the debug console (TPY) loads and its commands run. Run from the mod folder: luajit tests/test_console.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check = H.check
H.useModPaths()
H.installClock(100)
H.installModData()
H.installEvents()

-- Engine stand-ins
function getClimateManager()
    return { isUpdated = function() return true end, getTemperature = function() return 22 end, getHumidity = function() return 50 end }
end
SandboxVars = { TraditionalPreservationYeast = { FermentDays = 5 } }
function getCell() return { getGridSquare = function() return nil end } end
local player = H.player({ z = -1 })
function getPlayer() return player end
-- A culture given starts its run, so what AddItem gives back has modData.
local addItem = player:getInventory().AddItem
player:getInventory().AddItem = function(self, fullType)
    local item = addItem(self, fullType)
    item.modData = {}
    item.getModData = function() return item.modData end
    return item
end
local Station = require "TraditionalPreservationCore/Station"
Station.near = function() return {} end

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
check("fast sets the test timer", Y.FERMENT_HOURS == 2)
run("fast")
check("fast with no number goes back to the sandbox time", Y.FERMENT_HOURS == sandbox)

run("give", "culture", 3)
run("give", "flour")
check("give with no name lists the things", run("give"):find("culture", 1, true) ~= nil and #player.given == 4)
check("shelf with none near says so", run("shelf"):find("No Fermenting Shelf", 1, true) ~= nil)
player:getInventory().getAllEvalRecurse = function() return H.list({}) end
check("frost with nothing near freezes nothing, 6 hours by default", run("frost"):find("Froze 0 cultures and 0 shelf jars for 6 hours", 1, true) ~= nil)
check("cultures with none near says so", run("cultures"):find("No culture", 1, true) ~= nil)
check("cultures and flour land in the inventory", #player.given == 4
    and player.given[1] == "TraditionalPreservationYeast.FermentingYeastJar" and player.given[4] == "Base.Flour2")
run("give", "Base.Yeast")
run("give", "nothing")
check("give takes a full type too, and refuses an unknown name", #player.given == 5 and player.given[5] == "Base.Yeast")
run("give", "hopped")
run("give", "dried")
check("give spawns the rework's items by name", player.given[6] == "TraditionalPreservationYeast.ActiveCultureHopped"
    and player.given[7] == "TraditionalPreservationYeast.DriedYeastCakes")

-- The bottle comes with a fluid container the kit fills.
local filled = {}
function player:getInventory()
    return { AddItem = function(_, fullType)
        table.insert(player.given, fullType)
        return { getFluidContainer = function()
            return { Empty = function() end, getCapacity = function() return fullType == "Base.Pot" and 1.5 or 1 end,
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
check("the culture kit has the recipe's flour and the refreshes', a jar of each kind, a full pot and a bottle of water", counted("Base.Flour2") == 30
    and counted("Base.EmptyJar") == 1 and counted("Base.ClayJar") == 1 and counted("Base.ClayJarGlazed") == 1 and counted("Base.Pot") == 1 and filled.Water == 2.5)
player.given = {}
run("kit", "starters")
check("the starters kit has an apple, a potato, a full pot, four jars, flour and water", counted("Base.Apple") == 1
    and counted("Base.Potato") == 1 and counted("Base.Pot") == 1 and counted("Base.EmptyJar") == 4
    and counted("Base.Flour2") == 20 and filled.Water == 5)
player.given = {}
run("kit", "cakes")
check("the cakes kit has culture, cornmeal and a cloth's Sheet and Stones", counted("TraditionalPreservationYeast.ActiveCulture") == 2
    and counted("Base.Cornmeal2") == 6 and counted("Base.Sheet") == 1 and counted("Base.Stone2") == 2)
player.given = {}
run("kit", "hops")
check("the hops kit has hops, a full pot of water, a jar and flour", counted("Base.HopsDried") == 2
    and counted("Base.Pot") == 1 and counted("Base.EmptyJar") == 1 and filled.Water == 6.5)
player.given = {}
run("kit", "all")
check("all gives every kit", counted("Base.Plank") == 2 and counted("Base.Flour2") == 55 and filled.Water == 13)

H.done()

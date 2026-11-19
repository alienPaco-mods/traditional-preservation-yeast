-- Checks culture jars (the same jar through every step) and Active Culture's keeping by place, with stand-ins for the
-- engine. Run from the mod folder: luajit tests/test_culture.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near, list = H.check, H.near, H.list
H.useModPaths()
H.installClock(0)
H.installModData()
H.installEvents()
H.installGetText()
ScriptManager = { instance = { getCraftRecipe = function() return { Load = function() end } end } }
dofile("42/media/lua/shared/TraditionalPreservationYeast.lua")
local Y = TraditionalPreservationYeast
local NAMES = { [Y.ACTIVE] = "Active Culture", [Y.HOPPED] = "Hopped Culture", [Y.CAKES] = "Yeast Cakes" }
function getItemNameFromFullType(fullType) return NAMES[fullType] end

local DAYS = { [Y.ACTIVE] = { 3, 5 }, [Y.HOPPED] = { 7, 10 }, [Y.CAKES] = { 5, 8 } }
local function item(fullType, jar)
    local days = DAYS[fullType] or { 0, 0 }
    local self = { fullType = fullType, modData = { tpyJar = jar }, age = 0, offAge = days[1], offAgeMax = days[2] }
    function self:getFullType() return self.fullType end
    function self:getModData() return self.modData end
    function self:getAge() return self.age end
    function self:setAge(x) self.age = x end
    function self:getOffAge() return self.offAge end
    function self:getOffAgeMax() return self.offAgeMax end
    function self:setOffAge(x) self.offAge = x end
    function self:setOffAgeMax(x) self.offAgeMax = x end
    function self:getName() return self.name end
    function self:setName(x) self.name = x end
    function self:setCustomName() end
    function self:getOutermostContainer() return nil end
    function self:getWorldItem() return nil end
    return self
end

local function recipeData(consumed, created)
    local data = { modData = {} }
    function data:getModData() return self.modData end
    function data:getAllConsumedItems() return list(consumed) end
    function data:getAllCreatedItems() return list(created) end
    return data
end

-- Jars
local made = item(Y.FERMENTING)
Y.onCreateInJar(recipeData({ item("Base.Flour2"), item("Base.ClayJarGlazed") }, { made }))
check("a culture is in the jar that went in", made.modData.tpyJar == "Base.ClayJarGlazed")
check("and drawn in it", made.modData.customInventoryIcon == "media/textures/Item_FermentingCulture_glazed.png"
    and made.modData.worldStaticModel == "GlazedClayJar")
local glass = item(Y.FERMENTING)
Y.onCreateInJar(recipeData({ item("Base.JarCrafted") }, { glass }))
check("a glass one keeps its script icon", glass.modData.tpyJar == "Base.JarCrafted" and glass.modData.customInventoryIcon == nil)
check("an old culture with no jar noted is glass", Y.jarOf(item(Y.FERMENTING)) == "Base.EmptyJar" and Y.jarKind("Base.JarCrafted") == "glass")

-- Made, a culture is fed and its run starts (it goes hungry off the shelf too); a fruit start says so in its name.
check("a culture's run starts when it's made", made.modData.tpyRun ~= nil and made.modData.tpyRun.fedAt == 0
    and made.modData.tpyRun.work.age == 0 and made.modData.tpyStart == nil)
local fruity = item(Y.FERMENTING)
NAMES[Y.FERMENTING] = "Fermenting Culture"
Y.onCreateFruitStart(recipeData({ item("Base.Apple"), item("Base.EmptyJar") }, { fruity }))
check("a fruit start is noted and named", fruity.modData.tpyStart == "fruit" and fruity.name == "Fermenting Culture (Fruit)")
local potato = item(Y.FERMENTING)
Y.onCreatePotatoStart(recipeData({ item("Base.EmptyJar") }, { potato }))
check("and a potato water one", potato.modData.tpyStart == "potato" and potato.name == "Fermenting Culture (Potato Water)")

-- Pour Out: the jar back, empty.
local added = {}
local character = { getInventory = function() return { AddItem = function(_, fullType) table.insert(added, fullType) end } end }
Y.onCreateJarBack(recipeData({ item(Y.ACTIVE, "Base.ClayJar") }, {}), character)
check("pouring out gives the jar back", #added == 1 and added[1] == "Base.ClayJar")

-- Keeping: about 3 days at 20 C, a day at 30 C, about a week in a 13 C basement, two weeks in a fridge.
local function daysToSpent(celsius) return 5 / Y.CULTURE_KEEPER.ageRate(celsius) end
check("3 days at 20 C", near(daysToSpent(20), 3, 0.05))
check("a day at 30 C", near(daysToSpent(30), 1, 0.01))
check("about a week at 13 C", daysToSpent(13) > 5.5 and daysToSpent(13) < 7)
check("about two weeks at 4 C (a fridge)", near(daysToSpent(4), 16.7, 0.1))
check("frozen it waits", Y.CULTURE_KEEPER.ageRate(-2) == 0)

-- Names
local culture = item(Y.ACTIVE, "Base.ClayJar")
Y.keepCulture(culture, 0, "Open")
check("a new culture reads (Fresh)", culture.name == "Active Culture (Fresh)")
culture.modData.tpyKeep.base = 5
check("past its days it is Spent", Y.isSpent(culture) and culture.name == "Active Culture (Spent)")

-- Feeding: the culture's jar and the new one, both rising.
local fedOne, fedTwo = item(Y.FED), item(Y.FED)
Y.onCreateFed(recipeData({ item(Y.HOPPED, "Base.ClayJar"), item("Base.ClayJarGlazed"), item("Base.Flour2") }, { fedOne, fedTwo }))
check("a fed culture keeps its jar, the second takes the new one", fedOne.modData.tpyJar == "Base.ClayJar" and fedTwo.modData.tpyJar == "Base.ClayJarGlazed"
    and fedOne.modData.customInventoryIcon == "media/textures/Item_FedCulture_clay.png")
check("a hopped culture keeps twice as long", Y.CULTURE_DAYS[Y.HOPPED][2] == 2 * Y.CULTURE_DAYS[Y.ACTIVE][2])

-- Steeping: a pot of nothing but water, 1 L at most.
local function pot(fluid, litres)
    local container = { fluid = fluid, litres = litres }
    function container:isEmpty() return self.litres <= 0 end
    function container:getPrimaryFluid() return { getFluidTypeString = function() return container.fluid end } end
    function container:getPrimaryFluidAmount() return self.litres end
    function container:getAmount() return self.litres end
    function container:Empty() self.litres = 0 end
    function container:addFluid(name, litres) self.fluid, self.litres = name, self.litres + litres end
    local self = item("Base.Pot")
    function self:getFluidContainer() return container end
    return self, container
end
check("a full pot of water steeps", Y.canSteep((pot("Water", 1.5))))
check("nor anything but water", not Y.canSteep((pot("Milk", 0.5))))
check("other inputs pass", Y.canSteep(item("Base.HopsDried")))
local steeped, steepedFluid = pot("Water", 0.0)
local steep = recipeData({}, {})
steep.getAllKeepInputItems = function() return list({ steeped }) end
Y.onSteeped(steep)
check("the pot's 1.5 L comes back as Hop Water", steepedFluid.fluid == Y.HOP_WATER and steepedFluid.litres == 1.5)
local mashed, mashedFluid = pot("Water", 0.0)
local mash = recipeData({}, {})
mash.getAllKeepInputItems = function() return list({ mashed }) end
Y.onPotatoMashed(mash)
check("a mashed potato's pot is Potato in Water", mashedFluid.fluid == Y.POTATO_SOAK and mashedFluid.litres == 1.5)

-- Cakes on the cloth: a week at full speed, dead past 35 C; dry gives a packet of Yeast.
local DryingCloth = require "TraditionalPreservationCore/DryingCloth"
local Tiles = require "TraditionalPreservationYeast/Tiles"
local kind = DryingCloth.kindOf(Y.CAKES)
check("yeast cakes are a cloth kind", kind ~= nil and kind.hours == 168 and kind.killAbove == 35)
check("full speed from 15 to 25 C", kind.drying.rate(15) == 1 and kind.drying.rate(25) == 1 and kind.drying.rate(0) == 0)
local bag = {}
local inventory = { AddItem = function(_, fullType) local made = item(fullType) table.insert(bag, fullType) return made end }
kind.give({ data = { age = 1 } }, inventory, "dry")
kind.give({ data = { age = 1 } }, inventory, "dead")
check("a dry lot is Dried Yeast Cakes, a dead one nothing", #bag == 1 and bag[1] == Y.DRIED_CAKES)
check("its sprite is the mod's own", kind.sprite(2, "dry") == "traditionalpreservationyeast_01_" .. (Tiles.FIRST_CAKE + 5 + 2))

-- Wet on the cloth they keep ageing, slower as they dry: in a warm shut room (where nothing dries) they go off; in the
-- open at 15 C they dry in 7 days about 2.3 days older (8 to Spent), however often they are looked at; shaped already 6 days old, at 20 C they don't.
local function cloth()
    local self = { modData = {} }
    function self:getModData() return self.modData end
    return self
end
local function weather(hours, celsius)
    for _ = 1, hours do
        H.setHours(H.hours + 1)
        Y.CULTURE_KEEPER.recordWeather(H.hours, celsius)
        DryingCloth.recordWeather(H.hours, celsius)
    end
end
local shut = cloth()
DryingCloth.lay(shut, { item(Y.CAKES) }, H.hours, "Sheltered")
weather(24 * 2, 20)
local record = DryingCloth.update(shut, H.hours, "Sheltered")
check("two days in a shut room: wet, nothing dried, two days older", DryingCloth.state(record.lots[1]) == "wet"
    and record.lots[1].dry.age == 0 and Y.cakeLotAge(record.lots[1]) > 1)
weather(24 * 4, 20)
record = DryingCloth.update(shut, H.hours, "Sheltered")
check("by six days they are gone off", DryingCloth.state(record.lots[1]) == "dead" and record.lots[1].spoiled)
local cool = cloth()
DryingCloth.lay(cool, { item(Y.CAKES) }, H.hours, "Open")
weather(24 * 8, 15)
record = DryingCloth.update(cool, H.hours, "Open")
check("at 15 C in the open they dry first, a third of 7 days older, in one catch-up as in many looks",
    DryingCloth.state(record.lots[1]) == "dry" and not record.lots[1].spoiled and math.abs(Y.cakeLotAge(record.lots[1]) - 7 / 3) < 0.1)
local old = cloth()
local oldCakes = item(Y.CAKES)
oldCakes:setAge(6)
DryingCloth.lay(old, { oldCakes }, H.hours, "Open")
weather(24 * 8, 20)
record = DryingCloth.update(old, H.hours, "Open")
check("shaped 6 days old, at 20 C they go off first", record.lots[1].spoiled == true)
local frozen = cloth()
DryingCloth.lay(frozen, { item(Y.CAKES) }, H.hours, "Open")
weather(24 * 30, -5)
record = DryingCloth.update(frozen, H.hours, "Open")
check("frozen they neither dry nor age", DryingCloth.state(record.lots[1]) == "wet" and Y.cakeLotAge(record.lots[1]) == 0)
bag = {}
kind.give({ data = { age = 1, keep = { age = 24 } } }, inventory, "wet")
check("taken off wet they come back as old as they are", #bag == 1 and bag[1] == Y.CAKES)

H.done()

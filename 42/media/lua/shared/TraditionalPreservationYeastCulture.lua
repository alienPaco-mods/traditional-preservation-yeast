-- Traditional Preservation (Yeast): culture jars. A culture is one item whatever jar it is in: a glass Jar (found or
-- crafted), a Ceramic Jar or a Glazed Ceramic Jar, noted on the item (modData JAR_KEY, a full type) and shown by its
-- icon and model; every step hands the same jar on, and Pour Out gives it back empty. A finished culture, Active
-- Culture, keeps by place on TP Core's PlaceKeeping and goes Spent when rotten. Required by
-- TraditionalPreservationYeast.lua, whose Y it adds to.
TraditionalPreservationYeast = TraditionalPreservationYeast or {}
local Y = TraditionalPreservationYeast
local PlaceKeeping = require "TraditionalPreservationCore/PlaceKeeping"
local Recipes = require "TraditionalPreservationCore/Recipes"
local ItemFluid = require "TraditionalPreservationCore/ItemFluid"
local DryingCloth = require "TraditionalPreservationCore/DryingCloth"
local FluidAgeing = require "TraditionalPreservationCore/FluidAgeing"
local Tiles = require "TraditionalPreservationYeast/Tiles"

Y.FERMENTING = "TraditionalPreservationYeast.FermentingYeastJar"
Y.ACTIVE = "TraditionalPreservationYeast.ActiveCulture"
Y.FED = "TraditionalPreservationYeast.FedCulture"
Y.HOPPED = "TraditionalPreservationYeast.ActiveCultureHopped"
Y.CAKES = "TraditionalPreservationYeast.YeastCakes"
Y.DRIED_CAKES = "TraditionalPreservationYeast.DriedYeastCakes"
Y.YEAST = "Base.Yeast"

-- Save key on every culture: never rename it once the mod is out.
Y.JAR_KEY = "tpyJar"
Y.GLASS_JAR = "Base.EmptyJar"
-- Each jar a culture can be in, by its look on the shelf and in the hand (Tiles.JAR_KINDS, the icons' names).
Y.JARS = {
    ["Base.EmptyJar"] = "glass", ["Base.JarCrafted"] = "glass",
    ["Base.ClayJar"] = "clay", ["Base.ClayJarGlazed"] = "glazed",
}
-- What a clay jar looks like on the ground: vanilla's own models.
local JAR_MODELS = { clay = "ClayJar", glazed = "GlazedClayJar" }
-- Each culture item's icon names (tools/build_shelf_tileset.py, ICON_ITEMS): Item_<name>_<kind>.png.
local ICONS = { [Y.FERMENTING] = "FermentingCulture", [Y.FED] = "FedCulture", [Y.ACTIVE] = "ActiveCulture",
    [Y.HOPPED] = "ActiveCultureHopped" }

-- The jar a culture is in (a full type); a glass Jar for one made before jars were noted.
function Y.jarOf(item)
    return item:getModData()[Y.JAR_KEY] or Y.GLASS_JAR
end

function Y.jarKind(jarType)
    return Y.JARS[jarType] or "glass"
end

-- Puts a culture item in jarType: noted, and drawn in it. The engine reads customInventoryIcon and worldStaticModel
-- from modData first, and saves them.
function Y.putInJar(item, jarType)
    local modData = item:getModData()
    modData[Y.JAR_KEY] = jarType
    local kind = Y.jarKind(jarType)
    local icon = ICONS[item:getFullType()]
    modData.customInventoryIcon = icon and kind ~= "glass" and ("media/textures/Item_" .. icon .. "_" .. kind .. ".png") or nil
    modData.worldStaticModel = JAR_MODELS[kind]
end

-- The jars among a recipe's used-up items, in order.
local function jarsUsed(craftRecipeData)
    local jars = {}
    for _, item in ipairs(Recipes.consumed(craftRecipeData)) do
        local fullType = item:getFullType()
        if Y.JARS[fullType] then
            table.insert(jars, fullType)
        elseif ICONS[fullType] then
            table.insert(jars, Y.jarOf(item))
        end
    end
    return jars
end

-- OnCreate of Make Fermenting Culture: the culture is in the jar that went in, freshly fed (its run starts: it goes
-- hungry wherever it is, TraditionalPreservationYeastShelf.lua), started with start (Y.STARTS; nil plain).
local function makeCulture(craftRecipeData, start)
    local jar = jarsUsed(craftRecipeData)[1] or Y.GLASS_JAR
    local now = getGameTime():getWorldAgeHours()
    for _, item in ipairs(Recipes.created(craftRecipeData, ICONS)) do
        Y.putInJar(item, jar)
        item:getModData()[Y.START_KEY] = start
        Y.startRun(item, now, (FluidAgeing.placeOfItem(item)))
        Y.nameStart(item)
    end
end

function Y.onCreateInJar(craftRecipeData) makeCulture(craftRecipeData, nil) end
function Y.onCreateFruitStart(craftRecipeData) makeCulture(craftRecipeData, "fruit") end
function Y.onCreatePotatoStart(craftRecipeData) makeCulture(craftRecipeData, "potato") end

-- OnCreate of Pour Out: the jar back, empty, as vanilla's Open Water Can adds its can.
function Y.onCreateJarBack(craftRecipeData, character)
    if not character then return end
    for _, jar in ipairs(jarsUsed(craftRecipeData)) do character:getInventory():AddItem(jar) end
end

-- OnCreate of Feed Culture: the culture's own jar and the new one, both rising.
function Y.onCreateFed(craftRecipeData)
    local jars = jarsUsed(craftRecipeData)
    for i, item in ipairs(Recipes.created(craftRecipeData, Y.FED)) do Y.putInJar(item, jars[i] or Y.GLASS_JAR) end
end

-- OnCreate of Shape Yeast Cakes: the cakes start their keeping, and the culture's jar comes back.
function Y.onCreateCakes(craftRecipeData, character)
    for _, cakes in ipairs(Recipes.created(craftRecipeData, Y.CAKES)) do Y.keepCulture(cakes) end
    Y.onCreateJarBack(craftRecipeData, character)
end

-- Hops: a pot of cold water steeped with Hops (Dried) is Hop Water, and kept steaming a quarter of an hour it is Hop
-- Tea (TP Core's ItemFluid). One Hops to a full pot (1.5 L) of clean water.
Y.HOP_WATER, Y.HOP_TEA = "YeastHopWater", "YeastHopTea"
Y.STEEP_LITRES = 1.5
Y.BREW_HOURS = 0.25
ItemFluid.turnsHot(Y.HOP_WATER, Y.HOP_TEA, Y.BREW_HOURS)
-- The Cooking Pots (1.5 L); a saucepan holds 0.6 L.
local POTS = { ["Base.Pot"] = true, ["Base.PotForged"] = true }

-- Potato water: a Potato mashed into a pot of cold water (Mash Potato in Water) is Potato in Water, and kept steaming
-- half an hour it is Potato Water, whose starch starts a culture quicker (Y.STARTS). One Potato to a pot, as the hops.
Y.POTATO_SOAK, Y.POTATO_WATER = "YeastPotatoSoak", "YeastPotatoWater"
Y.POTATO_BOIL_HOURS = 0.5
ItemFluid.turnsHot(Y.POTATO_SOAK, Y.POTATO_WATER, Y.POTATO_BOIL_HOURS)

-- OnTest of Steep Hops and Mash Potato in Water: a pot holding nothing but water (the recipe asks a full pot).
function Y.canSteep(item)
    if not POTS[item:getFullType()] then return true end
    local name = ItemFluid.oneFluid(item:getFluidContainer())
    return name == "Water"
end

-- OnCreate of Steep Hops: the pot's water the recipe took (inputs are used before OnCreate) comes back as Hop Water
-- (or fluid), in the same pot.
function Y.onSteeped(craftRecipeData, character, fluid)
    local kept = craftRecipeData:getAllKeepInputItems()
    for i = 0, kept:size() - 1 do
        local pot = kept:get(i)
        if POTS[pot:getFullType()] then
            local container = pot:getFluidContainer()
            container:Empty()
            container:addFluid(fluid or Y.HOP_WATER, Y.STEEP_LITRES)
            return
        end
    end
end

-- OnCreate of Mash Potato in Water: the pot's water comes back as Potato in Water.
function Y.onPotatoMashed(craftRecipeData)
    Y.onSteeped(craftRecipeData, nil, Y.POTATO_SOAK)
end

-- Keeping: days of age a day counts as at a temperature. The script's days (3 fresh, 5 to Spent) are a 15 C cellar's:
-- about 3 days at 20 C, a day at 30 C, about a week in a 13 C basement, two weeks in a fridge, frozen it waits. A
-- hopped culture keeps twice as long; wet yeast cakes (5 and 8: the meal soaks up the culture's water) a little longer.
Y.CULTURE_AGE_CURVE = { { -2, 0 }, { 4, 0.3 }, { 10, 0.55 }, { 15, 1 }, { 20, 1.67 }, { 30, 5 } }
Y.CULTURE_DAYS = { [Y.ACTIVE] = { 3, 5 }, [Y.HOPPED] = { 7, 10 }, [Y.CAKES] = { 5, 8 } }
Y.CULTURE_KEEPER = PlaceKeeping.new({
    process = "cultureKeep", curve = Y.CULTURE_AGE_CURVE, ledgerKey = "TraditionalPreservationYeastKeep",
    modDataKey = "tpyKeep", days = Y.CULTURE_DAYS,
})

-- Brings a culture's age up to now where it is (or place), and its name with it: Active Culture (Fresh), (Spent).
-- Returns its clock.
function Y.keepCulture(item, now, place, ledger)
    local clock = Y.CULTURE_KEEPER.keep(item, now, place, ledger)
    local spent = item:getAge() >= item:getOffAgeMax()
    local name = getText(spent and "IGUI_TraditionalPreservationYeast_CultureSpent" or "IGUI_TraditionalPreservationYeast_CultureFresh",
        getItemNameFromFullType(item:getFullType()))
    if item:getName() ~= name then
        item:setName(name)
        item:setCustomName(true)
    end
    return clock
end

function Y.isSpent(item)
    Y.keepCulture(item)
    return item:getAge() >= item:getOffAgeMax()
end

-- Yeast cakes on TP Core's Drying Cloth: a week at full speed (15 to 25 C in moving air), slower cool or hot, waiting
-- below freezing and in a shut room (the cloth's rule), dead past 35 C. While wet they keep ageing by the cloth's
-- place (a shut room's still air ages them though it dries nothing): on the culture's curve, held at its 20 C speed
-- above 20 C, and slowed as they dry, by how wet they still are squared (half dry, a quarter as fast). Spent before
-- dry, the lot is gone off. Dry, a lot comes off as Dried Yeast Cakes (Crumble Yeast Cakes: a packet of vanilla Yeast), which keep; taken
-- off wet, the cakes come back as old as they are; dead or gone off, nothing comes back.
Y.CAKE_DRY_HOURS = 168
Y.CAKE_KILL_C = 35
Y.CAKE_DRY_CURVE = { { 0, 0 }, { 5, 0.3 }, { 10, 0.6 }, { 15, 1 }, { 25, 1 }, { 30, 0.8 }, { 35, 0.6 } }
local CAKE_LOTS = DryingCloth.LOTS
local CAKE_SPENT_DAYS = Y.CULTURE_DAYS[Y.CAKES][2]
Y.CAKE_AGE_CURVE = { { -2, 0 }, { 4, 0.3 }, { 10, 0.55 }, { 15, 1 }, { 20, 1.67 } }
local CAKE_AGEING = Y.CULTURE_KEEPER.addAgeing("cakeKeep", Y.CAKE_AGE_CURVE)

-- A lot's cakes' age in days now (lot.data: age = when laid, keep = a FluidAgeing age on the keeper's ledger).
function Y.cakeLotAge(lot)
    local data = lot.data or {}
    return (data.age or 0) + (data.keep and data.keep.age / 24 or 0)
end

Y.CAKES_ON_CLOTH = DryingCloth.register({
    name = "yeastCakes", title = "IGUI_TraditionalPreservationYeast_CakesTitle", types = { [Y.CAKES] = true }, perLot = 1,
    hours = Y.CAKE_DRY_HOURS, curve = Y.CAKE_DRY_CURVE, killAbove = Y.CAKE_KILL_C, pattern = "media/textures/TPCell_YeastCakes.png",
    sprite = function(lot, state) return Tiles.PREFIX .. (Tiles.FIRST_CAKE + Tiles.CAKE_STATES[state] * CAKE_LOTS + lot) end,
    layable = function(item) return Y.isSpent(item) and "IGUI_TraditionalPreservationYeast_CakesSpent" or nil end,
    lay = function(items, now, place)
        return { age = items[1]:getAge(), keep = FluidAgeing.newFluidAge(Y.CULTURE_KEEPER.ageing, Y.CULTURE_KEEPER.ledger(), now, place) }
    end,
    goesOff = function(lot, now, place, fire, isoObject)
        local keep = lot.data and lot.data.keep
        if not keep then return nil end
        local before = Y.cakeLotAge(lot)
        local keepWas = keep.age
        FluidAgeing.advance(keep, CAKE_AGEING, Y.CULTURE_KEEPER.ledger(), now, place)
        if isoObject then FluidAgeing.noteFire(keep, fire, isoObject, now) end
        -- The stretch's ageing counts by how wet they were over it, squared: the mean of the square from the wetness
        -- at its start to its end, so one long catch-up ages them as many short looks do. A stretch that dried them
        -- counts only up to dry.
        local dryWas = lot.data.dryWas or 0
        local share = 1
        if lot.dry.age > Y.CAKE_DRY_HOURS and lot.dry.age > dryWas then
            share = math.max(Y.CAKE_DRY_HOURS - dryWas, 0) / (lot.dry.age - dryWas)
        end
        local wasWet = 1 - math.min(dryWas / Y.CAKE_DRY_HOURS, 1)
        local nowWet = 1 - math.min(lot.dry.age / Y.CAKE_DRY_HOURS, 1)
        keep.age = keepWas + (keep.age - keepWas) * share * (wasWet * wasWet + wasWet * nowWet + nowWet * nowWet) / 3
        lot.data.dryWas = lot.dry.age
        local after = Y.cakeLotAge(lot)
        if after < CAKE_SPENT_DAYS then return nil end
        if before >= CAKE_SPENT_DAYS or after <= before then return 0 end
        return (CAKE_SPENT_DAYS - before) / (after - before)
    end,
    give = function(lot, inventory, state)
        if state == "dry" then
            inventory:AddItem(Y.DRIED_CAKES)
        elseif state == "wet" then
            local cakes = inventory:AddItem(Y.CAKES)
            if cakes and lot.data then
                Y.keepCulture(cakes)
                cakes:getModData().tpyKeep.base = Y.cakeLotAge(lot)
                Y.keepCulture(cakes)
            end
        end
    end,
})

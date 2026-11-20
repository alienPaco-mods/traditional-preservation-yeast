-- Checks the Fermenting Shelf with stand-ins for the engine: the World drawing each jar in its look and jar, the
-- right-click menu (status, Info, Put rows, Refresh Cultures, Take Done, Take Everything Off) and its hand jobs
-- (TPYShelf), what Shelf Info lists, its drop square, and that a shelf holding anything stays put. Run from the mod
-- folder: luajit tests/test_shelf.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near, list = H.check, H.near, H.list
H.useModPaths()
H.installClock(100)
H.installModData()
H.installEvents()
H.installGetText()

-- The mod's own modules, TP Core's and the mod's action load for real, vanilla's are left out.
local realRequire = require
require = function(name)
    if name:find("^TraditionalPreservation") or name:find("^TimedActions/TP") then return realRequire(name) end
end

local ui = H.installMenus()
function isClient() return false end
function isServer() return false end
function getNumActivePlayers() return 0 end
local temperature = 22
function getClimateManager()
    return { isUpdated = function() return true end, getTemperature = function() return temperature end, getHumidity = function() return 50 end }
end
local loaders = {}
MapObjects = { OnLoadWithSprite = function(name, handler) loaders[name] = handler end }
local cellSquares = {}
function getCell()
    return { getGridSquare = function(_, x, y, z) return cellSquares[x .. "," .. y .. "," .. z] end }
end
ISPanel = H.class("ISPanel")
ISCollapsableWindow = H.class("ISCollapsableWindow")
ArrayList = { new = function()
    local self = { items = {} }
    function self:add(x) table.insert(self.items, x) end
    function self:size() return #self.items end
    function self:get(i) return self.items[i + 1] end
    return self
end }
local given = {}
Actions = { addOrDropItem = function(_, item) table.insert(given, item) end }

local function square(x, z)
    local s = {}
    function s:getX() return x end
    function s:getY() return 0 end
    function s:getZ() return z end
    function s:getObjects() return list({}) end
    function s:isOutside() return false end
    function s:isInARoom() return true end
    H.shutRoom(s)
    cellSquares[x .. ",0," .. z] = s
    return s
end

-- A shelf facing faceIndex at x on level z.
local function shelf(faceIndex, x, z)
    local self = { square = square(x, z), sprites = {}, clears = 0, modData = {} }
    function self:getSprite() return { getName = function() return "traditionalpreservationyeast_01_" .. faceIndex end } end
    function self:getSquare() return self.square end
    function self:getModData() return self.modData end
    function self:hasModData() return true end
    function self:getObjectIndex() return 0 end
    function self:isOutside() return false end
    function self:clearAttachedAnimSprite() self.sprites = {} self.clears = self.clears + 1 end
    function self:addAttachedAnimSpriteByName(name) table.insert(self.sprites, name) end
    return self
end

-- What the player carries: cultures, flour and water, as the inventory and the reach both see them.
local function remove(item)
    for i, carried in ipairs(ui.carried) do
        if carried == item then return table.remove(ui.carried, i) end
    end
end
local inventory = { Remove = function(_, item) remove(item) end }
function inventory:containsRecursive(item)
    for _, carried in ipairs(ui.carried) do if carried == item then return true end end
    return false
end
function inventory:getAllTypeRecurse(fullType)
    local found = {}
    for _, carried in ipairs(ui.carried) do if carried:getFullType() == fullType then table.insert(found, carried) end end
    return list(found)
end
function inventory:getAllEvalRecurse(test)
    local found = {}
    for _, carried in ipairs(ui.carried) do if test(carried) then table.insert(found, carried) end end
    return list(found)
end
local playerObj = { getInventory = function() return inventory end, isTimedActionInstant = function() return false end }
function getSpecificPlayer() return playerObj end

local function newItem(fullType)
    local item = { fullType = fullType, modData = {} }
    function item:getFullType() return self.fullType end
    function item:getModData() return self.modData end
    function item:getContainer() return inventory end
    function item:getWorldItem() return nil end
    function item:getOutermostContainer() return nil end
    function item:isFavorite() return false end
    function item:getTex() return self.fullType .. ".png" end
    function item:setName(name) self.name = name end
    function item:getName() return self.name end
    function item:setCustomName() end
    function item:getFluidContainer() return nil end
    function item:getAge() return self.age or 0 end
    function item:setAge(age) self.age = age end
    function item:getOffAge() return self.offAge or 0 end
    function item:getOffAgeMax() return self.offAgeMax or 0 end
    function item:setOffAge(x) self.offAge = x end
    function item:setOffAgeMax(x) self.offAgeMax = x end
    return item
end
function instanceItem(fullType) return newItem(fullType) end
local function flour(uses)
    local item = newItem("Base.Flour2")
    item.uses = uses
    function item:getCurrentUses() return self.uses end
    function item:setCurrentUses(x) self.uses = x end
    return item
end
local function water(litres)
    local bottle = H.vessel("Water Bottle", "Water", litres, 1)
    local container = bottle:getFluidContainer()
    function container:removeFluid(taken) litres = litres - taken end
    bottle.getContainer = function() return inventory end
    return bottle, function() return litres end
end

dofile("42/media/lua/shared/TraditionalPreservationYeast.lua")
dofile("42/media/lua/server/TraditionalPreservationYeastWorld.lua")
dofile("42/media/lua/client/TraditionalPreservationYeastShelfUI.lua")
local Y, World, ShelfUI = TraditionalPreservationYeast, TraditionalPreservationYeastWorld, TraditionalPreservationYeastShelfUI
local handlers = H.handlers.OnFillWorldObjectContextMenu
local onFillMenu = handlers[#handlers]

local function tick(times)
    for _ = 1, times do H.fire("OnTick") end
end
local function culture(jar, start)
    local item = newItem(Y.FERMENTING)
    Y.putInJar(item, jar or "Base.EmptyJar")
    item.modData.tpyStart = start
    Y.startRun(item, H.hours, "Sheltered")
    return item
end

-- The World: each jar in its look and jar, in the order they went on.
check("the map loader knows all four faces", loaders.traditionalpreservationyeast_01_0 and loaders.traditionalpreservationyeast_01_3)
check("a jar's sprite: glass fresh, slot 0, face 2", World.jarSprite(2, 0, 0, 0) == "traditionalpreservationyeast_01_6")
check("clay hungry, slot 1", World.jarSprite(2, 1, 5, 1) == "traditionalpreservationyeast_01_250")
check("a fruit start in glass after the grid", World.jarSprite(2, 2, 7, 0) == "traditionalpreservationyeast_01_434")
check("in clay it shows fresh", World.jarSprite(2, 3, 7, 1) == World.jarSprite(2, 3, 0, 1))
local kitchen = shelf(2, 1, 0)
local record = Y.shelfOf(kitchen)
Y.putJar(record, culture("Base.EmptyJar"), H.hours, "Sheltered")
Y.putJar(record, culture("Base.ClayJar", "potato"), H.hours, "Sheltered")
Y.putJar(record, culture("Base.EmptyJar", "fruit"), H.hours, "Sheltered")
loaders.traditionalpreservationyeast_01_2(kitchen)
tick(30)
check("each jar gets its sprite, in the order they went on", table.concat(kitchen.sprites, " ") == World.jarSprite(2, 0, 0, 0)
    .. " " .. World.jarSprite(2, 1, 0, 1) .. " " .. World.jarSprite(2, 2, 7, 0))
tick(30)
check("an unchanged shelf is left alone", kitchen.clears == 1)

-- The menu: an empty shelf, two cultures carried, a little flour, no water.
local empty = shelf(0, 3, 0)
local function menuFor(station)
    local context = H.menu()
    onFillMenu(0, context, { station }, false)
    return context, context.options[1].subOption
end
local function named(menu, prefix)
    for _, option in ipairs(menu.options) do
        if option.name:sub(1, #prefix) == prefix then return option end
    end
end
local function choose(option) option.onSelect(option.target, unpack(option.args)) end
local function runQueued()
    local queued = ui.queued
    ui.queued = {}
    for _, action in ipairs(queued) do
        action.setActionAnim = function() end
        if action:isValid() then
            action:start()
            action:complete()
        end
    end
end

ui.carried = { culture("Base.ClayJar"), culture("Base.EmptyJar", "fruit") }
local context, menu = menuFor(empty)
check("the shelf's own entry, with its icon", context.options[1].name == "Fermenting Shelf"
    and context.options[1].iconTexture == "media/textures/Item_FermentingShelf.png")
check("the status row first, greyed: what it holds", menu.options[1].name == "Jars: 0 / 5" and menu.options[1].isDisabled)
check("then its Info row, the station's full name, and the same at the bottom of the main menu",
    menu.options[2].name == "Fermenting Shelf Info" and context.options[2].name == "Fermenting Shelf Info")
local put = named(menu, "Put Fermenting")
check("Put Fermenting Culture on the Shelf: One, All (2)", put and put.subOption.options[1].name == "One"
    and put.subOption.options[2].name == "All (2)")
check("no refresh with nothing on", named(menu, "Refresh") == nil)
local done = named(menu, "Take Done (0)")
check("Take Done (0) greyed: nothing on it", done.isDisabled and done.toolTip.description == "Nothing is on the shelf.")
check("every row has an icon", (function()
    for _, option in ipairs(menu.options) do if not option.iconTexture then return false end end
    return true
end)())

choose(put.subOption.options[2])
check("All queues one action a jar, the moves first", #ui.queued == 2 and ui.queued[1].mode == "put" and #ui.moved == 2 and ui.cleared == 0)
runQueued()
record = Y.shelfOf(empty)
check("two jars on, gone from the hands", #record.jars == 2 and #ui.carried == 0 and record.jars[2].start == "fruit")
local function canPickUp() return ISMoveableSpriteProps.canPickUpMoveable({}, playerObj, empty:getSquare(), empty) end
check("a shelf holding jars can't be picked up (no station moves mid-process)", canPickUp() == false)

-- A day on: both hungry. Refresh wants flour and water carried.
for _ = 1, 25 do
    H.setHours(H.hours + 1)
    H.fire("EveryTenMinutes")
end
context, menu = menuFor(empty)
local refresh = named(menu, "Refresh Cultures (2)")
check("hungry jars: Refresh Cultures (2), greyed without flour", refresh and refresh.isDisabled
    and refresh.toolTip.description:find("no flour", 1, true) ~= nil)
ui.carried = { flour(1) }
context, menu = menuFor(empty)
check("and without water", named(menu, "Refresh").toolTip.description:find("no water", 1, true) ~= nil)
local bottle, litres = water(1)
ui.carried = { flour(1), bottle }
context, menu = menuFor(empty)
refresh = named(menu, "Refresh")
check("with both it's open, its help saying how many are hungry", not refresh.isDisabled
    and refresh.toolTip.description:find("Hungry now: 2", 1, true) ~= nil)
choose(refresh)
runQueued()
local states = {}
for _, jar in ipairs(Y.shelfNow(empty).jars) do table.insert(states, Y.jarState(jar)) end
check("one use of flour feeds the hungriest one; the other stays hungry", table.concat(states, ",") == "working,hungry"
    or table.concat(states, ",") == "hungry,working")
check("the flour used up is gone, and a tenth of a litre of water", #ui.carried == 1 and ui.carried[1] == bottle and near(litres(), 0.9))

-- Shelf Info's rows and drop square.
local shelfRecord, place = Y.shelfNow(empty)
local view = ShelfUI.view(shelfRecord, place)
check("a row a jar, named by its start", #view.rows == 2 and view.rows[1].name == "FermentingYeastJar"
    and view.rows[2].name == "FermentingYeastJar (Fruit)")
local hungryRow
for _, row in ipairs(view.rows) do if row.status.state == "hungry" then hungryRow = row end end
check("a hungry row says so, and when it goes off in amber at its right", hungryRow.text == "Hungry: refresh it"
    and hungryRow.warning:find("Off in", 1, true) ~= nil and hungryRow.note == nil)
local InfoWindow = require "TraditionalPreservationCore/InfoWindow"
local function bandWord(v) local word, text, look = ShelfUI.band(v) return word:match("Band(%a+)$"), text, look end
local word, _, look = bandWord(view)
check("a hungry jar: hungry, amber", word == "Hungry" and look == InfoWindow.BAND_WAITING)
local function row(state, extra)
    local status = { state = state }
    for k, v in pairs(extra or {}) do status[k] = v end
    return { status = status }
end
check("empty: grey", bandWord({ rows = {}, hungry = 0 }) == "Empty")
check("a jar gone off goes first", bandWord({ rows = { row("off"), row("hungry") }, hungry = 1 }) == "Lost")
check("every jar done: done", bandWord({ rows = { row("done"), row("done") }, hungry = 0 }) == "Done")
check("none working: waiting", bandWord({ rows = { row("working") }, hungry = 0 }) == "Waiting")
local text
word, text = bandWord({ rows = { row("working", { hungryIn = 20 }), row("working") }, hungry = 0, soonest = 50 })
check("fermenting: the next to go hungry, sooner than done", word == "Fermenting" and text:find("hungry in", 1, true) ~= nil)
word, text = bandWord({ rows = { row("working", { hungryIn = 20 }) }, hungry = 0, soonest = 5 })
check("or the next done, when that is sooner", text:find("done in", 1, true) ~= nil)
check("the jars as five cells", ShelfUI.holding(view).cells == 5 and ShelfUI.holding(view).filled == 2)
check("both on the Fermenting tab", view.rows[1].tab == view.rows[2].tab)
local judged = ShelfUI.dropJudge(shelfRecord, { culture(), newItem(Y.ACTIVE) })
check("the cells take cultures only, a cell a jar, saying why not the rest", #judged.take == 1 and judged.cells == 1
    and judged.refused == "Only Fermenting and Fed Cultures go on the shelf.")
local full = { jars = { 1, 2, 3, 4, 5 } }
check("and refuses on a full shelf", #ShelfUI.dropJudge(full, { culture() }).take == 0)

-- Taking off: a jar part way comes back as it was (its start and run kept), and the shelf can be picked up again.
given = {}
ShelfUI.take(playerObj, empty, view.allIds)
runQueued()
check("Take All gives every jar back as it was", #given == 2 and given[1]:getFullType() == Y.FERMENTING
    and given[1].modData.tpyRun ~= nil and (given[1].modData.tpyStart == "fruit" or given[2].modData.tpyStart == "fruit"))
check("an empty shelf can be picked up", canPickUp() ~= false)
check("and no translator warnings", #H.textWarnings == 0)

-- Weather
H.fire("EveryTenMinutes")
check("the World records the weather", Y.getLedger().temperature == 22)

H.done()

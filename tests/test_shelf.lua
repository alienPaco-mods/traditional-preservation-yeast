-- Checks the Fermenting Shelf's jars and its popup with stand-ins for the engine. Run from the mod folder:
-- luajit tests/test_shelf.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near, list = H.check, H.near, H.list
H.useModPaths()
H.installClock(100)
H.installModData()
H.installEvents()
H.installGetText()

-- The mod's own modules load for real, vanilla's are left out.
local realRequire = require
require = function(name)
    if name:find("^TraditionalPreservationYeast") or name:find("^TraditionalPreservationCore/") then
        return realRequire(name)
    end
end

-- Engine stand-ins
-- A culture item in jar (a full type; none: one made before jars were noted).
local function item(fullType, jar)
    local self = { modData = { tpyJar = jar } }
    function self:getFullType() return fullType end
    function self:getModData() return self.modData end
    return self
end
function isClient() return false end
ComponentType = { Resources = "Resources", CraftLogic = "CraftLogic" }
ResourceIO = { Input = "Input", Output = "Output" }
ResourceType = { Item = "Item" }
ArrayList = { new = function() return list({}) end }
function getPlayer() return {} end
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
CraftLogicUILogic = {
    new = function(_, _, logic)
        return { getCraftLogic = function() return logic end, getItemsInProgress = function() return logic.inProgress end }
    end,
}
ScriptManager = { instance = { getCraftRecipe = function() return { Load = function() end } end } }

local function square(x, z)
    local s = {}
    function s:getX() return x end
    function s:getY() return 0 end
    function s:getZ() return z end
    function s:getObjects() return H.list({}) end
    cellSquares[x .. ",0," .. z] = s
    return s
end

local function recipeData(progress, count)
    local craftRecipeData = { modData = {}, progress = progress, count = count, elapsed = 0 }
    function craftRecipeData:getModData() return self.modData end
    function craftRecipeData:setElapsedTime(elapsedTime) self.elapsed = elapsedTime end
    function craftRecipeData:getAllConsumedItems() return list(self.consumed or {}) end
    function craftRecipeData:getRecipe()
        return { getTime = function() return 120 * 3600 end, getName = function() return "TraditionalPreservationYeast.FermentCulture" end }
    end
    return craftRecipeData
end

-- A shelf facing faceIndex, with waiting jars, running batches and finished output items.
local function shelf(faceIndex, x, z, outside, waiting, batches, outputs)
    local logic = { inProgress = {} }
    for _, batch in ipairs(batches) do logic.inProgress[batch] = { jar = batch.count } end
    function logic:getInputsGroupName() return "in" end
    function logic:getOutputsGroupName() return "out" end
    function logic:getProgress(craftRecipeData) return craftRecipeData.progress end
    local items = {}
    for _, fullType in ipairs(outputs) do table.insert(items, item(fullType)) end
    local resources = {}
    function resources:getResourcesFromGroup(group)
        if group == "in" then
            local jars = {}
            for i = 1, waiting do jars[i] = item("TraditionalPreservationYeast.FermentingYeastJar") end
            return list({ { storedSize = function() return waiting end, getStoredItems = function() return list(jars) end } })
        end
        return list({ { getStoredItems = function() return list(items) end } })
    end
    local shelf = { square = square(x, z), sprites = {}, clears = 0 }
    function shelf:getComponent(componentType) return componentType == "Resources" and resources or logic end
    function shelf:getSprite() return { getName = function() return "traditionalpreservationyeast_01_" .. faceIndex end } end
    function shelf:getSquare() return self.square end
    function shelf:getObjectIndex() return 0 end
    function shelf:isOutside() return outside end
    function shelf.square:isOutside() return outside end
    function shelf.square:isInARoom() return not outside end
    H.shutRoom(shelf.square)
    function shelf:clearAttachedAnimSprite() self.sprites = {} self.clears = self.clears + 1 end
    function shelf:addAttachedAnimSpriteByName(name) table.insert(self.sprites, name) end
    return shelf
end

local function tick(times)
    for _ = 1, times do H.fire("OnTick") end
end

dofile("42/media/lua/shared/TraditionalPreservationYeast.lua")
dofile("42/media/lua/server/TraditionalPreservationYeastShelf.lua")
local vanillaAdds, halos, queuedActions = 0, {}, {}
ISCraftLogicPanel = { ItemSlotAddItems = function() vanillaAdds = vanillaAdds + 1 end }
ISItemSlot = { defaultVerifyItem = function() return true end, onMouseUp = function() end }
instanceof = function() return true end
HaloTextHelper = { addBadText = function(_, text) table.insert(halos, text) end }
ISEntityUI = { WalkToEntity = function() return true end }
ISItemSlotAddAction = { new = function(_, _, _, item, resource) return { item = item, resource = resource } end }
ISTimedActionQueue = { add = function(action) table.insert(queuedActions, action) end }
ISWidgetCraftLogicOutputProgress = { updateProgressItems = function(self) self.vanillaRan = true end }
ISMoveableSpriteProps = { canPlaceMoveable = function() return true end }
-- What TP Core's StationInfo and InfoWindow derive from; the shelf's provider is kept here instead of hooked.
ISPanel = H.class("ISPanel")
ISCollapsableWindow = H.class("ISCollapsableWindow")
local shelfInfo
require("TraditionalPreservationCore/StationInfo").add = function(provider) shelfInfo = provider end
dofile("42/media/lua/client/TraditionalPreservationYeastShelfUI.lua")
local Y = TraditionalPreservationYeast
Y.getLedger()

-- Jars
check("the map loader knows all four faces", loaders.traditionalpreservationyeast_01_0 and loaders.traditionalpreservationyeast_01_3)
local halfway, fresh = recipeData(0.6, 1), recipeData(0.1, 2)
local kitchen = shelf(2, 1, 0, false, 1, { fresh, halfway }, { "TraditionalPreservationYeast.ActiveCulture" })
loaders.traditionalpreservationyeast_01_2(kitchen)
tick(30)
-- One done, one halfway, two fresh running, one fresh waiting: looks 2,1,0,0,0 in slots 0-4 of face 2.
check("each jar gets its sprite, finished first", table.concat(kitchen.sprites, " ") ==
    "traditionalpreservationyeast_01_46 traditionalpreservationyeast_01_30 traditionalpreservationyeast_01_14 "
    .. "traditionalpreservationyeast_01_18 traditionalpreservationyeast_01_22")
local looks = TraditionalPreservationYeastShelf.jarLooks({ { jar = "Base.ClayJar" } }, { { progress = 0.7, count = 2, jars = { "Base.ClayJarGlazed" } } }, { { jar = "Base.JarCrafted" } })
check("each jar's look and kind: done glass, halfway glazed, halfway glass (an old run), fresh clay",
    #looks == 4 and looks[1][1] == 2 and looks[1][2] == 0 and looks[2][1] == 1 and looks[2][2] == 2
    and looks[3][2] == 0 and looks[4][1] == 0 and looks[4][2] == 1)
local fed = TraditionalPreservationYeastShelf.jarLooks({ { jar = "Base.ClayJar", fed = true } }, { { progress = 0.1, count = 1, jars = {}, fed = true } }, { { jar = "Base.ClayJarGlazed", fed = true } })
check("fed cultures rise and finish in their own looks", fed[1][1] == 4 and fed[1][2] == 2 and fed[2][1] == 3 and fed[3][1] == 3 and fed[3][2] == 1)
check("running cultures learn their place", halfway.modData.place == "Sheltered" and fresh.modData.place == "Sheltered")
tick(30)
check("an unchanged shelf is left alone", kitchen.clears == 1)

local downstairs = recipeData(0.2, 1)
local cellar = shelf(0, 2, -1, false, 0, { downstairs }, {})
TraditionalPreservationYeastShelf.track(cellar)
tick(30)
check("a basement shelf is a basement", downstairs.modData.place == "Basement" and cellar.sprites[1] == "traditionalpreservationyeast_01_4")

-- The stale-station fix: once its chunk unloads the cell no longer returns its square, though the object keeps it.
cellSquares["2,0,-1"] = {}
cellar.sprites = {}
downstairs.progress = 0.9
TraditionalPreservationYeastShelf.track(cellar)
tick(30)
check("an unloaded shelf is dropped, not refreshed", #cellar.sprites == 0)

-- Weather
H.setHours(110)
H.fire("EveryTenMinutes")
local ledger = Y.getLedger()
check("the shelf file records the weather", ledger.temperature == 22 and near(ledger.cultureOpen, 10) and ledger.lastHour == 110)

-- Popup
local running = recipeData(0, 1)
Y.onFermentStart(running)
running.modData.place = "Open"
temperature = 10
H.setHours(120)
H.fire("EveryTenMinutes")
Y.onFermentUpdate(running)
local slot = { craftRecipeData = running }
local widget = { progressItems = { getItemSlots = function() return { slot } end } }
ISWidgetCraftLogicOutputProgress.updateProgressItems(widget)
check("vanilla's list still runs", widget.vanillaRan and slot.drawTooltip)

local lines = {}
local tooltip = { width = 0 }
function tooltip:getFont() end
function tooltip:DrawText() end
function tooltip:adjustWidth() end
function tooltip:getLineSpacing() return 10 end
function tooltip:beginLayout()
    return {
        addItem = function()
            local item = {}
            function item:setLabel(text) self.label = text end
            function item:setValue(text, r, g, b) self.value, self.colour = text, { r, g, b } end
            table.insert(lines, item)
            return item
        end,
        render = function() return 40 end,
    }
end
function tooltip:endLayout() end
function tooltip:setHeight() end
function tooltip:getWidth() return self.width end
function tooltip:setWidth(width) self.width = width end
slot.drawTooltip(slot, tooltip)
local shown = {}
for _, item in ipairs(lines) do table.insert(shown, item.label .. " " .. item.value) end
-- 10 hours at 40% is 4 of 120; 116 left at 40% is 290 hours.
check("the popup's lines", table.concat(shown, " | ") ==
    "Progress: 3% | Time Remaining: 12d 2h, if the temperature holds | Temperature: 10 C (Open air) | Working Rate: 40%")
check("a slow rate is coloured", lines[4].colour[2] == 0.7 and lines[1].colour[2] == 1)
check("and no translator warnings", #H.textWarnings == 0)
check("the popup is wide enough", tooltip.width == 150)

-- A culture that has just finished hands its data back to the engine's pool before its slot goes.
function running:getRecipe() return nil end
lines = {}
slot.drawTooltip(slot, tooltip)
check("a culture that has just finished draws nothing", #lines == 0)

-- The info block in the shelf's window: the kitchen shelf (indoors: the season's 22 C) with two batches, a culture
-- waiting and one finished.
halfway.modData.workHours, fresh.modData.workHours = 72, 12
local block = shelfInfo(kitchen)
local rows = {}
for _, row in ipairs(block.rows) do table.insert(rows, getText(row[1]) .. " " .. row[2]) end
check("the block's rows", table.concat(rows, " | ") == "Place Indoors | Temperature 22 C | Working rate 100%")
check("a numbered bar a batch, furthest along first", #block.bars == 2 and near(block.bars[1].share, 0.6)
    and block.bars[1].text == "1. Cultures: 1" and block.bars[2].text == "2. Cultures: 2")
check("with its time left", block.bars[1].progressText == "60%, 2 d 0 h left")
check("full speed is green", block.bars[1].colour[1] == 0.35)
check("waiting, finished and the weather note", table.concat(block.notes, " | ") == "Loaded and not started: 1 (press Craft) | "
    .. "Finished and waiting to be taken: 1 | Times left assume the temperature holds as it is now.")
check("anything else gets no block", shelfInfo({ getSprite = function() return { getName = function() return "x" end } end }) == nil)

-- Slots: five cultures, each needing an output slot, finished ones not yet taken counting too
local function shelfSlot(stored, freeOutputs, sprite)
    local logic = { getFreeOutputSlotCount = function() return freeOutputs end, getCurrentRecipe = function() return nil end }
    local entity = {
        getSprite = function() return { getName = function() return sprite or "traditionalpreservationyeast_01_0" end } end,
        getComponent = function() return logic end,
    }
    local resource = {
        getIO = function() return ResourceIO.Input end,
        getGameEntity = function() return entity end,
        storedSize = function() return stored end,
        getFreeItemCapacity = function() return 5 - stored end,
    }
    return { resource = resource }, entity, logic
end
local function add(slot, entity, logic, count)
    halos, queuedActions = {}, {}
    local items = {}
    for i = 1, count do items[i] = {} end
    ISCraftLogicPanel.ItemSlotAddItems({}, entity, slot, items, logic)
end
local slot, entity, logic = shelfSlot(0, 5)
add(slot, entity, logic, 7)
check("an empty shelf takes five of seven cultures and says it's full", #queuedActions == 5 and halos[1] == getText("IGUI_TraditionalPreservationYeast_Full"))
check("each queued culture checks again when it runs", queuedActions[1].canAddItem(queuedActions[1]))
slot, entity, logic = shelfSlot(2, 4)
add(slot, entity, logic, 3)
check("cultures waiting to go in count against the room", #queuedActions == 2)
check("and the slot isn't green when there's none", not ISItemSlot.defaultVerifyItem({}, shelfSlot(3, 3), {}))
check("but is with room", ISItemSlot.defaultVerifyItem({}, shelfSlot(2, 3), {}))
local other, otherEntity = shelfSlot(0, 5, "carpentry_02_122")
add(other, otherEntity, nil, 1)
check("other stations go to vanilla", vanillaAdds == 1 and #queuedActions == 0)

H.done()

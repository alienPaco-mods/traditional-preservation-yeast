-- Checks the Fermenting Shelf's jars and its popup with stand-ins for the engine. Run from the mod folder:
-- luajit tests/test_shelf.lua
local H = dofile((os.getenv("TPCORE") or "../_tpcore") .. "/tests/harness.lua")
local check, near, list = H.check, H.near, H.list
H.useModPaths()
H.installClock(100)
H.installModData()
H.installEvents()
H.installGetText()

-- The mod's own modules load for real, vanilla's are left out.
local realRequire = require
require = function(name)
    if name:find("^TraditionalPreservationYeast/") then return realRequire(name) end
end

-- Engine stand-ins
function isClient() return false end
ComponentType = { Resources = "Resources", CraftLogic = "CraftLogic" }
ResourceIO = { Input = "Input", Output = "Output" }
ResourceType = { Item = "Item" }
ArrayList = { new = function() return list({}) end }
function getPlayer() return {} end
local temperature = 22
function getClimateManager() return { getTemperature = function() return temperature end } end
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
    cellSquares[x .. ",0," .. z] = s
    return s
end

local function recipeData(progress, count)
    local data = { modData = {}, progress = progress, count = count, elapsed = 0 }
    function data:getModData() return self.modData end
    function data:getElapsedTime() return self.elapsed end
    function data:setElapsedTime(value) self.elapsed = value end
    function data:getRecipe()
        return { getTime = function() return 120 * 3600 end, getName = function() return "TraditionalPreservationYeast.FermentCulture" end }
    end
    return data
end

-- A shelf facing faceIndex, with waiting jars, running batches and finished output items.
local function shelf(faceIndex, x, z, outside, waiting, batches, outputs)
    local logic = { inProgress = {} }
    for _, batch in ipairs(batches) do logic.inProgress[batch] = { jar = batch.count } end
    function logic:getInputsGroupName() return "in" end
    function logic:getOutputsGroupName() return "out" end
    function logic:getProgress(data) return data.progress end
    local items = {}
    for _, fullType in ipairs(outputs) do table.insert(items, { getFullType = function() return fullType end }) end
    local resources = {}
    function resources:getResourcesFromGroup(group)
        if group == "in" then return list({ { storedSize = function() return waiting end } }) end
        return list({ { getStoredItems = function() return list(items) end } })
    end
    local object = { square = square(x, z), sprites = {}, clears = 0, overlay = true }
    function object:getComponent(kind) return kind == "Resources" and resources or logic end
    function object:getSprite() return { getName = function() return "traditionalpreservationyeast_01_" .. faceIndex end } end
    function object:getSquare() return self.square end
    function object:getObjectIndex() return 0 end
    function object:isOutside() return outside end
    function object:hasOverlaySprite() return self.overlay end
    function object:setOverlaySprite(sprite) self.overlay = sprite ~= nil end
    function object:clearAttachedAnimSprite() self.sprites = {} self.clears = self.clears + 1 end
    function object:addAttachedAnimSpriteByName(name) table.insert(self.sprites, name) end
    return object
end

local function tick(times)
    for _ = 1, times do H.fire("OnTick") end
end

dofile("42/media/lua/shared/TraditionalPreservationYeast.lua")
dofile("42/media/lua/server/TraditionalPreservationYeastShelf.lua")
ISCraftLogicPanel = { ItemSlotAddItems = function() end }
ISWidgetCraftLogicOutputProgress = { updateProgressItems = function(self) self.vanillaRan = true end }
ISMoveableSpriteProps = { canPlaceMoveable = function() return true end }
dofile("42/media/lua/client/TraditionalPreservationYeastShelfUI.lua")
local Y = TraditionalPreservationYeast
Y.getLedger()

-- Jars
check("the map loader knows all four faces", loaders.traditionalpreservationyeast_01_0 and loaders.traditionalpreservationyeast_01_3)
local halfway, fresh = recipeData(0.6, 1), recipeData(0.1, 2)
local kitchen = shelf(2, 1, 0, false, 1, { fresh, halfway }, { "Base.Yeast", "Base.EmptyJar" })
loaders.traditionalpreservationyeast_01_2(kitchen)
tick(30)
-- One done, one halfway, two fresh running, one fresh waiting: states 2,1,0,0,0 in slots 0-4 of face 2.
check("each jar gets its sprite, finished first", table.concat(kitchen.sprites, " ") ==
    "traditionalpreservationyeast_01_46 traditionalpreservationyeast_01_30 traditionalpreservationyeast_01_14 "
    .. "traditionalpreservationyeast_01_18 traditionalpreservationyeast_01_22")
check("an old shelf's single overlay goes", not kitchen.overlay)
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
check("the shelf file records the weather", ledger.temperature == 22 and near(ledger.Open, 10) and ledger.lastHour == 110)

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
    "Progress: 3% | Time Remaining: 12d 2h, if the temperature holds | Temperature: 10 C outdoors | Working Rate: 40%")
check("a slow rate is coloured", lines[4].colour[2] == 0.7 and lines[1].colour[2] == 1)
check("and no translator warnings", #H.textWarnings == 0)
check("the popup is wide enough", tooltip.width == 150)

-- A culture that has just finished hands its data back to the engine's pool before its slot goes.
function running:getRecipe() return nil end
lines = {}
slot.drawTooltip(slot, tooltip)
check("a culture that has just finished draws nothing", #lines == 0)

H.done()

-- Traditional Preservation (Yeast) B42: the Fermenting Shelf's right-click menu (what it holds, Info, Put rows for the
-- cultures carried, Refresh Cultures, Take Done, Take Everything Off; TPYShelf does the hand jobs) and Shelf Info,
-- its info window (TP Core's InfoWindow on the settled look: band, Station block, the jars as cells taking a drag, a
-- row a jar in TP Core's scrolling list, a tab for Fermenting and one for Fed cultures when both are on it, the
-- buttons). Also the look that keeps Active Culture by place
-- (TP Core's PlaceKeepingUI). A shelf holding anything stays where it is; none is put down in front of a door.
require "TimedActions/TPYShelf"
local InfoWindow = require "TraditionalPreservationCore/InfoWindow"
local StationReport = require "TraditionalPreservationCore/StationReport"
local PiecesUI = require "TraditionalPreservationCore/PiecesUI"
local UI = require "TraditionalPreservationCore/UI"
local Station = require "TraditionalPreservationCore/Station"
local Weather = require "TraditionalPreservationCore/Weather"
local PlaceKeepingUI = require "TraditionalPreservationCore/PlaceKeepingUI"
local KeepingTooltip = require "TraditionalPreservationCore/KeepingTooltip"
local Tiles = require "TraditionalPreservationYeast/Tiles"

TraditionalPreservationYeastShelfUI = TraditionalPreservationYeastShelfUI or {}
local ShelfUI = TraditionalPreservationYeastShelfUI
local Y = TraditionalPreservationYeast

local KEY = "IGUI_TraditionalPreservationYeast_"
local MENU = "ContextMenu_TraditionalPreservationYeast_"
local SHELF_ICON = "media/textures/Item_FermentingShelf.png"
local STATION_ICON = "media/textures/TPStation_FermentingShelf.png"   -- Shelf Info's Station block (TP Core's tools/station_icons.py)
local JAR_CELL = "media/textures/TPCell_Jar.png"                       -- the jars' cells (TP Core's tools/cell_patterns.py)
local CELL_COLOUR = { 0.78, 0.74, 0.55 }
local REFRESH_ICON = "media/textures/Item_FermentingCulture_glass.png"
local DONE_ICON, RETURNED_ICON = "media/textures/Item_ActiveCulture_glass.png", "media/ui/Entity/Icon_Returned_48x48.png"
local COLOURS = { working = { 0.35, 0.7, 0.35 }, hungry = { 0.8, 0.6, 0.2 }, off = { 0.6, 0.3, 0.25 },
    done = { 0.35, 0.7, 0.35 }, spent = { 0.6, 0.3, 0.25 } }
-- The icon a jar's row shows, by what it is now (tools/build_shelf_tileset.py, ICON_ITEMS).
local ICONS = { working = "FermentingCulture", hungry = "FermentingCulture", off = "FermentingCulture",
    done = "ActiveCulture", spent = "ActiveCulture" }
local FED_ICONS = { working = "FedCulture", done = "ActiveCultureHopped", spent = "ActiveCultureHopped" }

local isShelf = Station.kinds(Tiles.PREFIX, Tiles.FACE_COUNT, { shelf = 0 })
ShelfUI.isShelf = isShelf

local function say(key, ...) return UI.say(KEY .. key, ...) end

local function shelfNow(station)
    if TraditionalPreservationYeastWorld then TraditionalPreservationYeastWorld.refresh(station) end
    return Y.shelfNow(station)
end

local function iconOf(jar, state)
    local name = (jar.kind == "fed" and FED_ICONS or ICONS)[state] or "FedCulture"
    return getTexture("media/textures/Item_" .. name .. "_" .. Y.jarKind(jar.jar) .. ".png")
end

-- A jar's name as its item has it: Fermenting Culture (Fruit), Fed Culture.
function ShelfUI.jarName(jar)
    if jar.kind == "fed" then return getItemNameFromFullType(Y.FED) end
    local name = getItemNameFromFullType(Y.FERMENTING)
    if jar.start == "plain" then return name end
    return getText(KEY .. "Start_" .. jar.start, name)
end

-- What the bar says.
function ShelfUI.barText(status)
    if status.state == "working" then
        if not status.hoursLeft then return say("JarWaits", UI.percent(status.progress)) end
        return say("JarLeft", UI.percent(status.progress), UI.durationText(status.hoursLeft))
    end
    return say("Jar_" .. status.state)
end

-- The line under the bar: when it goes hungry, off or Spent.
function ShelfUI.noteText(status)
    if status.hungryIn then return say("JarHungryIn", UI.durationText(status.hungryIn)) end
    if status.offIn then return say("JarOffIn", UI.durationText(status.offIn)) end
    if status.state == "done" and status.spentIn then return say("JarSpentIn", UI.durationText(status.spentIn * 24)) end
    return nil
end

-- The row's warning, amber at its right (all_info_mock): when a working jar goes hungry, or a hungry one off.
function ShelfUI.warningText(status)
    if status.hungryIn then return say("JarHungryIn", UI.shortDuration(status.hungryIn)) end
    if status.offIn then return say("JarOffInShort", UI.shortDuration(status.offIn)) end
    return nil
end

local function drawPopup(tooltip, jar, status, place, placeC)
    UI.drawTooltip(tooltip, function(layout)
        if jar.kind == "culture" then UI.addLine(layout, KEY .. "StartedWith", say("StartName_" .. jar.start)) end
        UI.addLine(layout, KEY .. "Progress", UI.percent(status.progress))
        if status.hoursLeft and status.state == "working" then
            UI.addLine(layout, KEY .. "TimeLeft", UI.durationText(status.hoursLeft))
        end
        local note = ShelfUI.noteText(status)
        if note then UI.addLine(layout, KEY .. "Watch", note) end
        UI.addLine(layout, KEY .. "Temperature", UI.placeText(place, placeC))
        UI.addRateLine(layout, KEY .. "Rate", status.rate)
    end)
end

-- One list row a jar (TP Core's PieceList). Its tab is Fermenting Culture or Fed Culture.
function ShelfUI.jarRow(jar, place, placeC)
    local status = Y.jarStatus(jar, placeC, place)
    local fed = jar.kind == "fed"
    return {
        icon = iconOf(jar, status.state), name = ShelfUI.jarName(jar), share = status.progress,
        colour = COLOURS[status.state], text = ShelfUI.barText(status), warning = ShelfUI.warningText(status),
        note = not ShelfUI.warningText(status) and ShelfUI.noteText(status) or nil,
        tab = getItemNameFromFullType(fed and Y.FED or Y.FERMENTING), tabOrder = fed and 2 or 1,
        popup = function(tooltip) drawPopup(tooltip, jar, status, place, placeC) end,
        status = status,
    }
end

-- Everything the menu and Shelf Info show: { place, placeC, rows, doneIds, allIds, hungry, refreshable, waitText }.
function ShelfUI.view(record, place)
    local placeC = Weather.placeTemperature(Y.getLedger(), place)
    local rows, doneIds, allIds, hungry, soonest = {}, {}, {}, 0, nil
    for _, jar in ipairs(record.jars) do
        local row = ShelfUI.jarRow(jar, place, placeC)
        table.insert(rows, row)
        table.insert(allIds, jar.id)
        local state = row.status.state
        if state ~= "working" and state ~= "hungry" then table.insert(doneIds, jar.id) end
        if state == "hungry" then hungry = hungry + 1 end
        if state == "working" and row.status.hoursLeft then soonest = math.min(soonest or math.huge, row.status.hoursLeft) end
    end
    local waitText
    if #record.jars == 0 then
        waitText = say("ShelfEmpty")
    elseif soonest then
        waitText = say("NoneDone", UI.durationText(soonest))
    else
        waitText = say("NoneDoneStopped")
    end
    return { place = place, placeC = placeC, rows = rows, doneIds = doneIds, allIds = allIds, hungry = hungry,
        refreshable = #Y.refreshable(record), waitText = waitText, count = #record.jars, soonest = soonest }
end

-- The band (all_info_mock), the worst first: empty; a jar gone off or Spent; a jar hungry; all done; none working
-- (too cold); else fermenting, with the next jar to go hungry or be done. Returns the word's key, the finished text
-- and the colours.
function ShelfUI.band(view)
    local count, lost, done, working, hungryIn = #view.rows, 0, 0, 0, nil
    for _, row in ipairs(view.rows) do
        local state = row.status.state
        if state == "off" or state == "spent" then lost = lost + 1 end
        if state == "done" then done = done + 1 end
        if state == "working" then working = working + 1 end
        if row.status.hungryIn then hungryIn = math.min(hungryIn or math.huge, row.status.hungryIn) end
    end
    if count == 0 then return KEY .. "BandEmpty", say("BandEmptyText"), InfoWindow.BAND_IDLE end
    if lost > 0 then return KEY .. "BandLost", say("BandLostText", tostring(lost), tostring(count)), InfoWindow.BAND_AT_RISK end
    if view.hungry > 0 then
        return KEY .. "BandHungry", say("BandHungryText", tostring(view.hungry), tostring(count)), InfoWindow.BAND_WAITING
    end
    if done == count then return KEY .. "BandDone", say("BandDoneText"), InfoWindow.BAND_WORKING end
    if not view.soonest then return KEY .. "BandWaiting", say("BandWaitingText"), InfoWindow.BAND_WAITING end
    if hungryIn and hungryIn < view.soonest then
        return KEY .. "BandFermenting", say("BandHungryInText", tostring(count), UI.shortDuration(hungryIn)), InfoWindow.BAND_WORKING
    end
    return KEY .. "BandFermenting", say("BandDoneInText", tostring(count), UI.shortDuration(view.soonest)), InfoWindow.BAND_WORKING
end

-- The jars as Holds' cells: one a jar, out of the shelf's five.
function ShelfUI.holding(view)
    return { kind = "cells", name = say("InfoJarsCells"), amount = say("InfoHoldsValue", tostring(view.count), tostring(Y.SHELF_JARS)),
        cells = Y.SHELF_JARS, filled = view.count, share = view.count / Y.SHELF_JARS, colour = CELL_COLOUR, pattern = JAR_CELL }
end

local function viewOf(station)
    local record, place = shelfNow(station)
    return ShelfUI.view(record, place)
end

-- Why Refresh Cultures can't be done now, or nil.
function ShelfUI.refreshRefusal(view, playerObj)
    if view.refreshable == 0 then return say("NothingToRefresh") end
    local can, short = Y.refreshesCarried(playerObj, view.refreshable)
    if can == 0 then return say("RefreshNeeds_" .. short, tostring(Y.REFRESH_FLOUR), UI.litres(Y.REFRESH_WATER_L * 1000)) end
    return nil
end

function ShelfUI.refreshHelp(view)
    return say("RefreshHelp", tostring(Y.REFRESH_FLOUR), UI.litres(Y.REFRESH_WATER_L * 1000), tostring(view.hungry))
end

-- The jobs, queued: the cultures into the inventory first, then the walk, then the hand jobs (vanilla's order).
function ShelfUI.put(playerObj, station, items)
    if #items == 0 then return end
    for _, item in ipairs(items) do ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item) end
    if not UI.walkTo(playerObj, station) then return end
    for _, item in ipairs(items) do ISTimedActionQueue.add(TPYShelf:new(playerObj, station, "put", item)) end
end

function ShelfUI.take(playerObj, station, ids)
    if #ids == 0 or not UI.walkTo(playerObj, station) then return end
    for _, id in ipairs(ids) do ISTimedActionQueue.add(TPYShelf:new(playerObj, station, "take", nil, id)) end
end

function ShelfUI.refresh(playerObj, station)
    if not UI.walkTo(playerObj, station) then return end
    ISTimedActionQueue.add(TPYShelf:new(playerObj, station, "refresh"))
end

-- The carried cultures the shelf takes, by type (Fermenting first, then Fed).
local PUT_TYPES = { Y.FERMENTING, Y.FED }
local function carriedCultures(playerObj, fullType)
    return UI.findItems(playerObj, function(item) return item:getFullType() == fullType end)
end

-- What Shelf Info's cells make of a dragged selection: the cultures it would put on, as many as fit (a cell a jar).
function ShelfUI.dropJudge(record, items)
    local take, refused = {}, nil
    local room = Y.shelfRoom(record)
    for _, item in ipairs(items) do
        if not Y.SHELF_TAKES[item:getFullType()] then
            refused = refused or say("NotACulture")
        elseif #take >= room then
            refused = refused or say("Full")
        else
            table.insert(take, item)
        end
    end
    if #take == 0 then return { take = take, lines = { refused or say("Full") }, refused = refused, cells = 0 } end
    local lines = { say("DropPut", tostring(#take), tostring(#items)), say("DropRoom", tostring(room)) }
    return { take = take, lines = lines, refused = #take < #items and refused or nil, cells = #take, pattern = JAR_CELL }
end

-- Shelf Info

local ShelfWindow = InfoWindow:derive("TraditionalPreservationYeastShelfWindow")

function ShelfWindow:new(playerObj, station)
    local o = InfoWindow.new(self, playerObj, station)
    o.title = getText("IGUI_CraftingWindow_FermentingShelf")
    return o
end

function ShelfWindow:refresh()
    self.shelfView = viewOf(self.station)
    local station, playerObj = self.station, self.playerObj
    self.drop = self.drop or { judge = function(items) return ShelfUI.dropJudge(Y.shelfOf(station), items) end,
        drop = function(take) ShelfUI.put(playerObj, station, take) end }
end

-- Shelf Info on the settled look (all_info_mock): the band, the Station block with the working rate, the jars as
-- cells with the barm lore beside them (cultures dragged onto them go on), a row a jar (when it goes hungry in amber
-- at its right), Refresh Cultures, Take Done and Take All, then notes.
function ShelfWindow:render()
    ISCollapsableWindow.render(self)
    if self.isCollapsed or not self.shelfView then return end
    local view = self.shelfView
    local station, playerObj = self.station, self.playerObj
    local word, text, look = ShelfUI.band(view)
    local y = self:band(getText(word), text, look[1], look[2])
    y = self:stationBlock(y, STATION_ICON, view.place, view.placeC, { { KEY .. "InfoRate", UI.percent(Y.cultureRate(view.placeC)) } })
    y = self:section(y, "IGUI_TraditionalPreservationCore_SectionHolds")
    local holding = ShelfUI.holding(view)
    holding.drop = self.drop
    y = self:holds(y, { holding }, say("ShelfLore"))
    if view.count > 0 then
        y = self:pieceListBlock(y, KEY .. "InfoJars", say("InfoJarsCount", tostring(view.count)), view.rows)
    end
    local refusal = ShelfUI.refreshRefusal(view, playerObj)
    local done, all = view.doneIds, view.allIds
    y = self:buttonRow(y, {
        { title = UI.say(MENU .. "Refresh", tostring(view.refreshable)), icon = REFRESH_ICON, enabled = refusal == nil,
          tooltip = refusal or ShelfUI.refreshHelp(view), onClick = function() ShelfUI.refresh(playerObj, station) end },
        { title = UI.say(MENU .. "TakeDone", tostring(#done)), icon = DONE_ICON, enabled = #done > 0,
          tooltip = #done == 0 and view.waitText or nil, onClick = function() ShelfUI.take(playerObj, station, done) end },
        { title = UI.say(MENU .. "TakeAllCount", tostring(#all)), icon = RETURNED_ICON, enabled = #all > 0,
          tooltip = #all > #done and say("TakeAllHelp") or nil, onClick = function() ShelfUI.take(playerObj, station, all) end },
    })
    self:drawNotes(y, { say("NoteRefresh", tostring(Y.HUNGRY_HOURS), tostring(Y.OFF_HOURS)), say("NoteDrag") })
end

function ShelfUI.open(playerObj, station)
    InfoWindow.open(ShelfWindow, playerObj, station)
end
StationReport.add(ShelfWindow, function(isoObject) return isShelf(isoObject) and isoObject or nil end)

-- The menu

local function addShelfMenu(context, playerObj, station)
    local record, place = shelfNow(station)
    local view = ShelfUI.view(record, place)
    local shelfIcon = getTexture(SHELF_ICON)
    local option = context:addOption(getText("IGUI_CraftingWindow_FermentingShelf"))
    option.iconTexture = shelfIcon
    local menu = context:getNew(context)
    context:addSubMenu(option, menu)

    local status = menu:addOption(say("MenuHolds", tostring(view.count), tostring(Y.SHELF_JARS)))
    status.isDisabled = true
    status.iconTexture = shelfIcon
    local lines = { UI.placeText(view.place, view.placeC) }
    for index, row in ipairs(view.rows) do table.insert(lines, index .. ". " .. row.name .. ": " .. row.text) end
    UI.tooltip(status, table.concat(lines, " <LINE> "))
    local info = menu:addOption(say("ShelfInfo"), playerObj, ShelfUI.open, station)
    info.iconTexture = shelfIcon
    UI.topInfo(context, say("ShelfInfo"), shelfIcon, playerObj, ShelfUI.open, station)

    for _, fullType in ipairs(PUT_TYPES) do
        local pieces = carriedCultures(playerObj, fullType)
        if #pieces > 0 then
            local row = { label = UI.say(MENU .. "Put", getItemNameFromFullType(fullType)), room = Y.shelfRoom(record),
                pieces = pieces, help = say("PutHelp"), noRoom = say("Full") }
            local put = PiecesUI.row(menu, row, function(chosen)
                if row.room > 0 then ShelfUI.put(playerObj, station, chosen) end
            end)
            put.iconTexture = pieces[1]:getTex()
        end
    end

    if view.refreshable > 0 then
        local refresh = menu:addOption(UI.say(MENU .. "Refresh", tostring(view.refreshable)), playerObj, ShelfUI.refresh, station)
        refresh.iconTexture = getTexture(REFRESH_ICON)
        local refusal = ShelfUI.refreshRefusal(view, playerObj)
        if refusal then UI.disable(refresh, refusal) else UI.tooltip(refresh, ShelfUI.refreshHelp(view)) end
    end

    -- Take Done is always there: greyed until a jar is done, saying when the next will be.
    local done, all = view.doneIds, view.allIds
    local finished = menu:addOption(UI.say(MENU .. "TakeDone", tostring(#done)), playerObj, ShelfUI.take, station, done)
    finished.iconTexture = getTexture(DONE_ICON)
    if #done == 0 then UI.disable(finished, view.waitText) end
    if #all > #done then
        local takeAll = menu:addOption(getText(MENU .. "TakeAll"), playerObj, ShelfUI.take, station, all)
        takeAll.iconTexture = shelfIcon
        UI.tooltip(takeAll, say("TakeAllHelp"))
    end
end

local function onFillContextMenu(playerNum, context, worldobjects, test)
    local seen = {}
    for _, isoObject in ipairs(worldobjects) do
        if isShelf(isoObject) and not seen[isoObject] then
            if test then return ISWorldObjectContextMenu.setTest() end
            seen[isoObject] = true
            addShelfMenu(context, getSpecificPlayer(playerNum), isoObject)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillContextMenu)

-- A shelf with any jar on it stays where it is (no station moves mid-process).
UI.keepInPlace(function(isoObject)
    if not isShelf(isoObject) or not isoObject:hasModData() then return nil end
    local movableData = isoObject:getModData().movableData
    local record = movableData and movableData[Y.SHELF_KEY]
    return (record ~= nil and #record.jars > 0) or nil
end)

-- The shelf is not put down in front of a door (TP Core's Doors).
UI.keepDoorsFree(Tiles.STATIONS)

-- Active Culture catches up on its keeping, and its name with it, as it is carried and as containers are opened.
PlaceKeepingUI.watch({ keep = TraditionalPreservationYeast.keepCulture }, TraditionalPreservationYeast.CULTURE_DAYS)
-- Its tooltip says how long it keeps where it is (TP Core's KeepingTooltip).
KeepingTooltip.add(TraditionalPreservationYeast.CULTURE_DAYS, function(item)
    return KeepingTooltip.keeperLines(TraditionalPreservationYeast.CULTURE_KEEPER, item)
end)

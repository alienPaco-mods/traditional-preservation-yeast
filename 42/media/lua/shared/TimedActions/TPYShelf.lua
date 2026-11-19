-- Traditional Preservation (Yeast): the hand jobs at a Fermenting Shelf (TraditionalPreservationYeastShelf.lua). "put"
-- puts one carried culture on (if there is still room when the hands are done), "take" takes one jar off by its id (what
-- it has become, Y.jarOutput), "refresh" feeds every Fermenting Culture on it that flour and water carried allow. One
-- jar an action for put and take, so a queue of them shows its progress and stops where the player stops it.
require "TimedActions/ISBaseTimedAction"
require "TraditionalPreservationYeast"

TPYShelf = ISBaseTimedAction:derive("TPYShelf")

local Y = TraditionalPreservationYeast
local Action = require "TraditionalPreservationCore/Action"
local DURATIONS = { put = 30, take = 30, refresh = 40 }
local REFRESH_TICKS_A_JAR = 20

local function carried(self)
    return self.item ~= nil and self.character:getInventory():containsRecursive(self.item)
end

function TPYShelf:isValid()
    if not self.station:getSquare() then return false end
    local record = Y.shelfOf(self.station)
    if self.mode == "put" then return carried(self) and Y.shelfRoom(record) > 0 end
    if self.mode == "take" then return Y.jarById(record, self.id) ~= nil end
    return #Y.refreshable(record) > 0
end

function TPYShelf:waitToStart()
    self.character:faceThisObject(self.station)
    return self.character:shouldBeTurning()
end

function TPYShelf:start()
    self:setActionAnim("Loot")
end

function TPYShelf:complete()
    local now = getGameTime():getWorldAgeHours()
    local record, place = Y.shelfNow(self.station, now)
    if self.mode == "put" then
        if carried(self) and Y.putJar(record, self.item, now, place) then Action.removeItem(self.item) end
    elseif self.mode == "take" then
        local jar = Y.takeJar(record, self.id)
        if jar then Actions.addOrDropItem(self.character, Y.jarOutput(jar, now, place)) end
    else
        Y.refreshWith(record, self.character)
    end
    if TraditionalPreservationYeastWorld then TraditionalPreservationYeastWorld.refresh(self.station) end
    return true
end

function TPYShelf:perform()
    ISBaseTimedAction.perform(self)
end

function TPYShelf:getDuration()
    if self.mode == "refresh" then
        return Action.duration(self.character, DURATIONS.refresh + REFRESH_TICKS_A_JAR * #Y.refreshable(Y.shelfOf(self.station)))
    end
    return Action.duration(self.character, DURATIONS[self.mode])
end

-- "put": item is the carried culture; "take": id is the jar's id on this shelf; "refresh": neither.
function TPYShelf:new(character, station, mode, item, id)
    local o = ISBaseTimedAction.new(self, character)
    o.station = station
    o.mode = mode
    o.item = item
    o.id = id
    o.maxTime = o:getDuration()
    return o
end

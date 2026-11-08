-- Traditional Preservation (Yeast) B42: shows one jar on each Fermenting Shelf per culture it holds, coloured
-- by that culture's own timer. SpriteOverlayConfig can only show one sprite for the
-- first batch, so this reads every batch and layers a sprite for each jar.
if isClient() then return end

TraditionalPreservationYeastShelf = TraditionalPreservationYeastShelf or {}

local SPRITE_PREFIX = "traditionalpreservationyeast_01_"
local FACE_COUNT = 4
local MAX_JARS = 5
local TICKS_PER_REFRESH = 30
local MAP_PRIORITY = 5

-- Keep in step with JAR_STATES in tools/build_shelf_tileset.py.
local STATE_FRESH, STATE_HALFWAY, STATE_DONE = 0, 1, 2
local HALFWAY_PROGRESS = 0.5

local tracked = {}
local ticksSinceRefresh = 0

local function getItems(resources, group, io)
    return resources:getResourcesFromGroup(group, ArrayList.new(), io, ResourceType.Item)
end

-- Oldest first: finished jars, then running batches by progress, then ones not started.
function TraditionalPreservationYeastShelf.jarStates(waiting, batches, finished)
    local states = {}
    for _ = 1, finished do table.insert(states, STATE_DONE) end

    table.sort(batches, function(a, b) return a.progress > b.progress end)
    for _, batch in ipairs(batches) do
        local state = batch.progress >= HALFWAY_PROGRESS and STATE_HALFWAY or STATE_FRESH
        for _ = 1, batch.count do table.insert(states, state) end
    end

    for _ = 1, waiting do table.insert(states, STATE_FRESH) end
    while #states > MAX_JARS do table.remove(states) end
    return states
end

local function countWaiting(resources, logic)
    local waiting = 0
    local inputs = getItems(resources, logic:getInputsGroupName(), ResourceIO.Input)
    for i = 0, inputs:size() - 1 do
        waiting = waiting + inputs:get(i):storedSize()
    end
    return waiting
end

-- A finished culture is on the shelf until both its yeast and its jar are taken.
local function countFinished(resources, logic)
    local yeast, jars = 0, 0
    local outputs = getItems(resources, logic:getOutputsGroupName(), ResourceIO.Output)
    for i = 0, outputs:size() - 1 do
        local stored = outputs:get(i):getStoredItems()
        for j = 0, stored:size() - 1 do
            if stored:get(j):getFullType() == "Base.Yeast" then
                yeast = yeast + 1
            else
                jars = jars + 1
            end
        end
    end
    return math.max(yeast, jars)
end

-- Also tells each running culture where its shelf stands, for its temperature.
local function readBatches(logic, uiLogic, place)
    local batches = {}
    for craftData, items in pairs(uiLogic:getItemsInProgress()) do
        craftData:getModData().place = place
        local count = 0
        for _, amount in pairs(items) do
            count = count + tonumber(tostring(amount))
        end
        table.insert(batches, { progress = logic:getProgress(craftData), count = count })
    end
    return batches
end

-- Keep in step with jar_index in tools/build_shelf_tileset.py.
local function jarSprite(faceIndex, slot, state)
    return SPRITE_PREFIX .. (FACE_COUNT + (state * MAX_JARS + slot) * FACE_COUNT + faceIndex)
end

function TraditionalPreservationYeastShelf.refresh(shelf)
    local entry = tracked[shelf]
    local resources = shelf:getComponent(ComponentType.Resources)
    local logic = shelf:getComponent(ComponentType.CraftLogic)
    local sprite = shelf:getSprite()
    if not entry or not resources or not logic or not sprite then return end

    local faceIndex = tonumber(string.sub(sprite:getName(), #SPRITE_PREFIX + 1))
    if not faceIndex then return end

    if not entry.uiLogic or entry.uiLogic:getCraftLogic() ~= logic then
        -- Its constructor reads the player's mod data, so it needs a real player.
        local player = getPlayer()
        if not player then return end
        entry.uiLogic = CraftLogicUILogic.new(player, shelf, logic)
    end

    local states = TraditionalPreservationYeastShelf.jarStates(countWaiting(resources, logic), readBatches(logic, entry.uiLogic, TraditionalPreservationYeast.placeOf(shelf)), countFinished(resources, logic))
    local signature = faceIndex .. ":" .. table.concat(states, ",")
    if signature == entry.signature then return end
    entry.signature = signature

    -- Shelves from before 0.3.0 show their jars as a single overlay.
    if shelf:hasOverlaySprite() then shelf:setOverlaySprite(nil) end
    shelf:clearAttachedAnimSprite()
    for slot, state in ipairs(states) do
        shelf:addAttachedAnimSpriteByName(jarSprite(faceIndex, slot - 1, state))
    end
end

function TraditionalPreservationYeastShelf.track(shelf)
    tracked[shelf] = tracked[shelf] or {}
end

local function onTick()
    ticksSinceRefresh = ticksSinceRefresh + 1
    if ticksSinceRefresh < TICKS_PER_REFRESH then return end
    ticksSinceRefresh = 0

    for shelf in pairs(tracked) do
        if shelf:getSquare() and shelf:getObjectIndex() >= 0 then
            TraditionalPreservationYeastShelf.refresh(shelf)
        else
            tracked[shelf] = nil
        end
    end
end

local function recordWeather()
    local Y = TraditionalPreservationYeast
    Y.advance(Y.getLedger(), getGameTime():getWorldAgeHours(), getClimateManager():getTemperature())
end

Events.OnTick.Add(onTick)
Events.EveryTenMinutes.Add(recordWeather)

for faceIndex = 0, FACE_COUNT - 1 do
    MapObjects.OnLoadWithSprite(SPRITE_PREFIX .. faceIndex, TraditionalPreservationYeastShelf.track, MAP_PRIORITY)
end

-- Shows how long a culture takes through the year, how long Active and Hopped Culture keep, and how long yeast cakes
-- take on TP Core's Drying Cloth, from forecasts read from the real game. It runs the mod's
-- own code (the ten-minute weather record, a run's start and updates, the popup), so it doubles as a check
-- that a change to that code keeps every number. Run from the mod folder: luajit tools/season_report.lua [climate.csv]
-- Each line of the file: world month offset tempMin tempMean tempMax humMin humMean humMax rainy snowy
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
H.useModPaths()
H.installClock(0)
H.installModData()
Events = { OnInitGlobalModData = { Add = function() end } }
dofile("42/media/lua/shared/TraditionalPreservationYeast.lua")
local Y = TraditionalPreservationYeast

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local STEPS_PER_HOUR = 6
local SECONDS_PER_HOUR = 3600

local function readDays(path)
    local days = {}
    for line in io.lines(path) do
        local f = {}
        for field in line:gmatch("%S+") do table.insert(f, field) end
        -- Each month's forecast also holds the 10 days before it (offset below 0): skipped, so a month is 30 days.
        if #f >= 6 and tonumber(f[3]) >= 0 then
            table.insert(days, { world = tonumber(f[1]), offset = tonumber(f[3]), month = tonumber(f[2]), low = tonumber(f[4]), mean = tonumber(f[5]), high = tonumber(f[6]) })
        end
    end
    return days
end

-- The day's weather, coldest before dawn and warmest mid-afternoon.
local function temperatureAt(day, hour)
    local swing = math.cos((hour - 15) / 24 * 2 * math.pi)
    return swing >= 0 and day.mean + (day.high - day.mean) * swing or day.mean + (day.mean - day.low) * swing
end

local function recipeData(seconds)
    local craftRecipeData = { modData = {}, elapsed = 0 }
    function craftRecipeData:getModData() return self.modData end
    function craftRecipeData:getElapsedTime() return self.elapsed end
    function craftRecipeData:setElapsedTime(elapsedTime) self.elapsed = elapsedTime end
    function craftRecipeData:getAllConsumedItems() return { size = function() return 0 end } end
    function craftRecipeData:getRecipe() return { getTime = function() return seconds end } end
    return craftRecipeData
end

-- The first sampled world's calendar year, settled (Weather.settledMeans).
local function settle(days)
    local year = {}
    for _, day in ipairs(days) do
        if day.world == days[1].world then table.insert(year, day) end
    end
    return require("TraditionalPreservationCore/Weather").settledMeans(year)
end

local days = readDays(arg[1] or "tools/climate_year.csv")
-- The ledger starts as a long-running save's would on 1 January.
Y.getLedger().seasonTemperature, Y.getLedger().groundTemperature = settle(days)(days[1].month, days[1].offset)
local seconds = Y.FERMENT_HOURS * SECONDS_PER_HOUR

-- Keeping and drying run on their own ledgers (the culture's keeper, the cloth's), started the same way.
local DryingCloth = require "TraditionalPreservationCore/DryingCloth"
for _, ledger in ipairs({ Y.CULTURE_KEEPER.ledger(), DryingCloth.getLedger() }) do
    ledger.seasonTemperature, ledger.groundTemperature = Y.getLedger().seasonTemperature, Y.getLedger().groundTemperature
end
local KEEP_PLACES = { "Open", "Covered", "Sheltered", "AiredRoom", "Basement" }
-- A shut room's still air dries nothing (the cloth's rule), so it has no column.
local CLOTH_PLACES = { "Open", "Covered", "AiredRoom", "Basement" }

local function keptItem(fullType)
    local days = Y.CULTURE_DAYS[fullType]
    local item = { fullType = fullType, modData = {}, age = 0, offAge = days[1], offAgeMax = days[2] }
    function item:getFullType() return self.fullType end
    function item:getModData() return self.modData end
    function item:getAge() return self.age end
    function item:setAge(x) self.age = x end
    function item:getOffAge() return self.offAge end
    function item:getOffAgeMax() return self.offAgeMax end
    function item:setOffAge(x) self.offAge = x end
    function item:setOffAgeMax(x) self.offAgeMax = x end
    return item
end

local function newCloth()
    local cloth = { modData = {} }
    function cloth:getModData() return self.modData end
    return cloth
end

-- One culture per place, started on the first day of each month, plus one that goes down to the basement
-- halfway through its first day, and two by a fire that never goes out: under an open roof and in the open.
-- Updated every in-game hour, as an open window would.
local FIRES = { "FiresideCovered", "FiresideOpen" }
local runs = {}
local function startRuns(index)
    for _, place in ipairs({ "Open", "Sheltered", "AiredRoom", "Basement", "Moved", FIRES[1], FIRES[2] }) do
        local craftRecipeData = recipeData(seconds)
        Y.onFermentStart(craftRecipeData)
        craftRecipeData.modData.place = place == "Moved" and "Sheltered" or place
        table.insert(runs, { craftRecipeData = craftRecipeData, place = place, month = days[index].month, startHour = H.hours })
    end
end

-- One Active Culture and one Hopped Culture per place, made on the first of each month, and one lot of cakes laid on a
-- cloth per place.
local keeps, cloths = {}, {}
local function startKeeping(index)
    local month = days[index].month
    for _, place in ipairs(KEEP_PLACES) do
        for _, fullType in ipairs({ Y.ACTIVE, Y.HOPPED }) do
            local item = keptItem(fullType)
            Y.CULTURE_KEEPER.keep(item, H.hours, place)
            table.insert(keeps, { item = item, place = place, key = month .. fullType .. place, startHour = H.hours })
        end
    end
    for _, place in ipairs(CLOTH_PLACES) do
        local cloth = newCloth()
        DryingCloth.lay(cloth, { keptItem(Y.CAKES) }, H.hours, place)
        table.insert(cloths, { cloth = cloth, place = place, key = month .. place, startHour = H.hours })
    end
end

local results, statuses = {}, {}
local keepResults, clothResults = {}, {}
for index, day in ipairs(days) do
    if index == 1 or day.month ~= days[index - 1].month then
        startRuns(index)
        startKeeping(index)
    end
    for hour = 0, 23 do
        for step = 1, STEPS_PER_HOUR do
            H.setHours(H.hours + 1 / STEPS_PER_HOUR)
            local temperature = temperatureAt(day, hour + step / STEPS_PER_HOUR)
            Y.advance(Y.getLedger(), H.hours, temperature)
            Y.CULTURE_KEEPER.recordWeather(H.hours, temperature)
            DryingCloth.recordWeather(H.hours, temperature)
        end
        for _, keep in ipairs(keeps) do
            if not keep.done then
                Y.CULTURE_KEEPER.keep(keep.item, H.hours, keep.place)
                if keep.item:getAge() >= keep.item:getOffAgeMax() then
                    keep.done = true
                    keepResults[keep.key] = (H.hours - keep.startHour) / 24
                end
            end
        end
        for _, run in ipairs(cloths) do
            if not run.done then
                local record = DryingCloth.update(run.cloth, H.hours, run.place)
                local state = DryingCloth.state(record.lots[1])
                if state ~= "wet" then
                    run.done = true
                    clothResults[run.key] = state == "dead" and (record.lots[1].spoiled and "spent" or "dies")
                        or string.format("%.2f (%.1f old)", (H.hours - run.startHour) / 24, Y.cakeLotAge(record.lots[1]))
                end
            end
        end
        for _, run in ipairs(runs) do
            if not run.finished then
                if run.place == "Moved" and H.hours - run.startHour >= 12 then run.craftRecipeData.modData.place = "Basement" end
                Y.onFermentUpdate(run.craftRecipeData)
                local key = run.month .. run.place
                if not statuses[key] and H.hours - run.startHour >= 24 then
                    statuses[key] = Y.batchStatus(run.craftRecipeData.modData, Y.FERMENT_HOURS, Y.getLedger())
                end
                if run.craftRecipeData.elapsed >= seconds then
                    run.finished = true
                    results[key] = results[key] or (H.hours - run.startHour) / 24
                end
            end
        end
    end
end

local function cell(month, place)
    local taken = results[month .. place]
    return taken and string.format("%.2f", taken) or ""
end
-- A room while the power grid is on holds Weather.GRID_ROOM_C (22 C) whatever the month, so its days are the rate's.
local Weather = require "TraditionalPreservationCore/Weather"
local gridDays = string.format("%.2f", Y.FERMENT_HOURS / Y.cultureRate(Weather.GRID_ROOM_C) / 24)

print(string.format("Days for one culture (%d hours at full speed), started on the first of the month", Y.FERMENT_HOURS))
print("| Month | Outdoors | Indoors | Indoors, grid on | Aired room | Basement | Indoors, then basement | By a fire, under a roof | By a fire, in the open |")
print("|---|---|---|---|---|---|---|---|---|")
for month = 1, 12 do
    print(string.format("| %s | %s | %s | %s | %s | %s | %s | %s | %s |", MONTHS[month],
        cell(month, "Open"), cell(month, "Sheltered"), gridDays, cell(month, "AiredRoom"), cell(month, "Basement"), cell(month, "Moved"),
        cell(month, FIRES[1]), cell(month, FIRES[2])))
end
-- By a fire indoors the temperature holds while the fuel lasts, whatever the month.
local Fire = require "TraditionalPreservationCore/Fire"
for _, place in ipairs({ Fire.PLACE, Fire.EMBERS }) do
    print(string.format("%s indoors (%d C), any month: %.2f days", place, Fire.fireC(place),
        Y.FERMENT_HOURS / Y.cultureRate(Fire.fireC(place)) / 24))
end


local PLACE_HEADS = { Open = "Outdoors", Covered = "Under a roof", Sheltered = "Shut room", AiredRoom = "Aired room", Basement = "Basement" }
local function printHeads(places)
    local names, rule = {}, {}
    for i, place in ipairs(places) do names[i], rule[i] = PLACE_HEADS[place], "---" end
    print("| Month | " .. table.concat(names, " | ") .. " |")
    print("|---|" .. table.concat(rule, "|") .. "|")
end
for _, fullType in ipairs({ Y.ACTIVE, Y.HOPPED }) do
    print("")
    print(string.format("Days %s keeps before it is Spent (script %d / %d days, a 15 C cellar's), made on the first of the month",
        fullType == Y.ACTIVE and "an Active Culture" or "a Hopped Culture", Y.CULTURE_DAYS[fullType][1], Y.CULTURE_DAYS[fullType][2]))
    printHeads(KEEP_PLACES)
    for month = 1, 12 do
        local cells = {}
        for i, place in ipairs(KEEP_PLACES) do
            local taken = keepResults[month .. fullType .. place]
            cells[i] = taken and string.format("%.2f", taken) or ""
        end
        print(string.format("| %s | %s |", MONTHS[month], table.concat(cells, " | ")))
    end
end
print("")
print(string.format("Days for a lot of yeast cakes to dry on a Drying Cloth (%d hours at full speed; dies past %d C), laid fresh on the first of the month, and their age then in days (Spent at %d); a shut room never dries",
    Y.CAKE_DRY_HOURS, Y.CAKE_KILL_C, Y.CULTURE_DAYS[Y.CAKES][2]))
printHeads(CLOTH_PLACES)
for month = 1, 12 do
    local cells = {}
    for i, place in ipairs(CLOTH_PLACES) do cells[i] = clothResults[month .. place] or "" end
    print(string.format("| %s | %s |", MONTHS[month], table.concat(cells, " | ")))
end

print("")
print("Popup after one day: progress, hours left, temperature, rate")
for month = 1, 12 do
    for _, place in ipairs({ "Open", "Sheltered", "AiredRoom", "Basement", "Moved" }) do
        local s = statuses[month .. place]
        if s then
            local left = s.hoursLeft and string.format("%.6f", s.hoursLeft) or "paused"
            print(string.format("%s %-9s %.6f %s %.6f %.6f %s", MONTHS[month], place, s.progress, left, s.temperature, s.rate, s.place))
        end
    end
end

print("")
print("Ledger at the end")
local ledger = Y.getLedger()
local keys = {}
for key in pairs(ledger) do table.insert(keys, key) end
table.sort(keys)
for _, key in ipairs(keys) do print(string.format("%-18s %.9f", key, ledger[key])) end

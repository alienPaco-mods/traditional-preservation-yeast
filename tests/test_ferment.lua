-- Checks the culture's work outside the game: the temperature curve, and each jar on the Fermenting Shelf on its own
-- clock (hunger, going off, the starts, fed cultures, keeping once done). Run from the mod folder:
-- luajit tests/test_ferment.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local hours = 10
function getGameTime() return { getWorldAgeHours = function() return hours end } end
local onInit
Events = { OnInitGlobalModData = { Add = function(handler) onInit = handler end } }
H.useModPaths()
H.installModData()
dofile("42/media/lua/shared/TraditionalPreservationYeast.lua")

local check, near = H.check, H.near
local Y = TraditionalPreservationYeast
local TIME = 120 * 3600
local function weather(count, temperature)
    for _ = 1, count do
        hours = hours + 1
        Y.advance(Y.getLedger(), hours, temperature)
    end
end

-- Temperature
check("best from 18 to 30 C", Y.cultureRate(18) == 1 and Y.cultureRate(30) == 1)
check("slower in a cool room", math.abs(Y.cultureRate(10) - 0.4) < 1e-9)
check("and crawls near freezing without stopping", math.abs(Y.cultureRate(1) - 0.12) < 1e-9)
check("frozen it pauses", Y.cultureRate(0) == 0 and Y.cultureRate(-20) == 0)
check("heat hurts it too", Y.cultureRate(38) < 0.4)
Y.SENSITIVITY = 0
check("sensitivity off runs at full speed in any weather", Y.cultureRate(-20) == 1 and Y.cultureRate(40) == 1)
Y.SENSITIVITY = 1.5
check("harsh never stops it above freezing", Y.cultureRate(1) >= Y.MIN_RATE and Y.cultureRate(45) >= Y.MIN_RATE)
check("but frozen is frozen on harsh too", Y.cultureRate(-1) == 0)
Y.SENSITIVITY = 1
check("a basement swings two fifths as far as the ground", Y.placeTemperature({ temperature = -15, seasonTemperature = -5, groundTemperature = -10 }, "Basement") == 2)
check("a shut room is its mean, 2 C warmer in a cold one and a stuffy one", Y.placeTemperature({ temperature = 0, seasonTemperature = 5 }, "Sheltered") == 7
    and Y.placeTemperature({ temperature = 0, seasonTemperature = 25 }, "Sheltered") == 27
    and Y.placeTemperature({ temperature = 0, seasonTemperature = 25, threeDayTemperature = 18 }, "Sheltered") == 18)


-- The shelf's jars, on their own clocks (the record alone: Y.putJar, Y.advanceJar).
local function culture(fullType, start)
    local self = { modData = { tpyStart = start, tpyJar = "Base.ClayJar" } }
    function self:getFullType() return fullType end
    function self:getModData() return self.modData end
    return self
end

local record = { jars = {}, nextId = 1 }
local function put(fullType, start)
    return Y.putJar(record, culture(fullType, start), hours, "Open")
end
-- count hours of weather at temperature everywhere, then every jar on the record brought up to now in the open.
local function step(count, temperature)
    for _ = 1, count do
        hours = hours + 1
        Y.advance(Y.getLedger(), hours, temperature)
        Y.CULTURE_KEEPER.recordWeather(hours, temperature)
    end
    for _, jar in ipairs(record.jars) do Y.advanceJar(jar, hours, "Open", nil, nil, Y.getLedger(), Y.CULTURE_KEEPER.ledger()) end
end

Y.getLedger()
Y.CULTURE_KEEPER.ledger()
local plain = put(Y.FERMENTING)
check("a culture goes on in its jar, plain, just fed", plain.jar == "Base.ClayJar" and plain.start == "plain" and plain.fedAt == 0
    and plain.kind == "culture" and Y.jarHours(plain) == 120)
step(20, 22)
check("20 warm hours: a sixth done, still working", near(plain.done, 20) and Y.jarState(plain) == "working")
local status = Y.jarStatus(plain, 22, "Open")
check("hungry in 4 hours, done in 100 if fed", near(status.hungryIn, 4) and near(status.hoursLeft, 100))
step(10, 22)
check("a day unfed it's hungry and stops", Y.jarState(plain) == "hungry" and near(plain.done, 24))
check("and says when it goes off", near(Y.jarStatus(plain, 22, "Open").offIn, 42))
check("one refresh feeds it", Y.refreshJars(record) == 1 and Y.jarState(plain) == "working")
step(10, 22)
check("fed, it goes on", near(plain.done, 34))
step(5, 10)
check("cool, slower, and hungry later", near(plain.done, 36) and near(plain.work.age - plain.fedAt, 12))
step(24, -10)
check("frozen, nothing moves, not even hunger", near(plain.done, 36) and near(plain.work.age - plain.fedAt, 12)
    and Y.jarStatus(plain, -10, "Open").hoursLeft == nil)

local left = put(Y.FERMENTING)
step(36, 22)
plain.fedAt = plain.work.age
step(36, 22)
check("three days unfed it goes off, a day's work done", Y.jarState(left) == "off" and near(left.done, 24))
check("gone off it is fed no more", #Y.refreshable(record) == 1 and Y.refreshable(record)[1] == plain)
table.remove(record.jars, 2)

-- The starts: fed every 20 hours at 22 C, how long each takes.
local function hoursToDone(start)
    record.jars = {}
    local jar = put(Y.FERMENTING, start)
    local took = 0
    while not Y.jarDone(jar) and took < 400 do
        step(1, 22)
        took = took + 1
        if took % 20 == 0 then Y.refreshJars(record) end
    end
    return took, jar
end
check("plain flour and water: five days", hoursToDone(nil) == 120)
check("fruit: four", hoursToDone("fruit") == 96)
check("potato water: three and a half", hoursToDone("potato") == 84)
Y.FERMENT_HOURS = 60
check("a start's share follows the sandbox's time", Y.jarHours(put(Y.FERMENTING, "fruit")) == 48)
Y.FERMENT_HOURS = 120

-- A Fed Culture rises in a day and never goes hungry.
record.jars = {}
local fed = put(Y.FED)
step(23, 22)
check("a fed culture wants no refresh", Y.jarState(fed) == "working" and #Y.refreshable(record) == 0)
step(1, 22)
check("and rises in a day", Y.jarState(fed) == "done" and Y.jarLook(fed, 1) == "fedDone")

-- Done part way through a stretch, its keeping counts from there: 30 hours at 22 C after 110 done, 10 to finish.
record.jars = {}
local late = put(Y.FERMENTING)
late.done, late.fedAt = 110, 0
step(30, 22)
local keptAll = late.keep.age / 24
check("done in the stretch keeps from that point", Y.jarDone(late) and near(Y.jarKeptDays(late), keptAll * 20 / 30, 1e-6))
check("its status says when it's Spent here", Y.jarStatus(late, 22, "Open").spentIn ~= nil)
step(72, 22)
check("left on the shelf it goes Spent", Y.jarState(late) == "spent" and Y.jarLook(late, 1) == "off")

-- Looks
record.jars = {}
local fruity = put(Y.FERMENTING, "fruit")
check("a fruit start shows its fruit until halfway", Y.jarLook(fruity, 0.1) == "fruit" and Y.jarLook(fruity, 0.6) == "halfway")
check("a fed one rises in its look", Y.jarLook(put(Y.FED), 0) == "fedRising")
check("the shelf holds five", put(Y.FED) and put(Y.FED) and put(Y.FED) and put(Y.FED) == nil and Y.shelfRoom(record) == 0)
check("and takes only cultures", Y.putJar({ jars = {}, nextId = 1 }, culture(Y.ACTIVE), hours, "Open") == nil)

-- Off the shelf it goes on getting hungry: made, carried 30 warm hours, put on hungry; 80 hours, it goes on gone off.
record.jars = {}
local made = culture(Y.FERMENTING)
Y.startRun(made, hours, "Open")
step(30, 22)
local carried = Y.putJar(record, made, hours, "Open")
check("carried a day unfed, it goes on hungry, nothing done", Y.jarState(carried) == "hungry" and carried.done == 0)
local forgotten = culture(Y.FERMENTING)
Y.startRun(forgotten, hours, "Open")
step(80, 22)
check("forgotten three days, it goes on gone off", Y.jarState(Y.putJar(record, forgotten, hours, "Open")) == "off")
local old = culture(Y.FERMENTING)
check("one made before runs were kept goes on just fed", Y.jarState(Y.putJar(record, old, hours, "Open")) == "working")

onInit()
check("the default is five days", TraditionalPreservationYeast.FERMENT_HOURS == 120)
SandboxVars = { TraditionalPreservationYeast = { FermentDays = 2.5 } }
onInit()
check("the sandbox option sets the time", TraditionalPreservationYeast.FERMENT_HOURS == 60)
SandboxVars.TraditionalPreservationYeast.TemperatureSensitivity = 1
onInit()
check("and the sensitivity", TraditionalPreservationYeast.SENSITIVITY == 0)

H.done()

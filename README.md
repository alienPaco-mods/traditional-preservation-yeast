# Traditional Preservation (Yeast) — Build 42 prototype (v0.6.4)

**Status: experimental.** Back up your save before enabling.

Grow your own baker's yeast once the looted packets are gone. Flour and water in a jar, kept on a Fermenting Shelf and refreshed once a day for about five days at a good temperature, give a live **Active Culture**; started with fruit or potato water it is quicker. It doesn't keep long, so it is shaped into **yeast cakes** and dried on TP Core's **Drying Cloth**, about a week at a good temperature; a dry cake crumbles into a packet of vanilla Yeast. Hops keep a culture going: fed with hop tea and flour, one culture rises into two, one to carry on and one for cakes. Everything works by its place: a warm room or a fire's side is quick, a cold one slow, and frost stops it.

## Install (Arch Linux / Steam)

Copy the `TraditionalPreservationYeast` folder into `~/Zomboid/mods/`, so the metadata file is:
`~/Zomboid/mods/TraditionalPreservationYeast/42/mod.info`

It needs the **TP Core** mod (`TraditionalPreservationCore`, the series' shared mod) installed and enabled the same way (`~/Zomboid/mods/TraditionalPreservationCore`), and no other mods.

Enable **Traditional Preservation (Yeast)** for your existing save from
**Load → select save → More → Choose Mods** (wording can differ by game version).

## How it works

1. **Build a Fermenting Shelf** against a wall (Build menu, Furniture): 2 planks + 4 nails + any hammer (kept), Carpentry 2. Gives 10 Carpentry XP.
2. **Make Fermenting Culture** (Cooking): an empty jar + 5 uses of flour + half a litre of water from any container (bottle, pot, the tap's jar: it is kept) → 1 Fermenting Culture, in the empty jar. Any of vanilla's jars: a **Jar** (found or crafted), a **Ceramic Jar** or a **Glazed Ceramic Jar**. Gives 3 Cooking XP. Two quicker starts (below): **with Fruit** and **with Potato Water**.
3. Right-click the shelf, *Put Fermenting Culture on the Shelf* (One or All), or drop cultures on the square in the **Fermenting Shelf Info** window. It holds 5 jars, each on its own clock.
4. **Refresh the Cultures** about once a day: a use of flour and 0.1 L of water a jar, all the shelf's at once (below).
5. After five in-game days at a good temperature, *Take Done*: an **Active Culture** per jar, in the jar it went on in.
6. **Shape Yeast Cakes** (Cooking): an Active Culture + 3 uses of Cornmeal or Flour → wet **Yeast Cakes**, and the jar back. Gives 3 Cooking XP.
7. **Lay them on a Drying Cloth** (TP Core: a Sheet and 2 Stones, Build menu, Furniture): right-click it, *Lay Yeast Cakes on the Cloth*. One batch of cakes to a lot, five lots a cloth.
8. About a week later at a good temperature, *Take Off the Finished Lots*: **Dried Yeast Cakes**, which keep. **Crumble Yeast Cakes** (Cooking) makes them one vanilla `Base.Yeast`, a full packet of 10 uses.

**Pour Out Culture** (any culture, fresh, fermenting, fed or spent) gives its jar back empty.

No vanilla recipes or loot distribution are changed. No hunger, calorie or yeast-buff changes.

### Shelf behaviour

- Right-click the shelf: what it holds (hover for each jar), **Fermenting Shelf Info**, a *Put* row for each culture you carry, **Refresh the Cultures**, **Take Done** (greyed until a jar is done, saying when the next will be) and **Take Everything Off**. The Fermenting Shelf window lists every jar with its bar, what it's doing and when it goes hungry, off or Spent; hover a row for its start, progress, time left, temperature and working rate. It has the same buttons and a square to drop cultures on.
- Each jar keeps its own clock: one put on later finishes later. The shelf holds 5.
- **Refreshing.** A Fermenting Culture wants feeding, as a real starter does. After **24 hours of work** since it was made or last refreshed it is **hungry**: it stops until refreshed. After **72** it has **gone off**, and taking it off gives its empty jar back. The hours are the culture's own, by its temperature: at 20 C a refresh a day and three days to going off; in a cool basement about every two days; frozen, the clock waits. *Refresh the Cultures* feeds every Fermenting Culture on the shelf at once, a use of flour (in reach) and 0.1 L of water (carried) a jar, the hungriest first when there isn't enough. A plain culture wants about 4 refreshes wherever it stands; the place only spaces them out.
- A Fermenting Culture goes on getting hungry off the shelf too, from the moment it is made: carried or left in a crate, it is hungry after a day and gone off after three, so taking jars off doesn't skip the refresh. Its progress counts only on the shelf. Taken off part way, it comes back as it was and goes on where it stopped.
- A Fed Culture needs no refresh (the hop tea and flour are its feed).
- A shelf with anything on it can't be picked up.
- Fermentation continues while the area is unloaded. It goes by the temperature where the shelf stands (see below), and rain doesn't matter.
- The shelf shows each culture in its own jar, glass, ceramic or glazed: pale when fresh (with bits of fruit or potato through a glass jar), amber from halfway, sunk with grey liquid on top when hungry, mouldy when gone off or Spent, and dark brown when done. A ceramic jar shows it by the cloth over its mouth. A fed culture carries a hop sprig.

### Quicker starts

| Start | What goes in | Hours of work (plain 120) | Refreshes |
|---|---|---|---|
| Plain | an empty jar + 5 flour + half a litre of water (from any container, kept) | 120 (5 days at a good temperature) | 4 |
| **Make Fermenting Culture with Fruit** | the same + an Apple, Pear, Peach, Cherry, Grapes or Dried Apricots | 96 (4 days) | 3 |
| **Make Fermenting Culture with Potato Water** | an empty jar + 5 flour + half a litre of Potato Water (from the pot, kept) | 84 (3.5 days) | 3 |

The yeast on a fruit's skin gets it going; potato water's starch feeds it. **Mash Potato in Water** (Cooking): a full Cooking Pot (or Forged Pot), 1.5 L of clean water and nothing else, + 1 Potato (a saucepan holds only 0.6 L) → **Potato in Water**, which kept steaming on a stove or a fire for half an hour becomes **Potato Water**. The pot (1.5 L) starts three jars, none left over. Right-click the pot: the row opens **One** or **All** (one culture a half litre, as many as the jars and flour carried allow). The sandbox's Ferment Days sets the plain time; the starts keep their share (80% and 70%).

### Keeping a culture

An Active Culture is alive and doesn't keep: it reads **Active Culture (Fresh)**, then **(Spent)**, and a spent one is only good for pouring out. It keeps by the temperature where it is, the same places as the shelf (below), a powered fridge as 4 C, and a freezer stops it. Its script days (3 fresh, 5 to Spent) are a 15 C cellar's: about **3 days at 20 C**, a day at 30 C, a week in a basement in summer, two weeks in a fridge. By a fire (28 C) it is spent in about a day, so don't leave finished cultures on a shelf by the fire. It starts keeping the moment it is done, while it waits on the shelf too. Wet Yeast Cakes keep longer, 5 fresh and 8 to Spent (the meal takes up the culture's water): Spent in about 5 days at 20 C.

Days to Spent, made on the first of the month (`tools/season_report.lua`):

| Month | Outdoors, under a roof | Shut room | Aired room | Basement |
|---|---|---|---|---|
| Jan | 53 | 55 | 59 | 14 |
| Apr | 12 | 11 | 11 | 12 |
| Jul | 3 | 3 | 4 | 7 |
| Aug | 2 | 3 | 2 | 6 |
| Oct | 9 | 7 | 9 | 7 |
| Nov | 41 | 17 | 33 | 9 |

### Hops: keeping a culture going

1. **Steep Hops** (Cooking): a full Cooking Pot (or Forged Pot), 1.5 L of clean water and nothing else, + 1 **Hops (Dried)** (vanilla's: hops dried on the Herb Drying Rack) → the water becomes **Hop Water**, in the same pot.
2. Kept steaming on a stove or a fire for a quarter of an hour it becomes **Hop Tea**. The pot (1.5 L) feeds three cultures; right-click the pot for Feed Culture **One** or **All**.
3. **Feed Culture** (Cooking): an Active or Hopped Culture + an empty jar + half a litre of Hop Tea (from any container, kept) + 5 uses of flour → 2 **Fed Culture**, in the culture's own jar and the new one. Gives 3 Cooking XP.
4. Put them on the shelf: a Fed Culture rises in a day at the best temperature (by the shelf's own curve) → **Hopped Culture**, one a jar. It needs no refresh.

A Hopped Culture keeps twice as long (7 fresh, 10 to Spent in a cellar: about 6 days at 20 C) and does everything an Active Culture does, feeding included. One carries the line on, the other goes to cakes, so a culture never has to be started from flour again while it is fed in time.

### Drying the cakes

The Drying Cloth is TP Core's (its README, "The Drying Cloth"). Yeast cakes dry in **168 hours (7 days) at full speed**, from 15 to 25 C in moving air: 60% at 10 C, 30% at 5 C, nothing at 0 C and below (they wait), 80% at 30 C and 60% at 35 C. **Above 35 C for an hour they die**, and come off as nothing. In a shut room's still air they wait for a window to be opened. By a fire in a room they dry, in about 8 days (7 by banked embers). While wet they keep ageing on the cloth, by its place: on the culture's curve held at its 20 C speed above 20 C, and slowed as they dry, by how wet they still are squared (half dry, a quarter as fast). Laid fresh where the air moves they dry having used 2 to 5 of their 8 days in any month (the season table); shaped from a culture already a few days old, by a fire, or in a shut room (which ages them and dries nothing) they can go Spent first, and the lot is gone off: the Drying Cloth window says so, and it comes off as nothing. Taken off before they are dry, they come back wet, as old as they are.

Days for a lot to dry, laid on the first of the month:

| Month | Outdoors, under a roof | Aired room | Basement |
|---|---|---|---|
| Jan | 76 | 79 | 21 |
| Apr | 16 | 16 | 18 |
| Jun | 8 | 7 | 11 |
| Aug | 7 | 7 | 8 |
| Oct | 15 | 12 | 9 |
| Nov | 107 | 113 | 11 |

One cloth turns out at most five packets a week in summer. In winter, lay it by a fire.

## Temperature

A culture works by the temperature where the shelf stands, like the stations in the other Traditional Preservation mods. It's best from **18 to 30 C**, at 40% speed at 10 C, 20% at 5 C, and only crawls just above freezing. At 0 C and below it stops and waits, without ever dying: the Fermenting Shelf window says *waiting: too cold*, and its hunger waits too. Real heat slows it too (60% at 35 C).

- **Open air** (a shelf on an outside wall) and **under an open roof** (a porch, an open shed): the weather, hour by hour.
- **Indoors** (a shut room: every window to the outside shut or boarded): an unheated room follows the average of the last 3 days, 2 C warmer in the cold months and up to 2 C warmer in summer (stuffy). A room is **22 C while the power grid is on**, as vanilla's are.
- **Aired room** (a room with a window to the outside open, smashed, without its glass or an empty frame): the day's average, at most 1 C warmer in winter; 22 C while the power grid is on.
- **In a basement** (any level below ground): the earth takes the edge off the seasons and holds them back a month, about 5 C from January to March and 13 C from July to September.
- **By a fire**: any lit fire within 2 tiles on the same floor (a fireplace, an antique stove, a campfire, TP Core's Stone Hearth) holds a shelf in a shut room at **28 C**, banked embers at 24 C: **5 days in any month**. With a window open or outside, the air carries the heat off: in an aired room or under an open roof the fire gives the air +15 C, in the open +10 C, never past 28 C (banked embers +10 and +5, up to 24 C), so a winter culture by a porch fire or a campfire is quicker, not quick. While you're away, the fire counts for as long as its fuel would last.

Time keeps counting while you're away, from the weather recorded every 10 in-game minutes. Hover a jar's row in the Fermenting Shelf window for its progress, real time left at today's temperature, the temperature and place, and its working rate. **Temperature sensitivity** in the sandbox options sets how much this matters, and **Off** makes every culture take the same time whatever the weather, as before 0.4.0.

Days a plain culture takes, started on the first of the month and refreshed daily, on the game's sampled weather for default settings, the grid off (`tools/season_report.lua`; fruit takes 80% of it, potato water 70%):

| Month | Open air | Indoors (shut room) | Aired room | Basement | By a fire, under a roof | By a fire, in the open |
|---|---|---|---|---|---|---|
| Jan | 77 | 79 | 84 | 24 | 11 | 20 |
| Feb | 54 | 52 | 55 | 25 | 7 | 13 |
| Mar | 29 | 27 | 28 | 24 | 6 | 10 |
| Apr | 16 | 15 | 15 | 19 | 5 | 6 |
| May | 9 | 8 | 9 | 16 | 5 | 5 |
| Jun | 5 | 5 | 5 | 11 | 5 | 5 |
| Jul | 6 | 5 | 5 | 9 | 5 | 5 |
| Aug | 7 | 5 | 6 | 8 | 5 | 5 |
| Sep | 7 | 6 | 6 | 8 | 5 | 5 |
| Oct | 13 | 10 | 12 | 9 | 5 | 6 |
| Nov | 96 | 67 | 106 | 12 | 6 | 8 |
| Dec | 92 | 97 | 102 | 17 | 10 | 21 |

By a fire or banked embers in a shut room, or in any room while the grid is on (22 C): 5 days in any month. From October a shut room no longer keeps the summer's warmth: a November culture there takes about 67 days, by a fire 5.

A winter culture started in an unheated room spends weeks paused below freezing: about 91 days from the first of January, and more than 100 from December. Open air does a little better in January, because a sunny afternoon still thaws the jar for a few hours.

So a kitchen shelf is enough from May to October. In winter, set it by an indoor fire, or wait three to four weeks in a basement.

## Changing the timer

Set **Fermenting time (days)** (the time at the best temperature) and **Temperature sensitivity** (Off, Forgiving, Normal, Harsh) under Traditional Preservation (Yeast) in the sandbox options. The default is `FERMENT_HOURS` at the top of `42/media/lua/shared/TraditionalPreservationYeast.lua`. Fractions work. Running batches pick up the new time after a game restart.

`luajit tests/test_ferment.lua` checks the temperature curve, places, each jar's clock (hunger, going off, the starts, fed cultures, keeping once done, hunger off the shelf) and the sandbox options, `luajit tests/test_shelf.lua` the shelf's sprites, its menu and hand jobs, the Fermenting Shelf window's rows and drop square, and the refresh's flour and water, `luajit tests/test_culture.lua` the jars through every step, the keeping, hops, feeding and the cakes on the cloth, and `luajit tests/test_console.lua` the debug commands. `luajit tools/season_report.lua` runs the rules against `tools/climate_year.csv`, the game's forecasts: the culture's days, how long Active and Hopped Culture keep, and how long a lot of cakes takes on the cloth (golden-checked by `tp test Yeast`).

## Rebuilding the tileset

The shelf, its jars and the cakes on the cloth are painted by code, so there is no art to edit by hand. `tools/shelf_art.py` draws the shelf and `tools/build_shelf_tileset.py` draws the jars (three jar kinds by seven looks, and two start looks in glass only, which a ceramic jar hides: a sheet holds 512 tiles), the cakes' overlays for TP Core's cloth (`cloth_art.lot_spot`) and the culture icons; the tables and colours at the top of each control the look. To change them, edit the scripts and run `python3 tools/build_shelf_tileset.py` (needs Pillow). It rewrites `42/media/traditionalpreservationyeast.tiles` and `42/media/texturepacks/traditionalpreservationyeast.pack`. It also writes the generated `42/media/lua/shared/TraditionalPreservationYeast/Tiles.lua`, the tile numbers the Lua reads (don't edit it by hand), and `luajit tests/test_tiles.lua` checks the entity scripts against it.

## Debug commands

In debug mode, `TPY.help()` in the Lua console lists commands for testing this mod. They are described in `DEVHELP.md`.

## Known prototype caveats

- The workstation uses plain `CraftLogic`, which no vanilla entity uses in a script (vanilla racks use `DryingCraftLogic`, whose speed depends on temperature). The engine and UI support it, but it is a less travelled path.
- `tiledef` number 5127 must be unique among your active mods. If another mod uses it, change it in `42/mod.info`.
- Multiplayer is not supported. This mod is singleplayer only for now.
- If the shelf or recipes don't appear, review `~/Zomboid/console.txt`.

## Engineering notes

The shared Traditional Preservation core (weather, places, station tracking, popups) is the required TP Core mod (id `TraditionalPreservationCore`), loaded as `require "TraditionalPreservationCore/Weather"`. Edit it there. The fermenting curve, the jars and the shelf's record stay in this mod's own files. The cultures, their keeping, hops and the cakes are in `42/media/lua/shared/TraditionalPreservationYeastCulture.lua`: the jar a culture is in is its modData `tpyJar` (a full type), and a ceramic one is drawn through modData `customInventoryIcon` and `worldStaticModel`, which the engine reads before the script's; every recipe's `OnCreate` hands the jar on (`Y.onCreateInJar` and the starts' `Y.onCreateFruitStart`, `Y.onCreatePotatoStart`, `Y.onCreateFed`, `Y.onCreateCakes`, `Y.onCreateJarBack`; the shelf gives each back by `Y.jarOutput`). Keeping is TP Core's `PlaceKeeping` (`Y.CULTURE_KEEPER`, ledger `TraditionalPreservationYeastKeep`, item clock `tpyKeep`). Hop Water turns to Hop Tea, and Potato in Water to Potato Water, through TP Core's `ItemFluid.turnsHot`. The cakes are a kind registered on TP Core's `DryingCloth` (`Y.CAKES_ON_CLOTH`): the lot keeps the cakes' age as a FluidAgeing age on the keeper's ledger (process `cakeKeep`, `keeper.addAgeing`), its `goesOff` says when they go Spent, and it gives Dried Yeast Cakes when dry.

The shelf has no crafting window (TP Core's station rule: pieces put on a station). Its jars are a record in the shelf's movableData (`tpyShelf`, `42/media/lua/shared/TraditionalPreservationYeastShelf.lua`): each jar's work is a FluidAgeing age on the culture's ledger (process `culture`), `fedAt` its work hours at its last feed, `done` its progress, which counts only while fed (`Y.HUNGRY_HOURS` 24, off at `Y.OFF_HOURS` 72), and `keep` a FluidAgeing age on the keeper's ledger from which, once done, it goes Spent on the shelf. A culture off the shelf carries its run in modData `tpyRun` (`Y.startRun` at its recipe; work, `fedAt`, `done`) and its start in `tpyStart`, so it goes hungry wherever it is. `42/media/lua/server/TraditionalPreservationYeastWorld.lua` steps every loaded shelf (TP Core's `Station.tracker`, scanning for new ones) and layers one attached sprite a jar; `42/media/lua/client/TraditionalPreservationYeastShelfUI.lua` is the menu and the Fermenting Shelf window (TP Core's `InfoWindow`, `pieceList`, `buttonRow`, `dropZone`, `PiecesUI`), and `TimedActions/TPYShelf.lua` the put, take and refresh. The ferment time comes from the sandbox's Ferment Days on `OnInitGlobalModData`; a start takes its share (`Y.STARTS`), a fed culture `Y.RAISE_HOURS` (24).

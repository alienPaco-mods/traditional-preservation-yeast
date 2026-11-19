# Traditional Preservation (Yeast) — Build 42 prototype (v0.5.0)

**Status: experimental.** Back up your save before enabling.

Grow your own baker's yeast once the looted packets are gone. Flour and water in a jar, left on a Fermenting Shelf for about five days at a good temperature, give a live **Active Culture**. It doesn't keep long, so it is shaped into **yeast cakes** and dried on TP Core's **Drying Cloth**, about a week at a good temperature; a dry cake crumbles into a packet of vanilla Yeast. Hops keep a culture going: fed with hop tea and flour, one culture rises into two, one to carry on and one for cakes. Everything works by its place: a warm room or a fire's side is quick, a cold one slow, and frost stops it.

## Install (Arch Linux / Steam)

Copy the `TraditionalPreservationYeast` folder into `~/Zomboid/mods/`, so the metadata file is:
`~/Zomboid/mods/TraditionalPreservationYeast/42/mod.info`

It needs the **TP Core** mod (`TraditionalPreservationCore`, the series' shared mod) installed and enabled the same way (`~/Zomboid/mods/TraditionalPreservationCore`), and no other mods.

Enable **Traditional Preservation (Yeast)** for your existing save from
**Load → select save → More → Choose Mods** (wording can differ by game version).

## How it works

1. **Build a Fermenting Shelf** against a wall (Build menu, Furniture): 2 planks + 4 nails + any hammer (kept), Carpentry 2. Gives 10 Carpentry XP.
2. **Make Fermenting Culture** (Cooking): 5 uses of flour + a jar holding at least 0.3 L water → 1 Fermenting Culture. Any of vanilla's jars: a **Jar** (found or crafted), a **Ceramic Jar** or a **Glazed Ceramic Jar**. Gives 3 Cooking XP.
3. Open the shelf, add up to 5 cultures and press **Craft**.
4. After five in-game days at a good temperature, take an **Active Culture** per culture from the shelf, in the jar it went on in.
5. **Shape Yeast Cakes** (Cooking): an Active Culture + 3 uses of Cornmeal or Flour → wet **Yeast Cakes**, and the jar back. Gives 3 Cooking XP.
6. **Lay them on a Drying Cloth** (TP Core: a Sheet and 2 Stones, Build menu, Furniture): right-click it, *Lay Yeast Cakes on the Cloth*. One batch of cakes to a lot, five lots a cloth.
7. About a week later at a good temperature, *Take Off the Finished Lots*: **Dried Yeast Cakes**, which keep. **Crumble Yeast Cakes** (Cooking) makes them one vanilla `Base.Yeast`, a full packet of 10 uses.

**Pour Out Culture** (any culture, fresh, fermenting, fed or spent) gives its jar back empty.

No vanilla recipes or loot distribution are changed. No hunger, calorie or yeast-buff changes.

### Shelf behaviour

- Each press of **Craft** starts its own timer. Cultures added and started later finish later; cultures started by the same press finish together.
- The shelf holds 5 cultures in total, counting waiting, fermenting and finished-but-uncollected ones.
- **Cancel** stops every running batch and returns the cultures.
- Fermentation continues while the area is unloaded. It goes by the temperature where the shelf stands (see below), and rain doesn't matter.
- The shelf shows each culture in its own jar, glass, ceramic or glazed, coloured by that culture's own timer: pale when fresh, amber from halfway, and dark brown when done. A fed culture carries a hop sprig. A finished jar stays visible until it is collected.

### Keeping a culture

An Active Culture is alive and doesn't keep: it reads **Active Culture (Fresh)**, then **(Spent)**, and a spent one is only good for pouring out. It keeps by the temperature where it is, the same places as the shelf (below), a powered fridge as 4 C, and a freezer stops it. Its script days (3 fresh, 5 to Spent) are a 15 C cellar's: about **3 days at 20 C**, a day at 30 C, a week in a basement in summer, two weeks in a fridge. By a fire (28 C) it is spent in about a day, so don't leave finished cultures on a shelf by the fire. It starts keeping the moment it comes off the shelf's timer, while it waits on the shelf too. Wet Yeast Cakes keep longer, 5 fresh and 8 to Spent (the meal takes up the culture's water): Spent in about 5 days at 20 C.

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

1. **Steep Hops** (Cooking): a Cooking Pot or Saucepan holding exactly 1 L of water and nothing else + 1 **Hops (Dried)** (vanilla's: hops dried on the Herb Drying Rack) → the water becomes **Hop Water**, in the same pot.
2. Kept steaming on a stove or a fire for a quarter of an hour it becomes **Hop Tea**. 1 L feeds three cultures.
3. **Feed Culture** (Cooking): an Active or Hopped Culture + an empty jar + 0.3 L of Hop Tea (in a pot, saucepan, jar, bottle or mug, kept) + 5 uses of flour → 2 **Fed Culture**, in the culture's own jar and the new one. Gives 3 Cooking XP.
4. Put them on the shelf and press **Craft**: **Raise Fed Culture** takes a day at the best temperature (by the shelf's own curve) → 2 **Hopped Culture**.

A Hopped Culture keeps twice as long (7 fresh, 10 to Spent in a cellar: about 6 days at 20 C) and does everything an Active Culture does, feeding included. One carries the line on, the other goes to cakes, so a culture never has to be started from flour again while it is fed in time.

### Drying the cakes

The Drying Cloth is TP Core's (its README, "The Drying Cloth"). Yeast cakes dry in **168 hours (7 days) at full speed**, from 15 to 25 C in moving air: 60% at 10 C, 30% at 5 C, nothing at 0 C and below (they wait), 80% at 30 C and 60% at 35 C. **Above 35 C for an hour they die**, and come off as nothing. In a shut room's still air they wait for a window to be opened. By a fire in a room they dry, in about 8 days (7 by banked embers). While wet they keep ageing on the cloth, by its place: on the culture's curve held at its 20 C speed above 20 C, and slowed as they dry, by how wet they still are squared (half dry, a quarter as fast). Laid fresh where the air moves they dry having used 2 to 5 of their 8 days in any month (the season table); shaped from a culture already a few days old, by a fire, or in a shut room (which ages them and dries nothing) they can go Spent first, and the lot is gone off: Cloth Info says so, and it comes off as nothing. Taken off before they are dry, they come back wet, as old as they are.

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

A culture works by the temperature where the shelf stands, like the stations in the other Traditional Preservation mods. It's best from **18 to 30 C**, at 40% speed at 10 C, 20% at 5 C, and only crawls just above freezing. At 0 C and below it stops and waits, without ever dying: the shelf's window says *Paused here (frozen)*. Real heat slows it too (60% at 35 C).

- **Open air** (a shelf on an outside wall) and **under an open roof** (a porch, an open shed): the weather, hour by hour.
- **Indoors** (a shut room: every window to the outside shut or boarded): an unheated room follows the average of the last 3 days, 2 C warmer in the cold months and up to 2 C warmer in summer (stuffy). A room is **22 C while the power grid is on**, as vanilla's are.
- **Aired room** (a room with a window to the outside open, smashed, without its glass or an empty frame): the day's average, at most 1 C warmer in winter; 22 C while the power grid is on.
- **In a basement** (any level below ground): the earth takes the edge off the seasons and holds them back a month, about 5 C from January to March and 13 C from July to September.
- **By a fire**: any lit fire within 2 tiles on the same floor (a fireplace, an antique stove, a campfire, TP Core's Stone Hearth) holds a shelf in a shut room at **28 C**, banked embers at 24 C: **5 days in any month**. With a window open or outside, the air carries the heat off: in an aired room or under an open roof the fire gives the air +15 C, in the open +10 C, never past 28 C (banked embers +10 and +5, up to 24 C), so a winter culture by a porch fire or a campfire is quicker, not quick. While you're away, the fire counts for as long as its fuel would last.

Time keeps counting while you're away, from the weather recorded every 10 in-game minutes. Hover a fermenting culture in the shelf's window for its progress, real time left at today's temperature, the temperature and place, and its working rate. **Temperature sensitivity** in the sandbox options sets how much this matters, and **Off** makes every culture take the same time whatever the weather, as before 0.4.0.

Days a culture takes, started on the first of the month, on the game's sampled weather for default settings, the grid off (`tools/season_report.lua`):

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

`luajit tests/test_ferment.lua` checks the temperature curve, places, the timer and the sandbox options, `luajit tests/test_shelf.lua` the shelf's jars and its five-culture rule, `luajit tests/test_culture.lua` the jars through every step, the keeping, hops, feeding and the cakes on the cloth, and `luajit tests/test_console.lua` the debug commands. `luajit tools/season_report.lua` runs the rules against `tools/climate_year.csv`, the game's forecasts: the culture's days, how long Active and Hopped Culture keep, and how long a lot of cakes takes on the cloth (golden-checked by `tp test Yeast`).

## Rebuilding the tileset

The shelf, its jars and the cakes on the cloth are painted by code, so there is no art to edit by hand. `tools/shelf_art.py` draws the shelf and `tools/build_shelf_tileset.py` draws the jars (three jar kinds, five looks each), the cakes' overlays for TP Core's cloth (`cloth_art.lot_spot`) and the culture icons; the tables and colours at the top of each control the look. To change them, edit the scripts and run `python3 tools/build_shelf_tileset.py` (needs Pillow). It rewrites `42/media/traditionalpreservationyeast.tiles` and `42/media/texturepacks/traditionalpreservationyeast.pack`. It also writes the generated `42/media/lua/shared/TraditionalPreservationYeast/Tiles.lua`, the tile numbers the Lua reads (don't edit it by hand), and `luajit tests/test_tiles.lua` checks the entity scripts against it.

## Debug commands

In debug mode, `TPY.help()` in the Lua console lists commands for testing this mod. They are described in `DEVHELP.md`.

## Known prototype caveats

- The workstation uses plain `CraftLogic`, which no vanilla entity uses in a script (vanilla racks use `DryingCraftLogic`, whose speed depends on temperature). The engine and UI support it, but it is a less travelled path.
- `tiledef` number 5127 must be unique among your active mods. If another mod uses it, change it in `42/mod.info`.
- Multiplayer is not supported. This mod is singleplayer only for now.
- If the shelf or recipes don't appear, review `~/Zomboid/console.txt`.

## Engineering notes

The shared Traditional Preservation core (weather, places, station tracking, popups) is the required TP Core mod (id `TraditionalPreservationCore`), loaded as `require "TraditionalPreservationCore/Weather"`. Edit it there. The fermenting curve, the jars and the five-culture limit stay in this mod's own files. The cultures, their keeping, hops and the cakes are in `42/media/lua/shared/TraditionalPreservationYeastCulture.lua`: the jar a culture is in is its modData `tpyJar` (a full type), and a ceramic one is drawn through modData `customInventoryIcon` and `worldStaticModel`, which the engine reads before the script's; every recipe's `OnCreate` hands the jar on (`Y.onCreateInJar`, `Y.onCreateOffShelf`, `Y.onCreateFed`, `Y.onCreateCakes`, `Y.onCreateJarBack`; the shelf's `OnStart` notes them, `Y.noteJars`). Keeping is TP Core's `PlaceKeeping` (`Y.CULTURE_KEEPER`, ledger `TraditionalPreservationYeastKeep`, item clock `tpyKeep`). Hop Water turns to Hop Tea through TP Core's `ItemFluid.turnsHot`. The cakes are a kind registered on TP Core's `DryingCloth` (`Y.CAKES_ON_CLOTH`): the lot keeps the cakes' age as a FluidAgeing age on the keeper's ledger (process `cakeKeep`, `keeper.addAgeing`), its `goesOff` says when they go Spent, and it gives Dried Yeast Cakes when dry.

The shelf uses no `SpriteOverlayConfig`, because that shows one sprite for the first batch only. `42/media/lua/server/TraditionalPreservationYeastShelf.lua` reads each batch's progress through `CraftLogicUILogic` and layers one attached sprite per jar instead. Each culture makes one output item, so the output slot holds 5, and `42/media/lua/client/TraditionalPreservationYeastShelfUI.lua` limits adding to 5 cultures, counting finished ones not yet taken, through the core's `UI.slotRules`, which also keeps a full shelf's slot from showing green. That add loop is copied from vanilla's `ISCraftLogicPanel.ItemSlotAddItems`, so compare the two after a game update. The recipe `time` is in game seconds; `TraditionalPreservationYeast.lua` sets it from the sandbox's Ferment Days on `OnInitGlobalModData` (through the core's `Weather.setRecipeHours`). The engine's craft timers run at the fixed speed of a 60-minute day and ignore Day Length, so the timer's own count is not used. Raise Fed Culture runs on the same shelf and rules, its time from `Y.RAISE_HOURS` (24). The recipe's `OnStart` marks the weather ledger's totals for the shelf's place (Open, Sheltered or Basement), and its `OnUpdate` adds the work done since then at that place's temperature and sets the elapsed time from it, so a culture runs slower in the cold and keeps working while its shelf is unloaded. The ledger lives in global ModData and is kept by TP Core (`TraditionalPreservationCore/Weather`).

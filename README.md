# Traditional Preservation (Yeast) — Build 42 prototype (v0.4.22)

**Status: experimental.** Back up your save before enabling.

Grow your own baker's yeast once the looted packets are gone: flour and water in a glass jar, left on a Fermenting Shelf for about five days at a good temperature, give the same vanilla Yeast you find in kitchens, and the jar back. The shelf works by its place: a warm room or a fire's side is quick, a cold one slow, and frost stops it.

## Install (Arch Linux / Steam)

Copy the `TraditionalPreservationYeast` folder into `~/Zomboid/mods/`, so the metadata file is:
`~/Zomboid/mods/TraditionalPreservationYeast/42/mod.info`

It needs the **TP Core** mod (`TraditionalPreservationCore`, the series' shared mod) installed and enabled the same way (`~/Zomboid/mods/TraditionalPreservationCore`), and no other mods.

Enable **Traditional Preservation (Yeast)** for your existing save from
**Load → select save → More → Choose Mods** (wording can differ by game version).

## How it works

1. **Build a Fermenting Shelf** against a wall (Build menu, Furniture): 2 planks + 4 nails + any hammer (kept), Carpentry 2. Gives 10 Carpentry XP.
2. **Make Fermenting Culture** (Cooking): 5 uses of flour + a glass jar (Empty Jar or Crafted Jar) holding at least 0.3 L water → 1 Fermenting Culture. Gives 3 Cooking XP.
3. Open the shelf, add up to 5 cultures and press **Craft**.
4. After five in-game days at a good temperature, take 1 vanilla `Base.Yeast` and 1 empty jar per culture from the shelf.

No vanilla recipes or loot distribution are changed. No hunger, calorie or yeast-buff changes.

### Shelf behaviour

- Each press of **Craft** starts its own timer. Cultures added and started later finish later; cultures started by the same press finish together.
- The shelf holds 5 cultures in total, counting waiting, fermenting and finished-but-uncollected ones.
- **Cancel** stops every running batch and returns the cultures.
- Fermentation continues while the area is unloaded. It goes by the temperature where the shelf stands (see below), and rain doesn't matter.
- The shelf shows one jar for each culture on it, coloured by that culture's own timer: pale when fresh, amber from halfway, and dark brown when done. A finished jar stays visible until both its yeast and empty jar are collected.

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

`luajit tests/test_ferment.lua` checks the temperature curve, places, the timer and the sandbox options, `luajit tests/test_shelf.lua` the shelf's jars and its five-culture rule, and `luajit tests/test_console.lua` the debug commands. `luajit tools/season_report.lua` runs the rules against `tools/climate_year.csv`, the game's forecasts (golden-checked by `tp test Yeast`).

## Rebuilding the tileset

The shelf and its jars are painted by code, so there is no art to edit by hand. `tools/shelf_art.py` draws the shelf and `tools/build_shelf_tileset.py` draws the jars; the tables and colours at the top of each control the look. To change them, edit the scripts and run `python3 tools/build_shelf_tileset.py` (needs Pillow). It rewrites `42/media/traditionalpreservationyeast.tiles` and `42/media/texturepacks/traditionalpreservationyeast.pack`. It also writes the generated `42/media/lua/shared/TraditionalPreservationYeast/Tiles.lua`, the tile numbers the Lua reads (don't edit it by hand), and `luajit tests/test_tiles.lua` checks the entity scripts against it.

## Debug commands

In debug mode, `TPY.help()` in the Lua console lists commands for testing this mod. They are described in `DEVHELP.md`.

## Known prototype caveats

- The workstation uses plain `CraftLogic`, which no vanilla entity uses in a script (vanilla racks use `DryingCraftLogic`, whose speed depends on temperature). The engine and UI support it, but it is a less travelled path.
- The returned jar is always `Base.EmptyJar`, even if a crafted jar was used.
- `tiledef` number 5127 must be unique among your active mods. If another mod uses it, change it in `42/mod.info`.
- Multiplayer is not supported. This mod is singleplayer only for now.
- If the shelf or recipes don't appear, review `~/Zomboid/console.txt`.

## Engineering notes

The shared Traditional Preservation core (weather, places, station tracking, popups) is the required TP Core mod (id `TraditionalPreservationCore`), loaded as `require "TraditionalPreservationCore/Weather"`. Edit it there. The fermenting curve, the jars and the five-culture limit stay in this mod's own files.

The shelf uses no `SpriteOverlayConfig`, because that shows one sprite for the first batch only. `42/media/lua/server/TraditionalPreservationYeastShelf.lua` reads each batch's progress through `CraftLogicUILogic` and layers one attached sprite per jar instead. Each culture makes two output items, so the output slot holds 10 and `42/media/lua/client/TraditionalPreservationYeastShelfUI.lua` limits adding to 5 cultures through the core's `UI.slotRules`, which also keeps a full shelf's slot from showing green. That add loop is copied from vanilla's `ISCraftLogicPanel.ItemSlotAddItems`, so compare the two after a game update. The recipe `time` is in game seconds; `TraditionalPreservationYeast.lua` sets it from the sandbox's Ferment Days on `OnInitGlobalModData` (through the core's `Weather.setRecipeHours`). The engine's craft timers run at the fixed speed of a 60-minute day and ignore Day Length, so the timer's own count is not used. The recipe's `OnStart` marks the weather ledger's totals for the shelf's place (Open, Sheltered or Basement), and its `OnUpdate` adds the work done since then at that place's temperature and sets the elapsed time from it, so a culture runs slower in the cold and keeps working while its shelf is unloaded. The ledger lives in global ModData and is kept by TP Core (`TraditionalPreservationCore/Weather`).

# Traditional Preservation (Yeast) — Build 42 prototype (v0.4.5)

## Install (Arch Linux / Steam)

Copy the `TraditionalPreservationYeast` folder into `~/Zomboid/mods/`, so the metadata file is:
`~/Zomboid/mods/TraditionalPreservationYeast/42/mod.info`

Enable **Traditional Preservation (Yeast)** for your existing save from
**Load → select save → More → Choose Mods** (wording can differ by game version).

## How it works

1. **Build a Fermenting Shelf** against a wall (Build menu, Furniture): 2 planks + 4 nails + any hammer, Carpentry 2.
2. **Make Fermenting Culture** (Cooking): 5 uses of flour + a glass jar holding at least 0.3 L water → 1 Fermenting Culture.
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

A culture works by the temperature where the shelf stands, like the stations in the other Traditional Preservation mods. It's best from **18 to 30 C**, at 40% speed at 10 C, 20% at 5 C, and only crawls near freezing, without ever dying. Real heat slows it too (60% at 35 C).

- **Outdoors** (a shelf on an outside wall): the day's weather.
- **Under a roof**: a building evens out the weather, so it follows the average outdoor temperature of the last 10 days or so, plus 10 C, and never goes above 28 C. A warm afternoon or a cold night makes no difference.
- **In a basement** (any level below ground): **15 C all year**, so a culture takes about 6 days in any month.

Time keeps counting while you're away, from the weather recorded every 10 in-game minutes. Hover a fermenting culture in the shelf's window for its progress, real time left at today's temperature, the temperature and place, and its working rate. **Temperature sensitivity** in the sandbox options sets how much this matters, and **Off** makes every culture take the same time whatever the weather, as before 0.4.0.

Days a culture takes by the month it's started, on the game's forecasts for default weather:

| Month | Outdoors | Under a roof | Basement |
|---|---|---|---|
| Jan | 42–62 | 14–30 | 6 |
| Feb | 31–52 | 7–26 | 6 |
| Mar | 16–34 | 5–21 | 6 |
| Apr | 9–20 | 5–10 | 6 |
| May | 5–13 | 5–6 | 6 |
| Jun | 5–8 | 5 | 6 |
| Jul | 5–6 | 5 | 6 |
| Aug | 5–8 | 5 | 6 |
| Sep | 5–10 | 5 | 6 |
| Oct | 8–18 | 5–9 | 6 |
| Nov | 18–61 | 5–23 | 6 |
| Dec | 59–62 | 11–27 | 6 |

So a kitchen shelf is enough from spring to autumn, and in winter a basement shelf keeps the yeast coming.

## Changing the timer

Set **Fermenting time (days)** (the time at the best temperature) and **Temperature sensitivity** (Off, Forgiving, Normal, Harsh) under Traditional Preservation (Yeast) in the sandbox options. The default is `FERMENT_HOURS` at the top of `42/media/lua/shared/TraditionalPreservationYeast.lua`. Fractions work. Running batches pick up the new time after a game restart.

`luajit tests/test_ferment.lua` checks the temperature curve, places, the timer, cultures from older saves and the sandbox options.

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

The `TraditionalPreservationYeast/Core/` folders under `42/media/lua/shared` and `42/media/lua/client` are the shared Traditional Preservation core (weather, places, station tracking, popups), copied in from `~/MODS/TraditionalPreservationCore` by `tp sync`. Edit them there, not here. The fermenting curve, the jars and the five-culture limit stay in this mod's own files.

The shelf uses no `SpriteOverlayConfig`, because that shows one sprite for the first batch only. `42/media/lua/server/TraditionalPreservationYeastShelf.lua` reads each batch's progress through `CraftLogicUILogic` and layers one attached sprite per jar instead. Each culture makes two output items, so the output slot holds 10 and `42/media/lua/client/TraditionalPreservationYeastShelfUI.lua` limits adding to 5 cultures through the core's `UI.slotRules`, which also keeps a full shelf's slot from showing green. That add loop is copied from vanilla's `ISCraftLogicPanel.ItemSlotAddItems`, so compare the two after a game update. The recipe `time` is in game seconds; `TraditionalPreservationYeast.lua` sets it from the sandbox's Ferment Days on `OnInitGlobalModData` (through the core's `Weather.setRecipeHours`). The engine's craft timers run at the fixed speed of a 60-minute day and ignore Day Length, so the timer's own count is not used. Since 0.4.0 the recipe's `OnStart` marks the weather ledger's totals for the shelf's place (Open, Sheltered or Basement), and its `OnUpdate` adds the work done since then at that place's temperature and sets the elapsed time from it, so a culture runs slower in the cold and keeps working while its shelf is unloaded. The ledger lives in global ModData and is kept by the shared core (`Core/Weather.lua`). `fermentStartHour` is only read to carry over a batch started before 0.4.0, whose hours all count in full.

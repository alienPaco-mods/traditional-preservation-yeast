# Changelog: Traditional Preservation (Yeast)

## 0.6.9
- **Standing on the Drying Cloth** (user, session 77): yeast cakes lying on TP Core's cloth take vanilla's rug depth
  (`common/media/tileDepthTextureAssignments.txt`, written by `tools/build_shelf_tileset.py`), as the cloth does, so
  a character standing there is drawn over them too.

## 0.6.8
Needs TP Core 0.1.52 (its `Frost`).
- **Frost** (session 76): a culture freezes at 0 C, where its work already pauses, counted by place on TP Core's frost
  record (`Y.FROST`). A Fermenting Culture frozen through (6 hours in all), on the shelf or carried, goes **hungry**:
  its `fedAt` moves back, so one refresh puts it right. Active Culture, Hopped Culture and wet Yeast Cakes (in hand,
  in a container or on the Drying Cloth) and a done jar on the shelf take **1/48 of their days to Spent** an hour
  frozen (`Frost.STARTER_RUIN_HOURS`). A Fed Culture rising only waits; Dried Yeast Cakes take nothing; a cooked or
  burnt item keeps vanilla's timers and never freezes. A basement never freezes, nor a place by a lit fire or banked
  embers.
- New sandbox option **Starters freeze** (`FrostDamage`, on): off, frost does no harm and the records go on counting.
- Save keys: item modData `tpyFrost` (a kept culture's and a carried Fermenting Culture's frost record); a shelf jar's
  `frost` and a cloth lot's `frost` in their own records.
- Console: `TPY.frost(hours)`; `TPY.shelf()` and `TPY.cultures()` show hours frozen. New `tests/test_frost.lua`.
- `tools/season_report.lua` counts frost (golden re-recorded): from November to March a finished culture lasts about
  two days above ground and cake lots go Spent before they dry; basements unchanged; a plain culture up to about two
  days longer where it froze through. README and guide tables refreshed.

## 0.6.7
- **Fermenting Shelf Info built to the approved mock** (`art/all_info_mock.png`): a band (Empty, Lost, Hungry, Done,
  Waiting, Fermenting with the next jar to go hungry or be done; worst first), the Station block (outline icon, Place,
  Season, Working Rate), the five jars as cells in the jar pattern with the barm lore beside them, cultures dragged
  onto them go on (the drop square is gone), each row's "Hungry in" or "Off in" as an amber warning at its right,
  and Refresh the Cultures, Take Done and Take All with their icons.
- Make Fermenting Culture and with Fruit get **One / All (n)** on the water container's right-click, as with Potato
  Water (TP Core's RecipeUI): All counts every jar type in reach, where the crafting window's MAX counts only the
  type in its jar slot (vanilla's hand-craft panel is always manual select).
- The button and menu row read **Refresh Cultures (n)** (was Refresh the Cultures), so Shelf Info's three buttons sit
  in one row.

## 0.6.6
- Yeast cakes take a fifth of the Drying Cloth's room a batch (`Y.CAKE_ROOM` 10 of 50; TP Core 0.1.44's room): five
  batches a cloth as before, and they share it with kefir grains by room. Each batch stays its own lot (`perLot` 1),
  so each keeps its own age.

## 0.6.5
- Yeast cakes on the Drying Cloth show in Cloth Info's cells as the item's icon lays them at twice its size, cut to the cell: two behind, high, the third laid on top of them, in the series' pattern colours with a cross cut in each (TP Core 0.1.39's patterns);
  `TPCell_YeastCakes`, and `TPCell_Jar` for the Fermenting Shelf's window.

## 0.6.4
- Fermenting Shelf Info's drop square shows a Fermenting Culture jar.

## 0.6.3
- The window rows read the station's full name and Info (Fermenting Shelf Info), as vanilla's Fireplace Info and
  Generator Info; the window's title is the bare name. The short "Vessel Info", "Tub Info" and the like are gone.

## 0.6.2
- **A full pot** (user): Steep Hops and Mash Potato in Water take a full Cooking Pot or Forged Pot, 1.5 L of clean
  water (tainted refused), and all of it turns (1.5 L of Hop Water or Potato in Water), so nothing is poured off;
  one Hops or Potato a pot. The hops and starters kits give a full pot.
- **Half a litre a culture, every liquid** (user; 0.6.1's third): water for the plain and fruit starts, Potato Water,
  and Hop Tea for a feed. A full pot makes three, a 1 L bottle or jar two, a Ceramic Jar five, none left over. The
  culture kit gives a full Cooking Pot for its three jars (and its bottle for the refreshes).
- **Every culture's liquid from whatever holds it** (user; the series' `item 1 [*]` + fluid line, as Strain Lard):
  Make Fermenting Culture (plain, with Fruit, with Potato Water) takes an **empty jar**, the culture's jar, and its
  water or Potato Water from any container, which is kept; Feed Culture takes its Hop Tea the same way (its list of
  containers is gone). Before, the starts' water had to be in the culture's jar, so a pot of Potato Water didn't
  offer its recipe.
- **Hand recipes work from the floor** (series recipe audit, 2026-11-19): every hand recipe but Packing has
  `CanBeDoneFromFloor`, so its inputs aren't carried into the inventory first (vanilla moves them otherwise): all nine.
- **The game's names** in the README and guide: ceramic jar (was "clay jar").
- **One or All from the pot** (user; needs TP Core 0.1.32): right-click a pot of Potato Water or Hop Tea, and its
  Make Fermenting Culture with Potato Water or Feed Culture row opens **One** and **All (n)**, n what the pot's half
  litres and the jars and flour in reach allow (TP Core's `RecipeUI`, `TraditionalPreservationYeastCultureUI.lua`).
  The crafting window's own count works as before.

## 0.6.1
- **Fix:** Steep Hops and Mash Potato in Water take a Cooking Pot or Forged Pot only. Both need exactly 1 L of water,
  and vanilla's Saucepan and Copper Saucepan hold 0.6 L, so they were listed but could never be used (user, session
  56). The hops and starters kits give a Cooking Pot of 1 L (their saucepan was filled to 0.6 L only).
- **A third of a litre** (0.33333, was 0.3; user) for Make Fermenting Culture (plain, with Fruit and with Potato
  Water) and Feed Culture's Hop Tea: a litre makes three with none left in the container (the engine drops a fluid
  under 0.0001 L; the third take still finds 0.33334 L, where 0.333 would leave a millilitre). One potato's Potato
  Water starts three jars. The starters kit has
  4 jars and 20 flour for it.

## 0.6.0
- **The Fermenting Shelf off CraftLogic, and its second look** (2026-11-19, session 56; ROADMAP section 12; needs TP
  Core 0.1.31). No crafting window: the jars are the shelf's own record in its movableData (`tpyShelf`), one a culture,
  each on its own clock, stepped by the World (`TraditionalPreservationYeastWorld.lua`, was
  `TraditionalPreservationYeastShelf.lua` on the server; the record is now the shared file of that name). Right-click:
  what it holds, **Shelf Info** (TP Core's piece list: a row a jar, a tab for Fermenting and one for Fed cultures when
  both are on, Refresh / Take Done / Take All buttons, a drop square), *Put ... on the Shelf* (One / All), **Refresh the
  Cultures**, **Take Done**, **Take Everything Off**; the hand jobs are `TPYShelf`. A shelf with anything on it can't be
  picked up. The Ferment Culture and Raise Fed Culture recipes, the slot rules, the crafting-window info block and the
  progress popups are gone.
- **Refreshing** (user, session 56): a Fermenting Culture is hungry after 24 hours of work (the culture's own curve)
  since it was made or last refreshed, and stops; after 72 it has gone off and comes off as its empty jar. Refresh the
  Cultures feeds every one on the shelf: a use of flour (in reach) and 0.1 L of water (carried) a jar, the hungriest
  first. It goes hungry off the shelf too, from the moment it is made (modData `tpyRun`), so taking jars off doesn't skip
  the refresh; its progress counts only on the shelf. A Fed Culture needs none.
- **Quicker starts:** **Make Fermenting Culture with Fruit** (an Apple, Pear, Peach, Cherry, Grapes or Dried Apricots)
  takes 80% of the ferment time (4 days), **with Potato Water** 70% (3.5 days); the culture's name says its start
  (modData `tpyStart`). **Mash Potato in Water** (a pot or saucepan of exactly 1 L water + a Potato) gives Potato in
  Water, which turns to **Potato Water** after half an hour steaming (TP Core's `ItemFluid.turnsHot`).
- **Done on the shelf, a jar keeps** by place from the moment it was done (the keeper's ledger), goes Spent there, and
  comes off as old as it is.
- **Art:** two new looks in every jar, hungry (sunk, grey liquid on top, a dried ring; a clay jar's cloth darker grey,
  user's pick) and gone off or Spent (mould), and two start looks in glass only (fruit peel, potato bits; a clay jar
  hides them). The sheet would pass 512 tiles with every look in every jar, so the starts sit after the grid
  (`Tiles.GRID_LOOKS`, `FIRST_START_JAR`); the cakes moved to 464. Preview: `WIP/TPCore/art/yeast_shelf_mock.png`.
- **Console:** `TPY.shelf()`; `TPY.fast` sets the plain time live; `TPY.give` takes potato and apple, and a culture given
  starts fed; `TPY.kit("starters")`, and the culture kit has flour for the refreshes. **Season report:** jars refreshed
  daily; every column as before but the moved jar's (the hour of the move now counts at the place it left, FluidAgeing's
  rule: under 0.1 day); golden recorded anew. Tests: ferment and shelf tests rewritten on jars, culture and console
  follow.

## 0.5.0
- **Culture, cakes and hops** (2026-11-19; needs TP Core 0.1.20 for the Drying Cloth). The shelf no longer makes
  vanilla Yeast directly: it gives a live **Active Culture** in the jar it went on in, which keeps by its place on TP
  Core's PlaceKeeping (3 fresh and 5 days to Spent in a 15 C cellar: about 3 days at 20 C, a day at 30 C) and reads
  (Fresh) or (Spent). **Shape Yeast Cakes** (a culture + 3 Cornmeal or Flour, the jar back) gives wet Yeast Cakes,
  which keep 5 fresh and 8 days to Spent and dry on TP Core's **Drying Cloth** in 168 hours at full speed (15 to
  25 C, slower cool or hot, waiting in a shut room and below freezing, dead after an hour above 35 C) into **Dried
  Yeast Cakes**, which keep. Wet on the cloth they keep ageing (the culture's curve held at its 20 C speed above 20 C,
  slowed by wetness squared) and a lot that goes Spent first is gone off; **Crumble
  Yeast Cakes** makes them a packet of vanilla Yeast. **Steep Hops** (1 L of water in a pot or saucepan + Hops
  (Dried)) gives Hop Water, which turns to **Hop Tea** after a quarter of an hour steaming; **Feed Culture** (a
  culture + an empty jar + 0.3 L Hop Tea + 5 flour) gives 2 Fed Culture, and **Raise Fed Culture** on the shelf (a day
  at the best temperature) makes them **Hopped Culture**, which keeps twice as long (7 / 10 cellar days). **Pour Out
  Culture** gives any culture's jar back.
- **Jars:** a culture is made in a Jar, Ceramic Jar or Glazed Ceramic Jar, and every step gives back the same jar
  (modData `tpyJar`); a ceramic culture has its own icon and ground model. The shelf draws each jar's kind (tileset:
  three kinds by five looks, a fed jar with a hop sprig), and its output slot holds 5 (one item a culture).
- **Console:** `TPY.cultures()`; `TPY.give` takes active, fed, hopped, cakes, dried and hops; `TPY.kit("cakes")` and
  `TPY.kit("hops")`, and the culture kit has a jar of each kind. **Season report:** how long Active and Hopped Culture
  keep and how long a lot of cakes takes on the cloth, by place and month (golden recorded anew; the culture's days
  are unchanged). Tests: `test_culture.lua` new; shelf, ferment and console tests follow.

## 0.4.24
- **Aired rooms** (2026-11-19, TP Core 0.1.15): the shelf reads TP Core's new place temperatures (a shut room
  follows the last three days and is stuffy in summer, so autumn indoors is slower: a November culture about 67 days
  where it was 21; by a fire still 5). `tools/season_report.lua`: an aired room column (was loft). Needs TP Core 0.1.15.

## 0.4.23
- **Five places** (2026-11-19, TP Core 0.1.14): TP Core has no Enclosed place any more, so `TPY.weather()` and the
  ledger have no shed; the guide's console table follows. Nothing else changes in game.

## 0.4.22
- **Naming sweep** (2026-11-16, TP Core's DEVGUIDE "How code is named"): the ledger's `Y.PROCESS` (was `KIND`), the shelf's jar `looks` (`jarLooks`, `Tiles.JAR_LOOKS`; the tile builder's `JAR_COLOURS`, rerun byte-identical). Tests and golden results unchanged; nothing changes in game. Saved keys follow TP Core's renames (`workHours`, `marks`, the Smokehouse stack's hours): pre-release, an old test save's stations read as new, so test on a fresh save.

## 0.4.21
- **Guide** (2026-11-15): the loft keeps the Indoors column from November to April (was October); culturing in the open air takes 5 to 9 days at its best (May is 9). Nothing changes in game.
- **Guide shortened** (2026-11-15): the warmth secrets point to the Almanac, the loft to TP Core's guide; repeated notes and a tip cut. Nothing changes in game.
- **README says what is** (2026-11-15): no version tags or dev-machine paths; the tests line no longer lists older-save cultures (no such test). Nothing changes in game.
- **Docs** (2026-11-15): decisions in this CHANGELOG are stated plainly, without attributions. Nothing changes in game.
- **README** (2026-11-15): an opening paragraph and a status line.
- **README** (2026-11-15): its heading names 0.4.21 (was 0.4.13), as mod.info does.
Refactor with TP Core's names (2026-11-15): TP Core's `Hearth` is `Fire`; the place by a fire is `Fireside` (the season report's line reads Fireside indoors). Nothing changes in game.

## 0.4.20
Refactor (refactor pass step c, Yeast): nothing changes in game. **Pre-release leftovers gone:** the carry-over for a culture from before temperature counted (`fermentStartHour`, hours worked out from the elapsed time; a run its start hook never saw is now left alone, as Vinegar's are) and the clearing of a pre-0.3.0 shelf's single overlay, with their tests. **The ledger's totals are named by their kind**: `cultureOpen`, `cultureOpenRate` and so on (were the plain `Open`, `OpenRate` kept from 0.3); `Y.KIND` names it for `TPY.age` and `TPY.weather`. **A run's place before its World first sees it** is TP Core's `Weather.NEW_RUN_PLACE` (as Vinegar and Fish & Meat; was Sheltered): it only covers the moments before the shelf's first look, and the season report's numbers are unchanged. **Say it once:** `Y.finishedCultures` counts the cultures not yet taken (the shelf's sprites and its info block each had a copy); `Weather.recipeHours` reads a batch's recipe hours. **Named:** `Y.RECIPE_NAME` (the console had its own), `Y.YEAST`, `Y.LOG_TAG`. `KINDS` names `Y.cultureRate` directly. **New console command `TPY.kit(kind)`**: `build`, `culture`, or `all`; `TPY.kit()` lists them. `TPY.give` takes any full type too. test_console checks both. Tests pass; the season report's golden changes only in the ledger's key names (every number the same), recorded anew. In-game step 161 of TP Core's `TESTING_GUIDE.md` (INGAME_PASS 160).

## 0.4.19
Refactor with TP Core's Weather.lua tidy (2026-11-14): the culture rate is `Weather.rate`. Nothing changes in game; tests and golden results unchanged.

## 0.4.18
**No station in front of a door** (after TP Core's in-game step 146b): the Fermenting Shelf can't be built or put down on the tile in front of a door (TP Core's `Doors`): its build recipe asks `TraditionalPreservationCore.doorFits`, and `UI.keepDoorsFree(Tiles.STATIONS)`. In-game step 147 of TP Core's `TESTING_GUIDE.md` passed (INGAME_PASS 146).

## 0.4.17
Refactor with TP Core's Hearth.lua split (2026-11-14): `Y.placeTemperature` is `Weather.placeTemperature` (TP Core dropped the `Hearth.placeTemperature` alias). Nothing changes in game; tests and golden results unchanged.

## 0.4.16
Guide and README: TP Core's Hearth and Firebox are the Stone Hearth (2026-11-14).

## 0.4.15
- **Docs regenerated** (2026-11-13): the README's table, the Baker's Almanac and the Yearly Plan from `tools/season_report.lua` (the settled year: January indoors about 91 days, porch fire 11, campfire 20); the fire's 28 C is indoors only, outside the air's plus a lift; *Paused here (frozen)* in the README, guide and Workshop text.
- **A frozen culture pauses** (realism pass L6): at 0 C and below the culture stops (TP Core's `Weather.frozen`) and goes on once thawed, on Forgiving, Normal and Harsh alike; Off still ignores the weather. The 0.02 floor holds above freezing only. A January culture in an unheated room (about -1.6 C) now waits there: about 91 days started on the first (was 59), carried by the warmer days; the basement is unchanged. The popup and the shelf's info block say *Paused here (frozen)* instead of a time left. `tools/season_report.lua` prints a paused popup as such; golden re-recorded. Tests in `test_ferment.lua`. In-game step 118 of `TESTING_GUIDE.md`.

## 0.4.14
- **The realism pass's Core part reaches the shelf** (TP Core, 2026-11-13): an unheated room or loft is 2 C warmer in the cold months (a January culture indoors about 59 days, was 72); a fire under an open roof or in the open warms the air it stands in instead of holding 28 C (indoors unchanged: 5 days). `tools/season_report.lua` gains *By a fire, under a roof* and *in the open* columns (January: about 11 and 20 days). Test `test_ferment.lua` follows the warmer room. The guide's tables wait for the culture's frozen stop (ROADMAP, the curve edits), to be regenerated once.

## 0.4.13
- **The Yearly Plan** (guide chapter 11): culturing by place, as the game's planting seasons: season, best and poor months, out of season, and the days at best, from the Baker's Almanac. The Tester's Toolkit is now chapter 12.
- **Docs pass, sweep step G** (2026-11-12): the Baker's Almanac and the README's table regenerated from `tools/season_report.lua` (both sampled years; they were narrower than the old ranges), with a Loft column and the grid's 5 days; the days quoted in the text follow it; `TPY.weather()` lists the loft and *In a shed*.
- **The Fermenting Shelf gives 10 Carpentry XP** (was 5; sweep step F): five a level, as the other stations.
- Needs Build 42.22 or newer (`versionMin`, was 42.20: everything is checked on 42.22). README, Workshop text.

## 0.4.12
- **On TP Core's shared modules** (2026-11-12; nothing a player sees): a culture's catch-up and bar go through
  Core's `Hearth.catchUpRun` and `Hearth.updateRun`. In-game step 101 of `TESTING_GUIDE.md`.
- Guide (2026-11-12): checked line by line against the code. The shelf's window block is described; the basement
  takes 3 to 4 weeks from January to March; whole chapter numbers (the Almanac is chapter 6, the Diary 7), a
  Credits page.


## 0.4.11
- **TP Core's loft** (2026-11-12, consistency sweep step H): a shelf in the top storey reads the loft's temperature,
  a room's with the roof's summer warmth: the same as indoors from November to April, up to a day sooner in May,
  September and October. Season report has a Loft column; golden re-recorded. README, guide, Workshop text.

## 0.4.10
- Guide: no emojis (2026-11-12): the decorative bullets and margin-note marks are gone, warning signs read **Warning:**.
- **Info in the Fermenting Shelf's window** (2026-11-12, consistency sweep step E, TP Core's StationInfo): under
  In Progress, the shelf's place, its temperature and the cultures' working rate there, a bar for each running batch
  with its time left, and what is waiting or finished. Shown even with nothing running.

## 0.4.9
- **The cellar runs a month behind** (2026-11-12, TP Core): a basement follows the ground, about 5 C from January to
  March and 13 C from July to September, so a basement shelf is at its best in autumn (about 9 days a culture in
  October) and slow in spring. The season report starts from a long-running save's weather and reads 30-day months
  (each month's forecast also held the 10 days before it, which stretched the old almanac). Guide almanac and
  tips, README, Workshop text.

## 0.4.8
- **By a fire** (2026-11-12, consistency sweep step C): a shelf within 2 tiles of a lit fire works at 28 C, by banked
  embers 24 C (5 days a culture in any month); while you're away the fire counts for as long as its fuel lasts
  (TP Core's `Hearth.catchUp`, `Y.notePlace`). TP Core's new places: an unheated room follows the season (22 C while
  the grid is on), a basement swings a third as far. The popup's place words are Core's. Season report (by a fire),
  README, guide almanac, Workshop text, DEVHELP.

## 0.4.7
- Debug console by the series' convention (2026-11-12, consistency sweep): `TPY.give(name, n)` for `"culture"` and
  `"flour"` (`cultures` and `flour` are gone). Tests, DEVHELP, guide.

## 0.4.6
- Docs (2026-11-11 pass against the code): README names the XP (shelf Carpentry 5, culture Cooking 3), the jars the
  culture takes and every test; guide and Workshop text call the required mod by its name, Traditional Preservation
  (Core). No change in play.
- Balance (series pass, F1): Make Fermenting Culture gives Cooking 3 (was none).
- Internal: new `tests/test_console.lua` loads the debug console (TPY) and calls every command, so one can't
  break unseen as `TPY.here()` did.
- Changed: the season's mean temperature (the shelf's temperature under a roof) is the series' own, kept once by TP
  Core, so Yeast added to a running save agrees with the other mods from its first day. Save keys unchanged.
- Internal: the shelf is told by TP Core's `Station.kinds` lookup; the sensitivity scale is the core's
  (`Y.SENSITIVITY_SCALES` is gone).
- Fixed (debug console only): `TPY.here()` threw since Yeast moved onto the core's `placeOf`; it passes the player
  now.
- Docs: README Install and the Workshop text say the mod needs TP Core (the Workshop text said "no other mods").
- Internal: `test_shelf.lua` stubs `instanceof`, which the core's slot rules now call.
- Changed: Yeast now requires the **TP Core** mod (Traditional Preservation Core) and loads after it. Its own copy
  of the shared core (weather ledger, places, shelf tracking, popups) is gone; it uses TP Core's instead, which is
  the same code. Saves carry over: every save key, item and entity name is unchanged. No change in play.
- Internal: the synced core copies name the core's new source path (TP Core is now a mod). Comment line only.
- Internal: the shared core's folder is now `TraditionalPreservationCore` (was `_tpcore`): comments and test
  paths only. No change in play.

## 0.4.5
- Internal: comments on the public functions that lacked one, and an updated copy of the shared core
  (comments only). No change in play.

## 0.4.4
- Changed: adding more cultures than the shelf has room for now says "The shelf holds five cultures" instead of
  quietly adding fewer. A full shelf's slot no longer shows green while you drag a culture over it, and dropping
  one there says why.
- Internal: the shelf's slot rule runs on the shared core's `UI.slotRules`.

## 0.4.3
- Internal: the culture's recipe time is set through the shared core (`Weather.setRecipeHours`), also by `TPY.fast`.
  README dev notes now describe the weather ledger. No change in play.

## 0.4.2
- Internal: tile numbers come from a `Tiles.lua` the art builder writes, instead of hand-kept numbers. Same art.

## 0.4.1
- Fixed: a shelf in a chunk that had just unloaded could still be updated, so its jar sprites were lost or went to a
  stale chunk. Shelves are now checked against the live cell.
- Internal: runs on the shared Traditional Preservation core (weather ledger, station tracking, popups).
  Same fermenting times; saves carry over unchanged.

# Changelog: Traditional Preservation (Yeast)

## 0.4.15
- **A frozen culture pauses** (realism pass L6, user 2026-11-13): at 0 C and below the culture stops (TP Core's `Weather.frozen`) and goes on once thawed, on Forgiving, Normal and Harsh alike; Off still ignores the weather. The 0.02 floor holds above freezing only. A January culture in an unheated room (about -1.6 C) now waits there: about 91 days started on the first (was 59), carried by the warmer days; the basement is unchanged. The popup and the shelf's info block say *Paused here (frozen)* instead of a time left. `tools/season_report.lua` prints a paused popup as such; golden re-recorded. Tests in `test_ferment.lua`. In-game step 118 of `TESTING_GUIDE.md`.

## 0.4.14
- **The realism pass's Core part reaches the shelf** (TP Core, 2026-11-13): an unheated room or loft is 2 C warmer in the cold months (a January culture indoors about 59 days, was 72); a fire under an open roof or in the open warms the air it stands in instead of holding 28 C (indoors unchanged: 5 days). `tools/season_report.lua` gains *By a fire, under a roof* and *in the open* columns (January: about 11 and 20 days). Test `test_ferment.lua` follows the warmer room. The guide's tables wait for the culture's frozen stop (ROADMAP, the curve edits), to be regenerated once.

## 0.4.13
- **The Yearly Plan** (guide chapter 11, user 2026-11-13): culturing by place, as the game's planting seasons: season, best and poor months, out of season, and the days at best, from the Baker's Almanac. The Tester's Toolkit is now chapter 12.
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

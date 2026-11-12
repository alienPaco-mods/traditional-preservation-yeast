# Changelog: Traditional Preservation (Yeast)

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

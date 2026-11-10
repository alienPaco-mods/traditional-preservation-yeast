# Changelog: Traditional Preservation (Yeast)

## 0.4.6
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

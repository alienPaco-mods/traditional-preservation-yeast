# Changelog: Traditional Preservation (Yeast)

## Unreleased
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

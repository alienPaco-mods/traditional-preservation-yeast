# Traditional Preservation (Yeast): developer help

These console commands load only when the game runs in **debug mode** (launch option `-debug`). Type them into the in-game Lua console, the **Command Console** window, and press Enter. Output goes to the console and to `~/Zomboid/console.txt`.

`TPY.help()` prints this list in the game.

| Command | What it does |
|---|---|
| `TPY.weather()` | The temperature in each place (open air, under an open roof, indoors, a basement, by a fire, by banked embers), how fast a culture works there, and how many days it takes. By a fire counts by the clock, so `TPY.age` doesn't move it. |
| `TPY.cultures()` | Every Active Culture, Hopped Culture and wet Yeast Cakes on you or within reach: the jar, the place, how fast it keeps there, its age and the days to stale and Spent, and its hours frozen in all (and whether its place is freezing now). |
| `TPY.here()` | Which kind of place you're standing in. |
| `TPY.age(hours)` | Gives every shelf this many hours of perfect fermenting weather. Jars go hungry by it too (a day's worth makes a fresh jar hungry). |
| `TPY.fast(hours)` | Test timer: a plain culture takes this many hours (fruit and potato their share). `TPY.fast()` goes back to the sandbox time. |
| `TPY.shelf()` | Every jar on the Fermenting Shelves within 3 tiles: kind, start, jar, state, progress of its hours, work hours since it was fed, and hours frozen in all. |
| `TPY.frost(hours)` | Freezes for `hours` (default 6) the Active Culture, Hopped Culture and wet Yeast Cakes on you or within reach (1/48 of their days to Spent an hour) and every jar on the Fermenting Shelves within 3 tiles (a Fermenting Culture frozen through, 6 hours in all, goes hungry; a done jar takes the same bite; a Fed Culture rising nothing), whatever the sandbox's Starters freeze says. A carried Fermenting Culture counts its frost when put on a shelf, so freeze it there. Lots on the Drying Cloth are left out. |
| `TPY.give(name, n)` | Spawns `n` of: `"culture"` (a Fermenting Culture), `"active"` (Active Culture), `"fed"` (Fed Culture), `"hopped"` (Hopped Culture), `"cakes"` (wet Yeast Cakes), `"dried"` (Dried Yeast Cakes), `"hops"` (Hops (Dried)), `"flour"`, `"potato"`, `"apple"`, or any full type such as `"Base.Yeast"`. `TPY.give()` lists them. A spawned culture is in a glass Jar, fed just now. |
| `TPY.kit(kind)` | The things a test needs: `"build"` (a hammer, 2 planks and 4 nails for the Fermenting Shelf, Woodwork 2), `"culture"` (30 flour, a Jar, a Ceramic Jar, a Glazed Ceramic Jar, a full Cooking Pot of water and a Water Bottle: one Make Fermenting Culture in each jar from the pot, and their refreshes), `"starters"` (an Apple, a Potato, a full Cooking Pot of water, 4 Jars, 20 flour and a Water Bottle: Mash Potato in Water, three cultures with Potato Water and one with Fruit), `"cakes"` (2 Active Culture, 6 Cornmeal, a Sheet and 2 Stones: Shape Yeast Cakes and a Drying Cloth), `"hops"` (an Active Culture, 2 Hops (Dried), a full Cooking Pot of water, a Jar and 5 flour: Steep Hops and Feed Culture) or `"all"`. `TPY.kit()` lists them. |

**Typical check:** `TPY.fast(20)`, `TPY.give("culture", 5)`, *Put Fermenting Culture on the Shelf*, All, then `TPY.age(10)`. The jars should turn amber at halfway, and `TPY.age(10)` again finishes them: five Active Culture (Fresh) to take. **Hunger:** fresh jars and `TPY.age(24)`: hungry (sunk, grey on top), stopped; *Refresh Cultures* with flour and water carried feeds them. `TPY.age(72)` unfed: gone off.

**Cakes:** `TPY.kit("cakes")`, spread the Drying Cloth (right-click the floor), Shape Yeast Cakes twice and lay both lots. TP Core's `TPC.cloth()` shows the lots and `TPC.dryCloth(168)` dries them; take them off as Dried Yeast Cakes and crumble one into Yeast.

**Frost:** a fresh jar on the shelf, `TPY.frost(5)`: still working; `TPY.frost(1)`: hungry, and one refresh feeds it. An Active Culture (Fresh) in hand, `TPY.frost(24)`: half its days gone (`TPY.cultures()`); `TPY.frost(24)` again: Spent.

**Keeping:** `TPY.cultures()` with a culture in hand; TP Core's `TPC.setWeather` changes the place's temperature for a quick look at the rate.

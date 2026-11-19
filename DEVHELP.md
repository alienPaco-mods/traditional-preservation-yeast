# Traditional Preservation (Yeast): developer help

These console commands load only when the game runs in **debug mode** (launch option `-debug`). Type them into the in-game Lua console, the **Command Console** window, and press Enter. Output goes to the console and to `~/Zomboid/console.txt`.

`TPY.help()` prints this list in the game.

| Command | What it does |
|---|---|
| `TPY.weather()` | The temperature in each place (open air, under an open roof, indoors, a basement, by a fire, by banked embers), how fast a culture works there, and how many days it takes. By a fire counts by the clock, so `TPY.age` doesn't move it. |
| `TPY.cultures()` | Every Active Culture, Hopped Culture and wet Yeast Cakes on you or within reach: the jar, the place, how fast it keeps there, its age and the days to stale and Spent. |
| `TPY.here()` | Which kind of place you're standing in. |
| `TPY.age(hours)` | Gives every shelf this many hours of perfect fermenting weather. `TPY.age(120)` finishes a culture. |
| `TPY.fast(hours)` | Test timer: a culture takes this many hours. `TPY.fast()` goes back to the sandbox time. |
| `TPY.give(name, n)` | Spawns `n` of: `"culture"` (a Fermenting Culture), `"active"` (Active Culture), `"fed"` (Fed Culture), `"hopped"` (Hopped Culture), `"cakes"` (wet Yeast Cakes), `"dried"` (Dried Yeast Cakes), `"hops"` (Hops (Dried)), `"flour"`, or any full type such as `"Base.Yeast"`. `TPY.give()` lists them. A spawned culture is in a glass Jar. |
| `TPY.kit(kind)` | The things a test needs: `"build"` (a hammer, 2 planks and 4 nails for the Fermenting Shelf, Woodwork 2), `"culture"` (15 flour, a Jar, a Ceramic Jar, a Glazed Ceramic Jar and a Water Bottle: one Make Fermenting Culture in each jar), `"cakes"` (2 Active Culture, 6 Cornmeal, a Sheet and 2 Stones: Shape Yeast Cakes and a Drying Cloth), `"hops"` (an Active Culture, 2 Hops (Dried), a Saucepan of 1 L water, a Jar and 5 flour: Steep Hops and Feed Culture) or `"all"`. `TPY.kit()` lists them. |

**Typical check:** `TPY.give("culture", 5)`, load the shelf and press Craft, then `TPY.age(60)`. The jars should turn amber at halfway, and `TPY.age(60)` again finishes them: five Active Culture (Fresh) to take.

**Cakes:** `TPY.kit("cakes")`, build the Drying Cloth, Shape Yeast Cakes twice and lay both lots. TP Core's `TPC.cloth()` shows the lots and `TPC.dryCloth(168)` dries them; take them off as Dried Yeast Cakes and crumble one into Yeast.

**Keeping:** `TPY.cultures()` with a culture in hand; TP Core's `TPC.setWeather` changes the place's temperature for a quick look at the rate.

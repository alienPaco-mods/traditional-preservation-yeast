# Traditional Preservation (Yeast): developer help

These console commands load only when the game runs in **debug mode** (launch option `-debug`). Type them into the in-game Lua console, the **Command Console** window, and press Enter. Output goes to the console and to `~/Zomboid/console.txt`.

`TPY.help()` prints this list in the game.

| Command | What it does |
|---|---|
| `TPY.weather()` | The temperature in each place (open air, under an open roof, indoors, a basement, by a fire, by banked embers), how fast a culture works there, and how many days it takes. By a fire counts by the clock, so `TPY.age` doesn't move it. |
| `TPY.here()` | Which kind of place you're standing in. |
| `TPY.age(hours)` | Gives every shelf this many hours of perfect fermenting weather. `TPY.age(120)` finishes a culture. |
| `TPY.fast(hours)` | Test timer: a culture takes this many hours. `TPY.fast()` goes back to the sandbox time. |
| `TPY.give(name, n)` | Spawns `n` of: `"culture"` (a Fermenting Culture) or `"flour"`. `TPY.give()` lists them. |

**Typical check:** `TPY.give("culture", 5)`, load the shelf and press Craft, then `TPY.age(60)`. The jars should turn amber at halfway, and `TPY.age(60)` again finishes them.

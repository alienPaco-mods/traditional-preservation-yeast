-- Traditional Preservation (Yeast) B42: One and All on a vessel's culture row (TP Core's RecipeUI). Water (with a fruit
-- or without) or Potato Water starts a culture a half litre, Hop Tea feeds one a half litre, so a full pot (1.5 L) is
-- three. All counts every kind of jar in reach; the crafting window's MAX counts only the jar type in its slot.
local RecipeUI = require "TraditionalPreservationCore/RecipeUI"
local Y = TraditionalPreservationYeast

-- What each culture recipe takes from the vessel (the recipe script).
local CULTURE_LITRES = 0.5

RecipeUI.oneOrAll({ recipe = "TraditionalPreservationYeast.MakeFermentingCulture", fluid = "Water", litres = CULTURE_LITRES })
RecipeUI.oneOrAll({ recipe = "TraditionalPreservationYeast.MakeFermentingCultureFruit", fluid = "Water", litres = CULTURE_LITRES })
RecipeUI.oneOrAll({ recipe = "TraditionalPreservationYeast.MakeFermentingCulturePotato", fluid = Y.POTATO_WATER,
    litres = CULTURE_LITRES })
RecipeUI.oneOrAll({ recipe = "TraditionalPreservationYeast.FeedCulture", fluid = Y.HOP_TEA, litres = CULTURE_LITRES })

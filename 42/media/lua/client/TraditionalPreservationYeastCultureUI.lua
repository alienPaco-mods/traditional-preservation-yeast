-- Traditional Preservation (Yeast) B42: One and All on a pot's culture row (TP Core's RecipeUI). A pot of Potato
-- Water starts a culture a half litre, a pot of Hop Tea feeds one a half litre, so a full pot (1.5 L) is three.
local RecipeUI = require "TraditionalPreservationCore/RecipeUI"
local Y = TraditionalPreservationYeast

-- What Make Fermenting Culture with Potato Water and Feed Culture take (the recipe script).
local CULTURE_LITRES = 0.5

RecipeUI.oneOrAll({ recipe = "TraditionalPreservationYeast.MakeFermentingCulturePotato", fluid = Y.POTATO_WATER,
    litres = CULTURE_LITRES })
RecipeUI.oneOrAll({ recipe = "TraditionalPreservationYeast.FeedCulture", fluid = Y.HOP_TEA, litres = CULTURE_LITRES })

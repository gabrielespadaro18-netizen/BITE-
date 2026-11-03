import Foundation

/// Structured tags and draft recipes that sit on top of the World Table catalogue.
///
/// Tags (`DraftData.tags`) cover all 90 recipes:   id | allergens | intolerances | diets | €/serving | goals
///   allergens:     milk eggs wheat peanuts treenuts soy fish shellfish sesame
///   intolerances:  gluten lactose histamine fructose sorbitol caffeine sulfites
///   diets:         veg vegan halal   ("-" = none; halal assumes halal-certified meat)
///   goals:         H high-protein · L low-carb · E eat-healthier · B budget
///
/// Drafts (`DraftData.drafts`) cover the 68 recipes World Table has not verified yet:
///   id | minutes | servings | ingredients | steps
///   ingredient = "amount:name~c"  with c = p produce · d dairy&eggs · g grains · m fish&meat · x misc
///   steps are separated by " // ".
/// Drafts are traditional, commonly published versions written for the app. They are NOT verified by
/// World Table: the app labels them as drafts and only suggests them to people without dietary restrictions.
enum DraftData {
    static let tags = #"""
pizza-margherita|wheat,milk|gluten,lactose,histamine|veg,halal|2|B
pasta-alla-carbonara|eggs,wheat,milk|gluten,lactose|-|3|H
lasagne-al-forno|wheat,milk,eggs|gluten,lactose,histamine|-|3.5|H
risotto-alla-milanese|milk|lactose,sulfites|-|3|-
parmigiana-di-melanzane|milk,wheat|lactose,gluten,histamine|veg,halal|2.5|-
ratatouille|-|histamine|vegan,veg,halal|2|E,B,L
tortilla-espanola|eggs|-|veg,halal|1.5|B,H
okonomiyaki|eggs,wheat,fish,soy|gluten,histamine|-|3|-
mapo-tofu|soy|histamine|-|3|H
butter-chicken|milk|lactose|halal|4|H
chicken-tagine|-|-|halal|4|H,E,L
koshari|wheat|gluten|vegan,veg,halal|1|B,E
jollof-rice|-|histamine|halal|1.5|B
hamburger|wheat,sesame,milk,eggs|gluten,lactose|-|3.5|H
tacos-al-pastor|-|histamine|-|3|H
poutine|milk,wheat|lactose,gluten|-|3|-
pao-de-queijo|milk,eggs|lactose|veg,halal|1.5|B
choripan|wheat|gluten|-|3|-
ceviche-peruano|fish|histamine|halal|5|H,L,E
lamington|wheat,eggs,milk|gluten,lactose|veg,halal|1.5|B
pavlova|eggs,milk|lactose,fructose|veg,halal|2|-
kokoda|fish|histamine|halal|4|H,L,E
boeuf-bourguignon|wheat|gluten,sulfites,histamine|-|5|H
coq-au-vin|wheat|gluten,sulfites,histamine|-|4.5|H
quiche-lorraine|wheat,eggs,milk|gluten,lactose|-|2.5|H
crepes|wheat,eggs,milk|gluten,lactose|veg,halal|1|B
paella|shellfish|-|-|5|H
gazpacho|-|histamine|vegan,veg,halal|1.5|E,B,L
patatas-bravas|-|histamine|vegan,veg,halal|1.2|B
churros|wheat,eggs|gluten|veg,halal|1.2|B
sushi|fish,soy|histamine|-|5|H
ramen|wheat,eggs,soy|gluten,histamine|-|4|H
tempura|wheat,shellfish,eggs|gluten|halal|4|-
miso-soup|soy,fish|histamine|halal|1|E,B,L
peking-duck|wheat,soy|gluten|halal|7|H
jiaozi|wheat,soy,sesame|gluten|-|2|-
kung-pao-chicken|peanuts,soy|gluten,histamine|halal|3|H,L
fried-rice|eggs,soy|-|halal|1.5|B
biryani|milk|lactose|halal|3|H
masala-dosa|-|-|vegan,veg,halal|1|B,E
palak-paneer|milk|lactose|veg,halal|2|H,E,L
samosa|wheat|gluten|vegan,veg,halal|1|B
moroccan-couscous|wheat|gluten|halal|3|E
pastilla|wheat,eggs,treenuts,milk|gluten,lactose|halal|4|-
harira|wheat|gluten|halal|1.5|B,E,H
rfissa|wheat|gluten|halal|4|H
ful-medames|-|-|vegan,veg,halal|0.8|B,E,H
molokhia|-|-|halal|3|E,L
taameya|sesame|-|vegan,veg,halal|0.8|B,H
fatta|wheat,milk|gluten,lactose|halal|3|H
egusi-soup|fish|-|halal|3|H,L
pounded-yam|-|-|vegan,veg,halal|1|B
suya|peanuts|-|halal|4|H,L
akara|-|-|vegan,veg,halal|0.8|B,H
barbecue-ribs|-|histamine|-|5|H,L
mac-and-cheese|wheat,milk|gluten,lactose|veg,halal|2|-
clam-chowder|shellfish,milk,wheat|lactose,gluten|-|4|H
apple-pie|wheat,milk|gluten,lactose,fructose|veg,halal|1.5|-
mole-poblano|peanuts,treenuts,sesame,wheat|gluten,caffeine|halal|4|H
pozole|-|histamine|-|3|H,E
tamales|-|-|halal|2|B
chiles-en-nogada|treenuts,milk,eggs,wheat|lactose,gluten|-|5|-
tourtiere|wheat|gluten|-|3|H
montreal-smoked-meat-sandwich|wheat|gluten,histamine|halal|4|H
butter-tarts|wheat,eggs,milk|gluten,lactose,fructose|veg,halal|1.2|-
bannock|wheat|gluten|vegan,veg,halal|0.6|B
feijoada|-|histamine|-|3|H
moqueca|fish,shellfish|-|halal|5|H,L,E
acaraje|shellfish|-|halal|2.5|B,H
brazilian-churrasco|-|-|halal|6|H,L
asado|-|-|halal|6|H,L
empanadas|wheat,eggs|gluten|halal|2|-
milanesa|wheat,eggs|gluten|halal|3|H
locro|-|-|-|2|B,E,H
lomo-saltado|soy,wheat|gluten|halal|4|H
aji-de-gallina|milk,wheat,treenuts|lactose,gluten|halal|3|H
causa-limena|eggs,fish|histamine|halal|3|-
anticuchos|-|histamine|halal|3|H,L
australian-meat-pie|wheat|gluten|halal|2.5|-
barramundi|fish|-|halal|6|H,L,E
damper|wheat|gluten|vegan,veg,halal|0.6|B
chicken-parmigiana|wheat,eggs,milk|gluten,lactose,histamine|halal|3.5|H
hangi|-|-|halal|5|H
nz-meat-pie|wheat|gluten|halal|2.5|-
fish-and-chips|fish,wheat|gluten|halal|3.5|H
hokey-pokey-ice-cream|milk,eggs|lactose,fructose|veg,halal|1.5|-
lovo|fish|-|halal|5|H,L
palusami|-|-|vegan,veg,halal|1.5|E,L
rourou|-|-|vegan,veg,halal|1|E,B,L
cassava-cake|milk,eggs|lactose|veg,halal|1|B
"""#

    static let drafts = #"""
boeuf-bourguignon|180|6|1.2 kg:beef chuck, cubed~m; 150 g:smoked bacon lardons~m; 750 ml:red Burgundy wine~x; 3:carrots~p; 2:onions~p; 3 cloves:garlic~p; 2 tbsp:plain flour~g; 2 tbsp:tomato paste~x; 250 g:mushrooms~p; 1:bouquet garni (thyme, bay, parsley)~p; 2 tbsp:butter~d; :salt and pepper~x|Brown the bacon, then sear the beef in batches and set aside. // Soften the onions and carrots in the same pot, stir in the flour and tomato paste, then pour in the wine and add the herbs. // Return the meat, cover and braise in a 160 °C oven for 2½–3 hours. // Sauté the mushrooms in butter and stir them in for the last 20 minutes.
coq-au-vin|90|4|1.6 kg:chicken, jointed~m; 150 g:smoked bacon lardons~m; 500 ml:red wine~x; 200 g:small onions~p; 250 g:mushrooms~p; 2 cloves:garlic~p; 2 tbsp:plain flour~g; 1:bouquet garni~p; 2 tbsp:butter~d; :salt and pepper~x|Brown the bacon, then the seasoned chicken pieces; set aside. // Fry the onions, mushrooms and garlic, stir in the flour and add the wine and herbs. // Return the chicken and simmer gently for about 45 minutes until tender. // Reduce the sauce slightly and serve hot.
quiche-lorraine|65|6|1:shortcrust pastry case (about 250 g)~g; 200 g:smoked bacon lardons~m; 3:eggs~d; 250 ml:double cream~d; 100 ml:milk~d; 80 g:grated Gruyère~d; :nutmeg, salt and pepper~x|Blind-bake the pastry case for 12 minutes at 190 °C. // Fry the lardons until golden and scatter them in the case with the cheese. // Whisk the eggs, cream, milk and nutmeg, pour over and bake 30–35 minutes until just set.
crepes|30|4|250 g:plain flour~g; 3:eggs~d; 500 ml:milk~d; 2 tbsp:melted butter~d; 1 tbsp:sugar~x; 1 pinch:salt~x|Whisk the flour, eggs, milk, butter, sugar and salt into a smooth thin batter and rest 15 minutes. // Heat a lightly buttered pan and pour in a thin layer of batter, tilting to coat. // Cook about 1 minute per side and fill with sugar, lemon or jam.
paella|60|4|400 g:short-grain paella rice~g; 400 g:chicken thighs~m; 200 g:prawns~m; 150 g:squid or mussels~m; 1:red pepper~p; 2:tomatoes, grated~p; 1.2 l:fish or chicken stock~x; 1 pinch:saffron~x; 4 tbsp:olive oil~x; 3 cloves:garlic~p; 1 tsp:smoked paprika~x|Brown the chicken in olive oil in a wide pan, then add the pepper, garlic and tomatoes and cook down. // Stir in the paprika and rice, then pour in the hot stock with the saffron. // Simmer without stirring for 15 minutes, nestle in the seafood and cook 5 more minutes. // Rest 5 minutes before serving.
gazpacho|15|4|1 kg:ripe tomatoes~p; 1:cucumber~p; 1:green pepper~p; 1 clove:garlic~p; 4 tbsp:olive oil~x; 2 tbsp:sherry vinegar~x; 1 slice:stale bread~g; :salt~x|Chop the vegetables and soak the bread briefly in water. // Blend everything with the oil and vinegar until very smooth, then season. // Chill at least 2 hours and serve cold with a drizzle of olive oil.
patatas-bravas|45|4|800 g:potatoes~p; 4 tbsp:olive oil~x; 1 tsp:smoked paprika~x; 1 tsp:hot paprika~x; 2 tbsp:tomato paste~x; 1 clove:garlic~p; 1 tbsp:vinegar~x; :salt~x|Cut the potatoes into chunks and roast or fry in olive oil until golden and crisp. // Simmer the garlic, paprikas, tomato paste, vinegar and a little water into a thick spicy sauce. // Spoon the sauce over the hot potatoes and serve.
churros|35|4|250 ml:water~x; 125 g:plain flour~g; 1 tbsp:sugar~x; 1 pinch:salt~x; 1:egg~d; 500 ml:oil for frying~x; 100 g:dark chocolate~x; 150 ml:milk~d|Boil the water with sugar and salt, add the flour and beat to a smooth dough; cool slightly and beat in the egg. // Pipe strips into hot oil and fry until golden, then drain and roll in sugar. // Melt the chocolate with the milk for dipping.
sushi|60|4|300 g:sushi rice~g; 400 ml:water~x; 3 tbsp:rice vinegar~x; 1 tbsp:sugar~x; 4 sheets:nori~x; 200 g:sushi-grade fish~m; 1:cucumber~p; :soy sauce and wasabi~x|Rinse and cook the rice, then season it with the vinegar, sugar and a pinch of salt and cool. // Spread rice on nori, add strips of fish and cucumber, then roll tightly with a mat. // Slice with a wet knife and serve with soy sauce and wasabi.
ramen|45|2|200 g:ramen noodles~g; 750 ml:chicken or pork broth~x; 2 tbsp:soy sauce~x; 1 tbsp:miso paste~x; 2:eggs~d; 150 g:sliced pork belly~m; 2:spring onions~p; 1 sheet:nori~x|Simmer the broth with the soy sauce and miso. // Soft-boil the eggs for 6½ minutes, peel and halve them; sear the pork slices. // Cook the noodles, divide into bowls, ladle over the broth and top with pork, egg, spring onion and nori.
tempura|35|4|200 g:large prawns~m; 1:sweet potato~p; 1:courgette~p; 150 g:plain flour~g; 1:egg~d; 200 ml:ice-cold sparkling water~x; 500 ml:oil for frying~x; :soy dipping sauce~x|Pat the prawns and sliced vegetables dry. // Lightly mix the flour, egg and ice-cold water — leave it lumpy. // Dip and fry in 180 °C oil in small batches until pale golden, then drain and serve at once with dipping sauce.
miso-soup|15|4|1 l:water~x; 2 tsp:dashi granules~x; 3 tbsp:miso paste~x; 200 g:silken tofu, cubed~x; 2:spring onions~p; 1 tbsp:dried wakame~x|Heat the water with the dashi. // Add the tofu and wakame and warm through. // Take off the heat, dissolve the miso in a ladleful of broth and stir in; finish with spring onion. Do not boil.
peking-duck|240|4|1:whole duck (about 2 kg)~m; 2 tbsp:honey~x; 2 tbsp:soy sauce~x; 1 tbsp:rice vinegar~x; 12:thin pancakes~g; 1:cucumber~p; 4:spring onions~p; 4 tbsp:hoisin sauce~x|Scald the duck with boiling water, dry it and brush with the honey, soy and vinegar; air-dry in the fridge overnight if possible. // Roast at 180 °C for about 1 hour 45 minutes until the skin is deep brown and crisp. // Slice the skin and meat and serve with pancakes, cucumber, spring onion and hoisin.
jiaozi|75|4|300 g:plain flour~g; 150 ml:warm water~x; 300 g:minced pork~m; 200 g:Chinese cabbage~p; 2 tbsp:soy sauce~x; 1 tbsp:sesame oil~x; 1 tbsp:grated ginger~p|Knead the flour and water into a smooth dough and rest 30 minutes. // Mix the pork, finely chopped salted cabbage, soy sauce, sesame oil and ginger. // Roll small rounds, fill, fold and pleat, then boil 6–7 minutes or pan-fry then steam.
kung-pao-chicken|30|3|500 g:chicken breast or thigh, diced~m; 60 g:roasted peanuts~x; 8:dried chillies~x; 3 tbsp:soy sauce~x; 1 tbsp:rice vinegar~x; 1 tbsp:sugar~x; 3 cloves:garlic~p; 1 tbsp:grated ginger~p; 1 tsp:cornflour~g; 2 tbsp:oil~x|Marinate the chicken with half the soy sauce and the cornflour. // Stir-fry the chillies, garlic and ginger briefly, then add the chicken and cook through. // Add the remaining soy, vinegar and sugar, toss with the peanuts and serve with rice.
fried-rice|20|2|300 g:cooked cold rice~g; 2:eggs~d; 100 g:peas and diced carrot~p; 2:spring onions~p; 2 tbsp:soy sauce~x; 2 tbsp:oil~x|Scramble the eggs in hot oil and set aside. // Stir-fry the vegetables, then add the cold rice and fry until it starts to crisp. // Return the eggs, add the soy sauce and spring onion and toss.
biryani|90|4|400 g:basmati rice~g; 600 g:chicken or lamb pieces~m; 200 g:plain yogurt~d; 2:onions, sliced~p; 2 tbsp:ginger-garlic paste~x; 2 tsp:garam masala~x; 1 pinch:saffron~x; 3 tbsp:ghee or oil~d; 1 handful:mint and coriander~p|Marinate the meat in yogurt, ginger-garlic paste and spices for at least 1 hour. // Fry the onions until deep golden; par-boil the rice with whole spices. // Layer meat, rice, fried onions, herbs and saffron milk in a heavy pot, seal and cook on low heat for 35–40 minutes.
masala-dosa|40|4|200 g:rice~g; 100 g:urad dal~g; 500 g:potatoes~p; 1:onion~p; 1 tsp:mustard seeds~x; 1 tsp:turmeric~x; 2:green chillies~p; 2 tbsp:oil~x|Soak the rice and dal, grind to a batter and ferment overnight. // Make the filling: pop mustard seeds, fry onion and chilli, add turmeric and mashed boiled potato. // Spread the batter thin on a hot griddle, cook until crisp, fill and fold.
palak-paneer|35|3|500 g:fresh spinach~p; 250 g:paneer, cubed~d; 1:onion~p; 2:tomatoes~p; 2 cloves:garlic~p; 1 tsp:grated ginger~p; 1 tsp:garam masala~x; 50 ml:cream~d; 2 tbsp:oil~x|Blanch the spinach and blend to a purée. // Fry the onion, garlic and ginger, add chopped tomatoes and spices, and cook down. // Stir in the spinach and cream, add the paneer and simmer 5 minutes.
samosa|60|8|250 g:plain flour~g; 4 tbsp:oil~x; 500 g:potatoes~p; 100 g:peas~p; 1 tsp:cumin seeds~x; 1 tsp:garam masala~x; 1:green chilli~p; 500 ml:oil for frying~x|Make a firm dough from the flour, oil, salt and water; rest 30 minutes. // Cook the diced potatoes and peas with the cumin, chilli and garam masala for the filling. // Shape cones from the dough, fill, seal and deep-fry on medium heat until golden.
moroccan-couscous|60|6|500 g:couscous~g; 800 g:lamb or chicken pieces~m; 2:onions~p; 3:carrots~p; 2:courgettes~p; 1 can:chickpeas~g; 1 tsp:ras el hanout~x; 2 tbsp:olive oil~x; 1.2 l:water~x|Brown the meat with the onions and spices, add the water and carrots and simmer for 40 minutes. // Add the courgettes and chickpeas for the last 15 minutes. // Steam the couscous with a little oil and butter and serve topped with the stew.
pastilla|90|6|500 g:chicken thighs~m; 1:onion~p; 200 g:blanched almonds~x; 3:eggs~d; 8 sheets:warqa or filo pastry~g; 1 tsp:cinnamon~x; 1 tsp:ginger~x; 60 g:butter~d; 2 tbsp:icing sugar~x|Simmer the chicken with the onion and spices until tender, shred it and reduce the sauce, stirring in the eggs to set. // Fry the almonds and mix with sugar and cinnamon. // Layer buttered pastry with the chicken and almond fillings, fold into a parcel and bake at 200 °C until golden; dust with sugar and cinnamon.
harira|75|6|200 g:lamb or beef, diced~m; 100 g:brown lentils~g; 1 can:chickpeas~g; 800 g:tomatoes~p; 1:onion~p; 2 stalks:celery~p; 50 g:vermicelli~g; 1 tsp:turmeric~x; 1 handful:coriander and parsley~p; 1 tbsp:flour~g|Fry the meat and onion with the spices, add celery, tomatoes and lentils and simmer for 45 minutes. // Add the chickpeas and vermicelli. // Whisk the flour with water, stir in to thicken and finish with fresh herbs and lemon.
rfissa|120|6|1:whole chicken, jointed~m; 3:onions~p; 200 g:lentils~g; 1 tbsp:ground fenugreek~x; 1 tsp:ras el hanout~x; 6:msemen or flatbreads~g; 1 tsp:turmeric~x; 3 tbsp:olive oil~x|Simmer the chicken with the onions, lentils and spices until tender. // Shred the flatbread into small pieces and arrange on a large dish. // Pour over the broth, top with the chicken and lentils.
ful-medames|20|3|400 g:cooked fava beans (canned)~g; 2 cloves:garlic~p; 3 tbsp:olive oil~x; 1:lemon~p; 1 tsp:cumin~x; 1:tomato~p; 1 handful:parsley~p|Warm the beans gently with a splash of their liquid and mash lightly. // Stir in crushed garlic, lemon juice, cumin and half the olive oil. // Serve topped with chopped tomato, parsley and the remaining oil with warm bread.
molokhia|45|4|500 g:fresh or frozen molokhia leaves~p; 1 l:chicken stock~x; 6 cloves:garlic~p; 1 tbsp:ground coriander~x; 3 tbsp:ghee or oil~d; 500 g:chicken pieces~m|Simmer the chicken in the stock until cooked; keep the broth. // Add the finely chopped molokhia to the hot broth and cook briefly — do not boil hard. // Fry the garlic with the coriander until golden and stir it in. Serve with rice.
taameya|40|4|300 g:dried fava beans, soaked overnight~g; 1 bunch:parsley and coriander~p; 1:onion~p; 3 cloves:garlic~p; 1 tsp:cumin~x; 2 tbsp:sesame seeds~x; 500 ml:oil for frying~x|Grind the drained beans with the herbs, onion, garlic and spices into a coarse paste. // Shape into small patties and coat with sesame seeds. // Deep-fry until deep golden and serve in pita with salad.
fatta|60|4|500 g:lamb or beef chunks~m; 3:pita breads~g; 300 g:rice~g; 3 cloves:garlic~p; 2 tbsp:vinegar~x; 2 tbsp:tomato paste~x; 200 g:yogurt~d; 2 tbsp:ghee~d|Simmer the meat until tender; keep the broth. // Toast the pita pieces until crisp and cook the rice with the broth. // Layer pita, rice and meat, pour over a garlic-vinegar tomato sauce and top with yogurt.
egusi-soup|60|4|200 g:ground egusi seeds~x; 500 g:beef or goat meat~m; 100 g:smoked fish~m; 300 g:spinach or bitter leaf~p; 2:tomatoes~p; 1:onion~p; 100 ml:palm oil~x; 1:scotch bonnet~p|Boil the meat with onion and seasoning until tender. // Fry the blended tomato, onion and pepper in palm oil, then stir in the egusi paste and cook into curds. // Add the meat, fish and stock, simmer 20 minutes, then stir in the greens.
pounded-yam|40|4|1 kg:yam~p; 500 ml:water~x|Peel and cut the yam and boil in water until very soft. // Pound or beat in a mortar or food processor until completely smooth, stretchy and lump-free. // Shape into balls and serve with egusi or another soup.
suya|40|4|600 g:beef sirloin, thinly sliced~m; 100 g:roasted peanuts, ground~x; 2 tsp:paprika~x; 1 tsp:ground ginger~x; 1 tsp:garlic powder~x; 1 tsp:cayenne~x; 2 tbsp:oil~x; 1:onion~p; 2:tomatoes~p|Mix the ground peanuts with the spices to make the suya rub. // Coat the beef strips with oil and the rub, thread onto skewers and rest 30 minutes. // Grill on high heat for 8–10 minutes, turning, and serve with raw onion and tomato.
akara|30|4|300 g:black-eyed peas, soaked and peeled~g; 1:onion~p; 1:scotch bonnet~p; 1 tsp:salt~x; 500 ml:oil for frying~x|Blend the peeled peas with the onion and pepper and a little water into a thick fluffy paste. // Whisk the batter well to add air. // Drop spoonfuls into hot oil and fry until deep golden.
barbecue-ribs|240|4|2 kg:pork spare ribs~m; 3 tbsp:brown sugar~x; 2 tbsp:smoked paprika~x; 1 tbsp:garlic powder~x; 1 tbsp:salt~x; 250 ml:barbecue sauce~x|Remove the membrane from the ribs and rub with the sugar, paprika, garlic powder and salt. // Wrap in foil and bake at 140 °C for about 2½–3 hours until tender. // Unwrap, brush with sauce and finish under the grill or on the barbecue for 10 minutes.
mac-and-cheese|40|4|350 g:macaroni~g; 50 g:butter~d; 50 g:plain flour~g; 600 ml:milk~d; 250 g:grated cheddar~d; 1 tsp:mustard~x; 50 g:breadcrumbs~g|Cook the macaroni until just tender and drain. // Make a roux of butter and flour, whisk in the milk to a smooth sauce, then melt in most of the cheese and mustard. // Combine with the pasta, top with cheese and breadcrumbs and bake at 200 °C for 20 minutes.
clam-chowder|45|4|500 g:clams, cleaned (or 2 cans)~m; 3:potatoes, diced~p; 100 g:smoked bacon~m; 1:onion~p; 2 stalks:celery~p; 500 ml:milk~d; 200 ml:cream~d; 2 tbsp:flour~g|Fry the bacon, onion and celery, stir in the flour and add the potatoes and clam juice. // Simmer until the potatoes are tender, then add the milk and cream. // Add the clams, heat gently 5 minutes and season.
apple-pie|90|8|2:shortcrust pastry sheets (about 500 g)~g; 1 kg:apples~p; 100 g:sugar~x; 1 tsp:cinnamon~x; 2 tbsp:flour~g; 30 g:butter~d; 1:egg for glazing~d|Line a pie dish with half the pastry. // Toss sliced apples with sugar, cinnamon and flour, pile in and dot with butter. // Cover with the remaining pastry, seal, brush with egg and bake at 200 °C for 45 minutes.
mole-poblano|150|6|6:dried chillies (ancho, mulato, pasilla)~x; 50 g:almonds~x; 30 g:sesame seeds~x; 40 g:peanuts~x; 40 g:raisins~x; 40 g:dark chocolate~x; 800 g:chicken pieces~m; 2:tomatoes~p; 1:onion~p; 1 slice:stale bread~g|Toast and soak the chillies. // Fry the nuts, seeds, raisins, bread, onion and tomato and blend with the chillies and stock into a smooth paste. // Fry the paste, add the chocolate and spices and simmer for about 45 minutes. // Poach or roast the chicken and serve covered in the mole.
pozole|150|6|1 kg:pork shoulder~m; 800 g:hominy (canned)~g; 4 dried guajillo chillies~x; 1:onion~p; 4 cloves:garlic~p; 1:cabbage, shredded~p; 6:radishes~p; 2:limes~p; :oregano~x|Simmer the pork with half the onion and the garlic until tender, about 2 hours. // Soak and blend the chillies into a sauce and add with the hominy to the broth; simmer 30 minutes. // Serve with cabbage, radish, onion, oregano and lime.
tamales|120|8|500 g:masa harina~g; 150 g:lard or vegetable fat~x; 600 ml:stock~x; 1 tsp:baking powder~x; 400 g:cooked shredded chicken or pork~m; 200 ml:red or green salsa~x; 20:dried corn husks~x|Soak the husks in warm water. // Whip the fat, then beat in the masa, baking powder and stock into a soft dough. // Spread dough on a husk, add filling and salsa, fold and steam for about 1 hour.
chiles-en-nogada|120|6|6:poblano chillies~p; 400 g:minced pork or beef~m; 100 g:walnuts~x; 200 ml:cream~d; 100 g:fresh cheese~d; 1:pomegranate~p; 1:apple and 1 peach, diced~p; 2:eggs~d; 2 tbsp:flour~g|Roast, peel and slit the chillies. // Cook the meat with the diced fruit and spices for the filling and stuff the chillies. // Coat in beaten egg and flour and fry; blend the walnuts, cream and cheese into a sauce. // Cover with the walnut sauce and scatter with pomegranate seeds.
tourtiere|120|8|2:shortcrust pastry sheets (about 500 g)~g; 500 g:minced pork~m; 250 g:minced beef~m; 1:onion~p; 2:potatoes, diced~p; 1 tsp:cloves and cinnamon~x; 200 ml:stock~x|Cook the meat with onion, potato, spices and stock until thick; cool. // Line a pie dish with pastry, add the filling and cover with a pastry lid. // Brush with egg and bake at 200 °C for about 40 minutes until golden.
montreal-smoked-meat-sandwich|30|2|400 g:smoked brisket, sliced~m; 4 slices:rye bread~g; 2 tbsp:yellow mustard~x; 2:dill pickles~p|Steam or warm the brisket until hot and tender. // Pile it generously onto mustard-spread rye bread. // Serve with a dill pickle on the side.
butter-tarts|45|12|1:shortcrust pastry sheet (about 250 g)~g; 115 g:butter~d; 150 g:brown sugar~x; 120 ml:maple or corn syrup~x; 1:egg~d; 60 g:raisins~x|Cut pastry rounds and press into a muffin tin. // Whisk the melted butter, sugar, syrup and egg and add the raisins. // Fill the cases two-thirds full and bake at 190 °C for 15–18 minutes.
bannock|30|4|300 g:plain flour~g; 2 tsp:baking powder~x; 1 tsp:salt~x; 3 tbsp:oil or lard~x; 200 ml:water~x|Mix the dry ingredients and rub in the fat. // Stir in the water to form a soft dough and pat into a disc about 2 cm thick. // Pan-fry on low heat 8–10 minutes per side or bake at 200 °C for 20 minutes.
feijoada|180|6|500 g:black beans, soaked~g; 300 g:pork ribs or shoulder~m; 200 g:smoked sausage~m; 200 g:smoked bacon~m; 2:onions~p; 4 cloves:garlic~p; 2:bay leaves~x; 1:orange~p|Simmer the beans with the meats and bay leaves for 2 hours until everything is tender. // Fry the onion and garlic and stir a ladle of beans into them, mashing to thicken. // Serve with rice, collard greens and orange slices.
moqueca|40|4|600 g:firm white fish~m; 300 g:prawns~m; 400 ml:coconut milk~x; 1:onion~p; 1:red pepper~p; 2:tomatoes~p; 3 tbsp:palm (dendê) oil~x; 1 handful:coriander~p; 1:lime~p|Marinate the fish with lime, salt and garlic. // Layer sliced onion, pepper and tomato in a pot, add the fish and prawns and pour over the coconut milk and palm oil. // Simmer gently for 15–20 minutes and finish with coriander.
acaraje|60|6|400 g:black-eyed peas, soaked and peeled~g; 1:onion~p; 500 ml:palm oil for frying~x; 150 g:dried shrimp~m; 100 g:vatapá or spicy paste~x|Blend the peas with the onion and salt to a thick paste and beat until fluffy. // Shape into ovals and deep-fry in hot palm oil until golden. // Split open and fill with the shrimp and spicy paste.
brazilian-churrasco|60|6|1.5 kg:beef picanha or sirloin~m; 4 tbsp:coarse salt~x; 6:chicken hearts or thighs~m; 6:sausages~m|Cut the beef into thick steaks, season generously with coarse salt and thread onto skewers. // Grill over charcoal or high heat, turning, until browned outside and cooked to taste. // Slice thinly at the table and serve with farofa and vinaigrette.
asado|180|6|1.5 kg:beef short ribs or flank~m; 6:sausages~m; 4 tbsp:coarse salt~x; 1:lemon~p; :chimichurri sauce~x|Light the coals and let them burn down to even embers. // Season the meat with coarse salt and cook slowly on the grill, turning occasionally. // Rest and slice, then serve with chimichurri.
empanadas|60|10|500 g:plain flour~g; 100 g:butter or lard~d; 400 g:minced beef~m; 2:onions~p; 2:eggs, hard-boiled~d; 50 g:olives~p; 1 tsp:cumin and paprika~x|Make a dough with the flour, fat, salt and warm water; rest 30 minutes. // Cook the beef and onions with the spices; cool and fold in chopped egg and olives. // Cut rounds, fill, fold and crimp, brush with egg and bake at 200 °C until golden.
milanesa|35|4|600 g:beef or chicken cutlets~m; 2:eggs~d; 150 g:breadcrumbs~g; 2 cloves:garlic~p; 4 tbsp:oil for frying~x; 1:lemon~p|Pound the cutlets thin and season with salt and garlic. // Dip in beaten egg, then breadcrumbs. // Fry until golden on both sides and serve with lemon.
locro|150|6|500 g:white corn (dried, soaked)~g; 250 g:white beans, soaked~g; 300 g:pumpkin, cubed~p; 300 g:beef short rib~m; 150 g:chorizo~m; 2:onions~p; 1 tsp:paprika~x|Simmer the corn and beans with the beef for about 1½ hours. // Add the pumpkin and chorizo and cook until everything is soft and thick. // Top with a fried onion and paprika sauce.
lomo-saltado|30|3|500 g:beef sirloin strips~m; 2:red onions, cut in wedges~p; 2:tomatoes, cut in wedges~p; 3 tbsp:soy sauce~x; 1 tbsp:vinegar~x; 300 g:fries~p; 300 g:rice~g|Marinate the beef strips with soy and vinegar. // Stir-fry in a very hot pan, then add the onions and tomatoes briefly. // Toss with the fries and serve with rice.
aji-de-gallina|60|4|500 g:chicken breast~m; 4 slices:bread, soaked in milk~g; 150 ml:evaporated milk~d; 3 tbsp:aji amarillo paste~x; 50 g:walnuts~x; 1:onion~p; 4:potatoes, boiled~p; 2:eggs~d|Poach and shred the chicken. // Blend the soaked bread, milk, aji paste and walnuts into a creamy sauce and fry with the onion. // Stir in the chicken and serve over potatoes with egg.
causa-limena|45|6|1 kg:yellow potatoes~p; 4 tbsp:aji amarillo paste~x; 3:limes~p; 250 g:cooked chicken or tuna~m; 2:avocados~p; 4 tbsp:mayonnaise~x; 2:eggs, hard-boiled~d|Boil and mash the potatoes with aji paste, lime juice, oil and salt into a smooth dough. // Mix the chicken or tuna with mayonnaise. // Layer potato, filling and avocado in a mould, chill and serve with egg.
anticuchos|45|4|600 g:beef heart or sirloin, cubed~m; 3 tbsp:aji panca paste~x; 4 tbsp:vinegar~x; 3 cloves:garlic~p; 1 tsp:cumin~x; 4:potatoes, boiled~p; 2:corn cobs~p|Marinate the meat in aji panca, vinegar, garlic and cumin for at least 3 hours. // Thread onto skewers. // Grill over high heat for a few minutes per side, brushing with marinade, and serve with potato and corn.
australian-meat-pie|90|6|2:shortcrust pastry sheets (about 500 g)~g; 1 sheet:puff pastry for the lid~g; 500 g:minced beef~m; 1:onion~p; 2 tbsp:flour~g; 300 ml:beef stock~x; 1 tbsp:Worcestershire sauce~x|Brown the mince and onion, stir in the flour, stock and Worcestershire sauce and simmer until thick; cool. // Line individual tins with shortcrust, fill and top with puff pastry. // Brush with egg and bake at 200 °C for 25 minutes. Serve with tomato sauce.
barramundi|25|2|2:barramundi fillets~m; 2 tbsp:butter~d; 1:lemon~p; 1 handful:parsley~p; 200 g:green beans~p; :salt and pepper~x|Season the fillets and sear skin-side down in a hot pan for 4 minutes. // Flip, add butter and cook 2 minutes more, then squeeze over the lemon. // Serve with steamed green beans and parsley.
damper|40|6|400 g:self-raising flour~g; 1 tsp:salt~x; 50 g:butter~d; 250 ml:milk or water~x|Rub the butter into the flour and salt. // Stir in the liquid to a soft dough and shape into a round. // Slash the top and bake at 200 °C for 30–35 minutes until it sounds hollow when tapped.
chicken-parmigiana|45|4|4:chicken breast fillets, flattened~m; 2:eggs~d; 100 g:breadcrumbs~g; 300 ml:tomato sauce~x; 200 g:mozzarella~d; 50 g:parmesan~d; 4 tbsp:oil~x|Dip the chicken in egg and breadcrumbs and fry until golden. // Place in a dish, cover with tomato sauce and cheeses. // Bake at 200 °C for 15 minutes until the cheese bubbles.
hangi|240|6|1.5 kg:chicken pieces or lamb~m; 500 g:potatoes~p; 500 g:kumara (sweet potato)~p; 400 g:pumpkin~p; 1 head:cabbage~p; 6 sheets:foil~x|Season the meat and place in foil-lined baskets; add the vegetables. // Cook in a pit oven with hot stones, or wrap tightly and cook in a covered oven at 180 °C. // Cook 3–4 hours until smoky and tender.
nz-meat-pie|90|6|2:shortcrust pastry sheets (about 500 g)~g; 1 sheet:puff pastry~g; 500 g:minced beef~m; 1:onion~p; 2 tbsp:flour~g; 300 ml:beef stock~x; 100 g:cheese (optional)~d|Cook the mince and onion with the flour and stock into a thick filling; cool. // Line the tins with shortcrust, add the filling and cover with puff pastry. // Brush with egg and bake at 200 °C for 25–30 minutes.
fish-and-chips|45|4|4:white fish fillets (cod or hoki)~m; 1 kg:potatoes~p; 150 g:plain flour~g; 200 ml:cold beer or sparkling water~x; 1 l:oil for frying~x; 1:lemon~p|Cut the potatoes into thick chips and fry until pale, then fry again until crisp. // Whisk the flour and cold liquid into a batter, coat the fish and fry at 180 °C for 5–6 minutes. // Serve with lemon, salt and vinegar.
hokey-pokey-ice-cream|30|6|500 ml:double cream~d; 250 ml:milk~d; 100 g:sugar~x; 4:egg yolks~d; 100 g:honeycomb toffee, crushed~x|Heat the milk and cream, whisk the yolks and sugar and combine into a custard; chill. // Churn in an ice-cream machine or freeze, stirring every hour. // Fold in the crushed honeycomb at the end.
lovo|180|6|1 kg:fish or pork~m; 500 g:cassava~p; 500 g:taro (dalo)~p; 6:palusami leaf parcels or spinach~p; 400 ml:coconut cream~x; 10:banana leaves or foil~x|Wrap seasoned fish or meat and root vegetables in banana leaves or foil. // Cook in an earth oven over hot stones, or in a sealed oven at 180 °C. // Cook for about 2–3 hours and serve with coconut cream.
palusami|60|4|8:taro leaves or spinach~p; 400 ml:coconut cream~x; 1:onion, chopped~p; 1:lime~p; :salt~x|Mix the coconut cream with onion and salt. // Wrap spoonfuls in taro leaves or spinach, forming tight parcels. // Wrap in foil and bake at 180 °C for about 45 minutes.
rourou|40|4|500 g:taro leaves or spinach~p; 400 ml:coconut milk~x; 1:onion~p; 1:lime~p; :salt~x|Wash the leaves and simmer with the sliced onion until soft. // Add the coconut milk and cook gently for 15–20 minutes. // Season with salt and a squeeze of lime.
cassava-cake|75|10|900 g:grated cassava~p; 400 ml:coconut milk~x; 400 ml:condensed milk~d; 3:eggs~d; 50 g:butter~d; 100 g:sugar~x|Mix the grated cassava with the coconut milk, condensed milk, eggs, melted butter and sugar. // Pour into a greased pan and bake at 180 °C for about 1 hour. // Cool before slicing.
"""#
}

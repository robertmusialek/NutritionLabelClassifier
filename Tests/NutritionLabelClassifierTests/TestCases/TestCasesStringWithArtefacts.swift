import XCTest

@testable import NutritionLabelClassifier

let testCasesStringsWithArtefacts: [(input: String, artefacts: [NutrientArtefact])] = [
    ("Vitamin B6", [aa(.vitaminB6)]),

    ("ENERGY", [aa(.energy)]),
    ("Energy", [aa(.energy)]),
    ("Energy 116kcal 96kcal", [aa(.energy), av(116, .kcal), av(96, .kcal)]),

    ("CARBOHYDRATE", [aa(.carbohydrate)]),
    ("Carbohydrate", [aa(.carbohydrate)]),
    ("Carbohydrate 4", [aa(.carbohydrate), av(4)]),
    ("Total Carbohydrate 16g", [aa(.carbohydrate), av(16, .g)]),
    ("0% Total Carbohydrate 20g 7%", [av(0, .p), aa(.carbohydrate), av(20, .g), av(7, .p)]),
    ("0% Total Carbohydrate 19g 6%", [av(0, .p), aa(.carbohydrate), av(19, .g), av(6, .p)]),
    ("0% Total Carbohydrates 9g %", [av(0, .p), aa(.carbohydrate), av(9, .g)]),

    ("SUGARS", [aa(.sugar)]),
    ("sugars", [aa(.sugar)]),
    ("of which sugars", [aa(.sugar)]),
    ("- SUGARS", [aa(.sugar)]),
    ("Sugars 19g", [aa(.sugar), av(19, .g)]),
    ("Sugars 9g", [aa(.sugar), av(9, .g)]),
    ("Total Sugars 14g", [aa(.sugar), av(14, .g)]),
    ("2% Sugars 18g", [av(2, .p), aa(.sugar), av(18, .g)]),

    //TODO: Handle edge case of "Includes" by reading value before it}
    ("Includes 12g Added Sugars 24%", [ap(.includes), av(12, .g), aa(.addedSugar), av(24, .p)]),

    ("Dietary Fibre", [aa(.dietaryFibre)]),

    ("FAT, TOTAL", [aa(.fat)]),
    ("Fat", [aa(.fat)]),

    ("Saturated Fat", [aa(.saturatedFat)]),
    ("-SATURATED", [aa(.saturatedFat)]),
    ("Caring Suer: Go7z (170g) Saturated Fat", [av(170, .g), aa(.saturatedFat)]),
    ("Saturated Fat 13g", [aa(.saturatedFat), av(13, .g)]),
    ("Saturated Fat 0g", [aa(.saturatedFat), av(0, .g)]),

    ("Trans Fat", [aa(.transFat)]),
    ("Trans Fat 0g", [aa(.transFat), av(0, .g)]),

    ("Cholesterol", [aa(.cholesterol)]),
    ("Cholesterol 0mg", [aa(.cholesterol), av(0, .mg)]),
    ("Cholesterol 5mg", [aa(.cholesterol), av(5, .mg)]),

    ("PROTEIN", [aa(.protein)]),
    ("Protein", [aa(.protein)]),
    ("Protein 2g", [aa(.protein), av(2, .g)]),
    ("Protein 4", [aa(.protein), av(4)]),
    ("0% Protein 14g", [av(0, .p), aa(.protein), av(14, .g)]),
    ("2% Protein 12g", [av(2, .p), aa(.protein), av(12, .g)]),
    ("3% Protein 15g", [av(3, .p), aa(.protein), av(15, .g)]),
    ("0% Protein 23g", [av(0, .p), aa(.protein), av(23, .g)]),

    ("SALT", [aa(.salt)]),
    ("Salt", [aa(.salt)]),
    ("Salt Equivalent", [aa(.salt)]),
    ("(equivalent as salt)", [aa(.salt)]),

    ("SODIUM", [aa(.sodium)]),
    ("Sodium", [aa(.sodium)]),
    ("Sodium 65mg", [aa(.sodium), av(65, .mg)]),
    ("Sodium 25mq", [aa(.sodium), av(25, .mg)]),
    ("Sodium 50mg", [aa(.sodium), av(50, .mg)]),
    ("Sodium 105mg", [aa(.sodium), av(105, .mg)]),
    ("of which sodium", [aa(.sodium)]),

    ("CALCIUM (20% RI* PER 100g))", [aa(.calcium), av(20, .p), ap(.referenceIntakePer), av(100, .g)]),
    ("CALCIUM", [aa(.calcium)]),
    ("Calcium", [aa(.calcium)]),
    ("Calcium (% RDA) 128 mg (16%)", [aa(.calcium), av(128, .mg), av(16, .p)]),
    
    //MARK: - Multiples
    ("I Container (150g) Saturated Fat 0g 0% Total Carbohydrate 15g 5%",
     [av(150, .g), aa(.saturatedFat), av(0, .g), av(0, .p), aa(.carbohydrate), av(15, .g), av(5, .p)]),
    
    ("Calories from Fat 0 Cholesterol <5mg 1% Sugars 7g",
     [av(0), aa(.cholesterol), av(5, .mg), av(1, .p), aa(.sugar), av(7, .g)]),
    
    ("Vitamin A 0% Vitamin C 2% Calcium 20%",
     [aa(.vitaminA), av(0, .p), aa(.vitaminC), av(2, .p), aa(.calcium), av(20, .p)]),

    ("Vit. D 0mcg 0% Calcium 58mg 4%",
     [aa(.vitaminD), av(0, .mcg), av(0, .p), aa(.calcium), av(58, .mg), av(4, .p)]),

    ("based on a 2,000 calorie diet. Vit A 0% • Vit C 0% • Calcium 15% • Iron 0% • Vit D 15%",
     [av(2000, .kcal), aa(.vitaminA), av(0, .p), aa(.vitaminC), av(0, .p), aa(.calcium), av(15, .p), aa(.iron), av(0, .p), aa(.vitaminD), av(15, .p)]),

    ("based on a 2,000 calorie diet. Vitamin A 4% - Vitamin C 0% - Calcium 15% - Iron 0% - Vitamin D 15%",
     [av(2000, .kcal), aa(.vitaminA), av(4, .p), aa(.vitaminC), av(0, .p), aa(.calcium), av(15, .p), aa(.iron), av(0, .p), aa(.vitaminD), av(15, .p)]),

    ("2000 calorie diet. Vitamin A 0% PRONE ALONE PASTEREONOGAYMAKLIMEANOACINECTRESSERENIOPLIS.LAUSRSLISONER Vitamin C 0% Calcium 30% • Iron",
     [av(2000, .kcal), aa(.vitaminA), av(0, .p), aa(.vitaminC), av(0, .p), aa(.calcium), av(30, .p), aa(.iron)]),

    //MARK: - Ingredients (Ignore if needed)
    ("At least 2% lower in saturated fat compared to regular yoghurt",
     [av(2, .p), aa(.saturatedFat)]),

    ("SUGAR, YELLOW/BOX HONEY (4.2%), THICKENER", [aa(.sugar), av(4.2, .p)]),

    ("CARAMELISED SUGAR, MILK MINERALS LIVE", [aa(.sugar)]),
    ("INGREDIENTS: Milk Chocolate [sugar,", [aa(.sugar)]),
    ("(coconut, palm kernel), sugar, chocolate,", [aa(.sugar)]),
    ("INGREDIENTS: CULTURED GRADE A NON FAT MILK, WATER, STRAWBERRY, SUGAR, FRUCTOSE, CONTAINS LESS THAN 1%", [av(1, .p)]),

    ("(FOR COLOR), SODIUM CITRATE, POTASSIUM SORBATE (TO MAINTAIN FRESHNESS), MALIC ACID, VITAMIN D3.",
     [av(3)]),

    ("STEVIA LEAF EXTRACT, SEA SALT, VITAMIN D3, SODIUM CITRATE.", [av(3), aa(.sodium)]),

    ("INGREDIENTS: Low Fat Yogurt, Sugar, Raspherry Purée (2.5%)", [av(2.5, .p)]),
    ("yogurt cultures), Strawberry (10%), Sugar AbarAy", [av(10, .p), aa(.sugar)]),
    ("regulators citric acid, calcium citrate), Flavouring,", [aa(.calcium)]),

    //MARK: - Unsorted
    ("Calories", [aa(.energy)]),
    ("Dietary Fiber 0g", [aa(.dietaryFibre), av(0, .g)]),
    ("Iron 0mg 0%", [aa(.iron), av(0, .mg), av(0, .p)]),
    ("Potas. 60mg 2%", [aa(.potassium), av(60, .mg), av(2, .p)]),
    ("of which saturates", [aa(.saturatedFat)]),
    ("FIBRE", [aa(.dietaryFibre)]),
    ("VITAMIN D (68% RI* PER 100g)", [aa(.vitaminD), av(68, .p), ap(.referenceIntakePer), av(100, .g)]),
    ("131 Cal", [av(131, .kcal)]),
    ("196Cal", [av(196, .kcal)]),
    ("Dietary Fiber less than 1g", [aa(.dietaryFibre), av(1, .g)]),
    ("(calories 140", [aa(.energy), av(140, .kcal)]),
    ("200 calorie diel.", [av(200, .kcal)]),
    ("Iron 0%", [aa(.iron), av(0, .p)]),
    ("Calories 120", [aa(.energy), av(120, .kcal)]),
    ("of which saturates", [aa(.saturatedFat)]),
    ("Fibre", [aa(.dietaryFibre)]),
    ("0% Dietary Fiber 0g", [av(0, .p), aa(.dietaryFibre), av(0, .g)]),
    ("mono-unsaturates", [aa(.monounsaturatedFat)]),
    ("polyunsaturates", [aa(.polyunsaturatedFat)]),
    ("Calories 140", [aa(.energy), av(140, .kcal)]),

    ("<0.1 g", [av(0.1, .g)]),
    ("120 mg", [av(120, .mg)]),
    ("3.4 ug", [av(3.4, .mcg)]),
    ("0.19", [av(0.19)]),
    ("2", [av(2)]),
    ("0%", [av(0, .p)]),
    ("11%", [av(11, .p)]),
    ("0mg", [av(0, .mg)]),
    ("0.1 g", [av(0.1, .g)]),
    ("133kcal", [av(133, .kcal)]),
    ("2000 kcal", [av(2000, .kcal)]),
    ("5.9g 30%", [av(5.9, .g), av(30, .p)]),
    ("0.5g", [av(0.5, .g)]),
    ("746kJ", [av(746, .kj)]),
    ("210 mg", [av(210, .mg)]),

    /// Edge cases
    ("0.1 c", [av(0.1, .g)]), /// For when vision misreads a 'g' as 'c'

//    ("168ma", [av()]),
//    ("trace", [av()]),
//    ("497k1", [av()]),

//    Servings per package:
//    Serving size: 130g (1 cup)
//    Per serving
//    Servings per package: 8 Serving Size: 125g (1 cup)
//    Per Serving
//    Per 100 g
//    PER 100g 74g (2 tubes)
//    SERVINGS PER TUB:
//    SERVING SIZE: 150g
//    AVE. QTY. %DI* PER AVE. QTY.
//    PER SERVE
//    SERVE PER 100g
//    trition Amount Per Serving %Daily Value* Amount Per Serving
//    (sarins Per Container 1
//    about 40 servings per container
//    Serving size 3 balls (36g)
//    Amount per serving
//    Calories per gram:
//    Amount/Serving
//    %DV* Amount/Serving
//    Serving Size
//    Nutrition Facts Amount/Serving %DV* Amount/Serving
//    Serving Size
//    Servings per package: 8 Serving size: 125g (1 cup)
//    PER TUB: 1
//    SERVINGS E
//    SERVING SE
//    AVE. QTY. %DI* PER
//    PER SERVE
//    INFORMATION Per 120g Per 100g
//    Nutritional Values (Typical) Per 100 g Per serving (125 g)
//    Nutrition Amount Per Serving %Daily Value* Amount Per Serving 50al) Veter)
//    Serving Size:
//    Servings Per Container
//    Per 1 pot

//    13% cream
//    5 Dadson Road
//    1. 22000 369941
//    el 6288 6421
//    150 9001 QMS & 22000 Certined
//    8 888026 252014
//    2te with
//    40, 180 67 852
//    deceit S 00 s
//    AVERAGE ADULT DIET OF 8700kJ.
//    % AFRALA3008. FLAVOURED YOGHURT. KEEP REFRIGERATED BELOW 4°C.
//    from at least 99%
//    1 Divere based on a
//    Lund Parma G/AS7, 4980 FARMA, INC., 669 COUNTY ROAD 25. NEW BERLIN, MY ACAD
//    a serving of food contributes to a daily diet. 2000
//    Keep cool (60-68°F) and dry.
//    (%RDA) (27.9%) (23.3%) 2
//    4.0 0
//    (100g) contains RI* average adult
//    SIZE:
//    Vitamins & minerals
//
//    1 Container (150g)
//    Coz (225g)
//    ⅕ of a pot

]

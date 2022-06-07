import XCTest

@testable import NutritionLabelClassifier

let testCasesStringsWithFeatures: [(input: String, features: [Feature])] = [
    ("Energy 116kcal 96kcal", [f(.energy, 116, .kcal), f(.energy, 96, .kcal)]),
    ("ENERGY", []),
    ("Energy", []),

    ("CARBOHYDRATE", []),
    ("Carbohydrate", []),
    ("Carbohydrate 4", [f(.carbohydrate, 4)]),
    ("Total Carbohydrate 16g", [f(.carbohydrate, 16, .g)]),
    ("0% Total Carbohydrate 20g 7%", [f(.carbohydrate, 20, .g)]),
    ("0% Total Carbohydrate 19g 6%", [f(.carbohydrate, 19, .g)]),
    ("0% Total Carbohydrates 9g %", [f(.carbohydrate, 9, .g)]),

    ("SUGARS", []),
    ("sugars", []),
    ("of which sugars", []),
    ("- SUGARS", []),
    ("Sugars 19g", [f(.sugar, 19, .g)]),
    ("Sugars 9g", [f(.sugar, 9, .g)]),
    ("Total Sugars 14g", [f(.sugar, 14, .g)]),
    ("2% Sugars 18g", [f(.sugar, 18, .g)]),

    //TODO: Handle edge case of "Includes" by reading value before it}
    ("Includes 12g Added Sugars 24%", [f(.sugar, 12, .g)]),

    ("Dietary Fibre", []),

    ("FAT, TOTAL", []),
    ("Fat", []),

    ("Saturated Fat", []),
    ("-SATURATED", []),
    ("Caring Suer: Go7z (170g) Saturated Fat", []),
    ("Saturated Fat 13g", [f(.saturatedFat, 13, .g)]),
    ("Saturated Fat 0g", [f(.saturatedFat, 0, .g)]),

    ("Trans Fat", []),
    ("Trans Fat 0g", [f(.transFat, 0, .g)]),

    ("Cholesterol", []),
    ("Cholesterol 0mg", [f(.cholesterol, 0, .mg)]),
    ("Cholesterol 5mg", [f(.cholesterol, 5, .mg)]),

    ("PROTEIN", []),
    ("Protein", []),
    ("Protein 2g", [f(.protein, 2, .g)]),
    ("Protein 4", [f(.protein, 4)]),
    ("0% Protein 14g", [f(.protein, 14, .g)]),
    ("2% Protein 12g", [f(.protein, 12, .g)]),
    ("3% Protein 15g", [f(.protein, 15, .g)]),
    ("0% Protein 23g", [f(.protein, 23, .g)]),

    ("SALT", []),
    ("Salt", []),
    ("Salt Equivalent", []),
    ("(equivalent as salt)", []),

    ("SODIUM", []),
    ("Sodium", []),
    ("Sodium 65mg", [f(.sodium, 65, .mg)]),
    ("Sodium 25mq", [f(.sodium, 25, .mg)]),
    ("Sodium 50mg", [f(.sodium, 50, .mg)]),
    ("Sodium 105mg", [f(.sodium, 105, .mg)]),
    ("of which sodium", []),

    ("CALCIUM (20% RI* PER 100g))", [f(.calcium, 20, .p)]),
    ("CALCIUM", []),
    ("Calcium", []),
    ("Calcium (% RDA) 128 mg (16%)", [f(.calcium, 128, .mg)]),

    ("Vitamin B6 0%", [f(.vitaminB6, 0, .p)]),
    
    //MARK: - Multiples
    ("I Container (150g) Saturated Fat 0g 0% Total Carbohydrate 15g 5%",
     [f(.saturatedFat, 0, .g), f(.carbohydrate, 15, .g)]),

    ("Calories from Fat 0 Cholesterol <5mg 1% Sugars 7g",
     [f(.cholesterol, 5, .mg), f(.sugar, 7, .g)]),

    ("Vitamin A 0% Vitamin C 2% Calcium 20%",
     [f(.vitaminA, 0, .p), f(.vitaminC, 2, .p), f(.calcium, 20, .p)]),

    ("Vit. D 0mcg 0% Calcium 58mg 4%",
     [f(.vitaminD, 0, .mcg), f(.calcium, 58, .mg)]),

    ("based on a 2,000 calorie diet. Vit A 0% • Vit C 0% • Calcium 15% • Iron 0% • Vit D 15%",
     [f(.vitaminA, 0, .p), f(.vitaminC, 0, .p), f(.calcium, 15, .p), f(.iron, 0, .p), f(.vitaminD, 15, .p)]),

    ("based on a 2,000 calorie diet. Vitamin A 4% - Vitamin C 0% - Calcium 15% - Iron 0% - Vitamin D 15%",
     [f(.vitaminA, 4, .p), f(.vitaminC, 0, .p), f(.calcium, 15, .p), f(.iron, 0, .p), f(.vitaminD, 15, .p)]),

    ("2000 calorie diet. Vitamin A 0% PRONE ALONE PASTEREONOGAYMAKLIMEANOACINECTRESSERENIOPLIS.LAUSRSLISONER Vitamin C 0% Calcium 30% • Iron",
     [f(.vitaminA, 0, .p), f(.vitaminC, 0, .p), f(.calcium, 30, .p)]),

    //MARK: - Ingredients (Ignore if needed)
    ("At least 2% lower in saturated fat compared to regular yoghurt", []),
    ("SUGAR, YELLOW/BOX HONEY (4.2%), THICKENER", []),

    ("CARAMELISED SUGAR, MILK MINERALS LIVE", []),
    ("INGREDIENTS: Milk Chocolate [sugar,", []),
    ("(coconut, palm kernel), sugar, chocolate,", []),
    ("INGREDIENTS: CULTURED GRADE A NON FAT MILK, WATER, STRAWBERRY, SUGAR, FRUCTOSE, CONTAINS LESS THAN 1%", []),
    ("(FOR COLOR), SODIUM CITRATE, POTASSIUM SORBATE (TO MAINTAIN FRESHNESS), MALIC ACID, VITAMIN D3.", []),
    ("STEVIA LEAF EXTRACT, SEA SALT, VITAMIN D3, SODIUM CITRATE.", []),
    ("INGREDIENTS: Low Fat Yogurt, Sugar, Raspherry Purée (2.5%)", []),
    ("yogurt cultures), Strawberry (10%), Sugar AbarAy", []),
    ("regulators citric acid, calcium citrate), Flavouring,", []),

    //MARK: - Unsorted
    ("Calories", []),
    ("Dietary Fiber 0g", [f(.dietaryFibre, 0, .g)]),
    ("Iron 0mg 0%", [f(.iron, 0, .mg)]),
    ("Potas. 60mg 2%", [f(.potassium, 60, .mg)]),
    ("of which saturates", []),
    ("FIBRE", []),
    ("VITAMIN D (68% RI* PER 100g)", [f(.vitaminD, 68, .p)]),
    ("131 Cal", []),
    ("196Cal", []),
    ("Dietary Fiber less than 1g", [f(.dietaryFibre, 1, .g)]),
    ("(calories 140", [f(.energy, 140)]),
    ("200 calorie diel.", []),
    ("Iron 0%", [f(.iron, 0, .p)]),
    ("Calories 120", [f(.energy, 120)]),
    ("of which saturates", []),
    ("Fibre", []),
    ("0% Dietary Fiber 0g", [f(.dietaryFibre, 0, .g)]),
    ("mono-unsaturates", []),
    ("polyunsaturates", []),
    ("Calories 140", [f(.energy, 140)]),

    ("<0.1 g", []),
    ("120 mg", []),
    ("3.4 ug", []),
    ("0.19", []),
    ("2", []),
    ("0%", []),
    ("11%", []),
    ("0mg", []),
    ("0.1 g", []),
    ("133kcal", []),
    ("2000 kcal", []),
    ("5.9g 30%", []),
    ("0.5g", []),
    ("746kJ", []),
    ("210 mg", []),

//    ("168ma", [v()]),
//    ("trace", [v()]),
//    ("0.1 c", [v()]),
//    ("497k1", [v()]),

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

import XCTest

@testable import NutritionLabelClassifier

let testCasesValueAtStartOfString: [(input: String, value: Value?)] = [
    ("ENERGY", nil),
    ("CARBOHYDRATE", nil),
    ("of which sugars", nil),
    ("PROTEIN", nil),
    ("Salt Equivalent", nil),
    ("Calcium", nil),
    ("INGREDIENTS: Low Fat Yogurt, Sugar, Raspherry Purée (2.5%)", nil),
    ("yogurt cultures), Strawberry (10%), Sugar AbarAy", nil),
    ("regulators citric acid, calcium citrate), Flavouring,", nil),
    ("Saturated Fat 0g", nil),

    ("2000 calorie diet. Vitamin A 0% PRONE ALONE PASTEREONOGAYMAKLIMEANOACINECTRESSERENIOPLIS.LAUSRSLISONER Vitamin C 0% Calcium 30% • Iron", Value(amount: 2000, unit: .kcal)),

    ("0% Total Carbohydrate 20g 7%", Value(amount: 0, unit: .p)),
    ("0% Protein 14g", Value(amount: 0, unit: .p)),
    ("0% Total Carbohydrate 19g 6%", Value(amount: 0, unit: .p)),
    ("2% Sugars 18g", Value(amount: 2, unit: .p)),
    ("2% Protein 12g", Value(amount: 2, unit: .p)),
    ("3% Protein 15g", Value(amount: 3, unit: .p)),
    ("0% Total Carbohydrates 9g %", Value(amount: 0, unit: .p)),
    ("0% Protein 23g", Value(amount: 0, unit: .p)),
    
    ("0 Total Carbohydrate 20g 7%", Value(amount: 0)),
    ("25.6 Protein 14g", Value(amount: 25.6)),

    ("0:1g Total Carbohydrate 19g 6%", Value(amount: 0.1, unit: .g)),
    ("5:2 g Sugars 18g", Value(amount: 5.2, unit: .g)),

    ("200 mcg Protein 12g", Value(amount: 200, unit: .mcg)),
    ("20:5 mcg Protein 15g", Value(amount: 20.5, unit: .mcg)),

    ("0.01 kcal Total Carbohydrates 9g %", Value(amount: 0.01, unit: .kcal)),
    ("0:01 kcal Protein 23g", Value(amount: 0.01, unit: .kcal)),
]

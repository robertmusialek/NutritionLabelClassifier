import Foundation

@testable import NutritionLabelClassifier

let invalidAttributeTestCases: [Attribute: [String]] = [
    .fat: [
        "anufattured & Quality Tested by NOW FCWS.",
        "Saturatfrd Fat O",
        "Saturdted Fats 0,03",
        "satur￿ed Fat",
    ],
    .sugar: [
        "und Mandel-Torrone (10%). Zutaten: Zucker, Vollmilchpulver,"
    ]
]

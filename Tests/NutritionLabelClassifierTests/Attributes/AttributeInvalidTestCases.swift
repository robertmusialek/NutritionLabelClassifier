import Foundation

@testable import NutritionLabelClassifier

let invalidAttributeTestCases: [Attribute: [String]] = [
    .energy: [
        "ETheryl dadLemak l Energy from Fat",
        "Energi dari Lemak / Energy from Fat",
        "Energl daTI Lemak l Energy from Fat",
        "Energi dari Lemak/ Energy from Fat",
        "Energy from Fat",
        "Energy from Fat (kcal)",
    ],
    
    .fat: [
        "anufattured & Quality Tested by NOW FCWS.",
        "Saturatfrd Fat O",
        "Saturdted Fats 0,03",
        "satur￿ed Fat",
    ],
    
    .sugar: [
        "und Mandel-Torrone (10%). Zutaten: Zucker, Vollmilchpulver,"
    ],
    
    .vitaminE: [
        "Riboflavin (Vitamin E",
    ],

]

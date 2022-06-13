import XCTest
import SwiftSugar
import TabularData
import VisionSugar

@testable import NutritionLabelClassifier

final class TableClassifierTests: XCTestCase {
    
    var currentTestCaseId: UUID = defaultUUID
    
//    let SingledOutTestCase: UUID? = UUID(uuidString: "0748DBAE-1379-40CF-A29C-0D342F53E7E3")!
    let SingledOutTestCase: UUID? = nil
    
    func testTableClassifier() throws {
        
        try prepareTestCases()
        
        for id in testCaseIds {
            
            if let singledOutTestCase = SingledOutTestCase {
                guard id == singledOutTestCase else {
                    continue
                }
            }
            
            
            guard attributeExpectations.keys.contains(id.uuidString) else {
                continue
            }
            
            guard let array = arrayOfRecognizedTextsForTestCase(withId: id) else {
                XCTFail("Couldn't get array of recognized texts for Test Case \(id)")
                return
            }
            
            currentTestCaseId = id
            print("Checking: \(id)")
            
            let classifier = TableClassifier(arrayOfRecognizedTexts: array)
            let attributes = classifier.getAttributes()
            
            if attributes == attributeExpectations[id.uuidString] {
                print("🤖✅ \(id): \(attributes) as expected")
            } else {
                print("🤖❌ \(id)")
                print("🤖❌ Expected: \(attributeExpectations[id.uuidString]!)")
                print("🤖❌ Got back: \(attributes)")
                print("🤖❌ ----")
            }
            
            XCTAssertEqual(attributes, attributeExpectations[id.uuidString], m("Attributes"))
        }
    }
    
    func m(_ message: String) -> String {
        "\(message) (\(currentTestCaseId))"
    }
}

let attributeExpectations: [String: [Attribute]] = [
    "E84F7C80-50C4-4237-BAAD-BD5C1B958B84": [
        .energy, .protein, .fat, .saturatedFat, .carbohydrate, .sugar, .sodium, .calcium
    ],
    "00DC2D0A-2C55-4633-B5AE-DF2BA90C4249": [
        .energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt
    ],
    "3EDD65E5-6363-42E3-8358-21A520ED21CC": [
        .fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt, .sodium
    ],
    "2184C983-5761-4F8F-BE7A-E6771E963FFF": [
        .fat, .saturatedFat, .transFat, .cholesterol, .sodium, .salt, .carbohydrate, .dietaryFibre, .sugar, .addedSugar, .protein
    ],
    "364EDBD7-004B-4A97-83AA-F6404DE5EEB4": [
        .energy, .fat, .saturatedFat, .monounsaturatedFat, .polyunsaturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .solubleFibre, .insolubleFibre, .protein, .sodium, .iron, .magnesium, .zinc
    ],
    "15D5AD72-033E-4CA4-BA87-D6CB6193EC9B": [
        .energy, .protein, .carbohydrate, .sugar, .fat, .saturatedFat, .monounsaturatedFat, .polyunsaturatedFat, .transFat, .cholesterol, .dietaryFibre, .solubleFibre, .insolubleFibre, .sodium, .magnesium, .iron, .zinc
    ],
    "43F947A2-4E96-496B-884B-DF7C960F82FE": [
        .energy, .protein, .fat, .carbohydrate, .sugar, .dietaryFibre, .iron, .magnesium, .zinc, .folicAcid, .vitaminA, .vitaminB1, .vitaminB12
    ],
    "478883E6-2CA8-4C86-9A9F-A3FD71EA5BBE": [
        .energy, .fat, .saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat, .cholesterol, .sodium, .carbohydrate, .dietaryFibre, .sugar, .addedSugar, .protein, .vitaminD, .calcium, .iron, .potassium, .thiamin, .riboflavin, .niacin, .vitaminB6, .folate, .folicAcid, .vitaminB12
    ],
    "986EFEB4-069E-4091-805E-8C9A031611F3": [
        .energy, .protein, .fat, .saturatedFat, .transFat, .carbohydrate, .sugar, .sodium
    ],
    "B19E1AAD-F0A1-4F0E-B443-BF69894125E8": [
        .energy, .protein, .fat, .saturatedFat, .transFat, .carbohydrate, .sugar, .sodium
    ],
    "DD77C26D-4004-4071-B2B1-D228B258A893": [
        .energy, .protein, .fat, .saturatedFat, .transFat, .carbohydrate, .sugar, .sodium
    ],
    "81840F7C-B156-4A21-AE5B-A55531AA6B2D": [
        .energy, .protein, .fat, .saturatedFat, .transFat, .carbohydrate, .sugar, .sodium
    ],
    "2A79F2EC-9A9D-4CF0-B06A-8A634B7C61B1": [
        .energy, .fat, .saturatedFat, .carbohydrate, .sugar, .protein, .salt
    ],
    "DEB07FE7-3C3D-44E9-83AD-2234228A4F02": [
        .energy, .fat, .saturatedFat, .carbohydrate, .sugar, .protein, .salt
    ],
    "0748DBAE-1379-40CF-A29C-0D342F53E7E3": [
        .energy, .fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .sodium, .salt
    ],
    "826DB226-9FCD-4662-A1CD-5FD862493D55": [
        .energy, .fat, .saturatedFat, .transFat, . carbohydrate, .sugar, .protein, .sodium, .salt
    ],
]

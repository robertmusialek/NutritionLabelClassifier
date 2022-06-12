import XCTest
import SwiftSugar
import TabularData
import VisionSugar

@testable import NutritionLabelClassifier

final class TableClassifierTests: XCTestCase {

    var currentTestCaseId: UUID = defaultUUID

//    let SingledOutTestCase: UUID? = UUID(uuidString: "2184C983-5761-4F8F-BE7A-E6771E963FFF")!
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
            XCTAssertEqual(attributes, attributeExpectations[id.uuidString], m("Attributes"))
            
            if attributes == attributeExpectations[id.uuidString] {
                print("✅ \(attributes) was expected")
            } else {
                print("Expected: \(attributeExpectations[id.uuidString]!)")
                print("❌ Got: \(attributes)")
            }
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
    ]
]

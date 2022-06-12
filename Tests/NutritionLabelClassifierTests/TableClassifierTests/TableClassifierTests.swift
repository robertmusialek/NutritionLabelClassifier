import XCTest
import SwiftSugar
import TabularData
import VisionSugar

@testable import NutritionLabelClassifier

final class TableClassifierTests: XCTestCase {

    var currentTestCaseId: UUID = defaultUUID

    func testTableClassifier() throws {
        
        try prepareTestCases()
        
        for id in testCaseIds {
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
            
            print("✅ \(attributes) was expected")
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
    ]
]

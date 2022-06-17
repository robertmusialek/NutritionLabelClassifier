import XCTest

@testable import NutritionLabelClassifier

final class AttributeFatTests: XCTestCase {

    func _testAttributes() throws {
        
        for key in validAttributeTestCases.keys {
            guard let testCases = validAttributeTestCases[key] else {
                continue
            }
            for testCase in testCases {
                XCTAssertTrue(Attribute.detect(in: testCase).contains(key), "\(testCase) failed to be recognized as containing \(key.rawValue)")
            }
        }

        for key in invalidAttributeTestCases.keys {
            guard let testCases = invalidAttributeTestCases[key] else {
                continue
            }
            for testCase in testCases {
                XCTAssertFalse(Attribute.detect(in: testCase).contains(key), "\(testCase) incorrectly recognized as containing \(key.rawValue)")
            }
        }
    }
}


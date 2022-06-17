import XCTest

@testable import NutritionLabelClassifier

final class AttributeSugarTests: XCTestCase {

    func _testAttributeSugar() throws {
        for testCase in validCases {
            XCTAssertTrue(Attribute.detect(in: testCase).contains(.sugar), "\(testCase) failed to be recognized as containing sugar")
        }
        
        for testCase in invalidCases {
            XCTAssertFalse(Attribute.detect(in: testCase).contains(.sugar), "\(testCase) incorrectly recognized as containing sugar")
        }
    }
    
    let validCases = [
        "sugar"
    ]
    
    let invalidCases = [
        "und Mandel-Torrone (10%). Zutaten: Zucker, Vollmilchpulver,"
    ]
}


import XCTest
import SwiftSugar
import TabularData
import VisionSugar

@testable import NutritionLabelClassifier

final class TableClassifierTests: XCTestCase {
    
    var currentTestCaseId: UUID = defaultUUID
    
    func testTableClassifier() throws {
        
        try prepareTestCaseImages()
        
        var numberOfPassedTests = 0
        var numberOfFailedTests = 0
        
        for id in testCaseIds {
            
            if let singledOutTestCase = SingledOutTestCase {
                guard id == singledOutTestCase else {
                    continue
                }
            }
            
            guard attributeExpectations.keys.contains(id.uuidString) else {
                continue
            }
            
            guard let image = imageForTestCase(withId: id) else {
                XCTFail("Couldn't get image for Test Case \(id)")
                return
            }
            
            currentTestCaseId = id
            print("🔥 Testing: \(id)")
            
            let classifier = NutritionLabelClassifier(image: image, contentSize: image.size)
            classifier.onCompletion = {
                
                let tableClassifier = TableClassifier(visionResult: classifier.visionResult)
                let _ = tableClassifier.getObservations()
                
                let attributes = tableClassifier.attributeTextColumns.map {
                    $0.map { $0.map { $0.attribute } }
                }
                guard attributes == attributeExpectations[id.uuidString] else {
                    print("🤖❌ Attributes for: \(id)")
                    if let expectation = attributeExpectations[id.uuidString] {
                        if let expectation = expectation {
                            print("    🤖❌ Expected: \(expectation)")
                        }
                    }
                    if let attributes = attributes {
                        print("    🤖❌ Got back: \(attributes)")
                    }
                    numberOfFailedTests += 1
                    
                    XCTFail(self.m("Attributes didn't match"))
//                    XCTAssertEqual(attributes, attributeExpectations[id.uuidString], self.m("Attributes"))
                    return
                }
                
                //TODO: make this a variable on the struct itself
                let values = tableClassifier.extractedValues.map {
                    $0.valueTextColumnGroups.map { $0.map { $0.map { $0?.value } } }
                }

                guard values == valueExpectations[id.uuidString] else {
                    print("🤖❌ Values for: \(id)")
                    if let expectation = valueExpectations[id.uuidString] {
                        if let expectation = expectation {                            
                            print("    🤖❌ Expected: \(expectation.valuesGroupDescription)")
                        }
                    }
                    if let values = values {
                        print("    🤖❌ Got back: \(values.valuesGroupDescription)")
                    }
                    numberOfFailedTests += 1
                    
                    XCTFail(self.m("Values didn't match"))
//                    XCTAssertEqual(values, valueExpectations[id.uuidString], self.m("Values"))
                    return
                }
                
                print("🤖✅ \(id)")
                numberOfPassedTests += 1

            }
            
            classifier.classify()
        }
        
        print("🤖 Failed: \(numberOfFailedTests) tests")
        print("🤖 Passed: \(numberOfPassedTests) tests")
    }
    
    func m(_ message: String) -> String {
        "\(message) (\(currentTestCaseId))"
    }
}

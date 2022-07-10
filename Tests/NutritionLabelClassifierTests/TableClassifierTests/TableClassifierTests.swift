import XCTest
import SwiftSugar
import TabularData
import VisionSugar

@testable import NutritionLabelClassifier

final class TableClassifierTests: XCTestCase {
    
    var currentTestCaseId: UUID = defaultUUID
    var numberOfPassedTests = 0
    var numberOfFailedTests = 0
    
    func testTableClassifierAttributes() throws {
        
        guard !TestPassingTestCases else { return }
        
        try prepareTestCaseImages()
        
        for id in testCaseIds {
            
            if let singledOutTestCase = SingledOutTestCase {
                guard id == singledOutTestCase else { continue }
            }
            
            do {
                try testCaseWithId(id, attributesOnly: true)
                numberOfPassedTests += 1
            } catch {
                numberOfFailedTests += 1
            }
        }
        
        print("🤖 Failed: \(numberOfFailedTests) tests")
        print("🤖 Passed: \(numberOfPassedTests) tests")
    }

    func testTableClassifierValues() throws {
        guard TestPassingTestCases else { return }
        try prepareTestCaseImages()

        for idString in valueExpectations.keys {
            guard let id = UUID(uuidString: idString) else { continue }
            try testCaseWithId(id)
        }
    }
    
    //MARK: - Helpers
    
    func testCaseWithId(_ id: UUID, attributesOnly: Bool = false) throws {
        guard attributeExpectations.keys.contains(id.uuidString) else {
            XCTFail("Couldn't get attributeExpectations for Test Case \(id)")
            return
        }
        
        guard let image = imageForTestCase(withId: id) else {
            XCTFail("Couldn't get image for Test Case \(id)")
            return
        }
        
        currentTestCaseId = id
        print("🔥4️⃣ Testing: \(id)")
        
        let classifier = NutritionLabelClassifier(image: image, contentSize: image.size)
        classifier.getTableClassifier { classifier in
            guard let classifier = classifier else {
                return
            }
//            let classifier = TableClassifier(visionResult: classifier.visionResult)
            classifier.extractTable()
            
            let attributesPassed = self.testAttributes(classifier.attributes, forTestCase: id)
            
            let desc = classifier.grid?.desc
            
            let valuesPassed: Bool
            if attributesOnly {
                valuesPassed = true
            } else {
                valuesPassed = self.testValues(classifier.grid?.values, forTestCase: id)
            }

            if attributesPassed && valuesPassed {
                print("🤖✅ \(id)")
            }
        }
    }
    
    func testAttributes(_ extractedAttributes: ExtractedAttributes?, forTestCase id: UUID) -> Bool {
        let attributes = extractedAttributes?.attributes
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
            
            XCTFail(self.m("Attributes didn't match"))
            return false
        }
        return true
    }
    
    func testValues(_ values: [[[Value?]]]?, forTestCase id: UUID) -> Bool {
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
            
            XCTFail(self.m("Values didn't match"))
            return false
        }
        return true
    }
    
    func m(_ message: String) -> String {
        "\(message) (\(currentTestCaseId))"
    }
}

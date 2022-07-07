import XCTest
import SwiftSugar
import TabularData
import VisionSugar

@testable import NutritionLabelClassifier

final class NutritionLabelClassifierTests: XCTestCase {
    
    var currentTestCaseId: UUID = defaultUUID
    
    func _testClassifier() throws {
        
        try prepareTestCaseImages()
        
        for id in testCaseIds {

            if let singledOutTestCase = SingledOutTestCase {
                guard id == singledOutTestCase else { continue }
            }
            
            try testCaseWithId(id)
        }
    }

    //MARK: - Helpers
    
    func testCaseWithId(_ id: UUID) throws {
        
        currentTestCaseId = id
        print("🔥4️⃣ Testing: \(id)")
        
        guard let image = imageForTestCase(withId: id) else {
            XCTFail("Couldn't get image for Test Case \(id)")
            return
        }
        
        let classifier = NutritionLabelClassifier(image: image, contentSize: image.size)
        classifier.onCompletion = { output in
            guard let output = output else { return }
            print("🤖✅ Completed with: \(output.nutrients.rows.map { $0.attributeText.attribute }))")
            print("Let's go")
        }
        
        classifier.classify()
    }
    
    func m(_ message: String) -> String {
        "\(message) (\(currentTestCaseId))"
    }
}

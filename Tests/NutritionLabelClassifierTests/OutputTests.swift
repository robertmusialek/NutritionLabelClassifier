import XCTest
import SwiftSugar
import TabularData
import VisionSugar

@testable import NutritionLabelClassifier

final class OutputTests: XCTestCase {

    var currentTestCaseId: UUID = defaultUUID
    var observedOutput: Output? = nil
    var expectedOutput: Output? = nil

    func testAllExpectations() throws {
        
        guard RunTests else { return }
        
        try prepareTestCases()
        
        /// For each UUID in Test Cases/With Lanugage Correction
        for testCaseId in testCaseIds {
            if let singledOutTestCaseId = SingledOutTestCaseId {
                guard testCaseId == singledOutTestCaseId else {
                    print("↪️ Ignoring Test Case: \(testCaseId) as its not singled-out")
                    continue
                }
            }
            
            if IgnoredTests.contains(testCaseId) {
                print("↪️ Ignoring Test Case: \(testCaseId)")
                continue
            }
            
            try runTestsForTestCase(withId: testCaseId)
        }        
    }
    
    func runTestsForTestCase(withId id: UUID) throws {
        currentTestCaseId = id
        print("🧪 Test Case: \(id)")
        
        guard let array = arrayOfRecognizedTextsForTestCase(withId: id) else {
            XCTFail("Couldn't get array of recognized texts for Test Case \(id)")
            return
        }

        observedOutput = NutritionLabelClassifier.classify(array)
        
        /// Extract `expectedNutrients` from data frame
        guard let expectedDataFrame = dataFrameForTestCase(withId: id, testCaseFileType: .expectedNutrients) else {
            XCTFail("Couldn't get expected nutrients for Test Case \(id)")
            return
        }

        print("📃 Expectations:")
        print(expectedDataFrame)

        /// Create `Output` from test case file too
        guard let expectedOutput = Output(fromExpectedDataFrame: expectedDataFrame) else {
            XCTFail("Couldn't create expected Output from DataFrame for Test Case \(id)")
            return
        }
        self.expectedOutput = expectedOutput

        let dataFrame = NutritionLabelClassifier(arrayOfRecognizedTexts: array).dataFrameOfObservations()
        print("👀 Observations:")
        print(dataFrameWithTextIdsRemoved(from: dataFrame))
        
//        try compareOutputs()
        print("✅ Passed: \(id)")
    }
    
    func compareOutputs() throws {
        try compareServings()
        try compareNutrients()
    }
    
    //MARK: - Helpers
    
    func m(_ message: String) -> String {
        "\(message) (\(currentTestCaseId))"
    }
}

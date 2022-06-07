import XCTest
import SwiftSugar
import TabularData
import VisionSugar
import Zip

@testable import NutritionLabelClassifier

let RunTests = true
let RunLegacyTests = true

//let ClassifierTestCases = 18...18
let ClassifierTestCases = 1...23
let ClassifierTestCasesToIgnore: [Int] = []

let CurrentTestCase = UUID(uuidString: "4CF0CBA5-C746-4844-BF54-27A92C808280")!

let SingledOutTestCaseId: UUID? = nil
//let SingledOutTestCaseId: UUID? = CurrentTestCase
//let SingledOutTestCaseId: UUID? = UUID(uuidString: "6BAD0EB1-8BED-4DD9-8FD8-C9861A267A3D")

let IgnoredTests: [UUID] = []
//let IgnoredTests: [UUID] = [CurrentTestCase]
//let IgnoredTests: [UUID] = [UUID(uuidString: "0DEA4407-48DF-4A16-8488-0EB967CB13ED")!]

final class OutputTests: XCTestCase {

    var currentTestCaseId: UUID = defaultUUID
    var observedOutput: Output? = nil
    var expectedOutput: Output? = nil

    func testClassifierUsingZipFile() throws {
        guard RunTests else { return }
        print("🤖 Running Tests on Zip File")
        let filePath = Bundle.module.url(forResource: "NutritionClassifier-Test_Data", withExtension: "zip")!
        let testDataUrl = URL.documents.appendingPathComponent("Test Data", isDirectory: true)
        
        /// Remove directory and create it again
        try FileManager.default.removeItem(at: testDataUrl)
        try FileManager.default.createDirectory(at: testDataUrl, withIntermediateDirectories: true)

        /// Unzip Test Data contents
        try Zip.unzipFile(filePath, destination: testDataUrl, overwrite: true, password: nil)
        
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
        
        try compareOutputs()
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

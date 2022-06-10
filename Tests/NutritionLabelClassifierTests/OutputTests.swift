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

let CurrentTestCase = UUID(uuidString: "3EDD65E5-6363-42E3-8358-21A520ED21CC")!
//let CurrentTestCase = UUID(uuidString: "7648338E-8AC8-4C03-AAA1-AC8FC76E7368")!

let SingledOutTestCaseId: UUID? = nil
//let SingledOutTestCaseId: UUID? = CurrentTestCase
//let SingledOutTestCaseId: UUID? = UUID(uuidString: "6BAD0EB1-8BED-4DD9-8FD8-C9861A267A3D")

let FailingTestUUIDStrings = [
    "674347E4-7B53-4409-95AF-07FD0560ADBA",
    "03A07980-DDEC-41A6-8130-080F582FB5C3",
    "5FEDB3DF-4214-44EF-A390-3C5CB3C1DA14",
    "826DB226-9FCD-4662-A1CD-5FD862493D55",
    "DEB07FE7-3C3D-44E9-83AD-2234228A4F02",
    "DD77C26D-4004-4071-B2B1-D228B258A893",
    "81840F7C-B156-4A21-AE5B-A55531AA6B2D",
    "3EDD65E5-6363-42E3-8358-21A520ED21CC"
]

let FailingTests: [UUID] = FailingTestUUIDStrings.map { UUID(uuidString: $0)! }

//let IgnoredTests: [UUID] = []
let IgnoredTests: [UUID] = FailingTests + []

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

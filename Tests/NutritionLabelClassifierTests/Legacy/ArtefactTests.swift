import XCTest
import TabularData
import VisionSugar

@testable import NutritionLabelClassifier

final class ArtefactTests: XCTestCase {

    func testArtefacts() throws {
        guard SingledOutTestCaseId == nil else { return }
        testCasesStringsWithArtefacts.forEach {
            let dummyRecognizedText = RecognizedText(id: defaultUUID, rectString: "", boundingBoxString: "", candidates: [$0.input])
            XCTAssertEqual(dummyRecognizedText.getNutrientArtefacts(), $0.artefacts, "\($0.input)")
        }
    }

//    func testFeatures() throws {
//        testCasesStringsWithFeatures.forEach {
//            let dummyRecognizedText = RecognizedText(id: defaultUUID, rectString: "", boundingBoxString: "", candidates: [$0.input])
//            XCTAssertEqual(dummyRecognizedText.features, $0.features)
//        }
//    }
}

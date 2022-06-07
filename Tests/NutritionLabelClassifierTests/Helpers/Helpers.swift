import XCTest
import TabularData
import VisionSugar

@testable import NutritionLabelClassifier

let testCasesForColumnSpanningEnergy: [(input: String, kcal: [Double], kj: [Double])] = [
    ("Brennwert Energi 735 kJ (177 kcal) 412 kJ (99 kcal)", [177, 99], [735, 412]),
    ("384kJ/91kcal 284kJ/67 kcal", [91, 67], [384, 284]),
    ("94 kcal (395 kJ 75 kcal (315 kJ", [94, 75], [395, 315]),
    ("(117 kcal (491 kJ| 90 kcal (378 kJ)", [117, 90], [491, 378]),
    ("Energy 116kcal 96kcal", [116, 96], []),
    ("Energy 620kj 154 Kj", [], [620, 154]),
    ("113 kcal (475 kJ) 90 kcal (378 kJ)", [113, 90], [475, 378]),
]

let testCasesForColumnSpanningHeader: [(input: String, header1: HeaderString?, header2: HeaderString?)] = [
    ("PER 100g 74g (2 tubes)", .per100, .perServing(serving: "74g (2 tubes)")),
    ("Nutritional Values (Typical) Per 100 g Per serving (125 g)", .per100, .perServing(serving: "serving (125 g)"))
]

var testCaseIds: [UUID] {
    let url = URL.documents
        .appendingPathComponent("Test Data", isDirectory: true)
        .appendingPathComponent("Test Cases", isDirectory: true)
        .appendingPathComponent("With Language Correction", isDirectory: true)
    let files: [URL]
    do {
        files = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    } catch {
        print("Error getting Test Case Files: \(error)")
        files = []
    }
    return files.compactMap { UUID(uuidString: $0.lastPathComponent.replacingOccurrences(of: ".csv", with: "")) }
}

func arrayOfRecognizedTextsForTestCase(_ testCase: Int) -> [[RecognizedText]]? {
    guard let recognizedTexts = dataFrameForTestCase(testCase)?.recognizedTexts else {
        XCTFail("Couldn't read file for Test Case \(testCase)")
        return nil
    }

    guard let recognizedTextsWithoutLanugageCorrection = dataFrameForTestCase(testCase, testCaseFileType: .inputWithoutLanguageCorrection)?.recognizedTexts else {
        XCTFail("Couldn't read file for Test Case \(testCase) (Without Lanuage Correction)")
        return nil
    }

//    guard let recognizedTextsWithFastRecognition = dataFrameForTestCase(testCase, testCaseFileType: .inputWithFastRecognition)?.recognizedTexts else {
//        XCTFail("Couldn't read file for Test Case \(testCase) (With Fast Recognition)")
//        return nil
//    }

    return [recognizedTexts, recognizedTextsWithoutLanugageCorrection]
}

func arrayOfRecognizedTextsForTestCase(withId id: UUID) -> [[RecognizedText]]? {
    guard let withLC = dataFrameForTestCase(withId: id, testCaseFileType: .input)?.recognizedTexts else {
        XCTFail("Couldn't read file for Test Case \(id)")
        return nil
    }

    guard let withoutLC = dataFrameForTestCase(withId: id, testCaseFileType: .inputWithoutLanguageCorrection)?.recognizedTexts else {
        XCTFail("Couldn't read file for Test Case \(id)")
        return nil
    }

    guard let withFastRecognition = dataFrameForTestCase(withId: id, testCaseFileType: .inputWithFastRecognition)?.recognizedTexts else {
        XCTFail("Couldn't read file for Test Case \(id)")
        return nil
    }

    return [withLC, withoutLC, withFastRecognition]
}

func dataFrameWithTextIdsRemoved(from sourceDataFrame: DataFrame) -> DataFrame {
    var dataFrame = sourceDataFrame
    dataFrame.transformColumn("attribute") { (attributeText: AttributeText?) -> Attribute? in
        return attributeText?.attribute
    }
    dataFrame.transformColumn("value1") { (valueText: ValueText?) -> Value? in
        return valueText?.value
    }
    dataFrame.transformColumn("value2") { (valueText: ValueText?) -> Value? in
        return valueText?.value
    }
    dataFrame.transformColumn("double") { (doubleText: DoubleText?) -> Double? in
        return doubleText?.double
    }
    dataFrame.transformColumn("string") { (stringText: StringText?) -> String? in
        return stringText?.string
    }
    return dataFrame
}

func dataFrameForTestCase(withId id: UUID, testCaseFileType type: TestCaseFileType = .input) -> DataFrame? {
    let csvUrl = type.directoryUrl.appendingPathComponent("\(id).csv", isDirectory: false)
    do {
        return try DataFrame(contentsOfCSVFile: csvUrl, types: [.double:.double])
    } catch {
        print("Error reading CSV: \(error)")
        return nil
    }
}


func dataFrameForTestCase(_ testCase: Int, testCaseFileType: TestCaseFileType = .input) -> DataFrame? {
    guard let path = Bundle.module.path(forResource: "\(testCaseFileType.fileName(for: testCase))", ofType: "csv") else {
        XCTFail("Couldn't get path for \"\(testCaseFileType.fileName(for: testCase))\" for testCaseFileType: \(testCaseFileType.rawValue)")
        return nil
    }
    let url = URL(fileURLWithPath: path)
    do {
        return try DataFrame(
            contentsOfCSVFile: url,
            types: [.double:.double]
        )
    } catch {
        print("Error reading CSV: \(error)")
        return nil
    }
//    return DataFrame.read(from: url)
}

func f(_ attribute: Attribute, _ a: Double? = nil, _ u: NutritionUnit? = nil) -> Feature {
    let value: Value?
    if let amount = a {
        value = Value(amount: amount, unit: u)
    } else {
        value = nil
    }
    return Feature(attribute: attribute, value: value)
}

func p(_ preposition: Preposition) -> Preposition {
    preposition
}

func v(_ amount: Double, _ unit: NutritionUnit? = nil) -> Value {
    Value(amount: amount, unit: unit)
}

func a(_ attribute: Attribute) -> Attribute {
    attribute
}

func ap(_ preposition: Preposition) -> NutrientArtefact {
    NutrientArtefact(preposition: preposition, textId: defaultUUID)
}

func av(_ amount: Double, _ unit: NutritionUnit? = nil) -> NutrientArtefact {
    NutrientArtefact(value: Value(amount: amount, unit: unit), textId: defaultUUID)
}

func aa(_ attribute: Attribute) -> NutrientArtefact {
    NutrientArtefact(attribute: attribute, textId: defaultUUID)
}

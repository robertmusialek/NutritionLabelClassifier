import Foundation

enum TestCaseFileType: String {
    case input /// With Accurate Recognition and Language Correction
    case inputWithoutLanguageCorrection
    case inputWithFastRecognition
    case expectedNutrients
    case expectedFeatures
    
    func fileName(for testCase: Int) -> String {
        switch self {
        case .input:
            return "\(testCase)"
        case .inputWithoutLanguageCorrection:
            return "\(testCase)-without_language_correction"
        case .inputWithFastRecognition:
            return "\(testCase)-with_fast_recognition"
        case .expectedNutrients:
            return "\(testCase)-nutrients"
        case .expectedFeatures:
            return "\(testCase)-features"
        }
    }
    
    var directoryUrl: URL {
        let testDataUrl = URL.documents.appendingPathComponent("Test Data", isDirectory: true)
        let testCasesUrl = testDataUrl.appendingPathComponent("Test Cases", isDirectory: true)
        switch self {
        case .input:
            return testCasesUrl.appendingPathComponent("With Language Correction", isDirectory: true)
        case .inputWithoutLanguageCorrection:
            return testCasesUrl.appendingPathComponent("Without Language Correction", isDirectory: true)
        case .inputWithFastRecognition:
            return testCasesUrl.appendingPathComponent("With Fast Recognition", isDirectory: true)
        case .expectedNutrients:
            return testDataUrl.appendingPathComponent("Expectations", isDirectory: true)
        default:
            return URL.documents
        }
    }
}

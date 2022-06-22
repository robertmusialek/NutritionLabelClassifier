import Foundation
import VisionSugar
import TabularData
import UIKit

extension TableClassifier {
    
    func extractValueTextColumnGroups() -> ExtractedValues? {
        guard let extractedAttributes = self.extractedAttributes else { return nil }
        return ExtractedValues(visionResult: visionResult, extractedAttributes: extractedAttributes)
    }
}

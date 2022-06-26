import Foundation
import VisionSugar
import TabularData
import UIKit

extension TableClassifier {
    
    func extractValueTextColumnGroups() -> ExtractedValues? {
        guard let attributes = self.attributes else { return nil }
        return ExtractedValues(visionResult: visionResult, extractedAttributes: attributes)
    }
}

import Foundation
import VisionSugar
import TabularData
import UIKit

extension TableClassifier {
    
    func extractValueTextColumnGroups() -> ExtractedValues? {
        guard let _ = self.attributeTextColumns else { return nil }
        return ExtractedValues(visionResult: visionResult, attributeTextColumns: attributeTextColumns)
    }
}

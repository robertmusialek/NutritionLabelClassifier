import Foundation
import VisionSugar
import TabularData
import UIKit

extension TableClassifier {
    
    /// Returns an array of arrays of `AttributeText`s, with each array representing a column of attributes, in the order they appear on the label.
    func extractAttributeTextColumns() -> [[AttributeText]]? {
        let attributes = ExtractedAttributes(visionResult: visionResult)
        return attributes?.attributeTextColumns
    }
    
    //TODO-NEXT: Remove these if not needed
    var attributeTexts: [RecognizedText] {
        visionResult.arrayOfTexts.reduce([]) { $0 + $1.attributeTexts }
    }
    var inlineAttributeTexts: [RecognizedText] {
        visionResult.arrayOfTexts.reduce([]) { $0 + $1.inlineAttributeTexts }
    }
}

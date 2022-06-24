import SwiftUI
import VisionSugar

public struct AttributeText {
    public let attribute: Attribute
    public let text: RecognizedText
    public var allTexts: [RecognizedText] = []
    
    var allTextsRect: CGRect {
        guard let first = allTexts.first else { return .zero }
        var unionRect = first.rect
        for text in allTexts.dropFirst() {
            unionRect = unionRect.union(text.rect)
        }
        return unionRect
    }
    
    func yDistanceTo(valuesText: ValuesText) -> CGFloat {
        abs(valuesText.text.rect.midY - allTextsRect.midY)
    }
}

extension AttributeText: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(attribute)
        hasher.combine(text)
        hasher.combine(allTexts)
    }
}

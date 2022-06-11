import Foundation
import VisionSugar

extension Observation {
    init?(headerType: HeaderType, for attribute: Attribute, attributeText: RecognizedText? = nil, recognizedText: RecognizedText) {
        guard attribute == .headerType1 || attribute == .headerType2 else {
            return nil
        }
        
        self.init(
            attributeText: AttributeText(
                attribute: attribute,
                text: attributeText ?? recognizedText),
            stringText: StringText(
                string: headerType.rawValue,
                text: recognizedText,
                attributeText: attributeText ?? recognizedText)
        )
    }
    
    init?(double: Double, attribute: Attribute, attributeText: RecognizedText? = nil, recognizedText: RecognizedText) {
        guard attribute.expectsDouble else { return nil }
        self.init(
            attributeText: AttributeText(
                attribute: attribute,
                text: attributeText ?? recognizedText),
            doubleText: DoubleText(
                double: double,
                text: recognizedText,
                attributeText: attributeText ?? recognizedText))
    }
    
    init?(unit: NutritionUnit, attribute: Attribute, attributeText: RecognizedText? = nil, recognizedText: RecognizedText) {
        guard attribute.expectsNutritionUnit else { return nil }
        self.init(
            attributeText: AttributeText(
                attribute: attribute,
                text: attributeText ?? recognizedText),
            stringText: StringText(
                string: unit.description,
                text: recognizedText,
                attributeText: attributeText ?? recognizedText))
    }

    init?(string: String, attribute: Attribute, attributeText: RecognizedText? = nil, recognizedText: RecognizedText) {
        guard attribute.expectsString else { return nil }
        self.init(
            attributeText: AttributeText(
                attribute: attribute,
                text: attributeText ?? recognizedText),
            stringText: StringText(
                string: string,
                text: recognizedText,
                attributeText: attributeText ?? recognizedText))
    }
}

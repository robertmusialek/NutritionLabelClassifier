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
                textId: recognizedText.id,
                attributeTextId: attributeText?.id ?? recognizedText.id)
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
                textId: recognizedText.id,
                attributeTextId: attributeText?.id ?? recognizedText.id))
    }
    
    init?(unit: NutritionUnit, attribute: Attribute, attributeText: RecognizedText? = nil, recognizedText: RecognizedText) {
        guard attribute.expectsNutritionUnit else { return nil }
        self.init(
            attributeText: AttributeText(
                attribute: attribute,
                text: attributeText ?? recognizedText),
            stringText: StringText(
                string: unit.description,
                textId: recognizedText.id,
                attributeTextId: attributeText?.id ?? recognizedText.id))
    }

    init?(string: String, attribute: Attribute, attributeText: RecognizedText? = nil, recognizedText: RecognizedText) {
        guard attribute.expectsString else { return nil }
        self.init(
            attributeText: AttributeText(
                attribute: attribute,
                text: attributeText ?? recognizedText),
            stringText: StringText(
                string: string,
                textId: recognizedText.id,
                attributeTextId: attributeText?.id ?? recognizedText.id))
    }
}

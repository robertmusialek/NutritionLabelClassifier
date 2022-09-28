import Foundation
import VisionSugar

public struct Output {
    public let id = UUID()
    public let serving: Serving?
    public let nutrients: Nutrients
}

extension Output {
    //MARK: Serving
    public struct Serving {
        //TODO: Add attribute texts for these too
        public let amountText: DoubleText?
        public let unitText: UnitText?
        public let unitNameText: StringText?
        public let equivalentSize: EquivalentSize?

        public let perContainer: PerContainer?

        public struct EquivalentSize {
            public let amountText: DoubleText
            public let unitText: UnitText?
            public let unitNameText: StringText?
        }

        public struct PerContainer {
            public let amountText: DoubleText
            public let nameText: StringText?
        }
    }
    
    //MARK: Nutrients
    public struct Nutrients {
        public let headerText1: HeaderText?
        public let headerText2: HeaderText?
        
        public let rows: [Row]
        
        public struct Row {
            public let attributeText: AttributeText
            public let valueText1: ValueText?
            public let valueText2: ValueText?
        }
    }
}

//MARK: - Text-based Structs

public struct ValueText {
    public var value: Value
    public let text: RecognizedText
    public let attributeText: RecognizedText? = nil    
}

extension ValueText: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
        hasher.combine(text)
        hasher.combine(attributeText)
    }
}

extension ValueText: CustomStringConvertible {
    public var description: String {
        value.description
    }
}

public struct DoubleText {
    public let double: Double
    public let text: RecognizedText
    public let attributeText: RecognizedText
    
    public init(double: Double, text: RecognizedText, attributeText: RecognizedText) {
        self.double = double
        self.text = text
        self.attributeText = attributeText
    }
}

public struct UnitText {
    public let unit: NutritionUnit
    public let text: RecognizedText
    public let attributeText: RecognizedText
    
    public init(unit: NutritionUnit, text: RecognizedText, attributeText: RecognizedText) {
        self.unit = unit
        self.text = text
        self.attributeText = attributeText
    }
}

public struct StringText {
    public let string: String
    public let text: RecognizedText
    public let attributeText: RecognizedText
    
    public init(string: String, text: RecognizedText, attributeText: RecognizedText) {
        self.string = string
        self.text = text
        self.attributeText = attributeText
    }
}

public struct HeaderText {
    public let type: HeaderType
    public let text: RecognizedText
    public let attributeText: RecognizedText
    public let serving: Serving?
    
    public struct Serving {
        public let amount: Double?
        public let unit: NutritionUnit?
        public let unitName: String?
        public let equivalentSize: EquivalentSize?
        
        public struct EquivalentSize {
            public let amount: Double
            public let unit: NutritionUnit?
            public let unitName: String?
        }        
    }
}

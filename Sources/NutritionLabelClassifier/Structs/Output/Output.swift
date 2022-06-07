import Foundation

public struct Output {
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

public struct AttributeText {
    public let attribute: Attribute
    public let textId: UUID
}

public struct ValueText {
    public var value: Value
    public let textId: UUID
    public let attributeTextId: UUID? = nil
}

public struct DoubleText {
    public let double: Double
    public let textId: UUID
    public let attributeTextId: UUID
    
    public init(double: Double, textId: UUID, attributeTextId: UUID) {
        self.double = double
        self.textId = textId
        self.attributeTextId = attributeTextId
    }
}

public struct UnitText {
    public let unit: NutritionUnit
    public let textId: UUID
    public let attributeTextId: UUID
    
    public init(unit: NutritionUnit, textId: UUID, attributeTextId: UUID) {
        self.unit = unit
        self.textId = textId
        self.attributeTextId = attributeTextId
    }
}

public struct StringText {
    public let string: String
    public let textId: UUID
    public let attributeTextId: UUID
    
    public init(string: String, textId: UUID, attributeTextId: UUID) {
        self.string = string
        self.textId = textId
        self.attributeTextId = attributeTextId
    }
}

public struct HeaderText {
    public let type: HeaderType
    public let textId: UUID
    public let attributeTextId: UUID
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

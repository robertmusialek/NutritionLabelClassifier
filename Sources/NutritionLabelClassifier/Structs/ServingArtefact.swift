import Foundation

public struct ServingArtefact {
    let textId: UUID
    let attribute: Attribute?
    let double: Double?
    let string: String?
    let unit: NutritionUnit?
    
    init(attribute: Attribute, textId: UUID) {
        self.textId = textId
        self.attribute = attribute
        self.double = nil
        self.string = nil
        self.unit = nil
    }
    
    init(double: Double, textId: UUID) {
        self.textId = textId
        self.double = double
        self.attribute = nil
        self.string = nil
        self.unit = nil
    }
    
    init(string: String, textId: UUID) {
        self.textId = textId
        self.string = string
        self.double = nil
        self.attribute = nil
        self.unit = nil
    }
    
    init(unit: NutritionUnit, textId: UUID) {
        self.textId = textId
        self.unit = unit
        self.string = nil
        self.double = nil
        self.attribute = nil
    }
}

extension ServingArtefact: Equatable {
    public static func ==(lhs: ServingArtefact, rhs: ServingArtefact) -> Bool {
        lhs.textId == rhs.textId
        && lhs.attribute == rhs.attribute
        && lhs.double == rhs.double
        && lhs.string == rhs.string
        && lhs.unit == rhs.unit
    }
}

extension ServingArtefact: CustomStringConvertible {
    public var description: String {
        if let attribute = attribute {
            return ".\(attribute.rawValue)"
        }
        if let double = double {
            return "#\(double.clean)"
        }
        if let string = string {
            return "\(string)"
        }
        if let unit = unit {
            return ".\(unit.description)"
        }
        return "nil"
    }
}

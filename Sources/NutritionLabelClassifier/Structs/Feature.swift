import Foundation
import VisionSugar

public struct Feature {
    let attribute: Attribute
    let value: Value?
}

extension Feature: Identifiable {
    public var id: Int {
        hashValue
    }
}

extension Feature: Equatable {
    public static func ==(lhs: Feature, rhs: Feature) -> Bool {
        lhs.attribute == rhs.attribute
        && lhs.value == rhs.value
    }
}

extension Feature: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(attribute)
        hasher.combine(value)
    }
}

//MARK: - Refactor and remove these

extension RecognizedText {
    var isValueBasedAttribute: Bool {
        attribute?.isValueBased ?? false
    }

    var attribute: Attribute? {
        for classifierClass in Attribute.allCases {
            guard let regex = classifierClass.regex else { continue }
            if string.matchesRegex(regex) {
                return classifierClass
            }
        }
        return nil
    }
    
    var containsValue: Bool {
        string.matchesRegex(#"[0-9]+[.,]*[0-9]*[ ]*(mg|ug|g|kj|kcal)"#)
    }
    
    var containsPercentage: Bool {
        string.matchesRegex(#"[0-9]+[.,]*[0-9]*[ ]*%"#)
    }
}

import VisionSugar
import CoreGraphics

struct ValuesText {

    var values: [Value]
    let text: RecognizedText
    
    init?(_ text: RecognizedText) {
        var values = Value.detect(in: text.string)
        guard values.count > 0 else {
            return nil
        }        
        self.text = text
        
        /// Previously—if only value has a unit, pick that one and discard the rest
        if values.containingUnit.count == 1 {
            self.values = values.containingUnit
        } else {
            self.values = values
        }
        
        /// Remove all values with a percent
//        values.removeAll(where: { $0.unit == .p })
        
        /// If there are values with units—remove all that don't have any
//        if values.contains(where: { $0.unit != nil }) {
//            values.removeAll(where: { $0.unit == nil })
//        }
        
//        self.values = values
    }
    
    init(values: [Value], text: RecognizedText = defaultText) {
        self.values = values
        self.text = text
    }

    var containsValueWithEnergyUnit: Bool {
        values.containsValueWithEnergyUnit
    }
    
    var containsValueWithKjUnit: Bool {
        values.containsValueWithKjUnit
    }

    var containsValueWithKcalUnit: Bool {
        values.containsValueWithKcalUnit
    }

    var isSingularPercentValue: Bool {
        if values.count == 1, let first = values.first, first.unit == .p {
            return true
        }
        return false
    }
    
    var isSingularNutritionUnitValue: Bool {
        if values.count == 1, let first = values.first, let unit = first.unit, unit.isNutrientUnit {
            return true
        }
        return false
    }
}

extension NutritionUnit {
    var isNutrientUnit: Bool {
        switch self {
        case .mcg, .mg, .g:
            return true
        default:
            return false
        }
    }
}

extension ValuesText: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(values)
        hasher.combine(text)
    }
}

extension Array where Element == ValuesText {
    var containsValueWithEnergyUnit: Bool {
        contains(where: { $0.containsValueWithEnergyUnit })
    }
    
    var containsServingAttribute: Bool {
        contains(where: { $0.text.containsServingAttribute })
    }
    
    var kjValues: [ValuesText] {
        filter({ $0.containsValueWithKjUnit })
    }
    
    var kcalValues: [ValuesText] {
        filter({ $0.containsValueWithKcalUnit })
    }
    
    func closestValueText(to attributeText: AttributeText) -> ValuesText? {
        let sorted = self.sorted(by: {
            attributeText.yDistanceTo(valuesText: $0) < attributeText.yDistanceTo(valuesText: $1)
//            $0.text.rect.yDistanceToTopOf(text.rect) < $1.text.rect.yDistanceToTopOf(text.rect)
        })
        return sorted.first
    }
    
    var rect: CGRect {
        guard let first = self.first else { return .zero }
        var unionRect = first.text.rect
        for valuesText in self.dropFirst() {
            unionRect = unionRect.union(valuesText.text.rect)
        }
        return unionRect
//        reduce(.zero) {
//            $0.union($1.text.rect)
//        }
    }
}

extension CGRect {
    func yDistanceToTopOf(_ rect: CGRect) -> CGFloat {
        abs(midY - rect.minY)
    }
}

//extension CGPoint {
//    func distanceSquared(to: CGPoint) -> CGFloat {
//        (self.x - to.x) * (self.x - to.x) + (self.y - to.y) * (self.y - to.y)
//    }
//
//    func distance(to: CGPoint) -> CGFloat {
//        sqrt(CGPointDistanceSquared(from: from, to: to))
//    }
//}

import VisionSugar
import CoreGraphics

struct ValuesText {

    var values: [Value]
    let text: RecognizedText
    
    init?(_ text: RecognizedText) {
        let values = Value.detect(in: text.string)
        guard values.count > 0 else {
            return nil
        }        
        self.text = text
        
        /// If only value has a unit, pick that one and discard the rest
        if values.containingUnit.count == 1 {
            self.values = values.containingUnit
        } else {
            self.values = values
        }
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
    
    func closestValueText(to recognizedText: RecognizedText?) -> ValuesText? {
        /// Simply returning first value for now
        first
        //TODO: Consider recognizedText and distance to it when we need to
//        let sorted = self.sorted(by: { $0.text.rect.yDistanceToTopOf(recognizedText.rect) < $1.text.rect.yDistanceToTopOf(recognizedText.rect) })
//        return sorted.first
    }
    
    var rect: CGRect {
        reduce(.zero) {
            $0.union($1.text.rect)
        }
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

import Foundation

extension Array where Element == NutrientArtefact {
    func valuePreceding(_ attribute: Attribute) -> Value? {
        guard let attributeIndex = firstIndex(where: { $0.attribute == attribute }),
              attributeIndex > 0,
              let value = self[attributeIndex-1].value
        else {
            return nil
        }
        
        /// If the value has a unit, make sure that the attribute supports it
        if let unit = value.unit {
            guard attribute.supportsUnit(unit) else {
                return nil
            }
        } else {
            /// Otherwise, if the value has no unit, make sure that the attribute supports unit-less values
            guard attribute.supportsUnitLessValues else {
                return nil
            }
        }
        
        return value
    }
}

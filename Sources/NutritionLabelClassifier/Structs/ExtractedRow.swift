import SwiftUI
import VisionSugar

struct ExtractedRow {
    let attributeText: AttributeText
    var valuesTexts: [ValuesText?]
    
    var ratioColumn1To2: Double? {
        guard valuesTexts.count == 2,
              let amount1 = valuesTexts[0]?.values.first?.amount,
              let amount2 = valuesTexts[1]?.values.first?.amount,
              amount2 != 0
        else {
            return nil
        }
        return amount1/amount2
    }
    
    var hasNilValues: Bool {
        valuesTexts.allSatisfy({ $0 == nil })
    }
    
    var hasOneMissingValue: Bool {
        singleMissingValueIndex != nil
    }
    
    var singleMissingValueIndex: Int? {
        guard valuesTexts.count == 2 else { return nil }
        if valuesTexts[0] != nil && valuesTexts[1] == nil {
            return 1
        }
        if valuesTexts[1] != nil && valuesTexts[0] == nil {
            return 0
        }
        return nil
    }
    
    var hasZeroValues: Bool {
        valuesTexts.allSatisfy({ $0?.values.first?.amount == 0 })
    }
}

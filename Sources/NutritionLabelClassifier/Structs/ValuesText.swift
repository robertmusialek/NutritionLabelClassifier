import VisionSugar

struct ValuesText {

    let values: [Value]
    let text: RecognizedText
    
    init?(_ text: RecognizedText) {
        let values = Value.detect(in: text.string)
        /// End the loop if any non-value, non-skippable texts are encountered
        guard values.count > 0 || text.string.isSkippableValueElement else {
            return nil
        }

        /// Discard any singular % values
        if values.count == 1, let first = values.first {
            guard first.unit != .p else {
                return nil
            }
        }

        self.text = text
        self.values = values
    }

    var containsValueWithEnergyUnit: Bool {
        values.containsValueWithEnergyUnit
    }
}

extension Array where Element == ValuesText {
    var containsValueWithEnergyUnit: Bool {
        contains(where: { $0.containsValueWithEnergyUnit })
    }
}

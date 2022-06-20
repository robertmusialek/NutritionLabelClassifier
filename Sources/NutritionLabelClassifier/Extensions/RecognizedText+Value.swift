import VisionSugar

extension RecognizedText {
    var containsEnergyValue: Bool {
        let values = Value.detect(in: self.string)
        return values.contains(where: { $0.hasEnergyUnit })
    }
}

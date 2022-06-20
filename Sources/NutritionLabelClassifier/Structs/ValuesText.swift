import VisionSugar

struct ValuesText {

    let values: [Value]
    let text: RecognizedText
    
    init?(text: RecognizedText) {
        let values = Value.detect(in: text.string)
        guard values.count > 0 else {
            return nil
        }
        self.text = text
        self.values = values
    }
}

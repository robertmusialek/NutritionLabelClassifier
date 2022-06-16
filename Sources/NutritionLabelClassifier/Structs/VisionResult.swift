import VisionSugar

struct VisionResult {

    var accurateRecognitionWithLanugageCorrection: [RecognizedText]? = nil
    var accurateRecognitionWithoutLanugageCorrection: [RecognizedText]? = nil
    var fastRecognition: [RecognizedText]? = nil
    
    var arrayOfTexts: [[RecognizedText]] {
        var arrays: [[RecognizedText]] = []
        if let array = accurateRecognitionWithLanugageCorrection {
            arrays.append(array)
        }
        if let array = accurateRecognitionWithoutLanugageCorrection {
            arrays.append(array)
        }
        if let array = fastRecognition {
            arrays.append(array)
        }
        return arrays
    }
}

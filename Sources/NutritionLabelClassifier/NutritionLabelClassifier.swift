import SwiftUI
import VisionSugar
import TabularData

public let NutritionLabelClassifierVersion = "0.0.165"

let IsTestingNewAlgorithm = true

//TODO: Rename this to NutritionFactsRecognizer
public class NutritionLabelClassifier {
    
    //    var arrayOfRecognizedTexts: [[RecognizedText]]
    //
    var visionResult: VisionResult = VisionResult()
    
    var image: UIImage? = nil
    var contentSize: CGSize? = nil
    var onCompletion: ((Output?) -> Void)? = nil

    var observations: [Observation] = []

    public init(image: UIImage, contentSize: CGSize) {
        self.image = image
        self.contentSize = contentSize
    }
    
    //TODO: Handle having no images or contentsize elegantly, throwing errors that informs the client of this service
    public func classify() {
        recognizeTexts {
            let output = self.getOutput()
            self.onCompletion?(output)
        }
    }
    
    public func recognizeTexts(completion: @escaping () -> Void) {
        guard let image = image, let contentSize = contentSize else { return }

        let customWords = ["Lípidos", "zaharuri", "of which sugars"]
        
        let start = CFAbsoluteTimeGetCurrent()
        
        VisionSugar.recognizeTexts(in: image, useLanguageCorrection: true, customWords: customWords) { textObservations in
            guard let textObservations = textObservations else { return }
            self.visionResult.accurateRecognitionWithLanugageCorrection = VisionSugar.recognizedTexts(
                of: textObservations,
                for: image,
                inContentSize: contentSize
            )
            
            let withoutLCStart = CFAbsoluteTimeGetCurrent()
            print("👁 withLC took: \(CFAbsoluteTimeGetCurrent()-start)s")
            
            VisionSugar.recognizeTexts(in: image, useLanguageCorrection: false) { textObservations in
                guard let textObservations = textObservations else { return }
                self.visionResult.accurateRecognitionWithoutLanugageCorrection = VisionSugar.recognizedTexts(
                    of: textObservations,
                    for: image,
                    inContentSize: contentSize
                )
                
                let fastStart = CFAbsoluteTimeGetCurrent()
                print("👁 withoutLC finished by: \(CFAbsoluteTimeGetCurrent()-start)s, took \(CFAbsoluteTimeGetCurrent()-withoutLCStart)s")
                
                VisionSugar.recognizeTexts(in: image, recognitionLevel: .fast, customWords: customWords) { textObservations in
                    guard let textObservations = textObservations else { return }
                    self.visionResult.fastRecognition = VisionSugar.recognizedTexts(
                        of: textObservations,
                        for: image,
                        inContentSize: contentSize
                    )
                    
                    print("👁 fast recognition finished by: \(CFAbsoluteTimeGetCurrent()-start)s, took \(CFAbsoluteTimeGetCurrent()-fastStart)s")
                    print("👁 extraction took: \(CFAbsoluteTimeGetCurrent()-start)s")
                    
                    completion()
                }
            }
        }
    }
    
    public init(arrayOfRecognizedTexts: [[RecognizedText]]) {
        visionResult.accurateRecognitionWithLanugageCorrection = arrayOfRecognizedTexts[0]
        visionResult.accurateRecognitionWithoutLanugageCorrection = arrayOfRecognizedTexts[1]
        visionResult.fastRecognition = arrayOfRecognizedTexts[2]
    }
    
    public init(recognizedTexts: [RecognizedText]) {
        self.visionResult.accurateRecognitionWithLanugageCorrection = recognizedTexts
        //        self.arrayOfRecognizedTexts = [recognizedTexts]
    }
    
    //MARK: - Legacy
    
    public static func classify(_ arrayOfRecognizedTexts: [[RecognizedText]]) -> Output? {
        let classifier = NutritionLabelClassifier(arrayOfRecognizedTexts: arrayOfRecognizedTexts)
        return classifier.getOutput()
    }
    
    public static func classify(_ recognizedTexts: [RecognizedText]) -> Output? {
        let classifier = NutritionLabelClassifier(recognizedTexts: recognizedTexts)
        return classifier.getOutput()
    }
}

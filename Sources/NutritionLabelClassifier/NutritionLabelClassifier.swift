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
    var onCompletion: (() -> Void)? = nil

    var observations: [Observation] = []

    public init(image: UIImage, contentSize: CGSize) {
        self.image = image
        self.contentSize = contentSize
    }
    
    public func classify() {
        guard let image = image, let contentSize = contentSize else { return }
        let customWords = ["Lípidos", "zaharuri", "of which sugars"]
        
        let start = CFAbsoluteTimeGetCurrent()
        
        VisionSugar.recognizeTexts(in: image, useLanguageCorrection: true, customWords: customWords) { observations in
            guard let observations = observations else { return }
            self.visionResult.accurateRecognitionWithLanugageCorrection = VisionSugar.recognizedTexts(
                of: observations,
                for: image,
                inContentSize: contentSize
            )
            
            let withoutLCStart = CFAbsoluteTimeGetCurrent()
            print("👁 withLC took: \(CFAbsoluteTimeGetCurrent()-start)s")
            
            VisionSugar.recognizeTexts(in: image, useLanguageCorrection: false) { observations in
                guard let observations = observations else { return }
                self.visionResult.accurateRecognitionWithoutLanugageCorrection = VisionSugar.recognizedTexts(
                    of: observations,
                    for: image,
                    inContentSize: contentSize
                )
                
                let fastStart = CFAbsoluteTimeGetCurrent()
                print("👁 withoutLC finished by: \(CFAbsoluteTimeGetCurrent()-start)s, took \(CFAbsoluteTimeGetCurrent()-withoutLCStart)s")
                
                VisionSugar.recognizeTexts(in: image, recognitionLevel: .fast, customWords: customWords) { observations in
                    guard let observations = observations else { return }
                    self.visionResult.fastRecognition = VisionSugar.recognizedTexts(
                        of: observations,
                        for: image,
                        inContentSize: contentSize
                    )
                    
                    print("👁 fast recognition finished by: \(CFAbsoluteTimeGetCurrent()-start)s, took \(CFAbsoluteTimeGetCurrent()-fastStart)s")
                    print("👁 extraction took: \(CFAbsoluteTimeGetCurrent()-start)s")
                    self.onCompletion?()
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
    
    public static func classify(_ arrayOfRecognizedTexts: [[RecognizedText]]) -> Output {
        let classifier = NutritionLabelClassifier(arrayOfRecognizedTexts: arrayOfRecognizedTexts)
        return classifier.getObservations()
    }
    
    public static func classify(_ recognizedTexts: [RecognizedText]) -> Output {
        let classifier = NutritionLabelClassifier(recognizedTexts: recognizedTexts)
        return classifier.getObservations()
    }
    
    func getObservations() -> Output {
        dataFrameOfObservations().classifierOutput
    }
    
    /**
     - Stop using DataFrame as an intermediary between NutritionLabelClassifier and its Output as its adding unnecessary overhead

     - Stop appending observations to a pre-existing array with each Classifier
         - Instead, have each classifier (NutrientsTable, NutrientsInline, Serving, Header, (possibly EdgeCases) return an optional [Observations]?
         - Only append the contents to our main observations array if we do have a non-nil return value
         - Use this optionality to indicate whether the NutrientsTableClassifier returned a result—and only resort to the NutrientsInlineClassifier if not
         - Finally, convert the array of Observations to the Classifier Output
     */
    public func dataFrameOfObservations() -> DataFrame {
        if IsTestingNewAlgorithm {
            observations = TableClassifier.observations(
                from: visionResult,
                priorObservations: observations)
        } else {
            for recognizedTexts in visionResult.arrayOfTexts {
                
                observations = NutrientsClassifier.observations(
                    from: recognizedTexts,
                    priorObservations: observations)
                
                observations = ServingClassifier.observations(
                    from: recognizedTexts,
                    arrayOfRecognizedTexts: visionResult.arrayOfTexts,
                    priorObservations: observations)
                
                observations = HeaderClassifier.observations(
                    from: recognizedTexts,
                    priorObservations: observations)
                
                observations = EdgeCasesClassifier.observations(
                    from: recognizedTexts,
                    priorObservations: observations)
            }
        }
        return Self.dataFrameOfNutrients(from: observations)
    }
    
    private static func dataFrameOfNutrients(from observations: [Observation]) -> DataFrame {
        var dataFrame = DataFrame()
        let labelColumn = Column(name: "attribute", contents: observations.map { $0.attributeText })
        let value1Column = Column(name: "value1", contents: observations.map { $0.valueText1 })
        let value2Column = Column(name: "value2", contents: observations.map { $0.valueText2 })
        let doubleColumn = Column(name: "double", contents: observations.map { $0.doubleText })
        let stringColumn = Column(name: "string", contents: observations.map { $0.stringText })
        dataFrame.append(column: labelColumn)
        dataFrame.append(column: value1Column)
        dataFrame.append(column: value2Column)
        dataFrame.append(column: doubleColumn)
        dataFrame.append(column: stringColumn)
        return dataFrame
    }
}

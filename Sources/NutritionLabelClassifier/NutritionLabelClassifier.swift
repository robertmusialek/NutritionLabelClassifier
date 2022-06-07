import Foundation
import VisionSugar
import TabularData

public let NutritionLabelClassifierVersion = "0.0.148"

//TODO: Rename this to
/// `NutritionLabelRecognizer`
/// `NutritionFactRecognizer`
/// `NutritionFactsRecognizer` likely candidate—maybe name `output` to `facts`
/// `NuritionFactsLabelRecognizer` too long
/// `LabelRecognizer` too short
public class NutritionLabelClassifier {
    
    var arrayOfRecognizedTexts: [[RecognizedText]]
    var observations: [Observation] = []
    
    public init(arrayOfRecognizedTexts: [[RecognizedText]]) {
        self.arrayOfRecognizedTexts = arrayOfRecognizedTexts
    }
    
    public init(recognizedTexts: [RecognizedText]) {
        self.arrayOfRecognizedTexts = [recognizedTexts]
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
    
    public func dataFrameOfObservations() -> DataFrame {
        for recognizedTexts in arrayOfRecognizedTexts {
            observations = NutrientsClassifier.observations(from: recognizedTexts,
                                                            priorObservations: observations)
            observations = ServingClassifier.observations(
                from: recognizedTexts,
                arrayOfRecognizedTexts: arrayOfRecognizedTexts,
                priorObservations: observations)
            observations = HeaderClassifier.observations(from: recognizedTexts,
                                                          priorObservations: observations)
            observations = EdgeCasesClassifier.observations(from: recognizedTexts,
                                                            priorObservations: observations)
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

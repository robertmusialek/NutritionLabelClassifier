import SwiftUI
import VisionSugar
import TabularData

extension NutritionLabelClassifier {
    /**
     - Stop using DataFrame as an intermediary between NutritionLabelClassifier and its Output as its adding unnecessary overhead

     - Stop appending observations to a pre-existing array with each Classifier
         - Instead, have each classifier (NutrientsTable, NutrientsInline, Serving, Header, (possibly EdgeCases) return an optional [Observations]?
         - Only append the contents to our main observations array if we do have a non-nil return value
         - Use this optionality to indicate whether the NutrientsTableClassifier returned a result—and only resort to the NutrientsInlineClassifier if not
         - Finally, convert the array of Observations to the Classifier Output
     */
    func getOutput() -> Output? {
        let observations = TableClassifier.observations(from: visionResult)
        return observations.output
    }

    func getOutput_legacy() -> Output {
        dataFrameOfObservations().classifierOutput
    }

    //MARK: - Legacy
    
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

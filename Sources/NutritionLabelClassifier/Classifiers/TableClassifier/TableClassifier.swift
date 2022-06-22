import Foundation
import VisionSugar

class TableClassifier {
    
//    let arrayOfRecognizedTexts: [[RecognizedText]]
    let visionResult: VisionResult
    var observations: [Observation]
    
    var pendingObservations: [Observation] = []
    var observationBeingExtracted: Observation? = nil

    /// Holds onto those that are single `Value`s that have already been used
    var discarded: [RecognizedText] = []

    init(visionResult: VisionResult, observations: [Observation] = []) {
//        self.arrayOfRecognizedTexts = arrayOfRecognizedTexts
        self.visionResult = visionResult
        self.observations = observations
    }
    
    static func observations(from visionResult: VisionResult, priorObservations observations: [Observation] = []) -> [Observation]
    {
        TableClassifier(
            visionResult: visionResult,
            observations: observations)
        .getObservations()
    }
    
    var extractedAttributes: ExtractedAttributes? = nil
    var extractedValues: ExtractedValues? = nil
    
    func getObservations() -> [Observation] {

        extractedAttributes = extractAttributeTextColumns()
        extractedValues = extractValueTextColumnGroups()
        
        return observations
//        /// Identify column of labels
//        if let attributeRecognizedTexts = getColumnsOfAttributes() {
////            let attributes = getUniqueAttributeTextsFrom(attributeRecognizedTexts)
//
//            let valueRecognizedTexts = getValueRecognizedTexts()
//
//            let value1Texts: [ValueText]?
//            if let valueTexts = valueRecognizedTexts.0 {
//                value1Texts = valueTexts.compactMap {
//                    guard let value = Value(fromString: $0.string) else { return nil }
//                    return ValueText(value: value, text: $0)
//                }
//            } else {
//                value1Texts = nil
//            }
//
//            let value2Texts: [ValueText]?
//            if let valueTexts = valueRecognizedTexts.1 {
//                value2Texts = valueTexts.compactMap {
//                    guard let value = Value(fromString: $0.string) else { return nil }
//                    return ValueText(value: value, text: $0)
//                }
//            } else {
//                value2Texts = nil
//            }
//
//            //TODO: Next, we need to clean up columns by:
//            // 1. Detect that we have inline values with the attribute labels and then insert it accordingly into the column that is closest in terms of the y-value
//                // Also detect that we have merged two column values (such as energy with sliced cheese) in a value and use that to fill in both values accordingly
//            // 2. After this, use the largest column array (in terms of its count), to then space out and detect the empty or unread values in the smaller column by comparing the deltas between the y-values of elements (perhaps their centers?), and detecting the anomalies
//                // Test this on the Shredded Cheese Fibre value by making sure that gap is detected
//                // See if our ratio heuristic can fix this without the inline value before bringing it back in
//            // 3. Now that the values have the same number of rows, do another cleanup with the labels if the rows don't match
//                // First see if we have too many values, and if so, determine which labels are missing
//                    // If its energy and we have the energy units, fill it
//                // Now see if we have too many labels and if so, determine which value rows are missing, filling them with 0's (again using the y-value trick)
//            print("Here we go")
//        }
//
//        return observations
    }
    
    //MARK: - Values
    func getValueRecognizedTexts() -> ([RecognizedText]?, [RecognizedText]?) {

        var candidates: [[RecognizedText]] = [[]]
        
        for recognizedTexts in [visionResult.accurateRecognitionWithLanugageCorrection ?? []] {
            for text in recognizedTexts {
                guard let _ = Value(fromString: text.string) else {
                    continue
                }
                
//                let columnOfTexts = getColumnOfValueLabelTexts(startingFrom: text)
//                    .sorted(by: { $0.rect.minY < $1.rect.minY })
                
//                candidates.append(columnOfTexts)
            }
        }
        
        let uniqueCandidates = candidates.uniqued()

        /// Now that we've parsed all the nutrient-label columns, pick the first two with the most elements
        let sorted = uniqueCandidates
            .sorted(by: { $0.count > $1.count })
        
        guard sorted.count > 0 else {
            return (nil, nil)
        }
        
        guard sorted.count > 1 else {
            return (sorted[0], nil)
        }
        
        let average0 = sorted[0].reduce(0) { $0 + $1.rect.midX } / Double(sorted[0].count)
        let average1 = sorted[1].reduce(0) { $0 + $1.rect.midX } / Double(sorted[1].count)

        if average0 < average1 {
            return (sorted[0], sorted[1])
        } else {
            return (sorted[1], sorted[0])
        }
    }
}

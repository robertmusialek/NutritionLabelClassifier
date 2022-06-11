import Foundation
import VisionSugar

class TableClassifier: Classifier {
    
    let recognizedTexts: [RecognizedText]
    var observations: [Observation]
    
    var pendingObservations: [Observation] = []
    var observationBeingExtracted: Observation? = nil

    /// Holds onto those that are single `Value`s that have already been used
    var discarded: [RecognizedText] = []

    init(recognizedTexts: [RecognizedText], observations: [Observation]) {
        self.recognizedTexts = recognizedTexts
        self.observations = observations
    }
    
    static func observations(from recognizedTexts: [RecognizedText], priorObservations observations: [Observation]) -> [Observation] {
        TableClassifier(recognizedTexts: recognizedTexts, observations: observations).getObservations()
    }

    func getObservations() -> [Observation] {

        /// Identify column of labels
        let nutrientLabelTexts = getNutrientLabelTexts()
        
        return observations
    }
    
    func getNutrientLabelTexts() -> [RecognizedText]? {
        
        var candidates: [[RecognizedText]] = [[]]
        
        for text in recognizedTexts {
            guard let attribute = Attribute(fromString: text.string), attribute.isNutrientAttribute else {
                continue
            }
            
            /// Go through texts until a nutrient attribute is found
            let columnOfTexts = getColumnOfNutrientLabelTexts(startingFrom: text)
            
            /// Add this to the array of candidates
            candidates.append(columnOfTexts)
        }
        
        /// Now that we've parsed all the nutrient-label columns, pick the one with the most elements
        return candidates.sorted(by: { $0.count > $1.count }).first
    }
    
    func getColumnOfNutrientLabelTexts(startingFrom startingText: RecognizedText) -> [RecognizedText] {
        
//        print("Getting column starting from: \(startingText.string)")

        let BoundingBoxMinXDeltaThreshold = 0.05
        var array: [RecognizedText] = [startingText]
        
        /// Now go upwards to get nutrient-attribute texts in same column as it
        let textsAbove = recognizedTexts.filterSameColumn(as: startingText, preceding: true, removingOverlappingTexts: false).reversed()
        
        for text in textsAbove {
            let boundingBoxMinXDelta = abs(text.boundingBox.minX - startingText.boundingBox.minX)
            
            /// Ignore `text`s that are clearly not in-line with the `startingText`, in terms of its `boundingBox.minX` being more than `0.05` from the `startingText`s
            guard boundingBoxMinXDelta < BoundingBoxMinXDeltaThreshold else {
                continue
            }

            /// Until we reach a non-nutrient-attribute text
            guard let attribute = Attribute(fromString: text.string), attribute.isNutrient else {
                break
            }
            
            /// Insert these into the start of our column of labels as we read them in
            array.insert(text, at: 0)
        }

        /// Now do the same thing downwards
        let textsBelow = recognizedTexts.filterSameColumn(as: startingText, preceding: false, removingOverlappingTexts: false)
        for text in textsBelow {
            let boundingBoxMinXDelta = abs(text.boundingBox.minX - startingText.boundingBox.minX)
            
            /// Ignore `text`s that are clearly not in-line with the `startingText`, in terms of its `boundingBox.minX` being more than `0.05` from the `startingText`s
            guard boundingBoxMinXDelta < BoundingBoxMinXDeltaThreshold else {
                continue
            }

            guard let attribute = Attribute(fromString: text.string), attribute.isNutrient else {
                break
            }
            
            array.append(text)
        }

//        print(array.description)
//        print(" ")

        return array
    }
}

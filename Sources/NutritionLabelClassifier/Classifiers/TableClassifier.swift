import Foundation
import VisionSugar

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}

class TableClassifier {
    
    let arrayOfRecognizedTexts: [[RecognizedText]]
    var observations: [Observation]
    
    var pendingObservations: [Observation] = []
    var observationBeingExtracted: Observation? = nil

    /// Holds onto those that are single `Value`s that have already been used
    var discarded: [RecognizedText] = []

    init(arrayOfRecognizedTexts: [[RecognizedText]], observations: [Observation]) {
        self.arrayOfRecognizedTexts = arrayOfRecognizedTexts
        self.observations = observations
    }
    
    static func observations(from arrayOfRecognizedTexts: [[RecognizedText]], priorObservations observations: [Observation]) -> [Observation]
    {
        TableClassifier(
            arrayOfRecognizedTexts: arrayOfRecognizedTexts,
            observations: observations)
        .getObservations()
    }

    func getObservations() -> [Observation] {

        /// Identify column of labels
        if let nutrientLabelTexts = getNutrientLabelTexts() {
            let attributes = getUniqueAttributesFrom(nutrientLabelTexts)
            
            let valueTexts = getValueLabelTexts()
            print("Here we go")
        }
        
        
        
        
        return observations
    }
    
    //MARK: - Values
    func getValueLabelTexts() -> ([RecognizedText]?, [RecognizedText]?) {

        var candidates: [[RecognizedText]] = [[]]
        
        for recognizedTexts in arrayOfRecognizedTexts {
            for text in recognizedTexts {
                guard let _ = Value(fromString: text.string) else {
                    continue
                }
                
                let columnOfTexts = getColumnOfValueLabelTexts(startingFrom: text)
                    .sorted(by: { $0.rect.minY < $1.rect.minY })
                
                candidates.append(columnOfTexts)
            }
        }
        
        /// Now that we've parsed all the nutrient-label columns, pick the one with the most elements
        let sorted = candidates.sorted(by: { $0.count > $1.count })
        if let first = sorted.first {
            if candidates.count > 2 {
                return (first, candidates[1])
            } else {
                return (first, nil)
            }
        } else {
            return (nil, nil)
        }
    }
    
    func getColumnOfValueLabelTexts(startingFrom startingText: RecognizedText) -> [RecognizedText] {
        
        let BoundingBoxMaxXDeltaThreshold = 0.05
        var array: [RecognizedText] = [startingText]
        
        //TODO: Remove using only first array of texts
        for recognizedTexts in [arrayOfRecognizedTexts.first ?? []] {
            /// Now go upwards to get nutrient-attribute texts in same column as it
            let textsAbove = recognizedTexts.filterSameColumn(as: startingText, preceding: true, removingOverlappingTexts: false).filter { !$0.string.isEmpty }.reversed()
            
            for text in textsAbove {
                let delta = abs(text.boundingBox.maxX - startingText.boundingBox.maxX)
                
                /// Ignore `text`s that are clearly not in-line with the `startingText`, in terms of its `boundingBox.minX` being more than `0.05` from the `startingText`s
                guard delta < BoundingBoxMaxXDeltaThreshold else {
                    continue
                }

                /// Until we reach a non-nutrient-attribute text
                guard let _ = Value(fromString: text.string) else {
                    break
                }
                
                /// Insert these into the start of our column of labels as we read them in
                array.insert(text, at: 0)
            }

            /// Now do the same thing downwards
            let textsBelow = recognizedTexts.filterSameColumn(as: startingText, preceding: false, removingOverlappingTexts: false).filter { !$0.string.isEmpty }
            for text in textsBelow {
                let delta = abs(text.boundingBox.maxX - startingText.boundingBox.maxX)
                
                /// Ignore `text`s that are clearly not in-line with the `startingText`, in terms of its `boundingBox.minX` being more than `0.05` from the `startingText`s
                guard delta < BoundingBoxMaxXDeltaThreshold else {
                    continue
                }

                guard let _ = Value(fromString: text.string) else {
                    break
                }
                
                array.append(text)
            }
        }

        return array
    }
    
    //MARK: - Attributes
    func getUniqueAttributesFrom(_ texts: [RecognizedText]) -> [Attribute]? {
        texts.compactMap({ Attribute(fromString: $0.string) }).uniqued()
    }
    
    func getNutrientLabelTexts() -> [RecognizedText]? {
        
        var candidates: [[RecognizedText]] = [[]]
        
        for recognizedTexts in arrayOfRecognizedTexts {
            for text in recognizedTexts {
                guard let attribute = Attribute(fromString: text.string), attribute.isNutrientAttribute else {
                    continue
                }
                
                /// Go through texts until a nutrient attribute is found
                let columnOfTexts = getColumnOfNutrientLabelTexts(startingFrom: text)
                    .sorted(by: { $0.rect.minY < $1.rect.minY })
                
                /// Add this to the array of candidates
                candidates.append(columnOfTexts)
            }
        }
        
        /// Now that we've parsed all the nutrient-label columns, pick the one with the most elements
        return candidates.sorted(by: { $0.count > $1.count }).first
    }
    func getColumnOfNutrientLabelTexts(startingFrom startingText: RecognizedText) -> [RecognizedText] {
        
//        print("Getting column starting from: \(startingText.string)")

        let BoundingBoxMinXDeltaThreshold = 0.05
        var array: [RecognizedText] = [startingText]
        
        for recognizedTexts in arrayOfRecognizedTexts {
            /// Now go upwards to get nutrient-attribute texts in same column as it
            let textsAbove = recognizedTexts.filterSameColumn(as: startingText, preceding: true, removingOverlappingTexts: false).filter { !$0.string.isEmpty }.reversed()
            
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
            let textsBelow = recognizedTexts.filterSameColumn(as: startingText, preceding: false, removingOverlappingTexts: false).filter { !$0.string.isEmpty }
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
        }

//        print(array.description)
//        print(" ")

        return array
    }
}

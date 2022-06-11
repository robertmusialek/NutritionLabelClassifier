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
        if let attributeRecognizedTexts = getAttributeRecognizedTexts() {
            let attributes = getUniqueAttributeTextsFrom(attributeRecognizedTexts)
            
            let valueRecognizedTexts = getValueRecognizedTexts()
            
            let value1Texts: [ValueText]?
            if let valueTexts = valueRecognizedTexts.0 {
                value1Texts = valueTexts.compactMap {
                    guard let value = Value(fromString: $0.string) else { return nil }
                    return ValueText(value: value, text: $0)
                }
            } else {
                value1Texts = nil
            }
            
            let value2Texts: [ValueText]?
            if let valueTexts = valueRecognizedTexts.1 {
                value2Texts = valueTexts.compactMap {
                    guard let value = Value(fromString: $0.string) else { return nil }
                    return ValueText(value: value, text: $0)
                }
            } else {
                value2Texts = nil
            }
            
            //TODO: Next, we need to clean up columns by:
            // 1. Detect that we have inline values with the attribute labels and then insert it accordingly into the column that is closest in terms of the y-value
                // Also detect that we have merged two column values (such as energy with sliced cheese) in a value and use that to fill in both values accordingly
            // 2. After this, use the largest column array (in terms of its count), to then space out and detect the empty or unread values in the smaller column by comparing the deltas between the y-values of elements (perhaps their centers?), and detecting the anomalies
                // Test this on the Shredded Cheese Fibre value by making sure that gap is detected
                // See if our ratio heuristic can fix this without the inline value before bringing it back in
            // 3. Now that the values have the same number of rows, do another cleanup with the labels if the rows don't match
                // First see if we have too many values, and if so, determine which labels are missing
                    // If its energy and we have the energy units, fill it
                // Now see if we have too many labels and if so, determine which value rows are missing, filling them with 0's (again using the y-value trick)
            print("Here we go")
        }
        
        
        
        
        return observations
    }
    
    //MARK: - Values
    func getValueRecognizedTexts() -> ([RecognizedText]?, [RecognizedText]?) {

        var candidates: [[RecognizedText]] = [[]]
        
        for recognizedTexts in [arrayOfRecognizedTexts.first ?? []] {
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
    func getUniqueAttributeTextsFrom(_ texts: [RecognizedText]) -> [AttributeText]? {
        var attributeTexts: [AttributeText] = []
        for text in texts {
            guard let attribute = Attribute(fromString: text.string),
                  !attributeTexts.contains(where: { $0.attribute == attribute })
            else {
                continue
            }
            attributeTexts.append(AttributeText(attribute: attribute, text: text))
        }
        return attributeTexts
    }
    
    func getAttributeRecognizedTexts() -> [RecognizedText]? {
        
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

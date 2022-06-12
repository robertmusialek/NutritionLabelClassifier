import Foundation
import VisionSugar

extension TableClassifier {
    
    public func getAttributes() -> [Attribute] {
        guard let attributeRecognizedTexts = getAttributeRecognizedTexts() else {
            return []
        }
        return getUniqueAttributeTextsFrom(attributeRecognizedTexts)?
            .map { $0.attribute }
        ?? []
    }
    
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
        
        print("Getting column starting from: \(startingText.string)")

        let BoundingBoxMinXDeltaThreshold = 0.20
        var array: [RecognizedText] = [startingText]
        
        for recognizedTexts in arrayOfRecognizedTexts {
            /// Now go upwards to get nutrient-attribute texts in same column as it
            let textsAbove = recognizedTexts.filterSameColumn(as: startingText, preceding: true, removingOverlappingTexts: false).filter { !$0.string.isEmpty }.reversed()
            
            print("  ⬆️ textsAbove: \(textsAbove.map { $0.string } )")

            for text in textsAbove {
                print("    Checking: \(text.string)")
                let boundingBoxMinXDelta = abs(text.boundingBox.minX - startingText.boundingBox.minX)
                
                /// Ignore `text`s that are clearly not in-line with the `startingText`, in terms of its `boundingBox.minX` being more than `0.05` from the `startingText`s
                guard boundingBoxMinXDelta < BoundingBoxMinXDeltaThreshold else {
                    print("    ignoring because boundingBoxMinXDelta = \(boundingBoxMinXDelta)")
                    continue
                }

                /// Until we reach a non-nutrient-attribute text
                guard let attribute = Attribute(fromString: text.string) else {
                    print("    ✋🏽 ending search because couldn't get an attribute for it")
                    break
                }
                
                guard attribute.isNutrient else {
                    print("    ✋🏽 ending search because attribute: \(attribute) isn't a nutrient")
                    break
                }
                
                /// Insert these into the start of our column of labels as we read them in
                array.insert(text, at: 0)
            }

            /// Now do the same thing downwards
            let textsBelow = recognizedTexts.filterSameColumn(as: startingText, preceding: false, removingOverlappingTexts: false).filter { !$0.string.isEmpty }
            
            print("  ⬇️ textsBelow: \(textsBelow.map { $0.string } )")

            for text in textsBelow {
                print("    Checking: \(text.string)")
                let boundingBoxMinXDelta = abs(text.boundingBox.minX - startingText.boundingBox.minX)
                
                /// Ignore `text`s that are clearly not in-line with the `startingText`, in terms of its `boundingBox.minX` being more than `0.05` from the `startingText`s
                guard boundingBoxMinXDelta < BoundingBoxMinXDeltaThreshold else {
                    print("    ignoring because boundingBoxMinXDelta = \(boundingBoxMinXDelta)")
                    continue
                }

                guard let attribute = Attribute(fromString: text.string) else {
                    print("    ✋🏽 ending search because couldn't get an attribute for it")
                    break
                }
                
                guard attribute.isNutrient else {
                    print("    ✋🏽 ending search because attribute: \(attribute) isn't a nutrient")
                    break
                }
                
                array.append(text)
            }
        }

        print("    ✨Got: \(array.description)")
        print(" ")
        print(" ")
        return array
    }
}

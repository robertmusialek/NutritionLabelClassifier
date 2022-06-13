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
    
    func getAttributeRecognizedTexts() -> [RecognizedText]? {
        
        var candidates: [[RecognizedText]] = [[]]
        
        for recognizedTexts in arrayOfRecognizedTexts {
            for text in recognizedTexts {
                guard Attribute.haveNutrientAttribute(in: text.string) else {
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
    
    func getUniqueAttributeTextsFrom(_ texts: [RecognizedText]) -> [AttributeText]? {
        var attributeTexts: [AttributeText] = []
        for text in texts {
            let attributes = Attribute.detect(in: text.string)
            for attribute in attributes {
                guard !attributeTexts.contains(where: { $0.attribute == attribute }) else { continue }
                attributeTexts.append(AttributeText(attribute: attribute, text: text))
            }
        }
        return attributeTexts
    }
    
    func getColumnOfNutrientLabelTexts(startingFrom startingText: RecognizedText) -> [RecognizedText] {
        
        print("Getting column starting from: \(startingText.string)")

        let BoundingBoxMinXDeltaThreshold = 0.20
        var array: [RecognizedText] = [startingText]
        
        for recognizedTexts in arrayOfRecognizedTexts {
            /// Now go upwards to get nutrient-attribute texts in same column as it
            let textsAbove = recognizedTexts.filterColumn(of: startingText, preceding: true).filter { !$0.string.isEmpty }.reversed()
            
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
                guard text.string.containsNutrientOrTitleAttributes else {
                    print("    ✋🏽 ending search because no nutrient attributes can be detected in string")
                    break
                }
                
                /// Skip over title attributes, but don't stop searching because of them
                guard !text.string.isTitleAttribute else {
                    continue
                }

                /// Insert these into the start of our column of labels as we read them in
                array.insert(text, at: 0)
            }

            /// Now do the same thing downwards
            let textsBelow = recognizedTexts.filterColumn(of: startingText, preceding: false).filter { !$0.string.isEmpty }
            
            print("  ⬇️ textsBelow: \(textsBelow.map { $0.string } )")

            for text in textsBelow {
                print("    Checking: \(text.string)")
                let boundingBoxMinXDelta = abs(text.boundingBox.minX - startingText.boundingBox.minX)
                
                /// Ignore `text`s that are clearly not in-line with the `startingText`, in terms of its `boundingBox.minX` being more than `0.05` from the `startingText`s
                guard boundingBoxMinXDelta < BoundingBoxMinXDeltaThreshold else {
                    print("    ignoring because boundingBoxMinXDelta = \(boundingBoxMinXDelta)")
                    continue
                }
                
                guard text.string.containsNutrientOrTitleAttributes else {
                    print("    ✋🏽 ending search because no nutrient or title attributes can be detected in string")
                    break
                }
                
                /// Skip over title attributes, but don't stop searching because of them
                guard !text.string.isTitleAttribute else {
                    continue
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

extension String {
    
    var isTitleAttribute: Bool {
        guard let attribute = Attribute(fromString: self),
           attribute.isTitleAttribute else {
            return false
        }
        return true
    }
    
    var containsNutrientOrTitleAttributes: Bool {
        containsNutrientAttributes || isTitleAttribute
    }
    
    var containsNutrientAttributes: Bool {
        Attribute.haveNutrientAttribute(in: self)
    }
}
extension Attribute {
    
    /// Detects `Attribute`s in a provided `string` in the order that they appear
    static func detect(in string: String) -> [Attribute] {
        var attributesAndPositions: [(attribute: Attribute, positionOfMatch: Int)] = []
        
        for attribute in Self.allCases {
            guard let regex = attribute.regex else { continue }
            if let match = matches(for: regex, in: string.cleanedAttributeString)?.first {
                attributesAndPositions.append((attribute, match.position))
            }
        }
        
        return attributesAndPositions
            .sorted(by: { $0.positionOfMatch < $1.positionOfMatch })
            .map { $0.attribute }
    }

    static func haveAttributes(in string: String) -> Bool {
        detect(in: string).count > 0
    }
    
    static func haveNutrientAttribute(in string: String) -> Bool {
        detect(in: string).contains(where: { $0.isNutrientAttribute })
    }
}

//TODO: Rename, document and move to SwiftSugar
func matches(for regex: String, in text: String) -> [(string: String, position: Int)]? {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        let matches = results.map {
            (string: String(text[Range($0.range, in: text)!]),
             position: $0.range.lowerBound)
        }
        return matches.count > 0 ? matches : nil
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return nil
    }
}

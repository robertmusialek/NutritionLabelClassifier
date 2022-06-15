import Foundation
import VisionSugar
import TabularData
import UIKit

extension Array where Element == AttributeText {
    
    var averageMidX: CGFloat {
        guard count > 0 else { return 0 }
        let sum = self.reduce(0, { $0 + $1.text.rect.midX })
        return sum / Double(count)
    }
    
    var attributeDescription: String {
        map{ $0.attribute }.description
    }
}

extension Array where Element == [AttributeText] {
    
    var attributeDescription: String {
        map { $0.map { $0.attribute } }.description
    }
    
    func indexOfSuperset(of array: [AttributeText]) -> Int? {
        let arrayAsSet = Set(array.map { $0.attribute })
        for i in indices {
            let set = Set(self[i].map { $0.attribute })
            if arrayAsSet.isSubset(of: set) {
                return i
            }
        }
        return nil
    }
    
    func indexOfSubset(of array: [AttributeText]) -> Int? {
        let arrayAsSet = Set(array.map { $0.attribute })
        for i in indices {
            let set = Set(self[i].map { $0.attribute })
            if set.isSubset(of: arrayAsSet) {
                return i
            }
        }
        return nil
    }

    func indexOfArrayContainingAnyAttribute(in arrayToCheck: [AttributeText]) -> Int? {
        for i in indices {
            let array = self[i]
            if array.contains(where: { arrayElement in
                arrayToCheck.contains { arrayToCheckElement in
                    arrayToCheckElement.attribute == arrayElement.attribute
                }
            }) {
                return i
            }
        }
        return nil
    }
}

extension Array where Element == RecognizedText {
    var attributeTexts: [RecognizedText] {
        filter { $0.string.containsNutrientAttributes }
    }
    
    var inlineAttributeTexts: [RecognizedText] {
        filter { $0.string.containsInlineNutrients }
    }
}

extension TableClassifier {
    
    var attributeTexts: [RecognizedText] {
        arrayOfRecognizedTexts.reduce([]) { $0 + $1.attributeTexts }
    }
    
    var inlineAttributeTexts: [RecognizedText] {
        arrayOfRecognizedTexts.reduce([]) { $0 + $1.inlineAttributeTexts }
    }
    
    var mostTextsAreInline: Bool {
        var attributes: [Attribute] = []
        var inlineAttributes: [Attribute] = []
        
        /// Go through all recognized texts
        for recognizedTexts in arrayOfRecognizedTexts {
            for text in recognizedTexts {
                
                /// Each time we detect a non-mineral, non-vitamin attribute for the first time—whether inline or not—add it to the `attributes` array
                let detectedAttributes = Attribute.detect(in: text.string)
                for detectedAttribute in detectedAttributes {
                    /// Ignore non-nutrient attributes and energy (because it's usually not inline)
                    guard detectedAttribute.isNutrientAttribute,
                          !detectedAttribute.isVitamin,
                          !detectedAttribute.isMineral,
                          detectedAttribute != .energy
                    else {
                        continue
                    }
                    
                    if !attributes.contains(detectedAttribute) {
                        attributes.append(detectedAttribute)
                    }
                }
                
                /// Each time we detect an inline version of an attribute, add it to the `inlineAttributes` array
                let nutrients = text.string.nutrients
                for nutrient in nutrients {
                    guard nutrient.attribute != .energy,
                          !nutrient.attribute.isVitamin,
                          !nutrient.attribute.isMineral
                    else {
                        continue
                    }

                    if !inlineAttributes.contains(nutrient.attribute) {
                        inlineAttributes.append(nutrient.attribute)
                    }
                }
            }
        }
        
        let ratio = Double(inlineAttributes.count) / Double(attributes.count)
        
        //TODO: Tweak this threshold
        print("🧮 Ratio is: \(ratio)")
        return ratio > 0.75
    }
    
    /// Returns an array of arrays of `AttributeText`s, with each array representing a column of attributes, in the order they appear on the label.
    func getColumnsOfAttributes() -> [[Attribute]]? {
        
        //TODO: Check if most values are inline and if so, return nil
        guard !mostTextsAreInline else {
            return nil
        }
        
        var columns: [[AttributeText]] = []
        
        for recognizedTexts in arrayOfRecognizedTexts {
            for text in recognizedTexts {
                guard Attribute.haveNutrientAttribute(in: text.string) else {
                    continue
                }
                
                /// Go through texts until a nutrient attribute is found
                let columnOfTexts = getColumnOfNutrientLabelTexts(startingFrom: text)
                    .sorted(by: { $0.rect.minY < $1.rect.minY })
                
                guard let column = getUniqueAttributeTextsFrom(columnOfTexts) else {
                    continue
                }

                /// First, make sure the column is at least the threshold of attributes long
                guard column.count >= 3 else {
                    continue
                }
                
                /// Now see if we have any existing columns that is a subset of this column
                if let index = columns.indexOfSubset(of: column) {
                    /// Replace it
                    columns[index] = column
                } else if let _ = columns.indexOfSuperset(of: column) {
                    /// This `column` is a subset of one of the `columns`, so ignore it
                } else if let index = columns.indexOfArrayContainingAnyAttribute(in: column) {
                    /// This `column` has attributes that another added `column has`
                    if columns[index].count < column.count {
                        /// This column has more attributes, so replace the smaller one with it
                        columns[index] = column
                    }
                } else {
                    /// Otherwise, set it as a new column
                    columns.append(column)
                }
            }
        }
        
        /// Sort the columns by the `text.rect.midX` values (so that we get them in the order they appear), and only return the `attribute`s
        let columnsOfAttributes = columns.sorted(by: {
            $0.averageMidX < $1.averageMidX
        }).map {
            $0.map { $0.attribute }
        }
        
        print(columnsOfAttributes)
        return columnsOfAttributes
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
        return attributeTexts.count > 0 ? attributeTexts : nil
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
                guard !text.string.isSkippableTableElement else {
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
                guard !text.string.isSkippableTableElement else {
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
    
    var isSkippableTableElement: Bool {
        guard let attribute = Attribute(fromString: self),
            attribute.isTableAttribute else {
            return false
        }
        return true
    }
    
    var containsNutrientOrTitleAttributes: Bool {
        containsNutrientAttributes || isSkippableTableElement
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

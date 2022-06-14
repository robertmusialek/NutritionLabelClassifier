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
//            guard array.count < self[i].count else {
//                continue
//            }
//
            let set = Set(self[i].map { $0.attribute })
            if arrayAsSet.isSubset(of: set) {
                return i
            }
        }
        return nil
    }
}

extension TableClassifier {
    
    public func getAttributes() -> [[Attribute]]? {
        return []
//        guard let attributeRecognizedTexts = getAttributeRecognizedTexts() else {
//            return []
//        }
//        return getUniqueAttributeTextsFrom(attributeRecognizedTexts)?
//            .map { $0.attribute }
//        ?? []
    }
    
    /// Returns an array of arrays of `AttributeText`s, with each array representing a column of attributes, in the order they appear on the label.
    func getColumnsOfAttributes() -> [[Attribute]]? {
        
        var columns: [[AttributeText]] = []
        
        var startingStrings: [String] = []
        var attributes: [[Attribute]] = []
        
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
//                    print("🔧 ➡️ Starting from: '\(text.string)'")
//                    print("🔧 ✨ \(uniqueAttributes.map { $0.attribute } )")
                }

                startingStrings.append(text.string)
                attributes.append(column.map { $0.attribute })
                
                /// First, make sure the column is at least the threshold of attributes long
                guard column.count > 3 else {
                    continue
                }
                
                /// Now see if we have any existing columns that is a subset of this column
                if let index = columns.indexOfSuperset(of: column) {
                    /// Replace it
                    columns[index] = column
                } else {
                    /// Otherwise, set it as a new column
                    columns.append(column)
                }
            }
        }
        
        var dataFrame = DataFrame()
        dataFrame.append(column: Column(name: "startingStrings", contents: startingStrings))
        dataFrame.append(column: Column(name: "attributes", contents: attributes))
        print(dataFrame)
        
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

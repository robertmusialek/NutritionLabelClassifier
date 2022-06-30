import VisionSugar
import SwiftUI

struct VisionResult {

    var accurateRecognitionWithLanugageCorrection: [RecognizedText]? = nil
    var accurateRecognitionWithoutLanugageCorrection: [RecognizedText]? = nil
    var fastRecognition: [RecognizedText]? = nil
    
    var arrayOfTexts: [[RecognizedText]] {
        var arrays: [[RecognizedText]] = []
        if let array = accurateRecognitionWithLanugageCorrection {
            arrays.append(array)
        }
        if let array = accurateRecognitionWithoutLanugageCorrection {
            arrays.append(array)
        }
        if let array = fastRecognition {
            arrays.append(array)
        }
        return arrays
    }
}

extension VisionResult {
    var mostTextsAreInline: Bool {
        var attributes: [Attribute] = []
        var inlineAttributes: [Attribute] = []
        
        /// Go through all recognized texts
        for recognizedTexts in arrayOfTexts {
            for text in recognizedTexts {
                
                guard !text.string.isSkippableRecognizedText else {
                    continue
                }
                /// Each time we detect a non-mineral, non-vitamin attribute for the first time—whether inline or not—add it to the `attributes` array
                let detectedAttributes = Attribute.detect(in: text.string)
                for detectedAttribute in detectedAttributes {
                    /// Ignore non-nutrient attributes and energy (because it's usually not inline)
                    guard detectedAttribute.isNutrientAttribute,
                          detectedAttribute.isCoreTableNutrient,
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
                          nutrient.attribute.isCoreTableNutrient
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
        return ratio >= 0.75
    }
}

extension Array where Element == RecognizedText {
    func column(startingFrom startingText: RecognizedText, preceding: Bool) -> [RecognizedText] {
        filter {
            $0.isInSameColumnAs(startingText)
            && (preceding ? $0.rect.maxY < startingText.rect.maxY : $0.rect.minY > startingText.rect.minY)
        }.sorted {
//            preceding ? $0.rect.minY > $1.rect.minY : $0.rect.minY < $1.rect.minY
            preceding ? $0.rect.midY > $1.rect.midY : $0.rect.midY < $1.rect.midY
        }
    }
    
    func textsOnSameRow(as text: RecognizedText) -> [RecognizedText] {
        filter {
            let overlapsVertically = $0.rect.minY < text.rect.maxY && $0.rect.maxY > text.rect.minY
            let isOnSameLine = (overlapsVertically && $0.rect.maxX < text.rect.minX)
            return isOnSameLine || $0 == text
        }.sorted {
            $0.rect.minX < $1.rect.minX
        }
    }
}

extension VisionResult {
    
    enum TextSet {
        case accurate
        case accurateWithoutLanguageCorrection
        case fast
    }
    
    func array(for textSet: TextSet) -> [RecognizedText]? {
        switch textSet {
        case .accurate:
            return accurateRecognitionWithLanugageCorrection
        case .accurateWithoutLanguageCorrection:
            return accurateRecognitionWithoutLanugageCorrection
        case .fast:
            return fastRecognition
        }
    }
    
    func column(startingFrom startingText: RecognizedText, preceding: Bool, textSet: TextSet) -> [RecognizedText] {
        guard let array = array(for: textSet) else { return [] }
        return array.column(startingFrom: startingText, preceding: preceding)
    }
    
    func columnOfValueTexts(startingFrom startingText: RecognizedText, preceding: Bool) -> [ValuesText] {
        
        /// Only include texts that are a minimum of 5% overlapping (in the x-axis) with the starting text
        //TODO: Make this a parameter on the column(startingFrom:...) function instead of filtering the values it returns
        let columnOfTexts = column(startingFrom: startingText, preceding: preceding, textSet: .accurate).filter {
            guard let intersectionRatio = startingText.rect.ratioOfXIntersection(with: $0.rect), intersectionRatio >= 0.05 else {
                return false
            }
            return true
        }
        
        var column: [ValuesText] = []
        var discarded: [RecognizedText] = []
        
        /// Now go through the texts
        for text in columnOfTexts {
            
            guard !discarded.contains(text) else {
                continue
            }
            
            /// Disqualify texts that are substantially long. This removes incorrectly read values (usually 0's) that span multiple lines and get read as a completely unrelated number.
            guard !text.rect.isSubstantiallyLong else {
                continue
            }
            
            /// Make sure we don't have a discarded text containing the same string that also overlaps it considerably
            guard !discarded.contains(where: {
                $0.string == text.string
                &&
                $0.rect.overlapsSubstantially(with: text.rect)
            }) else {
                continue
            }

            //TODO: Shouldn't we check all arrays here so that we grab the FastRecognized results that may not have been grabbed as a fallback?
            /// Get texts on same row arranged by their `minX` values
            let textsOnSameRow = columnOfTexts.textsOnSameRow(as: text)

            /// Pick the left most text on the row, making sure it hasn't been discarded
            guard let pickedText = textsOnSameRow.first, !discarded.contains(pickedText) else {
                continue
            }
            discarded.append(contentsOf: textsOnSameRow)

            /// Return nil if any non-skippable texts are encountered
            guard !text.string.isSkippableValueElement else {
                continue
            }

            guard let valuesText = valuesText(for: pickedText) else {
                continue
            }
            
            /// If we picked an alternate overlapping valuesText, make sure that's added to discarded
            if !discarded.contains(where: { $0.id == valuesText.text.id }) {
                discarded.append(valuesText.text)
            }
            
            /// Stop if a second energy value is encountered after a non-energy value has been added—as this usually indicates the bottom of the table where strings containing the representative diet (stating something like `2000 kcal diet`) are found.
            if column.containsValueWithEnergyUnit, valuesText.containsValueWithEnergyUnit,
               let last = column.last, !last.containsValueWithEnergyUnit {
                break
            }

            column.append(valuesText)
        }
        
        return column
    }
    
    func valuesText(for pickedText: RecognizedText) -> ValuesText? {
        guard !pickedText.string.containsServingAttribute, !pickedText.containsHeaderAttribute else {
            return nil
        }
        
        
        /// First try and get a valid `ValuesText` here
        if let valuesText = ValuesText(pickedText), !valuesText.isSingularPercentValue {
            return valuesText
        }
        
        /// If this failed, check the other arrays of the VisionResult by grabbing any texts in those that overlap with this one and happen to have a non-singular percent value within it.
        for overlappingText in alternativeTexts(overlapping: pickedText) {
            guard !overlappingText.string.containsServingAttribute, !overlappingText.containsHeaderAttribute else {
                continue
            }
            if let valuesText = ValuesText(overlappingText), valuesText.isSingularNutritionUnitValue {
                return valuesText
            }
        }
        return nil
    }
    
    /// Be default, we will search the arrays other than `.accurate` as we're assuming that the to be the primary one we're searching through (during which this function is used to find alternatives)
    func alternativeTexts(overlapping text: RecognizedText, in textSets: [TextSet] = [.accurateWithoutLanguageCorrection, .fast]) -> [RecognizedText] {
        var texts: [RecognizedText] = []
        for textSet in textSets {
            guard let array = array(for: textSet) else {
                continue
            }
            for arrayText in array {
                /// Skip any texts that have the same string as the one we're finding alternatives for
                guard arrayText.string != text.string else {
                    continue
                }
                
                //TODO: Use CGRect.overlapsSubstantially(with:) instead
                /// Get the intersection and skip any texts that don't overlap what we're looking for
                let intersection = arrayText.rect.intersection(text.rect)
                guard !intersection.isNull else {
                    continue
                }
                
                /// Get the ratio of the intersection to whichever the smaller of the two rects are, and only add it if it covers at least 90%
                let smallerRect = CGRect.smaller(of: arrayText.rect, and: text.rect)
                let ratioOfIntersectionToSmallerRect = intersection.area / smallerRect.area
                
                if ratioOfIntersectionToSmallerRect > 0.9 {
                    texts.append(arrayText)
                }
            }
        }
        return texts
    }
}

let SubstantialOverlapRatioThreshold = 0.9

extension CGRect {
    
    var isSubstantiallyLong: Bool {
        width/height < 0.5
    }
    
    func overlapsSubstantially(with rect: CGRect) -> Bool {
        guard let ratio = ratioOfIntersection(with: rect) else {
            return false
        }
        return ratio > SubstantialOverlapRatioThreshold
    }

    func ratioOfXIntersection(with rect: CGRect) -> Double? {
        let yNormalizedRect = self.rectWithYValues(of: rect)
        return rect.ratioOfIntersection(with: yNormalizedRect)
    }

    func ratioOfYIntersection(with rect: CGRect) -> Double? {
        let xNormalizedRect = self.rectWithXValues(of: rect)
        return rect.ratioOfIntersection(with: xNormalizedRect)
    }

    func ratioThatIsInline(with rect: CGRect) -> Double? {
        let xNormalizedRect = self.rectWithXValues(of: rect)
        
        let intersection = xNormalizedRect.intersection(rect)
        guard !intersection.isNull else {
            return nil
        }
        
        return intersection.area / area
    }

    func heightThatIsInline(with rect: CGRect) -> Double? {
        let xNormalizedRect = self.rectWithXValues(of: rect)
        let intersection = xNormalizedRect.intersection(rect)
        guard !intersection.isNull else { return nil }
        return intersection.height
    }

    func ratioOfIntersection(with rect: CGRect) -> Double? {
        let intersection = rect.intersection(self)
        guard !intersection.isNull else {
            return nil
        }
        
        /// Get the ratio of the intersection to whichever the smaller of the two rects are, and only add it if it covers at least 90%
        let smallerRect = CGRect.smaller(of: rect, and: self)
        return intersection.area / smallerRect.area
    }
    
    static func smaller(of rect1: CGRect, and rect2: CGRect) -> CGRect {
        if rect1.area < rect2.area {
            return rect1
        } else {
            return rect2
        }
    }
    var area: CGFloat {
        size.width * size.height
    }
}

extension VisionResult {
    func getColumnOfNutrientLabelTexts(startingFrom startingText: RecognizedText) -> [RecognizedText] {
        
        print("Getting column starting from: \(startingText.string)")

        let BoundingBoxMinXDeltaThreshold = 0.20
        var array: [RecognizedText] = [startingText]
        
        for recognizedTexts in arrayOfTexts {
            
            var skipPassUsed = false
            
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
                guard text.string.containsNutrientAttributesOrSkippableTableElements else {
                    if skipPassUsed {
                        print("    ✋🏽 ending search because no nutrient attributes can be detected in string AND skip pass was used")
                        break
                    } else if text.string.terminatesColumnWiseAttributeSearch {
                        print("    ✋🏽 ending search because cannot use skipPass")
                        break
                    } else {
                        print("    ignoring and using up skipPass")
                        skipPassUsed = true
                        continue
                    }
                }
                
                skipPassUsed = false

                /// Skip over title attributes, but don't stop searching because of them
                guard !text.string.isSkippableTableElement else {
                    continue
                }

                /// Insert these into the start of our column of labels as we read them in
                array.insert(text, at: 0)
            }

            /// Reset skipPass
            skipPassUsed = false
            
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
                
                guard text.string.containsNutrientAttributesOrSkippableTableElements else {
                    if skipPassUsed {
                        print("    ✋🏽 ending search because no nutrient attributes can be detected in string AND skip pass was used")
                        break
                    } else if text.string.terminatesColumnWiseAttributeSearch {
                        print("    ✋🏽 ending search because cannot use skipPass")
                        break
                    } else {
                        print("    ignoring and using up skipPass")
                        skipPassUsed = true
                        continue
                    }
                }
                
                skipPassUsed = false
                
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
    
    func getUniqueAttributeTextsFrom(_ texts: [RecognizedText]) -> [AttributeText]? {
        var lastAddedAttribute: Attribute? = nil
        var attributeTexts: [AttributeText] = []
        for text in texts {
            let attributes = Attribute.detect(in: text.string)
            for attribute in attributes {
                /// Make sure each `Attribute` detected in this text hasn't already been added, and is also a nutrient (for edge cases where strings containing both a nutrient and a serving (or other type) of attribute may have been picked up and then the nutrient attribute disregarded
                guard !attributeTexts.contains(where: { $0.attribute.isSameAttribute(as: attribute) }),
                      attribute.isNutrientAttribute
                else { continue }
                
                /// If this is the `nutrientLabelTotal` attribute (where `Total` may come after a nutrient)
                guard attribute != .nutrientLabelTotal else {
                    /// Check if the last attribute appended supports total
                    guard let lastAttributeText = attributeTexts.last, lastAttributeText.attribute.supportsTotalLabel else {
                        continue
                    }
                    
                    /// If it does, add this text to its list of texts so that its considered when finding values in-line with it
                    attributeTexts[attributeTexts.count-1].allTexts.append(text)
                    continue
                }
                
                /// If this is part of the last added attribute, simply append the text to its `allTexts`
                if let index = attributeTexts.firstIndex(where: { $0.attribute == attribute }) {
                    guard let lastAddedAttribute = lastAddedAttribute, lastAddedAttribute == attribute else {
                        continue
                    }
                    attributeTexts[index].allTexts.append(text)
                } else {
                    attributeTexts.append(AttributeText(attribute: attribute,
                                                        text: text,
                                                        allTexts: [text]))
                    lastAddedAttribute = attribute
                }
            }
        }
        return attributeTexts.count > 0 ? attributeTexts : nil
    }
}

extension Attribute {
    var supportsTotalLabel: Bool {
        switch self {
        case .fat, .carbohydrate:
            return true
        default:
            return false
        }
    }
}

import VisionSugar

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

extension VisionResult {
    
    func columnOfValues(startingFrom startingText: RecognizedText, preceding: Bool) -> [ValuesText] {
        
        //TODO: Write this to possibly go through all arrays, or better yet—the actual VisionResult (even if we're just using the first—ie. accurately recognized with language correction), so that it can contextually handle the array of texts without having to assume what they are
        let array = self.arrayOfTexts
        
        let texts = array.first!.filter {
            $0.isInSameColumnAs(startingText)
            && (preceding ? $0.rect.maxY < startingText.rect.maxY : $0.rect.minY > startingText.rect.minY)
        }.sorted {
            preceding ? $0.rect.minY > $1.rect.minY : $0.rect.minY < $1.rect.minY
        }
        
        var valuesTexts: [ValuesText] = []
        var discarded: [RecognizedText] = []
        
        /// Now go through the texts
        for text in texts {

            guard !discarded.contains(text) else {
                continue
            }

            //TODO: Shouldn't we check all arrays here so that we grab the FastRecognized results that may not have been grabbed as a fallback?
            /// Get texts on same row arranged by their `minX` values
            let textsOnSameRow = texts.filter {
                ($0.rect.minY < text.rect.maxY
                && $0.rect.maxY > text.rect.minY
                && $0.rect.maxX < text.rect.minX)
                || $0 == text
            }.sorted {
                $0.rect.minX < $1.rect.minX
            }

            /// Pick the left most text on the row, making sure it isn't
            guard let pickedText = textsOnSameRow.first, !discarded.contains(pickedText) else {
                continue
            }
            discarded.append(contentsOf: textsOnSameRow)

            /// Return nil if any non-skippable texts are encountered
            guard !text.string.isSkippableValueElement else {
                continue
            }

            guard let valuesText = ValuesText(pickedText), !valuesText.isSingularPercentValue else {
                continue
            }
            
            /// Stop if a second energy value is encountered after a non-energy value has been added—as this usually indicates the bottom of the table where strings containing the representative diet (stating something like `2000 kcal diet`) are found.
            if valuesTexts.containsValueWithEnergyUnit, valuesText.containsValueWithEnergyUnit,
               let last = valuesTexts.last, !last.containsValueWithEnergyUnit {
                break
            }

            valuesTexts.append(valuesText)
        }
        
        return valuesTexts
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
        var attributeTexts: [AttributeText] = []
        for text in texts {
            let attributes = Attribute.detect(in: text.string)
            for attribute in attributes {
                /// Make sure each `Attribute` detected in this text hasn't already been added, and is also a nutrient (for edge cases where strings containing both a nutrient and a serving (or other type) of attribute may have been picked up and then the nutrient attribute disregarded
                guard !attributeTexts.contains(where: { $0.attribute == attribute }),
                      !attributeTexts.contains(where: { $0.attribute.isSameAttribute(as: attribute) }),
                      attribute.isNutrientAttribute
                else { continue }
                
                attributeTexts.append(AttributeText(attribute: attribute, text: text))
            }
        }
        return attributeTexts.count > 0 ? attributeTexts : nil
    }
}

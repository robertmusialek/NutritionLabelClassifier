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

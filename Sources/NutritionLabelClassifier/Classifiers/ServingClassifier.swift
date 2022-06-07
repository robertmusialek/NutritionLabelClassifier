import VisionSugar

class ServingClassifier: Classifier {
    
    let recognizedTexts: [RecognizedText]
    let arrayOfRecognizedTexts: [[RecognizedText]]
    var observations: [Observation]

    var pendingObservations: [Observation] = []
    var observationBeingExtracted: Observation? = nil
    var discarded: [RecognizedText] = []

    init(recognizedTexts: [RecognizedText], arrayOfRecognizedTexts: [[RecognizedText]] = [], observations: [Observation]) {
        self.recognizedTexts = recognizedTexts
        self.observations = observations
        self.arrayOfRecognizedTexts = arrayOfRecognizedTexts
    }

    static func observations(from recognizedTexts: [RecognizedText],
                             priorObservations observations: [Observation]) -> [Observation] {
        Self.observations(from: recognizedTexts, arrayOfRecognizedTexts: [], priorObservations: observations)
    }
    
    static func observations(from recognizedTexts: [RecognizedText],
                             arrayOfRecognizedTexts: [[RecognizedText]],
                             priorObservations observations: [Observation]) -> [Observation] {
        ServingClassifier(
            recognizedTexts: recognizedTexts,
            arrayOfRecognizedTexts: arrayOfRecognizedTexts,
            observations: observations).getObservations()
    }

    //MARK: - Helpers
    func getObservations() -> [Observation] {
        for recognizedText in recognizedTexts {
            guard recognizedText.string.containsServingAttribute else {
                continue
            }
            
            extractObservations(of: recognizedText)
            
            /// Process any attributes that were extracted
            for observation in pendingObservations {
                observations.appendIfValid(observation)
            }

            /// Now do an inline search for any attribute that is still being extracted
            if let observation = observationBeingExtracted {
                
                /// Skip attributes that have already been added
                guard !observations.contains(where: { $0.attributeText.attribute == observation.attributeText.attribute }) else {
                    continue
                }

                let didExtractInColumn = extractInColumnObservations(
                    of: recognizedText,
                    for: observation)
                
                if !didExtractInColumn {
                    let _ = extractInlineObservations(of: recognizedText, for: observation)
                }
            }
        }
        return observations
    }
    
    func extractInlineObservations(of recognizedText: RecognizedText, for observation: Observation) -> Bool {
        
        //TODO: Handle array of recognized texts
        /// **Copy across what we're doing here, of:**
        /// - Going through the entire `arrayOfRecognizedTexts` to find matching observations, and not just the array that was passed in
        /// - Make sure we're doing this in other classifiers as well
        /// - See if we can run each classifier once, feeding it the array of recognized texts, and
        ///     - Check if the tests succeed, and if so
        ///     - If this is any faster, by measuring how long it takes
        
        for recognizedTexts in arrayOfRecognizedTexts {
            let inlineTextColumns = recognizedTexts.inlineTextColumns(as: recognizedText, ignoring: discarded)
            for column in inlineTextColumns {

                guard let inlineText = pickInlineText(fromColumn: column, for: observation.attributeText.attribute) else {
                    continue
                }

                guard recognizedText.isNotTooFarFrom(inlineText) else {
                    continue
                }
                
                extractObservations(
                    of: inlineText,
                    startingWithAttributeText: observation.attributeText
                )
                for observation in pendingObservations {
                    observations.appendIfValid(observation)
                }
                if pendingObservations.count > 0 {
                    return true
                }
            }
        }
        return false
    }
    
    func extractInColumnObservations(of recognizedText: RecognizedText, for observation: Observation) -> Bool {
        /// If we've still not found any resulting attributes, look in the next text directly below it
        guard let nextLineText = recognizedTexts.filterSameColumn(as: recognizedText, removingOverlappingTexts: false).first,
            nextLineText.string != "Per 100g",
            !nextLineText.string.matchesRegex("^calories")
        else {
            return false
        }
        extractObservations(
            of: nextLineText,
            startingWithAttributeText: observation.attributeText)
        
        guard pendingObservations.count > 0 else {
            return false
        }
        for observation in pendingObservations {
            observations.appendIfValid(observation)
        }
        return true
    }
    
    func extractObservations(of recognizedText: RecognizedText, startingWithAttributeText startingAttributeText: AttributeText? = nil) {

        let artefacts = recognizedText.servingArtefacts

        let textId = recognizedText.id
        var observations: [Observation] = []
        var extractingAttributes: [AttributeText] = [startingAttributeText].compactMap { $0 }

        for i in artefacts.indices {
            let artefact = artefacts[i]
            if let extractedAttribute = artefact.attribute {
                extractingAttributes = [AttributeText(attribute: extractedAttribute, textId: textId)]
            }
            else if !extractingAttributes.isEmpty {
                for extractingAttribute in extractingAttributes {
                    /// If this attribute supports the serving artefact, add it as an observation
                    if let observation = Observation(attributeText: extractingAttribute, servingArtefact: artefact) {
                        observations.append(observation)
                        
                        /// If we expect attributes following this (for example, `.servingUnit` or `.servingUnitSize` following a `.servingAmount`), assign those as the attributes we're now extracting
                        if let nextAttributes = extractingAttribute.attribute.nextAttributes {
                            extractingAttributes = nextAttributes.map { AttributeText(attribute: $0, textId: textId) }
                        } else {
                            extractingAttributes = []
                        }
                    }
                }
            }
        }
        
        pendingObservations = observations
        if startingAttributeText == nil, let extractingAttribute = extractingAttributes.first {
            observationBeingExtracted = Observation(
                attributeText: extractingAttribute,
                valueText1: nil,
                valueText2: nil)
        }
    }
    
    //MARK: - Helpers
    private func pickInlineText(fromColumn column: [RecognizedText], for attribute: Attribute) -> RecognizedText? {
        
        /// **Heuristic** Remove any texts that contain no artefacts before returning the closest one, if we have more than 1 in a column (see Test Case 22 for how `Alimentaires` and `1.5 g` fall in the same column, with the former overlapping with `Protein` more, and thus `1.5 g` getting ignored
        let column = column.filter {
            $0.servingArtefacts.count > 0
        }
        
        /// As the defaul fall-back, return the first text (ie. the one closest to the observation we're extracted)
        return column.first
    }
}

extension RecognizedText {
    //TODO: Build on this, as we're currently naively checking the horizontal distance
    func isNotTooFarFrom(_ recognizedText: RecognizedText) -> Bool {
        let HorizontalThreshold = 0.3
        let horizontalDistance = recognizedText.boundingBox.minX - boundingBox.maxX
        
        /// Make sure the `RecognizedText` we're checking is to the right of this
        guard horizontalDistance > 0 else {
            return false
        }
        
        /// Returns true if the distance between them is less than the `HorizontalThreshold` value which is in terms of the bounding box. So a value of `0.3` would mean that it's considered "not too far" if it's less than 30% of the width of the bounding box.
        return horizontalDistance < HorizontalThreshold
    }
}

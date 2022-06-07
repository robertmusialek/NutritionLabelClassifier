import Foundation
import VisionSugar

class HeaderClassifier: Classifier {
    
    let recognizedTexts: [RecognizedText]
    var observations: [Observation]

    var pendingObservations: [Observation] = []
    var observationBeingExtracted: Observation? = nil
    var discarded: [RecognizedText] = []

    init(recognizedTexts: [RecognizedText], observations: [Observation]) {
        self.recognizedTexts = recognizedTexts
        self.observations = observations
    }
    
    static func observations(from recognizedTexts: [RecognizedText], priorObservations observations: [Observation]) -> [Observation] {
        HeaderClassifier(recognizedTexts: recognizedTexts, observations: observations).getObservations()
    }

    func getObservations() -> [Observation] {
        /// Get top-most value1 recognized text
        guard let topMostValue1RecognizedText = topMostValue1RecognizedText else {
            //TODO: Try other methods here
            return observations
        }

        /// Get preceding recognized texts in that column
        let result = extractHeaders(inSameColumnAs: topMostValue1RecognizedText)
        guard result.extractedHeader1 else {
            //TODO: Try other methods for header 1
            return observations
        }
        
        /// Make sure we haven't extracted header 2 yet before attempting to do it
        guard !result.extractedHeader2 else {
            return observations
        }
        
        /// If we haven't extracted header 2 yet, and are expecting it (by checking if we have any value 2's)
        guard observations.containsSeparateValue2Observations else {
            return observations
        }
        
        guard let topMostValue2RecognizedText = topMostValue2RecognizedText else {
            //TODO: Try first inline text to header1 that's also in the same column as value 2's
            return observations
        }
        
        let _ = extractHeaders(inSameColumnAs: topMostValue2RecognizedText, forHeaderNumber: 2)

        return observations
    }
    
    func extractHeaders(inSameColumnAs topRecognizedText: RecognizedText, forHeaderNumber headerNumber: Int = 1) -> (extractedHeader1: Bool, extractedHeader2: Bool)
    {
        let inlineTextRows = recognizedTexts.inlineTextRows(as: topRecognizedText, preceding: true, ignoring: discarded)
        var didExtractHeader1: Bool = false
        var didExtractHeader2: Bool = false
        let headerAttribute: Attribute = headerNumber == 1 ? .headerType1 : .headerType2
        
        for row in inlineTextRows {
            for recognizedText in row {
                if !shouldContinueExtractingAfter(
                    extracting: recognizedText,
                    forHeaderAttribute: headerAttribute,
                    headerNumber: headerNumber,
                    didExtractHeader1: &didExtractHeader1,
                    didExtractHeader2: &didExtractHeader2
                ) {
                    break
                }
            }
            if didExtractHeader1 || didExtractHeader2 {
                break
            }
        }
        
        /// If we hadn't extracted a header, try to find a header by merging the two rows at the top
        if !didExtractHeader1 && !didExtractHeader2 {
            for row in inlineTextRows
            {
                let texts = row.reversed().prefix(2)
                guard texts.count == 2 else {
                    continue
                }
                
                let string = texts.map { $0.string }.joined(separator: " ")
                
                guard let firstText = texts.first,
                      string.matchesRegex(HeaderString.Regex.perServingWithSize2),
                      let serving = HeaderText.Serving(string: string),
                      let headerTypeObservation = Observation(
                        headerType: .perServing,
                        for: headerAttribute,
                        attributeTextId: Array(texts)[1].id,
                        recognizedText: firstText
                      )
                else {
                    continue
                }
                observations.append(headerTypeObservation)
                
                processHeaderServing(serving, for: firstText, attributeTextId: Array(texts)[1].id)
                didExtractHeader1 = true
            }
        }
        return (didExtractHeader1, didExtractHeader2)
    }
    
    /// Return value indicates if search should continue
    func shouldContinueExtractingAfter(extracting recognizedText: RecognizedText, forHeaderAttribute headerAttribute: Attribute, headerNumber: Int, didExtractHeader1: inout Bool, didExtractHeader2: inout Bool) -> Bool
    {
        func extractedFirstHeader() {
            if headerNumber == 1 {
                didExtractHeader1 = true
            } else {
                didExtractHeader2 = true
            }
        }
        
        guard let headerString = HeaderString(string: recognizedText.string) else {
            return true
        }
        
        switch headerString {
        case .per100:
            guard let observation = Observation(
                headerType: HeaderType(per100String: recognizedText.string),
                for: headerAttribute,
                recognizedText: recognizedText) else
            {
                return true
            }
            observations.appendIfValid(observation)
            extractedFirstHeader()
        case .perServing:
            guard let observation = Observation(
                headerType: .perServing,
                for: headerAttribute,
                recognizedText: recognizedText) else
            {
                return true
            }
            observations.appendIfValid(observation)
            extractedFirstHeader()
        case .per100AndPerServing:
            guard let firstObservation = Observation(
                headerType: HeaderType(per100String: recognizedText.string),
                for: headerAttribute,
                recognizedText: recognizedText) else
            {
                return true
            }
            observations.appendIfValid(firstObservation)
            extractedFirstHeader()
            
            guard headerNumber == 1, let secondObservation = Observation(
                headerType: .perServing,
                for: .headerType2,
                recognizedText: recognizedText) else
            {
                return true
            }
            observations.appendIfValid(secondObservation)
            didExtractHeader2 = true
        case .perServingAnd100:
            guard let firstObservation = Observation(
                headerType: .perServing,
                for: headerAttribute,
                recognizedText: recognizedText) else
            {
                return true
            }
            observations.appendIfValid(firstObservation)
            extractedFirstHeader()

            guard headerNumber == 1, let secondObservation = Observation(
                headerType: HeaderType(per100String: recognizedText.string),
                for: .headerType2,
                recognizedText: recognizedText) else
            {
                return true
            }
            observations.appendIfValid(secondObservation)
            didExtractHeader2 = true
        }
        
        switch headerString {
        case .perServing(let string), .per100AndPerServing(let string), .perServingAnd100(let string):
            guard let string = string, let serving = HeaderText.Serving(string: string) else {
                return false
            }
            processHeaderServing(serving, for: recognizedText)
        default:
            return false
        }
        if didExtractHeader1 || didExtractHeader2 {
            return false
        } else {
            return true
        }
    }
    
    func processHeaderServing(_ serving: HeaderText.Serving, for recognizedText: RecognizedText, attributeTextId: UUID? = nil) {
        if let amount = serving.amount, let observation = Observation(double: amount, attribute: .headerServingAmount, attributeTextId: attributeTextId, recognizedText: recognizedText) {
            observations.appendIfValid(observation)
        }
        if let unit = serving.unit, let observation = Observation(unit: unit, attribute: .headerServingUnit, attributeTextId: attributeTextId, recognizedText: recognizedText) {
            observations.appendIfValid(observation)
        }
        if let string = serving.unitName, let observation = Observation(string: string, attribute: .headerServingUnitSize, attributeTextId: attributeTextId, recognizedText: recognizedText) {
            observations.appendIfValid(observation)
        }
        guard let equivalentSize = serving.equivalentSize else {
            return
        }
        if let observation = Observation(double: equivalentSize.amount, attribute: .headerServingEquivalentAmount, attributeTextId: attributeTextId, recognizedText: recognizedText) {
            observations.appendIfValid(observation)
        }
        if let unit = equivalentSize.unit, let observation = Observation(unit: unit, attribute: .headerServingEquivalentUnit, attributeTextId: attributeTextId, recognizedText: recognizedText) {
            observations.appendIfValid(observation)
        }
        if let string = equivalentSize.unitName, let observation = Observation(string: string, attribute: .headerServingEquivalentUnitSize, attributeTextId: attributeTextId, recognizedText: recognizedText) {
            observations.appendIfValid(observation)
        }
    }
    
    var topMostValue1RecognizedText: RecognizedText? {
        value1RecognizedTexts.sorted { $0.rect.minY < $1.rect.minY }.first
    }
    
    var value1RecognizedTexts: [RecognizedText] {
        value1RecognizedTextIds.compactMap { id in
            recognizedTexts.first { $0.id == id }
        }
    }
    
    var value1RecognizedTextIds: [UUID] {
        observations.filterContainingSeparateValue1.compactMap { $0.valueText1?.textId }
    }
    
    var topMostValue2RecognizedText: RecognizedText? {
        value2RecognizedTexts.sorted { $0.rect.minY < $1.rect.minY }.first
    }
    
    var value2RecognizedTexts: [RecognizedText] {
        value2RecognizedTextIds.compactMap { id in
            recognizedTexts.first { $0.id == id }
        }
    }
    
    var value2RecognizedTextIds: [UUID] {
        observations.filterContainingSeparateValue2.compactMap { $0.valueText2?.textId }
    }

}

extension HeaderText.Serving {
    
    init?(string: String) {
        let regex = #"^([^\#(Rx.numbers)]*)([\#(Rx.numbers)]+[0-9\/]*)[ ]*(?:of a |)([A-z]+)(?:[^\#(Rx.numbers)]*([\#(Rx.numbers)]+)[ ]*([A-z]+)|).*$"#
        let groups = string.capturedGroups(using: regex)
        
        if groups.count == 3 {
            
            /// ** Heuristic ** If the first match contains `serving`, ignore it and assign the next two array elements as the serving amount and unit
            if !groups[0].isEmpty && !groups[0].contains("serving") {
                
                /// if we have the first group, this indicates that we got the serving unit without an amount, so assume it to be a `1`
                /// e.g. **bowl (125 g)**
                self.init(amount: 1,
                          unitString: groups[0],
                          equivalentSize: EquivalentSize(
                            amountString: groups[1],
                            unitString: groups[2]
                          )
                )
            } else {
                /// 120g
                /// 100ml
                /// 15 ml
                /// 100 ml
                self.init(amountString: groups[1], unitString: groups[2], equivalentSize: nil)
            }
        }
        else if groups.count == 5 {
            /// 74g (2 tubes)
            /// 130g (1 cup)
            /// 125g (1 cup)
            /// 3 balls (36g)
            /// 1/4 cup (30 g)
            self.init(amountString: groups[1],
                      unitString: groups[2],
                      equivalentSize: EquivalentSize(
                        amountString: groups[3],
                        unitString: groups[4]
                      )
            )
        } else {
            return nil
        }
    }
    
    init?(amountString: String, unitString: String, equivalentSize: EquivalentSize?) {
        self.init(amount: Double(fromString: amountString), unitString: unitString, equivalentSize: equivalentSize)
    }
    
    init?(amount: Double?, unitString: String, equivalentSize: EquivalentSize?) {
        self.amount = amount
        let cleaned = unitString.cleanedUnitString
        if let unit = NutritionUnit(string: cleaned) {
            guard unit.isAllowedInHeader else {
                return nil
            }
            self.unit = unit
            unitName = nil
        } else {
            unit = nil
            unitName = cleaned
        }
        self.equivalentSize = equivalentSize
    }

}

extension String {
    var cleanedUnitString: String {
        var string = self
        if string.hasSuffix(" (") {
            string = string.replacingLastOccurrence(of: " (", with: "")
        }
        if string.hasSuffix(")") {
            string = string.replacingLastOccurrence(of: ")", with: "")
        }
        return string.trimmingWhitespaces
    }
}

extension HeaderText.Serving.EquivalentSize {
    
    init?(amountString: String, unitString: String) {
        guard let amount = Double(fromString: amountString) else {
            return nil
        }
        let cleaned = unitString.cleanedUnitString
        self.amount = amount
        if let unit = NutritionUnit(string: cleaned) {
            self.unit = unit
            unitName = nil
        } else {
            unit = nil
            unitName = cleaned
        }
    }
}

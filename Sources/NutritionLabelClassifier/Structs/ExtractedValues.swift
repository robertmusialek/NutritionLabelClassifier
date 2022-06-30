import SwiftUI
import VisionSugar

struct ExtractedValues {
    
    let groupedColumns: [[ValuesTextColumn]]
    
    init(visionResult: VisionResult, extractedAttributes: ExtractedAttributes) {
        
        var columns: [ValuesTextColumn] = []
        
        let start = CFAbsoluteTimeGetCurrent()
        
        for recognizedTexts in [visionResult.accurateRecognitionWithLanugageCorrection ?? []] {
            for text in recognizedTexts {

                print("1️⃣ Getting ValuesTextColumn starting from: '\(text.string)'")

                guard !text.containsServingAttribute else {
                    print("1️⃣   ↪️ Contains serving attribute")
                    continue
                }
                
                guard !text.containsHeaderAttribute else {
                    print("1️⃣   ↪️ Contains header attribute")
                    continue
                }
                
                guard let column = ValuesTextColumn(startingFrom: text, in: visionResult) else {
                    print("1️⃣   Did not get a ValuesTextColumn")
                    continue
                }
                
                print("1️⃣   Got a ValuesTextColumn with: \(column.valuesTexts.count) valuesTexts")
                print("1️⃣   \(column.desc)")
                columns.append(column)
            }
        }

        print("⏱ extracting columns took: \(CFAbsoluteTimeGetCurrent()-start)s")

        let groupedColumns = Self.process(valuesTextColumns: columns, extractedAttributes: extractedAttributes)
        self.groupedColumns = groupedColumns
    }
    
    static func process(valuesTextColumns: [ValuesTextColumn], extractedAttributes: ExtractedAttributes) -> [[ValuesTextColumn]] {

        let start = CFAbsoluteTimeGetCurrent()

        var columns = valuesTextColumns

        columns.removeTextsAboveEnergy(for: extractedAttributes)
        columns.removeTextsBelowLastAttribute(of: extractedAttributes)

        columns.removeDuplicateColumns()
        columns.removeEmptyColumns()
        columns.pickTopColumns(using: extractedAttributes)
        columns.removeColumnsWithServingAttributes()

        columns.removeColumnsWithSingleValuesNotInColumnWithAllOtherSingleValues()
        columns.sort()
        columns.cleanupEnergyValues(using: extractedAttributes)
        columns.removeInvalidColumns()

        columns.removeOverlappingTextsWithSameString()

        columns.removeReferenceColumns()
        
        var groupedColumns = groupByAttributes(columns)
        groupedColumns.removeColumnsInSameColumnAsAttributes(in: extractedAttributes)
        groupedColumns.removeExtraneousColumns()
//        groupedColumns.removeInvalidValueTexts()
         print("⏱ processing columns took: \(CFAbsoluteTimeGetCurrent()-start)s")
        return groupedColumns
    }

    /// - Group columns if `attributeTextColumns.count > 1`
    static func groupByAttributes(_ initialColumnsOfTexts: [ValuesTextColumn]) -> [[ValuesTextColumn]] {
        return [initialColumnsOfTexts]
//        guard let attributeTextColumns = attributeTextColumns else { return [] }
//
//        var columnsOfTexts = initialColumnsOfTexts
//        var groups: [[[RecognizedText]]] = []
//
//        /// For each Attribute Column
//        for i in attributeTextColumns.indices {
//            let attributeTextColumn = attributeTextColumns[i]
//
//            /// Get the minX of the shortest attribute
//            guard let attributeColumnMinX = attributeTextColumn.shortestText?.rect.minX else { continue }
//
//            var group: [[RecognizedText]] = []
//            while group.count < 2 && !columnsOfTexts.isEmpty {
//                let column = columnsOfTexts.removeFirst()
//
//                /// Skip columns that are clearly to the left of this `attributeTextColumn`
//                guard let columnMaxX = column.shortestText?.rect.maxX,
//                      columnMaxX > attributeColumnMinX else {
//                    continue
//                }
//
//                /// If we have another attribute column
//                if i < attributeTextColumns.count - 1 {
//                    /// If we have reached columns that is to the right of it
//                    guard let nextAttributeColumnMinX = attributeTextColumns[i+1].shortestText?.rect.minX,
//                          columnMaxX < nextAttributeColumnMinX else
//                    {
//                        /// Make sure we re-insert the column so that it's extracted by that column
//                        columnsOfTexts.insert(column, at: 0)
//
//                        /// Stop the loop so that the next attribute column is focused on
//                        break
//                    }
//                }
//
//                /// Skip columns that contain all nutrient attributes
//                guard !column.allElementsContainNutrientAttributes else {
//                    continue
//                }
//
//                /// Skip columns that contain all percentage values
//                guard !column.allElementsArePercentageValues else {
//                    continue
//                }
//
//                //TODO: Write this
//                /// If this column has more elements than the existing (first) column and contains any texts belonging to it, replace it
//                if let existing = group.first,
//                    column.count > existing.count,
//                    column.containsTextsFrom(existing)
//                {
//                    group[0] = column
//                } else {
//                    group.append(column)
//                }
//            }
//
//            groups.append(group)
//        }
//
//        return groups
    }
}

extension Array where Element == [ValuesTextColumn] {
    var desc: [[String]] {
        map { $0.desc }
    }
    
    mutating func removeExtraneousColumns() {
        for i in indices {
            let group = self[i]
            guard group.count > 2 else { continue }
            self[i] = group.enumerated().compactMap{ $0.offset < 2 ? $0.element : nil }
        }
    }
    
    mutating func removeColumnsInSameColumnAsAttributes(in extractedAttributes: ExtractedAttributes) {
        /// If there's only column, don't consider this heuristic
        guard totalColumnsCount != 1 else {
            return
        }
        for i in indices {
            guard i < extractedAttributes.attributeTextColumns.count else { continue }
            let attributesRect = extractedAttributes.attributeTextColumns[i].rect
            self[i] = self[i].filter { $0.rect.maxX > attributesRect.maxX }
        }
    }
    
    var totalColumnsCount: Int {
        reduce(0) { $0 + $1.count }
    }
}

extension ValuesTextColumn {
    
    mutating func pickEnergyValueIfMultiplesWithinText(energyPairIndexToExtract index: inout Int, lastMultipleEnergyTextId: inout UUID?) {
        
        for i in valuesTexts.indices {
            let valuesText = valuesTexts[i]
            guard valuesText.containsMultipleEnergyValues else {
                continue
            }
            
            /// If we've encountered a different text to the last one, reset the `energyPairIndexToExtract` variable
            if let textId = lastMultipleEnergyTextId, textId != valuesText.text.id {
                index = 0
            }
            lastMultipleEnergyTextId = valuesTexts[i].text.id
            
            valuesTexts[i].pickEnergyValue(energyPairIndexToExtract: &index)
            break
        }
    }
}

typealias EnergyPair = (kj: Value?, kcal: Value?)

extension Array where Element == Value {

    var energyPairs: [EnergyPair] {
        var pairs: [EnergyPair] = []
        var currentPair = EnergyPair(kj: nil, kcal: nil)
        for value in self {
            if value.unit == .kj {
                guard currentPair.kj == nil else {
                    pairs.append(currentPair)
                    currentPair = EnergyPair(kj: value, kcal: nil)
                    continue
                }
                currentPair.kj = value
            }
            else if value.unit == .kcal {
                guard currentPair.kcal == nil else {
                    pairs.append(currentPair)
                    currentPair = EnergyPair(kj: nil, kcal: value)
                    continue
                }
                currentPair.kcal = value
            }
        }
        pairs.append(currentPair)
        return pairs
    }
}

extension ValuesText {
    
    mutating func pickEnergyValue(energyPairIndexToExtract: inout Int) {
        let energyPairs = values.energyPairs

        guard energyPairIndexToExtract < energyPairs.count else {
            return
        }
        let energyPair = energyPairs[energyPairIndexToExtract]
        energyPairIndexToExtract += 1
        
        //TODO: Make this configurable
        /// We're selecting kj here preferentially
        guard let kj = energyPair.kj else {
            guard let kcal = energyPair.kcal else {
                return
            }
            values = [kcal]
            return
        }
        values = [kj]
    }
    
    var containsMultipleEnergyValues: Bool {
        values.filter({ $0.hasEnergyUnit }).count > 1
    }
}
extension Array where Element == ValuesTextColumn {

    mutating func insertNilForMissingValues() {
        /// Get the column with the largest size as the `referenceColumn`
        /// Now get all the columns excluding the `referenceColumn`, calling it `partialColumns`
        /// For each `partialColumn`
        ///     Get the deltas of the `midY` between each column
        ///     Go through these, comparing them to the deltas of the `midY` of the reference column
        ///     As soon as we determine an anomaly (ie. a value with a statistically significant different),
        ///         Use that to determine the an index missing a value and add it to the array
        ///     After going through all the deltas and determining the empty columns
        ///         Fill them up with `nil` so that they can be determined later via scaling
    }
    
    var hasMismatchingColumnSizes: Bool {
        guard let firstColumnSize = first?.valuesTexts.count else {
            return false
        }
        for column in self.dropFirst() {
            if column.valuesTexts.count != firstColumnSize {
                return true
            }
        }
        return false
    }
    
    mutating func cleanupEnergyValues(using extractedAttributes: ExtractedAttributes) {
        /// If we've got any two sets of energy values (ie. two kcal and/or two kJ values), pick those that that are closer to the energy attribute
        let energyAttribute = extractedAttributes.energyAttributeText
        var extractedEnergyPairs = 0
        var lastMultipleEnergyTextId: UUID? = nil
        for i in indices {
            var column = self[i]
            column.pickEnergyValueIfMultiplesWithinText(energyPairIndexToExtract: &extractedEnergyPairs, lastMultipleEnergyTextId: &lastMultipleEnergyTextId)
            column.removeDuplicateEnergy(using: energyAttribute)
            column.pickEnergyIfMultiplePresent()
            self[i] = column
        }
    }

    mutating func removeColumnsWithServingAttributes() {
        removeAll { $0.containsServingAttribute }
    }
    
    mutating func removeColumnsWithSingleValuesNotInColumnWithAllOtherSingleValues() {
        for i in indices {
            var column = self[i]
            let number = column.numberOfSingleValuesThatAreInColumnWithOtherSingleValues
            let portion = column.portionOfSingleValuesThatAreInColumnWithOtherSingleValues
            print("4️⃣ \(portion) (\(number)/\(column.singleValuesTexts.count)): \(column.desc)")
        }

        removeAll {
            $0.portionOfSingleValuesThatAreInColumnWithOtherSingleValues != 1.0
        }
        
    }
    
    var topMostEnergyValueTextUsingValueUnits: ValuesText? {
        var top: ValuesText? = nil
        for column in self {
            guard let index = column.indexOfFirstEnergyValue else { continue }
            guard let topValuesText = top else {
                top = column.valuesTexts[index]
                continue
            }
            if column.valuesTexts[index].text.rect.minY < topValuesText.text.rect.minY {
                top = column.valuesTexts[index]
            }
        }
        return top
    }
    
    func topMostEnergyValueTextUsingEnergyAttribute(from attributes: ExtractedAttributes) -> ValuesText? {
        guard let energyAttribute = attributes.attributeText(for: .energy) else {
            return nil
        }
        return topMostInlineValuesText(to: energyAttribute.text)
    }
    
    func topMostInlineValuesText(to text: RecognizedText) -> ValuesText? {
        var top: ValuesText? = nil
        for column in self {
            guard let topMostInlineValuesText = column.topMostInlineValuesText(to: text) else {
                continue
            }
            guard let topValuesText = top else {
                top = topMostInlineValuesText
                continue
            }
            if topMostInlineValuesText.text.rect.minY < topValuesText.text.rect.minY {
                top = topMostInlineValuesText
            }
        }
        return top
    }
    
    func topMostEnergyValueText(for attributes: ExtractedAttributes) -> ValuesText? {
        if let top = topMostEnergyValueTextUsingValueUnits {
            return top
        }
        /// If we still haven't got the top-most energy value, use the Energy attribute to find the-most value that is inline with it
        if let top = topMostEnergyValueTextUsingEnergyAttribute(from: attributes) {
            return top
        }
        return nil
    }
    
    mutating func removeOverlappingTextsWithSameString() {
        for i in indices {
            var column = self[i]
            column.removeOverlappingTextsWithSameString()
            self[i] = column
        }
    }
    
    mutating func removeReferenceColumns() {
        removeAll { $0.valuesTexts.containsReferenceEnergyValue }
    }
    
    mutating func removeTextsAboveEnergy(for attributes: ExtractedAttributes) {
        guard let topMostEnergyValueText = topMostEnergyValueText(for: attributes) else {
            return
        }
        
        for i in indices {
            var column = self[i]
            column.removeValueTextsAbove(topMostEnergyValueText.text)
            self[i] = column
        }
    }
    
    mutating func removeInvalidColumns() {
        guard let highestNumberOfRows = sorted(by: {
            $0.valuesTexts.count > $1.valuesTexts.count
        }).first?.valuesTexts.count else {
            return
        }
        
        /// Remove columns with too few rows
        self = filter {
            $0.valuesTexts.count > Int(ceil(0.1 * Double(highestNumberOfRows)))
        }
        
        /// Remove columns that contain all attribute texts
        self = filter { column in
            column.valuesTexts.count > column.valuesTexts.filter { Attribute.detect(in: $0.text.string).count > 0 }.count
        }
    }
    
    mutating func removeTextsBelowLastAttribute(of extractedAttributes: ExtractedAttributes) {
        guard let bottomAttributeText = extractedAttributes.bottomAttributeText else {
            return
        }

        for i in self.indices {
            var column = self[i]
            column.removeValueTextsBelow(bottomAttributeText)
            self[i] = column
        }
    }

    mutating func removeTextsAboveFirstAttribute(of extractedAttributes: ExtractedAttributes) {
        guard let topAttributeText = extractedAttributes.topAttributeText else {
            return
        }

        for i in self.indices {
            var column = self[i]
            column.removeValueTextsAbove(topAttributeText)
            self[i] = column
        }
    }

    mutating func removeDuplicateColumns() {
        self = self.uniqued()
    }
    
    mutating func removeEmptyColumns() {
        removeAll { $0.valuesTexts.count == 0 }
    }
    
    mutating func pickTopColumns(using attributes: ExtractedAttributes) {
        let groups = groupedColumnsOfTexts(for: attributes)
        self = Self.pickTopColumns(from: groups)
    }

    /// - Group columns based on their positions
    mutating func groupedColumnsOfTexts(for attributes: ExtractedAttributes) -> [[ValuesTextColumn]] {
        var groups: [[ValuesTextColumn]] = []
        for column in self {

            var didAdd = false
            for i in groups.indices {
                if column.belongsTo(groups[i], using: attributes) {
                    groups[i].append(column)
                    didAdd = true
                    break
                }
            }

            if !didAdd {
                groups.append([column])
            }
        }
        return groups
    }
    
    /// - Pick the column with the most elements in each group
    static func pickTopColumns(from groupedColumns: [[ValuesTextColumn]]) -> [ValuesTextColumn] {
        var topColumns: [ValuesTextColumn] = []
        for group in groupedColumns {
            guard let top = group.sorted(by: { $0.valuesTexts.count > $1.valuesTexts.count }).first else { continue }
            topColumns.append(top)
        }
        return topColumns
    }
    
    /// - Order columns
    ///     Compare `midX`'s of shortest text from each column
    mutating func sort() {
        sort(by: {
            guard let midX0 = $0.midXOfShortestText, let midX1 = $1.midXOfShortestText else {
                return false
            }
            return midX0 < midX1
        })
    }
}

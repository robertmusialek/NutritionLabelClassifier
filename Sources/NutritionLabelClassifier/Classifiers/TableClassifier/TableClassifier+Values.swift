import Foundation
import VisionSugar
import TabularData
import UIKit

extension Array where Element == [AttributeText] {
    var smallestCount: Int {
        sorted(by: { $0.count < $1.count })
            .first?.count ?? 0
    }
    
    var maximumNumberOfValueColumns: Int {
        count * 2
    }
}


extension Array where Element == [ValueText] {
    var containsValueWithEnergyUnit: Bool {
        contains(where: { $0.containsValueWithEnergyUnit })
    }
}

extension Array where Element == ValueText {
    var containsValueWithEnergyUnit: Bool {
        contains(where: { $0.value.hasEnergyUnit })
    }
}
extension Array where Element == Value {
    var containsValueWithEnergyUnit: Bool {
        contains(where: { $0.hasEnergyUnit } )
    }
}

extension Array where Element == [RecognizedText] {
    
    func extractValueTextsInSameColumn(as recognizedText: RecognizedText,
                                       preceding: Bool = false,
                                       ignoreSingularPercentValues: Bool = true) -> [[ValueText]]
    {
        //TODO: Rewrite this by removing first!
        //Also create test cases for it starting with spicy chips
        let texts = first!.filter {
            $0.isInSameColumnAs(recognizedText)
            && (preceding ? $0.rect.maxY < recognizedText.rect.maxY : $0.rect.minY > recognizedText.rect.minY)
        }.sorted {
            preceding ? $0.rect.minY > $1.rect.minY : $0.rect.minY < $1.rect.minY
        }
        
        /// Now go through the texts
        var valueTexts: [[ValueText]] = []
        var discarded: [RecognizedText] = []
        for text in texts {
            
            guard !discarded.contains(text) else {
                continue
            }
            
            /// Get texts on same row arrange by their `minX` values
            let textsOnSameRow = texts.filter {
                ($0.rect.minY < text.rect.maxY
                && $0.rect.maxY > text.rect.minY
                && $0.rect.maxX < text.rect.minX)
                || $0 == text
            }.sorted {
                $0.rect.minX < $1.rect.minX
            }
            
            guard let pickedText = textsOnSameRow.first,
                  !discarded.contains(pickedText)
            else {
                continue
            }
            discarded.append(contentsOf: textsOnSameRow)
            
            let values = Value.detect(in: pickedText.string)
            /// End the loop if any non-value, non-skippable texts are encountered
            guard values.count > 0 || text.string.isSkippableValueElement else {
                continue
            }
            
            /// Stop if a second energy value is encountered, only after a non-energy value has been added—as this usually indicates the bottom of the table where strings containing the representative diet (stating something like `2000 kcal diet`) are found.
            if valueTexts.containsValueWithEnergyUnit, values.containsValueWithEnergyUnit,
               let last = valueTexts.last, last.contains(where: { !$0.value.hasEnergyUnit }) {
                break
            }

            /// Discard any singular % values
            if values.count == 1, let first = values.first {
                guard first.unit != .p else {
                    continue
                }
            }
            
            valueTexts.append(
                values.map {
                    ValueText(value: $0, text: pickedText)
                }
            )
        }
        
        return valueTexts
    }
}

extension Array where Element == [ValueText] {
    var strings: [[String]] {
        map { $0.map { $0.value.description } }
    }
}

extension TableClassifier {
    
    /// Groups of `ValueText` columns, 1 for each `AttributeText` column
    func extractValueTextColumnGroups() -> [[[ValueText?]]]? {
        
        guard let _ = self.attributeTextColumns else { return nil }
        var columnsOfValueTexts: [[[ValueText]]] = []
        
        for recognizedTexts in [visionResult.accurateRecognitionWithLanugageCorrection ?? []] {
            for text in recognizedTexts {
                //TODO: Make sure text.string also isn't a Serving value (like Serving Size etc)
                guard text.string.containsValues else {
                    continue
                }
                
                let columnOfTexts = getColumnOfValueTexts(startingFrom: text)
//                    .sorted(by: { $0.rect.minY < $1.rect.minY })
                
                columnsOfValueTexts.append(columnOfTexts)
            }
        }
        
        return groupsOfColumns(from: columnsOfValueTexts)
    }

    func groupsOfColumns(from columnsOfValueTexts: [[[ValueText]]]) -> [[[ValueText?]]] {
        
        var columns = columnsOfValueTexts

        removeTextsAboveEnergy(&columns)
        removeTextsBelowLastAttribute(&columns)
        removeDuplicates(&columns)
        pickTopColumns(&columns)
        sort(&columns)
//        let groupedColumnsOfTexts = group(columns)
//        let groupedColumnsOfDetectedValueTexts = groupedColumnsOfDetectedValueTexts(from: groupedColumnsOfTexts)
//
//        var groupedColumnsOfValueTexts = pickValueTexts(from: groupedColumnsOfDetectedValueTexts)
//        insertNilForMissedValues(&groupedColumnsOfValueTexts)
//
//        return groupedColumnsOfValueTexts

        return []
    }
    
    func removeTextsBelowLastAttribute(_ columnsOfTexts: inout [[[ValueText]]]) {
        //TODO-NEXT: Do this after making structs for TextOfValues replacing [ValueText] and ValuesColumn, replacing [[TextOfValues]]
        /// For each `ValuesColumn`
        ///
    }
    
    /// - Remove anything values above energy for each column
    func removeTextsAboveEnergy(_ columnsOfTexts: inout [[[ValueText]]]) {
        for i in columnsOfTexts.indices {
            var column = columnsOfTexts[i]
            guard column.hasValueTextsAboveEnergyValue else { continue }
            column.removeValueTextRowsAboveEnergyValue()
            columnsOfTexts[i] = column
        }
    }
    
    func removeDuplicates(_ columnsOfTexts: inout [[[ValueText]]]) {
        columnsOfTexts = columnsOfTexts.uniqued()
    }
    
    /// - Order columns
    ///     Compare `midX`'s of shortest text from each column
    func sort(_ columnsOfTexts: inout [[[ValueText]]]) {
        columnsOfTexts.sort(by: {
            guard let midX0 = $0.compactMap({ $0.first?.text }).midXOfShortestText,
                    let midX1 = $1.compactMap({ $0.first?.text }).midXOfShortestText else {
                return false
            }
            return midX0 < midX1
        })
    }
    
    /// - Group columns if `attributeTextColumns.count > 1`
    func group(_ initialColumnsOfTexts: [[[ValueText]]]) -> [[[[ValueText]]]] {
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
        return []
    }
    
    //MARK: Helpers
    func getColumnOfValueTexts(startingFrom startingText: RecognizedText) -> [[ValueText]] {

        let startingValueText = Value.detect(in: startingText.string).map { ValueText(value: $0, text: startingText) }
        var array: [[ValueText]] = [startingValueText]

        let valueTextsAbove = visionResult.arrayOfTexts.extractValueTextsInSameColumn(as: startingText, preceding: true).reversed()
        array.insert(contentsOf: valueTextsAbove, at: 0)
        let valueTextsBelow = visionResult.arrayOfTexts.extractValueTextsInSameColumn(as: startingText, preceding: false)
        array.append(contentsOf: valueTextsBelow)
        
//        print("🔢Getting column starting from: \(startingText.string)")
//        print("🔢  ⬆️ textsAbove: \(valueTextsAbove.map { $0.string } )")
//        print("🔢  ⬇️ textsBelow: \(textsBelow.map { $0.string } )")

        return array
    }
    
    //MARK: - Legacy
    func groupsOfColumns(from columnsOfTexts: [[RecognizedText]]) -> [[[ValueText?]]] {
        
        var columns = columnsOfTexts

        /// Process columns
        removeTextsAboveEnergy(&columns)
        removeDuplicates(&columns)
        pickTopColumns(&columns)
        sort(&columns)
        let groupedColumnsOfTexts = group(columns)
        let groupedColumnsOfDetectedValueTexts = groupedColumnsOfDetectedValueTexts(from: groupedColumnsOfTexts)
        
        var groupedColumnsOfValueTexts = pickValueTexts(from: groupedColumnsOfDetectedValueTexts)
        insertNilForMissedValues(&groupedColumnsOfValueTexts)

        return groupedColumnsOfValueTexts
    }
    
    func getColumnOfValueRecognizedTexts(startingFrom startingText: RecognizedText) -> [RecognizedText] {

        let BoundingBoxMaxXDeltaThreshold = 0.05
        
        var array: [RecognizedText] = [startingText]

        print("🔢Getting column starting from: \(startingText.string)")

        /// Now go upwards to get nutrient-attribute texts in same column as it
        let textsAbove: [RecognizedText] = []
//        let textsAbove = visionResult.arrayOfTexts.extractValuesInSameColumn(as: startingText, preceding: true).filter { !$0.string.isEmpty }
//
        print("🔢  ⬆️ textsAbove: \(textsAbove.map { $0.string } )")

        for text in textsAbove {
            print("🔢    Checking: \(text.string)")
            let boundingBoxMaxXDelta = abs(text.boundingBox.maxX - startingText.boundingBox.maxX)
            
            guard boundingBoxMaxXDelta < BoundingBoxMaxXDeltaThreshold else {
                print("🔢    ignoring because boundingBoxMaxXDelta = \(boundingBoxMaxXDelta)")
                continue
            }

            /// Until we reach a non-value-attribute text
            guard text.string.containsNutrientAttributes else {
                print("🔢    ✋🏽 ending search because a string wihtout any values was encountered")
                break
            }

            /// Insert these into the start of our column of labels as we read them in
            array.insert(text, at: 0)
        }

        /// Now do the same thing downwards
//        let textsBelow = visionResult.arrayOfTexts.extractValuesInSameColumn(as: startingText, preceding: false).filter { !$0.string.isEmpty }
        let textsBelow: [RecognizedText] = []
        let valueTextsBelow = visionResult.arrayOfTexts.extractValueTextsInSameColumn(as: startingText, preceding: false)
        
        print("🔢  ⬇️ textsBelow: \(textsBelow.map { $0.string } )")

        for text in textsBelow {
            print("🔢    Checking: \(text.string)")
            let boundingBoxMaxXDelta = abs(text.boundingBox.maxX - startingText.boundingBox.maxX)
            
            guard boundingBoxMaxXDelta < BoundingBoxMaxXDeltaThreshold else {
                print("🔢    ignoring because boundingBoxMaxXDelta = \(boundingBoxMaxXDelta)")
                continue
            }

            guard text.string.containsValues else {
                print("🔢    ✋🏽 ending search because a string without any values was encountered")
                break
            }
            
            array.append(text)
        }

        return array
    }
    
    func removeDuplicates(_ columnsOfTexts: inout [[RecognizedText]]) {
        columnsOfTexts = columnsOfTexts.uniqued()
    }
    
    /// - Remove anything values above energy for each column
    func removeTextsAboveEnergy(_ columnsOfTexts: inout [[RecognizedText]]) {
        for i in columnsOfTexts.indices {
            var column = columnsOfTexts[i]
            guard column.hasTextsAboveEnergyValue else { continue }
            column.removeTextsAboveEnergyValue()
            columnsOfTexts[i] = column
        }
    }
    
    /// - Order columns
    ///     Compare `midX`'s of shortest text from each column
    func sort(_ columnsOfTexts: inout [[RecognizedText]]) {
        columnsOfTexts.sort(by: {
            guard let midX0 = $0.midXOfShortestText, let midX1 = $1.midXOfShortestText else {
                return false
            }
            return midX0 < midX1
        })
    }
    
    /// - Group columns if `attributeTextColumns.count > 1`
    func group(_ initialColumnsOfTexts: [[RecognizedText]]) -> [[[RecognizedText]]] {
        guard let attributeTextColumns = attributeTextColumns else { return [] }
        
        var columnsOfTexts = initialColumnsOfTexts
        var groups: [[[RecognizedText]]] = []
        
        /// For each Attribute Column
        for i in attributeTextColumns.indices {
            let attributeTextColumn = attributeTextColumns[i]
            
            /// Get the minX of the shortest attribute
            guard let attributeColumnMinX = attributeTextColumn.shortestText?.rect.minX else { continue }
            
            var group: [[RecognizedText]] = []
            while group.count < 2 && !columnsOfTexts.isEmpty {
                let column = columnsOfTexts.removeFirst()
                
                /// Skip columns that are clearly to the left of this `attributeTextColumn`
                guard let columnMaxX = column.shortestText?.rect.maxX,
                      columnMaxX > attributeColumnMinX else {
                    continue
                }
                
                /// If we have another attribute column
                if i < attributeTextColumns.count - 1 {
                    /// If we have reached columns that is to the right of it
                    guard let nextAttributeColumnMinX = attributeTextColumns[i+1].shortestText?.rect.minX,
                          columnMaxX < nextAttributeColumnMinX else
                    {
                        /// Make sure we re-insert the column so that it's extracted by that column
                        columnsOfTexts.insert(column, at: 0)
                        
                        /// Stop the loop so that the next attribute column is focused on
                        break
                    }
                }
                
                /// Skip columns that contain all nutrient attributes
                guard !column.allElementsContainNutrientAttributes else {
                    continue
                }

                /// Skip columns that contain all percentage values
                guard !column.allElementsArePercentageValues else {
                    continue
                }

                /// If this column has more elements than the existing (first) column and contains any texts belonging to it, replace it
                if let existing = group.first,
                    column.count > existing.count,
                    column.containsTextsFrom(existing)
                {
                    group[0] = column
                } else {
                    group.append(column)
                }
            }
            
            groups.append(group)
        }
        
        return groups
    }
    
    func groupedColumnsOfDetectedValueTexts(from groupedColumnsOfTexts: [[[RecognizedText]]]) -> [[[[ValueText]]]] {
        groupedColumnsOfTexts.map { group in
            group.map { column in
                column.map { text in
                    Value.detect(in: text.string)
                        .map { value in
                            ValueText(value: value, text: text)
                        }
                }
            }
        }
    }
    
    func pickValueTexts(from groupedColumnsOfDetectedValueTexts: [[[[ValueText]]]]) -> [[[ValueText?]]] {
        for group in groupedColumnsOfDetectedValueTexts {
            for column in group {
                for valueTexts in column {
                    if valueTexts.count > 1 {
                        print("🔥 \(valueTexts)")
                    }
                    for valueText in valueTexts {
                        
                    }
                }
            }
        }
        return []
    }
    
    /// - Insert `nil`s wherever values failed to be recognized
    ///     Do this if we have a mismatch of element counts between columns
    func insertNilForMissedValues(_ groupedColumnsOfValueTexts: inout [[[ValueText?]]]) {
        
    }
}

extension Array where Element == ValueText {
    var minX: CGFloat? {
        map { $0.text.rect.minX }.sorted(by: { $0 < $1 }).first
    }
    var maxX: CGFloat? {
        map { $0.text.rect.maxX }.sorted(by: { $0 > $1 }).first
    }
    var shortestText: RecognizedText? {
        map { $0.text }.shortestText
    }
}

extension Array where Element == RecognizedText {
    var minX: CGFloat? {
        map { $0.rect.minX }.sorted(by: { $0 < $1 }).first
    }
    var maxX: CGFloat? {
        map { $0.rect.maxX }.sorted(by: { $0 > $1 }).first
    }
    var allElementsContainNutrientAttributes: Bool {
        allSatisfy { $0.string.containsNutrientAttributes }
    }
    
    var allElementsArePercentageValues: Bool {
        allSatisfy { $0.string.isPercentageValue }
    }
    
    func containsTextsFrom(_ array: [RecognizedText]) -> Bool {
        contains { array.contains($0) }
    }
}

extension Array where Element == AttributeText {
    var minX: CGFloat? {
        map { $0.text.rect.minX }.sorted(by: { $0 < $1 }).first
    }
    var maxX: CGFloat? {
        map { $0.text.rect.maxX }.sorted(by: { $0 > $1 }).first
    }
    
    var shortestText: RecognizedText? {
        map { $0.text }.shortestText
    }
}

extension Array where Element == [[[ValueText]]] {
    var descriptions: [[[[String]]]] {
        map { $0.map { $0.map { $0.map { $0.description } } } }
    }
}

extension TableClassifier {
    func pickTopColumns(_ columnsOfTexts: inout [[[ValueText]]]) {
        let groupedColumnsOfTexts = groupedColumnsOfTexts(from: columnsOfTexts)
        columnsOfTexts = pickTopColumns(from: groupedColumnsOfTexts)
    }

    /// - Pick the column with the most elements in each group
    func pickTopColumns(from groupedColumnsOfTexts: [[[[ValueText]]]]) -> [[[ValueText]]] {
        var topColumns: [[[ValueText]]] = []
        for group in groupedColumnsOfTexts {
            guard let top = group.sorted(by: { $0.count > $1.count }).first else { continue }
            topColumns.append(top)
        }
        return topColumns
    }
    
    /// - Group columns based on their positions
    func groupedColumnsOfTexts(from columnsOfTexts: [[[ValueText]]]) -> [[[[ValueText]]]] {
        var groups: [[[[ValueText]]]] = []
        for column in columnsOfTexts {

            var didAdd = false
            for i in groups.indices {
                //TODO-NEXT: Belongs to needs to be modified to recognize columns in spicy chips
                if column.belongsTo(groups[i]) {
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
}

extension TableClassifier {
    func pickTopColumns(_ columnsOfTexts: inout [[RecognizedText]]) {
        let groupedColumnsOfTexts = groupedColumnsOfTexts(from: columnsOfTexts)
        columnsOfTexts = pickTopColumns(from: groupedColumnsOfTexts)
    }

    /// - Pick the column with the most elements in each group
    func pickTopColumns(from groupedColumnsOfTexts: [[[RecognizedText]]]) -> [[RecognizedText]] {
        var topColumns: [[RecognizedText]] = []
        for group in groupedColumnsOfTexts {
            guard let top = group.sorted(by: { $0.count > $1.count }).first else { continue }
            topColumns.append(top)
        }
        return topColumns
    }
    
    /// - Group columns based on their positions
    func groupedColumnsOfTexts(from columnsOfTexts: [[RecognizedText]]) -> [[[RecognizedText]]] {
        var groups: [[[RecognizedText]]] = []
        for column in columnsOfTexts {
            
            var didAdd = false
            for i in groups.indices {
                if column.belongsTo(groups[i]) {
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
}

/// Array of Groups
extension Array where Element == [[RecognizedText]] {
    var strings: [[[String]]] {
        map { $0.strings }
    }
}

/// Group
extension Array where Element == [RecognizedText] {
    var strings: [[String]] {
        map { $0.strings }
    }
    
    var shortestText: RecognizedText? {
        let shortestTexts = compactMap { $0.shortestText }
        return shortestTexts.sorted(by: { $0.rect.width < $1.rect.width }).first
    }
}

extension Array where Element == [[ValueText]] {
    var shortestText: RecognizedText? {
        let shortestTexts = compactMap { $0.compactMap { $0.first?.text }.shortestText }
        return shortestTexts.sorted(by: { $0.rect.width < $1.rect.width }).first
    }
}

extension Array where Element == [ValueText] {
    /// Use `midX` of shortest text, checking if it lies within the shortest text of any column in each group
    func belongsTo(_ group: [[[ValueText]]]) -> Bool {
        guard let midX = self.compactMap({ $0.first?.text }).midXOfShortestText,
              let shortestText = group.shortestText
        else {
            return false
        }
        
        return midX >= shortestText.rect.minX && midX <= shortestText.rect.maxX
    }
}

/// Column
extension Array where Element == RecognizedText {
    
    var strings: [String] {
        map { $0.string }
    }
    /// Use `midX` of shortest text, checking if it lies within the shortest text of any column in each group
    func belongsTo(_ group: [[RecognizedText]]) -> Bool {
        guard let midX = self.midXOfShortestText,
              let shortestText = group.shortestText
        else {
            return false
        }
        
        return midX >= shortestText.rect.minX && midX <= shortestText.rect.maxX
    }
    
    var midXOfShortestText: CGFloat? {
        shortestText?.rect.midX
    }
    
    var shortestText: RecognizedText? {
        sorted(by: { $0.rect.width < $1.rect.width }).first
    }

    mutating func removeTextsAboveEnergyValue() {
        guard let index = indexOfFirstEnergyValue else { return }
        removeFirst(index)
    }
    
    var indexOfFirstEnergyValue: Int? {
        for i in indices {
            if self[i].containsEnergyValue {
                return i
            }
        }
        return nil
    }
    
    var hasTextsAboveEnergyValue: Bool {
        /// Return false if we didn't detect an energy value
        guard let index = indexOfFirstEnergyValue else { return false }
        /// Return true if its not the first element
        return index != 0
    }
}

extension Array where Element == [ValueText] {
    mutating func removeValueTextRowsAboveEnergyValue() {
        guard let index = indexOfFirstEnergyValue else { return }
        removeFirst(index)
    }
    
    var indexOfFirstEnergyValue: Int? {
        for i in indices {
            if self[i].containsValueWithEnergyUnit {
                return i
            }
        }
        return nil
    }
    
    var hasValueTextsAboveEnergyValue: Bool {
        /// Return false if we didn't detect an energy value
        guard let index = indexOfFirstEnergyValue else { return false }
        /// Return true if its not the first element
        return index != 0
    }
}

extension RecognizedText {
    var containsEnergyValue: Bool {
        let values = Value.detect(in: self.string)
        return values.contains(where: { $0.hasEnergyUnit })
    }
}

//MARK: - Heuristics
extension TableClassifier {
    func chooseEnergyValues(_ columns: inout [[ValueText]]) {
        for i in columns.indices {
            var column = columns[i]
            if column.containsTwoEnergyValues {
                chooseEnergyValues(&column)
                columns[i] = column
            }
        }
    }
    
    func chooseEnergyValues(_ column: inout [ValueText]) {
        /// Make sure the column contains two energy values
        guard column.containsTwoEnergyValues else {
            return
        }
        
        /// Grab the index of the kJ `ValueText`
        guard let index = column.firstIndex(where: { $0.value.unit == .kj }) else {
            return
        }
        
        /// Remove it
        let _ = column.remove(at: index)
    }
}

//MARK: - Extensions

extension Value {
    /// Detects `Value`s in a provided `string` in the order that they appear
    static func detect(in string: String) -> [Value] {
        var array: [(value: Value, positionOfMatch: Int)] = []
        print("🔢      👁 detecting values in: \(string)")

        let regex = #"([0-9.]+[ ]*(?:\#(Value.Regex.units)|))"#
        if let matches = matches(for: regex, in: string), !matches.isEmpty {
            
            for match in matches {
                guard let value = Value(fromString: match.string) else {
                    print("🔢      👁   - '\(match.string)' @ \(match.position): ⚠️ Couldn't get value")
                    continue
                }
                print("🔢      👁   - '\(match.string)' @ \(match.position): \(value.description)")
                array.append((value, match.position))
            }
        }
        
        array.sort(by: { $0.positionOfMatch < $1.positionOfMatch })
        return array.map { $0.value }
    }
    
    static func haveValues(in string: String) -> Bool {
        detect(in: string).count > 0
    }
}

extension Array where Element == ValueText {
    
    var containsTwoEnergyValues: Bool {
        contains(where: { $0.value.unit == .kj })
        &&
        contains(where: { $0.value.unit == .kcal })
    }
    
    var averageMidX: CGFloat {
        guard count > 0 else { return 0 }
        let sum = self.reduce(0, { $0 + $1.text.rect.midX })
        return sum / Double(count)
    }
}

extension Array where Element == [[Value?]] {
    var valuesGroupDescription: String {
        var description = "{"
        for group in self {
            description += "("
            for column in group {
                description += "["
                for value in column {
                    if let value = value {
                        description += "\(value.description), "
                    } else {
                        description += "nil, "
                    }
                }
                description = description.replacingLastOccurrence(of: ", ", with: "")
                description += "]"
            }
            description += ")"
        }
        description += "}"
        return description
    }
}

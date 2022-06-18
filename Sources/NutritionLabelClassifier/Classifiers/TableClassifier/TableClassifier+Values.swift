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

extension TableClassifier {
    
    /// Groups of `ValueText` columns, 1 for each `AttributeText` column
    func extractValueTextColumnGroups() -> [[[ValueText?]]]? {
        
        guard let attributeTextColumns = self.attributeTextColumns else {
            return nil
        }
        
        var groups: [[[ValueText?]]] = []
        
        var columnsOfTexts: [[RecognizedText]] = []
        
        for recognizedTexts in [visionResult.accurateRecognitionWithLanugageCorrection ?? []] {
            for text in recognizedTexts {
                guard text.string.containsValues else {
                    continue
                }
                
                let columnOfTexts = getColumnOfValueRecognizedTexts(startingFrom: text)
                    .sorted(by: { $0.rect.minY < $1.rect.minY })
                
                columnsOfTexts.append(columnOfTexts)
            }
        }
        
        return groupsOfColumns(from: columnsOfTexts)
    }
    
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
    
    func removeDuplicates(_ columnsOfTexts: inout [[RecognizedText]]) {
        columnsOfTexts = columnsOfTexts.uniqued()
    }
    
    //MARK: Helpers
    func getColumnOfValueRecognizedTexts(startingFrom startingText: RecognizedText) -> [RecognizedText] {

        let BoundingBoxMaxXDeltaThreshold = 0.05
        
        var array: [RecognizedText] = [startingText]

        print("🔢Getting column starting from: \(startingText.string)")

        //TODO: Remove using only first array of texts
        for recognizedTexts in [visionResult.accurateRecognitionWithLanugageCorrection ?? []] {
            
            /// Now go upwards to get nutrient-attribute texts in same column as it
            let textsAbove = recognizedTexts.filterSameColumn(as: startingText, preceding: true, removingOverlappingTexts: false).filter { !$0.string.isEmpty }.reversed()
            
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
            let textsBelow = recognizedTexts.filterSameColumn(as: startingText, preceding: false, removingOverlappingTexts: false).filter { !$0.string.isEmpty }
            
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
        }

        return array
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
        
        /// For each Attribute Column
        for attributeTextColumn in attributeTextColumns {
            
            /// Get the minX
            guard let minX = attributeTextColumn.minX else { continue }
            
            var numberOfGroupedColumns = 0
            while numberOfGroupedColumns != 2 && !columnsOfTexts.isEmpty {
                let nextColumn = columnsOfTexts.removeFirst()
                
                guard let nextColumnMaxX = nextColumn.maxX,
                      let attributeColumnMinX = attributeTextColumn.minX,
                      nextColumnMaxX > attributeColumnMinX else {
                    continue
                }
            }
            
        }
        //TODO: Handle attributeTextColumns with count > 1
        ///     Compare `minX` of shortest text from each value-column to `minX` of shortest attribute in each attribute-column
        return []
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

}

extension Array where Element == RecognizedText {
    var minX: CGFloat? {
        map { $0.rect.minX }.sorted(by: { $0 < $1 }).first
    }
    var maxX: CGFloat? {
        map { $0.rect.maxX }.sorted(by: { $0 > $1 }).first
    }

}

extension Array where Element == AttributeText {
    var minX: CGFloat? {
        map { $0.text.rect.minX }.sorted(by: { $0 < $1 }).first
    }
    var maxX: CGFloat? {
        map { $0.text.rect.maxX }.sorted(by: { $0 > $1 }).first
    }
}

extension Array where Element == [[[ValueText]]] {
    var descriptions: [[[[String]]]] {
        map { $0.map { $0.map { $0.map { $0.description } } } }
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

import Foundation
import VisionSugar
import TabularData
import UIKit

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
}

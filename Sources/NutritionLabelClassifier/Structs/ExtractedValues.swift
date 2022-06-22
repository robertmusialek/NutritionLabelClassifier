import SwiftUI
import VisionSugar

struct ExtractedValues {
    
    /// Groups of `ValueText` columns, 1 for each `AttributeText` column
    let valueTextColumnGroups: [[[ValueText?]]]
    
    init(visionResult: VisionResult, extractedAttributes: ExtractedAttributes) {
        
        var columns: [ValuesTextColumn] = []
        
        for recognizedTexts in [visionResult.accurateRecognitionWithLanugageCorrection ?? []] {
            for text in recognizedTexts {

                print("1️⃣ Getting ValuesTextColumn starting from: '\(text.string)'")

                guard !text.containsServingAttribute else {
                    print("1️⃣   ↪️ Contains serving attribute")
                    continue
                }
                
                guard let column = ValuesTextColumn(startingFrom: text, in: visionResult) else {
                    print("1️⃣   ❌ Did not get a ValuesTextColumn")
                    continue
                }
                print("1️⃣   Got a ValuesTextColumn with: \(column.valuesTexts.count) valuesTexts")
                columns.append(column)
            }
        }
        
        self.valueTextColumnGroups = Self.group(valuesTextColumns: columns, extractedAttributes: extractedAttributes)
    }
    
    static func group(valuesTextColumns: [ValuesTextColumn], extractedAttributes: ExtractedAttributes) -> [[[ValueText?]]] {
         
        var columns = valuesTextColumns

        columns.removeTextsAboveEnergy()
        columns.removeTextsBelowLastAttribute(extractedAttributes: extractedAttributes)
        columns.removeDuplicateColumns()
        columns.pickTopColumns()
        columns.removeEmptyColumns()
        columns.removeColumnsWithServingAttributes()
        columns.sort()
        
        //TODO-NEXT 0: Get the missing 5g by considering other recognized texts
        
        //TODO-NEXT 1:
//        let groupedColumnsOfTexts = group(columns)
//        let groupedColumnsOfDetectedValueTexts = groupedColumnsOfDetectedValueTexts(from: groupedColumnsOfTexts)
//
//        var groupedColumnsOfValueTexts = pickValueTexts(from: groupedColumnsOfDetectedValueTexts)
//        insertNilForMissedValues(&groupedColumnsOfValueTexts)
//
//        return groupedColumnsOfValueTexts

        return []
    }
    
    /// - Remove anything values above energy for each column
}

extension Array where Element == ValuesTextColumn {
    mutating func removeColumnsWithServingAttributes() {
        removeAll { $0.containsServingAttribute }
    }
    
    mutating func removeTextsAboveEnergy() {
        for i in indices {
            var column = self[i]
            guard column.hasValuesAboveEnergyValue else { continue }
            column.removeValuesTextsAboveEnergy()
            self[i] = column
        }
    }
    
    mutating func removeTextsBelowLastAttribute(extractedAttributes: ExtractedAttributes) {
        guard let bottomAttributeText = extractedAttributes.bottomAttributeText else {
            return
        }

        for i in self.indices {
            var column = self[i]
            column.removeValueTextsBelowAttributeText(bottomAttributeText)
            self[i] = column
        }
    }

    mutating func removeDuplicateColumns() {
        self = self.uniqued()
    }
    
    mutating func removeEmptyColumns() {
        removeAll { $0.valuesTexts.count == 0 }
    }
    
    mutating func pickTopColumns() {
        let groups = groupedColumnsOfTexts()
        self = Self.pickTopColumns(from: groups)
    }

    /// - Group columns based on their positions
    mutating func groupedColumnsOfTexts() -> [[ValuesTextColumn]] {
        var groups: [[ValuesTextColumn]] = []
        for column in self {

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
    
    /// - Group columns if `attributeTextColumns.count > 1`
    static func group(_ initialColumnsOfTexts: [[[ValueText]]]) -> [[[[ValueText]]]] {
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
}

import SwiftUI
import VisionSugar
import TabularData

struct ExtractedColumn {
    
    var rows: [ExtractedRow]
    
    init(attributesColumn: [AttributeText], valueColumns: [ValuesTextColumn]) {
        self.rows = attributesColumn.extractedRows(using: valueColumns)
        
        insertNilValues()
        
        print("We here")
    }
    
    mutating func insertNilValues() {
        for column in 0..<(self.rows.first?.valuesTexts.count ?? 0) {
            assignNilToReusedValuesTexts(forColumn: column)
        }
    }

    var dataFrame: DataFrame {
        var dataFrame = DataFrame()
        let attributeColumn = Column(name: "attribute", contents: rows.map { $0.attributeText.attribute.rawValue })
        dataFrame.append(column: attributeColumn)
        let value1Column = Column(name: "value1", contents: rows.map { $0.valuesTexts[0] })
        dataFrame.append(column: value1Column)
        
        if rows.first?.valuesTexts.count == 2 {
            let value2Column = Column(name: "value2", contents: rows.map { $0.valuesTexts[1] })
            dataFrame.append(column: value2Column)
            let ratioColumn = Column(name: "ratio", contents: rows.map { $0.ratioColumn1To2 })
            dataFrame.append(column: ratioColumn)
        }
        return dataFrame
    }
    
    var values1Rect: CGRect? {
        let valuesTexts = rows.compactMap { $0.valuesTexts.first ?? nil }
        return valuesTexts.rectOfSingleValues
    }
    var values2Rect: CGRect? {
        guard rows.first?.valuesTexts.count == 2 else { return nil }
        let valuesTexts = rows.compactMap { $0.valuesTexts[1] ?? nil }
        return valuesTexts.rectOfSingleValues
    }
    
    var columnRects: (CGRect?, CGRect?) {
        (values1Rect, values2Rect)
    }
}

extension Array where Element == ValuesText {
    var rectOfSingleValues: CGRect? {
        var rect: CGRect? = nil
        for valuesText in self {
            /// Only use single-valued `ValuesText`s to calculate the rect
            guard valuesText.values.count == 1 else {
                continue
            }
            guard let unionRect = rect else {
                rect = valuesText.text.rect
                continue
            }
            rect = unionRect.union(valuesText.text.rect)
        }
        return rect
    }
}
extension ExtractedColumn {
    mutating func assignNilToReusedValuesTexts(forColumn column: Int) {
        var dict: [ValuesText: (attributeText: AttributeText, index: Int)] = [:]
        for i in rows.indices {
            let row = rows[i]
            guard let valuesText = row.valuesTexts[column] else { continue }
            guard let previousTuple = dict[valuesText] else {
                dict[valuesText] = (row.attributeText, i)
                continue
            }
            
            //TODO: NEXT!
            // AttributeText needs to be modified so that it can have a group of `RecognizedText` objects associated with it
            // Do this without break
            
            
            /// We've encountered the same `ValuesText` again
            
            let previousDistance = previousTuple.attributeText.yDistanceTo(valuesText: valuesText)
            let distance = row.attributeText.yDistanceTo(valuesText: valuesText)
            
            /// If the distance to its previous `attributeText` is greater than to this one, set that `ExtractedRow` to nil
            if distance < previousDistance {
                rows[previousTuple.index].valuesTexts[column] = nil
                dict[valuesText] = (row.attributeText, i)
            } else {
                rows[i].valuesTexts[column] = nil
            }
        }
    }
}

extension Array where Element == AttributeText {

    func extractedRowsAfterInsertingNilInSingleMissingValuesPlace(using valueColumns: [ValuesTextColumn]) -> [ExtractedRow] {
        
        /// First create the empty rows with the attributes in order
        var rows: [ExtractedRow] = map { ExtractedRow(attributeText: $0, valuesTexts: [nil, nil]) }
        
        /// Then for each each column
        for columnIndex in valueColumns.indices {
            let column = valueColumns[columnIndex]
            
            /// If the count matches, simply append the values
            guard column.valuesTexts.count != rows.count else {
                column.valuesTexts.indices.forEach { rowIndex in
                    let valueText = column.valuesTexts[rowIndex]
                    if columnIndex == 0 {
                        rows[rowIndex].valuesTexts[0] = valueText
                    } else {
                        rows[rowIndex].valuesTexts[1] = valueText
                    }
                }
                continue
            }
            
            //TODO: Support multiple nil values by changing this to a count instead
            var nilAdded = false
            
            /// Otherwise, go through their values
            for rowIndex in rows.indices {
                
                let row = rows[rowIndex]
                let attributeText = row.attributeText

                if !nilAdded {
                    /// Checking that each successive item is the closest (overlapping) text
                    guard let closest = column.valuesTexts.closestValueText(to: attributeText, requiringOverlap: true),
                          closest.text.id == column.valuesTexts[rowIndex].text.id
                    else {
                        /// As soon as we reach one that fails this requirement, insert nil in its place
                        if columnIndex == 0 {
                            rows[rowIndex].valuesTexts[0] = nil
                        } else {
                            rows[rowIndex].valuesTexts[1] = nil
                        }
                        nilAdded = true
                        continue
                    }
                }
                
                let valueText = column.valuesTexts[nilAdded ? rowIndex - 1 : rowIndex]
                /// Otherwise, business as usual—keep appending the rows
                if columnIndex == 0 {
                    rows[rowIndex].valuesTexts[0] = valueText
                } else {
                    rows[rowIndex].valuesTexts[1] = valueText
                }
            }
        }
        
        return rows
    }
    
    func extractedRowsWithMissingValues(using valueColumns: [ValuesTextColumn]) -> [ExtractedRow] {
        var rows: [ExtractedRow] = []
        for i in indices {
            let attributeText = self[i]
            var valuesTexts: [ValuesText?] = []
            
            for column in valueColumns {
                guard let closest = column.valuesTexts.closestValueText(to: attributeText) else {
                    valuesTexts.append(nil)
                    continue
                }
                valuesTexts.append(closest)
            }
            let row = ExtractedRow(attributeText: attributeText, valuesTexts: valuesTexts)
            rows.append(row)
        }
        return rows
    }
    
    func extractedRows(using valueColumns: [ValuesTextColumn]) -> [ExtractedRow] {
        /// If we have a common count and it matches the count of attributes, go ahead and map them 1-1
        if let commonCount = valueColumns.commonCount, commonCount == self.count {
            return indices.map { i in
                ExtractedRow(attributeText: self[i],
                             valuesTexts: valueColumns.map { $0.valuesTexts[i] }
                )
            }
        }
        
        /// Special case where we may have only 1 value missing. If either side is short by just 1 value from the attribute count (**possibly increase this and handle greater missing values later**)—then go through the column(s) that's short until we hit the first value that's not inline with an the expected attribute—and insert nil there, and then continue adding the rest.
        if valueColumns.missingOnlyOneValue(forAttributeCount: self.count) {
            return extractedRowsAfterInsertingNilInSingleMissingValuesPlace(using: valueColumns)
        }
        
        /// As a fallback—map rows to attributes based on how in-line they are
        return extractedRowsWithMissingValues(using: valueColumns)
    }
}


extension Array where Element == ValuesTextColumn {
    func missingOnlyOneValue(forAttributeCount count: Int) -> Bool {
        allSatisfy({ column in
            column.valuesTexts.count == count
            || column.valuesTexts.count == count - 1
        })
    }
    
    var commonCount: Int? {
        var count: Int? = nil
        for column in self {
            guard let currentCount = count else {
                count = column.valuesTexts.count
                continue
            }
            guard currentCount == column.valuesTexts.count else {
                return nil
            }
        }
        return count
    }
}

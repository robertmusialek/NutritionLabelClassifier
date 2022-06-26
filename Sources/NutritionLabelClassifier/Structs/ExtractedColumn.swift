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
        guard let commonCount = valueColumns.commonCount, commonCount == self.count else {
            return extractedRowsWithMissingValues(using: valueColumns)
        }
        return indices.map { i in
            ExtractedRow(attributeText: self[i],
                         valuesTexts: valueColumns.map { $0.valuesTexts[i] }
            )
        }
    }
}


extension Array where Element == ValuesTextColumn {
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

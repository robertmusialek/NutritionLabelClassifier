import SwiftUI
import VisionSugar

struct ExtractedColumn {
    
    var rows: [ExtractedRow]
    
    init(attributesColumn: [AttributeText], valueColumns: [ValuesTextColumn]) {
        self.rows = attributesColumn.extractedRows(using: valueColumns)
        
        for column in 0..<(self.rows.first?.valuesTexts.count ?? 0) {
            assignNilToReusedValuesTexts(forColumn: column)
        }
        
        print("We here")
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
            
            let previousDistance = valuesText.text.rect.yDistanceToTopOf(previousTuple.attributeText.text.rect)
            let distance = valuesText.text.rect.yDistanceToTopOf(row.attributeText.text.rect)
            
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
                guard let closest = column.valuesTexts.closestValueText(to: attributeText.text) else {
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

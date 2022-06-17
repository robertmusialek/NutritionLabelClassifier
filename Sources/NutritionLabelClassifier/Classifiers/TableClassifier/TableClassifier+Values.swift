import Foundation
import VisionSugar
import TabularData
import UIKit

extension Array where Element == [AttributeText] {
    var smallestCount: Int {
        sorted(by: { $0.count < $1.count })
            .first?.count ?? 0
    }
}

extension TableClassifier {
    
    /// Groups of `ValueText` columns, 1 for each `AttributeText` column
    func extractValueTextColumnGroups() -> [[[ValueText?]]]? {
        
        guard let attributeTextColumns = self.attributeTextColumns else {
            return nil
        }
        
        var groups: [[[ValueText?]]] = []
        
        var columns: [[ValueText]] = []
        
        for recognizedTexts in [visionResult.accurateRecognitionWithLanugageCorrection ?? []] {
            for text in recognizedTexts {
                guard let value = Value(fromString: text.string) else {
                    continue
                }
                let startingValueText = ValueText(value: value, text: text)
                
                let columnOfTexts = getColumnOfValueTexts(startingFrom: startingValueText)
                    .sorted(by: { $0.text.rect.minY < $1.text.rect.minY })
                
                columns.append(columnOfTexts)
            }
        }

        columns = columns
            .uniqued()
            .sorted(by: { $0.count > $1.count })
            .filter { $0.count >= Int(Double(attributeTextColumns.smallestCount) * 0.3) }
        
        chooseEnergyValues(&columns)
        
        return groups
    }
    
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

extension Array where Element == ValueText {
    var containsTwoEnergyValues: Bool {
        contains(where: { $0.value.unit == .kj })
        &&
        contains(where: { $0.value.unit == .kcal })
    }
}

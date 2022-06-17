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
        
        columns = Array(
            columns
                .uniqued()
                .sorted(by: { $0.count > $1.count })
                .filter { $0.count >= Int(Double(attributeTextColumns.smallestCount) * 0.3) }
                .prefix(attributeTextColumns.maximumNumberOfValueColumns)
        )
        chooseEnergyValues(&columns)
        
        columns = columns.sorted(by: {
            $0.averageMidX < $1.averageMidX
        })
        
        groups = [columns]
        
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

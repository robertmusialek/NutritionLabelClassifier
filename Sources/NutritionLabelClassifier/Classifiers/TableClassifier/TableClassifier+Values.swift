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
        
        var columns: [[RecognizedText]] = []
        
        for recognizedTexts in [visionResult.accurateRecognitionWithLanugageCorrection ?? []] {
            for text in recognizedTexts {
                guard let value = Value(fromString: text.string) else {
                    continue
                }
                
                let columnOfTexts = getColumnOfValueRecognizedTexts(startingFrom: text)
                    .sorted(by: { $0.rect.minY < $1.rect.minY })
                
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
        
        let columnsOfValueTexts = columnsOfValuesTexts(fromRecognizedTextColumns: columns)
        return groupsOfColumns(fromColumnsOfValueTexts: columnsOfValueTexts)
    }
    
    func columnsOfValuesTexts(fromRecognizedTextColumns columns: [[RecognizedText]]) -> [[ValueText?]] {
        
//        chooseEnergyValues(&columns)
//
//        columns = columns.sorted(by: {
//            $0.averageMidX < $1.averageMidX
//        })

        return []
    }
    
    func groupsOfColumns(fromColumnsOfValueTexts columns: [[ValueText?]]) -> [[[ValueText?]]] {
        
//        groups = [columns]
        
        return []
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

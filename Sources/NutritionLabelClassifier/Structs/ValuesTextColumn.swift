import VisionSugar
import SwiftUI

//TODO: Create test cases for it starting with spicy chips
struct ValuesTextColumn {

    var valuesTexts: [ValuesText]

    init?(startingFrom text: RecognizedText, in visionResult: VisionResult) {
        guard let valuesText = ValuesText(text), valuesText.isSingularPercentValue else {
            return nil
        }

        let above = visionResult.columnOfValues(startingFrom: text, preceding: true)
        let below = visionResult.columnOfValues(startingFrom: text, preceding: false)
        self.valuesTexts = above + [valuesText] + below
    }
}

extension ValuesText: CustomDebugStringConvertible {
    var debugDescription: String {
        return "[" + values.map { $0.description }.joined(separator: ", ") + "]"
    }
    var description: String {
        return "[" + values.map { $0.description }.joined(separator: ", ") + "]"
    }
}

extension Array where Element == ValuesTextColumn {
    var descriptions: [String] {
        return map { $0.desc }
    }
}

extension ValuesTextColumn {
    //TODO: Rename this
    var desc: String {
        return "[" + valuesTexts.map { $0.debugDescription }.joined(separator: ", ") + "]"
    }
}

extension ValuesTextColumn: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(valuesTexts)
    }
}

/// Helpers for `ExtractedValues.removeTextsAboveEnergy(_:)`
extension ValuesTextColumn {
    
    var hasValuesAboveEnergyValue: Bool {
        /// Return false if we didn't detect an energy value
        guard let index = indexOfFirstEnergyValue else { return false }
        /// Return true if its not the first element
        return index != 0
    }
    
    var indexOfFirstEnergyValue: Int? {
        for i in valuesTexts.indices {
            if valuesTexts[i].containsValueWithEnergyUnit {
                return i
            }
        }
        return nil
    }
    
    mutating func removeValuesTextsAboveEnergy() {
        guard let index = indexOfFirstEnergyValue else { return }
        valuesTexts.removeFirst(index)
    }
}

extension ValuesTextColumn {
    
    /// Use `midX` of shortest text, checking if it lies within the shortest text of any column in each group
    func belongsTo(_ group: [ValuesTextColumn]) -> Bool {
        //TODO-NEXT (2): Belongs to needs to be modified to recognize columns in spicy chips
        guard let midX = valuesTexts.compactMap({ $0.text }).midXOfShortestText,
              let shortestText = group.shortestText
        else {
            return false
        }

        return midX >= shortestText.rect.minX && midX <= shortestText.rect.maxX
    }
    
    var shortestText: RecognizedText? {
        valuesTexts.compactMap { $0.text }.shortestText
    }
    
    var midXOfShortestText: CGFloat? {
        shortestText?.rect.midX
    }
}

extension Array where Element == ValuesTextColumn {
    var shortestText: RecognizedText? {
        let shortestTexts = compactMap { $0.shortestText }
        return shortestTexts.sorted(by: { $0.rect.width < $1.rect.width }).first
    }
}

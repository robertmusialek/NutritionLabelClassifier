import VisionSugar
import SwiftUI

//TODO: Create test cases for it starting with spicy chips
struct ValuesTextColumn {

    var valuesTexts: [ValuesText]

    init?(startingFrom text: RecognizedText, in visionResult: VisionResult) {
        guard let valuesText = ValuesText(text), !valuesText.isSingularPercentValue else {
            return nil
        }

        let above = visionResult.columnOfValues(startingFrom: text, preceding: true).reversed()
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
    
    func indexOfFirstValueTextBelowAttributeText(_ attributeText: AttributeText) -> Int? {
        let thresholdY = 0.0
        for i in valuesTexts.indices {
            if valuesTexts[i].text.rect.minY > attributeText.text.rect.maxY + thresholdY {
                return i
            }
        }
        return nil
    }
    
    mutating func removeValuesTextsAboveEnergy() {
        guard let index = indexOfFirstEnergyValue else { return }
        valuesTexts.removeFirst(index)
    }
    
    mutating func removeValueTextsBelowAttributeText(_ attributeText: AttributeText) {
        guard let index = indexOfFirstValueTextBelowAttributeText(attributeText) else { return }
        valuesTexts.removeLast(valuesTexts.count - index)
    }
}

extension ValuesTextColumn {

    //TODO: Improve this
    /**
     Returns a `CGRect` which represents a union of all the single-value `ValueText`'s of the column.

     Any outliers that may span multple columns are ignored when calculating this union.
     
     Improve this by ignoring inline values that may be wider than the other single-value ValueText's. Do this by either ignoring those that also have an Attribute that can be extracted from the text or—better yet—write a function on ValueText that returns a boolean of whether the text contains any extraneous strings to the actual value strings and use this.
     */
    var columnRect: CGRect {
        var unionRect: CGRect? = nil
        for valuesText in valuesTexts {
            
            /// Skip values that don't have exactly one value
            guard valuesText.values.count == 1 else {
                continue
            }
            
            guard let rect = unionRect else {
                /// Set the first `ValuesText.rect` to be the `unionRect`
                unionRect = valuesText.text.rect
                continue
            }
            
            /// Keep joining `unionRect` with any subsequent `ValuesText.rect`'s
            unionRect = rect.union(valuesText.text.rect)
        }
        
        /// Now return the union
        return unionRect ?? .zero
    }
    
    func belongsTo(_ group: [ValuesTextColumn]) -> Bool {
        
        group.contains {
            let rect = $0.columnRect
            let yNormalizedRect = columnRect.rectWithYValues(of: rect)
            return rect.intersection(yNormalizedRect).isNull
        }
        
//        guard let midX = valuesTexts.compactMap({ $0.text }).midXOfShortestText,
//              let shortestText = group.shortestText
//        else {
//            return false
//        }
//
//        return midX >= shortestText.rect.minX && midX <= shortestText.rect.maxX
    }

    func belongsTo_legacy(_ group: [ValuesTextColumn]) -> Bool {
        /// Use `midX` of shortest text, checking if it lies within the shortest text of any column in each group
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

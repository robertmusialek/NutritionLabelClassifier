import VisionSugar
import SwiftUI

//TODO: Create test cases for it starting with spicy chips
struct ValuesTextColumn {

    var valuesTexts: [ValuesText]

    init?(startingFrom text: RecognizedText, in visionResult: VisionResult) {
        guard let valuesText = ValuesText(text), !valuesText.isSingularPercentValue else {
            return nil
        }

        let above = visionResult.columnOfValueTexts(startingFrom: text, preceding: true).reversed()
        let below = visionResult.columnOfValueTexts(startingFrom: text, preceding: false)
        self.valuesTexts = above + [valuesText] + below
        print("W ehere")
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

extension Array where Element == ValuesTextColumn {
    func containsNoValuesTexts(from column: ValuesTextColumn) -> Bool {
        !contains { c in
            c.valuesTexts.contains {
                column.valuesTexts.contains($0)
            }
        }
    }
    
    func containsNoSingleValuesTexts(from column: ValuesTextColumn) -> Bool {
        !contains { c in
            c.valuesTexts.contains {
                column.singleValuesTexts.contains($0)
            }
        }
    }

}

/// Helpers for `ExtractedValues.removeTextsAboveEnergy(_:)`
extension ValuesTextColumn {
    
    var rect: CGRect {
        valuesTexts.rect
    }
    
    var containsServingAttribute: Bool {
        valuesTexts.containsServingAttribute
    }
    var hasValuesAboveEnergyValue: Bool {
        /// Return false if we didn't detect an energy value
        guard let index = indexOfFirstEnergyValue else { return false }
        /// Return true if its not the first element
        return index != 0
    }
    
    var indexOfFirstEnergyValue: Int? {
        for i in valuesTexts.indices {
            if valuesTexts[i].containsValueWithEnergyUnit, !valuesTexts[i].containsNutrientUnit {
                return i
            }
        }
        return nil
    }
    
    func topMostInlineValuesText(to text: RecognizedText) -> ValuesText? {
        for valuesText in valuesTexts {
            let xNormalizedRect = valuesText.text.rect.rectWithXValues(of: text.rect)
            if xNormalizedRect.intersects(text.rect) {
                return valuesText
            }
        }
        return nil
    }
    
    func indexOfLastValueTextInline(with attributeText: AttributeText) -> Int? {
        let thresholdY = attributeText.text.rect.height
        let aRect = attributeText.text.rect
        for i in valuesTexts.indices {
            let vRect = valuesTexts[i].text.rect
            
            guard !(vRect.minX < aRect.minX && vRect.minY > aRect.maxY) else {
                return i
            }
            if valuesTexts[i].text.rect.minY > attributeText.text.rect.maxY + thresholdY {
                return i
            }
        }
        return nil
    }

    func indexOfFirstValueTextInline(with attributeText: AttributeText) -> Int? {
        let thresholdY = attributeText.text.rect.height
        for i in valuesTexts.indices {
            if valuesTexts[i].text.rect.maxY + thresholdY > attributeText.text.rect.minY {
                return i
            }
        }
        return nil
    }

    mutating func removeValuesTextsAboveEnergy() {
        guard let index = indexOfFirstEnergyValue else { return }
        valuesTexts.removeFirst(index)
    }
    
    var hasMultipleKcalValues: Bool {
        valuesTexts.kcalValues.count > 1
    }
    
    var hasMultipleKjValues: Bool {
        valuesTexts.kjValues.count > 1
    }
    
    var hasBothKcalAndKjValues: Bool {
        !valuesTexts.kjValues.isEmpty && !valuesTexts.kcalValues.isEmpty
    }
        
    mutating func removeDuplicateEnergy(using energyAttribute: AttributeText?) {
        if hasMultipleKjValues {
            pickEnergyValue(from: valuesTexts.kjValues, for: energyAttribute)
        }
        if hasMultipleKcalValues {
            pickEnergyValue(from: valuesTexts.kcalValues, for: energyAttribute)
        }
    }
    
    mutating func pickEnergyIfMultiplePresent() {
        guard hasBothKcalAndKjValues else {
            return
        }
        
        //TODO: Have this a preference where we choose kcal over kj so that it is configurable when using the classifier
        valuesTexts.removeAll(where: { $0.containsValueWithKcalUnit })
    }
        
    mutating func pickEnergyValue(from multipleValues: [ValuesText], for energyAttribute: AttributeText?) {
        var array = multipleValues
        /// If we have an energy attribute, determine the closest value to it
        if let first = array.first {
//        if let closest = array.closestValueText(to: energyAttribute?.text) {
            /// Remove it from array of kj values
            array.removeAll(where: { $0 == first })

            /// Now remove the remaining kj values from the `valueText`s array
            valuesTexts.removeAll(where: { array.contains($0) })
        }
    }
    
    mutating func removeValueTextsBelow(_ attributeText: AttributeText) {
        guard let index = indexOfLastValueTextInline(with: attributeText) else { return }
        valuesTexts.removeLast(valuesTexts.count - index)
    }
    
    mutating func removeValueTextsAbove(_ attributeText: AttributeText) {
        guard let index = indexOfFirstValueTextInline(with: attributeText) else { return }
        valuesTexts.removeFirst(index)
    }
    
    mutating func removeTextsWithMultipleNutrientValues() {
        valuesTexts.removeAll { valuesText in
            valuesText.values.filter { $0.hasNutrientUnit }.count > 2
        }
    }

    mutating func removeTextsWithExtraLargeValues() {
        valuesTexts.removeAll { valuesText in
            valuesText.values.contains(where: { $0.amount > 15_000 })
        }
    }

    mutating func removeValueTextsAbove(_ text: RecognizedText) {
        valuesTexts.removeAll(where: {
            let thresholdY = 0.02 * text.rect.height
            return $0.text.rect.minY + thresholdY < text.rect.minY
        })
    }
    
    mutating func removeOverlappingTextsWithSameString() {
        guard valuesTexts.count > 1 else { return }
        
        /// Crashing with `E3BAC0B0-8E46-4C97-A67A-9AFBE5E8ACF7` due to `i` being 8 and out of range of `valuesText` since we've probably removed an overlapping text (we knew this would happen)
        /// Try using `valuesTexts.removeAll(where: )` instead and run tests straight after
        /// Also crashing with `364EDBD7-004B-4A97-83AA-F6404DE5EEB4`
        
        for i in 1..<valuesTexts.count {
            guard i < valuesTexts.count else {
                continue
            }
            
            let valuesText = valuesTexts[i]
            let previousValuesTexts = valuesTexts[0..<i]
            
            /// if any of the previous valuesTexts contains
            if previousValuesTexts.contains(where: {
                $0.text.rect == valuesText.text.rect
                &&
                $0.text.string == valuesText.text.string
            }) {
                valuesTexts.remove(at: i)
            }
        }
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
        columnRect(of: singleValuesTexts)
    }

    func columnRectOfSingleValuesNotWithinOrVerticallyOutsideOf(_ attributes: ExtractedAttributes) -> CGRect {
        columnRect(of: singleValuesNotWithinOrVerticallyOutsideOf(attributes))
    }
    
    func singleValuesNotWithinOrVerticallyOutsideOf(_ attributes: ExtractedAttributes) -> [ValuesText] {
        singleValuesTexts.filter {
            /// Do not include value texts that are substantailly contained by any of the attribute columns
//            guard !attributes.contains(rect: $0.text.rect) else {
//                return false
//            }
            
            /// Do not include value texts that are vertically outside of any of the attribute columns
            guard attributes.overlapsVertically(with: $0.text.rect) else {
                return false
            }
            
            return true
        }
    }

    func columnRect(of valuesTexts: [ValuesText]) -> CGRect {
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
    
    func belongsTo(_ group: [ValuesTextColumn], using attributes: ExtractedAttributes) -> Bool {
        
        guard let topGroupColumn = group.sorted(by: { $0.valuesTexts.count > $1.valuesTexts.count }).first else {
            return false
        }

        let rect = topGroupColumn.columnRectOfSingleValuesNotWithinOrVerticallyOutsideOf(attributes)
        let yNormalizedRect = columnRectOfSingleValuesNotWithinOrVerticallyOutsideOf(attributes).rectWithYValues(of: rect)
        
        guard let intersectionRatio = rect.ratioOfIntersection(with: yNormalizedRect) else {
            return false
        }

        /// We chose `0.43` because `0.423` was needed to identify a column as not belonging to in case `21AB8151-540A-41A9-BAB2-8674FD3A46E7` (check for one that starts with a value with amount 297) and `0.45` was needed to identify a column as belonging to the group in case `31D0CA8B-5069-4AB3-B865-47CD1D15D879` (check for one that starts with a value with amount 5).
        let intersectionRatioIsSubstantial = intersectionRatio >= 0.43
        let intersects = rect.intersects(yNormalizedRect)
        
        /// We added this check because `31D0CA8B-5069-4AB3-B865-47CD1D15D879` fails the `intersectionRatio` check. This makes sure that none of the `ValuesText`'s in this column exists in any of the group before continuing.
        if group.containsNoSingleValuesTexts(from: self) {
            /// We added this after case `21AB8151-540A-41A9-BAB2-8674FD3A46E7` where both columns overlapped by each other slightly (the intersection ratio—the width of the intersection as a proportion of the width of the smaller column's width was `2.9%`
            return intersectionRatioIsSubstantial
        } else {
            return intersects
        }
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
    
    mutating func removeFirstSetOfValues() {
        for i in indices {
            var column = self[i]
            column.valuesTexts.remove(at: 0)
            self[i] = column
        }
    }
    
    var firstSetOfValuesTextsContainingEnergy: [ValuesText]? {
        var valuesTexts: [ValuesText?] = []
        for column in self {
            guard let firstValuesText = column.valuesTexts.first else {
                valuesTexts.append(nil)
                continue
            }
            if firstValuesText.containsValueWithEnergyUnit {
                valuesTexts.append(firstValuesText)
            }
        }
        
        let nonNilValuesTexts = valuesTexts.compactMap { $0 }
        return valuesTexts.count == nonNilValuesTexts.count ? nonNilValuesTexts : nil
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
    var desc: [String] {
        return map { $0.desc }
    }
}

//MARK: - Experimental

extension ValuesTextColumn {
    func numberOfValuesInlineWith(attributes: ExtractedAttributes) -> Int {
        valuesTexts.filter {
            $0.isInlineWithAnyAttribute(in: attributes)
        }.count
    }
    
    var numberOfSingleValuesThatAreInColumnWithOtherSingleValues: Int {
        singleValuesTexts.filter {
            $0.isInColumnWithAllValuesTexts(in: singleValuesTexts, except: $0)
        }.count
    }
    
    var singleValuesTexts: [ValuesText] {
        valuesTexts.filter { $0.values.count == 1 }
    }
    
    func portionOfValuesInlineWith(attributes: ExtractedAttributes) -> Double {
        Double(numberOfValuesInlineWith(attributes: attributes)) / Double(valuesTexts.count)
    }
    
    var portionOfSingleValuesThatAreInColumnWithOtherSingleValues: Double {
        Double(numberOfSingleValuesThatAreInColumnWithOtherSingleValues) / Double(singleValuesTexts.count)
    }
    
    var containsMoreThanOneSingleValue: Bool {
        singleValuesTexts.count > 1
    }
}

extension ValuesText {

    func isInColumnWithAllValuesTexts(in valuesTexts: [ValuesText], except: ValuesText) -> Bool {
        for valuesText in valuesTexts {
            guard valuesText != except else { continue }
            if self.text.isInColumn(with: valuesText.text) {
                return true
            }
        }
        return false
    }

    func isInlineWithAnyAttribute(in attributes: ExtractedAttributes) -> Bool {
        for attributeText in attributes.attributeTextColumns.reduce([], +) {
            if self.text.isInline(with: attributeText.text) {
                return true
            }
        }
        return false
    }
}

extension RecognizedText {
    func isInColumn(with text: RecognizedText) -> Bool {
        rect.rectWithYValues(of: text.rect).intersects(text.rect)
    }
    func isInline(with text: RecognizedText) -> Bool {
        rect.rectWithXValues(of: text.rect).intersects(text.rect)
    }
}

import SwiftUI
import VisionSugar
import SwiftSugar
import TabularData

let RatioErrorPercentageThreshold = 17.0
let MacroOrEnergyErrorPercentageThreshold = 20.0

struct ExtractedGrid {
    
    var columns: [ExtractedColumn]
    let numberOfValues: Int
    
    init(attributes: ExtractedAttributes, values: ExtractedValues) {
        
        var columns: [ExtractedColumn] = []
        
        for i in attributes.attributeTextColumns.indices {
            guard i < values.groupedColumns.count else {
                //TODO: Remove all fatalErrors after testing
                self.columns = []
                self.numberOfValues = 0
                return
//                fatalError("Expected groupedColumnsOfValues to have: \(i) columns")
            }
            
            let attributesColumn = attributes.attributeTextColumns[i]
            let valueColumns = values.groupedColumns[i]
            let column = ExtractedColumn(attributesColumn: attributesColumn, valueColumns: valueColumns)
            columns.append(column)
        }
        
        self.columns = columns
        self.numberOfValues = columns.first?.rows.first?.valuesTexts.count ?? 0

        removeValuesOutsideColumnRects()
        removeExtraneousValues()

        handleReusedValueTexts()
        handleMultipleValues()

        fillInRowsWithOneMissingValue()
        fixInvalidRows()
        fixInvalidRowsContainingLessThanPrefix()

        fixSingleInvalidMacroOrEnergyRow()
        removeEmptyValues()
        removeRowsWithMultipleValues()

        fillInMissingUnits()

        addMissingEnergyValuesIfNeededAndAvailable()

    }
    
    var values: [[[Value?]]] {
        columns.map {
            $0.rows.map { $0.valuesTexts.map { $0?.values.first } }
        }
    }
    
    func row(for attribute: Attribute) -> ExtractedRow? {
        allRows.first(where: { $0.attributeText.attribute == attribute })
    }
    
    /// Used for debugging
    var desc: DataFrame {
        columns[0].dataFrame
    }
}

extension Array where Element == Bool? {
    var onlyOneOfTwoIsTrue: Bool {
        count == 2
        && (
            (self[0] == true && self[1] != true)
            ||
            (self[0] != true && self[1] == true)
        )
    }
}

extension Array where Element == ExtractedColumn {
    mutating func modify(_ row: ExtractedRow, with newValues: (Value, Value)) {
        for columnIndex in indices {
            var column = self[columnIndex]
            if column.contains(row) {
                column.modify(row, with: newValues)
                self[columnIndex] = column
            }
        }
    }

    mutating func modify(_ row: ExtractedRow, with newValue: Value) {
        for columnIndex in indices {
            var column = self[columnIndex]
            if column.contains(row) {
                column.modify(row, with: newValue)
                self[columnIndex] = column
            }
        }
    }

    mutating func modify(_ row: ExtractedRow, with newRow: ExtractedRow) {
        for columnIndex in indices {
            var column = self[columnIndex]
            if column.contains(row) {
                column.modify(row, with: newRow)
                self[columnIndex] = column
            }
        }
    }

    mutating func remove(_ row: ExtractedRow) {
        for columnIndex in indices {
            var column = self[columnIndex]
            if column.contains(row) {
                column.remove(row)
                self[columnIndex] = column
            }
        }
    }
    
    mutating func fillInMissingUnits() {
        for columnIndex in indices {
            var column = self[columnIndex]
            column.fillInMissingUnits()
            self[columnIndex] = column
        }
    }
    
    mutating func handleMultipleValues() {
        for columnIndex in indices {
            var column = self[columnIndex]
            column.handleMultipleValues()
            self[columnIndex] = column
        }
    }
    
    mutating func removeRowsWithMultipleValues() {
        for columnIndex in indices {
            var column = self[columnIndex]
            column.removeRowsWithMultipleValues()
            self[columnIndex] = column
        }
    }
    
    mutating func handleReusedValueTexts() {
        for columnIndex in indices {
            var column = self[columnIndex]
            column.handleReusedValueTexts()
            self[columnIndex] = column
        }
    }
}
extension ExtractedColumn {
    mutating func modify(_ row: ExtractedRow, with newValues: (Value, Value)) {
        rows.modify(row, with: newValues)
    }

    mutating func modify(_ row: ExtractedRow, with newValue: Value) {
        rows.modify(row, with: newValue)
    }

    mutating func modify(_ row: ExtractedRow, with newRow: ExtractedRow) {
        rows.modify(row, with: newRow)
    }

    mutating func remove(_ row: ExtractedRow) {
        rows.removeAll(where: { $0.attributeText.attribute == row.attributeText.attribute })
    }
    
    func contains(_ row: ExtractedRow) -> Bool {
        rows.contains(where: { $0.attributeText.attribute == row.attributeText.attribute })
    }
 
    mutating func fillInMissingUnits() {
        rows.fillInMissingUnits()
    }
    
    mutating func removeRowsWithMultipleValues() {
        rows.removeRowsWithMultipleValues()
    }
    
    mutating func handleMultipleValues() {
        for row in rowsWithMultipleValues {
            
            /// First see if these are multple values for successive attributes on the same line
            if attemptHandlingMultipleValuesForInlineMultipleAttributes(for: row) {
                continue
            }
            
            if attemptHandlingMultipleValuesByDistributingAcrossValues(for: row) {
                continue
            }
            
        }
    }

    mutating func attemptHandlingMultipleValuesByDistributingAcrossValues(for row: ExtractedRow) -> Bool {
        let valuesText: ValuesText?
        if let vt = row.valuesTexts[0] {
            valuesText = vt
        } else if let vt = row.valuesTexts[1] {
            valuesText = vt
        } else {
            valuesText = nil
        }
        
        guard let valuesText = valuesText, valuesText.values.count > 1 else {
            return false
        }
        
        modify(row, with: (valuesText.values[0], valuesText.values[1]))
        return true
    }
     
    mutating func attemptHandlingMultipleValuesForInlineMultipleAttributes(for row: ExtractedRow) -> Bool {
        /// If we have multiple values, and the next attribute shares the same attribute text as the one with multiple values, this implies we have something along the lines of `Sodium/Salt` (see case `31D0CA8B-5069-4AB3-B865-47CD1D15D879`) with inline values within the column.
        /// We handle this by keeping the first value and assigning the second value to the next row (within the same column), essentially discarding any remaining values.
        /// We currently support two inline values, but this can be extended by checking rows further down the line if we have more values.
        guard let index = indexOfRow(row),
              index < rows.count - 1,
              rows[index+1].attributeText.text == row.attributeText.text
        else {
            return false
        }
        
        /// If it's in the first column
        if let valuesText = row.valuesTexts[0] {
            let values = valuesText.values
            guard values.count > 1 else {
                return false
            }
            
            var newValuesText = valuesText
            newValuesText.values = [values[0]]
            rows[index].valuesTexts[0] = newValuesText
            
            var newValuesTextForNextRow = valuesText
            newValuesTextForNextRow.values = [values[1]]
            rows[index+1].valuesTexts[0] = newValuesTextForNextRow
        }
        /// If it's also in the second column
        if let valuesText = row.valuesTexts[1] {
            let values = valuesText.values
            guard values.count > 1 else {
                return false
            }
            
            var newValuesText = valuesText
            newValuesText.values = [values[0]]
            rows[index].valuesTexts[1] = newValuesText
            
            var newValuesTextForNextRow = valuesText
            newValuesTextForNextRow.values = [values[1]]
            rows[index+1].valuesTexts[1] = newValuesTextForNextRow
        }
        return true
    }
    
    mutating func handleReusedValueTexts() {
        rows.handleReusedValueTexts(using: columnRects)
    }
    
    var rowsWithMultipleValues: [ExtractedRow] {
        rows.filter { $0.containsValueTextsWithMultipleValues }
    }
    
    func indexOfRow(_ row: ExtractedRow) -> Int? {
        rows.firstIndex(where: { $0.attributeText.attribute == row.attributeText.attribute })
    }
}

extension Array where Element == ExtractedRow {
    mutating func modify(_ rowToModify: ExtractedRow, with newValues: (Value, Value)) {
        for i in indices {
            var row = self[i]
            if row.attributeText.attribute == rowToModify.attributeText.attribute {
                row.modify(with: newValues)
                self[i] = row
            }
        }
    }

    mutating func modify(_ rowToModify: ExtractedRow, with newValue: Value) {
        for i in indices {
            var row = self[i]
            if row.attributeText.attribute == rowToModify.attributeText.attribute {
                row.modify(with: newValue)
                self[i] = row
            }
        }
    }

    mutating func modify(_ rowToModify: ExtractedRow, with newRow: ExtractedRow) {
        for i in indices {
            let row = self[i]
            if row.attributeText.attribute == rowToModify.attributeText.attribute {
                self[i] = newRow
            }
        }
    }

    mutating func fillInMissingUnits() {
        for i in indices {
            var row = self[i]
            row.fillInMissingUnits()
            self[i] = row
        }
    }
    
    mutating func removeRowsWithMultipleValues() {
        removeAll { $0.containsValueTextsWithMultipleValues }
    }
    
    mutating func handleReusedValueTexts(using columnRects: (CGRect?, CGRect?)) {
        for rowIndex in indices {
            var row = self[rowIndex]
            row.handleReusedValueTexts(using: columnRects)
            self[rowIndex] = row
        }
    }
}

extension ExtractedRow {
    
    var containsValueTextsWithMultipleValues: Bool {
        valuesTexts.contains(where: { valuesText in
            guard let valuesText = valuesText else {
                return false
            }
            return valuesText.values.count > 1
        })
    }
    mutating func fillInMissingUnits() {
        if valuesTexts.count > 0, let valuesText = valuesTexts[0], valuesText.values.first?.unit == nil {
            var new = valuesText
            new.values[0].unit = attributeText.attribute.defaultUnit
            valuesTexts[0] = new
        }

        if valuesTexts.count == 2, let valuesText = valuesTexts[1], valuesText.values.first?.unit == nil {
            var new = valuesText
            new.values[0].unit = attributeText.attribute.defaultUnit
            valuesTexts[1] = new
        }
    }
    
    mutating func handleReusedValueTexts(using columnRects: (CGRect?, CGRect?)) {
        guard valuesTexts.count == 2,
              let valuesText = valuesTexts[0],
              let valuesText2 = valuesTexts[1],
              let columnRect1 = columnRects.0,
              let columnRect2 = columnRects.1,
              valuesText == valuesText2
        else {
            return
        }
        
        let distanceTo1 = abs(valuesText.text.rect.midX - columnRect1.midX)
        let distanceTo2 = abs(valuesText.text.rect.midX - columnRect2.midX)
        
        if distanceTo1 > distanceTo2 {
            valuesTexts[0] = nil
        } else {
            valuesTexts[1] = nil
        }
    }

    mutating func modify(with newValues: (Value, Value)) {
        if let existing = valuesTexts[0] {
            var new = existing
            new.values = [newValues.0]
            valuesTexts[0] = new
        } else {
            valuesTexts[0] = ValuesText(values: [newValues.0])
        }
        
        guard valuesTexts.count > 1 else {
            return
        }
        if let existing = valuesTexts[1] {
            var new = existing
            new.values = [newValues.1]
            valuesTexts[1] = new
        } else {
            valuesTexts[1] = ValuesText(values: [newValues.1])
        }
    }

    mutating func modify(with newValue: Value) {
        if let existing = valuesTexts[0] {
            var new = existing
            new.values = [newValue]
            valuesTexts[0] = new
        } else {
            valuesTexts[0] = ValuesText(values: [newValue])
        }        
    }

    var containsExtraneousValues: Bool {
        valuesTexts.contains { $0?.containsExtraneousValues == true }
    }
    
    func containsValueOutside(_ columnRects: (CGRect?, CGRect?)) -> Bool {
        if let columnRect = columnRects.0, let textRect = valuesTexts.first??.text.rect {
            if !textRect.isInSameColumnAs(columnRect) {
                return true
            }
        }
        if let columnRect = columnRects.1, valuesTexts.count == 2, let textRect = valuesTexts[1]?.text.rect {
            if !textRect.isInSameColumnAs(columnRect) {
                return true
            }
        }
        return false
    }
    
    func withoutValuesOutsideColumnRects(_ columnRects: (CGRect?, CGRect?)) -> ExtractedRow {
        var newRow = self
        newRow.removeValuesOutsideColumnRects(columnRects)
        return newRow
    }
    
    var withoutExtraneousValues: ExtractedRow {
        var newRow = self
        newRow.removeExtraneousValues()
        return newRow
    }
    
    mutating func removeExtraneousValues() {
        for i in valuesTexts.indices {
            guard let valueText = valuesTexts[i], valueText.containsExtraneousValues else {
                continue
            }
            var newValueText = valueText
            newValueText.removeExtraneousValues()
            valuesTexts[i] = newValueText
        }
    }
    
    mutating func removeValuesOutsideColumnRects(_ columnRects: (CGRect?, CGRect?)) {
        if let columnRect = columnRects.0, let textRect = valuesTexts.first??.text.rect {
            if !textRect.isInSameColumnAs(columnRect) {
                valuesTexts[0] = nil
            }
        }
        if let columnRect = columnRects.1, valuesTexts.count == 2, let textRect = valuesTexts[1]?.text.rect {
            if !textRect.isInSameColumnAs(columnRect) {
                valuesTexts[1] = nil
            }
        }
    }
    
    var desc: String {
        var string = "\(attributeText.attribute.rawValue)"
        if let valuesText = valuesTexts.first {
            string += ": \(valuesText?.description ?? "nil")"
        }
        if valuesTexts.count == 2 {
            string += ", \(valuesTexts[1]?.description ?? "nil")"
        }
        return string
    }
}

extension CGRect {
    func isInSameColumnAs(_ rect: CGRect) -> Bool {
        let yNormalized = rectWithYValues(of: rect)
        return yNormalized.intersects(rect)
    }
}
extension ValuesText {
    mutating func removeExtraneousValues() {
        values.removeAll(where: { $0.unit == .p })
        if values.contains(where: { $0.unit != nil }) {
            values.removeAll(where: { $0.unit == nil })
        }
    }
    
    func rectNotInSameColumnAs(_ columnRect: CGRect) -> Bool {
        //😵‍💫
        false
    }
    
    var containsExtraneousValues: Bool {
        values.contains(where: { $0.unit == .p })
        ||
        (
            values.contains(where: { $0.unit != nil })
            &&
            values.contains(where: { $0.unit == nil })
        )
    }
}

extension ExtractedGrid {

    mutating func remove(_ row: ExtractedRow) {
        columns.remove(row)
    }
    
    mutating func modify(_ row: ExtractedRow, withNewValues newValues: (Value, Value)) {
        print("2️⃣ Correct row: \(row.attributeText.attribute) with: \(newValues.0.description) and \(newValues.1.description)")
        columns.modify(row, with: newValues)
        print("2️⃣ done.")
    }

    mutating func modify(_ row: ExtractedRow, withNewValue newValue: Value) {
        columns.modify(row, with: newValue)
    }

    mutating func modify(_ row: ExtractedRow, with newRow: ExtractedRow) {
        columns.modify(row, with: newRow)
    }

    mutating func addMissingEnergyValuesIfNeededAndAvailable() {
        guard row(for: .energy) == nil else {
            return
        }
        //TODO: Do this when a test case requires us to
    }
    
    mutating func fillInMissingUnits() {
        columns.fillInMissingUnits()
    }

    mutating func handleMultipleValues() {
        columns.handleMultipleValues()
    }
    
    mutating func handleReusedValueTexts() {
        columns.handleReusedValueTexts()
    }
    
    mutating func removeRowsWithMultipleValues() {
        columns.removeRowsWithMultipleValues()
    }

    mutating func fillInRowsWithOneMissingValue() {
        guard let validRatio = validRatio else {
            return
        }
        
        /// For each row with one missing value
        /// Use the `validRatio` to fill in the missing value
        for row in rowsWithOneMissingValue {
            guard let missingIndex = row.singleMissingValueIndex else {
                continue
            }
            if missingIndex == 1 {
                guard let value = row.valuesTexts[0]?.values.first else {
                    continue
                }
                let amount = (value.amount / validRatio).roundedNutrientAmount
                modify(row, withNewValues: (value, Value(amount: amount, unit: value.unit)))
            }
            else if missingIndex == 0 {
                guard let value = row.valuesTexts[1]?.values.first else {
                    continue
                }
                let amount = (value.amount * validRatio).roundedNutrientAmount
                modify(row, withNewValues: (Value(amount: amount, unit: value.unit), value))
            }
        }
    }
    
    func amountFor(_ attribute: Attribute, at index: Int) -> Double? {
        allRows.valueFor(attribute, valueIndex: index)?.amount
    }
    
    func energyInKj(at index: Int) -> Double? {
        guard let energyValue = allRows.valueFor(.energy, valueIndex: index) else {
            return nil
        }
        if energyValue.unit == .kj {
            return energyValue.amount / KcalsPerKilojule
        } else {
            return energyValue.amount
        }
    }

    func calculateValue(for attribute: Attribute, in index: Int) -> Value? {
        guard let amount = calculateAmount(for: attribute, in: index) else {
            return nil
        }
        let validValue = allRows.valueFor(attribute, valueIndex: index == 0 ? 1 : 0)
        let unit: NutritionUnit
        if let validUnit = validValue?.unit {
            unit = validUnit
        } else {
            unit = attribute == .energy ? .kj : .g
        }
        
        if attribute == .energy && unit == .kj {
            return Value(amount: (amount * KcalsPerKilojule).rounded(toPlaces: 0), unit: unit)
        } else {
            return Value(amount: amount, unit: unit)
        }
    }
    
    func calculateAmount(for attribute: Attribute, in index: Int) -> Double? {
        print("2️⃣ Calculate \(attribute) in column \(index)")
        guard allRows.containsAllMacrosAndEnergy else {
            return nil
        }
        
        switch attribute {
        case .carbohydrate:
            guard let fat = amountFor(.fat, at: index),
                  let protein = amountFor(.protein, at: index),
                  let energy = energyInKj(at: index) else {
                return nil
            }
            return (energy - (protein * KcalsPerGramOfProtein) - (fat * KcalsPerGramOfFat)) / KcalsPerGramOfCarb
            
        case .fat:
            guard let carb = amountFor(.carbohydrate, at: index),
                  let protein = amountFor(.protein, at: index),
                  let energy = energyInKj(at: index) else {
                return nil
            }
            return (energy - (protein * KcalsPerGramOfProtein) - (carb * KcalsPerGramOfCarb)) / KcalsPerGramOfFat
            
        case .protein:
            guard let fat = amountFor(.fat, at: index),
                  let carb = amountFor(.carbohydrate, at: index),
                  let energy = energyInKj(at: index) else {
                return nil
            }
            return (energy - (carb * KcalsPerGramOfCarb) - (fat * KcalsPerGramOfFat)) / KcalsPerGramOfProtein

        case .energy:
            guard let fat = amountFor(.fat, at: index),
                  let carb = amountFor(.carbohydrate, at: index),
                  let protein = amountFor(.protein, at: index) else {
                return nil
            }
            return (carb * KcalsPerGramOfCarb) + (fat * KcalsPerGramOfFat) + (protein * KcalsPerGramOfProtein)

        default:
            return nil
        }
    }

    mutating func fixSingleInvalidMacroOrEnergyRow() {
        if macrosValidities.count == 1 {
            fixSingleInvalidMacroOrEnergyRowForOneValue()
        } else {
            fixSingleInvalidMacroOrEnergyRowForTwoValues()
        }
    }

    mutating func fixSingleInvalidMacroOrEnergyRowForOneValue() {
        guard macrosValidities.first == false,
              allRows.containsAllMacrosAndEnergy,
              let macroAndEnergyRows = allMacroAndEnergyRows,
              let energyValue = row(for: .energy)?.firstValue,
              let carb = row(for: .carbohydrate)?.firstValue?.amount,
              let fat = row(for: .fat)?.firstValue?.amount,
              let protein = row(for: .protein)?.firstValue?.amount
        else {
            return
        }
        
        var energy = energyValue.amount
        if energyValue.unit == .kj {
            energy = energy / KcalsPerKilojule
        }

        //TODO: We might be able to improve this (albeit expensively) by going through all combinations of alternate values for each of the macro and energy rows to find one that works—in which case we would need to modify all the rows that require picking an alternate
        /// For each macro and energy row
        for row in macroAndEnergyRows {
            guard let valuesText = row.valuesTexts.first, let valuesText = valuesText else {
                continue
            }
            
            let attribute = row.attributeText.attribute
            
            for value in valuesText.alternateValues {
                
                var amount = value.amount
                if attribute == .energy, value.unit == .kj {
                    amount = amount / KcalsPerKilojule
                }
                
                let isValid: Bool
                switch attribute {
                case .energy:
                    isValid = macroAndEnergyValuesAreValid(energyInKcal: amount, carb: carb, fat: fat, protein: protein)
                case .carbohydrate:
                    isValid = macroAndEnergyValuesAreValid(energyInKcal: energy, carb: amount, fat: fat, protein: protein)
                case .fat:
                    isValid = macroAndEnergyValuesAreValid(energyInKcal: energy, carb: carb, fat: amount, protein: protein)
                case .protein:
                    isValid = macroAndEnergyValuesAreValid(energyInKcal: energy, carb: carb, fat: fat, protein: amount)
                default:
                    isValid = false
                }
                if isValid {
                    modify(row, withNewValue: value)
                    return
                }
            }
        }
        
   }

    mutating func fixSingleInvalidMacroOrEnergyRowForTwoValues() {
        let start = CFAbsoluteTimeGetCurrent()
        /// Check `macrosValidities` to see if we have two values where one is true
        /// Then check the validity of rows to determine if we have only one of the 3 variables that's invalid
        guard macrosValidities.onlyOneOfTwoIsTrue,
              allRows.containsAllMacrosAndEnergy,
              invalidMacroAndEnergyRows.count == 1,
              let invalidRow = invalidMacroAndEnergyRows.first
        else {
            return
        }
        
        let attribute = invalidRow.attributeText.attribute
        
        if (macrosValidities[0] == true && macrosValidities[1] != true) {
            guard let validValue = allRows.valueFor(attribute, valueIndex: 0) else {
                print("2️⃣ ⚠️ Error getting valid value for: \(attribute) in column 1")
                return
            }
            guard let calculatedValue = calculateValue(for: attribute, in: 1) else {
                print("2️⃣ ⚠️ Error getting calculated value for: \(attribute) in column 1")
                return
            }
            modify(invalidRow, withNewValues: (validValue, calculatedValue))
        }
        else if (macrosValidities[0] != true && macrosValidities[1] == true) {
            guard let validValue = allRows.valueFor(attribute, valueIndex: 1) else {
                print("2️⃣ ⚠️ Error getting valid value for: \(attribute) in column 2")
                return
            }
            guard let calculatedValue = calculateValue(for: attribute, in: 0) else {
                print("2️⃣ ⚠️ Error getting calculated value for: \(attribute) in column 2")
                return
            }
            modify(invalidRow, withNewValues: (calculatedValue, validValue))
        }
        print("took: \(CFAbsoluteTimeGetCurrent()-start)s")
        print("We here")
        /// If that's the case, then use the equation to determine that value and fill it in
    }
    
    /// Remove all rows that are empty (containing all nil values)
    mutating func removeEmptyValues() {
        for row in emptyRows {
            remove(row)
        }
    }
    
    mutating func removeValuesOutsideColumnRects() {
        for column in columns {
            for row in column.rows {
                if row.containsValueOutside(column.columnRects) {
                    modify(row, with: row.withoutValuesOutsideColumnRects(column.columnRects))
                }
            }
        }
    }
    
    mutating func removeExtraneousValues() {
        for row in allRows {
            if row.containsExtraneousValues {
                modify(row, with: row.withoutExtraneousValues)
            }
        }
    }
    
    mutating func fixInvalidRows() {
        guard let validRatio = validRatio else {
            return
        }
        let invalidRows = invalidRows(using: validRatio)
        for row in invalidRows {
            correct(row, for: validRatio)
        }
    }
    
    var greaterValueIndex: Int? {
        guard let row = validRows.first,
              row.valuesTexts.count == 2,
              let value1 = row.valuesTexts[0]?.values.first,
              let value2 = row.valuesTexts[1]?.values.first
        else {
            return nil
        }
        return value1.amount > value2.amount ? 0 : 1
    }
    
    var validRows: [ExtractedRow] {
        allRows.filter { row in
            !invalidRows.contains(where: { invalidRow in
                invalidRow.attributeText.attribute == row.attributeText.attribute
            })
        }
    }

    mutating func fixInvalidRowsContainingLessThanPrefix() {
        guard let validRatio = validRatio, let greaterValueIndex = greaterValueIndex else {
            return
        }
        let invalidRowsWithLessThanPrefix = invalidRows(using: validRatio, containingLessThanPrefix: true)
        for row in invalidRowsWithLessThanPrefix {
            correctRowContainingLessThanPrefix(row, for: validRatio, usingGreaterValueIndex: greaterValueIndex)
        }
    }

    mutating func correctRowContainingLessThanPrefix(_ row: ExtractedRow, for validRatio: Double, usingGreaterValueIndex greaterValueIndex: Int) {
        guard let value1 = row.valuesTexts[0]?.values.first, let value2 = row.valuesTexts[1]?.values.first else {
            return
        }

        if greaterValueIndex == 0 {
            let amount = (value1.amount / validRatio).roundedNutrientAmount
            modify(row, withNewValues: (value1, Value(amount: amount, unit: value1.unit)))
        }
        else if greaterValueIndex == 1 {
            let amount = (value1.amount * validRatio).roundedNutrientAmount
            modify(row, withNewValues: (Value(amount: amount, unit: value2.unit), value2))
        }
    }
    
    mutating func correct(_ row: ExtractedRow, for validRatio: Double) {
        print("3️⃣ Correcting: \(row.desc)")
        guard !correctionMadeUsingAlternativeValues(row, for: validRatio) else {
            print("3️⃣ Correction was made using alternative values for: \(row.desc)")
            return
        }
        
        guard !correctionMadeUsingParentNutrientHeuristics(row, for: validRatio) else {
            print("3️⃣ Correction was made using parent nutrient heuristics for: \(row.desc)")
            return
        }
        
        print("3️⃣ We weren't able to correct: \(row.desc)")
    }

    mutating func correctionMadeUsingParentNutrientHeuristics(_ row: ExtractedRow, for validRatio: Double) -> Bool {
        //TODO: Bring this in when needed—but keep in mind that this will make previous cases fail  where we have values taken directly from nutrition labels that don't actually have correctly scaled values
        return false
    }

    mutating func correctionMadeUsingAlternativeValues(_ row: ExtractedRow, for validRatio: Double) -> Bool {
        /// Try and use the alternative text candidates to see if one satisfies the ratio requirement (of being within an error margin of it)
        guard let valuesText1 = row.valuesTexts[0], let valuesText2 = row.valuesTexts[1] else {
            return false
        }
        
        for c1 in valuesText1.text.candidates {
            for c2 in valuesText2.text.candidates {
                
                guard let altValue1 = Value.detectSingleValue(in: c1),
                      let altValue2 = Value.detectSingleValue(in: c2),
                      altValue2.amount != 0 else {
                    continue
                }

                let ratio = altValue1.amount/altValue2.amount
                
                if ratio.errorPercentage(with: validRatio) <= RatioErrorPercentageThreshold {
                    modify(row, withNewValues: (altValue1, altValue2))
                    return true
                }
            }
        }
        return false
    }

    
    var allRows: [ExtractedRow] {
        columns.map { $0.rows }.reduce([], +)
    }
    
    var invalidRows: [ExtractedRow] {
        guard let validRatio = validRatio else {
            return []
        }
        return invalidRows(using: validRatio)
    }
    
    var rowsWithOneMissingValue: [ExtractedRow] {
        allRows.filter { $0.hasOneMissingValue }
    }
    
    var allMacroAndEnergyRows: [ExtractedRow]? {
        guard allRows.containsAllMacrosAndEnergy else { return nil }
        return allRows.filter { $0.attributeText.attribute.isEnergyOrMacro }
    }
    
    var invalidMacroAndEnergyRows: [ExtractedRow] {
        invalidRows(threshold: MacroOrEnergyErrorPercentageThreshold)
            .filter { $0.attributeText.attribute.isEnergyOrMacro }
            .filter { $0.ratioColumn1To2 != 0 }
            .filter { $0.valuesTexts.count == 2 && $0.valuesTexts[1]?.values.first?.amount != 0 }
    }
    
    var emptyRows: [ExtractedRow] {
        allRows.filter { $0.hasNilValues }
    }
    
    func invalidRows(using validRatio: Double? = nil, threshold: Double = RatioErrorPercentageThreshold, containingLessThanPrefix: Bool = false) -> [ExtractedRow] {
        guard let validRatio = validRatio ?? self.validRatio else {
            return []
        }
        
        return allRows.filter {
            /// Do not consider rows with completely nil or zero values as invalid
            guard !$0.hasNilValues, !$0.hasZeroValues else {
                return false
            }
            
            if containingLessThanPrefix {
                guard $0.valuesTextsContainLessThanPrefix else {
                    return false
                }
            }
                    
            /// Consider anything else without a ratio as invalid (implying that one side is `nil`)
            guard let ratio = $0.ratioColumn1To2 else {
                return true
            }
            
            /// Consider a row invalid if its ratio has a difference from the validRatio greater than the error threshold
            let errorPercentage = ratio.errorPercentage(with: validRatio)
            return errorPercentage > threshold
        }
    }
    
    /**
     Determine this by either:
     -[X]  Getting the modal value in the array of ratios (rounded to 1 decimal place), and then getting the average of all the actual ratios
     -[ ]  Using the header texts if that's not available or using the header texts in the array to find the ratio
     */
    var validRatio: Double? {
        guard let mode = allRatiosOfColumn1To2.modalAverage(consideringNumberOfPlaces: 1) else {
            return allRatiosOfColumn1To2.modalAverage(consideringNumberOfPlaces: 0)
        }
        return mode
    }
    
    var allRatiosOfColumn1To2: [Double] {
        columns.map { $0.rows.compactMap { $0.ratioColumn1To2 } }.reduce([], +)
    }

    var macrosValidities: [Bool?] {
        var validities: [Bool?] = []
        
        var rows: [ExtractedRow] = []
        for column in columns {
            rows.append(contentsOf: column.rows.filter({
                $0.attributeText.attribute.isEnergyOrMacro
            }))
        }
        guard rows.containsAllMacrosAndEnergy else {
            return Array(repeating: nil, count: numberOfValues)
        }
        
        /// Now that we've confirmed that all macros and energy rows are present
        for i in  0..<numberOfValues {
            guard let energy = rows.valueFor(.energy, valueIndex: i),
                  let carb = rows.valueFor(.carbohydrate, valueIndex: i),
                  let fat = rows.valueFor(.fat, valueIndex: i),
                  let protein = rows.valueFor(.protein, valueIndex: i) else {
                validities.append(nil)
                continue
            }

            //TODO: Use macroAndEnergyValuesAreValid(energyInKcal: Double, carb: Double, fat: Double, protein: Double) instead, after running tests
            //TODO: Replace coefficients with precise values from constants such as KcalsPerGramOfFat
            //TODO: Use the constant we have for 4.184 (KcalsPerKilojule) making sure we've named in correctly while we're at it—should'nt it be KjPerKcal
            var calculatedEnergy = (carb.amount * 4) + (protein.amount * 4) + (fat.amount * 9)
            if energy.unit == .kj || energy.unit == nil {
                calculatedEnergy = calculatedEnergy * 4.184
            }
            let errorPercentage = (abs(energy.amount - calculatedEnergy) / calculatedEnergy) * 100.0
            if errorPercentage <= ErrorPercentageThresholdEnergyCalculation {
                validities.append(true)
            } else {
                validities.append(false)
            }
        }
        
        return validities
    }

    func macroAndEnergyValuesAreValid(energyInKcal: Double, carb: Double, fat: Double, protein: Double) -> Bool {
        let calculatedEnergy = (carb * KcalsPerGramOfCarb) + (protein * KcalsPerGramOfProtein) + (fat * KcalsPerGramOfFat)
        let errorPercentage = (abs(energyInKcal - calculatedEnergy) / calculatedEnergy) * 100.0
        return errorPercentage <= ErrorPercentageThresholdEnergyCalculation
    }
}

let ErrorPercentageThresholdEnergyCalculation = 5.0

extension Array where Element == ExtractedRow {
    
    func valueFor(_ attribute: Attribute, valueIndex: Int) -> Value? {
        first(where: { $0.attributeText.attribute == attribute })?.valuesTexts[valueIndex]?.values.first
    }
    
    var containsAllMacrosAndEnergy: Bool {
        filter({ $0.attributeText.attribute.isEnergyOrMacro }).count == 4
    }
}

extension Attribute {
    var isEnergyOrMacro: Bool {
        self == .energy
        || self == .carbohydrate
        || self == .fat
        || self == .protein
    }
}

extension Double {
    func errorPercentage(with double: Double) -> Double {
        let difference = abs(self - double)
        return (difference/self) * 100.0
    }
    
    var roundedNutrientAmount: Double {
        if self < 0.02 {
            return self.rounded(toPlaces: 3)
        } else {
            return self.rounded(toPlaces: 2)
        }
    }
}

extension CGFloat {
    var roundedNutrientAmount: CGFloat {
        Double(self).roundedNutrientAmount
    }
}

extension Array where Element == Double {

    func modalAverage(consideringNumberOfPlaces places: Int) -> Double? {
        
        /// For each value in array
        /// Get value rounded off to `places` places
        var dict: [Double: [Double]] = [:]
        for double in self {
            let rounded = double.rounded(toPlaces: places)
            guard let array = dict[rounded] else {
                dict[rounded] = [double]
                continue
            }
            dict[rounded] = array + [double]
        }
        
        var modes: [(roundedValue: Double, values: [Double])] = []
        for (rounded, values) in dict {
            /// If we don't already have a mode, add this
            guard let count = modes.first?.values.count else {
                modes = [(rounded, values)]
                continue
            }
            /// Ignore any set of values that appears less than any of the modes we have so far
            guard values.count >= count else {
                continue
            }
            
            if values.count > count {
                /// If this pair of values exceeds in frequency as the current mode(s), replace them
                modes = [(rounded, values)]
            } else {
                /// If not, that means it equals in frequency, so add this to the array
                modes.append((rounded, values))
            }
        }
        
        /// Make sure we have exactly one mode before returning it
        guard modes.count == 1, let mode = modes.first else {
            return nil
        }
        
        return mode.values.average
    }
}

extension Array where Element: BinaryInteger {

    /// The average value of all the items in the array
    var average: Double {
        if self.isEmpty {
            return 0.0
        } else {
            let sum = self.reduce(0, +)
            return Double(sum) / Double(self.count)
        }
    }

}

extension Array where Element: BinaryFloatingPoint {

    /// The average value of all the items in the array
    var average: Double {
        if self.isEmpty {
            return 0.0
        } else {
            let sum = self.reduce(0, +)
            return Double(sum) / Double(self.count)
        }
    }

}

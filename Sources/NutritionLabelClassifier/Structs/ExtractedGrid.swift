import SwiftUI
import VisionSugar
import SwiftSugar

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
        
        //TODO: Possibly do this conditionally only if there's two column values
        //TODO: Also include header values if available to increase the chances off determining the valid ratio
        fixInvalidRows()
        fillInRowsWithOneMissingValue()
        //TODO: Do this before fixing invalid rows so that we have as many valid rows as possible to grab the ratio from
        fixSingleInvalidMacroOrEnergyRow()
        removeEmptyValues()
    }
    
    var values: [[[Value?]]] {
        columns.map {
            $0.rows.map { $0.valuesTexts.map { $0?.values.first } }
        }
    }
}

let RatioErrorPercentageThreshold = 2.0

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
        for i in indices {
            var column = self[i]
            if column.contains(row) {
                column.modify(row, with: newValues)
                self[i] = column
            }
        }
    }
}
extension ExtractedColumn {
    mutating func modify(_ row: ExtractedRow, with newValues: (Value, Value)) {
        rows.modify(row, with: newValues)
    }
    
    func contains(_ row: ExtractedRow) -> Bool {
        rows.contains(where: { $0.attributeText.attribute == row.attributeText.attribute })
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
}

extension ExtractedRow {
    mutating func modify(with newValues: (Value, Value)) {
        if let existing = valuesTexts[0] {
            var new = existing
            new.values = [newValues.0]
            valuesTexts[0] = new
        } else {
            valuesTexts[0] = ValuesText(values: [newValues.0])
        }
        
        if let existing = valuesTexts[1] {
            var new = existing
            new.values = [newValues.1]
            valuesTexts[1] = new
        } else {
            valuesTexts[1] = ValuesText(values: [newValues.1])
        }
    }
}

extension ExtractedGrid {

    
    
    mutating func modify(_ row: ExtractedRow, withNewValues newValues: (Value, Value)) {
        print("2️⃣ Correct row: \(row.attributeText.attribute) with: \(newValues.0.description) and \(newValues.1.description)")
        columns.modify(row, with: newValues)
        print("2️⃣ done.")
    }

    mutating func fillInRowsWithOneMissingValue() {
        /// For each row with one missing value
        /// Use the `validRatio` to fill in the missing value
    }
    
    func calculateValue(for attribute: Attribute, in index: Int) -> Double? {
        print("2️⃣ Calculate \(attribute) in column \(index)")
        guard allRows.containsAllMacrosAndEnergy else {
            return nil
        }
        
        switch attribute {
        case .carbohydrate:
            guard let fat = allRows.valueFor(.fat, valueIndex: index)?.amount,
                  let protein = allRows.valueFor(.protein, valueIndex: index)?.amount,
                  let energyValue = allRows.valueFor(.energy, valueIndex: index)
            else {
                return nil
            }
            
            //TODO: Modularize this before repeating for other cases
            let energy: Double
            if energyValue.unit == .kj {
                energy = energyValue.amount / KcalsPerKilojule
            } else {
                energy = energyValue.amount
            }
            //TODO: Fix equation here
            return (energy - (protein * KcalsPerGramOfProtein) - (fat * KcalsPerGramOfFat)) / KcalsPerGramOfCarb
            
//        case .fat:
//        case .protein:
//        case .energy:
        default:
            return nil
        }
    }
    
    mutating func fixSingleInvalidMacroOrEnergyRow() {
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
            modify(invalidRow, withNewValues: (validValue, Value(amount: calculatedValue, unit: .g)))
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
            modify(invalidRow, withNewValues: (Value(amount: calculatedValue, unit: .g), validValue))
        }
        print("took: \(CFAbsoluteTimeGetCurrent()-start)s")
        print("We here")
        /// If that's the case, then use the equation to determine that value and fill it in
    }
    
    /// Remove all rows that are empty (containing all nil values)
    mutating func removeEmptyValues() {
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
    
    mutating func correct(_ row: ExtractedRow, for validRatio: Double) {
        /// Try and use the alternative text candidates to see if one satisfies the ratio requirement (of being within an error margin of it)
        guard let valuesText1 = row.valuesTexts[0], let valuesText2 = row.valuesTexts[1] else {
            return
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
                    return
                }
            }
        }
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
    
    var allMacroAndEnergyRows: [ExtractedRow]? {
        guard allRows.containsAllMacrosAndEnergy else { return nil }
        return allRows.filter { $0.attributeText.attribute.isEnergyOrMacro }
    }
    
    var invalidMacroAndEnergyRows: [ExtractedRow] {
        invalidRows.filter { $0.attributeText.attribute.isEnergyOrMacro }
    }
    
    func invalidRows(using validRatio: Double) -> [ExtractedRow] {
        return allRows.filter {
            /// Do not consider rows with completely nil or zero values as invalid
            guard !$0.hasNilValues, !$0.hasZeroValues else {
                return false
            }
                    
            /// Consider anything else without a ratio as invalid (implying that one side is `nil`)
            guard let ratio = $0.ratioColumn1To2 else {
                return true
            }
            /// Consider a row invalid if its ratio has a difference from the validRatio greater than the error threshold
            return ratio.errorPercentage(with: validRatio) > RatioErrorPercentageThreshold
        }
    }
    
    /**
     Determine this by either:
     -[X]  Getting the modal value in the array of ratios (rounded to 1 decimal place), and then getting the average of all the actual ratios
     -[ ]  Using the header texts if that's not available or using the header texts in the array to find the ratio
     */
    var validRatio: Double? {
        let start = CFAbsoluteTimeGetCurrent()
        guard let mode = allRatiosOfColumn1To2.modalAverage(consideringNumberOfPlaces: 1) else {
            return nil
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
            
            var calculatedEnergy = (carb.amount * 4) + (protein.amount * 4) + (fat.amount * 9)
            if energy.unit == .kj {
                calculatedEnergy = calculatedEnergy * 4.184
            }
            let errorPercentage = abs(energy.amount - calculatedEnergy) / calculatedEnergy
            let errorThreshold = 0.02
            if errorPercentage <= errorThreshold {
                validities.append(true)
            } else {
                validities.append(false)
            }
        }
        
        return validities
    }
    
}

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
        return (difference/double) * 100.0
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

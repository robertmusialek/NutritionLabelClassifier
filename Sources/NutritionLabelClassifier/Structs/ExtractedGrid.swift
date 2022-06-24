import SwiftUI
import VisionSugar

struct ExtractedGrid {
    let columns: [ExtractedColumn]
    
    var values: [[[Value?]]] {
        []
//        groupedColumns.map { $0.map { $0.valuesTexts.map { $0.values.first } } }
    }
    
    init(extractedAttributes: ExtractedAttributes, groupedColumnsOfValues: [[ValuesTextColumn]]) {
        self.columns = []
        
        insertNilForMissedValues()

        //TODO: This should detect incorrectly read values by determining the ratio between them (if two values are present) and disqualifying values that are past a certain threshold
//        insertNilForIncorrectlyReadValues(&groupedColumns)
        
        //TODO: This should go through the nil values and replace them with correctly scaled values using the ratios. Possibly to be done with observations and not here.
//        replaceNilsWithScaledValues(&groupedColumns)

        
        //TODO: This should do the calculation for the macros and if it's off by a threshold, recalculate whichever one is incorrect by using the ratio of values. ALTHOUGH do this after associating the groups to the extractedAttributes and getting our observations? We might already have this!
//        columns.correctIncorrectlyReadMacros()
    }
    
    /// - Insert `nil`s wherever values failed to be recognized
    ///     Do this if we have a mismatch of element counts between columns
    func insertNilForMissedValues() {
//        for i in groups.indices {
//            guard groups[i].hasMismatchingColumnSizes else {
//                continue
//            }
//            groups[i].insertNilForMissingValues()
//        }
    }
}

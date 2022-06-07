import Foundation
import NutritionLabelClassifier
import XCTest

extension OutputTests {
    
    func compareNutrients() throws {
        try compareRows()
        try compareHeader1()
        try compareHeader2()
    }

    func compareRows() throws {
        guard let expectedNutrients = expectedOutput?.nutrients else {
            XCTAssertNil(observedOutput?.nutrients, m("Observed observedOutput.nutrients without an expectation"))
            return
        }
        
        let observedNutrients = try XCTUnwrap(observedOutput?.nutrients, m("Expected expectedOutput.nutrients wasn't observed"))

        /// For each expected row
        for expectedRow in expectedNutrients.rows {
            guard let observedRow = observedNutrients.rows.first(where: {$0.attribute == expectedRow.attribute}) else {
                XCTFail(m("Expected Nutrient Row wasn't observed for attribute: \(expectedRow.attribute)"))
                continue
            }
            
            XCTAssertEqual(observedRow.value1, expectedRow.value1, m("\(observedRow.attribute).value1"))
            XCTAssertEqual(observedRow.value2, expectedRow.value2, m("\(observedRow.attribute).value2"))
        }
        
        /// Filter out observed rows that weren't expected
        let unexpectedObservedRows = observedNutrients.rows.filter { observedRow in
            !expectedNutrients.rows.contains(where: { $0.attribute == observedRow.attribute })
        }
        /// For each observed row that wasn't expected, generate a failure
        for row in unexpectedObservedRows {
            XCTFail(m("Observed Nutrient wasn't expected — attribute: \(row.attribute), value1: \(row.value1?.description ?? "(nil)"), value2: \(row.value2?.description ?? "(nil)")"))
        }
    }
}

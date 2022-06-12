import Foundation
import NutritionLabelClassifier
import XCTest
    
extension OutputTests {

    func compareServings() throws {
        
        guard let expected = expectedOutput?.serving else {
            XCTAssertNil(observedOutput?.serving, m("Observed observedOutput.serving without an expectation"))
            return
        }
        
        let observed = try XCTUnwrap(observedOutput?.serving, m("Expected expectedOutput.serving wasn't observed"))
        
        XCTAssertEqual(observed.amount, expected.amount, m("serving.amount"))
        XCTAssertEqual(observed.unit, expected.unit, m("serving.unit"))
        XCTAssertEqual(observed.unitName, expected.unitName, m("serving.unitName"))
        
        try compareServingEquivalentSizes()
        try compareServingPerContainers()
    }
    
    func compareServingEquivalentSizes() throws {
        guard let expected = expectedOutput?.serving?.equivalentSize else {
            XCTAssertNil(observedOutput?.serving?.equivalentSize, m("Observed observedOutput.serving.equivalentSize without an expectation"))
            return
        }
        
        let equivalent = try XCTUnwrap(observedOutput?.serving?.equivalentSize, m("Expected expectedOutput.serving.equivalentSize wasn't observed"))

        XCTAssertEqual(equivalent.amount, expected.amount, m("serving.equivalentSize.amount"))
        XCTAssertEqual(equivalent.unit, expected.unit, m("serving.equivalentSize.unit"))
        XCTAssertEqual(equivalent.unitName, expected.unitName, m("serving.equivalentSize.unitName"))
    }
    
    func compareServingPerContainers() throws {
        guard let expected = expectedOutput?.serving?.perContainer else {
            if observedOutput?.serving?.perContainer != nil {
                XCTFail(m("Observed observedOutput.serving.perContainer without an expectation"))
            }
            return
        }
        
        let observed = try XCTUnwrap(observedOutput?.serving?.perContainer, m("Expected expectedOutput.serving.perContainer wasn't observed"))

        XCTAssertEqual(observed.amount, expected.amount, m("serving.perContainer.amount"))
        XCTAssertEqual(observed.name, expected.name, m("serving.perContainer.name"))
    }
}

import XCTest
import SwiftSugar
import TabularData
import VisionSugar
import Zip
import NutritionLabelClassifier

extension OutputTests {
    
    func compareHeader1() throws {
        guard let expected = expectedOutput?.nutrients.headerText1 else {
            if let observed = observedOutput?.nutrients.headerText1 {
                XCTFail(m("Observed headerText1 (of type \(observed.type.rawValue)) without an expectation"))
            }
            return
        }
        
        guard let observed = observedOutput?.nutrients.headerText1 else {
            XCTFail(m("Expected headerText1 (of type \(expected.type.rawValue)) wasn't observed"))
            return
        }

        try compareHeaderTexts(observed: observed, expected: expected, headerNumber: 1)
    }

    func compareHeader2() throws {
        guard let expected = expectedOutput?.nutrients.headerText2 else {
            if let observed = observedOutput?.nutrients.headerText2 {
                XCTFail(m("Observed headerText2 (of type \(observed.type.rawValue)) without an expectation"))
            }
            return
        }
        
        guard let observed = observedOutput?.nutrients.headerText2 else {
            XCTFail(m("Expected headerText2 (of type \(expected.type.rawValue)) wasn't observed"))
            return
        }

        try compareHeaderTexts(observed: observed, expected: expected, headerNumber: 2)
    }

    func compareHeaderTexts(observed: HeaderText, expected: HeaderText, headerNumber i: Int) throws {
        XCTAssertEqual(observed.type, expected.type, m("headerText\(i).type"))
        try compareHeaderServings(observed: observed.serving, expected: expected.serving, headerNumber: i)
    }
    
    func compareHeaderServings(observed: HeaderText.Serving?, expected: HeaderText.Serving?, headerNumber i: Int) throws {
        guard let expected = expected else {
            XCTAssertNil(observed, m("Observed observedOutput.nutrients.headerText\(i).serving without an expectation"))
            return
        }
        
        let observed = try XCTUnwrap(observed, m("expectedOutput.nutrients.headerText\(i).serving"))

        XCTAssertEqual(observed.amount, expected.amount, m("headerText\(i).serving.amount"))
        XCTAssertEqual(observed.unit, expected.unit, m("headerText\(i).serving.unit"))
        XCTAssertEqual(observed.unitName, expected.unitName, m("headerText\(i).serving.unitName"))

        try compareHeaderServingEquivalentSizes(
            observed: observed.equivalentSize,
            expected: expected.equivalentSize,
            headerNumber: i)
    }
    
    func compareHeaderServingEquivalentSizes(observed: HeaderText.Serving.EquivalentSize?, expected: HeaderText.Serving.EquivalentSize?, headerNumber i: Int) throws {
        guard let expected = expected else {
            XCTAssertNil(observed, m("Observed observedOutput.nutrients.headerText\(i).serving.equivalentSize without an expectation"))
            return
        }
        
        let observed = try XCTUnwrap(observed, m("Expected expectedOutput.nutrients.headerText\(i).serving.equivalent wasn't observed"))

        XCTAssertEqual(observed.amount, expected.amount, m("headerText\(i).serving.equivalentSize.amount"))
        XCTAssertEqual(observed.unit, expected.unit, m("headerText\(i).serving.equivalentSize.unit"))
        XCTAssertEqual(observed.unitName, expected.unitName, m("headerText\(i).serving.equivalentSize.unitName"))
    }
}

import XCTest
import SwiftSugar
import TabularData
import VisionSugar
import Zip

@testable import NutritionLabelClassifier

final class NutritionLabelClassifierTests: XCTestCase {
    
    func testClassifier() throws {
        guard RunLegacyTests else { return }
        
        guard SingledOutTestCaseId == nil else { return }
        
        print("🤖 Running Legacy Tests on Test Cases: \(ClassifierTestCases)")
        
        for testCase in ClassifierTestCases {
            
            guard !ClassifierTestCasesToIgnore.contains(testCase) else { continue }
            
            guard let arrayOfRecognizedTexts = arrayOfRecognizedTextsForTestCase(testCase) else {
                XCTFail("Couldn't get array of recognized texts for Test Case \(testCase)")
                return
            }

            let classifier = NutritionLabelClassifier(arrayOfRecognizedTexts: arrayOfRecognizedTexts)
            let observationsDataFrame = classifier.dataFrameOfObservations()
            print(dataFrameWithTextIdsRemoved(from: observationsDataFrame))

            /// Extract `processedNutrients` from data frame
            var processedNutrients: [Attribute: (value1: Value?, value2: Value?)] = [:]
            for row in observationsDataFrame.rows {
                guard let attributeWithId = row[.attribute] as? AttributeText,
                      let valueWithId1 = row[.value1] as? ValueText?,
                      let valueWithId2 = row[.value2] as? ValueText?
                else {
                    XCTFail("Failed to get a processed nutrient for \(testCase)")
                    return
                }
                
                processedNutrients[attributeWithId.attribute] = (valueWithId1?.value, valueWithId2?.value)
            }
            
            print("🧬 Nutrients for Test Case: \(testCase)")
            print(dataFrameWithTextIdsRemoved(from: observationsDataFrame))

            /// Extract `expectedNutrients` from data frame
            guard let expectedNutrientsDataFrame = dataFrameForTestCase(testCase, testCaseFileType: .expectedNutrients) else {
                XCTFail("Couldn't get expected nutrients for Test Case \(testCase)")
                return
            }
            print("📃 Expected Nutrients for Test Case: \(testCase)")
            print(expectedNutrientsDataFrame)

            var expectedNutrients: [Attribute: (value1: Value?, value2: Value?)] = [:]
            for row in expectedNutrientsDataFrame.rows {
                guard let attributeName = row[.attributeString] as? String,
                      let attribute = Attribute(rawValue: attributeName),
                      let value1String = row[.value1String] as? String?,
                      let value2String = row[.value2String] as? String?
                else {
                    XCTFail("Failed to read an expected nutrient for \(row) in Test Case: \(testCase)")
                    return
                }
                
                guard value1String != nil || value2String != nil else {
                    continue
                }
                
                var value1: Value? = nil
                if let value1String = value1String {
                    guard let value = Value(fromString: value1String) else {
                        XCTFail("Failed to convert value1String: \(value1String) for \(testCase)")
                        return
                    }
                    value1 = value
                }
                
                var value2: Value? = nil
                if let value2String = value2String {
                    guard let value = Value(fromString: value2String) else {
                        XCTFail("Failed to convert value2String: \(value2String) for \(testCase)")
                        return
                    }
                    value2 = value
                }

                
                expectedNutrients[attribute] = (value1, value2)
            }
            
            for attribute in expectedNutrients.keys {
                guard let values = processedNutrients[attribute] else {
                    XCTFail("Missing Attribute: \(attribute) for Test Case: \(testCase)")
                    return
                }
                XCTAssertEqual(values.value1, expectedNutrients[attribute]?.value1, "TestCase: \(testCase), Attribute: \(attribute)")
                XCTAssertEqual(values.value2, expectedNutrients[attribute]?.value2, "TestCase: \(testCase), Attribute: \(attribute)")
            }
        }
    }
    
    func testContainsTwoKcalValues() throws {
        for testCase in testCasesForColumnSpanningEnergy {
            let kcalValues = NutritionLabelClassifier.kcalValues(from: testCase.input)
            XCTAssertEqual(kcalValues, testCase.kcal)
        }
    }
    
    func testContainsTwoKjValues() throws {
        for testCase in testCasesForColumnSpanningEnergy {
            let kjValues = NutritionLabelClassifier.kjValues(from: testCase.input)
            XCTAssertEqual(kjValues, testCase.kj)
        }
    }

    func testColumnSpanningHeader() throws {
        for testCase in testCasesForColumnSpanningHeader {
            let headers = NutritionLabelClassifier.columnHeadersFromColumnSpanningHeader(testCase.input)
            XCTAssertEqual(headers.header1, testCase.header1)
            XCTAssertEqual(headers.header2, testCase.header2)
        }
    }
}

//MARK: - Helpers

extension NutritionLabelClassifierTests {
        
    func recognizedTextsForTestCase(_ testCase: Int) -> [RecognizedText]? {
        guard let dataFrame = dataFrameForTestCase(testCase) else {
            XCTFail("Couldn't read file for Test Case \(testCase)")
            return nil
        }
        
        return dataFrame.recognizedTexts
    }
}

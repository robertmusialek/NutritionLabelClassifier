import XCTest
import SwiftSugar
import TabularData
import VisionSugar

@testable import NutritionLabelClassifier

final class TableClassifierTests: XCTestCase {
    
    var currentTestCaseId: UUID = defaultUUID
    
    func testTableClassifier() throws {
        
        try prepareTestCases()
        
        for id in testCaseIds {
            
            if let singledOutTestCase = SingledOutTestCase {
                guard id == singledOutTestCase else {
                    continue
                }
            }
            
            
            guard attributeExpectations.keys.contains(id.uuidString) else {
                continue
            }
            
            guard let array = arrayOfRecognizedTextsForTestCase(withId: id) else {
                XCTFail("Couldn't get array of recognized texts for Test Case \(id)")
                return
            }
            
            currentTestCaseId = id
            print("Checking: \(id)")
            
            let classifier = TableClassifier(arrayOfRecognizedTexts: array)
            let attributes = classifier.getColumnsOfAttributes()
            
            if attributes == attributeExpectations[id.uuidString] {
                print("🤖✅ \(id): \(attributes) as expected")
            } else {
                print("🤖❌ \(id)")
                print("🤖❌ Expected: \(attributeExpectations[id.uuidString]!)")
                print("🤖❌ Got back: \(attributes)")
                print("🤖❌ ----")
            }
            
            XCTAssertEqual(attributes, attributeExpectations[id.uuidString], m("Attributes"))
        }
    }
    
    func m(_ message: String) -> String {
        "\(message) (\(currentTestCaseId))"
    }
}

let attributeExpectations: [String: [[Attribute]]?] = [
    "E84F7C80-50C4-4237-BAAD-BD5C1B958B84": [
        [.energy, .protein, .fat, .saturatedFat, .carbohydrate, .sugar, .sodium, .calcium]
    ],
    "00DC2D0A-2C55-4633-B5AE-DF2BA90C4249": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
    ],
    "3EDD65E5-6363-42E3-8358-21A520ED21CC": [
        [.fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt, .sodium]
    ],
    "2184C983-5761-4F8F-BE7A-E6771E963FFF": [
        [.fat, .saturatedFat, .transFat, .cholesterol, .sodium, .salt, .carbohydrate, .dietaryFibre, .sugar, .addedSugar, .protein]
    ],
    "364EDBD7-004B-4A97-83AA-F6404DE5EEB4": [
        [.energy, .fat, .saturatedFat, .monounsaturatedFat, .polyunsaturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .solubleFibre, .insolubleFibre, .protein, .sodium, .iron, .magnesium, .zinc]
    ],
    "15D5AD72-033E-4CA4-BA87-D6CB6193EC9B": [
        [.energy, .protein, .carbohydrate, .sugar, .fat, .saturatedFat, .monounsaturatedFat, .polyunsaturatedFat, .transFat, .cholesterol, .dietaryFibre, .solubleFibre, .insolubleFibre, .sodium, .magnesium, .iron, .zinc]
    ],
    "43F947A2-4E96-496B-884B-DF7C960F82FE": [
        [.energy, .protein, .fat, .carbohydrate, .sugar, .dietaryFibre, .iron, .magnesium, .zinc, .folicAcid, .vitaminA, .vitaminB1, .vitaminB12]
    ],
    "478883E6-2CA8-4C86-9A9F-A3FD71EA5BBE": [
        [.energy, .fat, .saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat, .cholesterol, .sodium, .carbohydrate, .dietaryFibre, .sugar, .addedSugar, .protein, .vitaminD, .calcium, .iron, .potassium, .thiamin, .riboflavin, .niacin, .vitaminB6, .folate, .folicAcid, .vitaminB12]
    ],
    "986EFEB4-069E-4091-805E-8C9A031611F3": [
        [.energy, .protein, .fat, .saturatedFat, .transFat, .carbohydrate, .sugar, .sodium]
    ],
    "B19E1AAD-F0A1-4F0E-B443-BF69894125E8": [
        [.energy, .protein, .fat, .saturatedFat, .transFat, .carbohydrate, .sugar, .sodium]
    ],
    "DD77C26D-4004-4071-B2B1-D228B258A893": [
        [.energy, .protein, .fat, .saturatedFat, .transFat, .carbohydrate, .sugar, .sodium]
    ],
    "81840F7C-B156-4A21-AE5B-A55531AA6B2D": [
        [.energy, .protein, .fat, .saturatedFat, .transFat, .carbohydrate, .sugar, .sodium]
    ],
    "2A79F2EC-9A9D-4CF0-B06A-8A634B7C61B1": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .protein, .salt]
    ],
    "DEB07FE7-3C3D-44E9-83AD-2234228A4F02": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .protein, .salt]
    ],
    "0748DBAE-1379-40CF-A29C-0D342F53E7E3": [
        [.energy, .fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .sodium, .salt]
    ],
    "826DB226-9FCD-4662-A1CD-5FD862493D55": [
        [.energy, .fat, .saturatedFat, .transFat, . carbohydrate, .sugar, .protein, .sodium, .salt]
    ],
    "B1B04BC0-212D-442E-AF10-2F860400AE45": [
        [.energy, .fat, .saturatedFat, .transFat, . carbohydrate, .sugar, .protein, .sodium, .salt]
    ],
    "5FEDB3DF-4214-44EF-A390-3C5CB3C1DA14": [
        [.energy, .fat, .saturatedFat, .transFat, . carbohydrate, .sugar, .protein, .sodium, .salt]
    ],
    "22801297-A39C-4F80-AE1D-858AA6A68DDC": [
        [.energy, .fat, .saturatedFat, .transFat, . carbohydrate, .sugar, .protein, .sodium, .salt]
    ],
    "03A07980-DDEC-41A6-8130-080F582FB5C3": [
        [.energy, .fat, .saturatedFat, .transFat, .cholesterol, .sodium, .carbohydrate, .dietaryFibre, .sugar, .addedSugar, .protein, .vitaminD, .calcium, .iron, .potassium]
    ],
    "7E6948F3-3CBC-4DE3-8E18-7FD2E9EFD79E": [
        [.energy, .protein, .carbohydrate, .sugar, .starch, .fat, .saturatedFat, .monounsaturatedFat, .polyunsaturatedFat, .dietaryFibre, .salt, .sodium, .calcium]
    ],
    "38F77747-253E-4E3B-A5E9-D74B4EE2CBC0": [
        [.energy, .protein, .carbohydrate, .sugar, .fat, .saturatedFat, .dietaryFibre, .sodium, .salt, .calcium]
    ],
    "EDAA3E38-55CC-4202-8128-91A04883AB33": [
        [.energy, .protein, .carbohydrate, .sugar, .fat, .saturatedFat, .dietaryFibre, .sodium, .salt, .calcium]
    ],
    "6C225FA4-44FF-45D7-B723-3AF4DD1D4E40": [
        [.energy, .protein, .gluten, .fat, .saturatedFat, .carbohydrate, .sugar, .sodium, .calcium]
    ],
    "E7EFDA78-DC5B-4E4F-B82A-F04DBBE04577": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
    ],
    "C05EDF6E-BB82-49FB-B745-1B8984987762": [
        [.energy, .protein, .carbohydrate, .sugar, .fat, .saturatedFat, .dietaryFibre, .sodium]
    ],
    "21AB8151-540A-41A9-BAB2-8674FD3A46E7": [
        [.energy, .fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .sodium, .salt]
    ],
    "02CE7C0B-CA9C-4E63-8E42-5D8C105FE320": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .protein, .salt]
    ],
    "A049E005-AB5E-4474-92B2-979EBC347FB5": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
    ],
    "77B1E2FD-7879-4C75-9CA4-187C3EDAB858": [
        [.energy, .protein, .fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .dietaryFibre, .sodium, .calcium]
    ],
    "F3B96913-B2CD-4FFB-99B1-B277395BD003": [
        [.energy, .protein, .fat, .saturatedFat, .carbohydrate, .sugar, .sodium]
    ],
    "0DEA4407-48DF-4A16-8488-0EB967CB13ED": [
        [.energy, .protein, .gluten, .fat, .saturatedFat, .carbohydrate, .sugar, .sodium, .calcium]
    ],
    "C132B648-8974-457A-8EE6-824688D901EA": [
        [.energy, .protein, .fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .dietaryFibre, .sodium, .calcium]
    ],
    "991D390B-B741-4821-8DAD-B0F967CE9D3B": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt, .calcium, .vitaminD]
    ],
    "6BAD0EB1-8BED-4DD9-8FD8-C9861A267A3D": [
        [.energy, .protein, .fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .dietaryFibre, .sodium, .calcium]
    ],
    "024A0939-FF3D-4312-868F-F82565C58ED9": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
    ],
    "7A686ECF-A383-4ACF-9868-A290701D92F3": [
        [.energy, .fat, .saturatedFat, .sugar, .dietaryFibre, .protein, .salt]
    ],
    "81344E05-FDC0-44D3-AA58-61259F3D2AE6": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .protein, .salt]
    ],
    "9671423C-3C8F-484F-A462-7584660C7149": [
        [.energy, .fat, .saturatedFat, .carbohydrate],
        [.sugar, .dietaryFibre, .protein, .salt]
    ],
    "0AA10182-06ED-46BE-AC45-19BFFADA9DC9": [
        [.energy, .fat, .saturatedFat, .carbohydrate],
        [.sugar, .dietaryFibre, .protein, .salt]
    ],
    "7648338E-8AC8-4C03-AAA1-AC8FC76E7368": [
        [.energy, .carbohydrate, .sugar, .addedSugar],
        [.fat, .saturatedFat, .transFat, .cholesterol, .sodium]
    ],
    "4CF0CBA5-C746-4844-BF54-27A92C808280": nil,
]

let SingledOutTestCase: UUID? = UUID(uuidString: "4CF0CBA5-C746-4844-BF54-27A92C808280")!
//let SingledOutTestCase: UUID? = nil

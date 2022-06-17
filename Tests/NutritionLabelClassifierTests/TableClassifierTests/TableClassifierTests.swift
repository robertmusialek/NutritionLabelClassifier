import XCTest
import SwiftSugar
import TabularData
import VisionSugar

@testable import NutritionLabelClassifier

final class TableClassifierTests: XCTestCase {
    
    var currentTestCaseId: UUID = defaultUUID
    
    func testTableClassifier() throws {
        
        try prepareTestCaseImages()
        
        var numberOfPassedTests = 0
        var numberOfFailedTests = 0
        
        for id in testCaseIds {
            
            if let singledOutTestCase = SingledOutTestCase {
                guard id == singledOutTestCase else {
                    continue
                }
            }
            
            guard attributeExpectations.keys.contains(id.uuidString) else {
                continue
            }
            
            guard let image = imageForTestCase(withId: id) else {
                XCTFail("Couldn't get image for Test Case \(id)")
                return
            }
            
            currentTestCaseId = id
            print("🧮 Checking: \(id)")
            
//            let classifier = NutritionLabelClassifier(image: image, contentSize: CGSize(width: 428.0, height: 376.0))
            let classifier = NutritionLabelClassifier(image: image, contentSize: image.size)
            classifier.onCompletion = {
                
                let start = CFAbsoluteTimeGetCurrent()
                
                let tableClassifier = TableClassifier(visionResult: classifier.visionResult)
                let attributes = tableClassifier.getColumnsOfAttributes()
                
                if attributes == attributeExpectations[id.uuidString] {
                    print("🤖✅ \(id)")
                    if let attributes = attributes {
//                        print("🤖✅ \(id): \(attributes) as expected (classification took: \(CFAbsoluteTimeGetCurrent()-start)s)")
                    } else {
//                        print("🤖✅ \(id): nil as expected (classification took: \(CFAbsoluteTimeGetCurrent()-start)s)")
                    }
                    numberOfPassedTests += 1
                } else {
                    print("🤖❌ \(id)")
                    if let expectation = attributeExpectations[id.uuidString]! {
                        print("🤖❌ Expected: \(expectation)")
                    }
                    if let attributes = attributes {
                        print("🤖❌ Got back: \(attributes)")
                    }
                    print("🤖❌ ----")
                    numberOfFailedTests += 1
                }
                
                XCTAssertEqual(attributes, attributeExpectations[id.uuidString], self.m("Attributes"))
            }
            
            classifier.classify()
        }
        
        print("🤖 Failed: \(numberOfFailedTests) tests")
        print("🤖 Passed: \(numberOfPassedTests) tests")
    }
    
    func m(_ message: String) -> String {
        "\(message) (\(currentTestCaseId))"
    }
}

let attributeExpectations: [String: [[Attribute]]?] = [
//    "E84F7C80-50C4-4237-BAAD-BD5C1B958B84": [
//        [.energy, .protein, .fat, .saturatedFat, .carbohydrate, .sugar, .sodium, .calcium]
//    ],
//    "00DC2D0A-2C55-4633-B5AE-DF2BA90C4249": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "3EDD65E5-6363-42E3-8358-21A520ED21CC": [
//        [.fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt, .sodium]
//    ],
//    "2184C983-5761-4F8F-BE7A-E6771E963FFF": [
//        [.fat, .saturatedFat, .transFat, .cholesterol, .sodium, .salt, .carbohydrate, .dietaryFibre, .sugar, .addedSugar, .protein]
//    ],
//    "364EDBD7-004B-4A97-83AA-F6404DE5EEB4": [
//        [.energy, .fat, .saturatedFat, .monounsaturatedFat, .polyunsaturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .solubleFibre, .insolubleFibre, .protein, .sodium, .iron, .magnesium, .zinc]
//    ],
//    "15D5AD72-033E-4CA4-BA87-D6CB6193EC9B": [
//        [.energy, .protein, .carbohydrate, .sugar, .fat, .saturatedFat, .monounsaturatedFat, .polyunsaturatedFat, .transFat, .cholesterol, .dietaryFibre, .solubleFibre, .insolubleFibre, .sodium, .magnesium, .iron, .zinc]
//    ],
//    "43F947A2-4E96-496B-884B-DF7C960F82FE": [
//        [.energy, .protein, .fat, .carbohydrate, .sugar, .dietaryFibre, .iron, .magnesium, .zinc, .folicAcid, .vitaminA, .vitaminB1, .vitaminB12]
//    ],
//    "478883E6-2CA8-4C86-9A9F-A3FD71EA5BBE": [
//        [.energy, .fat, .saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat, .cholesterol, .sodium, .carbohydrate, .dietaryFibre, .sugar, .addedSugar, .protein, .vitaminD, .calcium, .iron, .potassium, .thiamin, .riboflavin, .niacin, .vitaminB6, .folate, .folicAcid, .vitaminB12]
//    ],
//    "986EFEB4-069E-4091-805E-8C9A031611F3": [
//        [.energy, .protein, .fat, .saturatedFat, .transFat, .carbohydrate, .sugar, .sodium]
//    ],
//    "B19E1AAD-F0A1-4F0E-B443-BF69894125E8": [
//        [.energy, .protein, .fat, .saturatedFat, .transFat, .carbohydrate, .sugar, .sodium]
//    ],
//    "DD77C26D-4004-4071-B2B1-D228B258A893": [
//        [.energy, .protein, .fat, .saturatedFat, .transFat, .carbohydrate, .sugar, .sodium]
//    ],
//    "81840F7C-B156-4A21-AE5B-A55531AA6B2D": [
//        [.energy, .protein, .fat, .saturatedFat, .transFat, .carbohydrate, .sugar, .sodium]
//    ],
//    "2A79F2EC-9A9D-4CF0-B06A-8A634B7C61B1": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .protein, .salt]
//    ],
//    "DEB07FE7-3C3D-44E9-83AD-2234228A4F02": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .protein, .salt]
//    ],
//    "0748DBAE-1379-40CF-A29C-0D342F53E7E3": [
//        [.energy, .fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .sodium, .salt]
//    ],
//    "826DB226-9FCD-4662-A1CD-5FD862493D55": [
//        [.energy, .fat, .saturatedFat, .transFat, . carbohydrate, .sugar, .protein, .sodium, .salt]
//    ],
//    "B1B04BC0-212D-442E-AF10-2F860400AE45": [
//        [.energy, .fat, .saturatedFat, .transFat, . carbohydrate, .sugar, .protein, .sodium, .salt]
//    ],
//    "5FEDB3DF-4214-44EF-A390-3C5CB3C1DA14": [
//        [.energy, .fat, .saturatedFat, .transFat, . carbohydrate, .sugar, .protein, .sodium, .salt]
//    ],
//    "22801297-A39C-4F80-AE1D-858AA6A68DDC": [
//        [.energy, .fat, .saturatedFat, .transFat, . carbohydrate, .sugar, .protein, .sodium, .salt]
//    ],
//    "03A07980-DDEC-41A6-8130-080F582FB5C3": [
//        [.energy, .fat, .saturatedFat, .transFat, .cholesterol, .sodium, .carbohydrate, .dietaryFibre, .sugar, .addedSugar, .protein, .vitaminD, .calcium, .iron, .potassium]
//    ],
//    "7E6948F3-3CBC-4DE3-8E18-7FD2E9EFD79E": [
//        [.energy, .protein, .carbohydrate, .sugar, .starch, .fat, .saturatedFat, .monounsaturatedFat, .polyunsaturatedFat, .dietaryFibre, .salt, .sodium, .calcium]
//    ],
//    "38F77747-253E-4E3B-A5E9-D74B4EE2CBC0": [
//        [.energy, .protein, .carbohydrate, .sugar, .fat, .saturatedFat, .dietaryFibre, .sodium, .salt, .calcium]
//    ],
//    "EDAA3E38-55CC-4202-8128-91A04883AB33": [
//        [.energy, .protein, .carbohydrate, .sugar, .fat, .saturatedFat, .dietaryFibre, .sodium, .salt, .calcium]
//    ],
//    "6C225FA4-44FF-45D7-B723-3AF4DD1D4E40": [
//        [.energy, .protein, .gluten, .fat, .saturatedFat, .carbohydrate, .sugar, .sodium, .calcium]
//    ],
//    "E7EFDA78-DC5B-4E4F-B82A-F04DBBE04577": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "C05EDF6E-BB82-49FB-B745-1B8984987762": [
//        [.energy, .protein, .carbohydrate, .sugar, .fat, .saturatedFat, .dietaryFibre, .sodium]
//    ],
//    "21AB8151-540A-41A9-BAB2-8674FD3A46E7": [
//        [.energy, .fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .sodium, .salt]
//    ],
//    "02CE7C0B-CA9C-4E63-8E42-5D8C105FE320": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .protein, .salt]
//    ],
//    "A049E005-AB5E-4474-92B2-979EBC347FB5": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "77B1E2FD-7879-4C75-9CA4-187C3EDAB858": [
//        [.energy, .protein, .fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .dietaryFibre, .sodium, .calcium]
//    ],
//    "F3B96913-B2CD-4FFB-99B1-B277395BD003": [
//        [.energy, .protein, .fat, .saturatedFat, .carbohydrate, .sugar, .sodium]
//    ],
//    "0DEA4407-48DF-4A16-8488-0EB967CB13ED": [
//        [.energy, .protein, .gluten, .fat, .saturatedFat, .carbohydrate, .sugar, .sodium, .calcium]
//    ],
//    "C132B648-8974-457A-8EE6-824688D901EA": [
//        [.energy, .protein, .fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .dietaryFibre, .sodium, .calcium]
//    ],
//    "991D390B-B741-4821-8DAD-B0F967CE9D3B": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt, .calcium, .vitaminD]
//    ],
//    "6BAD0EB1-8BED-4DD9-8FD8-C9861A267A3D": [
//        [.energy, .protein, .fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .dietaryFibre, .sodium, .calcium]
//    ],
//    "024A0939-FF3D-4312-868F-F82565C58ED9": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "7A686ECF-A383-4ACF-9868-A290701D92F3": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "81344E05-FDC0-44D3-AA58-61259F3D2AE6": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "9671423C-3C8F-484F-A462-7584660C7149": [
//        [.energy, .fat, .saturatedFat, .carbohydrate],
//        [.sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "0AA10182-06ED-46BE-AC45-19BFFADA9DC9": [
//        [.energy, .fat, .saturatedFat, .carbohydrate],
//        [.sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "7648338E-8AC8-4C03-AAA1-AC8FC76E7368": [
//        [.energy, .carbohydrate, .sugar, .addedSugar],
//        [.fat, .saturatedFat, .transFat, .cholesterol, .sodium]
//    ],
//    "CDD8E0DD-7D2B-4802-9C1D-54EFFBB71E58": [
//        [.energy, .fat, .saturatedFat, .transFat, .cholesterol, .sodium, .carbohydrate, .dietaryFibre, .sugar, .protein, .calcium]
//    ],
//    "7CB18F78-A24A-435B-B053-6D186C8C4E2C": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .polyols, .protein, .salt]
//    ],
//    "AC1F7D24-296F-4346-883D-E10890938861": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .polyols, .protein, .salt]
//    ],
//    "413A3118-6D94-4158-8B31-FBC3AAA47FCE": [
//        [.energy, .protein, .carbohydrate, .sugar, .fat, .transFat, .saturatedFat]
//    ],
//    "DE476A74-8174-4E9C-81DA-450F578F039D": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .protein, .salt]
//    ],
//    "8CE7C875-BF15-42A1-A49D-A216D3329C9A": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .protein, .salt]
//    ],
//    "81942184-145C-4858-884A-8A76B9BD6498": [
//        [.energy, .protein, .gluten, .fat, .saturatedFat, .carbohydrate, .sugar, .sodium]
//    ],
//    "75C66881-51E5-4A42-92E6-F3B3953BC8E6": [
//        [.energy, .fat, .saturatedFat, .monounsaturatedFat, .polyunsaturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt, .sodium]
//    ],
//    "9C26D1D5-50B2-4933-B906-29824617FD96": [
//        [.energy, .fat, .saturatedFat, .monounsaturatedFat, .polyunsaturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt, .sodium]
//    ],
//    "1B51A831-FE9C-4752-B526-0ED7823EA591": [
//        [.energy, .fat, .saturatedFat, .monounsaturatedFat, .polyunsaturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt, .sodium]
//    ],
//    
//    "6682E31B-6674-47F7-BF71-CA3B2C7713DC": [
//        [.fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt, .sodium]
//    ],
//    "3FFEB5C4-610D-488F-BA4B-9BA1E99C020E": [
//        [.fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt, .sodium]
//    ],
//    "D0A85313-7611-494C-969C-5A2F62A7B9D4": [
//        [.fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt, .sodium]
//    ],
//    "7E330674-3589-4B20-BA7A-283FF70AB01C": [
//        [.fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt, .sodium]
//    ],
//    "BE5881E2-44D1-44ED-8471-0DC980A97244": [
//        [.fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt, .sodium]
//    ],
//    "26440E08-8A8D-450A-A6DF-6F95C5E76C7D": [
//        [.fat, .saturatedFat, .transFat, .cholesterol, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt, .sodium]
//    ],
//    
//    "DD0390E1-6555-40C8-9E58-D7B93D731A88": [
//        [.energy, .carbohydrate, .protein, .fat, .calcium]
//    ],
//
//    "207A16DF-03DF-41DE-B29F-075558953CEA": [
//        [.energy, .fat, .saturatedFat, .transFat, .protein, .carbohydrate, .dietaryFibre, .sugar, .sodium]
//    ],
//
//    "C6FA0D87-4B38-4D8F-9408-26725BB8D463": [
//        [.energy, .fat, .saturatedFat, .transFat, .protein, .carbohydrate, .dietaryFibre, .sugar, .sodium]
//    ],
//    "EB754683-ECF4-4DC4-9978-0B6258581172": [
//        [.energy, .fat, .saturatedFat, .transFat, .protein, .carbohydrate, .dietaryFibre, .sugar, .sodium]
//    ],
//    "A221A0C0-A111-40DF-81BF-C334359B3809": [
//        [.energy, .fat, .saturatedFat, .transFat, .protein, .carbohydrate, .dietaryFibre, .sugar, .sodium]
//    ],
//    "C6BDB073-EF44-46DE-864A-9B3E2EAA2BA8": [
//        [.energy, .fat, .saturatedFat, .transFat, .protein, .carbohydrate, .dietaryFibre, .sugar, .sodium]
//    ],
//    
//    "A4DC9A58-AE29-4C79-A364-827470D60DD6": [
//        [.energy, .fat, .saturatedFat, .transFat, .protein, .carbohydrate, .dietaryFibre, .sugar, .sodium]
//    ],
//    "C19F126E-6D6E-464A-B7C4-718AA4384CC2": [
//        [.energy, .fat, .saturatedFat, .transFat, .protein, .carbohydrate, .dietaryFibre, .sugar, .sodium]
//    ],
//
//    "99DAA772-983E-4C3E-ABF9-D97D870BC14D": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//
//    "8ABC130C-07E8-4780-898D-1B69950C947D": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "B1E5C59E-7B94-4570-B226-DD9D17BC743E": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "660D2B6A-F56B-46DB-B82C-FF78AAA341AD": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "01BD75D4-6F0D-4F67-B3C6-FC22AE1B157C": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "CADCD350-B6B0-4DD9-9892-872B58F5CC44": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "C9B40B4A-213C-439A-8142-3042072D0B32": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    
//    "736D808A-6D24-4DC3-B448-11A8CA04B15D": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .polyols, .protein, .salt]
//    ],
//    "54B88941-BF23-4D42-8B59-8DDA76F11C9D": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .polyols, .protein, .salt]
//    ],
//    "74ED810B-EF85-4D73-A7F5-D3AA0DDD5CDF": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .polyols, .protein, .salt]
//    ],
//    "C9C4FC00-486C-4D4B-985C-6CDDC45A466A": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .polyols, .protein, .salt]
//    ],
//    "C50419CB-B58A-47A1-A9F3-41DD1C7074EE": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .polyols, .protein, .salt]
//    ],
//    "D24F62B2-6DC5-4249-B0A3-3023C0DEB711": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .polyols, .protein, .salt]
//    ],
//    "E790FF79-2551-440E-8C80-ECBCF069881E": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .polyols, .protein, .salt]
//    ],
//    
//    "904EDDD5-A997-4778-A202-0B6A20629058": [
//        [.energy, .fat, .saturatedFat, .transFat, .cholesterol, .sodium, .carbohydrate, .dietaryFibre, .sugar, .protein, .vitaminA, .calcium]
//    ],
//    "E2EF4CFB-3B79-4DFE-9215-A13AFADC858D": [
//        [.energy, .fat, .saturatedFat, .transFat, .cholesterol, .sodium, .carbohydrate, .dietaryFibre, .sugar, .protein, .vitaminA, .calcium]
//    ],
//    
//    "352BBEBB-C688-4A8F-85E1-CB2C0B059E81": [
//        [.vitaminA, .vitaminC, .vitaminD, .vitaminE, .vitaminK, .thiamin, .riboflavin, .niacin, .vitaminB6, .folate, .vitaminB12, .biotin, .pantothenicAcid, .iodine, .zinc, .selenium]
//    ],
//    
//    "97F9F6CB-6F27-47A5-BEAD-D2F901D78C2A": [
//        [.thiamin, .riboflavin, .niacin, .vitaminB6, .folate, .vitaminB12, .biotin, .pantothenicAcid, .iodine, .zinc, .selenium, .manganese, .chromium, .vitaminK2]
//    ],
//    
//    "C86F6FD2-ADA2-45C1-818F-AD4A85DC0611": [
//        [.energy, .protein, .carbohydrate, .sugar, .fat, .saturatedFat, .dietaryFibre, .sodium]
//    ],
//    
//    "31D0CA8B-5069-4AB3-B865-47CD1D15D879": [
//        [.fat, .saturatedFat, .transFat, .cholesterol, .sodium, .salt, .carbohydrate, .dietaryFibre, .sugar, .addedSugar, .protein]
//    ],
//    
//    "0B9B630F-C388-4DB6-BA7E-221D14F83B26": [
//        [.magnesium]
//    ],
//    
//    "233BE115-FB25-42CC-BCF5-A2E34CC473B6": [
//        [.energy, .protein, .fat, .carbohydrate, .sugar, .sodium, .vitaminB3, .vitaminB6, .vitaminB12]
//    ],
//    "6F8BBF90-AD9D-460C-B0D2-AD5C7FEE08B7": [
//        [.energy, .protein, .fat, .saturatedFat, .carbohydrate, .sugar, .sodium]
//    ],
//    
//    "9D43F6AC-7D3B-498F-AF10-991649E94B74": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "3078556E-1AC2-4DFF-8420-0BAB5597DCAC": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "06D9335B-FED5-48BF-8A95-5D3AA1569289": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "32558479-A279-461B-A736-7FE7D14E859A": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    "C9863E9C-792E-4014-8640-8E1D39EFAC59": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
//    
//    "ED60515A-B115-49B8-A047-0612A6A0B2F1": [
//        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
//    ],
    
    
    
    "56426B57-7D52-4870-90FD-AFF2E2CFFA3C": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
    ],
    "F0E29C26-F9F0-4853-AFAB-574D30221F2C": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
    ],
    "0DEEAD69-9ED7-45FD-B5CA-B44A856B10F4": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
    ],
    "667712A5-FC2A-43E3-ADD7-1DF84BFC699E": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
    ],
    "B897533B-B4EE-408C-AB7E-3234200FEDE8": [
        [.energy, .protein, .fat, .saturatedFat, .transFat, .polyunsaturatedFat, .monounsaturatedFat, .carbohydrate, .sugar, .sodium, .potassium]
    ],
    "EC391CA2-6E7C-4AF0-8150-CF9B8EF1B4BC": [
        [.energy, .protein, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .sodium, .potassium]
    ],
    "B2C50752-AE52-493A-AD79-69DA4EA74504": [
        [.energy, .protein, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .sodium, .potassium]
    ],
    "130F9F42-B1DC-4134-B607-D0C28107F360": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .protein, .salt]
    ],
    "39D5570C-8942-4BC5-A707-058B25E0F247": [
        [.energy, .protein, .carbohydrate, .fat]
    ],
    "13A85C40-6714-4465-9802-25ADFCDF53DE": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .protein, .salt]
    ],
    "980B8F1D-7F4A-42FF-BA70-1D003BC5070B": [
        [.energy, .protein, .fat, .saturatedFat, .transFat, .carbohydrate, .sugar, .sodium, .calcium]
    ],
    "B7025C67-51CD-4508-91DB-D8EBED32A872": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
    ],
    "F90778A7-565D-453C-A41C-A8D8138C63D8": [
        [.energy, .protein, .fat, .saturatedFat, .carbohydrate, .sugar, .sodium]
    ],
    "E3BAC0B0-8E46-4C97-A67A-9AFBE5E8ACF7": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
    ],
    "8C7C1D3C-EA76-41D3-852C-4191AC12D28A": [
        [.energy, .fat, .saturatedFat, .carbohydrate, .sugar, .dietaryFibre, .protein, .salt]
    ],
    
    "3C53CC91-34D1-46EE-92BE-328ABDC20342": nil,
    "15C9C2C9-5012-43A3-835A-3FB0A2DD1E2D": nil,
    "0D04AEB7-95B1-4781-AFCA-38BF1036DAAC": nil,
    "26F3916F-B688-49CC-A0DD-4F757B6735FD": nil,
    "B3DC8D45-2F10-41C8-ACDF-2A00AFE6E0D3": nil,
    "0A321001-BD7F-4A8A-8F62-FDE636B64CE3": nil,
    "749A730F-17B1-47DE-9A5B-129C152D657E": nil,
    "AE8C75F6-D65E-4F5F-A2D9-47FC81C158B9": nil,
    "0494F267-A8C9-4796-8D23-DA6098C1AA5B": nil,
    "BF1EE7E6-96C0-4929-8F9B-C3E4EC7782F2": nil,
    "DF58E0D9-56BF-404C-8B36-675F797411A6": nil,
    "0CBD5EF1-01E2-482E-891D-21A32479CFB0": nil,
    "91F8FEFC-DF56-492D-BAB0-3EC24ADB84F3": nil,

//    "FCA442D0-9F3A-4AF9-9460-D3075C7FB2A0": nil,
//    "D65B73DA-E3E0-4968-83EF-06EA3E629A20": nil,
//    "6C3008A5-A6B0-438D-9332-827B52421643": nil,
//    "CC5957B2-1208-4A85-A728-5EABA1348DB9": nil,
//    "BB071452-B8C0-492D-890E-122BDBBF5909": nil,
//    "D3E7433B-AF49-4ACB-84EC-8366795CE048": nil,
//    "18E7934B-8B75-4E60-A041-7837D1E3DC27": nil,
//    "3A7D1894-FD50-4226-8A97-8471F4E34E89": nil,
//    "4CF0CBA5-C746-4844-BF54-27A92C808280": nil,
//    "5410D64B-4A8D-4183-8C81-EC82ABBFA648": nil,
//    "B789ED71-802F-42EF-85A5-FD9FEED77E6F": nil,
//    "083C5BAA-2DDA-42E5-8A6C-DCD1A3E5B7E1": nil,
//    "CE17DE0B-1480-4195-ACD0-C706FF9EE86F": nil,
//    "9CFDEE5E-005E-408F-B1E5-2EF751747988": nil,
//    "85025F31-4CD8-48D5-8AB0-246D8EAF0465": nil,
//    "9BA54F68-9FC5-430B-90C2-158A2BD1B29D": nil,
//    "90520604-4AF2-4C16-8C5E-F522F2309ECE": nil,
//    "92C3B115-CBED-4E4D-B831-4BF7BF973BCD": nil,
//    "674347E4-7B53-4409-95AF-07FD0560ADBA": nil,
//    "0E6CBF93-F98E-4922-8058-CE987BBD9617": nil,
//    "B362A01E-8762-4BD4-B7E9-ACED4D919B5B": nil,
//    "4527F77A-3514-4EAB-9DC1-214D10BBE9BA": nil,
//    "2E51C3CE-7363-412E-AF68-EB3F3ED9B343": nil,
//    "662AD301-6914-49EE-B8D2-DAFE00AF7F7F": nil,
//    "DE38ABA0-A8D7-46A5-8DBB-7E2DE983F9F4": nil,
//    "180F6D30-B077-4787-BE2C-22D3C4FC00E3": nil,
//    "1B9397C9-27E5-4E9F-BE75-17C878A2F323": nil,
//    "40E7C0B9-E9CC-4FA7-93A3-B3623FAB23FF": nil,
//    "7A7E14B8-EFA8-4140-987F-65439B83D99A": nil,
//    "713A721E-A470-4DA8-B44E-E939FEF9777A": nil,
//    "BD53EFF6-2AF9-4FCA-8865-67CCB4BA9B69": nil,
//    "D8809685-A90E-4756-BCA1-79B2D8C0D090": nil,
]

//let SingledOutTestCase: UUID? = UUID(uuidString: "ED60515A-B115-49B8-A047-0612A6A0B2F1")!
let SingledOutTestCase: UUID? = nil

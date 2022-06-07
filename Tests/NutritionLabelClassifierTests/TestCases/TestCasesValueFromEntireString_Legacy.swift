import XCTest

@testable import NutritionLabelClassifier

let testCasesValueFromEntireString_Legacy: [(input: String, value: Value?)] = [
    //MARK: - Test Cases from Test Images 1-15
    
    /// Standard
    ("12.1 g", v(12.1, .g)),
    ("9.0 g", v(9, .g)),
    ("10.9 g", v(10.9, .g)),
    ("8.1 g", v(8.1, .g)),
    ("3.7 g", v(3.7, .g)),
    ("2.7 g", v(2.7, .g)),
    ("0.15 g", v(0.15, .g)),
    ("0.11 g", v(0.11, .g)),
    ("5.5 g", v(5.5, .g)),
    ("4.2 g", v(4.2, .g)),
    ("1.4 g", v(1.4, .g)),
    ("1.1 g", v(1.1, .g)),
    ("0.1 g", v(0.1, .g)),
    ("0.1 g", v(0.1, .g)),
    ("10 mg", v(10, .mg)),
    ("8 mg", v(8, .mg)),
    ("19.5 g", v(19.5, .g)),
    ("15.0 g", v(15, .g)),
    ("0.7 g", v(0.7, .g)),
    ("0.5 g", v(0.5, .g)),
    ("72 mg", v(72, .mg)),
    ("55 mg", v(55, .mg)),
    ("169 mg", v(169, .mg)),
    ("130 mg", v(130, .mg)),
    ("5.4 g", v(5.4, .g)),
    ("43 g", v(43, .g)),
    ("0.1 g", v(0.1, .g)),
    ("0.1 g", v(0.1, .g)),
    ("0g", v(0, .g)),
    ("0 g", v(0, .g)),
    ("4 mg", v(4, .mg)),
    ("3 mg", v(3, .mg)),
    ("14.2 g", v(14.2, .g)),
    ("0.1 g", v(0.1, .g)),
    ("84 mg", v(84, .mg)),
    ("67 mg", v(67, .mg)),
    ("225 mg", v(225, .mg)),
    ("180 mg", v(180, .mg)),
    ("5.6g", v(5.6, .g)),
    ("3.7g", v(3.7, .g)),
    ("9.5g", v(9.5, .g)),
    ("6.3g", v(6.3, .g)),
    ("6.2g", v(6.2, .g)),
    ("4.1 g", v(4.1, .g)),
    ("21.9g", v(21.9, .g)),
    ("14.6g", v(14.6, .g)),
    ("21.3g", v(21.3, .g)),
    ("14.2 g", v(14.2, .g)),
    ("38mg", v(38, .mg)),
    ("124mg", v(124, .mg)),
    ("6.3 g", v(6.3, .g)),
    ("5.0 g", v(5, .g)),
    ("1.6 g", v(1.6, .g)),
    ("1.3 g", v(1.3, .g)),
    ("8 mg", v(8, .mg)),
    ("6 mg", v(6, .mg)),
    ("16.6 g", v(16.6, .g)),
    ("13.3 g", v(13.3, .g)),
    ("0.0 g", v(0, .g)),
    ("0.0 g", v(0, .g)),
    ("88 mg", v(88, .mg)),
    ("70 mg", v(70, .mg)),
    ("200 mg", v(200, .mg)),
    ("160 mg", v(160, .mg)),
    ("70g", v(70, .g)),
    ("7.3g", v(7.3, .g)),
    ("6.8g", v(6.8, .g)),
    ("90g", v(90, .g)),
    ("4.3g", v(4.3, .g)),
    ("5.7g", v(5.7, .g)),
    ("9.5g", v(9.5, .g)),
    ("6.3g", v(6.3, .g)),
    ("6.2 g", v(6.2, .g)),
    ("4.1g", v(4.1, .g)),
    ("17.4g", v(17.4, .g)),
    ("11.6g", v(11.6, .g)),
    ("17.1g", v(17.1, .g)),
    ("11.4g", v(11.4, .g)),
    ("59mg", v(59, .mg)),
    ("39mg", v(39, .mg)),
    ("142 mg", v(142, .mg)),
    ("5.9g", v(5.9, .g)),
    ("4.9 g", v(4.9, .g)),
    ("18.1 g", v(18.1, .g)),
    ("15.1 g", v(15.1, .g)),
    ("18.1 g", v(18.1, .g)),
    ("15.1 g", v(15.1, .g)),
    ("2.2g", v(2.2, .g)),
    ("1.8g", v(1.8, .g)),
    ("0.1g", v(0.1, .g)),
    ("0.1 g", v(0.1, .g)),
    ("0.2g", v(0.2, .g)),
    ("0.2g", v(0.2, .g)),
    ("3.5 g", v(3.5, .g)),
    ("4.4 g", v(4.4, .g)),
    ("12.8 g", v(12.8, .g)),
    ("16.0 g", v(16.0, .g)),
    ("12.7 g", v(12.7, .g)),
    ("15.9 g", v(15.9, .g)),
    ("3.2 g", v(3.2, .g)),
    ("0.06 g", v(0.06, .g)),
    ("0.08 g", v(0.08, .g)),
    ("4.9g", v(4.9, .g)),
    ("6.1g", v(6.1, .g)),
    ("6.9g", v(6.9, .g)),
    ("8.6g", v(8.6, .g)),
    ("6.9g", v(6.9, .g)),
    ("8.6g", v(8.6, .g)),
    ("1.5g", v(1.5, .g)),
    ("1.9g", v(1.9, .g)),
    ("0.2 g", v(0.2, .g)),
    ("0.3g", v(0.3, .g)),
    
    /// To be corrected
    ("17:8 g", v(17.8, .g)),
    ("0:1 mg", v(0.1, .mg)),
    
    /// To be extracted from end
    ("Trans Fat 0g", v(0, .g)),
    ("Cholesterol 0mg", v(0, .mg)),
    ("Sodium 65mg", v(65, .mg)),
    ("Saturated Fat 13g", v(13, .g)),
    ("Trans Fat 0g", v(0, .g)),
    ("Cholesterol 5mg", v(5, .mg)),
    ("Total Carbohydrate 16g", v(16, .g)),
    ("Total Sugars 14g", v(14, .g)),
    ("Protein 2g", v(2, .g)),
    ("Saturated Fat 0g", v(0, .g)),
    ("Trans Fat 0g", v(0, .g)),
    ("Cholesterol 5mg", v(5, .mg)),
    ("Sodium 50mg", v(50, .mg)),
    ("Trans Fat 0g", v(0, .g)),
    ("Sodium 65mg", v(65, .mg)),
    ("(0.2 g", v(0.2, .g)),
    ("Saturated Fat 0g", v(0, .g)),
    ("Trans Fat 0g", v(0, .g)),
    ("Cholesterol 0mg", v(0, .mg)),
    ("Sodium 105mg", v(105, .mg)),
    
    /// Extract from start or middle
    ("186mg 23% RDI*", v(186, .mg)),
    ("Includes 12g Added Sugars 24%", v(12, .g)),
    ("9.5g 14%", v(9.5, .g)),
    ("213mg 27% RDI*", v(213, .mg)),
    ("(0.2 g)", v(0.2, .g)),
    ("Calcium (% RDA) 128 mg (16%)", v(128, .mg)),
    
    ("819kJ", v(819, .kj)),
    ("546kJ", v(546, .kj)),
    ("553kJ", v(553, .kj)),
    ("8400kJ", v(8400, .kj)),
    ("256 kJ", v(256, .kj)),
    ("320 kJ", v(320, .kj)),
    
    /// Need to extract percent first
    ("0% Total Carbohydrates 9g %", v(9, .g)),
    ("0% Total Carbohydrate 20g 7%", v(20, .g)),
    
    /// invalids
    ("CALCIUM (20% RI* PER 100g))", nil), /// invalidated by "PER 100g"
    ("CALCIUM 20% RI* PER 100g", nil), /// invalidated by "PER 100g"
    ("Caring Suer: Go7z (170g) Saturated Fat", nil), /// invalidated by '7' in text before value
    ("Serving Size: Something (170g) Saturated Fat", nil), /// invalidated by semi-colon before value
    ("Serving Size Something (170g) Saturated Fat", nil), /// invalidated by extra-large value

    /// both energy values
    ("396kJ/94kcal", v(396, .kj)),
    ("495 kJ/118kcal", v(495, .kj)),

    /// 4 energy values
//        ("384kJ/91kcal 284kJ/67 kcal", value(0, .kj)),
//        ("(117 kcal (491 kJ| 90 kcal (378 kJ)", value(0, .kj)),
//        ("94 kcal (395 kJ) 75 kcal (315 kJ)", value(0, .kj)),
//        ("113 kcal (475 kJ) 90 kcal (378 kJ)", value(0, .kj)),

    /// multiples
//        ("Energy 116kcal 96kcal", value(0, .kj)),
//        ("223mg 186mg", value(0, .kj)),
    
    // MARK: - Erranousely parsed values (should have been detected multiple attributes)
    
    /// `Vitamin D` and `Calcium`
//        ("Vit. D 0mcg 0% Calcium 58mg 4%", value(0, .kj)),
    
    /// `Saturated Fat` and `Carbohydrate`
//        ("I Container (150g) Saturated Fat 0g 0% Total Carbohydrate 15g 5%", value(0, .kj)),
    
    /// `Cholesterol` and `Sugar`
//        ("Calories from Fat 0 Cholesterol <5mg 1% Sugars 7g", value(0, .kj)),
]

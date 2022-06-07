import SwiftSugar
import TabularData
import VisionSugar

extension NutritionLabelClassifier {
    public struct Regex {
        static let containsTwoKcalValues = #"(?:^.*[^0-9.]+|^)([0-9.]+)[ ]*kcal.*[^0-9.]+([0-9.]+)[ ]*kcal.*$"#
        static let containsTwoKjValues = #"(?:^.*[^0-9.]+|^)([0-9.]+)[ ]*kj.*[^0-9.]+([0-9.]+)[ ]*kj.*$"#
        
        static let twoColumnHeadersWithPer100OnLeft = #"(?:.*per 100[ ]*g[ ])(?:per[ ])?(.*)"#
        static let twoColumnHeadersWithPer100OnRight = #""# /// Use this once a real-world test case has been encountered and added
        
        static let isColumnHeader = #"^(?=((^|.* )per .*|.*100[ ]*g.*|.*serving.*))(?!^.*Servings per.*$)(?!^.*DI.*$).*$"#
    }
    
    public static func kcalValues(from string: String) -> [Double] {
        string.capturedGroups(using: Regex.containsTwoKcalValues).compactMap { Double($0) }
    }
    
    public static func kjValues(from string: String) -> [Double] {
        string.capturedGroups(using: Regex.containsTwoKjValues).compactMap { Double($0) }
    }
    
    //MARK: - Sort these
    
    static func columnHeadersFromColumnSpanningHeader(_ string: String) -> (header1: HeaderString?, header2: HeaderString?) {
        if let rightColumn = string.firstCapturedGroup(using: Regex.twoColumnHeadersWithPer100OnLeft) {
            return (.per100, .perServing(serving: rightColumn))
        }
        return (nil, nil)
    }
    
    static func columnHeader(fromRecognizedText recognizedText: RecognizedText?) -> HeaderString? {
        guard let recognizedText = recognizedText else {
            return nil
        }
        return HeaderString(string: recognizedText.string)
    }
    
    static func columnHeaderRecognizedText(for dataFrame: DataFrame, withColumnName columnName: String, in recognizedTexts: [RecognizedText]) -> RecognizedText? {
        let column: [RecognizedText] = dataFrame.rows.compactMap({
            ($0[columnName] as? RecognizedText)
        })
        
        guard let smallest = column.sorted(by: { $0.rect.width < $1.rect.width}).first else {
            return nil
        }
        
        let preceding = recognizedTexts.filterSameColumn(as: smallest, preceding: true)
        for recognizedText in preceding {
            if recognizedText.string.matchesRegex(Regex.isColumnHeader) {
                return recognizedText
            }
        }
        return nil
    }

    static func columnHeaders(from recognizedTexts: [RecognizedText], using dataFrame: DataFrame) -> (HeaderString?, HeaderString?) {
        guard dataFrame.columns.count == 3 else {
            return (nil, nil)
        }
        
        let header1 = columnHeaderRecognizedText(for: dataFrame, withColumnName: "recognizedText1", in: recognizedTexts)
        let header2 = columnHeaderRecognizedText(for: dataFrame, withColumnName: "recognizedText2", in: recognizedTexts)
        
        return (columnHeader(fromRecognizedText: header1),
                columnHeader(fromRecognizedText: header2))
    }
    
    //TODO: Remove this
    static func columnHeadersRecognizedTexts(from recognizedTexts: [RecognizedText], using dataFrame: DataFrame) -> (RecognizedText?, RecognizedText?) {
        guard dataFrame.columns.count == 3 else {
            return (nil, nil)
        }
        
        let header1 = columnHeaderRecognizedText(for: dataFrame, withColumnName: "recognizedTex1", in: recognizedTexts)
        let header2 = columnHeaderRecognizedText(for: dataFrame, withColumnName: "recognizedTex2", in: recognizedTexts)
        return (header1, header2)
    }
}

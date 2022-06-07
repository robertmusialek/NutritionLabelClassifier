import Foundation

extension Value {
    //TODO: Remove this
    init?(string: String) {
        
        /// First trim out any percentage-signed valued
        var string = string.trimmingPercentageValues
        
        /// Next, invalidate anything that has "per 100g" in it
        if string.matchesRegex(#"per 100[ ]*g"#) {
            return nil
        }
        
        /// If the string contains both 'kj' and 'kcal', extract and remove the kcal-based value (since its smaller)
        if string.hasBothKjAndKcal {
            let kcalSubstringRegex = #"([0-9]+[ ]*kcal)"#
            let groups = string.capturedGroups(using: kcalSubstringRegex)
            if let kcalSubstring = groups.first {
                string = string.replacingOccurrences(of: kcalSubstring, with: "")
            }
        }
        
        let groups = string.capturedGroups(using: Regex.standardPattern, allowCapturingEntireString: true)
        guard groups.count > 1,
              let amount = Double(groups[1].replacingOccurrences(of: ":", with: "."))
        else {
            return nil
        }
        self.amount = amount
        if groups.count == 3 {
            guard let unit = NutritionUnit(string: groups[2].lowercased()) else {
                return nil
            }
//            guard let unit = NutritionUnit(rawValue: groups[2].lowercased()) else {
//                return nil
//            }
            
            /// invalidate extra large 'g' values to account for serving size being misread into value lines sometimes
            if unit == .g, amount > 100 {
                return nil
            }
            
            self.unit = unit
        } else {
            self.unit = nil
        }
    }
}

import Foundation

// MARK: - Output
extension Array where Element == Observation {
    
    var output: Output? {
        Output(serving: serving, nutrients: nutrients)
    }
    
    var serving: Output.Serving? {
        nil
    }
    
    var nutrients: Output.Nutrients {
        Output.Nutrients(
            headerText1: headerText1,
            headerText2: headerText2,
            rows: rows
        )
    }
    
    var headerText1: HeaderText? {
        nil
    }
    
    var headerText2: HeaderText? {
        nil
    }
    
    var rows: [Output.Nutrients.Row] {
        nutrientObservations.map {
            Output.Nutrients.Row(
                attributeText: $0.attributeText,
                valueText1: $0.valueText1,
                valueText2: $0.valueText2
            )
        }
    }
    
    //MARK: - Helpers
    
    var nutrientObservations: [Observation] {
        filter { $0.attributeText.attribute.isNutrientAttribute }
    }
}

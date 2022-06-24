import SwiftUI
import VisionSugar

struct ExtractedAttributes {
    
    /// `AttributeText` columns
    let attributeTextColumns: [[AttributeText]]
    
    init?(visionResult: VisionResult) {
        
        guard !visionResult.mostTextsAreInline else {
            return nil
        }
        
        var columns: [[AttributeText]] = []
        
        for recognizedTexts in visionResult.arrayOfTexts {
            for text in recognizedTexts {
                guard Attribute.haveNutrientAttribute(in: text.string) else {
                    continue
                }
                
                /// Go through texts until a nutrient attribute is found
                let columnOfTexts = visionResult.getColumnOfNutrientLabelTexts(startingFrom: text)
                    .sorted(by: { $0.rect.minY < $1.rect.minY })
                
                guard let column = visionResult.getUniqueAttributeTextsFrom(columnOfTexts) else {
                    continue
                }

                /// First, make sure the column is at least the threshold of attributes long
//                guard column.count >= 3 else {
//                    continue
//                }
                
                if columns.containsArrayWithAnAttributeFrom(column) {
                    
                    if columns.contains(where: {
                        $0.containsAnyAttributeIn(column) && $0.count <= column.count
                    }) {
                        /// filter out the columns
                        columns = columns.filter {
                            !$0.containsAnyAttributeIn(column) ||
                            $0.count >= column.count
                        }
                    }
                    
//                /// Now see if we have any existing columns that is a subset of this column
//                if let index = columns.indexOfSubset(of: column), columns[index].count < column.count {
//
//                    if columns.containsArrayWithAnAttributeFrom(column) {
//                        /**
//                         Consider the following case
//                         ```
//                         (lldb) po column.map { $0.attribute }
//                         ▿ 8 elements
//                           - 0 : Energy
//                           - 1 : Protein
//                           - 2 : Carbohydrate
//                           - 3 : Total Sugars
//                           - 4 : Fat
//                           - 5 : Saturated Fat
//                           - 6 : Dietary Fibre
//                           - 7 : Sodium
//
//                         (lldb) po columns.map { $0.map { $0.attribute } }
//                         ▿ 2 elements
//                           ▿ 0 : 1 element
//                             - 0 : Total Sugars
//                           ▿ 1 : 2 elements
//                             - 0 : Fat
//                             - 1 : Gluten
//                         ```
//                         So we need to replace both of them in this case and only retain the first one
//                         */
//
//                        /// Remove the column
//                        let _ = columns.remove(at: index)
//                    } else {
//                        /// Replace it
//                        columns[index] = column
//                    }
//
//
//                } else if columns.containsArrayWithAnAttributeFrom(column) {
//                    /// Ignore it
//                } else if let index = columns.indexOfArrayContainingAnyAttribute(in: column) {
//                    /// This `column` has attributes that another added `column has`
//                    if columns[index].count < column.count {
//                        /// This column has more attributes, so replace the smaller one with it
//                        columns[index] = column
//                    }
                } else {
                    
                    /// Otherwise, set it as a new column
                    columns.append(column)
                }
            }
        }
        
        /// Sort the columns by the `text.rect.midX` values (so that we get them in the order they appear), and only return the `attribute`s
        let columnsOfAttributes = columns.sorted(by: {
            $0.averageMidX < $1.averageMidX
        })
        
        guard columnsOfAttributes.count > 1 else {
            self.attributeTextColumns = columnsOfAttributes
            return
        }
        
        /// If we've got more than one column, remove any that's less than 3 first
        var unfiltered = columnsOfAttributes.filter { $0.count >= 3 }
//        var filtered: [[Attribute]] = []
//        for array in unfiltered {
//            if
//        }
//        if columnsOfAttributes.count > 1 {
//            return columnsOfAttributes.filter { $0.count >= 3 }
//        } else {
        self.attributeTextColumns = unfiltered
//        }
    }
}

extension ExtractedAttributes {
    
    var attributes: [[Attribute]] {
        attributeTextColumns.map { $0.map { $0.attribute } }
    }
    
    func attributeText(for attribute: Attribute) -> AttributeText? {
        for column in attributeTextColumns {
            for attributeText in column {
                if attributeText.attribute == .energy {
                    return attributeText
                }
            }
        }
        return nil
    }
    
    //TODO: Write tests for these
    var bottomAttributeText: AttributeText? {
        let columns = attributeTextColumns
        var bottom: AttributeText? = nil
        for column in columns {
            for attributeText in column {
                guard let bottomAttributeText = bottom else {
                    bottom = attributeText
                    continue
                }
                if attributeText.text.rect.maxY > bottomAttributeText.text.rect.maxY {
                    bottom = attributeText
                }
            }
        }
        return bottom
    }
    
    var topAttributeText: AttributeText? {
        let columns = attributeTextColumns
        var top: AttributeText? = nil
        for column in columns {
            for attributeText in column {
                guard let topAttributeText = top else {
                    top = attributeText
                    continue
                }
                if attributeText.text.rect.minY < topAttributeText.text.rect.minY {
                    top = attributeText
                }
            }
        }
        return top
    }
    
    var energyAttributeText: AttributeText? {
        for column in attributeTextColumns {
            for attributeText in column {
                if attributeText.attribute == .energy {
                    return attributeText
                }
            }
        }
        return nil
    }
}

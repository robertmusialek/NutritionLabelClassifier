import Foundation
import VisionSugar
import TabularData

extension DataFrame {
    func rowForObservedAttribute(_ attribute: Attribute) -> DataFrame.Rows.Element? {
        rows.first(where: {
            guard let attributeWithId = $0[.attribute] as? AttributeText else { return false }
            return attributeWithId.attribute == attribute
        })
    }

    func attributeText(for attribute: Attribute) -> AttributeText? {
        guard let row = rowForObservedAttribute(attribute) else { return nil }
        return row[.attribute] as? AttributeText
    }

    func valueText1ForAttribute(_ attribute: Attribute) -> ValueText? {
        guard let row = rowForObservedAttribute(attribute) else { return nil }
        return row[.value1] as? ValueText
    }
    
    func valueText2ForAttribute(_ attribute: Attribute) -> ValueText? {
        guard let row = rowForObservedAttribute(attribute) else { return nil }
        return row[.value2] as? ValueText
    }
    
    func doubleTextForAttribute(_ attribute: Attribute) -> DoubleText? {
        guard let row = rowForObservedAttribute(attribute) else { return nil }
        return row[.double] as? DoubleText
    }

    func stringTextForAttribute(_ attribute: Attribute) -> StringText? {
        guard let row = rowForObservedAttribute(attribute) else { return nil }
        return row[.string] as? StringText
    }

    func unitTextForAttribute(_ attribute: Attribute) -> UnitText? {
        guard let stringText = stringTextForAttribute(attribute),
              let unit = NutritionUnit(string: stringText.string) else {
            return nil
        }
        return UnitText(
            unit: unit,
            textId: stringText.textId,
            attributeTextId: stringText.attributeTextId
        )
    }
}

extension String {
    static let attribute = "attribute"
    static let value1 = "value1"
    static let value2 = "value2"
    static let double = "double"
    static let string = "string"
    
    static let attributeString = "attributeString"
    static let value1String = "value1String"
    static let value2String = "value2String"
    static let doubleString = "doubleString"
}
extension DataFrame {

    var headerServingEquivalentSize: HeaderText.Serving.EquivalentSize? {
        let amount: Double
        guard let doubleText = doubleTextForAttribute(.headerServingEquivalentAmount) else {
            return nil
        }
        amount = doubleText.double

        let unit = unitTextForAttribute(.headerServingEquivalentUnit)?.unit
        let unitName = stringTextForAttribute(.headerServingEquivalentUnitSize)?.string
        return HeaderText.Serving.EquivalentSize(amount: amount, unit: unit, unitName: unitName)
    }
    
    var headerServing: HeaderText.Serving? {
        let amount = doubleTextForAttribute(.headerServingAmount)?.double
        let unit = unitTextForAttribute(.headerServingUnit)?.unit
        let unitName = stringTextForAttribute(.headerServingUnitSize)?.string
        let equivalentSize = headerServingEquivalentSize
        
        if amount != nil || unit != nil || unitName != nil || equivalentSize != nil {
            return HeaderText.Serving(
                amount: amount,
                unit: unit,
                unitName: unitName,
                equivalentSize: headerServingEquivalentSize
            )
        } else {
            return nil
        }
    }
    
    func headerText(for attribute: Attribute) -> HeaderText? {
        guard let stringText = stringTextForAttribute(attribute),
              let type = HeaderType(rawValue: stringText.string) else {
            return nil
        }
        guard type == .perServing else {
            return HeaderText(
                type: type,
                textId: stringText.textId,
                attributeTextId: stringText.attributeTextId,
                serving: nil)
        }
        return HeaderText(
            type: .perServing,
            textId: stringText.textId,
            attributeTextId: stringText.attributeTextId,
            serving: headerServing)
    }
    
    var nutrients: Output.Nutrients {
        /// Get all the `Output.Nutrient.Row`s
        let rows: [Output.Nutrients.Row] = rows.compactMap { row in
            guard let attributeText = row[.attribute] as? AttributeText,
                  let value1Text = row[.value1] as? ValueText?,
                  let value2Text = row[.value2] as? ValueText?
            else {
                return nil
            }
            
            guard value1Text != nil || value2Text != nil else {
                return nil
            }
            
            return Output.Nutrients.Row(
                attributeText: attributeText,
                valueText1: value1Text,
                valueText2: value2Text
            )
        }
        
        return Output.Nutrients(
            headerText1: headerText(for: .headerType1),
            headerText2: headerText(for: .headerType2),
            rows: rows.filter { $0.attributeText.attribute.isNutrient }
        )
    }
    
    var perContainer: Output.Serving.PerContainer? {
        guard let doubleText = doubleTextForAttribute(.servingsPerContainerAmount) else {
            return nil
        }
        let stringText = stringTextForAttribute(.servingsPerContainerName)
        
        return Output.Serving.PerContainer(
            amountText: doubleText,
            nameText: stringText
        )
    }
    
    var equivalentSize: Output.Serving.EquivalentSize? {
        guard let doubleText = doubleTextForAttribute(.servingEquivalentAmount) else {
            return nil
        }
        return Output.Serving.EquivalentSize(
            amountText: DoubleText(doubleText),
            unitText: unitTextForAttribute(.servingEquivalentUnit),
            unitNameText: stringTextForAttribute(.servingEquivalentUnitSize)
        )
    }
    
    var serving: Output.Serving? {
        let amountText = doubleTextForAttribute(.servingAmount)
        let unitText = unitTextForAttribute(.servingUnit)
        let unitNameText = stringTextForAttribute(.servingUnitSize)
        
        let allFieldsEmpty = amountText == nil && unitText == nil && unitNameText == nil && equivalentSize == nil && perContainer == nil
        
        if allFieldsEmpty {
            return nil
        } else {
            return Output.Serving(
                amountText: amountText,
                unitText: unitText,
                unitNameText: unitNameText,
                equivalentSize: equivalentSize,
                perContainer: perContainer
            )
        }
    }
    
    var classifierOutput: Output {
        Output(
            serving: serving,
            nutrients: nutrients
        )
    }
}

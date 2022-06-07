import Foundation
import TabularData

@testable import NutritionLabelClassifier

extension Output {
    init?(fromExpectedDataFrame dataFrame: DataFrame) {
        self.init(serving: Serving(fromExpectedDataFrame: dataFrame),
                  nutrients: Nutrients(fromExpectedDataFrame: dataFrame))
    }
}

extension DoubleText {
    init(fromExpectedDouble double: Double) {
        self.init(double: double, textId: defaultUUID, attributeTextId: defaultUUID)
    }
}

extension UnitText {
    init(fromExpectedUnit unit: NutritionUnit) {
        self.init(unit: unit, textId: defaultUUID, attributeTextId: defaultUUID)
    }
}

extension StringText {
    init(fromExpectedString string: String) {
        self.init(string: string, textId: defaultUUID, attributeTextId: defaultUUID)
    }
}

extension HeaderText {
    init(fromExpectedType type: HeaderType, serving: HeaderText.Serving?) {
        self.init(type: type, textId: defaultUUID, attributeTextId: defaultUUID, serving: serving)
    }
}

extension Output.Serving {
    init?(fromExpectedDataFrame dataFrame: DataFrame) {

        var amountText: DoubleText? = nil
        var unitText: UnitText? = nil
        var unitNameText: StringText? = nil
        
        var identifiableEquivalentAmount: DoubleText? = nil
        var identifiableEquivalentUnit: UnitText? = nil
        var identifiableEquivalentUnitSizeName: StringText? = nil
        var equivalentSize: EquivalentSize? = nil
        
        var identifiablePerContainerAmount: DoubleText? = nil
        var identifiablePerContainerName: StringText? = nil
//        var identifiablePerContainerName: Output.Serving.PerContainer.IdentifiableContainerName? = nil
        var perContainer: PerContainer? = nil
        
        for row in dataFrame.rows {
            guard let attributeName = row[.attributeString] as? String,
                  let attribute = Attribute(rawValue: attributeName),
                  attribute.isServingAttribute,
                  let double = row[.double] as? Double?,
                  let string = row[.string] as? String?
            else {
                continue
            }
            
            if attribute == .servingAmount, let double = double {
                amountText = DoubleText(fromExpectedDouble: double)
            }
            
            if attribute == .servingUnit, let string = string, let unit = NutritionUnit(string: string) {
                unitText = UnitText(fromExpectedUnit: unit)
            }

            if attribute == .servingUnitSize, let string = string {
                unitNameText = StringText(fromExpectedString: string)
            }
            
            //MARK: Equivalent Amount
            if attribute == .servingEquivalentAmount, let double = double {
                identifiableEquivalentAmount = DoubleText(fromExpectedDouble: double)
            }
            if attribute == .servingEquivalentUnit, let string = string, let unit = NutritionUnit(string: string) {
                identifiableEquivalentUnit = UnitText(fromExpectedUnit: unit)
            }
            if attribute == .servingEquivalentUnitSize, let string = string {
                identifiableEquivalentUnitSizeName = StringText(fromExpectedString: string)
            }
            
            //MARK: Per Container
            if attribute == .servingsPerContainerAmount, let double = double {
                identifiablePerContainerAmount = DoubleText(fromExpectedDouble: double)
            }
            if attribute == .servingsPerContainerName, let string = string {
                identifiablePerContainerName = StringText(fromExpectedString: string)
            }
        }
        
        if let amountText = identifiableEquivalentAmount,
            (identifiableEquivalentUnit != nil || identifiableEquivalentUnitSizeName != nil) {
            equivalentSize = EquivalentSize(
                amountText: amountText,
                unitText: identifiableEquivalentUnit,
                unitNameText: identifiableEquivalentUnitSizeName)
        }
        
        if let identifiablePerContainerAmount = identifiablePerContainerAmount {
            perContainer = PerContainer(
                amountText: identifiablePerContainerAmount,
                nameText: identifiablePerContainerName)
        }
        
        let allFieldsAreEmpty = amountText == nil && unitText == nil && unitNameText == nil && equivalentSize == nil && perContainer == nil
        if allFieldsAreEmpty {
            return nil
        }
        self.init(
            amountText: amountText,
            unitText: unitText,
            unitNameText: unitNameText,
            equivalentSize: equivalentSize,
            perContainer: perContainer
        )
    }
}

extension DataFrame {
    func rowForExpectedAttribute(_ attribute: Attribute) -> DataFrame.Rows.Element? {
        rows.first(where: {
            guard let attributeName = $0[.attributeString] as? String,
                  let attr = Attribute(rawValue: attributeName) else {
                return false
            }
            return attr == attribute
        })
    }
    
    func doubleForAttribute(_ attribute: Attribute) -> Double? {
        guard let row = rowForExpectedAttribute(attribute) else { return nil }
        return row[.double] as? Double
    }

    func stringForAttribute(_ attribute: Attribute) -> String? {
        guard let row = rowForExpectedAttribute(attribute) else { return nil }
        return row[.string] as? String
    }

    func unitForAttribute(_ attribute: Attribute) -> NutritionUnit? {
        guard let string = stringForAttribute(attribute) else { return nil }
        return NutritionUnit(string: string)
    }
    
    func headerTypeForAttribute(_ attribute: Attribute) -> HeaderType? {
//        guard let double = doubleForAttribute(attribute) else { return nil }
        guard let string = stringForAttribute(attribute) else { return nil}
        return HeaderType(rawValue: string)
    }
}
extension DataFrame {
    var headerServingEquivalentSize: HeaderText.Serving.EquivalentSize? {
        guard let amount = doubleForAttribute(.headerServingEquivalentAmount) else {
            return nil
        }
        let unit = unitForAttribute(.headerServingEquivalentUnit)
        let unitName = stringForAttribute(.headerServingEquivalentUnitSize)
        return HeaderText.Serving.EquivalentSize(amount: amount, unit: unit, unitName: unitName)
    }
    
    var headerServing: HeaderText.Serving? {
        let amount = doubleForAttribute(.headerServingAmount)
        let unit = unitForAttribute(.headerServingUnit)
        let unitName = stringForAttribute(.headerServingUnitSize)
        let equivalentSize = headerServingEquivalentSize
        
        guard amount != nil || equivalentSize != nil else {
            return nil
        }
        return HeaderText.Serving(
            amount: amount, unit: unit, unitName: unitName, equivalentSize: equivalentSize)
    }
}

extension Output.Nutrients {
    init(fromExpectedDataFrame dataFrame: DataFrame) {
        
        let headerText1: HeaderText?
        if let type = dataFrame.headerTypeForAttribute(.headerType1) {
            if type == .perServing {
                headerText1 = HeaderText(fromExpectedType: type, serving: dataFrame.headerServing)
            } else {
                headerText1 = HeaderText(fromExpectedType: type, serving: nil)
            }
        } else {
            headerText1 = nil
        }

        let headerText2: HeaderText?
        if let type = dataFrame.headerTypeForAttribute(.headerType2) {
            if type == .perServing {
                headerText2 = HeaderText(fromExpectedType: type, serving: dataFrame.headerServing)
            } else {
                headerText2 = HeaderText(fromExpectedType: type, serving: nil)
            }
        } else {
            headerText2 = nil
        }

        /// Rows
        var nutrientRows: [Row] = []
        for row in dataFrame.rows {
            guard let attributeName = row[.attributeString] as? String,
                  let attribute = Attribute(rawValue: attributeName),
                  let value1String = row[.value1String] as? String?,
                  let value2String = row[.value2String] as? String?
            else {
                continue
            }
            
            guard value1String != nil || value2String != nil else {
                continue
            }
            
            var valueText1: ValueText? = nil
            if let value1String = value1String {
                guard let value = Value(fromString: value1String) else {
                    print("Failed to convert value1String: \(value1String)")
                    continue
                }
                valueText1 = ValueText(value: value, textId: defaultUUID)
            }
            
            var valueText2: ValueText? = nil
            if let value2String = value2String {
                guard let value = Value(fromString: value2String) else {
                    print("Failed to convert value2String: \(value2String)")
                    continue
                }
                valueText2 = ValueText(value: value, textId: defaultUUID)
            }
            
            let nutrientRow = Row(
                attributeText: AttributeText(
                    attribute: attribute,
                    textId: defaultUUID
                ),
                valueText1: valueText1,
                valueText2: valueText2)
            
            nutrientRows.append(nutrientRow)
        }

        self.init(
            headerText1: headerText1,
            headerText2: headerText2,
            rows: nutrientRows
        )
    }
}

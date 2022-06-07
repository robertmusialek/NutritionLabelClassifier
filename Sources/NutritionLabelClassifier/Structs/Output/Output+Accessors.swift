import Foundation

public extension Output.Serving {
    var amount: Double? { amountText?.double }
    var unit: NutritionUnit? { unitText?.unit }
    var unitName: String? { unitNameText?.string }
    
    var amountId: UUID? { amountText?.textId }
    var unitId: UUID? { unitText?.textId }
    var unitNameId: UUID? { unitNameText?.textId }
}

public extension Output.Serving.EquivalentSize {
    var amount: Double { amountText.double }
    var unit: NutritionUnit? { unitText?.unit }
    var unitName: String? { unitNameText?.string }
    
    var amountId: UUID { amountText.textId }
    var unitId: UUID? { unitText?.textId }
    var unitNameId: UUID? { unitNameText?.textId }
}

public extension Output.Serving.PerContainer {
    var amount: Double { amountText.double }
    var name: String? { nameText?.string }
//    var containerName: ContainerName? { identifiableContainerName?.containerName }
    
    var amountId: UUID { amountText.textId }
    var nameId: UUID? { nameText?.textId }
//    var containerNameId: UUID? { identifiableContainerName?.id }
}

public extension Output.Nutrients {
    var header1Type: HeaderType? { headerText1?.type }
    var header2Type: HeaderType? { headerText2?.type }

    var header1Id: UUID? { headerText1?.textId }
    var header2Id: UUID? { headerText2?.textId }
}

public extension Output.Nutrients.Row {
    var attribute: Attribute { attributeText.attribute }
    var value1: Value? { valueText1?.value }
    var value2: Value? { valueText2?.value }
    
    var attributeId: UUID { attributeText.textId }
    var value1Id: UUID? { valueText1?.textId }
    var value2Id: UUID? { valueText2?.textId }
}

public extension Output {
    var headerServing: HeaderText.Serving? {
        servingHeaderText?.serving
    }
    
    var servingHeaderText: HeaderText? {
        if let type = nutrients.header1Type,
           type == .perServing {
            return nutrients.headerText1
        }
        if let type = nutrients.header2Type,
           type == .perServing {
            return nutrients.headerText2
        }
        return nil
    }
}

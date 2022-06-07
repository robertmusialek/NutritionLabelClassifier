import Foundation
import VisionSugar

let KcalsPerGramOfFat = 8.75428571
let KcalsPerGramOfCarb = 4.0
let KcalsPerGramOfProtein = 4.0
let KcalsPerKilojule = 4.184

extension EdgeCasesClassifier {
    
    func calculateMissingMacroOrEnergyInSingleColumnOfValues() {
        guard !observations.hasTwoColumnsOfValues else {
            return
        }
        
        calculateMissingEnergy()
        calculateMissingCarbs()
        calculateMissingFat()
        calculateMissingProtein()
    }
    
    func calculateMissingEnergy() {
        /// If we're missing `.energy` and have the other 3 macros, calculate it
        guard !observations.contains(attribute: .energy),
           let carbsValue = observations.value1(for: .carbohydrate),
           let fatValue = observations.value1(for: .fat),
           let proteinValue = observations.value1(for: .protein),
           carbsValue.unit == fatValue.unit, carbsValue.unit == proteinValue.unit
        else {
            return
        }
        
        let kcal = (carbsValue.amount * KcalsPerGramOfCarb) + (fatValue.amount * KcalsPerGramOfFat) + (proteinValue.amount * KcalsPerGramOfProtein)
        
        let uuid: UUID
        if let recognizedText = recognizedTexts.first(where: { $0.string == kcal.clean }) {
            uuid = recognizedText.id
        } else {
            uuid = defaultUUID
        }

        let attributeText = AttributeText(attribute: .energy, textId: uuid)
        let observation = Observation(
            attributeText: attributeText,
            valueText1: ValueText(value: Value(amount: kcal, unit: .kcal), textId: uuid),
            valueText2: nil, doubleText: nil, stringText: nil
        )
        observations.append(observation)
    }
    
    //TODO: Modularize these 3 functions as there's quite a bit of repeated code
    func calculateMissingCarbs() {
        /// If we're missing `.carbohydrate` and have `.protein`, `.fat` and `.energy`, calculate it
        guard !observations.contains(attribute: .carbohydrate),
           let energyValue = observations.value1(for: .energy),
           let fatValue = observations.value1(for: .fat),
           let proteinValue = observations.value1(for: .protein),
           fatValue.unit == proteinValue.unit
        else {
            return
        }
        
        let kcal: Double
        if energyValue.unit == .kj {
            kcal = energyValue.amount / KcalsPerKilojule
        } else {
            kcal = energyValue.amount
        }
        
        var amount = (kcal - (fatValue.amount * KcalsPerGramOfFat) - (proteinValue.amount * KcalsPerGramOfProtein)) / KcalsPerGramOfCarb
        amount = amount.rounded(toPlaces: 4)
        
        let uuid: UUID
        if let recognizedText = recognizedTexts.first(where: { $0.string == amount.clean }) {
            uuid = recognizedText.id
        } else {
            uuid = defaultUUID
        }

        let attributeText = AttributeText(attribute: .carbohydrate, textId: uuid)
        let observation = Observation(
            attributeText: attributeText,
            valueText1: ValueText(value: Value(amount: amount, unit: .g), textId: uuid),
            valueText2: nil, doubleText: nil, stringText: nil
        )
        observations.append(observation)
    }
    
    func calculateMissingFat() {
        /// If we're missing `.fat` and have `.protein`, `.carbohydrate` and `.energy`, calculate it
        guard !observations.contains(attribute: .fat),
           let energyValue = observations.value1(for: .energy),
           let proteinValue = observations.value1(for: .protein),
           let carbValue = observations.value1(for: .carbohydrate),
           proteinValue.unit == carbValue.unit
        else {
            return
        }
        
        let kcal: Double
        if energyValue.unit == .kj {
            kcal = energyValue.amount / KcalsPerKilojule
        } else {
            kcal = energyValue.amount
        }
        
        var amount = (kcal - (carbValue.amount * KcalsPerGramOfCarb) - (proteinValue.amount * KcalsPerGramOfProtein)) / KcalsPerGramOfFat
        amount = amount.rounded(toPlaces: 4)

        let uuid: UUID
        if let recognizedText = recognizedTexts.first(where: { $0.string == amount.clean }) {
            uuid = recognizedText.id
        } else {
            uuid = defaultUUID
        }

        let attributeText = AttributeText(attribute: .fat, textId: uuid)
        let observation = Observation(
            attributeText: attributeText,
            valueText1: ValueText(value: Value(amount: amount, unit: .g), textId: uuid),
            valueText2: nil, doubleText: nil, stringText: nil
        )
        observations.append(observation)
    }
    
    func calculateMissingProtein() {
        /// If we're missing `.protein` and have `.carbohydrate`, `.fat` and `.energy`, calculate it
        guard !observations.contains(attribute: .protein),
           let energyValue = observations.value1(for: .energy),
           let carbValue = observations.value1(for: .carbohydrate),
           let fatValue = observations.value1(for: .fat),
           carbValue.unit == fatValue.unit
        else {
            return
        }
        
        let kcal: Double
        if energyValue.unit == .kj {
            kcal = energyValue.amount / KcalsPerKilojule
        } else {
            kcal = energyValue.amount
        }
        
        var amount = (kcal - (carbValue.amount * KcalsPerGramOfCarb) - (fatValue.amount * KcalsPerGramOfFat)) / KcalsPerGramOfProtein
        amount = amount.rounded(toPlaces: 4)
        
        let uuid: UUID
        if let recognizedText = recognizedTexts.first(where: { $0.string == amount.clean }) {
            uuid = recognizedText.id
        } else {
            uuid = defaultUUID
        }

        let attributeText = AttributeText(attribute: .protein, textId: uuid)
        let observation = Observation(
            attributeText: attributeText,
            valueText1: ValueText(value: Value(amount: amount, unit: .g), textId: uuid),
            valueText2: nil, doubleText: nil, stringText: nil
        )
        observations.append(observation)
    }
}

import Foundation
import VisionSugar

extension EdgeCasesClassifier {
    
    func correctMacroOrEnergyUsingRatioInTwoColumn() {
        guard let ratio = ratioOfValues,
              let energyObservation = observations.forAttribute(.energy),
              let carbObservation = observations.forAttribute(.carbohydrate),
              let proteinObservation = observations.forAttribute(.protein),
              let fatObservation = observations.forAttribute(.fat),
              let energy1 = energyObservation.value1?.amount,
              let energy2 = energyObservation.value2?.amount,
              let energyUnit = energyObservation.value1?.unit,
              let carb1 = carbObservation.value1?.amount,
              let carb2 = carbObservation.value2?.amount,
              let protein1 = proteinObservation.value1?.amount,
              let protein2 = proteinObservation.value2?.amount,
              let fat1 = fatObservation.value1?.amount,
              let fat2 = fatObservation.value2?.amount
        else {
            return
        }
        
        if Int(energy1/energy2) != Int(ratio) {
            /// Find out why value is incorrect
            let calculatedEnergy1 = energy(c: carb1, f: fat1, p: protein1, u: energyUnit)
            let calculatedEnergy2 = energy(c: carb2, f: fat2, p: protein2, u: energyUnit)
            let delta1 = abs(energy1 - calculatedEnergy1)
            let delta2 = abs(energy2 - calculatedEnergy2)
            
            if delta1 < delta2 {
                let correctEnergy2 = energy1 / ratio
                observations.modifyObservation(energyObservation, withValue2Amount: correctEnergy2)
            } else {
                let correctEnergy1 = energy2 * ratio
                observations.modifyObservation(energyObservation, withValue1Amount: correctEnergy1)
            }
        }
        
        //TODO: Do the same this above for the macros to correct any incorrect macros as well
    }
}

func energy(c: Double, f: Double, p: Double, u: NutritionUnit) -> Double {
    let kcal = (c * KcalsPerGramOfCarb) + (f * KcalsPerGramOfFat) + (p * KcalsPerGramOfProtein)
    if u == .kj {
        return kcal * KcalsPerKilojule
    } else {
        return kcal
    }
}

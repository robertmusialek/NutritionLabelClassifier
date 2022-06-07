import Foundation
import VisionSugar

extension RecognizedText {

    //TODO: Remove
    var features: [Feature] {
        var features: [Feature] = []
        
//        // Set the currentAttribute we're grabbing as nil
//        var currentAttribute: Attribute? = nil
//        var currentValueWaitingForAttribute: Value? = nil
//        var shouldHoldNextValueForAttribute = false
//
//        // For each artefact
//        for artefact in nutrientArtefacts {
//            if let attribute = artefact.attribute {
//                /// if we're holding onto a value for the next attribute (due to the `includes` preposition), create the feature and reset the holding variable
//                if let value = currentValueWaitingForAttribute {
//                    features.append(Feature(attribute: attribute, value: value))
//                    currentValueWaitingForAttribute = nil
//                } else {
//                    currentAttribute = attribute
//                }
//            } else if let value = artefact.value {
//                /// If we encounter this value after an `includes` preposition, hold onto it, and reset the flag that was used to indicate this
//                guard !shouldHoldNextValueForAttribute else {
//                    currentValueWaitingForAttribute = value
//                    shouldHoldNextValueForAttribute = false
//                    continue
//                }
//
//                guard let attribute = currentAttribute else {
//                    continue
//                }
//                if let unit = value.unit {
//                    guard attribute.supportsUnit(unit) else {
//                        continue
//                    }
//                }
//
//                features.append(Feature(attribute: attribute, value: value))
//
//                /// Reset `currentAttribute` if it doesn't support multiple columns (currently only energy supports this)
//                if !attribute.supportsMultipleColumns {
//                    currentAttribute = nil
//                }
//            } else if let preposition = artefact.preposition {
//                if preposition == .includes {
//                    /// set a flag for the next `Value` to be held onto so that we expect the `Attribute` to come afterwards
//                    shouldHoldNextValueForAttribute = true
//                }
//            }
//        }
        
        return features
    }
}


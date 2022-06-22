import VisionSugar

extension TableClassifier {
    
//    func groupsOfColumns(from columnsOfTexts: [[RecognizedText]]) -> [[[ValueText?]]] {
//
//        var columns = columnsOfTexts
//
//        /// Process columns
//        removeTextsAboveEnergy(&columns)
//        removeDuplicates(&columns)
//        pickTopColumns(&columns)
//        sort(&columns)
//        let groupedColumnsOfTexts = group(columns)
//        let groupedColumnsOfDetectedValueTexts = groupedColumnsOfDetectedValueTexts(from: groupedColumnsOfTexts)
//
//        var groupedColumnsOfValueTexts = pickValueTexts(from: groupedColumnsOfDetectedValueTexts)
//        insertNilForMissedValues(&groupedColumnsOfValueTexts)
//
//        return groupedColumnsOfValueTexts
//    }
//
//    func getColumnOfValueRecognizedTexts(startingFrom startingText: RecognizedText) -> [RecognizedText] {
//
//        let BoundingBoxMaxXDeltaThreshold = 0.05
//
//        var array: [RecognizedText] = [startingText]
//
//        print("🔢Getting column starting from: \(startingText.string)")
//
//        /// Now go upwards to get nutrient-attribute texts in same column as it
//        let textsAbove: [RecognizedText] = []
////        let textsAbove = visionResult.arrayOfTexts.extractValuesInSameColumn(as: startingText, preceding: true).filter { !$0.string.isEmpty }
////
//        print("🔢  ⬆️ textsAbove: \(textsAbove.map { $0.string } )")
//
//        for text in textsAbove {
//            print("🔢    Checking: \(text.string)")
//            let boundingBoxMaxXDelta = abs(text.boundingBox.maxX - startingText.boundingBox.maxX)
//
//            guard boundingBoxMaxXDelta < BoundingBoxMaxXDeltaThreshold else {
//                print("🔢    ignoring because boundingBoxMaxXDelta = \(boundingBoxMaxXDelta)")
//                continue
//            }
//
//            /// Until we reach a non-value-attribute text
//            guard text.string.containsNutrientAttributes else {
//                print("🔢    ✋🏽 ending search because a string wihtout any values was encountered")
//                break
//            }
//
//            /// Insert these into the start of our column of labels as we read them in
//            array.insert(text, at: 0)
//        }
//
//        /// Now do the same thing downwards
////        let textsBelow = visionResult.arrayOfTexts.extractValuesInSameColumn(as: startingText, preceding: false).filter { !$0.string.isEmpty }
//        let textsBelow: [RecognizedText] = []
//        let valueTextsBelow = visionResult.arrayOfTexts.extractValueTextsInSameColumn(as: startingText, preceding: false)
//
//        print("🔢  ⬇️ textsBelow: \(textsBelow.map { $0.string } )")
//
//        for text in textsBelow {
//            print("🔢    Checking: \(text.string)")
//            let boundingBoxMaxXDelta = abs(text.boundingBox.maxX - startingText.boundingBox.maxX)
//
//            guard boundingBoxMaxXDelta < BoundingBoxMaxXDeltaThreshold else {
//                print("🔢    ignoring because boundingBoxMaxXDelta = \(boundingBoxMaxXDelta)")
//                continue
//            }
//
//            guard text.string.containsValues else {
//                print("🔢    ✋🏽 ending search because a string without any values was encountered")
//                break
//            }
//
//            array.append(text)
//        }
//
//        return array
//    }
//
//    func removeDuplicates(_ columnsOfTexts: inout [[RecognizedText]]) {
//        columnsOfTexts = columnsOfTexts.uniqued()
//    }
//
//    /// - Remove anything values above energy for each column
//    func removeTextsAboveEnergy(_ columnsOfTexts: inout [[RecognizedText]]) {
//        for i in columnsOfTexts.indices {
//            var column = columnsOfTexts[i]
//            guard column.hasTextsAboveEnergyValue else { continue }
//            column.removeTextsAboveEnergyValue()
//            columnsOfTexts[i] = column
//        }
//    }
//
//    /// - Order columns
//    ///     Compare `midX`'s of shortest text from each column
//    func sort(_ columnsOfTexts: inout [[RecognizedText]]) {
//        columnsOfTexts.sort(by: {
//            guard let midX0 = $0.midXOfShortestText, let midX1 = $1.midXOfShortestText else {
//                return false
//            }
//            return midX0 < midX1
//        })
//    }
//
//    /// - Group columns if `attributeTextColumns.count > 1`
//    func group(_ initialColumnsOfTexts: [[RecognizedText]]) -> [[[RecognizedText]]] {
//        guard let attributeTextColumns = attributeTextColumns else { return [] }
//
//        var columnsOfTexts = initialColumnsOfTexts
//        var groups: [[[RecognizedText]]] = []
//
//        /// For each Attribute Column
//        for i in attributeTextColumns.indices {
//            let attributeTextColumn = attributeTextColumns[i]
//
//            /// Get the minX of the shortest attribute
//            guard let attributeColumnMinX = attributeTextColumn.shortestText?.rect.minX else { continue }
//
//            var group: [[RecognizedText]] = []
//            while group.count < 2 && !columnsOfTexts.isEmpty {
//                let column = columnsOfTexts.removeFirst()
//
//                /// Skip columns that are clearly to the left of this `attributeTextColumn`
//                guard let columnMaxX = column.shortestText?.rect.maxX,
//                      columnMaxX > attributeColumnMinX else {
//                    continue
//                }
//
//                /// If we have another attribute column
//                if i < attributeTextColumns.count - 1 {
//                    /// If we have reached columns that is to the right of it
//                    guard let nextAttributeColumnMinX = attributeTextColumns[i+1].shortestText?.rect.minX,
//                          columnMaxX < nextAttributeColumnMinX else
//                    {
//                        /// Make sure we re-insert the column so that it's extracted by that column
//                        columnsOfTexts.insert(column, at: 0)
//
//                        /// Stop the loop so that the next attribute column is focused on
//                        break
//                    }
//                }
//
//                /// Skip columns that contain all nutrient attributes
//                guard !column.allElementsContainNutrientAttributes else {
//                    continue
//                }
//
//                /// Skip columns that contain all percentage values
//                guard !column.allElementsArePercentageValues else {
//                    continue
//                }
//
//                /// If this column has more elements than the existing (first) column and contains any texts belonging to it, replace it
//                if let existing = group.first,
//                    column.count > existing.count,
//                    column.containsTextsFrom(existing)
//                {
//                    group[0] = column
//                } else {
//                    group.append(column)
//                }
//            }
//
//            groups.append(group)
//        }
//
//        return groups
//    }
//
//    func groupedColumnsOfDetectedValueTexts(from groupedColumnsOfTexts: [[[RecognizedText]]]) -> [[[[ValueText]]]] {
//        groupedColumnsOfTexts.map { group in
//            group.map { column in
//                column.map { text in
//                    Value.detect(in: text.string)
//                        .map { value in
//                            ValueText(value: value, text: text)
//                        }
//                }
//            }
//        }
//    }
//
//    func pickValueTexts(from groupedColumnsOfDetectedValueTexts: [[[[ValueText]]]]) -> [[[ValueText?]]] {
//        for group in groupedColumnsOfDetectedValueTexts {
//            for column in group {
//                for valueTexts in column {
//                    if valueTexts.count > 1 {
//                        print("🔥 \(valueTexts)")
//                    }
//                    for valueText in valueTexts {
//
//                    }
//                }
//            }
//        }
//        return []
//    }
//
//    /// - Insert `nil`s wherever values failed to be recognized
//    ///     Do this if we have a mismatch of element counts between columns
//    func insertNilForMissedValues(_ groupedColumnsOfValueTexts: inout [[[ValueText?]]]) {
//
//    }
//
//    func pickTopColumns(_ columnsOfTexts: inout [[RecognizedText]]) {
//        let groupedColumnsOfTexts = groupedColumnsOfTexts(from: columnsOfTexts)
//        columnsOfTexts = pickTopColumns(from: groupedColumnsOfTexts)
//    }
//
//    /// - Pick the column with the most elements in each group
//    func pickTopColumns(from groupedColumnsOfTexts: [[[RecognizedText]]]) -> [[RecognizedText]] {
//        var topColumns: [[RecognizedText]] = []
//        for group in groupedColumnsOfTexts {
//            guard let top = group.sorted(by: { $0.count > $1.count }).first else { continue }
//            topColumns.append(top)
//        }
//        return topColumns
//    }
//
//    /// - Group columns based on their positions
//    func groupedColumnsOfTexts(from columnsOfTexts: [[RecognizedText]]) -> [[[RecognizedText]]] {
//        var groups: [[[RecognizedText]]] = []
//        for column in columnsOfTexts {
//
//            var didAdd = false
//            for i in groups.indices {
//                if column.belongsTo(groups[i]) {
//                    groups[i].append(column)
//                    didAdd = true
//                    break
//                }
//            }
//
//            if !didAdd {
//                groups.append([column])
//            }
//        }
//        return groups
//    }
    
    //TODO-NEXT: Remove if not needed
    func chooseEnergyValues(_ columns: inout [[ValueText]]) {
        for i in columns.indices {
            var column = columns[i]
            if column.containsTwoEnergyValues {
                chooseEnergyValues(&column)
                columns[i] = column
            }
        }
    }
    
    //TODO-NEXT: Remove if not needed
    func chooseEnergyValues(_ column: inout [ValueText]) {
        /// Make sure the column contains two energy values
        guard column.containsTwoEnergyValues else {
            return
        }
        
        /// Grab the index of the kJ `ValueText`
        guard let index = column.firstIndex(where: { $0.value.unit == .kj }) else {
            return
        }
        
        /// Remove it
        let _ = column.remove(at: index)
    }
}

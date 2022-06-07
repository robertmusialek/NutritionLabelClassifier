import SwiftUI
import VisionSugar

extension Array where Element == RecognizedText {

    var description: String {
        map { $0.string }.joined(separator: ", ")
    }

    func inlineTextRows(as recognizedText: RecognizedText, preceding: Bool = false, ignoring textsToIgnore: [RecognizedText] = []) -> [[RecognizedText]] {
        
        var column: [[RecognizedText]] = []
        var discarded: [RecognizedText] = []
        let candidates = filter {
            $0.isInSameColumnAs(recognizedText)
            && !textsToIgnore.contains($0)
            && (preceding ? $0.rect.maxY < recognizedText.rect.maxY : $0.rect.minY > recognizedText.rect.minY)
            
            /// Filter out empty `recognizedText`s
            && $0.candidates.filter { !$0.isEmpty }.count > 0
        }.sorted {
            preceding ?
                $0.rect.minY > $1.rect.minY
                : $0.rect.minY < $1.rect.minY
        }

        /// Deal with multiple recognizedTexts we may have grabbed from the same row due to them both overlapping with `recognizedText` by choosing the one that intersects with it the most
        for candidate in candidates {

            guard !discarded.contains(candidate) else {
                continue
            }
            let row = candidates.filter {
                $0.isInSameRowAs(candidate)
            }
            guard row.count > 1 else {
                column.append([candidate])
                continue
            }
            
            var rowElementsAndIntersections: [(recognizedText: RecognizedText,
                                               intersection: CGRect)] = []
            for rowElement in row {
                /// first normalize the y values of both rects, `rowElement`, `closest` to `recognizedText` in new temporary variables, by assigning both the same y values (`origin.y` and `size.height`)
                let yNormalizedRect = rowElement.rect.rectWithYValues(of: recognizedText.rect)
//                let closestYNormalizedRect = closest.rect.rectWithYValues(of: recognizedText.rect)
                let intersection = yNormalizedRect.intersection(recognizedText.rect)
                rowElementsAndIntersections.append(
                    (rowElement, intersection)
                )
                
//                let closestIntersection = closestYNormalizedRect.intersection(recognizedText.rect)
//
//                let intersectionRatio = intersection.width / rowElement.rect.width
//                let closestIntersectionRatio = closestIntersection.width / closest.rect.width
//
//                if intersectionRatio > closestIntersectionRatio {
//                    closest = rowElement
//                }
                
                discarded.append(rowElement)
            }
            
            /// Now order the `rowElementsAndIntersections` in decreasing order of `intersection.width` — which indicates how far away from the source `recognizedText` they are
            rowElementsAndIntersections.sort { $0.intersection.width > $1.intersection.width }
            
            /// Now that its sorted, map the recognized texts into an array and provide that in the result array
            column.append(rowElementsAndIntersections.map { $0.recognizedText })
        }
        
        return column
    }
    
    /** Returns an array of the inline `recognizedText`s to the one we specify, in the direction indicating by `preceding`—whilst ignoring those provided.
     
        The return array is 2-dimensional, where each element is another array of elements that appear in the same column as one another, in order of how much they intersect with the source `recognizedText`. These arrays are in the order of the how far away from the `recognizedText` they are.
     */
    func inlineTextColumns(as recognizedText: RecognizedText, preceding: Bool = false, ignoring textsToIgnore: [RecognizedText] = []) -> [[RecognizedText]] {
        
        let mininumHeightOverlapThreshold = 0.08
        
        var row: [[RecognizedText]] = []
        var discarded: [RecognizedText] = []
        let candidates = filter {
            $0.isInSameRowAs(recognizedText)
            && !textsToIgnore.contains($0)
            && (preceding ? $0.rect.maxX < recognizedText.rect.minX : $0.rect.minX > recognizedText.rect.maxX)
            
            /// Filter out texts that overlap the recognized text by at least the minimum threshold
            && $0.rect.rectWithXValues(of: recognizedText.rect).intersection(recognizedText.rect).height/recognizedText.rect.height >= mininumHeightOverlapThreshold
            
            /// Filter out empty `recognizedText`s
            && $0.candidates.filter { !$0.isEmpty }.count > 0
        }.sorted {
            $0.rect.minX < $1.rect.minX
        }
        

        /// Deal with multiple recognizedText we may have grabbed from the same column due to them both overlapping with `recognizedText` by choosing the one that intersects with it the most
        for candidate in candidates {

            guard !discarded.contains(candidate) else {
                continue
            }
            let column = candidates.filter {
                $0.isInSameColumnAs(candidate)
            }
            guard column.count > 1 else {
                row.append([candidate])
                continue
            }
            
            var columnElementsAndIntersections: [(recognizedText: RecognizedText,
                                                  intersection: CGRect)] = []
            for columnElement in column {
                /// first normalize the x values of both rects, `columnElement`, `closest` to `recognizedText` in new temporary variables, by assigning both the same x values (`origin.x` and `size.width`)
                let xNormalizedRect = columnElement.rect.rectWithXValues(of: recognizedText.rect)
                let intersection = xNormalizedRect.intersection(recognizedText.rect)
                columnElementsAndIntersections.append(
                    (columnElement, intersection)
                )
                discarded.append(columnElement)
            }
            
            /// Now order the `columnElementsAndIntersections` in decreasing order of `intersection.height` — which indicates how far away from the source `recognizedText` they are
            columnElementsAndIntersections.sort { $0.intersection.height > $1.intersection.height }
            
            /// Now that its sorted, map the recognized texts into an array and provide that in the result array
            row.append(columnElementsAndIntersections.map { $0.recognizedText })
        }
        
        return row
    }
    
    //MARK: - Legacy

    func filterSameColumn(as recognizedText: RecognizedText, preceding: Bool = false, removingOverlappingTexts: Bool = true) -> [RecognizedText] {
        var column: [RecognizedText] = []
        var discarded: [RecognizedText] = []
        let candidates = filter {
            $0.isInSameColumnAs(recognizedText)
            && (preceding ? $0.rect.maxY < recognizedText.rect.maxY : $0.rect.minY > recognizedText.rect.minY)
        }.sorted {
            $0.rect.minY < $1.rect.minY
        }

        for candidate in candidates {

            guard !discarded.contains(candidate) else {
                continue
            }
            let row = candidates.filter {
                $0.isInSameRowAs(candidate)
            }
            guard row.count > 1, let first = row.first else {
                column.append(candidate)
                continue
            }
            
            /// Deal with multiple recognizedTexts we may have grabbed from the same row due to them both overlapping with `recognizedText` by choosing the one that intersects with it the most
            if removingOverlappingTexts {
                var closest = first
                for rowElement in row {
                    /// first normalize the y values of both rects, `rowElement`, `closest` to `recognizedText` in new temporary variables, by assigning both the same y values (`origin.y` and `size.height`)
                    let yNormalizedRect = rowElement.rect.rectWithYValues(of: recognizedText.rect)
                    let closestYNormalizedRect = closest.rect.rectWithYValues(of: recognizedText.rect)

                    let intersection = yNormalizedRect.intersection(recognizedText.rect)
                    let closestIntersection = closestYNormalizedRect.intersection(recognizedText.rect)

                    let intersectionRatio = intersection.width / rowElement.rect.width
                    let closestIntersectionRatio = closestIntersection.width / closest.rect.width

                    if intersectionRatio > closestIntersectionRatio {
                        closest = rowElement
                    }
                    
                    discarded.append(rowElement)
                }
                column.append(closest)
            } else {
                column = candidates
            }
        }
        
        return column
    }

    /// Same as `inlineTextColumns(as:preceding:ignoring)`, but with commented out code included
    func inlineTextColumns_legacy(as recognizedText: RecognizedText, preceding: Bool = false, ignoring textsToIgnore: [RecognizedText] = []) -> [[RecognizedText]] {
//        log.verbose(" ")
//        log.verbose("******")
//        log.verbose("Finding recognizedTextsOnSameLine as: \(recognizedText.string)")
        
        let mininumHeightOverlapThreshold = 0.08
//        let mininumHeightOverlapThreshold = 0.0

        var row: [[RecognizedText]] = []
        var discarded: [RecognizedText] = []
        let candidates = filter {
            $0.isInSameRowAs(recognizedText)
            && !textsToIgnore.contains($0)
            && (preceding ? $0.rect.maxX < recognizedText.rect.minX : $0.rect.minX > recognizedText.rect.maxX)
            
            /// Filter out texts that overlap the recognized text by at least the minimum threshold
            && $0.rect.rectWithXValues(of: recognizedText.rect).intersection(recognizedText.rect).height/recognizedText.rect.height >= mininumHeightOverlapThreshold
            
            /// Filter out empty `recognizedText`s
            && $0.candidates.filter { !$0.isEmpty }.count > 0
        }.sorted {
            $0.rect.minX < $1.rect.minX
//            && $0.rect.minY < $1.rect.minY
        }
        

//        log.verbose("candidates are:")
//        log.verbose("\(candidates.map { $0.string })")

        /// Deal with multiple recognizedText we may have grabbed from the same column due to them both overlapping with `recognizedText` by choosing the one that intersects with it the most
        for candidate in candidates {

//            log.verbose("  finding recognizedTexts in same column as: \(candidate.string)")

            guard !discarded.contains(candidate) else {
//                log.verbose("  this recognizedText has been discarded, so ignoring it")
                continue
            }
            let column = candidates.filter {
                $0.isInSameColumnAs(candidate)
            }
            guard column.count > 1, let _ = column.first else {
//            guard column.count > 1, let first = column.first else {
//                log.verbose("  no recognizedTexts in same column, so adding this to the final array and continuing")
                row.append([candidate])
                continue
            }
            
//            log.verbose("  found these recognizedTexts in the same column:")
//            log.verbose("  \(column.map { $0.string })")

//            log.verbose("  setting closest as \(first.string)")
//            var closest = first
            
            var columnElementsAndIntersections: [(recognizedText: RecognizedText, intersection: CGRect)] = []
            for columnElement in column {
//                log.verbose("    checking if \(columnElement.string) is a closer candidate")
                /// first normalize the x values of both rects, `columnElement`, `closest` to `recognizedText` in new temporary variables, by assigning both the same x values (`origin.x` and `size.width`)
                let xNormalizedRect = columnElement.rect.rectWithXValues(of: recognizedText.rect)
//                let closestXNormalizedRect = closest.rect.rectWithXValues(of: recognizedText.rect)

//                log.verbose("    xNormalizedRect is: \(xNormalizedRect)")
//                log.verbose("    closestXNormalizedRect is: \(closestXNormalizedRect)")

                let intersection = xNormalizedRect.intersection(recognizedText.rect)
//                let closestIntersection = closestXNormalizedRect.intersection(recognizedText.rect)
//                log.verbose("    intersection is: \(intersection)")
//                log.verbose("    closestIntersection is: \(closestIntersection)")

//                log.verbose("    Checking if intersection.height(\(intersection.height)) > closestIntersection.height(\(closestIntersection.height))")
                /// now compare these intersection of both the x-normalized rects with `recognizedText` itself, and return whichever intersection rect has a larger height (indicating which one is more 'in line' with `recognizedText`)
//                if intersection.height > closestIntersection.height {
//                    log.verbose("    It is greater, so setting closest as: \(sameColumnElement.string)")
//                    closest = columnElement
//                } else {
//                    log.verbose("    It isn't greater, so leaving closest as it was")
//                }
                
//                log.verbose("    Adding \(columnElement.string) to the discarded pile")
                columnElementsAndIntersections.append(
                    (columnElement, intersection)
                )
                discarded.append(columnElement)
            }
            
            
//            log.verbose("  Now that we've gone through all the \(column.count) columnElements, we're appending the final closest: \(closest.string) to row")
            
            
            /// Now order the `columnElementsAndIntersections` in decreasing order of `intersection.height` — which indicates how far away from the source `recognizedText` they are
            columnElementsAndIntersections.sort { $0.intersection.height > $1.intersection.height }
            
            /// Now that its sorted, map the recognized texts into an array and provide that in the result array
            row.append(columnElementsAndIntersections.map { $0.recognizedText })
        }
        
//        log.verbose("Finally, we have row as:")
//        log.verbose("\(row.map { $0.string })")
        
        return row
    }
}


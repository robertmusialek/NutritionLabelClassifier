import SwiftUI

//TODO: Move this to SwiftSugar
extension CGRect {
    func rectWithXValues(of rect: CGRect) -> CGRect {
        CGRect(x: rect.origin.x, y: origin.y,
               width: rect.size.width, height: size.height)
    }
    
    func rectWithYValues(of rect: CGRect) -> CGRect {
        CGRect(x: origin.x, y: rect.origin.y,
               width: size.width, height: rect.size.height)
    }
}

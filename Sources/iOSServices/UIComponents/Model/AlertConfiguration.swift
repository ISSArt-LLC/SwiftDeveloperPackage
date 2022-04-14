import Foundation
import SwiftUI

public struct AlertConfiguration {
    public var title: String
    public var message: String
    public var placeholder: String = emptyString
    public var accept: String = okLabel
    public var cancel: String? = cancelLabel
    public var secondaryActionTitle: String? = nil
    public var keyboardType: UIKeyboardType = .default
    public var action: (String?) -> Void
    public var secondaryAction: VoidCallback? = nil
    
    public init() {}
}


import Foundation
import SwiftUI

public struct AlertConfiguration {
    public var title: String
    public var message: String
    public var placeholder: String
    public var accept: String
    public var cancel: String?
    public var secondaryActionTitle: String?
    public var keyboardType: UIKeyboardType
    public var action: NullableStringCallback
    public var secondaryAction: VoidCallback?
    
    public init(
        alertTitle: String,
        alertMessage: String,
        mainAction: @escaping NullableStringCallback,
        alertPlaceholder: String = emptyString,
        acceptText: String = okLabel,
        cancelText: String? = cancelLabel,
        alterActionTitle: String? = nil,
        alertKeyboardType: UIKeyboardType = .default,
        alterAction: VoidCallback? = nil
    ) {
        title = alertTitle
        message = alertMessage
        placeholder = alertPlaceholder
        accept = acceptText
        cancel = cancelText
        secondaryActionTitle = alterActionTitle
        keyboardType = alertKeyboardType
        action = mainAction
        secondaryAction = alterAction
    }
}


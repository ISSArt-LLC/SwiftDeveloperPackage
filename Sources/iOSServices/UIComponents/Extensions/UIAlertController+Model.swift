import Foundation
import UIKit

extension UIAlertController {
    convenience init(model: AlertConfiguration) {
        self.init(title: model.title, message: model.message, preferredStyle: .alert)
        addTextField {
            $0.placeholder = model.placeholder
            $0.keyboardType = model.keyboardType
        }
        if let cancel = model.cancel {
            addAction(UIAlertAction(title: cancel, style: .cancel) { _ in
                model.action(nil)
            })
        }
            
        if let secondaryActionTitle = model.secondaryActionTitle {
            addAction(UIAlertAction(title: secondaryActionTitle, style: .default, handler: { _ in
                model.secondaryAction?()
            }))
        }
        
        let textField = self.textFields?.first
        addAction(UIAlertAction(title: model.accept, style: .default) { _ in
            model.action(textField?.text)
        })
    }
}

import Foundation
import SwiftUI

public struct TextFieldAlert<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let model: AlertConfiguration
    let content: Content
    
    public func makeUIViewController(context: UIViewControllerRepresentableContext<TextFieldAlert>) -> UIHostingController<Content> {
        UIHostingController(rootView: content)
    }
    
    public final class Coordinator {
        var alertController: UIAlertController?
        init(_ controller: UIAlertController? = nil) {
            self.alertController = controller
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    public func updateUIViewController(
        _ uiViewController: UIHostingController<Content>,
        context: UIViewControllerRepresentableContext<TextFieldAlert>
    ) {
        uiViewController.rootView = content
        if isPresented && uiViewController.presentedViewController == nil {
            var alert = self.model
            alert.action = {
                self.isPresented = false
                self.model.action($0)
            }
            context.coordinator.alertController = UIAlertController(model: alert)
            uiViewController.present(context.coordinator.alertController!, animated: true)
        }
        if !isPresented && uiViewController.presentedViewController == context.coordinator.alertController {
            uiViewController.dismiss(animated: true)
        }
    }
}

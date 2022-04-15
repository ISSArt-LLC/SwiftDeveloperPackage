import SwiftUI

public extension View {
    func textAlert(isPresented: Binding<Bool>, _ model: AlertConfiguration) -> some View {
    return TextFieldAlert(isPresented: isPresented, model: model, content: self)
  }
}

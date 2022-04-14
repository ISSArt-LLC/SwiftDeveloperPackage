import SwiftUI

extension View {
  public func alert(isPresented: Binding<Bool>, _ model: AlertConfiguration) -> some View {
    return TextFieldAlert(isPresented: isPresented, model: model, content: self)
  }
}

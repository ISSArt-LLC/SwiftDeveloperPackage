import SwiftUI

@available(iOS 13.0, macOS 10.15, *)
public enum NavigationTransition {
    case none
    case custom(_ pushTransition: AnyTransition, _ popTransition: AnyTransition)
}

public enum NavigationType {
    case push
    case pop
}

public enum PopDestination {
    case previous
    case root
}

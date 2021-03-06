import SwiftUI


@available(iOS 13.0, macOS 10.15, *)
fileprivate struct Screen: Identifiable, Equatable {

    let id: String
    let nextScreen: AnyView
    
    static func == (lhs: Screen, rhs: Screen) -> Bool {
        lhs.id == rhs.id
    }
    
}

@available(iOS 13.0, macOS 10.15, *)
fileprivate struct ScreenStack {
    
    private var screens = [Screen]()
    
    func top() -> Screen? {
        screens.last
    }
    
    mutating func push(_ s: Screen) {
        screens.append(s)
    }
    
    mutating func popToPrevious() {
        _ = screens.popLast()
    }
    
    mutating func popToRoot() {
        screens.removeAll()
    }
}

@available(iOS 13.0, macOS 10.15, *)
public final class NavigationControllerViewModel: ObservableObject {
    
    private let easing: Animation
    
    var navigationType = NavigationType.push
    
    @Published fileprivate var currentScreen: Screen?
    
    private var screenStack = ScreenStack() {
        didSet {
            currentScreen = screenStack.top()
        }
    }
    
    public init(easing: Animation) {
        self.easing = easing
    }
    
    public func push<S: View>(_ screenView: S) {
        withAnimation(easing) {
            navigationType = .push
            let screen = Screen(id: UUID().uuidString, nextScreen: AnyView(screenView))
            screenStack.push(screen)
        }
    }
    
    public func pop(to: PopDestination = .previous) {
        withAnimation(easing) {
            navigationType = .pop
            switch to {
            case .root:
                screenStack.popToRoot()
            case .previous:
                screenStack.popToPrevious()
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, *)
public struct NavigationControllerView<Content>: View where Content: View {
    
    @ObservedObject private var viewModel: NavigationControllerViewModel
    
    private let content: Content
    private let transition: (push: AnyTransition, pop: AnyTransition)
    
    public init(
        transition: NavigationTransition,
        viewModel: NavigationControllerViewModel = NavigationControllerViewModel(
            easing: .easeOut(duration: 0.33)
        ),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.viewModel = viewModel
        self.content = content()
        switch transition {
        case .custom(let pushTransition, let popTransition):
            self.transition = (pushTransition, popTransition)
        case .none:
            self.transition = (.identity, .identity)
        }
    }
    
    public var body: some View {
        let isRoot = viewModel.currentScreen == nil
        return ZStack {
            if isRoot {
                content
                    .environmentObject(viewModel)
                    .transition(viewModel.navigationType == .push ? transition.push : transition.pop)
            } else {
                viewModel.currentScreen!.nextScreen
                    .environmentObject(viewModel)
                    .transition(viewModel.navigationType == .push ? transition.push : transition.pop)
            }
        }
    }
    
}

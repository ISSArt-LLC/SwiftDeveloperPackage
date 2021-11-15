public protocol BasicServiceLocator {
    func getDependency<T>(_ type: T.Type) -> T?
}

import Foundation

public final class LazyServiceLocator: BasicServiceLocator {
    fileprivate var services: [String : () -> Any] = [:]
    
    public static let shared = LazyServiceLocator()
            
    fileprivate init() {}
    
    public func getDependency<T>(_ type: T.Type) -> T? {
        guard let initializer = services[String(describing: T.self)] else { return nil }
        return initializer() as? T
    }
    
    public func addDependency<T>(initializer: @escaping () -> T) {
        let typeName = String(describing: T.self)
        if services[typeName] == nil {
            services[typeName] = initializer
        }
    }
}

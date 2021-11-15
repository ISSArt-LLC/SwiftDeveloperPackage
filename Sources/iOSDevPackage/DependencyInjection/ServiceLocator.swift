import Foundation

public final class ServiceLocator: BasicServiceLocator {
    fileprivate var services: [String : Any] = [:]
    
    public static let shared = ServiceLocator()
            
    fileprivate init() {}
    
    public func getDependency<T>(_ type: T.Type) -> T? {
        return services[String(describing: T.self)] as? T
    }
    
    public func addDependency<T>(_ dependency: T) {
        let typeName = String(describing: T.self)
        if services[typeName] == nil {
            services[typeName] = dependency
        }
    }
}

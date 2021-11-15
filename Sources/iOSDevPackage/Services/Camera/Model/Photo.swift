import UIKit

@available(iOS 13.0, *)
public struct Photo: Identifiable, Equatable {
    public var id: String
    public var originalData: Data
    public var uniformTypeIdentifier: String?
    
    public init(id: String = UUID().uuidString, originalData: Data, uniformTypeIdentifier: String?) {
        self.id = id
        self.originalData = originalData
        self.uniformTypeIdentifier = uniformTypeIdentifier
    }
    
    public var compressedData: Data? {
        UIImage(data: originalData)?.resize(targetWidth: 800).jpegData(compressionQuality: 0.5)
    }
    
    public var thumbnailData: Data? {
        UIImage(data: originalData)?.resize(targetWidth: 100).jpegData(compressionQuality: 0.5)
    }
    
    public var thumbnailImage: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }
    
    public var image: UIImage? {
        guard let data = compressedData else { return nil }
        return UIImage(data: data)
    }
}

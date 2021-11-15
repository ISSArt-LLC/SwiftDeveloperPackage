import Foundation
import AVFoundation

@available(iOS 13.0, *)
public protocol BasicPhotoStorage {
    func savePhoto(photo: Photo)
}

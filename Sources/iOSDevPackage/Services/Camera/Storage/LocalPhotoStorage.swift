import Foundation
import Photos
import AVFoundation

@available(iOS 13.0, *)
public class LocalPhotoStorage: BasicPhotoStorage {
    
    public func savePhoto(photo: Photo) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    options.uniformTypeIdentifier = photo.uniformTypeIdentifier
                    creationRequest.addResource(with: .photo, data: photo.originalData, options: options)
                }, completionHandler: { _, error in
                    if let error = error {
                        print("Error occurred while saving photo to photo library: \(error)")
                    }
                }
                )
            } 
        }
    }
}

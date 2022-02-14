import Combine
import AVFoundation
import DependencyInjection

@available(iOS 13.0, *)
public class CameraViewModel: ObservableObject {
    
    private let service = CameraService()
    
    private let photoStorage: BasicPhotoStorage = ServiceLocator.shared.getDependency(BasicPhotoStorage.self) ?? LocalPhotoStorage()
    private var subscriptions = Set<AnyCancellable>()
    
    @Published public var photo: Photo!
    @Published public var showAlertError = false
    @Published public var isFlashOn = false
    
    public var alertError: AlertError!
    public var session: AVCaptureSession
    
    public var showProcessing = true
    
    public init() {
        self.session = service.session
        
        service.$photo.sink { [weak self] photo in
            guard let pic = photo else { return }
            self?.photo = pic
            self?.showProcessing = false
        }
        .store(in: &self.subscriptions)
        
        service.$shouldShowAlertView.sink { [weak self] val in
            self?.alertError = self?.service.alertError
            self?.showAlertError = val
        }
        .store(in: &self.subscriptions)
        
        service.$flashMode.sink { [weak self] mode in
            self?.isFlashOn = mode == .on
        }
        .store(in: &self.subscriptions)
    }
    
    public func configure() {
        service.checkForPermissions()
        service.configure()
    }
    
    public func capturePhoto() {
        service.capturePhoto()
    }
    
    public func savePhoto() {
        photoStorage.savePhoto(photo: self.photo)
    }
    
    public func switchCamera() {
        service.switchCamera()
    }
    
    public func zoom(with factor: CGFloat) {
        service.set(zoom: factor)
    }
    
    public func switchFlash() {
        service.flashMode = service.flashMode == .on ? .off : .on
    }
    
    public func alert(alertError: AlertError) {
        service.alertError = alertError
    }
}

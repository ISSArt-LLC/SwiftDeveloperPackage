#if !os(macOS)

    import Foundation
    import UIKit
    import AVFoundation

    @available(iOS 13.0, *)
    public class CameraService: NSObject {
        
        @Published public var flashMode: AVCaptureDevice.FlashMode = .off
        @Published public var shouldShowAlertView = false
        @Published public var shouldShowSpinner = false
        @Published public var willCapturePhoto = false
        @Published public var isCameraButtonDisabled = true
        @Published public var isCameraUnavailable = true
        @Published public var photo: Photo?
        
        public var alertError: AlertError = AlertError()
        
        public let session = AVCaptureSession()
        private var isSessionRunning = false
        private var isConfigured = false
        private var setupResult: SessionSetupResult = .success
        private let sessionQueue = DispatchQueue(label: "camera session queue")
        @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
        
        private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified)
        
        private let photoOutput = AVCapturePhotoOutput()
        private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
        
        public func configure() {
            /*
             Setup the capture session.
             In general, it's not safe to mutate an AVCaptureSession or any of its
             inputs, outputs, or connections from multiple threads at the same time.
             
             Don't perform these tasks on the main queue because
             AVCaptureSession.startRunning() is a blocking call, which can
             take a long time. Dispatch session setup to the sessionQueue, so
             that the main queue isn't blocked, which keeps the UI responsive.
             */
            sessionQueue.async { [weak self] in
                self?.configureSession()
            }
        }
        
        public func checkForPermissions() {
            
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                // The user has previously granted access to the camera.
                break
            case .notDetermined:
                /*
                 The user has not yet been presented with the option to grant
                 video access. Suspend the session queue to delay session
                 setup until the access request has completed.
                 */
                sessionQueue.suspend()
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if !granted {
                        self.setupResult = .notAuthorized
                    }
                    self.sessionQueue.resume()
                })
                
            default:
                // The user has previously denied access.
                // Store this result, create an alert error and tell the UI to show it.
                setupResult = .notAuthorized
                
                DispatchQueue.main.async { [weak self] in
                    self?.alertError = AlertError(
                        title: "Camera Access",
                        message: "SwiftCamera doesn't have access to use your camera, please update your privacy settings.",
                        primaryButtonTitle: "Settings",
                        secondaryButtonTitle: nil,
                        primaryAction: {
                            UIApplication.shared.open(
                                URL(string: UIApplication.openSettingsURLString)!,
                                options: [:],
                                completionHandler: nil
                            )
                        },
                        secondaryAction: nil
                    )
                    self?.shouldShowAlertView = true
                    self?.isCameraUnavailable = true
                    self?.isCameraButtonDisabled = true
                }
            }
        }
        
        private func configureSession() {
            if setupResult != .success {
                return
            }
            
            session.beginConfiguration()
            
            session.sessionPreset = .photo
            
            do {
                var defaultVideoDevice: AVCaptureDevice?
                
                if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                    defaultVideoDevice = backCameraDevice
                } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                    defaultVideoDevice = frontCameraDevice
                } else {
                    print("Default video device is unavailable.")
                    setupResult = .configurationFailed
                    session.commitConfiguration()
                    return
                }
                let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice!)
                
                if session.canAddInput(videoDeviceInput) {
                    session.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
                    
                } else {
                    print("Couldn't add video device input to the session.")
                    setupResult = .configurationFailed
                    session.commitConfiguration()
                    return
                }
            } catch {
                print("Couldn't create video device input: \(error)")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                
                photoOutput.isHighResolutionCaptureEnabled = true
                photoOutput.maxPhotoQualityPrioritization = .quality
                
            } else {
                print("Could not add photo output to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            
            session.commitConfiguration()
            self.isConfigured = true
            
            self.start()
        }
        
        public func start() {
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                if !self.isSessionRunning && self.isConfigured {
                    switch self.setupResult {
                    case .success:
                        self.session.startRunning()
                        self.isSessionRunning = self.session.isRunning
                        
                        if self.session.isRunning {
                            DispatchQueue.main.async { [weak self] in
                                self?.isCameraButtonDisabled = false
                                self?.isCameraUnavailable = false
                            }
                        }
                        
                    case .configurationFailed, .notAuthorized:
                        print("Application not authorized to use camera")
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.alertError = AlertError(
                                title: "Camera Error",
                                message: "Camera configuration failed. Either your device camera is not available or its missing permissions",
                                primaryButtonTitle: "Accept",
                                secondaryButtonTitle: nil,
                                primaryAction: nil,
                                secondaryAction: nil
                            )
                            self?.shouldShowAlertView = true
                            self?.isCameraButtonDisabled = true
                            self?.isCameraUnavailable = true
                        }
                    }
                }
            }
        }
        
        public func stop(completion: (() -> ())? = nil) {
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                if self.isSessionRunning {
                    if self.setupResult == .success {
                        self.session.stopRunning()
                        self.isSessionRunning = self.session.isRunning
                        
                        if !self.session.isRunning {
                            DispatchQueue.main.async { [weak self] in
                                self?.isCameraButtonDisabled = true
                                self?.isCameraUnavailable = true
                                completion?()
                            }
                        }
                    }
                }
            }
        }
        
        public func set(zoom: CGFloat){
            let factor = zoom < 1 ? 1 : zoom
            let device = self.videoDeviceInput.device
            
            do {
                defer {
                    device.unlockForConfiguration()
                }
                try device.lockForConfiguration()
                device.videoZoomFactor = factor
            }
            catch {
                print(error.localizedDescription)
            }
        }
        
        public func switchCamera() {
            DispatchQueue.main.async { [weak self] in
                self?.isCameraButtonDisabled = true
            }
            
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                let currentVideoDevice = self.videoDeviceInput.device
                let currentPosition = currentVideoDevice.position
                
                let preferredPosition: AVCaptureDevice.Position
                let preferredDeviceType: AVCaptureDevice.DeviceType
                
                switch currentPosition {
                case .unspecified, .front:
                    preferredPosition = .back
                    preferredDeviceType = .builtInWideAngleCamera
                case .back:
                    preferredPosition = .front
                    preferredDeviceType = .builtInWideAngleCamera
                @unknown default:
                    print("Unknown capture position. Defaulting to back, dual-camera.")
                    preferredPosition = .back
                    preferredDeviceType = .builtInWideAngleCamera
                }
                
                let devices = self.videoDeviceDiscoverySession.devices
                var newVideoDevice: AVCaptureDevice? = nil
                
                // First, seek a device with both the preferred position and device type. Otherwise, seek a device with only the preferred position.
                if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                    newVideoDevice = device
                } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                    newVideoDevice = device
                }
                
                if let videoDevice = newVideoDevice {
                    do {
                        let input = try AVCaptureDeviceInput(device: videoDevice)
                        
                        self.session.beginConfiguration()
                        
                        // Remove the existing device input first, because AVCaptureSession doesn't support
                        // simultaneous use of the rear and front cameras.
                        self.session.removeInput(self.videoDeviceInput)
                        
                        if self.session.canAddInput(input) {
                            self.session.addInput(input)
                            self.videoDeviceInput = input
                        } else {
                            self.session.addInput(self.videoDeviceInput)
                        }
                        
                        if let connection = self.photoOutput.connection(with: .video) {
                            if connection.isVideoStabilizationSupported {
                                connection.preferredVideoStabilizationMode = .auto
                            }
                        }
                        
                        self.photoOutput.maxPhotoQualityPrioritization = .quality
                        
                        self.session.commitConfiguration()
                    } catch {
                        print("Error occurred while creating video device input: \(error)")
                    }
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.isCameraButtonDisabled = false
                }
            }
        }
        
        public func capturePhoto() {
            if self.setupResult != .configurationFailed {
                self.isCameraButtonDisabled = true
                
                sessionQueue.async { [weak self] in
                    guard let self = self else { return }
                    if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                        photoOutputConnection.videoOrientation = .portrait
                    }
                    var photoSettings = AVCapturePhotoSettings()
                    
                    // Capture HEIF photos when supported. Enable according to user settings and high-resolution photos.
                    if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                        photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                    }
                    
                    // Sets the flash option for this capture.
                    if self.videoDeviceInput.device.isFlashAvailable {
                        photoSettings.flashMode = self.flashMode
                    }
                    
                    photoSettings.isHighResolutionPhotoEnabled = true
                    
                    // Sets the preview thumbnail pixel format
                    if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                        photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
                    }
                    
                    photoSettings.photoQualityPrioritization = .quality
                    
                    let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, willCapturePhotoAnimation: {
                        DispatchQueue.main.async { [weak self] in
                            self?.willCapturePhoto.toggle()
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                            self?.willCapturePhoto.toggle()
                        }
                        
                    }, completionHandler: { [weak self] processor in
                        if let data = processor.photoData {
                            self?.photo = Photo(originalData: data, uniformTypeIdentifier: photoSettings.processedFileType.map { $0.rawValue })
                        }
                        
                        self?.isCameraButtonDisabled = false
                        self?.sessionQueue.async { [weak self] in
                            self?.inProgressPhotoCaptureDelegates[processor.requestedPhotoSettings.uniqueID] = nil
                        }
                    }, photoProcessingHandler: { [weak self] animate in
                        self?.shouldShowSpinner = animate
                    })
                    
                    // The photo output holds a weak reference to the photo capture delegate and stores it in an array to maintain a strong reference.
                    self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
                    self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
                }
            }
        }
        
        enum LivePhotoMode {
            case on
            case off
        }
        
        enum DepthDataDeliveryMode {
            case on
            case off
        }
        
        enum PortraitEffectsMatteDeliveryMode {
            case on
            case off
        }
        
        enum SessionSetupResult {
            case success
            case notAuthorized
            case configurationFailed
        }
        
        enum CaptureMode: Int {
            case photo = 0
            case movie = 1
        }
    }
#endif

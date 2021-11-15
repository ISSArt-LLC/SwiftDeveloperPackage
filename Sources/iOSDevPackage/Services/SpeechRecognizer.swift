import Foundation
import Speech
import SwiftUI

@available(iOS 13.0, *)
public class SpeechRecognizer: ObservableObject {

    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    @Published public var transcript = ""

    public init(speechRecognizer: SFSpeechRecognizer) {
        self.speechRecognizer = speechRecognizer
    }

    public func startRecognition() {
        do {
            canAccess { authorized in
                if !authorized {
                    fatalError("Can't get access to microphone or speech recognition")
                }
            }
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let request = self.recognitionRequest else {
                fatalError("Unable to create speech recognition request")
            }
            request.shouldReportPartialResults = true

            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let recordingFormat = self.audioEngine.inputNode.outputFormat(forBus: 0)
            audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }

            self.audioEngine.prepare()
            try self.audioEngine.start()

            self.recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
                var isFinal = false
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString
                    isFinal = result.isFinal
                }

                if error != nil || isFinal {
                    self.audioEngine.stop()
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                }
            }
        } catch {
            print("Error transcibing audio: " + error.localizedDescription)
            self.reset()
        }
    }

    public func stopRecognition() {
        self.reset()
    }

    public func canAccess(withHandler handler: @escaping (Bool) -> Void) {
        var authorized = true
        SFSpeechRecognizer.requestAuthorization { authStatus in
            authorized = authStatus == .authorized
        }
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            authorized = granted
        }
        handler(authorized)
    }

    private func reset() {
        recognitionTask?.cancel()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionRequest = nil
        recognitionTask = nil
    }
}

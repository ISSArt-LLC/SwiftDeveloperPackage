# iOSDevPackage

Репозиторий со Swift Package в котором будут классы, расширения, инструменты, которые будем переиспользовать. Пакеты Swift легко имортировать и просто писать.

Нужно :
- Прогресс бар (горизонтальный, крутящийся) для 13 < iOS < 14.
- Что-то свое.

### Расширение для цвета, чтобы он понимал HEX строки

```swift
Color.init(hex: 0x65696B)

Color.init(hex: 0x65696B, alpha: 1)
```

### Стэк навигации

```swift
struct ContentView: View {
    
    var body: some View {
        NavigationControllerView(transition: .custom(.slide, .slide)) {
            SecondView()
        }
    }
}
```

```swift
struct SecondView: View {
    
    @EnvironmentObject private var navigation: NavigationControllerViewModel

    var body: some View {
        Button("ThirdView") {
            navigation.push(ThirdView())
        }
    }
}
```

```swift
struct ThirdView: View {
    
    @EnvironmentObject private var navigation: NavigationControllerViewModel

    var body: some View {
        Button("Return") {
            navigation.pop(to: .previous)
        }
    }
}
```

### Dependency Injection

```swift
ServiceLocator.shared.addDependency(NetworkService() as BasicNetworkService)
// or
LazyServiceLocator.shared.addDependency(initializer: { return NetworkService() as BasicNetworkService})

ServiceLocator.shared.getDependency(BasicNetworkService.self)
```

### UIImage Resizing

```swift
image.resize(targetWidth: 800)
// or
image.resize(targetSize: CGSize(width: 800, height: 600)
```

### Камера

```swift
let cameraViewModel = CameraViewModel()
cameraViewModel.configure()

ServiceLocator.shared.addDependency(cameraViewModel)
// or
let contentView = ContentView()
    .environmentObject(cameraViewModel)
```

Info.plist должен содержать ключ NSCameraUsageDescription, в качестве значения необходимо указать, как ваше приложение использует камеру.

По умолчанию при сохранении фото будет использовано локальное хранилище `LocalPhotoStorage`, для использования другого хранилища (облако и т.д.) необходимо создать класс, реализующий протокол `BasicPhotoStorage`:

```swift
ServiceLocator.shared.addDependency(CustomPhotoStorage() as BasicPhotoStorage)
```

### Speech To Text

```swift
guard let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU")) else {
    // handle it
}

let contentView = ContentView()
    .environmentObject(SpeechRecognizer(speechRecognizer: speechRecognizer))
```

Info.plist должен содержать :
 - ключ NSMicrophoneUsageDescription, в качестве значения необходимо указать, как ваше приложение использует микрофон
 - ключ NSSpeechRecognitionUsageDescription, в качестве значения необходимо указать, как ваше приложение использует распознавание речи.
 
 Пример использования:

 ```swift
 struct SomeView: View {

     @EnvironmentObject private var speechRecognizer: SpeechRecognizer
     @State private var isRecording = false
     
     var body: some View {
         VStack {
             Text(speechRecognizer.transcript)
                 .padding()
             Button(
                 action: {
                     if isRecording {
                         speechRecognizer.stopRecognition()
                     } else {
                         speechRecognizer.startRecognition()
                     }
                     isRecording.toggle()
                 },
                 label: {
                     // ...
                 }
             )
         }
         .onAppear {
             speechRecognizer.canAccess { authorized in
                 accessDenied = !authorized
             }
         }
     }
 }
 ```

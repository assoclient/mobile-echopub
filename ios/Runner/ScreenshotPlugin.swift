import Flutter
import UIKit
import Photos

public class ScreenshotPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var isListening = false
    private var timeoutTimer: Timer?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.echopub.mobile/screenshot", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "com.echopub.mobile/screenshot_events", binaryMessenger: registrar.messenger())
        
        let instance = ScreenshotPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            result(true)
            
        case "startScreenshotListener":
            startScreenshotListener()
            result(true)
            
        case "stopService":
            stopScreenshotListener()
            result(true)
            
        case "hasOverlayPermission":
            // iOS n'a pas besoin de permission overlay
            result(true)
            
        case "requestOverlayPermission":
            // iOS n'a pas besoin de permission overlay
            result(nil)
            
        case "processScreenshot":
            if let args = call.arguments as? [String: Any],
               let imagePath = args["imagePath"] as? String {
                processScreenshot(imagePath: imagePath, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Arguments invalides", details: nil))
            }
            
        case "openAppSettings":
            openAppSettings()
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    // MARK: - Screenshot Listener
    
    private func startScreenshotListener() {
        guard !isListening else { return }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotTaken),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        
        isListening = true
        sendEvent(event: "serviceStarted", imagePath: nil, errorMessage: nil)
        print("📸 Screenshot listener démarré")
    }
    
    private func stopScreenshotListener() {
        guard isListening else { return }
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        isListening = false
        
        sendEvent(event: "serviceStopped", imagePath: nil, errorMessage: nil)
        print("📸 Screenshot listener arrêté")
    }
    
    @objc private func screenshotTaken() {
        print("📸 Screenshot détecté!")
        
        // Envoyer l'événement à Flutter
        sendEvent(event: "screenshotTaken", imagePath: nil, errorMessage: nil)
        
        // Démarrer le timeout de 2 minutes
        startTimeout()
        
        // Demander à l'utilisateur d'importer l'image
        DispatchQueue.main.async {
            self.promptUserToImportScreenshot()
        }
    }
    
    private func startTimeout() {
        timeoutTimer?.invalidate()
        
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 120.0, repeats: false) { [weak self] _ in
            print("⏰ Timeout de capture atteint")
            self?.sendEvent(event: "timeoutReached", imagePath: nil, errorMessage: "Timeout de 2 minutes atteint")
            self?.timeoutTimer = nil
        }
    }
    
    private func promptUserToImportScreenshot() {
        guard let topViewController = getTopViewController() else { return }
        
        let alert = UIAlertController(
            title: "Capture d'écran détectée",
            message: "Voulez-vous importer cette capture comme preuve de publication ?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Importer", style: .default) { [weak self] _ in
            self?.openPhotoLibrary()
        })
        
        alert.addAction(UIAlertAction(title: "Ignorer", style: .cancel) { [weak self] _ in
            self?.timeoutTimer?.invalidate()
            self?.timeoutTimer = nil
        })
        
        topViewController.present(alert, animated: true)
    }
    
    private func openPhotoLibrary() {
        guard let topViewController = getTopViewController() else { return }
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = ["public.image"]
        imagePickerController.delegate = self
        
        topViewController.present(imagePickerController, animated: true)
    }
    
    private func processScreenshot(imagePath: String, result: @escaping FlutterResult) {
        // Traitement basique de l'image (compression, métadonnées, etc.)
        guard let image = UIImage(contentsOfFile: imagePath) else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Image invalide", details: nil))
            return
        }
        
        // Compresser l'image si nécessaire
        let compressedData = image.jpegData(compressionQuality: 0.8)
        
        // Créer un nouveau fichier temporaire
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let processedPath = "\(documentsPath)/processed_screenshot_\(Date().timeIntervalSince1970).jpg"
        
        do {
            try compressedData?.write(to: URL(fileURLWithPath: processedPath))
            result(["processedPath": processedPath])
        } catch {
            result(FlutterError(code: "PROCESSING_ERROR", message: error.localizedDescription, details: nil))
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        var topViewController = window.rootViewController
        while let presentedViewController = topViewController?.presentedViewController {
            topViewController = presentedViewController
        }
        
        return topViewController
    }
    
    private func sendEvent(event: String, imagePath: String?, errorMessage: String?) {
        let eventData: [String: Any?] = [
            "event": event,
            "imagePath": imagePath,
            "errorMessage": errorMessage,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        
        eventSink?(eventData)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ScreenshotPlugin: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            sendEvent(event: "error", imagePath: nil, errorMessage: "Impossible de récupérer l'image")
            return
        }
        
        // Sauvegarder l'image temporairement
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let imagePath = "\(documentsPath)/screenshot_\(Date().timeIntervalSince1970).jpg"
        
        if let imageData = image.jpegData(compressionQuality: 0.9) {
            do {
                try imageData.write(to: URL(fileURLWithPath: imagePath))
                
                // Annuler le timeout
                timeoutTimer?.invalidate()
                timeoutTimer = nil
                
                // Envoyer l'événement de capture traitée
                sendEvent(event: "screenshotProcessed", imagePath: imagePath, errorMessage: nil)
                
            } catch {
                sendEvent(event: "error", imagePath: nil, errorMessage: error.localizedDescription)
            }
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        
        // L'utilisateur a annulé, mais le timeout continue
        print("📸 Import de screenshot annulé par l'utilisateur")
    }
}

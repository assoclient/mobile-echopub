# Système de Capture d'Écran Avancé - Implémentation Complète

## 🎯 Vue d'Ensemble

Implémentation d'un système de capture d'écran sophistiqué suivant les directives spécifiques pour Android et iOS :

### **Android** 🤖
- **Bouton flottant (overlay)** avec permission `SYSTEM_ALERT_WINDOW`
- **Capture automatique** via `MediaProjection` (image, pas vidéo)
- **Traitement direct** dans l'app Flutter

### **iOS** 🍎  
- **Écoute des notifications** `UIScreen.screenshotNotification`
- **Détection automatique** des captures utilisateur
- **Timeout de 2 minutes** pour l'import
- **Invitation à importer** l'image dans l'app

---

## 🔧 Architecture Technique

### **1. Service Flutter (Cross-Platform)**
```dart
// lib/plugins/screenshot_service.dart
class ScreenshotService {
  static const MethodChannel _channel = MethodChannel('com.echopub.mobile/screenshot');
  static const EventChannel _eventChannel = EventChannel('com.echopub.mobile/screenshot_events');
  
  // Méthodes principales
  static Future<bool> startScreenshotService()
  static Future<bool> stopScreenshotService()
  static Stream<Map<String, dynamic>> getScreenshotStream()
  static void startTimeout({required VoidCallback onTimeout})
}
```

### **2. Service Android Natif**
```kotlin
// ScreenshotService.kt - Service de premier plan
class ScreenshotService : Service() {
  private var floatingView: View? = null
  private var mediaProjection: MediaProjection? = null
  private var virtualDisplay: VirtualDisplay? = null
  private var imageReader: ImageReader? = null
  
  // Fonctionnalités principales
  fun startFloatingButton()
  fun takeScreenshot()
  fun processImage(image: Image)
}
```

### **3. Plugin iOS Natif**
```swift
// ScreenshotPlugin.swift - Listener de notifications
public class ScreenshotPlugin: NSObject, FlutterPlugin {
  @objc private func screenshotTaken()
  private func startTimeout()
  private func promptUserToImportScreenshot()
}
```

---

## 📱 Interface Utilisateur

### **Widget de Capture Avancé**
```dart
// lib/widgets/screenshot_capture_widget.dart
class ScreenshotCaptureWidget extends StatefulWidget {
  final String campaignId;
  final String campaignTitle;
  final Function(String imagePath) onScreenshotCaptured;
  final VoidCallback? onTimeout;
  final VoidCallback? onError;
}
```

#### **États du Service**
- 🔴 **Idle** : Service non démarré
- 🟡 **Initializing** : Initialisation en cours
- 🟢 **Ready** : Prêt à capturer
- 🔵 **Capturing** : Capture en cours
- 🟣 **Processing** : Traitement de l'image
- 🔴 **Error** : Erreur ou permissions manquantes

#### **Interface Adaptative**
- **Instructions spécifiques** à chaque plateforme
- **Indicateurs visuels** de statut avec couleurs
- **Boutons contextuels** selon l'état
- **Messages d'erreur** informatifs

---

## 🔐 Permissions et Configuration

### **Android Permissions**
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

<service
    android:name=".ScreenshotService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="mediaProjection" />
```

### **iOS Permissions**
```swift
// Info.plist (automatiquement géré)
// Pas de permissions spéciales requises pour la détection
```

---

## 🚀 Flux d'Utilisation

### **Flux Android** 🤖

1. **🎯 Démarrage**
   ```
   Utilisateur → "Capture automatique" → Vérification permission overlay
   ```

2. **🔘 Bouton Flottant**
   ```
   Service démarre → Bouton flottant affiché → Notification persistante
   ```

3. **📸 Capture**
   ```
   Clic bouton → MediaProjection → VirtualDisplay → ImageReader → Bitmap
   ```

4. **💾 Traitement**
   ```
   Sauvegarde PNG → Envoi événement Flutter → Confirmation utilisateur
   ```

### **Flux iOS** 🍎

1. **👂 Écoute**
   ```
   Utilisateur → "Détecter capture" → Listener notification activé
   ```

2. **🔔 Détection**
   ```
   Screenshot physique → Notification système → Timer 2min démarré
   ```

3. **📋 Import**
   ```
   Alert utilisateur → Sélection photo → Validation → Upload
   ```

4. **⏰ Timeout**
   ```
   2 minutes → Auto-expiration → Message d'erreur
   ```

---

## 🔄 Intégration dans l'App

### **Page Publications Ambassadeur**
```dart
// Nouveau choix dans _pickCapture()
final choice = await showDialog<String>(
  builder: (context) => AlertDialog(
    title: Text('${captureNum == 1 ? "Première" : "Deuxième"} preuve'),
    actions: [
      TextButton.icon(
        onPressed: () => Navigator.pop(context, 'auto'),
        icon: const Icon(Icons.camera_alt),
        label: Text(Platform.isAndroid 
            ? 'Capture automatique' 
            : 'Détecter capture'),
      ),
      TextButton.icon(
        onPressed: () => Navigator.pop(context, 'gallery'),
        icon: const Icon(Icons.photo_library),
        label: const Text('Galerie'),
      ),
    ],
  ),
);
```

### **Gestion des Événements**
```dart
void _handleScreenshotEvent(Map<String, dynamic> eventData) {
  final event = ScreenshotEventData.fromMap(eventData);
  
  switch (event.event) {
    case ScreenshotEvent.serviceStarted:
      // Service prêt
    case ScreenshotEvent.screenshotTaken:
      // Capture réalisée
    case ScreenshotEvent.screenshotProcessed:
      // Image disponible
    case ScreenshotEvent.timeoutReached:
      // Timeout atteint (iOS)
    case ScreenshotEvent.error:
      // Erreur survenue
  }
}
```

---

## 📊 Avantages de l'Implémentation

### **🎯 Précision**
- ✅ **Capture exacte** du contenu affiché
- ✅ **Pas de manipulation** manuelle
- ✅ **Timing parfait** de la capture

### **🔒 Sécurité**
- ✅ **Permissions contrôlées** par l'OS
- ✅ **Pas de stockage persistant** non autorisé
- ✅ **Validation utilisateur** obligatoire

### **📱 UX Optimale**
- ✅ **Interface intuitive** par plateforme
- ✅ **Feedback visuel** en temps réel
- ✅ **Gestion d'erreurs** complète
- ✅ **Fallback galerie** disponible

### **⚡ Performance**
- ✅ **Service natif** optimisé
- ✅ **Traitement asynchrone** des images
- ✅ **Gestion mémoire** appropriée
- ✅ **Cleanup automatique** des ressources

---

## 🔧 Utilisation

### **Pour l'Ambassadeur**

1. **📱 Ouvrir** la page Publications
2. **👆 Cliquer** "Remplacer" sur une preuve
3. **🎯 Choisir** "Capture automatique" ou "Détecter capture"
4. **📸 Android** : Cliquer le bouton flottant sur l'app cible
5. **📸 iOS** : Prendre screenshot avec boutons physiques + importer
6. **✅ Confirmer** la capture dans l'app
7. **⬆️ Upload** automatique vers le backend

### **Gestion d'Erreurs**
- **❌ Permissions refusées** → Redirection paramètres
- **⏰ Timeout iOS** → Message + possibilité de recommencer  
- **🔧 Service indisponible** → Fallback vers galerie
- **📡 Erreur réseau** → Retry automatique

---

## ✅ Résultat Final

### **🎉 Fonctionnalités Actives**
- 🤖 **Android** : Bouton flottant + capture MediaProjection
- 🍎 **iOS** : Détection screenshot + timeout 2min
- 🔄 **Cross-platform** : Interface unifiée Flutter
- 📸 **Dual-mode** : Automatique + Galerie
- 🔐 **Permissions** : Gestion complète
- ⚡ **Performance** : Services natifs optimisés

### **🚀 Prêt pour Production**
L'ambassadeur peut maintenant **capturer ses preuves de publication** de manière **automatique et précise**, avec une **expérience utilisateur optimale** sur les deux plateformes !

Le système respecte **parfaitement** les directives techniques spécifiées et offre une **solution robuste** pour la collecte de preuves de publication.

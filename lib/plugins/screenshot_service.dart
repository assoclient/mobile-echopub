import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class ScreenshotService {
  static const MethodChannel _channel = MethodChannel('com.echopub.communications/screenshot');
  static const EventChannel _eventChannel = EventChannel('com.echopub.communications/screenshot_events');
  
  static Stream<Map<String, dynamic>>? _screenshotStream;
  static Timer? _timeoutTimer;
  static VoidCallback? _onTimeoutCallback;
  
  /// Initialise le service de capture d'écran selon la plateforme
  static Future<bool> initialize() async {
    try {
      final bool result = await _channel.invokeMethod('initialize');
      return result;
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du service screenshot: $e');
      return false;
    }
  }
  
  /// Démarre le service de capture (Android: bouton flottant, iOS: listener)
  static Future<bool> startScreenshotService() async {
    try {
      if (Platform.isAndroid) {
        // Vérifier la permission SYSTEM_ALERT_WINDOW
        final bool hasPermission = await hasOverlayPermission();
        if (!hasPermission) {
          await requestOverlayPermission();
          return false;
        }
        
        // Démarrer le service avec bouton flottant
        final bool result = await _channel.invokeMethod('startFloatingButton');
        //final bool requestPermission = await _channel.invokeMethod('requestMediaProjection');
        return result;
      } else if (Platform.isIOS) {
        // Démarrer l'écoute des notifications de screenshot
        final bool result = await _channel.invokeMethod('startScreenshotListener');
        return result;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors du démarrage du service screenshot: $e');
      return false;
    }
  }
  
  /// Arrête le service de capture
  static Future<bool> stopScreenshotService() async {
    try {
      final bool result = await _channel.invokeMethod('stopService');
      _timeoutTimer?.cancel();
      return result;
    } catch (e) {
      debugPrint('Erreur lors de l\'arrêt du service screenshot: $e');
      return false;
    }
  }
  
  /// Vérifie si la permission overlay est accordée (Android)
  static Future<bool> hasOverlayPermission() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool hasPermission = await _channel.invokeMethod('hasOverlayPermission');
      return hasPermission;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la permission overlay: $e');
      return false;
    }
  }
  
  /// Demande la permission overlay (Android)
  static Future<void> requestOverlayPermission() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      debugPrint('Erreur lors de la demande de permission overlay: $e');
    }
  }
  
  /// Écoute les événements de capture d'écran
  static Stream<Map<String, dynamic>> getScreenshotStream() {
    _screenshotStream ??= _eventChannel
        .receiveBroadcastStream()
        .map<Map<String, dynamic>>((dynamic event) {
      return Map<String, dynamic>.from(event);
    });
    
    return _screenshotStream!;
  }
  
  /// Démarre le timeout pour iOS (2 minutes)
  static void startTimeout({required VoidCallback onTimeout}) {
    _timeoutTimer?.cancel();
    _onTimeoutCallback = onTimeout;
    
    _timeoutTimer = Timer(const Duration(minutes: 2), () {
      debugPrint('Timeout de capture d\'écran atteint');
      _onTimeoutCallback?.call();
      _timeoutTimer = null;
    });
  }
  
  /// Annule le timeout
  static void cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }
  
  /// Traite l'image capturée
  static Future<String?> processScreenshot(String imagePath) async {
    try {
      final Map<String, dynamic> result = await _channel.invokeMethod('processScreenshot', {
        'imagePath': imagePath,
      });
      
      return result['processedPath'] as String?;
    } catch (e) {
      debugPrint('Erreur lors du traitement de la capture: $e');
      return null;
    }
  }
  
  /// Déclenche manuellement une capture (Android uniquement)
  static Future<String?> takeScreenshot() async {
    if (!Platform.isAndroid) return null;
    
    try {
      final Map<String, dynamic> result = await _channel.invokeMethod('takeScreenshot');
      return result['imagePath'] as String?;
    } catch (e) {
      debugPrint('Erreur lors de la capture: $e');
      return null;
    }
  }
  
  /// Ouvre les paramètres de l'application pour les permissions
  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture des paramètres: $e');
    }
  }

  /// Revenir à l'application Flutter
  static Future<void> returnToApp() async {
    try {
      await _channel.invokeMethod('returnToApp');
    } catch (e) {
      debugPrint('Erreur lors du retour à l\'app: $e');
    }
  }
}

/// États du service de capture
enum ScreenshotServiceState {
  idle,
  initializing,
  ready,
  capturing,
  processing,
  error,
}

/// Événements de capture
enum ScreenshotEvent {
  serviceStarted,
  serviceStoped,
  screenshotTaken,
  screenshotProcessed,
  mediaProjectionReady,
  timeoutReached,
  permissionDenied,
  error,
}

/// Données d'événement de capture
class ScreenshotEventData {
  final ScreenshotEvent event;
  final String? imagePath;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  
  const ScreenshotEventData({
    required this.event,
    this.imagePath,
    this.errorMessage,
    this.metadata,
  });
  
  factory ScreenshotEventData.fromMap(Map<String, dynamic> map) {
    return ScreenshotEventData(
      event: ScreenshotEvent.values.firstWhere(
        (e) => e.toString().split('.').last == map['event'],
        orElse: () => ScreenshotEvent.error,
      ),
      imagePath: map['imagePath'] as String?,
      errorMessage: map['errorMessage'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../plugins/screenshot_service.dart';
import '../theme.dart';

class ScreenshotCaptureWidget extends StatefulWidget {
  final String campaignId;
  final String campaignTitle;
  final Function(String imagePath) onScreenshotCaptured;
  final VoidCallback? onTimeout;
  final VoidCallback? onError;
  
  const ScreenshotCaptureWidget({
    Key? key,
    required this.campaignId,
    required this.campaignTitle,
    required this.onScreenshotCaptured,
    this.onTimeout,
    this.onError,
  }) : super(key: key);

  @override
  State<ScreenshotCaptureWidget> createState() => _ScreenshotCaptureWidgetState();
}

class _ScreenshotCaptureWidgetState extends State<ScreenshotCaptureWidget> {
  ScreenshotServiceState _serviceState = ScreenshotServiceState.idle;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  bool _isWaitingForScreenshot = false;
  Timer? _timeoutTimer;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _timeoutTimer?.cancel();
    ScreenshotService.stopScreenshotService();
    super.dispose();
  }

  Future<void> _initializeService() async {
    setState(() {
      _serviceState = ScreenshotServiceState.initializing;
      _statusMessage = 'Initialisation du service...';
    });

    final initialized = await ScreenshotService.initialize();
    if (!initialized) {
      setState(() {
        _serviceState = ScreenshotServiceState.error;
        _statusMessage = 'Erreur d\'initialisation';
      });
      widget.onError?.call();
      return;
    }

    // Écouter les événements
    _eventSubscription = ScreenshotService.getScreenshotStream().listen(
      _handleScreenshotEvent,
      onError: (error) {
        setState(() {
          _serviceState = ScreenshotServiceState.error;
          _statusMessage = 'Erreur: $error';
        });
        widget.onError?.call();
      },
    );

    setState(() {
      _serviceState = ScreenshotServiceState.ready;
      _statusMessage = 'Service prêt';
    });
  }

  void _handleScreenshotEvent(Map<String, dynamic> eventData) {
    final event = ScreenshotEventData.fromMap(eventData);
    
    switch (event.event) {
      case ScreenshotEvent.serviceStarted:
        setState(() {
          _serviceState = ScreenshotServiceState.ready;
          _statusMessage = Platform.isAndroid 
              ? 'Bouton flottant actif - Cliquez pour capturer'
              : 'En attente de capture d\'écran...';
        });
        break;

      case ScreenshotEvent.screenshotTaken:
        setState(() {
          _serviceState = ScreenshotServiceState.capturing;
          _statusMessage = Platform.isAndroid 
              ? 'Capture en cours...'
              : 'Capture détectée - Importez l\'image (2 min max)';
          _isWaitingForScreenshot = true;
        });
        
        if (Platform.isIOS) {
          _startTimeout();
        }
        break;

      case ScreenshotEvent.mediaProjectionReady:
        setState(() {
          _serviceState = ScreenshotServiceState.ready;
          _statusMessage = 'Permission accordée! Naviguez vers l\'app cible puis cliquez le bouton bleu flottant';
          _isWaitingForScreenshot = true; // Garder true pour maintenir l'état de capture actif
        });
        break;

      case ScreenshotEvent.screenshotProcessed:
        if (event.imagePath != null) {
          _timeoutTimer?.cancel();
          setState(() {
            _serviceState = ScreenshotServiceState.ready;
            _statusMessage = '📸 Capture réussie ! Retour automatique dans 3 secondes...';
            _isWaitingForScreenshot = false;
          });
          
          // Afficher une notification de succès
          _showCaptureSuccessMessage();
          
          // Laisser le callback gérer la fermeture du dialog
          // Pas de fermeture automatique ici
          widget.onScreenshotCaptured(event.imagePath!);
        }
        break;

      case ScreenshotEvent.timeoutReached:
        setState(() {
          _serviceState = ScreenshotServiceState.error;
          _statusMessage = 'Timeout atteint - Recommencez';
          _isWaitingForScreenshot = false;
        });
        widget.onTimeout?.call();
        break;

      case ScreenshotEvent.permissionDenied:
        setState(() {
          _serviceState = ScreenshotServiceState.error;
          _statusMessage = 'Permission refusée';
        });
        widget.onError?.call();
        break;

      case ScreenshotEvent.error:
        setState(() {
          _serviceState = ScreenshotServiceState.error;
          _statusMessage = event.errorMessage ?? 'Erreur inconnue';
        });
        widget.onError?.call();
        break;

      default:
        break;
    }
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(minutes: 2), () {
      setState(() {
        _serviceState = ScreenshotServiceState.error;
        _statusMessage = 'Timeout - Veuillez recommencer';
        _isWaitingForScreenshot = false;
      });
      widget.onTimeout?.call();
    });
  }

  void _showCaptureSuccessMessage() {
    // Afficher un snackbar de succès si possible
    if (mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📸 Capture réussie ! Retour automatique vers l\'application...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        debugPrint('Erreur affichage SnackBar: $e');
      }
    }
  }

  Future<void> _startCapture() async {
    if (_serviceState == ScreenshotServiceState.ready) {
      setState(() {
        _statusMessage = 'Démarrage du service de capture...';
      });
      
      final started = await ScreenshotService.startScreenshotService();
      if (started) {
        setState(() {
          _isWaitingForScreenshot = true;
          _statusMessage = 'Service démarré ! Naviguez vers l\'app cible puis cliquez le bouton bleu flottant';
        });
        
        if (Platform.isIOS) {
          _startTimeout();
        }
      } else {
        setState(() {
          _serviceState = ScreenshotServiceState.error;
          _statusMessage = 'Impossible de démarrer le service';
        });
      }
    }
  }

  Future<void> _stopCapture() async {
    await ScreenshotService.stopScreenshotService();
    _timeoutTimer?.cancel();
    setState(() {
      _serviceState = ScreenshotServiceState.ready;
      _statusMessage = 'Service arrêté';
      _isWaitingForScreenshot = false;
    });
  }

  Future<void> _requestPermissions() async {
    await ScreenshotService.requestOverlayPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête
          Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: AppColors.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Capture de Preuve',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Campagne
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.campaign, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.campaignTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Statut
          _buildStatusWidget(),
          
          const SizedBox(height: 16),
          
          // Instructions spécifiques à la plateforme
          _buildInstructionsWidget(),
          
          const SizedBox(height: 16),
          
          // Boutons d'action
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusWidget() {
    Color statusColor;
    IconData statusIcon;
    
    switch (_serviceState) {
      case ScreenshotServiceState.idle:
        statusColor = Colors.grey;
        statusIcon = Icons.radio_button_unchecked;
        break;
      case ScreenshotServiceState.initializing:
        statusColor = Colors.orange;
        statusIcon = Icons.refresh;
        break;
      case ScreenshotServiceState.ready:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ScreenshotServiceState.capturing:
        statusColor = Colors.blue;
        statusIcon = Icons.camera;
        break;
      case ScreenshotServiceState.processing:
        statusColor = Colors.purple;
        statusIcon = Icons.hourglass_empty;
        break;
      case ScreenshotServiceState.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage ?? 'Statut inconnu',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_serviceState == ScreenshotServiceState.initializing ||
              _serviceState == ScreenshotServiceState.capturing)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionsWidget() {
    String instructions;
    IconData icon;
    Color color;
    
    if (Platform.isAndroid) {
      instructions = 'Android: Un bouton flottant apparaîtra sur votre écran. '
          'Naviguez vers l\'application à capturer, puis cliquez sur le bouton flottant.';
      icon = Icons.android;
      color = Colors.green;
    } else {
      instructions = 'iOS: Prenez une capture d\'écran avec les boutons physiques. '
          'Vous aurez 2 minutes pour l\'importer dans l\'application.';
      icon = Icons.phone_iphone;
      color = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              instructions,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Bouton principal
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _getMainButtonAction(),
            icon: Icon(_getMainButtonIcon()),
            label: Text(_getMainButtonText()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getMainButtonColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Bouton secondaire
        if (_serviceState == ScreenshotServiceState.ready && _isWaitingForScreenshot)
          OutlinedButton.icon(
            onPressed: _stopCapture,
            icon: const Icon(Icons.stop),
            label: const Text('Arrêter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
        // Bouton paramètres
        if (_serviceState == ScreenshotServiceState.error)
          OutlinedButton.icon(
            onPressed: () => ScreenshotService.openAppSettings(),
            icon: const Icon(Icons.settings),
            label: const Text('Paramètres'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey[400]!),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }

  VoidCallback? _getMainButtonAction() {
    switch (_serviceState) {
      case ScreenshotServiceState.ready:
        return _isWaitingForScreenshot ? null : _startCapture;
      case ScreenshotServiceState.error:
        return _requestPermissions;
      default:
        return null;
    }
  }

  IconData _getMainButtonIcon() {
    switch (_serviceState) {
      case ScreenshotServiceState.ready:
        return _isWaitingForScreenshot ? Icons.hourglass_empty : Icons.play_arrow;
      case ScreenshotServiceState.error:
        return Icons.security;
      default:
        return Icons.refresh;
    }
  }

  String _getMainButtonText() {
    switch (_serviceState) {
      case ScreenshotServiceState.idle:
        return 'Initialiser';
      case ScreenshotServiceState.initializing:
        return 'Initialisation...';
      case ScreenshotServiceState.ready:
        return _isWaitingForScreenshot ? 'En attente...' : 'Commencer la capture';
      case ScreenshotServiceState.capturing:
        return 'Capture en cours...';
      case ScreenshotServiceState.processing:
        return 'Traitement...';
      case ScreenshotServiceState.error:
        return 'Accorder les permissions';
    }
  }

  Color _getMainButtonColor() {
    switch (_serviceState) {
      case ScreenshotServiceState.ready:
        return _isWaitingForScreenshot ? Colors.orange : AppColors.primaryBlue;
      case ScreenshotServiceState.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

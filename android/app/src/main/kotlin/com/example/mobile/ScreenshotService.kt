package com.example.mobile

import android.annotation.SuppressLint
import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.LayoutInflater
import android.view.WindowManager
import android.widget.TextView
import androidx.core.content.ContextCompat
import android.util.DisplayMetrics
import android.util.Log
import android.view.*
import android.widget.ImageView
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer

class ScreenshotService : Service() {
    companion object {
        private const val TAG = "ScreenshotService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "screenshot_service_channel"
        private const val REQUEST_CODE_SCREENSHOT = 1000
        
        var isServiceRunning = false
        var eventSink: EventChannel.EventSink? = null
    }
    
    private lateinit var windowManager: WindowManager
    private var floatingView: View? = null
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var mediaProjectionManager: MediaProjectionManager? = null
    
    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        createNotificationChannel()
        Log.d(TAG, "Service created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START_FLOATING_BUTTON" -> startFloatingButton()
            "STOP_SERVICE" -> stopService()
            "TAKE_SCREENSHOT" -> takeScreenshot()
            "MEDIA_PROJECTION_READY" -> onMediaProjectionReady()
        }
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Service de Capture d'Écran",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Service pour capturer les preuves de publication"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    @SuppressLint("ClickableViewAccessibility")
    private fun startFloatingButton() {
        if (!Settings.canDrawOverlays(this)) {
            Log.e(TAG, "Pas de permission overlay")
            sendEvent("permissionDenied", null, "Permission overlay requise")
            return
        }
        
        if (floatingView != null) {
            Log.d(TAG, "Bouton flottant déjà actif")
            return
        }
        
        // Créer la notification persistante
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Capture d'Écran Active")
            .setContentText("1. Naviguez vers l'app à capturer 2. Cliquez le bouton bleu")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setOngoing(true)
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("1. Naviguez vers l'application à capturer\n2. Cliquez sur le bouton bleu flottant\n3. La capture sera automatique"))
            .build()
        
        startForeground(NOTIFICATION_ID, notification)
        
        // Créer le bouton flottant
        floatingView = LayoutInflater.from(this).inflate(R.layout.floating_button, null)
        
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 100
            y = 200 // Position plus visible
        }
        
        Log.d(TAG, "Paramètres du bouton flottant - x: ${params.x}, y: ${params.y}")
        
        // Ajouter le bouton à la fenêtre
        windowManager.addView(floatingView, params)
        
        // Gérer les interactions avec le bouton
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        
        val buttonView = floatingView?.findViewById<ImageView>(R.id.floating_button)
        Log.d(TAG, "Bouton trouvé: ${buttonView != null}")
        
        buttonView?.setOnTouchListener { _, event ->
            Log.d(TAG, "Touch event reçu: ${event.action}")
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    params.x = initialX + (event.rawX - initialTouchX).toInt()
                    params.y = initialY + (event.rawY - initialTouchY).toInt()
                    windowManager.updateViewLayout(floatingView, params)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    val deltaX = Math.abs(event.rawX - initialTouchX)
                    val deltaY = Math.abs(event.rawY - initialTouchY)
                    
                    Log.d(TAG, "ACTION_UP - deltaX: $deltaX, deltaY: $deltaY")
                    
                    if (deltaX < 10 && deltaY < 10) {
                        // C'est un clic, pas un déplacement
                        Log.d(TAG, "Clic détecté sur le bouton flottant")
                        
                        // Mettre à jour la notification
                        updateNotification("Capture en cours...", "Traitement de la capture d'écran")
                        
                        // Envoyer immédiatement un événement pour confirmer le clic
                        sendEvent("screenshotTaken", null, null)
                        
                        takeScreenshot()
                    } else {
                        Log.d(TAG, "Déplacement détecté, pas de capture")
                    }
                    true
                }
                else -> false
            }
        }
        
        isServiceRunning = true
        sendEvent("serviceStarted", null, null)
        Log.d(TAG, "Bouton flottant démarré")
    }
    
    private fun takeScreenshot() {
        Log.d(TAG, "Tentative de capture d'écran")
        showPendingOverlay()
        // Nettoyer les anciennes ressources avant de recommencer
        virtualDisplay?.release()
        imageReader?.close()
        virtualDisplay = null
        imageReader = null
        
        // Récupérer la MediaProjection du singleton
        mediaProjection = com.example.mobile.MediaProjectionManager.getMediaProjection()
        
        if (mediaProjection == null) {
            Log.d(TAG, "MediaProjection non disponible, demande de permission")
            // Demander la permission MediaProjection
            requestMediaProjection()
            return
        }
        
        Log.d(TAG, "MediaProjection disponible, démarrage de la capture")
        setupImageReader()
        setupVirtualDisplay()
        
        // Attendre un peu plus longtemps pour que l'affichage se stabilise
        Handler(Looper.getMainLooper()).postDelayed({
            captureScreen()
        }, 1500) // Augmenté à 1.5 secondes
    }
    
    private fun onMediaProjectionReady() {
        Log.d(TAG, "MediaProjection prête, démarrage automatique du bouton flottant")
        
        // Démarrer automatiquement le bouton flottant après permission
        startFloatingButton()
        
        // Mettre à jour la notification
        updateNotification("Permission accordée - Prêt à capturer!", 
                          "Naviguez vers l'app cible puis cliquez le bouton bleu flottant")
        
        // Envoyer un événement pour informer l'utilisateur
        sendEvent("mediaProjectionReady", null, "Permission accordée - Le bouton flottant est maintenant actif")
    }
    
    private fun updateNotification(title: String, text: String) {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setOngoing(true)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .build()
            
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
    
    private fun showCaptureCompletedNotification() {
        val notificationManager = getSystemService(NotificationManager::class.java)
        
        // Intent pour retourner à l'application
        val intent = Intent(this, com.example.mobile.MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 
            0, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Notification popup avec action
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("📸 Capture réussie!")
            .setContentText("Retour automatique vers l'application dans 3 secondes...")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setLargeIcon(android.graphics.BitmapFactory.decodeResource(resources, android.R.drawable.ic_menu_camera))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .addAction(
                android.R.drawable.ic_media_play,
                "Retourner maintenant",
                pendingIntent
            )
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("La capture d'écran a été réalisée avec succès ! Vous allez être redirigé vers l'application automatiquement ou vous pouvez cliquer ici pour y retourner immédiatement."))
            .build()
        
        // Afficher la notification avec un ID différent pour qu'elle soit visible
        notificationManager.notify(NOTIFICATION_ID + 1, notification)
        
        // Afficher aussi un popup overlay pour une meilleure visibilité
        showSuccessOverlay()
        
        // Supprimer la notification après le délai de retour automatique
        Handler(Looper.getMainLooper()).postDelayed({
            notificationManager.cancel(NOTIFICATION_ID + 1)
        }, 3500) // Un peu après le retour automatique
    }
    
    @SuppressLint("InflateParams")
    private fun showSuccessOverlay() {
        try {
            val layoutInflater = LayoutInflater.from(this)
            val successOverlay = layoutInflater.inflate(android.R.layout.simple_list_item_1, null)
            
            // Configuration du texte
            val textView = successOverlay.findViewById<TextView>(android.R.id.text1)
            textView.text = "📸 Capture réussie!\nRetour automatique dans 3s..."
            textView.setTextColor(Color.WHITE)
            textView.gravity = Gravity.CENTER
            textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            textView.setTypeface(null, Typeface.BOLD)
            
            // Configuration du fond
            successOverlay.background = ContextCompat.getDrawable(this, android.R.drawable.dialog_holo_dark_frame)
            successOverlay.setPadding(40, 40, 40, 40)
            
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                PixelFormat.TRANSLUCENT
            )
            
            params.gravity = Gravity.CENTER
            params.x = 0
            params.y = -200 // Un peu vers le haut
            
            windowManager.addView(successOverlay, params)
            
            // Supprimer l'overlay après 3 secondes
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    windowManager.removeView(successOverlay)
                } catch (e: Exception) {
                    Log.w(TAG, "Erreur lors de la suppression de l'overlay: ${e.message}")
                }
            }, 3000)
            
            Log.d(TAG, "Overlay de succès affiché")
            
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de l'affichage de l'overlay: ${e.message}")
        }
    }
     @SuppressLint("InflateParams")
    private fun showPendingOverlay() {
        try {
            val layoutInflater = LayoutInflater.from(this)
            val successOverlay = layoutInflater.inflate(android.R.layout.simple_list_item_1, null)
            
            // Configuration du texte
            val textView = successOverlay.findViewById<TextView>(android.R.id.text1)
            textView.text = "⌛ Capture en cours !\nVeuillez patienter..."
            textView.setTextColor(Color.WHITE)
            textView.gravity = Gravity.CENTER
            textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            textView.setTypeface(null, Typeface.BOLD)
            
            // Configuration du fond
            successOverlay.background = ContextCompat.getDrawable(this, android.R.drawable.dialog_holo_dark_frame)
            successOverlay.setPadding(40, 40, 40, 40)
            
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                PixelFormat.TRANSLUCENT
            )
            
            params.gravity = Gravity.CENTER
            params.x = 0
            params.y = -200 // Un peu vers le haut
            
            windowManager.addView(successOverlay, params)
            
            // Supprimer l'overlay après 3 secondes
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    windowManager.removeView(successOverlay)
                } catch (e: Exception) {
                    Log.w(TAG, "Erreur lors de la suppression de l'overlay: ${e.message}")
                }
            }, 3000)
            
            Log.d(TAG, "Overlay de succès affiché")
            
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de l'affichage de l'overlay: ${e.message}")
        }
    }
    private fun requestMediaProjection() {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("REQUEST_MEDIA_PROJECTION", true)
        }
        startActivity(intent)
    }
    

    
    private fun setupImageReader() {
        try {
            val displayMetrics = DisplayMetrics()
            windowManager.defaultDisplay.getMetrics(displayMetrics)
            
            Log.d(TAG, "Configuration ImageReader - Width: ${displayMetrics.widthPixels}, Height: ${displayMetrics.heightPixels}")
            
            imageReader = ImageReader.newInstance(
                displayMetrics.widthPixels,
                displayMetrics.heightPixels,
                PixelFormat.RGBA_8888,
                1
            )
            
            imageReader?.setOnImageAvailableListener({ reader ->
                Log.d(TAG, "Image disponible dans ImageReader!")
                
                // Vérifier si l'ImageReader est toujours valide
                if (imageReader == null) {
                    Log.w(TAG, "ImageReader a été nettoyé, ignorer cette image")
                    return@setOnImageAvailableListener
                }
                
                val image = reader.acquireLatestImage()
                if (image != null) {
                    Log.d(TAG, "Image acquise, traitement en cours...")
                    processImage(image)
                    image.close()
                } else {
                    Log.w(TAG, "Image null dans ImageReader")
                }
            }, Handler(Looper.getMainLooper()))
            
            Log.d(TAG, "ImageReader configuré avec succès")
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la configuration ImageReader", e)
            sendEvent("error", null, "Erreur ImageReader: ${e.message}")
        }
    }
    
    private fun setupVirtualDisplay() {
        try {
            val displayMetrics = DisplayMetrics()
            windowManager.defaultDisplay.getMetrics(displayMetrics)
            
            Log.d(TAG, "Configuration VirtualDisplay - Width: ${displayMetrics.widthPixels}, Height: ${displayMetrics.heightPixels}, DPI: ${displayMetrics.densityDpi}")
            Log.d(TAG, "MediaProjection: ${mediaProjection != null}")
            Log.d(TAG, "ImageReader Surface: ${imageReader?.surface != null}")
            
            if (mediaProjection == null) {
                Log.e(TAG, "MediaProjection est null lors de setupVirtualDisplay!")
                sendEvent("error", null, "MediaProjection null")
                return
            }
            
            if (imageReader?.surface == null) {
                Log.e(TAG, "ImageReader surface est null!")
                sendEvent("error", null, "ImageReader surface null")
                return
            }
            
            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "Screenshot",
                displayMetrics.widthPixels,
                displayMetrics.heightPixels,
                displayMetrics.densityDpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface,
                null,
                null
            )
            
            Log.d(TAG, "VirtualDisplay créé: ${virtualDisplay != null}")
            
            if (virtualDisplay == null) {
                Log.e(TAG, "Échec de création du VirtualDisplay!")
                sendEvent("error", null, "Échec création VirtualDisplay")
            } else {
                Log.d(TAG, "VirtualDisplay configuré avec succès")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la configuration VirtualDisplay", e)
            sendEvent("error", null, "Erreur VirtualDisplay: ${e.message}")
        }
    }
    
    private fun captureScreen() {
        Log.d(TAG, "captureScreen() appelée")
        Log.d(TAG, "ImageReader: ${imageReader != null}")
        Log.d(TAG, "VirtualDisplay: ${virtualDisplay != null}")
        Log.d(TAG, "MediaProjection: ${mediaProjection != null}")
        showPendingOverlay();
        if (imageReader == null) {
            Log.e(TAG, "ImageReader est null!")
            sendEvent("error", null, "ImageReader non initialisé")
            return
        }
        
        if (virtualDisplay == null) {
            Log.e(TAG, "VirtualDisplay est null!")
            sendEvent("error", null, "VirtualDisplay non initialisé")
            return
        }
        
        Log.d(TAG, "Capture en cours... Attente de l'ImageReader")
        // La capture se fait automatiquement via l'ImageReader listener
        // setupImageReader() a configuré le callback onImageAvailable
    }
    
    private fun processImage(image: Image) {
        try {
            Log.d(TAG, "processImage() démarré")
            Log.d(TAG, "Image dimensions: ${image.width}x${image.height}")
            Log.d(TAG, "Image format: ${image.format}")
            
            val planes = image.planes
            Log.d(TAG, "Nombre de planes: ${planes.size}")
            
            val buffer = planes[0].buffer
            val pixelStride = planes[0].pixelStride
            val rowStride = planes[0].rowStride
            val rowPadding = rowStride - pixelStride * image.width
            
            Log.d(TAG, "Buffer info - PixelStride: $pixelStride, RowStride: $rowStride, RowPadding: $rowPadding")
            
            val bitmap = Bitmap.createBitmap(
                image.width + rowPadding / pixelStride,
                image.height,
                Bitmap.Config.ARGB_8888
            )
            bitmap.copyPixelsFromBuffer(buffer)
            
            Log.d(TAG, "Bitmap créé: ${bitmap.width}x${bitmap.height}")
            
            // Sauvegarder l'image
            val filename = "screenshot_${System.currentTimeMillis()}.png"
            val file = File(applicationContext.cacheDir, filename)
            
            Log.d(TAG, "Sauvegarde vers: ${file.absolutePath}")
            
            FileOutputStream(file).use { out ->
                val success = bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                Log.d(TAG, "Compression bitmap: $success")
            }
            
            Log.d(TAG, "Fichier créé, taille: ${file.length()} bytes")
            Log.d(TAG, "Capture sauvegardée: ${file.absolutePath}")
            
            // Mettre à jour la notification
            updateNotification("Capture réussie!", "Image traitée et prête à être envoyée")
            
            sendEvent("screenshotProcessed", file.absolutePath, null)
            
            // Afficher une notification popup pour informer l'utilisateur
            showCaptureCompletedNotification()
            
            // Retour automatique après un délai pour laisser le temps de voir la notification
            Handler(Looper.getMainLooper()).postDelayed({
                returnToFlutterApp()
            }, 3000) // 3 secondes pour voir la notification
            
            // IMPORTANT: Arrêter la capture après la première image
            // Nettoyer les ressources pour éviter les captures continues
            // Délai plus long pour s'assurer que toutes les images sont traitées
            Handler(Looper.getMainLooper()).postDelayed({
                cleanupCapture()
            }, 1000) // 1 seconde au lieu de 100ms
            
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors du traitement de l'image", e)
            sendEvent("error", null, "Erreur processImage: ${e.message}")
        }
    }
    
    private fun returnToFlutterApp() {
        try {
            Log.d(TAG, "Retour automatique vers l'application Flutter")
            
            val packageName = applicationContext.packageName
            val intent = applicationContext.packageManager.getLaunchIntentForPackage(packageName)
            
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                applicationContext.startActivity(intent)
                Log.d(TAG, "Application Flutter relancée avec succès")
            } else {
                Log.w(TAG, "Impossible de trouver l'intent de lancement pour l'application")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors du retour à l'application", e)
        }
    }
    
    private fun cleanupCapture() {
        Log.d(TAG, "Nettoyage des ressources de capture")
        try {
            // Nettoyer le VirtualDisplay en premier
            virtualDisplay?.let { display ->
                Log.d(TAG, "Libération du VirtualDisplay")
                display.release()
                virtualDisplay = null
            }
            
            // Ensuite nettoyer l'ImageReader
            imageReader?.let { reader ->
                Log.d(TAG, "Fermeture de l'ImageReader")
                reader.close()
                imageReader = null
            }
            
            Log.d(TAG, "Ressources de capture nettoyées avec succès")
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors du nettoyage", e)
            // Forcer le nettoyage même en cas d'erreur
            virtualDisplay = null
            imageReader = null
        }
    }
    
    private fun stopService() {
        try {
            floatingView?.let {
                windowManager.removeView(it)
                floatingView = null
            }
            
            virtualDisplay?.release()
            imageReader?.close()
            mediaProjection?.stop()
            
            virtualDisplay = null
            imageReader = null
            mediaProjection = null
            
            // Nettoyer le singleton aussi
            com.example.mobile.MediaProjectionManager.clearMediaProjection()
            
            stopForeground(true)
            isServiceRunning = false
            
            sendEvent("serviceStopped", null, null)
            Log.d(TAG, "Service arrêté")
            
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de l'arrêt du service", e)
        }
    }
    
    private fun sendEvent(event: String, imagePath: String?, errorMessage: String?) {
        eventSink?.success(mapOf(
            "event" to event,
            "imagePath" to imagePath,
            "errorMessage" to errorMessage,
            "timestamp" to System.currentTimeMillis()
        ))
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopService()
        Log.d(TAG, "Service détruit")
    }
}

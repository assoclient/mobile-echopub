package com.example.mobile

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.echopub.mobile/screenshot"
        private const val EVENT_CHANNEL = "com.echopub.mobile/screenshot_events"
        private const val REQUEST_CODE_SCREENSHOT = 1000
        private const val REQUEST_CODE_OVERLAY = 1001
        private const val TAG = "MainActivity"
    }
    
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var screenshotService: ScreenshotService? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    result.success(true)
                }
                
                "startFloatingButton" -> {
                    startFloatingButton(result)
                }
                
                "stopService" -> {
                    stopScreenshotService(result)
                }
                
                "hasOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(null)
                }
                
                "takeScreenshot" -> {
                    requestMediaProjectionPermission()
                    result.success(null)
                }
                
                "processScreenshot" -> {
                    val imagePath = call.argument<String>("imagePath")
                    if (imagePath != null) {
                        // Traitement basique de l'image
                        result.success(mapOf("processedPath" to imagePath))
                    } else {
                        result.error("INVALID_ARGS", "Chemin d'image manquant", null)
                    }
                }
                
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(null)
                }
                
                "returnToApp" -> {
                    returnToApp()
                    result.success(null)
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Configurer l'EventChannel
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                ScreenshotService.eventSink = events
            }
            
            override fun onCancel(arguments: Any?) {
                ScreenshotService.eventSink = null
            }
        })
    }
    
    private fun startFloatingButton(result: MethodChannel.Result) {
        if (!hasOverlayPermission()) {
            result.error("PERMISSION_DENIED", "Permission overlay requise", null)
            return
        }
        
        val intent = Intent(this, ScreenshotService::class.java).apply {
            action = "START_FLOATING_BUTTON"
        }
        startService(intent)
        result.success(true)
    }
    
    private fun stopScreenshotService(result: MethodChannel.Result) {
        val intent = Intent(this, ScreenshotService::class.java).apply {
            action = "STOP_SERVICE"
        }
        startService(intent)
        result.success(true)
    }
    
    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }
    
    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivityForResult(intent, REQUEST_CODE_OVERLAY)
        }
    }
    
    private fun requestMediaProjectionPermission() {
        val mediaProjectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val intent = mediaProjectionManager.createScreenCaptureIntent()
        startActivityForResult(intent, REQUEST_CODE_SCREENSHOT)
    }
    
    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
        }
        startActivity(intent)
    }
    
    private fun returnToApp() {
        // Ramener l'activité au premier plan
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        startActivity(intent)
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        when (requestCode) {
            REQUEST_CODE_SCREENSHOT -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    val mediaProjectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as android.media.projection.MediaProjectionManager
                    val mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)
                    
                    // Stocker la MediaProjection dans le singleton
                    com.example.mobile.MediaProjectionManager.setMediaProjection(mediaProjection)
                    
                    Log.d(TAG, "MediaProjection obtenue et stockée")
                    
                    // Notifier le service que la MediaProjection est disponible
                    val intent = Intent(this, ScreenshotService::class.java).apply {
                        action = "MEDIA_PROJECTION_READY"
                    }
                    startService(intent)
                    
                } else {
                    Log.e(TAG, "Permission MediaProjection refusée")
                    ScreenshotService.eventSink?.success(mapOf(
                        "event" to "permissionDenied",
                        "errorMessage" to "Permission de capture d'écran refusée"
                    ))
                }
            }
            
            REQUEST_CODE_OVERLAY -> {
                if (hasOverlayPermission()) {
                    Log.d(TAG, "Permission overlay accordée")
                    ScreenshotService.eventSink?.success(mapOf(
                        "event" to "permissionGranted"
                    ))
                } else {
                    Log.e(TAG, "Permission overlay refusée")
                    ScreenshotService.eventSink?.success(mapOf(
                        "event" to "permissionDenied",
                        "errorMessage" to "Permission overlay refusée"
                    ))
                }
            }
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        // Gérer les demandes spéciales du service
        if (intent.getBooleanExtra("REQUEST_MEDIA_PROJECTION", false)) {
            requestMediaProjectionPermission()
        }
    }
}

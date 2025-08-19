package com.echopub.communications

import android.media.projection.MediaProjection

object MediaProjectionManager {
    private var mediaProjection: MediaProjection? = null
    
    fun setMediaProjection(projection: MediaProjection?) {
        mediaProjection = projection
    }
    
    fun getMediaProjection(): MediaProjection? {
        return mediaProjection
    }
    
    fun clearMediaProjection() {
        mediaProjection?.stop()
        mediaProjection = null
    }
    
    fun hasMediaProjection(): Boolean {
        return mediaProjection != null
    }
}

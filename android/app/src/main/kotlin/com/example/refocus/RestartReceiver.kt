package com.example.refocus

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class RestartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean("flutter.protection_enabled", false)
        Log.d("RestartReceiver", "onReceive triggered, protection_enabled=$isEnabled")
        if (isEnabled) {
            RefocusForegroundService.startService(context)
        }
    }
}

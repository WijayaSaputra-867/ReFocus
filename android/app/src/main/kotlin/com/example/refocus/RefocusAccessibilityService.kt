package com.example.refocus

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.ContextThemeWrapper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class RefocusAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "RefocusAccessSvc"
        var instance: RefocusAccessibilityService? = null
            private set

        @Volatile
        var currentForegroundPackage: String? = null

        private val IGNORED_TRANSIENT_PACKAGES = setOf(
            "com.example.refocus",
            "com.android.systemui",
            "com.google.android.inputmethod.latin",
            "com.touchtype.swiftkey",
            "com.samsung.android.honeyboard",
            "com.android.permissioncontroller",
            "com.google.android.permissioncontroller"
        )
    }

    private var activeOverlayView: View? = null
    private var overlayDismissRunnable: Runnable? = null
    private var lastBlockerShownAt = 0L
    private val handler = Handler(Looper.getMainLooper())
    private val wm by lazy { getSystemService(Context.WINDOW_SERVICE) as WindowManager }

    private val heartbeatRunnable = object : Runnable {
        override fun run() {
            try {
                val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val enabled = prefs.getBoolean("flutter.protection_enabled", false)
                if (enabled && RefocusForegroundService.instance == null) {
                    RefocusForegroundService.startService(this@RefocusAccessibilityService)
                    RefocusForegroundService.scheduleRestart(this@RefocusAccessibilityService)
                }
            } catch (e: Exception) {
                Log.w(TAG, "heartbeat error: ${e.message}")
            }
            handler.postDelayed(this, 1000)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "RefocusAccessibilityService connected")
        handler.removeCallbacks(heartbeatRunnable)
        handler.post(heartbeatRunnable)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (IGNORED_TRANSIENT_PACKAGES.any { pkg.startsWith(it) }) return

        currentForegroundPackage = pkg

        val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean("flutter.protection_enabled", false)

        if (enabled && RefocusForegroundService.isProtectedApp(applicationContext, pkg)) {
            val now = System.currentTimeMillis()
            val cooldownUntil = getSafeLong(prefs, "flutter.cooldown_until_epoch_ms")
            val status = prefs.getString("flutter.protection_status", "idle") ?: "idle"
            val cooldownRemaining = getSafeInt(prefs, "flutter.cooldown_remaining", 0)
            val sessions = getSafeInt(prefs, "flutter.sessions_today", 0)
            val limit = getSafeInt(prefs, "flutter.daily_session_limit", 5)

            val isCooldownActive = if (cooldownUntil > 0L) (cooldownUntil > now) else (status == "cooldown" && cooldownRemaining > 0)
            val isDailyLock = status == "daily_locked" || status == "dailyLocked" || sessions >= limit

            if (isCooldownActive || isDailyLock) {
                // Instant kick to home and show overlay blocker immediately (even when swiped away)
                performGlobalAction(GLOBAL_ACTION_HOME)
                val rem = if (cooldownUntil > now) ((cooldownUntil - now) / 1000).toInt() else cooldownRemaining
                showBlockerOverlay(isDailyLock = isDailyLock, cooldownRemaining = rem)
                return
            }
        }

        RefocusForegroundService.onForegroundPackageChanged(this, pkg)
    }

    private fun getSafeLong(prefs: SharedPreferences, key: String): Long {
        return try {
            prefs.getLong(key, 0L)
        } catch (_: Exception) {
            try {
                prefs.getInt(key, 0).toLong()
            } catch (_: Exception) {
                0L
            }
        }
    }

    private fun getSafeInt(prefs: SharedPreferences, key: String, defValue: Int = 0): Int {
        return try {
            prefs.getInt(key, defValue)
        } catch (_: Exception) {
            try {
                prefs.getLong(key, defValue.toLong()).toInt()
            } catch (_: Exception) {
                defValue
            }
        }
    }

    private fun showBlockerOverlay(isDailyLock: Boolean, cooldownRemaining: Int) {
        val now = System.currentTimeMillis()
        if (now - lastBlockerShownAt < 2_000) return
        lastBlockerShownAt = now

        handler.post {
            dismissOverlay()
            val ctx = ContextThemeWrapper(this, android.R.style.Theme_DeviceDefault_NoActionBar)
            val density = resources.displayMetrics.density
            val lp = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                PixelFormat.TRANSLUCENT
            ).apply { gravity = Gravity.CENTER }

            val pad = (24 * density).toInt()
            val root = LinearLayout(ctx).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                setBackgroundColor(Color.parseColor("#E60F1117"))
                setPadding(pad, pad, pad, pad)
                setOnTouchListener { _, _ -> true }
            }

            val cardBg = GradientDrawable().apply {
                setColor(Color.parseColor("#1A1D27"))
                cornerRadius = 20 * density
                setStroke((1.5 * density).toInt(), Color.parseColor("#2A2E3A"))
            }
            val card = LinearLayout(ctx).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                background = cardBg
                setPadding((28 * density).toInt(), (32 * density).toInt(), (28 * density).toInt(), (32 * density).toInt())
            }

            val title = if (isDailyLock) "Batas Harian Tercapai" else "Waktunya Istirahat"
            val message = if (isDailyLock) {
                "Jatah sesi harian Anda sudah habis. Kembali lagi besok."
            } else {
                val mm = String.format("%02d", cooldownRemaining / 60)
                val ss = String.format("%02d", cooldownRemaining % 60)
                "Aplikasi sedang dalam masa jeda (cooldown). Waktu istirahat tersisa: $mm:$ss."
            }

            val titleView = TextView(ctx).apply {
                text = title
                setTextColor(Color.parseColor("#F0F6FC"))
                textSize = 20f
                gravity = Gravity.CENTER
                setTypeface(null, Typeface.BOLD)
            }
            val msgView = TextView(ctx).apply {
                text = message
                setTextColor(Color.parseColor("#8B949E"))
                textSize = 14f
                gravity = Gravity.CENTER
                setPadding(0, (14 * density).toInt(), 0, (20 * density).toInt())
            }
            val countView = TextView(ctx).apply {
                text = "Menutup dalam 5 detik..."
                setTextColor(Color.parseColor("#58A6FF"))
                textSize = 15f
                gravity = Gravity.CENTER
                setTypeface(null, Typeface.BOLD)
                setPadding(0, 0, 0, (24 * density).toInt())
            }
            val exitBtn = Button(ctx).apply {
                text = "Keluar Sekarang"
                setTextColor(Color.parseColor("#F0F6FC"))
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#2A2E3A"))
                    cornerRadius = 12 * density
                }
                isAllCaps = false
                setOnClickListener {
                    dismissOverlay()
                    performGlobalAction(GLOBAL_ACTION_HOME)
                }
            }

            card.addView(titleView)
            card.addView(msgView)
            card.addView(countView)
            card.addView(exitBtn)
            root.addView(card)

            try {
                wm.addView(root, lp)
                activeOverlayView = root

                var remaining = 5
                val dismiss = object : Runnable {
                    override fun run() {
                        remaining--
                        if (remaining > 0) {
                            countView.text = "Menutup dalam $remaining detik..."
                            handler.postDelayed(this, 1000)
                        } else {
                            dismissOverlay()
                            performGlobalAction(GLOBAL_ACTION_HOME)
                        }
                    }
                }
                overlayDismissRunnable = dismiss
                handler.postDelayed(dismiss, 1000)
            } catch (e: Exception) {
                Log.e(TAG, "showBlockerOverlay failed: ${e.message}")
                dismissOverlay()
                performGlobalAction(GLOBAL_ACTION_HOME)
            }
        }
    }

    private fun dismissOverlay() {
        overlayDismissRunnable?.let { handler.removeCallbacks(it) }
        overlayDismissRunnable = null
        activeOverlayView?.let {
            try {
                if (it.isAttachedToWindow) wm.removeView(it)
            } catch (e: Exception) {
                Log.w(TAG, "dismissOverlay error: ${e.message}")
            }
            activeOverlayView = null
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "RefocusAccessibilityService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(heartbeatRunnable)
        dismissOverlay()
        if (instance == this) instance = null
        currentForegroundPackage = null
    }
}

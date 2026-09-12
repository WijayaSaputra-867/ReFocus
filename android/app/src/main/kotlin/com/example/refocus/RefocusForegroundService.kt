package com.example.refocus

import android.app.AlarmManager
import android.app.AppOpsManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import android.util.Log
import android.view.ContextThemeWrapper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class RefocusForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "refocus_protection_channel"
        const val NOTIFICATION_ID = 1001
        private const val TAG = "RefocusSvc"

        // SharedPreferences keys — must match protection_notifier.dart
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val K_ENABLED = "flutter.protection_enabled"
        private const val K_APPS = "flutter.protected_apps"
        private const val K_STATUS = "flutter.protection_status"
        private const val K_TRIGGER = "flutter.trigger_seconds"
        private const val K_COOLDOWN_REMAINING = "flutter.cooldown_remaining"
        private const val K_COOLDOWN_UNTIL = "flutter.cooldown_until_epoch_ms"
        private const val K_COOLDOWN = "flutter.cooldown_seconds"

        fun getSafeLong(prefs: SharedPreferences, key: String): Long {
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

        fun getSafeInt(prefs: SharedPreferences, key: String, defValue: Int = 0): Int {
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
        private const val K_SESSIONS = "flutter.sessions_today"
        private const val K_LIMIT = "flutter.daily_session_limit"
        private const val K_ELAPSED = "flutter.elapsed_seconds"
        private const val K_DATE = "flutter.sessions_date"
        private const val K_TOTAL_DISTRACTION = "flutter.total_distraction_seconds"
        private const val K_RESISTED = "flutter.resisted_today"

        private val IGNORED_LAUNCHERS = listOf(
            "com.example.refocus",
            "com.android.launcher",
            "com.google.android.launcher",
            "com.google.android.apps.nexuslauncher",
            "com.android.launcher3",
            "com.teslacoilsw.launcher",
            "com.miui.home",
            "com.sec.android.app.launcher",
            "com.huawei.android.launcher",
            "com.oneplus.launcher",
            "com.coloros.launcher",
            "com.oppo.launcher",
            "com.vivo.launcher",
            "com.android.systemui"
        )

        private val KNOWN_APP_ALIASES = mapOf(
            "tiktok" to listOf(
                "com.zhiliaoapp.musically",
                "com.ss.android.ugc.trill",
                "com.zhiliaoapp.musically.go",
                "com.ss.android.ugc.aweme",
                "tiktok"
            ),
            "instagram" to listOf(
                "com.instagram.android",
                "instagram"
            ),
            "youtube" to listOf(
                "com.google.android.youtube",
                "youtube"
            ),
            "mobile legends" to listOf(
                "com.mobile.legends",
                "mobile legends",
                "mobilelegends"
            ),
            "facebook" to listOf(
                "com.facebook.katana",
                "com.facebook.lite",
                "facebook"
            ),
            "twitter" to listOf(
                "com.twitter.android",
                "twitter",
                "x"
            )
        )

        private val DEFAULT_PROTECTED_PACKAGES = setOf(
            "com.zhiliaoapp.musically",
            "com.ss.android.ugc.trill",
            "com.ss.android.ugc.aweme",
            "com.instagram.android",
            "com.google.android.youtube",
            "com.mobile.legends",
            "com.facebook.katana",
            "com.facebook.lite",
            "com.twitter.android"
        )

        fun startService(context: Context, initialPackage: String? = null) {
            try {
                val intent = Intent(context, RefocusForegroundService::class.java).apply {
                    if (initialPackage != null) {
                        putExtra("extra_pkg", initialPackage)
                    }
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "startService failed: ${e.message}")
            }
        }

        fun scheduleRestart(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val enabled = prefs.getBoolean(K_ENABLED, false)
            if (!enabled) return

            try {
                val intent = Intent(context, RestartReceiver::class.java).apply {
                    action = "com.example.refocus.RESTART_SERVICE"
                }
                val pi = PendingIntent.getBroadcast(
                    context,
                    1003,
                    intent,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                    else
                        PendingIntent.FLAG_UPDATE_CURRENT
                )
                val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
                val triggerAt = System.currentTimeMillis() + 1000L
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    try {
                        am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                    } catch (_: Exception) {
                        am.set(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                    }
                } else {
                    am.set(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                }
                Log.d(TAG, "Scheduled service restart in 1s via AlarmManager")
            } catch (e: Exception) {
                Log.w(TAG, "scheduleRestart error: ${e.message}")
            }
        }

        fun cancelScheduledRestart(context: Context) {
            try {
                val intent = Intent(context, RestartReceiver::class.java).apply {
                    action = "com.example.refocus.RESTART_SERVICE"
                }
                val pi = PendingIntent.getBroadcast(
                    context,
                    1003,
                    intent,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_NO_CREATE
                    else
                        PendingIntent.FLAG_NO_CREATE
                )
                if (pi != null) {
                    val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                    am?.cancel(pi)
                    pi.cancel()
                }
            } catch (_: Exception) {}
        }

        fun stopService(context: Context) {
            cancelScheduledRestart(context)
            try {
                context.stopService(Intent(context, RefocusForegroundService::class.java))
            } catch (e: Exception) {
                Log.e(TAG, "stopService failed: ${e.message}")
            }
        }

        var instance: RefocusForegroundService? = null
            private set

        fun getProtectedAppList(context: Context): Set<String> {
            val result = mutableSetOf<String>()
            result.addAll(DEFAULT_PROTECTED_PACKAGES)
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            try {
                val raw = prefs.getString(K_APPS, null)
                if (raw != null) {
                    val clean = if (raw.startsWith("VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu")) {
                        raw.substring("VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu".length)
                    } else {
                        raw
                    }
                    val json = org.json.JSONArray(clean)
                    for (i in 0 until json.length()) {
                        val entry = json.getString(i).trim().lowercase()
                        result.add(entry)
                        for ((alias, pkgs) in KNOWN_APP_ALIASES) {
                            if (entry == alias || entry.contains(alias) || alias.contains(entry)) {
                                result.addAll(pkgs)
                            }
                        }
                    }
                }
            } catch (_: Exception) {}

            try {
                val set = prefs.getStringSet(K_APPS, null)
                if (set != null) {
                    for (item in set) {
                        val entry = item.trim().lowercase()
                        result.add(entry)
                        for ((alias, pkgs) in KNOWN_APP_ALIASES) {
                            if (entry == alias || entry.contains(alias) || alias.contains(entry)) {
                                result.addAll(pkgs)
                            }
                        }
                    }
                }
            } catch (_: Exception) {}

            return result
        }

        fun isProtectedApp(context: Context, pkg: String): Boolean {
            if (pkg.isBlank()) return false
            val lower = pkg.lowercase().trim()
            if (IGNORED_LAUNCHERS.any { lower.startsWith(it) }) return false

            val protectedList = getProtectedAppList(context)
            if (protectedList.contains(lower)) return true

            return protectedList.any { s ->
                s.length >= 4 && (lower.contains(s) || s.contains(lower))
            }
        }

        fun onForegroundPackageChanged(context: Context, pkg: String) {
            val svc = instance
            if (svc != null) {
                svc.handleForegroundAppChange(pkg)
            } else {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val enabled = prefs.getBoolean(K_ENABLED, false)
                if (enabled && isProtectedApp(context, pkg)) {
                    val status = prefs.getString(K_STATUS, "idle") ?: "idle"
                    val sessions = getSafeInt(prefs, K_SESSIONS, 0)
                    val limit = getSafeInt(prefs, K_LIMIT, 5)
                    if (status == "cooldown" || status == "daily_locked" || status == "dailyLocked" || sessions >= limit) {
                        RefocusAccessibilityService.instance?.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_HOME)
                    }
                }
                startService(context, pkg)
            }
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var pollRunnable: Runnable? = null
    private var lastBlockerShownAt = 0L

    // Overlay state
    private var overlayView: View? = null
    private var overlayDismissRunnable: Runnable? = null
    private val wm by lazy { applicationContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager }

    private val prefs: SharedPreferences by lazy {
        applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private var currentActivePackage: String? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        startInForeground()
        startPolling()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startInForeground()
        val pkg = intent?.getStringExtra("extra_pkg")
        if (!pkg.isNullOrBlank()) {
            handleForegroundAppChange(pkg)
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        if (instance == this) instance = null
        stopPolling()
        dismissOverlay()
        try {
            val enabled = prefs.getBoolean(K_ENABLED, false)
            if (enabled) {
                scheduleRestart(applicationContext)
            }
        } catch (e: Exception) {
            Log.w(TAG, "onDestroy handling: ${e.message}")
        }
    }

    fun handleForegroundAppChange(pkg: String) {
        val enabled = prefs.getBoolean(K_ENABLED, false)
        if (!enabled) return
        if (IGNORED_LAUNCHERS.any { pkg.startsWith(it) }) {
            currentActivePackage = null
            return
        }

        val isProtected = isProtectedApp(pkg)
        if (!isProtected) {
            val status = prefs.getString(K_STATUS, "idle") ?: "idle"
            if (status == "distracting") {
                prefs.edit().putString(K_STATUS, "idle").apply()
                val appName = currentActivePackage?.let { getAppDisplayName(it) } ?: "Aplikasi"
                val elapsed = getSafeInt(prefs, K_ELAPSED, 0)
                val triggerSec = getSafeInt(prefs, K_TRIGGER, 300)
                if (elapsed > 0) {
                    updateForegroundNotification(
                        "Refocus • $appName",
                        "Sesi dijeda: ${formatSeconds(elapsed)} / ${formatSeconds(triggerSec)}"
                    )
                } else {
                    updateForegroundNotification("Refocus", "Proteksi aktif di latar belakang")
                }
            }
            currentActivePackage = pkg
            return
        }

        currentActivePackage = pkg
        val status = prefs.getString(K_STATUS, "idle") ?: "idle"
        val sessions = getSafeInt(prefs, K_SESSIONS, 0)
        val limit = getSafeInt(prefs, K_LIMIT, 5)

        when {
            status == "daily_locked" || status == "dailyLocked" || sessions >= limit -> {
                triggerBlocker(isDailyLock = true)
            }
            status == "cooldown" -> {
                triggerBlocker(isDailyLock = false)
            }
            status == "distracting" -> {
                // already tracking in polling tick
            }
            else -> {
                val elapsed = getSafeInt(prefs, K_ELAPSED, 0)
                val triggerSec = getSafeInt(prefs, K_TRIGGER, 300)
                val appName = getAppDisplayName(pkg)
                prefs.edit().putString(K_STATUS, "distracting").apply()
                updateForegroundNotification(
                    "Refocus • $appName",
                    "Sesi berjalan: ${formatSeconds(elapsed)} / ${formatSeconds(triggerSec)}"
                )
            }
        }
    }

    // ── Polling ───────────────────────────────────────────────────────────────

    private fun startPolling() {
        stopPolling()
        val r = object : Runnable {
            override fun run() {
                try { tick() } catch (e: Exception) { Log.w(TAG, "tick error: ${e.message}") }
                handler.postDelayed(this, 1000)
            }
        }
        pollRunnable = r
        handler.postDelayed(r, 1000)
    }

    private fun stopPolling() {
        pollRunnable?.let { handler.removeCallbacks(it) }
        pollRunnable = null
    }

    private fun tick() {
        // Default protection is OFF
        val enabled = prefs.getBoolean(K_ENABLED, false)
        if (!enabled) return

        val today = todayKey()
        val savedDate = prefs.getString(K_DATE, today) ?: today
        if (savedDate != today) {
            // Day rolled over — reset
            prefs.edit()
                .putString(K_DATE, today)
                .putInt(K_SESSIONS, 0)
                .putInt(K_ELAPSED, 0)
                .putInt(K_COOLDOWN_REMAINING, 0)
                .putString(K_STATUS, "idle")
                .putInt(K_TOTAL_DISTRACTION, 0)
                .putInt(K_RESISTED, 0)
                .apply()
            return
        }

        val status = prefs.getString(K_STATUS, "idle") ?: "idle"
        val sessions = getSafeInt(prefs, K_SESSIONS, 0)
        val limit = getSafeInt(prefs, K_LIMIT, 5)
        val triggerSec = getSafeInt(prefs, K_TRIGGER, 300)
        val elapsed = getSafeInt(prefs, K_ELAPSED, 0)
        val cooldownRemaining = getSafeInt(prefs, K_COOLDOWN_REMAINING, 0)
        val cooldownSec = getSafeInt(prefs, K_COOLDOWN, 900)
        val cooldownUntil = getSafeLong(prefs, K_COOLDOWN_UNTIL)
        val now = System.currentTimeMillis()

        // 1. Tick cooldown down using real wall-clock time
        if (status == "cooldown") {
            val currentCooldown = if (cooldownUntil > 0L) {
                ((cooldownUntil - now) / 1000).toInt()
            } else {
                val rem = getSafeInt(prefs, K_COOLDOWN_REMAINING, 0)
                if (rem > 0) {
                    val until = now + rem * 1000L
                    prefs.edit().putLong(K_COOLDOWN_UNTIL, until).apply()
                    rem
                } else {
                    0
                }
            }

            if (currentCooldown <= 0) {
                // Cooldown completed: increment daily sessions used by 1!
                val nextSessions = (sessions + 1).coerceAtMost(limit)
                val isMax = nextSessions >= limit
                prefs.edit()
                    .putString(K_STATUS, if (isMax) "daily_locked" else "idle")
                    .putInt(K_SESSIONS, nextSessions)
                    .putInt(K_COOLDOWN_REMAINING, 0)
                    .putLong(K_COOLDOWN_UNTIL, 0L)
                    .putInt(K_ELAPSED, 0)
                    .putInt(K_RESISTED, getSafeInt(prefs, K_RESISTED, 0) + 1)
                    .apply()
                updateForegroundNotification(
                    "Refocus",
                    if (isMax) "Batas harian tercapai ($nextSessions/$limit)"
                    else "Proteksi aktif di latar belakang (Sesi $nextSessions/$limit selesai)"
                )
            } else {
                prefs.edit().putInt(K_COOLDOWN_REMAINING, currentCooldown).apply()
                updateForegroundNotification("Refocus • Jeda Istirahat", "Cooldown tersisa: ${formatSeconds(currentCooldown)}")
            }
        }

        val foreground = getForegroundApp()
        val isProtected = foreground != null && isProtectedApp(foreground)

        if (isProtected) {
            currentActivePackage = foreground
            val appName = getAppDisplayName(foreground)

            when {
                status == "daily_locked" || status == "dailyLocked" || sessions >= limit -> {
                    triggerBlocker(isDailyLock = true)
                }
                status == "cooldown" -> {
                    triggerBlocker(isDailyLock = false)
                }
                status == "distracting" -> {
                    val nextElapsed = elapsed + 1
                    val nextTotal = getSafeInt(prefs, K_TOTAL_DISTRACTION, 0) + 1
                    if (nextElapsed >= triggerSec) {
                        // Distraction time is up! Enter cooldown and cover app with overlay blocker!
                        val until = System.currentTimeMillis() + cooldownSec * 1000L
                        prefs.edit()
                            .putString(K_STATUS, "cooldown")
                            .putInt(K_ELAPSED, 0)
                            .putInt(K_COOLDOWN_REMAINING, cooldownSec)
                            .putLong(K_COOLDOWN_UNTIL, until)
                            .putInt(K_TOTAL_DISTRACTION, nextTotal)
                            .apply()
                        triggerBlocker(isDailyLock = false)
                    } else {
                        prefs.edit()
                            .putInt(K_ELAPSED, nextElapsed)
                            .putInt(K_TOTAL_DISTRACTION, nextTotal)
                            .apply()
                        updateForegroundNotification(
                            "Refocus • $appName",
                            "Sesi berjalan: ${formatSeconds(nextElapsed)} / ${formatSeconds(triggerSec)}"
                        )
                    }
                }
                else -> {
                    // Was idle / paused -> resume or start distraction session from saved elapsed time!
                    val nextElapsed = elapsed + 1
                    val nextTotal = getSafeInt(prefs, K_TOTAL_DISTRACTION, 0) + 1
                    if (nextElapsed >= triggerSec) {
                        val until = System.currentTimeMillis() + cooldownSec * 1000L
                        prefs.edit()
                            .putString(K_STATUS, "cooldown")
                            .putInt(K_ELAPSED, 0)
                            .putInt(K_COOLDOWN_REMAINING, cooldownSec)
                            .putLong(K_COOLDOWN_UNTIL, until)
                            .putInt(K_TOTAL_DISTRACTION, nextTotal)
                            .apply()
                        triggerBlocker(isDailyLock = false)
                    } else {
                        prefs.edit()
                            .putString(K_STATUS, "distracting")
                            .putInt(K_ELAPSED, nextElapsed)
                            .putInt(K_TOTAL_DISTRACTION, nextTotal)
                            .apply()
                        updateForegroundNotification(
                            "Refocus • $appName",
                            "Sesi berjalan: ${formatSeconds(nextElapsed)} / ${formatSeconds(triggerSec)}"
                        )
                    }
                }
            }
        } else {
            // If the foreground app cannot be detected for a moment (for example, while the
            // Refocus app itself is swiped away from recents), do not immediately clear the
            // active distraction state. Keep tracking until we confirm the user actually left the
            // protected app.
            if (status == "distracting") {
                val activePkg = currentActivePackage
                val stillProtected = activePkg != null && isProtectedApp(activePkg)
                if (!stillProtected) {
                    prefs.edit()
                        .putString(K_STATUS, "idle")
                        .apply()
                    val appName = currentActivePackage?.let { getAppDisplayName(it) } ?: "Aplikasi"
                    if (elapsed > 0) {
                        updateForegroundNotification(
                            "Refocus • $appName",
                            "Sesi dijeda: ${formatSeconds(elapsed)} / ${formatSeconds(triggerSec)}"
                        )
                    } else {
                        updateForegroundNotification("Refocus", "Proteksi aktif di latar belakang")
                    }
                }
            }
        }
    }

    // ── Overlay & Notification Blocker ────────────────────────────────────────

    fun isOverlayVisible(): Boolean = overlayView != null

    private fun triggerBlocker(isDailyLock: Boolean) {
        if (overlayView != null || RefocusAccessibilityService.instance?.isOverlayVisible() == true) {
            return
        }
        val now = System.currentTimeMillis()
        if (now - lastBlockerShownAt < 6_000L) {
            kickToHome()
            return
        }
        lastBlockerShownAt = now

        val status = prefs.getString(K_STATUS, "idle") ?: "idle"
        val cooldownUntil = getSafeLong(prefs, K_COOLDOWN_UNTIL)
        val cooldownRemaining = if (cooldownUntil > now) ((cooldownUntil - now) / 1000).toInt() else getSafeInt(prefs, K_COOLDOWN_REMAINING, 0)

        val title = if (isDailyLock) "Batas Harian Tercapai" else "Waktunya Istirahat"
        val message = if (isDailyLock) {
            "Jatah sesi harian Anda sudah habis. Kembali lagi besok."
        } else if (status == "cooldown" && cooldownRemaining > 0) {
            "Aplikasi sedang dalam masa jeda (cooldown). Waktu istirahat tersisa: ${formatSeconds(cooldownRemaining)}."
        } else {
            "Waktu buka aplikasi sudah habis. Tarik napas sejenak."
        }

        sendBlockerNotification(title, message)
        showOverlay(title, message, seconds = 5)
    }

    private fun showOverlay(title: String, message: String, seconds: Int) {
        if (overlayView != null) return
        if (!canDrawOverlays()) {
            Log.w(TAG, "Cannot draw overlay: SYSTEM_ALERT_WINDOW not granted, kicking to home")
            kickToHome()
            return
        }

        handler.post {
            if (overlayView != null) return@post
            dismissOverlay() // safety clean

            val ctx = ContextThemeWrapper(applicationContext, android.R.style.Theme_DeviceDefault_NoActionBar)
            val density = resources.displayMetrics.density

            val lp = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else
                    @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE,
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
                text = "Menutup dalam $seconds detik..."
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
                setOnClickListener { dismissOverlay(); kickToHome() }
            }

            card.addView(titleView)
            card.addView(msgView)
            card.addView(countView)
            card.addView(exitBtn)
            root.addView(card)

            try {
                wm.addView(root, lp)
                overlayView = root

                var remaining = seconds
                val dismiss = object : Runnable {
                    override fun run() {
                        remaining--
                        if (remaining > 0) {
                            countView.text = "Menutup dalam $remaining detik..."
                            handler.postDelayed(this, 1000)
                        } else {
                            dismissOverlay()
                            kickToHome()
                        }
                    }
                }
                overlayDismissRunnable = dismiss
                handler.postDelayed(dismiss, 1000)
            } catch (e: Exception) {
                Log.e(TAG, "addView failed: ${e.message}", e)
                dismissOverlay()
                kickToHome()
            }
        }
    }

    private fun dismissOverlay() {
        overlayDismissRunnable?.let { handler.removeCallbacks(it) }
        overlayDismissRunnable = null
        overlayView?.let {
            try { if (it.isAttachedToWindow) wm.removeView(it) }
            catch (e: Exception) { Log.w(TAG, "removeView: ${e.message}") }
        }
        overlayView = null
    }

    private fun kickToHome() {
        try {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "kickToHome failed: ${e.message}")
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun getForegroundApp(): String? {
        val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
        if (pm?.isInteractive == false) {
            return null
        }

        val accessPkg = RefocusAccessibilityService.currentForegroundPackage
        if (accessPkg != null) {
            if (IGNORED_LAUNCHERS.any { accessPkg.startsWith(it) }) return null
            return accessPkg
        }

        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return null
        if (!hasUsagePermission()) return null

        val now = System.currentTimeMillis()
        var latestPkg: String? = null

        // Query last 30 seconds of events
        try {
            val events = usm.queryEvents(now - 30_000L, now)
            val event = UsageEvents.Event()
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                when (event.eventType) {
                    UsageEvents.Event.ACTIVITY_RESUMED -> {
                        latestPkg = event.packageName
                    }
                    UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                        latestPkg = null
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "queryEvents error: ${e.message}")
        }

        // Fallback to queryUsageStats if no recent resumed event in window
        if (latestPkg == null) {
            try {
                val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 60_000L, now)
                val top = stats?.maxByOrNull { it.lastTimeUsed }?.packageName
                if (top != null) {
                    latestPkg = top
                }
            } catch (_: Exception) {}
        }

        if (latestPkg != null && IGNORED_LAUNCHERS.any { latestPkg.startsWith(it) }) {
            return null
        }
        return latestPkg
    }

    private fun getProtectedAppList(): Set<String> = getProtectedAppList(applicationContext)

    private fun isProtectedApp(pkg: String): Boolean = isProtectedApp(applicationContext, pkg)

    private fun getAppDisplayName(pkg: String): String {
        val lower = pkg.lowercase().trim()
        for ((alias, pkgs) in KNOWN_APP_ALIASES) {
            if (pkgs.any { lower == it || lower.contains(it) }) {
                return alias.replaceFirstChar { it.uppercase() }
            }
        }
        return try {
            val pm = packageManager
            val info = pm.getApplicationInfo(pkg, 0)
            pm.getApplicationLabel(info).toString()
        } catch (_: Exception) {
            "Aplikasi Distraksi"
        }
    }

    private fun formatSeconds(sec: Int): String {
        val m = sec / 60
        val s = sec % 60
        return String.format("%02d:%02d", m, s)
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun canDrawOverlays() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
        Settings.canDrawOverlays(this) else true

    private fun todayKey(): String {
        val c = java.util.Calendar.getInstance()
        return "${c.get(java.util.Calendar.YEAR)}-${(c.get(java.util.Calendar.MONTH) + 1).toString().padStart(2, '0')}-${c.get(java.util.Calendar.DAY_OF_MONTH).toString().padStart(2, '0')}"
    }

    private fun sendBlockerNotification(title: String, message: String) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        val chId = "refocus_alert_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(chId, "Refocus Peringatan", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Peringatan saat batas waktu penggunaan habis"
                enableVibration(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            nm.createNotificationChannel(channel)
        }
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        val pi = PendingIntent.getActivity(
            this, 1002, launchIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            else PendingIntent.FLAG_UPDATE_CURRENT
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            Notification.Builder(this, chId)
        else @Suppress("DEPRECATION") Notification.Builder(this)

        val notif = builder
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pi)
            .setAutoCancel(true)
            .setPriority(Notification.PRIORITY_HIGH)
            .setDefaults(Notification.DEFAULT_ALL)
            .build()

        nm.notify(2002, notif)
    }

    // ── Foreground notification ───────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Refocus Protection Service", NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifikasi tenang untuk menjaga Refocus tetap aktif di latar belakang"
                setShowBadge(false)
            }
            (getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)
                ?.createNotificationChannel(channel)
        }
    }

    private fun startInForeground() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        val pi = PendingIntent.getActivity(
            this, 0, launchIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            else PendingIntent.FLAG_UPDATE_CURRENT
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            Notification.Builder(this, CHANNEL_ID)
        else @Suppress("DEPRECATION") Notification.Builder(this)

        val notification = builder
            .setContentTitle("Refocus")
            .setContentText("Proteksi aktif di latar belakang")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pi)
            .setOngoing(true)
            .build()

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (_: Exception) {
            try { startForeground(NOTIFICATION_ID, notification) } catch (_: Exception) {}
        }
    }

    private fun updateForegroundNotification(title: String, text: String) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        val pi = PendingIntent.getActivity(
            this, 0, launchIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            else PendingIntent.FLAG_UPDATE_CURRENT
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            Notification.Builder(this, CHANNEL_ID)
        else @Suppress("DEPRECATION") Notification.Builder(this)

        val notification = builder
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pi)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()

        nm.notify(NOTIFICATION_ID, notification)
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        try {
            val enabled = prefs.getBoolean(K_ENABLED, false)
            if (enabled) {
                scheduleRestart(applicationContext)
            }
        } catch (e: Exception) {
            Log.w(TAG, "onTaskRemoved handling: ${e.message}")
        }
    }
}

package com.example.refocus

import android.app.AppOpsManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.refocus/platform"

    private var activeOverlayView: View? = null
    private var overlayHandler: Handler? = null
    private var overlayRunnable: Runnable? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    try {
                        val apps = getInstalledApps()
                        result.success(apps)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "hasUsagePermission" -> {
                    result.success(hasUsagePermission())
                }
                "requestUsagePermission" -> {
                    requestUsagePermission()
                    result.success(true)
                }
                "hasOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "startForegroundService" -> {
                    RefocusForegroundService.startService(this)
                    result.success(true)
                }
                "stopForegroundService" -> {
                    RefocusForegroundService.stopService(this)
                    result.success(true)
                }
                "showOverlayBlocker" -> {
                    val title = call.argument<String>("title") ?: "Waktunya Istirahat"
                    val message = call.argument<String>("message") ?: "Aplikasi ini diblokir sementara."
                    val seconds = call.argument<Int>("seconds") ?: 5
                    showOverlayBlocker(title, message, seconds)
                    result.success(true)
                }
                "kickToHomeScreen" -> {
                    kickToHomeScreen()
                    result.success(true)
                }
                "getForegroundApp" -> {
                    val pkg = getForegroundApp()
                    result.success(pkg)
                }
                "hasBatteryOptimizationIgnored" -> {
                    result.success(isBatteryOptimizationIgnored())
                }
                "requestIgnoreBatteryOptimization" -> {
                    requestIgnoreBatteryOptimization()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsagePermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            ).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        }
    }

    private fun sendBlockerNotification(title: String, message: String) {
        val appContext = applicationContext
        val nm = appContext.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        val channelId = "refocus_alert_channel"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Refocus Peringatan & Blokir",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikasi muncul saat batas waktu habis atau aplikasi diblokir"
                enableVibration(true)
                setShowBadge(true)
            }
            nm.createNotificationChannel(channel)
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: Intent(this, MainActivity::class.java)
        launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        val pendingIntent = PendingIntent.getActivity(
            appContext,
            1002,
            launchIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            else
                PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(appContext, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(appContext)
        }

        val notif = builder
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(Notification.PRIORITY_HIGH)
            .setDefaults(Notification.DEFAULT_ALL)
            .build()

        nm.notify(2002, notif)
    }

    private fun showOverlayBlocker(title: String, message: String, durationSeconds: Int) {
        sendBlockerNotification(title, message)

        if (!hasOverlayPermission()) {
            // Fallback if overlay permission is missing: immediately kick to home screen
            kickToHomeScreen()
            return
        }

        runOnUiThread {
            if (activeOverlayView != null) return@runOnUiThread // Blocker already on screen

            val appContext = applicationContext
            val wm = appContext.getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: return@runOnUiThread
            val layoutParams = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.CENTER
            }

            val density = appContext.resources.displayMetrics.density
            val pad = (24 * density).toInt()

            val root = LinearLayout(appContext).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                setBackgroundColor(Color.parseColor("#E60E1116")) // Calm backdrop
                setPadding(pad, pad, pad, pad)
                setOnTouchListener { _, _ -> true } // Block touches through to underlying app
            }

            val cardBg = GradientDrawable().apply {
                setColor(Color.parseColor("#181D24"))
                cornerRadius = 20 * density
                setStroke((1.5 * density).toInt(), Color.parseColor("#21262D"))
            }

            val card = LinearLayout(appContext).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                background = cardBg
                setPadding((28 * density).toInt(), (32 * density).toInt(), (28 * density).toInt(), (32 * density).toInt())
            }

            val titleView = TextView(appContext).apply {
                text = title
                setTextColor(Color.parseColor("#F0F6FC"))
                textSize = 20f
                gravity = Gravity.CENTER
                setTypeface(null, Typeface.BOLD)
            }

            val msgView = TextView(appContext).apply {
                text = message
                setTextColor(Color.parseColor("#8B949E"))
                textSize = 14f
                gravity = Gravity.CENTER
                setPadding(0, (14 * density).toInt(), 0, (20 * density).toInt())
            }

            val countView = TextView(appContext).apply {
                text = "Menutup dalam $durationSeconds detik..."
                setTextColor(Color.parseColor("#58A6FF"))
                textSize = 15f
                gravity = Gravity.CENTER
                setTypeface(null, Typeface.BOLD)
                setPadding(0, 0, 0, (24 * density).toInt())
            }

            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#21262D"))
                cornerRadius = 12 * density
            }

            val exitBtn = Button(appContext).apply {
                text = "Keluar Sekarang"
                setTextColor(Color.parseColor("#F0F6FC"))
                background = btnBg
                isAllCaps = false
                setOnClickListener {
                    dismissOverlay(wm)
                    kickToHomeScreen()
                }
            }

            card.addView(titleView)
            card.addView(msgView)
            card.addView(countView)
            card.addView(exitBtn)
            root.addView(card)

            try {
                wm.addView(root, layoutParams)
                activeOverlayView = root

                var remaining = durationSeconds
                overlayHandler = Handler(Looper.getMainLooper())
                overlayRunnable = object : Runnable {
                    override fun run() {
                        remaining--
                        if (remaining > 0) {
                            countView.text = "Menutup dalam $remaining detik..."
                            overlayHandler?.postDelayed(this, 1000)
                        } else {
                            dismissOverlay(wm)
                            kickToHomeScreen()
                        }
                    }
                }
                overlayHandler?.postDelayed(overlayRunnable!!, 1000)
            } catch (e: Exception) {
                kickToHomeScreen()
            }
        }
    }

    private fun dismissOverlay(wm: WindowManager) {
        activeOverlayView?.let {
            try {
                wm.removeView(it)
            } catch (_: Exception) {}
            activeOverlayView = null
        }
        overlayRunnable?.let { overlayHandler?.removeCallbacks(it) }
        overlayRunnable = null
        overlayHandler = null
    }

    private fun kickToHomeScreen() {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val pm = packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveInfos = pm.queryIntentActivities(mainIntent, 0)
        val appList = mutableListOf<Map<String, String>>()
        val seen = mutableSetOf<String>()

        for (info in resolveInfos) {
            val pkg = info.activityInfo.packageName
            if (pkg != packageName && !seen.contains(pkg)) {
                seen.add(pkg)
                val label = info.loadLabel(pm).toString()
                appList.add(mapOf("packageName" to pkg, "appName" to label))
            }
        }
        appList.sortBy { it["appName"]?.lowercase() ?: "" }
        return appList
    }

    private fun getForegroundApp(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return null
        val time = System.currentTimeMillis()
        // Query 60-minute window so active app remains tracked even if user stays in it without switching
        val events = usm.queryEvents(time - 3600000L, time)
        val event = UsageEvents.Event()
        var currentPkg: String? = null

        val ignoredPrefixes = listOf(
            packageName,                          // com.example.refocus
            "com.android.launcher",
            "com.google.android.launcher",
            "com.miui.home",
            "com.sec.android.app.launcher",
            "com.huawei.android.launcher",
            "com.oneplus.launcher",
            "com.coloros.launcher",
            "com.oppo.launcher",
            "com.vivo.launcher"
        )

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    val pkg = event.packageName ?: continue
                    currentPkg = pkg
                }
                UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                    currentPkg = null
                }
            }
        }

        if (currentPkg != null && ignoredPrefixes.any { currentPkg.startsWith(it) }) {
            return null
        }
        return currentPkg
    }

    private fun isBatteryOptimizationIgnored(): Boolean {
        val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return false
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    private fun requestIgnoreBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        }
    }
}

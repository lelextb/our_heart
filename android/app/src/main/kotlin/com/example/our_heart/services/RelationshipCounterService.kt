package com.example.our_heart.services

import android.Manifest
import android.app.AlarmManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.example.our_heart.utils.DateUtils
import com.example.our_heart.utils.NotificationHelper
import java.util.Calendar

class RelationshipCounterService : Service() {

    private lateinit var wakeLock: PowerManager.WakeLock
    private val handler = Handler(Looper.getMainLooper())
    private var startDateMillis: Long = 0L
    private var midnightAlarmPendingIntent: PendingIntent? = null
    private var isRunning = false

    override fun onCreate() {
        super.onCreate()
        NotificationHelper.createChannel(this)

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "OurHeart:RelationshipCounterWakeLock"
        )
        wakeLock.setReferenceCounted(false)

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_TIME_CHANGED)
            addAction(Intent.ACTION_TIMEZONE_CHANGED)
        }
        registerReceiver(timeChangeReceiver, filter)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent != null) {
            val date = intent.getLongExtra(EXTRA_START_DATE, 0L)
            if (date > 0L) {
                startDateMillis = date
                isRunning = true
                // Check permission before starting foreground
                if (hasDataSyncPermission()) {
                    startForegroundNotification()
                } else {
                    // Fallback: show notification without foreground service
                    updateNotification()
                }
                scheduleMidnightUpdate()
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        isRunning = false
        stopForeground(true)
        cancelMidnightAlarm()
        unregisterReceiver(timeChangeReceiver)
        if (wakeLock.isHeld) {
            wakeLock.release()
        }
        super.onDestroy()
    }

    private fun hasDataSyncPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.FOREGROUND_SERVICE_DATA_SYNC
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun startForegroundNotification() {
        val days = DateUtils.daysSince(startDateMillis)
        val notification = NotificationHelper.buildNotification(this, days).build()
        startForeground(NotificationHelper.NOTIFICATION_ID, notification)
    }

    private fun updateNotification() {
        if (!isRunning) return
        val days = DateUtils.daysSince(startDateMillis)
        val notification = NotificationHelper.buildNotification(this, days).build()
        NotificationManagerCompat.from(this).notify(
            NotificationHelper.NOTIFICATION_ID,
            notification
        )
    }

    private fun scheduleMidnightUpdate() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, MidnightAlarmReceiver::class.java)

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            MIDNIGHT_ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        midnightAlarmPendingIntent = pendingIntent

        val triggerTime = getNextMidnightMillis()

        alarmManager.setRepeating(
            AlarmManager.RTC_WAKEUP,
            triggerTime,
            AlarmManager.INTERVAL_DAY,
            pendingIntent ?: return
        )
    }

    private fun cancelMidnightAlarm() {
        midnightAlarmPendingIntent?.let {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(it)
            midnightAlarmPendingIntent = null
        }
    }

    private fun getNextMidnightMillis(): Long {
        val cal = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return cal.timeInMillis
    }

    private val timeChangeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_TIME_CHANGED ||
                intent?.action == Intent.ACTION_TIMEZONE_CHANGED
            ) {
                if (isRunning) {
                    updateNotification()
                    cancelMidnightAlarm()
                    scheduleMidnightUpdate()
                }
            }
        }
    }

    class MidnightAlarmReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (context == null) return

            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wl = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "OurHeart:MidnightWakeLock"
            )
            wl.acquire(10 * 1000L)

            try {
                val serviceIntent = Intent(context, RelationshipCounterService::class.java).apply {
                    putExtra(EXTRA_START_DATE, getStoredStartDate(context))
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } finally {
                wl.release()
            }
        }

        private fun getStoredStartDate(context: Context): Long {
            val prefs = context.getSharedPreferences(
                PREFS_NAME,
                Context.MODE_PRIVATE
            )
            return prefs.getLong(KEY_START_DATE, 0L)
        }
    }

    companion object {
        private const val EXTRA_START_DATE = "start_date_millis"
        private const val MIDNIGHT_ALARM_REQUEST_CODE = 200
        private const val KEY_START_DATE = "relationship_start_date"
        private const val PREFS_NAME = "com.example.our_heart.RELATIONSHIP_PREFS"

        fun start(context: Context, startDateMillis: Long) {
            persistStartDate(context, startDateMillis)
            val intent = Intent(context, RelationshipCounterService::class.java).apply {
                putExtra(EXTRA_START_DATE, startDateMillis)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, RelationshipCounterService::class.java)
            context.stopService(intent)
        }

        fun updateDate(context: Context, newStartDateMillis: Long) {
            persistStartDate(context, newStartDateMillis)
            stop(context)
            start(context, newStartDateMillis)
        }

        private fun persistStartDate(context: Context, millis: Long) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putLong(KEY_START_DATE, millis)
                .apply()
        }
    }
}